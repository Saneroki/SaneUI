// The interface lab's page: draws what the lab's host makes (a list of regions with their places in the screen's
// pixels, sent as changes), sends the mouse and the keys back, and shows the log, the fake server, the inspector
// and a console.
"use strict";
const $ = (s) => document.querySelector(s);
const stage = $("#stage"), itemsEl = $("#items"), overlay = $("#overlay"), viewport = $("#viewport");
const els = new Map();         // id -> element
const data = new Map();        // id -> item
const fonts = new Map();       // font url -> family
const sizes = new Map();       // texture url -> {w, h} | "missing" | Promise
const waiting = new Map();     // texture url -> Set of ids to draw again once its size is known
let screen = { pw: 3840, ph: 2160, scale: 0.65 };
let input = [];
let busy = false, paused = false, inspecting = false, pinned = false;
let last = performance.now(), fit = 1;
let logCount = 0;

// Talking to the server ----------------------------------------------------------------------------------------------
async function post(path, body) {
  const r = await fetch(path, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body || {}) });
  return r.json();
}

function apply(r) {
  if (!r) return;
  if (r.reset) { clearStage(); }
  const changes = r.changes || {};
  for (const id in changes) {
    const it = changes[id];
    if (it === null) remove(id); else draw(id, it);
  }
  for (const m of r.messages || []) log(m);
  if (r.people) setPeople(r.people);
  $("#focus").textContent = r.focus ? "under the mouse: " + r.focus : "";
  if (r.inspect) showInspect(r.inspect);
}

function clearStage() {
  for (const el of els.values()) el.remove();
  els.clear(); data.clear();
}

async function loop(now) {
  requestAnimationFrame(loop);
  if (busy) return;
  const dt = Math.min(1, (now - last) / 1000);
  if (dt < 1 / 61) return;
  last = now;
  busy = true;
  const t0 = performance.now();
  try {
    const events = input; input = [];
    const r = await post("api/frame", { dt: paused ? 0 : dt, input: events });
    apply(r);
    $("#perf").textContent = `${Math.round(performance.now() - t0)} ms a frame · ${els.size} regions`;
    $("#status").textContent = paused ? "paused" : `running · ${(r.time || 0).toFixed(1)} s since the login`;
  } catch (e) {
    $("#status").textContent = "the lab's server does not answer: " + e;
  }
  busy = false;
}

// Drawing ------------------------------------------------------------------------------------------------------------
const texUrl = (p) => "tex?p=" + encodeURIComponent(p);
function rgba(hex, a) {
  const n = parseInt(hex || "ffffff", 16);
  return `rgba(${(n >> 16) & 255},${(n >> 8) & 255},${n & 255},${a == null ? 1 : a})`;
}

function textureSize(url, id) {
  const s = sizes.get(url);
  if (s && !(s instanceof Promise)) return s;
  if (!waiting.has(url)) waiting.set(url, new Set());
  waiting.get(url).add(id);
  if (!s) {
    const p = new Promise((done) => {
      const img = new Image();
      img.onload = () => { sizes.set(url, { w: img.naturalWidth, h: img.naturalHeight }); done(); };
      img.onerror = () => {
        sizes.set(url, "missing");
        log({ kind: "warn", text: "texture not found: " + decodeURIComponent(url.slice(7)) });
        done();
      };
      img.src = url;
    }).then(() => {
      const ids = waiting.get(url) || new Set();
      waiting.delete(url);
      for (const i of ids) if (data.has(i)) draw(i, data.get(i));
    });
    sizes.set(url, p);
  }
  return null;
}

function family(url) {
  if (!url) return "serif";
  if (!fonts.has(url)) {
    const name = "labfont" + fonts.size;
    fonts.set(url, name);
    const face = new FontFace(name, `url(${url})`);
    face.load().then((f) => document.fonts.add(f)).catch(() => log({ kind: "warn", text: "font did not load: " + url }));
  }
  return fonts.get(url);
}

