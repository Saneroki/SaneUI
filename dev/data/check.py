"""The check of the master (Doc/guides/data.md, *The check*): what reading each line on its own cannot see.

Reading (master.py) already checks every file, line and value on its own. This adds the rules across lines:
the order of a file, an entry's versions (the first whole, every later one changing something, gone, one
line per build and day), refs and replaces pointing at entries that exist, and the fixes.
"""
import master as masters
import schema as schemas


def check(master):
    """Checks a loaded master; adds its problems to master.problems and returns them."""
    for (set_name, game), lines in master.lines.items():
        _order(master, lines)
        _entries(master, set_name, game, lines)
    _refs(master)
    for (set_name, game), fixes in master.fixes.items():
        _fixes(master, set_name, game, fixes)
    return master.problems


def _order(master, lines):
    for before, line in zip(lines, lines[1:]):
        if line.order() < before.order():
            master.error(f"{line.where}: out of order (lines are sorted by key, then since, then day)")
        elif line.order() == before.order():
            master.error(f"{line.where}: a second line of {line.key} for build {line.since}{' on ' + line.day if line.day else ''}")


def _entries(master, set_name, game, lines):
    """An entry's versions, against the game version's view: live's own lines, or another game version's
    lines over live's newest version of each entry."""
    base = {}
    if masters.base_of(game) != game:
        for key, versions in master.view(set_name, masters.base_of(game), fixes=False).items():
            if not versions[-1].gone:
                base[key] = masters.Version(0, None, False, dict(versions[-1].fields), None)
    entries = {}
    for line in sorted(lines, key=masters.Line.order):
        entries.setdefault(line.key, []).append(line)
    for key, own in entries.items():
        versions = [base[key]] if key in base else []
        for number, line in enumerate(own):
            last = versions[-1] if versions else None
            whole = last is None or last.gone  # this line starts the entry anew: it holds every fact
            if number > 0 and line.replaces is not None:
                master.error(f"{line.where}: replaces stands in an entry's first line only")
            if whole and not line.gone:
                nulls = [name for name, value in line.fields.items() if value is None]
                if nulls:
                    master.error(f"{line.where}: {', '.join(nulls)} cleared (null) in a first version")
                if not any(value is not None for value in line.fields.values()):
                    master.error(f"{line.where}: a first version holds at least one fact")
            if whole and line.gone:
                master.error(f"{line.where}: an entry that is not there cannot be gone")
            if not whole and not line.gone:
                same = [name for name, value in line.fields.items()
                        if (value is None and name not in last.fields)
                        or (value is not None and name in last.fields and schemas.same(value, last.fields[name]))]
                if same:
                    master.error(f"{line.where}: {', '.join(same)} does not change (a later version holds only what changed)")
                if not line.fields and line.replaces is None:
                    master.error(f"{line.where}: a later version that changes nothing")
            masters.apply(versions, line)
            if not versions[-1].gone and not versions[-1].fields:
                master.error(f"{line.where}: leaves {key} with no value (write gone instead)")
            if line.replaces is not None and line.replaces == key:
                master.error(f"{line.where}: an entry cannot replace itself")


def _refs(master):
    """Every ref and every replaces points at an entry the game version's view has. A set with no entries at
    all in that view is still to be filled: the refs into it are checked once it has some."""
    known = {}
    for where, game, set_name, key in master.refs:
        if set_name not in master.schemas:
            continue  # said already: no such set
        if (set_name, game) not in known:
            known[(set_name, game)] = set(master.view(set_name, game, fixes=False))
        if not known[(set_name, game)]:
            continue
        if key not in known[(set_name, game)]:
            master.error(f"{where}: points at {set_name} {key!r}, which {game} does not have")


def _fixes(master, set_name, game, fixes):
    """Every fix matches a version of its own game version; one the game may have overtaken is a warning."""
    lines = {line.order(): line for line in master.lines.get((set_name, game), [])}
    entries = {}
    for line in sorted(master.lines.get((set_name, game), []), key=masters.Line.order):
        entries.setdefault(line.key, []).append(line)
    for fix in fixes:
        if fix.order() not in lines:
            master.error(f"{fix.where}: matches no version of {set_name} {fix.key!r} (the same key, since and day)")
            continue
        if fix.gone or fix.replaces is not None:
            master.error(f"{fix.where}: a fix mends fields only")
        for later in entries[fix.key]:
            if later.clock() <= fix.clock():
                continue
            from_game = any(master.sources.get(masters.source_name(s), {}).get("kind") == "game" for s in later.src)
            overtaken = [name for name in fix.fields if name in later.fields]
            if from_game and overtaken:
                master.warning(f"{fix.where}: the game changed {', '.join(overtaken)} later ({later.where}): the fix may be stale")
                break
