#!/usr/bin/env python3
"""A module's sample data on the real schemas, compiled into packs for that module's tests: a copy of the real
master's tables and schemas (assets/data) with the sample's lines in place of the real ones, checked, then the
packs of a game version (forever unless given) written into <out>. So a module is tested on a few made-up
entries, never on the real data, in the very shape the real packs have.

Usage: python3 -I dev/tests/data/packs.py <sample folder> <out folder> [game version]
       the sample folder holds <Set>/<Set>.jsonl files, as the master does"""
import shutil
import sys
import tempfile
from pathlib import Path

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "dev" / "data"))

import check as checks  # noqa: E402
import compile as compiler  # noqa: E402
import master as masters  # noqa: E402


def main(sample, out, game="forever"):
    with tempfile.TemporaryDirectory(prefix="saneui-packs-") as folder:
        root = Path(folder) / "data"
        root.mkdir()
        for name in masters.TOP:
            shutil.copyfile(masters.MASTER / name, root / name)
        for schema in sorted(masters.MASTER.glob("*/schema.toml")):
            (root / schema.parent.name).mkdir()
            shutil.copyfile(schema, root / schema.parent.name / "schema.toml")
        for lines in sorted(Path(sample).glob("*/*.jsonl")):
            shutil.copyfile(lines, root / lines.parent.name / lines.name)
        master = masters.Master(root).load()
        checks.check(master)
        if master.errors:
            print("\n".join(master.errors), file=sys.stderr)
            return 1
        Path(out).mkdir(parents=True, exist_ok=True)
        compiler.compile_packs(master, Path(out), game)
    return 0


if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:]))