function remove(id) {
  const el = els.get(id);
  if (el) el.remove();
  els.delete(id); data.delete(id);
}

function draw(id, it) {
  data.set(id, it);
  let el = els.get(id);
  if (!el) {
    el = document.createElement("div");
    els.set(id, el);
    itemsEl.appendChild(el);
  }
  el.className = "";
  el.removeAttribute("style");
  el.textContent = "";
  const st = el.style;
  st.left = it.x + "px"; st.top = it.y + "px"; st.width = it.w + "px"; st.height = it.h + "px";
  st.zIndex = it.z;
  if (it.a != null && it.a < 1) st.opacity = it.a;
  if (it.cl) {
    const t = it.cl[1] - it.y, l = it.cl[0] - it.x;
    const r = (it.x + it.w) - (it.cl[0] + it.cl[2]), b = (it.y + it.h) - (it.cl[1] + it.cl[3]);
    st.clipPath = `inset(${Math.max(0, t)}px ${Math.max(0, r)}px ${Math.max(0, b)}px ${Math.max(0, l)}px)`;
  }
  if (it.k === "c") drawColor(el, it);
  else if (it.k === "t") drawTexture(id, el, it);
  else if (it.k === "f") drawText(el, it);
  else if (it.k === "l") drawLine(id, el, it);
  else if (it.k === "cd") {
    const done = (1 - it.left) * 360;
    st.background = `conic-gradient(transparent 0deg ${done}deg, ${rgba(it.c, it.ca)} ${done}deg 360deg)`;
  } else if (it.k === "m") {
    el.className = "model"; el.textContent = "3D model";
  }
}

function blendAndTone(st, it) {
  if (it.bl === "ADD") st.mixBlendMode = "plus-lighter";
  else if (it.bl === "MOD") st.mixBlendMode = "multiply";
  if (it.ds) st.filter = `grayscale(${it.ds})`;
  // The game turns the region as drawn, a mirror of its texture coordinates (scale) inside it: in CSS the rightmost
  // function acts first, so the turn goes in front.
  if (it.rot) st.transform = `rotate(${-it.rot}rad) ${st.transform || ""}`;
}

function drawColor(el, it) {
  const st = el.style;
  if (it.gr) {
    const [o, c1, a1, c2, a2] = it.gr;
    const dir = o === "HORIZONTAL" ? "to right" : "to top";
    st.background = `linear-gradient(${dir}, ${rgba(c1, a1)}, ${rgba(c2, a2)})`;
  } else {
    st.background = rgba(it.c, it.ca);
  }
  if (it.vc) st.backgroundColor = mix(it.c, it.vc, it.ca);
  masks(st, it, []);
  blendAndTone(st, it);
}
function mix(a, b, alpha) {
  const x = parseInt(a, 16), y = parseInt(b, 16);
  const m = (s) => Math.round((((x >> s) & 255) * ((y >> s) & 255)) / 255);
  return `rgba(${m(16)},${m(8)},${m(0)},${alpha == null ? 1 : alpha})`;
}

// The region's masks (mask textures), plus the texture's own alpha where a colour is multiplied into it.
function masks(st, it, extra) {
  const list = extra.slice();
  for (const m of it.m || []) list.push({ url: texUrl(m.f), x: m.x, y: m.y, w: m.w, h: m.h });
  if (!list.length) return;
  st.maskImage = st.webkitMaskImage = list.map((m) => `url("${m.url}")`).join(",");
  st.maskPosition = st.webkitMaskPosition = list.map((m) => m.pos || `${m.x}px ${m.y}px`).join(",");
  st.maskSize = st.webkitMaskSize = list.map((m) => m.size || `${m.w}px ${m.h}px`).join(",");
  st.maskRepeat = st.webkitMaskRepeat = list.map((m) => m.repeat || "no-repeat").join(",");
  if (list.length > 1) { st.maskComposite = "intersect"; st.webkitMaskComposite = "source-in"; }
}

