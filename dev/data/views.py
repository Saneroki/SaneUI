"""What the master holds, for people (Doc/guides/data.md, *Tools*): an entry with every version and source
(show), what a patch changed (diff), and counts and sizes per set and pack (stats). Each gives lines of text.
"""
import json

import compile as compiler
import master as masters
import schema as schemas


def shown(value):
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"))


def key_of(schema, text):
    """A key as typed on the command line, as the set keys its entries; None when it cannot be one."""
    if schema.key == "int":
        return int(text) if text.lstrip("-").isdigit() else None
    return text


def _when(master, game, version):
    patch = master.builds.get(game, {}).get(version.since, {}).get("patch")
    return f"{version.since}" + (f" ({patch})" if patch else "") + (f" {version.day}" if version.day else "")


def _fields(schema, fields):
    return ", ".join(f"{field.name} {'cleared' if fields[field.name] is None else shown(fields[field.name])}"
                     for field in schema.fields if field.name in fields)


def show(master, set_name, text, game=masters.LIVE):
    """An entry's versions, each as its line says (its sources and what it changed) with the fix laid on it,
    then the entry as the packs carry it now."""
    schema = master.schemas.get(set_name)
    if schema is None:
        return [f"'{set_name}' is no set ({', '.join(sorted(master.schemas))})."]
    key = key_of(schema, text)
    versions = master.view(set_name, game, fixes=False).get(key)
    if not versions:
        return [f"{set_name} has no {text!r} in {game}."]
    fixes = {fix.order(): fix for fix in master.fixes.get((set_name, game), [])}
    out = [f"{set_name} {key!r} ({game}), in the pack {schema.pack}:"]
    for version in versions:
        line = version.line
        if line is None:
            out.append(f"  0: live's newest version, which {game} stands on")
            continue
        what = "gone" if line.gone else _fields(schema, line.fields)
        if line.replaces is not None:
            what = f"replaces {line.replaces!r}; " + what
        out.append(f"  {_when(master, game, version)} [{', '.join(map(masters.source_name, line.src))}]: {what}")
        fix = fixes.get(line.order())
        if fix:
            out.append(f"    fixed by hand: {_fields(schema, fix.fields)}")
    newest = master.view(set_name, game)[key][-1]
    out.append("  now: " + ("gone" if newest.gone else _fields(schema, newest.fields)))
    return out


def _patch_builds(master, game, patch):
    return {build for build, info in master.builds.get(game, {}).items() if info["patch"] == patch}


def diff(master, set_name, game=masters.LIVE, patch=None):
    """What a patch changed in a set (the newest patch of the game version when none is named): every entry
    with a version at one of its builds, against the version before."""
    schema = master.schemas.get(set_name)
    if schema is None:
        return [f"'{set_name}' is no set ({', '.join(sorted(master.schemas))})."]
    builds = master.builds.get(game, {})
    if patch is None:
        if not builds:
            return [f"{game} has no builds in builds.toml."]
        patch = builds[max(builds)]["patch"]
    wanted = _patch_builds(master, game, patch)
    if not wanted:
        return [f"No build of {game} is {patch} in builds.toml."]
    out = []
    view = master.view(set_name, game)
    for key in sorted(view, key=lambda k: (isinstance(k, str), k)):
        versions = view[key]
        for index, version in enumerate(versions):
            if version.since not in wanted:
                continue
            before = versions[index - 1] if index else None
            when = _when(master, game, version)
            if version.gone:
                out.append(f"  {key!r} {when}: gone")
            elif before is None or before.gone:
                out.append(f"  {key!r} {when}: {'new' if before is None else 'back'}: {_fields(schema, version.fields)}")
            else:
                changes = [f"{field.name} {shown(before.fields.get(field.name)) if field.name in before.fields else 'empty'}"
                           f" → {shown(version.fields[field.name]) if field.name in version.fields else 'empty'}"
                           for field in schema.fields
                           if not schemas.same(before.fields.get(field.name), version.fields.get(field.name))]
                out.append(f"  {key!r} {when}: {'; '.join(changes)}")
    head = f"{set_name} ({game}), patch {patch}: {len(out)} " + ("change." if len(out) == 1 else "changes.")
    return [head] + out


def _size(count):
    return f"{count / 1024:.1f} KB" if count >= 1024 else f"{count} B"


def stats(master):
    """Per game version: every set's entries, versions and file size in its pack, then each pack's totals."""
    out = []
    for game in master.games:
        packs = {}
        rows = []
        for name in sorted(master.schemas):
            schema = master.schemas[name]
            view = master.view(name, game)
            if not view:
                continue
            text, entries = compiler.set_file(master, schema, game)
            versions = sum(len(v) for v in view.values())
            changed = sum(1 for v in view.values() if len(v) > 1)
            gone = sum(1 for v in view.values() if v[-1].gone)
            own = len(master.lines.get((name, game), []))
            size = len(text.encode("utf-8"))
            rows.append((name, schema.pack, entries, versions, changed, gone, own, _size(size)))
            total = packs.setdefault(schema.pack, [0, 0, 0])
            total[0], total[1], total[2] = total[0] + 1, total[1] + entries, total[2] + size
        if not rows:
            out.append(f"{game}: no entries.")
            continue
        out.append(f"{game}:")
        head = ("Set", "Pack", "Entries", "Versions", "Changed", "Gone", "Lines", "Size")
        widths = [max(len(str(row[i])) for row in rows + [head]) for i in range(len(head))]
        for row in [head] + rows:
            out.append("  " + "  ".join(str(cell).ljust(width) if i < 2 else str(cell).rjust(width)
                                        for i, (cell, width) in enumerate(zip(row, widths))).rstrip())
        for pack in sorted(packs):
            sets, entries, size = packs[pack]
            out.append(f"  pack {pack}: {sets} {'set' if sets == 1 else 'sets'}, {entries} entries, {_size(size)}")
    return out
