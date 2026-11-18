// The tools' pages menu (dev/tools/web-pages): a ☰ button on every tool page of SaneUI that opens the list of
// them all, with a dot for whether a page is ready, so one page leads to the others. The server sends this file as
// /web-nav.js with the list filled in and puts it into every HTML page it sends.
// It also asks the browser for its dark controls and scrollbars, as the pages are dark.
(() => {
  "use strict";
  const PAGES = /*PAGES*/[];
  if (window.__saneNav) return;
  window.__saneNav = true;
  document.documentElement.style.colorScheme = "dark";

  const here = location.pathname.split("/")[1];
  const box = document.createElement("div");
  box.id = "sane-web-nav";
  const root = box.attachShadow({ mode: "open" });
  root.innerHTML = `<style>
    :host { all: initial; }
    * { box-sizing: border-box; font: 14px/1.4 system-ui, -apple-system, "Segoe UI", sans-serif; }
    button.open { display: inline-flex; align-items: center; justify-content: center; width: 32px; height: 32px;
      border: 1px solid #3b3732; border-radius: 8px; background: #24221f; color: #ece6dc; cursor: pointer; padding: 0;
      font-size: 17px; line-height: 1; }
    button.open:hover { border-color: #d9a56b; color: #d9a56b; }
    .fixed { position: fixed; top: 10px; left: 10px; z-index: 2147483000; box-shadow: 0 2px 8px rgba(0,0,0,.4); }
    .scrim { position: fixed; inset: 0; background: rgba(0,0,0,.5); z-index: 2147483001; opacity: 0; pointer-events: none;
      transition: opacity .15s; }
    .drawer { position: fixed; top: 0; left: 0; bottom: 0; width: min(300px, 86vw); background: #1b1a18; color: #ece6dc;
      border-right: 1px solid #3b3732; z-index: 2147483002; transform: translateX(-102%); transition: transform .18s ease-out;
      display: flex; flex-direction: column; box-shadow: 4px 0 24px rgba(0,0,0,.5); }
    .on .scrim { opacity: 1; pointer-events: auto; }
    .on .drawer { transform: none; }
    .head { display: flex; align-items: center; gap: 10px; padding: 14px 16px; border-bottom: 1px solid #3b3732; }
    .head b { font-size: 15px; } .head b span { color: #d9a56b; }
    .head button { margin-left: auto; background: none; border: 0; color: #a39a8c; font-size: 20px; cursor: pointer; }
    nav { overflow-y: auto; padding: 8px; }
    a { display: flex; align-items: center; gap: 10px; padding: 9px 10px; border-radius: 8px; color: #ece6dc;
      text-decoration: none; }
    a:hover, a:focus-visible { background: #2e2b27; outline: none; }
    a[aria-current="page"] { background: #3a3027; color: #d9a56b; }
    i { width: 8px; height: 8px; border-radius: 50%; background: #5a544c; flex: none; }
    i.up { background: #7fb08a; } i.down { background: #6b3a33; }
    a.down { color: #8c8478; }
  </style>
  <button class="open" title="Every tool page (Alt+M)" aria-label="Every tool page"><svg width="16" height="16" viewBox="0 0 16 16" aria-hidden="true"><path d="M2 4h12M2 8h12M2 12h12" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg></button>
  <div class="layer"><div class="scrim"></div>
    <aside class="drawer" role="dialog" aria-label="Every tool page">
      <div class="head"><b>SaneUI <span>pages</span></b><button title="Close (Esc)" aria-label="Close">×</button></div>
      <nav></nav>
    </aside></div>`;

  const layer = root.querySelector(".layer"), nav = root.querySelector("nav"), open = root.querySelector("button.open");
  for (const page of PAGES) {
    const a = document.createElement("a");
    a.href = page.href;
    a.innerHTML = `<i class="${page.ready ? "up" : "down"}"></i><span></span>`;
    a.querySelector("span").textContent = page.name.charAt(0).toUpperCase() + page.name.slice(1);
    if (page.place === here) a.setAttribute("aria-current", "page");
    if (!page.ready) { a.classList.add("down"); a.title = "not built yet"; }
    nav.append(a);
  }

  const show = (on) => {
    layer.classList.toggle("on", on);
    if (on) (nav.querySelector("a[aria-current]") || nav.querySelector("a"))?.focus();
  };
  open.onclick = () => show(true);
  root.querySelector(".scrim").onclick = root.querySelector(".head button").onclick = () => show(false);
  document.addEventListener("keydown", (ev) => {
    if (ev.key === "Escape" && layer.classList.contains("on")) { ev.stopPropagation(); show(false); }
    if (ev.altKey && (ev.key === "m" || ev.key === "M")) { ev.preventDefault(); show(!layer.classList.contains("on")); }
  }, true);

  function place() {   // in the page's header bar, before its title; else in the top left corner
    const header = document.querySelector("body > header, header");
    const title = header?.querySelector("h1");
    if (header && getComputedStyle(header).display.includes("flex")) {
      box.style.cssText = "display:inline-flex;flex:none;margin-right:4px";
      header.prepend(box);
    } else if (title) {
      box.style.cssText = "display:inline-flex;vertical-align:middle;margin-right:10px";
      title.prepend(box);
    } else {
      open.classList.add("fixed");
      document.body.append(box);
    }
  }
  if (document.body) place(); else document.addEventListener("DOMContentLoaded", place);
})();