function drawTexture(id, el, it) {
  const st = el.style;
  const url = texUrl(it.f);
  const needSize = it.ht || it.vt || it.sl || it.tc8;
  let size = sizes.get(url);
  if (needSize || !size) size = textureSize(url, id);
  if (size === "missing") { el.className = "missing"; return; }
  if (needSize && !size) return;          // drawn once its size is known
  if (it.tc8) return drawTurned(el, it, url, size);
  if (it.sl) return drawSliced(el, it, url, size);
  let [l, r, t, b] = it.tc || [0, 1, 0, 1];
  let flipX = false, flipY = false;
  if (l > r) { [l, r] = [r, l]; flipX = true; }
  if (t > b) { [t, b] = [b, t]; flipY = true; }
  let bw = it.w / Math.max(1e-6, r - l), bh = it.h / Math.max(1e-6, b - t);
  let px = -l * bw, py = -t * bh;
  let repeat = (it.rx || it.ry) ? `${it.rx ? "repeat" : "no-repeat"} ${it.ry ? "repeat" : "no-repeat"}` : "no-repeat";
  if (it.ht || it.vt) {
    if (it.ht) { bw = size.w * it.u; px = 0; }
    if (it.vt) { bh = size.h * it.u; py = 0; }
    repeat = `${it.ht ? "repeat" : "no-repeat"} ${it.vt ? "repeat" : "no-repeat"}`;
  }
  st.backgroundImage = `url("${url}")`;
  st.backgroundSize = `${bw}px ${bh}px`;
  st.backgroundPosition = `${px}px ${py}px`;
  st.backgroundRepeat = repeat;
  const extra = [];
  if (it.vc || it.va != null) {
    if (it.vc) { st.backgroundColor = rgba(it.vc, 1); st.backgroundBlendMode = "multiply"; }
    if (it.va != null) st.opacity = (it.a == null ? 1 : it.a) * it.va;
    extra.push({ url, pos: `${px}px ${py}px`, size: `${bw}px ${bh}px`, repeat });
  }
  if (flipX || flipY) st.transform = `scale(${flipX ? -1 : 1}, ${flipY ? -1 : 1})`;
  masks(st, it, extra);
  blendAndTone(st, it);
}

// Texture coordinates that turn or slant the picture: its corners mapped onto the region's by an affine transform.
function drawTurned(el, it, url, size) {
  const [ulx, uly, llx, lly, urx, ury] = it.tc8;
  const ux = urx - ulx, uy = ury - uly, vx = llx - ulx, vy = lly - uly;
  const det = ux * vy - uy * vx || 1e-6;
  // (s, t) -> (u, v) = inverse([U V]) * ((s, t) - UL); then x = u * w, y = v * h; the picture is drawn at its own
  // pixel size, so s = X / size.w, t = Y / size.h.
  const ia = vy / det, ib = -uy / det, ic = -vx / det, id = ux / det;
  const a = (ia * it.w) / size.w, b = (ib * it.h) / size.w, c = (ic * it.w) / size.h, d = (id * it.h) / size.h;
  const e = -(ia * ulx + ic * uly) * it.w, f = -(ib * ulx + id * uly) * it.h;
  el.style.overflow = "hidden";
  const img = document.createElement("div");
  const s = img.style;
  s.position = "absolute"; s.left = "0"; s.top = "0"; s.width = size.w + "px"; s.height = size.h + "px";
  s.backgroundImage = `url("${url}")`; s.backgroundSize = "100% 100%";
  s.transformOrigin = "0 0";
  s.transform = `matrix(${a}, ${b}, ${c}, ${d}, ${e}, ${f})`;
  if (it.vc) { s.backgroundColor = rgba(it.vc, 1); s.backgroundBlendMode = "multiply"; s.maskImage = s.webkitMaskImage = `url("${url}")`; s.maskSize = s.webkitMaskSize = "100% 100%"; }
  el.appendChild(img);
  blendAndTone(el.style, it);
}

