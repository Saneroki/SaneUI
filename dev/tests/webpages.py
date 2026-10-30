#!/usr/bin/env python3
"""Tests of dev/tools/web-pages, the one server of the tools' pages: a page by its place, folders over each other, a
tool's web(), new code without a restart, what only this computer may ask, and every page of the real list.
Run by dev/tests/run."""
import http.client
import importlib.machinery
import importlib.util
import json
import os
import shutil
import sys
import tempfile
import threading
from pathlib import Path

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
loader = importlib.machinery.SourceFileLoader("web_pages", str(ROOT / "dev" / "tools" / "web-pages"))
wp = importlib.util.module_from_spec(importlib.util.spec_from_loader("web_pages", loader))
sys.modules["web_pages"] = wp
loader.exec_module(wp)
checks = failed = 0


def check(name, got, want):
    global checks, failed
    checks += 1
    if got != want:
        failed += 1
        print(f"FAIL {name}: got {got!r}, want {want!r}")


# The real list: what the tools and the one command name is there.
places = [p.place for p in wp.PAGES]
check("places are unique", len(places), len(set(places)))
for page in wp.PAGES:
    if page.tool:
        check(f"{page.name} is a script", page.tool.path.is_file(), True)
        check(f"{page.name} has web()", "def web(request):" in page.tool.path.read_text(), True)
    else:
        check(f"{page.name}'s first folder lies in the project or is made", page.folders[0].is_relative_to(ROOT), True)
saneui = (ROOT / "dev" / "saneui").read_text()
for place in places:
    if place != "pieces":
        check(f"saneui opens {place}", f'["dev/tools/web-pages", "open", "{place}"]' in saneui, True)
for name in ("board-page/index.html", "world-map-page/index.html", "map-compare-page/index.html"):
    check(f"{name} leaves the menu to the server", "web-nav.js" in (ROOT / "dev" / "tools" / name).read_text(), False)

# A little site of its own on a free port.
scratch = Path(tempfile.mkdtemp(prefix="web-pages-"))
first, second = scratch / "first", scratch / "second"
(first / "deep").mkdir(parents=True)
second.mkdir()
(first / "index.html").write_text("<html><body>first</body></html>")
(first / "both.txt").write_text("from the first")
(first / "deep" / "index.html").write_text("<html><body>deep</body></html>")
(second / "both.txt").write_text("from the second")
(second / "only.txt").write_text("only in the second")
tool = scratch / "tool"
tool.write_text('def web(request):\n'
                '    if request.path == "/boom":\n        raise ValueError("boom")\n'
                '    if request.method == "POST":\n        return 200, "application/json", {"got": request.json()}\n'
                '    return 200, "text/html; charset=utf-8", f"<body>one {request.path} {request.query}</body>"\n')
wp.PAGES[:] = [wp.Page("folders", "files", [first, second]), wp.Page("a tool", "tool", tool, "?a=1")]
wp.CONFIG = scratch / "no-config.json"
wp.traceback.print_exc = lambda: None    # the error asked for below is no news
server = wp.http.server.ThreadingHTTPServer(("127.0.0.1", 0), wp.Site)
threading.Thread(target=server.serve_forever, daemon=True).start()
port = server.server_address[1]


def ask(path, method="GET", body=None, headers=None):
    link = http.client.HTTPConnection("127.0.0.1", port)
    link.request(method, path, body, headers or {})
    answer = link.getresponse()
    data = answer.read().decode()
    link.close()
    return answer.status, data, answer.getheader("Location")


status, data, _ = ask("/")
check("the list", status, 200)
check("the list names a page", "Folders" in data and "/tool/?a=1" in data, True)
check("the list has the menu", wp.MENU.decode() in data, True)
status, data, _ = ask("/web-nav.js")
check("the menu is sent", status, 200)
check("the menu holds the list", '"place": "tool"' in data and "/*PAGES*/" not in data, True)
check("an unknown place", ask("/nothing/")[0], 404)
status, _, where = ask("/files")
check("a place wants its slash", (status, where), (302, "/files/"))
check("the slash keeps the query", ask("/tool?a=1")[2], "/tool/?a=1")
status, data, _ = ask("/files/")
check("a folder's page", status, 200)
check("a folder's page has the menu", "first" in data and wp.MENU.decode() in data, True)
check("the first folder wins", ask("/files/both.txt")[1], "from the first")
check("the next folder answers", ask("/files/only.txt")[1], "only in the second")
check("a folder inside wants its slash", ask("/files/deep")[2], "/files/deep/")
check("a folder inside", "deep" in ask("/files/deep/")[1], True)
check("nothing there", ask("/files/missing.txt")[0], 404)
check("no way out of a folder", ask("/files/../tool")[0] != 200 or "one" not in ask("/files/../tool")[1], True)
check("a folder takes no POST", ask("/files/", "POST", b"{}")[0], 405)
status, data, _ = ask("/tool/some/path?a=1&a=2")
check("a tool", status, 200)
check("a tool's path is under its place", "one /some/path {'a': ['1', '2']}" in data, True)
check("a tool's page has the menu", wp.MENU.decode() in data, True)
status, data, _ = ask("/tool/", "POST", json.dumps({"x": 1}), {"Content-Type": "application/json"})
check("a tool's POST", (status, json.loads(data)), (200, {"got": {"x": 1}}))
status, data, _ = ask("/tool/boom")
check("an error stays in its page", (status, "boom" in data), (500, True))
check("the others go on", ask("/files/only.txt")[0], 200)
tool.write_text(tool.read_text().replace("one ", "two "))
os.utime(tool, (1, 1))
check("a tool's new code needs no restart", "two /" in ask("/tool/")[1], True)
check("a foreign name is refused", ask("/", headers={"Host": "elsewhere.example"})[0], 403)
check("a foreign site is refused", ask("/tool/", "POST", b"{}", {"Origin": "https" + "://elsewhere.example"})[0], 403)
check("this computer's own page is not", ask("/tool/", "POST", b"{}", {"Origin": "http" + f"://localhost:{port}"})[0], 200)
server.shutdown()
shutil.rmtree(scratch, ignore_errors=True)

if failed:
    sys.exit(f"web-pages: {failed} of {checks} checks failed")
print(f"web-pages: all {checks} checks passed.")
