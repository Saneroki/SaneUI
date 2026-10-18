"""The todo list for people (Markdown) and for tools (JSON), from an Analysis."""
import json
import os
from datetime import date
from pathlib import Path

from compare import SECTIONS

TITLES = {
    "broken": "Broken: Sane UI uses what is gone",
    "deprecated": "Deprecated: only Blizzard's deprecated addons still have it",
    "changed": "Changed: check how Sane UI calls it",
    "review": "Review: hooked or built on, and changed inside",
    "housekeeping": "Housekeeping",
}
SHOWN_USES = 8  # places named per item; the JSON has them all


def describe(export, root):
    try:
        where = Path(export.root).resolve().relative_to(Path(root).resolve()).as_posix()
    except ValueError:
        where = str(export.root)
    return f"`{where}`" + (f" (build {export.build})" if export.build else " (build not known)")


def markdown(analysis, out, root, new_path_arg=None):
    old, new = analysis.old, analysis.new
    sections = analysis.by_section()
    counts = analysis.counts()
    up = os.path.relpath(Path(root).resolve(), Path(out).resolve().parent)
    changed_files = sum(1 for path in old.files.keys() | new.files.keys() if old.files.get(path) != new.files.get(path))
    lines = [
        f"# Blizzard update: {old.label} → {new.label}",
        "",
        f"- Old: {describe(old, root)}. New: {describe(new, root)}.",
        f"- Blizzard changed {changed_files} files. Symbols: {counts.get('added', 0)} new, {counts.get('removed', 0)} "
        f"gone, {counts.get('changed', 0)} called differently, {counts.get('deprecated', 0)} deprecated, "
        f"{counts.get('body', 0)} changed inside.",
        "- For Sane UI: " + ", ".join(f"{len(sections[s])} {s}" for s in SECTIONS) + ".",
        f"- Made {date.today().isoformat()} by `dev/tools/blizzard check`.",
        "",
        "Work from the top and tick each item when it is done. `dev/tools/blizzard show <name>` shows a symbol in",
        "both exports with its diff. When everything is done, the last item takes the new export in.",
    ]
    for section in SECTIONS:
        findings = sections[section]
        if not findings:
            continue
        lines += ["", f"## {TITLES[section]} ({len(findings)})", ""]
        for finding in findings:
            lines.append(f"- [ ] {finding.title()}: " + "; ".join(finding.notes) + ".")
            if finding.uses:
                shown = [f"[{u.file}:{u.line}]({up}/{u.file}#L{u.line})" + (f" ({u.how})" if u.how and u.kind == "hook" else "")
                         for u in finding.uses[:SHOWN_USES]]
                more = len(finding.uses) - SHOWN_USES
                lines.append("  - Used: " + ", ".join(shown) + (f" and {more} more" if more > 0 else ""))
            if finding.hints:
                lines.append("  - Maybe now: " + ", ".join(finding.hints))
            if finding.diff:
                lines += ["  <details><summary>diff</summary>", "", "  ```diff"]
                lines += [f"  {line}" for line in finding.diff]
                lines += ["  ```", "  </details>"]
    adopt = "dev/tools/blizzard adopt" + (f" {new_path_arg}" if new_path_arg else "")
    if not sections["housekeeping"]:
        lines += ["", f"## {TITLES['housekeeping']}", ""]
    lines += [f"- [ ] Take the new export in: `{adopt}` (references/ and the files made from it), then build, "
              "try it in the game and commit."]
    added = analysis.new_api()
    if added:
        lines += ["", "## For information", "", f"New API in the namespaces Sane UI calls ({len(added)}): "
                  + ", ".join(f"`{name}`" for name in added[:60]) + (" ..." if len(added) > 60 else "") + "."]
    warnings = old.warnings + new.warnings + analysis.uses.problems
    if warnings:
        lines += ["", "Warnings:", ""] + [f"- {w}" for w in warnings]
    Path(out).parent.mkdir(parents=True, exist_ok=True)
    Path(out).write_text("\n".join(lines) + "\n", encoding="utf-8")


def as_json(analysis, out):
    old, new = analysis.old, analysis.new
    data = {
        "old": {"root": str(old.root), "build": old.build}, "new": {"root": str(new.root), "build": new.build},
        "made": date.today().isoformat(), "changes": analysis.counts(),
        "findings": [f.as_dict() for section in analysis.by_section().values() for f in section],
        "new_api": analysis.new_api(),
    }
    Path(out).write_text(json.dumps(data, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")


def summary(analysis, out):
    """A few lines to print when the check is done."""
    sections = analysis.by_section()
    lines = [f"Blizzard {analysis.old.label} → {analysis.new.label}: "
             + ", ".join(f"{len(sections[s])} {s}" for s in SECTIONS) + "."]
    for section in ("broken", "deprecated", "changed"):
        for finding in sections[section][:10]:
            lines.append(f"  {section}: {finding.title()}: " + "; ".join(finding.notes)[:140])
    lines.append(f"The todo list: {out}")
    return lines