// Nine slices (SetTextureSliceMargins): the corners kept, the edges and the middle stretched or tiled.
function drawSliced(el, it, url, size) {
  const [l, t, r, b] = it.sl;
  const st = el.style;
  st.borderStyle = "solid";
  st.borderImageSource = `url("${url}")`;
  st.borderImageSlice = `${t} ${r} ${b} ${l} fill`;
  st.borderImageWidth = `${t * it.u}px ${r * it.u}px ${b * it.u}px ${l * it.u}px`;
  st.borderImageRepeat = it.slm === 1 ? "round" : "stretch";
  blendAndTone(st, it);
}

function drawLine(id, el, it) {
  const [x1, y1, x2, y2, th] = it.line;
  const len = Math.hypot(x2 - x1, y2 - y1), ang = Math.atan2(y2 - y1, x2 - x1);
  const st = el.style;
  st.left = x1 + "px"; st.top = (y1 - th / 2) + "px"; st.width = len + "px"; st.height = th + "px";
  st.transformOrigin = `0 ${th / 2}px`;
  st.transform = `rotate(${ang}rad)`;
  if (it.f) {
    st.backgroundImage = `url("${texUrl(it.f)}")`; st.backgroundSize = "100% 100%";
    if (it.vc) { st.backgroundColor = rgba(it.vc, 1); st.backgroundBlendMode = "multiply"; }
  } else {
    st.background = rgba(it.c || "ffffff", it.ca);
  }
}

function drawText(el, it) {
  el.className = "text";
  const fam = family(it.font);
  const flags = it.flags || "";
  const shadows = [];
  const ring = flags.includes("THICK") ? 2 : flags.includes("OUTLINE") ? 1 : 0;
  if (ring) {
    const k = ring * (it.size / 14);
    for (const [dx, dy] of [[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [1, 1], [-1, 1], [1, -1]]) shadows.push(`${dx * k}px ${dy * k}px 0 #000`);
  }
  if (it.sh) shadows.push(`${it.sh[0]}px ${it.sh[1]}px 0 ${rgba(it.sh[2], it.sh[3])}`);
  for (const line of it.lines) {
    for (const item of line.i) {
      const span = document.createElement("span");
      const s = span.style;
      if (item.tex != null) {
        s.left = (line.x + item.x) + "px";
        s.top = (line.y + (it.size - item.h) / 2) + "px";
        s.width = item.w + "px"; s.height = item.h + "px";
        if (item.tex) {
          s.backgroundImage = `url("${texUrl(item.tex)}")`;
          if (item.tc) {
            const [l, r, t, b] = item.tc;
            const bw = item.w / (r - l), bh = item.h / (b - t);
            s.backgroundSize = `${bw}px ${bh}px`; s.backgroundPosition = `${-l * bw}px ${-t * bh}px`;
          } else s.backgroundSize = "100% 100%";
        }
      } else {
        span.textContent = item.t;
        s.left = (line.x + item.x) + "px";
        s.top = line.y + "px";
        s.fontFamily = `"${fam}", serif`;
        s.fontSize = it.size + "px";
        s.lineHeight = it.size + "px";
        s.color = rgba(item.c || it.c, it.ca);
        if (shadows.length) s.textShadow = shadows.join(",");
        if (flags.includes("MONOCHROME")) s.webkitFontSmoothing = "none";
      }
      el.appendChild(span);
    }
  }
}

// The stage's size and zoom ----------------------------------------------------------------------------------------
function layout() {
  stage.style.width = screen.pw + "px";
  stage.style.height = screen.ph + "px";
  const z = $("#zoom").value;
  if (z === "fit") {
    fit = Math.min(viewport.clientWidth / screen.pw, viewport.clientHeight / screen.ph);
    viewport.classList.remove("zoomed");
    const left = (viewport.clientWidth - screen.pw * fit) / 2, top = (viewport.clientHeight - screen.ph * fit) / 2;
    stage.style.left = left / fit + "px"; stage.style.top = top / fit + "px";
  } else {
    fit = parseFloat(z);
    viewport.classList.add("zoomed");
    stage.style.left = "0"; stage.style.top = "0";
  }
  stage.style.zoom = fit;     // zoom, not a transform: the browser lays the stage out at its size, no seams between tiles
  if ($("#zoom").value !== "fit") {
    // a spacer so the viewport scrolls over the whole stage
    let pad = $("#pad");
    if (!pad) { pad = document.createElement("div"); pad.id = "pad"; pad.style.position = "absolute"; viewport.appendChild(pad); }
    pad.style.width = screen.pw * fit + "px"; pad.style.height = screen.ph * fit + "px"; pad.style.pointerEvents = "none";
  } else if ($("#pad")) $("#pad").remove();
}
window.addEventListener("resize", layout);

function backdrop() {
  const v = $("#backdrop").value;
  stage.className = v === "world" ? "" : v;
  stage.style.backgroundImage = v === "world" ? `url("${texUrl("Interface\\Glues\\LoadingScreens\\LoadScreenEasternKingdomWide")}")` : "";
  try { localStorage.setItem("lab.backdrop", v); } catch (e) {}
}

// Mouse and keys ---------------------------------------------------------------------------------------------------------
function point(e) {
  const r = stage.getBoundingClientRect();
  return { x: (e.clientX - r.left) / fit, y: (e.clientY - r.top) / fit };
}
const mods = (e) => ({ shift: e.shiftKey, ctrl: e.ctrlKey, alt: e.altKey, meta: e.metaKey });
const BUTTONS = ["LeftButton", "MiddleButton", "RightButton", "Button4", "Button5"];
let moveQueued = null;
stage.addEventListener("mousemove", (e) => {
  const p = point(e);
  if (inspecting) { if (!pinned) inspectAt(p); return; }
  if (moveQueued) { moveQueued.x = p.x; moveQueued.y = p.y; return; }
  moveQueued = { t: "move", x: p.x, y: p.y, mods: mods(e) };
  input.push(moveQueued);
  setTimeout(() => { moveQueued = null; }, 0);
});
stage.addEventListener("mousedown", (e) => {
  stage.focus();
  e.preventDefault();
  const p = point(e);
  if (inspecting) { pinned = !pinned; if (!pinned) inspectAt(p); return; }
  input.push({ t: "down", b: BUTTONS[e.button] || "LeftButton", x: p.x, y: p.y, mods: mods(e) });
});
window.addEventListener("mouseup", (e) => {
  if (inspecting) return;
  const p = point(e);
  input.push({ t: "up", b: BUTTONS[e.button] || "LeftButton", x: p.x, y: p.y, mods: mods(e) });
});
stage.addEventListener("contextmenu", (e) => e.preventDefault());
stage.addEventListener("mouseleave", () => input.push({ t: "leave" }));
stage.addEventListener("wheel", (e) => {
  e.preventDefault();
  const p = point(e);
  input.push({ t: "wheel", d: e.deltaY < 0 ? 1 : -1, x: p.x, y: p.y, mods: mods(e) });
}, { passive: false });

const KEYS = { Enter: "ENTER", Escape: "ESCAPE", Backspace: "BACKSPACE", Delete: "DELETE", Tab: "TAB", ArrowLeft: "LEFT",
  ArrowRight: "RIGHT", ArrowUp: "UP", ArrowDown: "DOWN", Home: "HOME", End: "END", PageUp: "PAGEUP", PageDown: "PAGEDOWN",
  " ": "SPACE", Shift: "LSHIFT", Control: "LCTRL", Alt: "LALT", Insert: "INSERT" };
function keyName(e) {
  if (KEYS[e.key]) return KEYS[e.key];
  if (/^F\d+$/.test(e.key)) return e.key;
  if (e.key.length === 1) return e.key.toUpperCase();
  return e.key.toUpperCase();
}
stage.addEventListener("keydown", (e) => {
  if (e.ctrlKey && (e.key === "v" || e.key === "c" || e.key === "x")) return;   // paste comes as a paste event
  e.preventDefault();
  const printable = e.key.length === 1 && !e.ctrlKey && !e.altKey && !e.metaKey;
  input.push({ t: "key", key: keyName(e), char: printable ? e.key : null, mods: mods(e) });
});
stage.addEventListener("keyup", (e) => { e.preventDefault(); input.push({ t: "keyup", key: keyName(e), mods: mods(e) }); });
stage.addEventListener("paste", (e) => {
  const text = (e.clipboardData || window.clipboardData).getData("text");
  for (const ch of text) input.push({ t: "key", key: ch === " " ? "SPACE" : ch.toUpperCase(), char: ch, mods: {} });
  e.preventDefault();
});

// The log ----------------------------------------------------------------------------------------------------------------
const KIND = { error: "error", warn: "warn", missing: "missing", print: "print", result: "result", note: "note", sound: "sound",
  addon: "addon", lab: "lab" };
const seen = new Map();
function log(m) {
  const kind = KIND[m.kind] || "note";
  const group = kind === "result" ? "print" : (kind === "sound" || kind === "addon" || kind === "note") ? "chat" : kind;
  const key = kind + "|" + m.text + "|" + (m.where || "");
  const ol = $("#log");
  if (seen.has(key) && (kind === "error" || kind === "warn" || kind === "missing")) {
    const li = seen.get(key);
    const n = li.querySelector(".n");
    n.dataset.n = (+n.dataset.n || 1) + 1;
    n.textContent = "×" + n.dataset.n;
    ol.appendChild(li);
    return;
  }
  const li = document.createElement("li");
  li.className = kind;
  li.dataset.group = group;
  const k = document.createElement("span"); k.className = "k"; k.textContent = kind;
  li.appendChild(k);
  li.appendChild(document.createTextNode(" " + m.text));
  if (m.where) { const w = document.createElement("span"); w.className = "where"; w.textContent = "  (" + m.where + ")"; li.appendChild(w); }
  const n = document.createElement("span"); n.className = "n"; li.appendChild(n);
  if (m.stack) { const pre = document.createElement("pre"); pre.textContent = m.stack; li.appendChild(pre); }
  li.hidden = !filterOn(group);
  ol.appendChild(li);
  seen.set(key, li);
  while (ol.children.length > 600) { const first = ol.firstChild; seen.forEach((v, k2) => { if (v === first) seen.delete(k2); }); first.remove(); }
  ol.parentElement.scrollTop = ol.parentElement.scrollHeight;
  if (kind === "error") { logCount++; $("#logCount").textContent = logCount ? `(${logCount} errors)` : ""; }
}
function filterOn(group) {
  const box = document.querySelector(`.filters input[data-kind="${group}"]`);
  return !box || box.checked;
}
document.querySelectorAll(".filters input").forEach((box) => box.addEventListener("change", () => {
  document.querySelectorAll("#log li").forEach((li) => { li.hidden = !filterOn(li.dataset.group); });
}));
$("#clearLog").onclick = () => { $("#log").textContent = ""; seen.clear(); logCount = 0; $("#logCount").textContent = ""; };

// Tabs ---------------------------------------------------------------------------------------------------------------------
document.querySelectorAll("nav button").forEach((b) => b.onclick = () => {
  document.querySelectorAll("nav button").forEach((x) => x.classList.toggle("on", x === b));
  document.querySelectorAll(".tab").forEach((t) => t.classList.toggle("on", t.id === "tab-" + b.dataset.tab));
});

// The fake server ------------------------------------------------------------------------------------------------------------
function setPeople(list) {
  const dl = $("#people");
  dl.textContent = "";
  for (const name of list) { const o = document.createElement("option"); o.value = name; dl.appendChild(o); }
}
$("#chatKind").onchange = () => { $("#chatChannelLabel").hidden = $("#chatKind").value !== "CHANNEL"; };
$("#chatForm").onsubmit = async (e) => {
  e.preventDefault();
  apply(await post("api/server", { what: "chat", kind: $("#chatKind").value, from: $("#chatFrom").value,
    text: $("#chatText").value, channel: +$("#chatChannel").value }));
  $("#chatText").value = "";
};
$("#eventForm").onsubmit = async (e) => {
  e.preventDefault();
  let args = [];
  try { args = JSON.parse($("#eventArgs").value || "[]"); } catch (err) { log({ kind: "warn", text: "the arguments are no JSON list" }); return; }
  apply(await post("api/server", { what: "event", name: $("#eventName").value.trim(), args }));
};
$("#replay").onclick = async () => apply(await post("api/server", { what: "replay" }));
$("#combat").onchange = async () => apply(await post("api/server", { what: "combat", on: $("#combat").checked }));

// The inspector ----------------------------------------------------------------------------------------------------------------
let inspectBusy = false;
async function inspectAt(p) {
  if (inspectBusy) return;
  inspectBusy = true;
  try { apply(await post("api/inspect", p)); } finally { inspectBusy = false; }
}
function showInspect(list) {
  overlay.textContent = "";
  const out = $("#inspectOut");
  out.textContent = "";
  list.forEach((d, i) => {
    if (d.px && i === 0) box(d.px, "", d.name);
    for (const r of d.regions || []) if (r.px && i === 0) box(r.px, "region");
    const div = document.createElement("div");
    div.className = "frame";
    const lines = [`<b>${esc(d.name)}</b> <span class="meta">${d.kind}${d.size ? ` · ${d.size[0]} × ${d.size[1]}` : ""} · ${d.strata || ""} ${d.level ?? ""}${d.mouse ? " · takes the mouse" : ""} · scale ${d.scale}</span>`,
      `<div class="meta">made at ${esc(d.at || "?")}</div>`];
    if (d.points && d.points.length) lines.push("<ul>" + d.points.map((p) => `<li>${esc(p)}</li>`).join("") + "</ul>");
    for (const r of d.regions || []) {
      lines.push(`<div class="region">${r.kind} ${esc(r.name)} · ${r.layer || ""}${r.size ? ` · ${r.size[0]} × ${r.size[1]}` : ""}` +
        (r.file ? `<br><code>${esc(r.file)}</code>` : "") + (r.text ? `<br>“${esc(r.text)}” ${r.font ? esc(r.font.join(" ")) : ""}` : "") +
        `<div class="meta">made at ${esc(r.at || "?")}</div></div>`);
    }
    div.innerHTML = lines.join("");
    out.appendChild(div);
  });
}
function box(px, cls, tag) {
  const b = document.createElement("div");
  b.className = "box " + cls;
  Object.assign(b.style, { left: px[0] + "px", top: px[1] + "px", width: px[2] + "px", height: px[3] + "px" });
  overlay.appendChild(b);
  if (tag) {
    const t = document.createElement("div");
    t.className = "tag"; t.textContent = tag;
    Object.assign(t.style, { left: px[0] + "px", top: Math.max(0, px[1] - 34) + "px" });
    overlay.appendChild(t);
  }
}
const esc = (s) => String(s ?? "").replace(/[&<>]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;" })[c]);
function setInspect(on) {
  inspecting = on; pinned = false;
  $("#inspect").classList.toggle("on", on);
  overlay.textContent = "";
  if (on) document.querySelector('nav button[data-tab="inspector"]').click();
}
$("#inspect").onclick = () => setInspect(!inspecting);

// The console -------------------------------------------------------------------------------------------------------------------
const history = []; let historyAt = 0;
async function runCode() {
  const code = $("#code").value;
  if (!code.trim()) return;
  history.push(code); historyAt = history.length;
  log({ kind: "note", text: "> " + code });
  apply(await post("api/run", { code }));
  $("#code").value = "";
  document.querySelector('nav button[data-tab="log"]').click();
}
$("#run").onclick = runCode;
$("#code").addEventListener("keydown", (e) => {
  if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); runCode(); }
  else if (e.key === "ArrowUp" && e.ctrlKey && historyAt > 0) { $("#code").value = history[--historyAt]; }
  else if (e.key === "ArrowDown" && e.ctrlKey && historyAt < history.length) { $("#code").value = history[++historyAt] || ""; }
});

// Header ---------------------------------------------------------------------------------------------------------------------------
async function start(body) {
  busy = true;
  try { apply(await post("api/start", body)); } finally { busy = false; }
}
$("#scene").onchange = () => { remember(); start({ scene: $("#scene").value }); };
$("#world").onchange = () => { remember(); $("#worldFile").textContent = `dev/uilab/worlds/${$("#world").value}.lua`; start({ world: $("#world").value }); };
$("#screen").onchange = async () => {
  const [pw, ph] = $("#screen").value.split("x").map(Number);
  screen.pw = pw; screen.ph = ph;
  layout(); remember();
  clearStage();
  apply(await post("api/screen", { pw, ph, scale: screen.scale }));
};
$("#scale").oninput = () => { $("#scaleOut").textContent = (+$("#scale").value).toFixed(2); };
$("#scale").onchange = async () => {
  screen.scale = +$("#scale").value; remember();
  clearStage();
  apply(await post("api/screen", { pw: screen.pw, ph: screen.ph, scale: screen.scale }));
};
$("#backdrop").onchange = backdrop;
$("#zoom").onchange = () => { layout(); remember(); };
$("#reload").onclick = () => start({});
$("#fresh").onclick = async () => { busy = true; try { apply(await post("api/reset", {})); } finally { busy = false; } };
$("#pause").onclick = () => { paused = !paused; $("#pause").classList.toggle("on", paused); };
document.addEventListener("keydown", (e) => {
  if (document.activeElement === stage || ["INPUT", "TEXTAREA", "SELECT"].includes(document.activeElement.tagName)) return;
  if (e.key === "i" || e.key === "I") setInspect(!inspecting);
  if (e.key === "p" || e.key === "P") $("#pause").click();
});

function remember() {
  try {
    localStorage.setItem("lab.view", JSON.stringify({ scene: $("#scene").value, world: $("#world").value,
      screen: $("#screen").value, scale: screen.scale, zoom: $("#zoom").value }));
  } catch (e) {}
}

async function init() {
  let saved = {};
  try { saved = JSON.parse(localStorage.getItem("lab.view") || "{}"); } catch (e) {}
  try { $("#backdrop").value = localStorage.getItem("lab.backdrop") || "world"; } catch (e) {}
  const info = await (await fetch("api/scenes")).json();
  for (const s of info.scenes) {
    const o = document.createElement("option"); o.value = s.path; o.textContent = s.name; o.title = s.about;
    $("#scene").appendChild(o);
  }
  for (const w of info.worlds) { const o = document.createElement("option"); o.value = w; o.textContent = w; $("#world").appendChild(o); }
  if (saved.scene && info.scenes.some((s) => s.path === saved.scene)) $("#scene").value = saved.scene;
  if (saved.world && info.worlds.includes(saved.world)) $("#world").value = saved.world;
  if (saved.screen) $("#screen").value = saved.screen;
  if (saved.zoom) $("#zoom").value = saved.zoom;
  const [pw, ph] = $("#screen").value.split("x").map(Number);
  screen = { pw, ph, scale: saved.scale || info.screen.scale || 0.65 };
  $("#scale").value = screen.scale; $("#scaleOut").textContent = screen.scale.toFixed(2);
  $("#worldFile").textContent = `dev/uilab/worlds/${$("#world").value}.lua`;
  layout(); backdrop();
  await start({ scene: $("#scene").value, world: $("#world").value, screen });
  stage.focus();
  requestAnimationFrame(loop);
}
init();
