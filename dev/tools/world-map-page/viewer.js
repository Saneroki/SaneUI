// The world map offline (dev/tools/world-map): every layer laid where the game lays it. The stage is in yards, as
// the game's grid: left = HALF - y (west to east), top = HALF - x (north to south), x north and y west. A block layer
// draws the level the game's Painted.Level would (the coarsest with as many pixels a yard as the screen, the next
// coarser under it); a zone layer lays each zone's picture on its box.
"use strict";
let world, place = null, scale = 1, panX = 0, panY = 0;
const view = document.getElementById("view"), stage = document.getElementById("stage");
const labels = document.getElementById("labels"), where = document.getElementById("where");
const CAP = 400;   // blocks in view at most, as the game's (a coarser level beyond)
const store = {
  get(key, fallback) { try { const v = localStorage.getItem(key); return v === null ? fallback : JSON.parse(v); } catch { return fallback; } },
  set(key, value) { try { localStorage.setItem(key, JSON.stringify(value)); } catch { /* the page works without */ } },
};

const span = (level) => world.tile / 4 * 2 ** level;

// A box (north, south, west, east) on the stage.
function boxStyle(box, img) {
  const [n, s, w, e] = box;
  Object.assign(img.style, { left: world.half - w + "px", top: world.half - n + "px", width: w - e + "px", height: n - s + "px" });
}

function frame() {   // the place's box on the stage: a continent's grid, an instance's frame
  if (place.kind === "continent") {
    const lands = place.zones.map((z) => z.box);
    if (!lands.length) return [world.half, -world.half, world.half, -world.half];
    return [Math.max(...lands.map((b) => b[0])), Math.min(...lands.map((b) => b[1])),
            Math.max(...lands.map((b) => b[2])), Math.min(...lands.map((b) => b[3]))];
  }
  return place.box;
}

function fit() {
  if (!view.clientWidth || !view.clientHeight) { requestAnimationFrame(fit); return; }   // not laid out yet
  const [n, s, w, e] = frame(), width = w - e, height = n - s;
  scale = Math.min(view.clientWidth / width, view.clientHeight / height) * 0.96;
  panX = view.clientWidth / 2 - (world.half - w + width / 2) * scale;
  panY = view.clientHeight / 2 - (world.half - n + height / 2) * scale;
  render();
}

function levelFor(layer, perYard, visible) {
  let level = layer.finest;
  while (level + 1 < world.levels && world.pixels / span(level + 1) >= perYard) level++;
  while (level + 1 < world.levels && visible(level) > CAP) level++;
  return level;
}

function render() {
  stage.style.transform = `translate(${panX}px, ${panY}px) scale(${scale})`;
  const x0 = -panX / scale, y0 = -panY / scale, x1 = (view.clientWidth - panX) / scale, y1 = (view.clientHeight - panY) / scale;
  const perYard = scale * (window.devicePixelRatio || 1);
  for (const layer of place.layers) {
    if (layer.kind !== "blocks") continue;
    const cells = (level) => {
      const sp = span(level);
      return [Math.floor(y0 / sp), Math.floor(y1 / sp), Math.floor(x0 / sp), Math.floor(x1 / sp)];
    };
    const visible = (level) => { const [r0, r1, c0, c1] = cells(level); return (r1 - r0 + 1) * (c1 - c0 + 1); };
    const level = levelFor(layer, perYard, visible), wanted = new Map();
    for (const lv of [level + 1, level]) {   // the coarser under, as the game draws them
      const have = layer.sets[lv];
      if (!have) continue;
      const [r0, r1, c0, c1] = cells(lv), sp = span(lv);
      for (let r = r0; r <= r1; r++) for (let c = c0; c <= c1; c++) {
        if (!have.has(r + "_" + c)) continue;
        wanted.set(`${lv}/${r}_${c}`, [lv, r, c, sp]);
      }
    }
    for (const [key, img] of layer.shown) if (!wanted.has(key)) { img.remove(); layer.shown.delete(key); }
    for (const [key, [lv, r, c, sp]] of wanted) {
      if (layer.shown.has(key)) continue;
      const img = new Image();
      img.src = `${layer.id}/${place.id}/${lv}/${r}_${c}.jpg`;
      Object.assign(img.style, { left: c * sp + "px", top: r * sp + "px", width: sp * 1.002 + "px", height: sp * 1.002 + "px",
                                 zIndex: lv === level ? 2 : 1 });
      layer.box.appendChild(img); layer.shown.set(key, img);
    }
    for (const [key, img] of layer.shown) img.style.zIndex = key.startsWith(level + "/") ? 2 : 1;
  }
  drawLabels();
}

function drawLabels() {
  labels.innerHTML = "";
  if (!document.getElementById("names").checked || place.kind !== "continent") return;
  for (const zone of place.zones) {
    const [n, s, w, e] = zone.box, width = (w - e) * scale;
    if (width < 70 || width > view.clientWidth * 3) continue;
    const div = document.createElement("div");
    div.textContent = zone.name;
    div.style.left = panX + (world.half - (w + e) / 2) * scale + "px";
    div.style.top = panY + (world.half - (n + s) / 2) * scale + "px";
    labels.appendChild(div);
  }
}

function show(next) {
  place = next;
  document.getElementById("place").value = place.key;
  document.getElementById("title").textContent = place.name;
  stage.innerHTML = "";
  const list = document.getElementById("layers");
  list.innerHTML = "";
  place.layers.forEach((layer, i) => {
    layer.box = document.createElement("div");
    layer.box.className = "layer-box";
    layer.box.style.zIndex = i;
    layer.shown = new Map();
    stage.appendChild(layer.box);
    if (layer.kind === "blocks") {
      layer.sets = {};
      for (const [lv, blocks] of Object.entries(layer.levels)) layer.sets[lv] = new Set(blocks.map(([r, c]) => r + "_" + c));
    } else {
      for (const image of layer.images) {
        const img = new Image();
        img.src = image.file;
        img.loading = "lazy";
        boxStyle(image.box, img);
        layer.box.appendChild(img);
      }
    }
    const saved = store.get(`${place.key}:${layer.name}`, i === 0 ? 100 : 0);
    const row = document.createElement("div");
    row.className = "layer";
    row.innerHTML = `<label><input type="checkbox" ${saved ? "checked" : ""}> ${layer.name}<span class="value"></span></label>
                     <input type="range" min="0" max="100" value="${saved || 50}">`;
    const box = row.querySelector("input[type=checkbox]"), range = row.querySelector("input[type=range]");
    const value = row.querySelector(".value");
    const apply = () => {
      const v = box.checked ? +range.value : 0;
      layer.box.style.opacity = v / 100; layer.box.style.display = v ? "" : "none"; value.textContent = v + "%";
      store.set(`${place.key}:${layer.name}`, v);
    };
    box.addEventListener("change", apply);
    range.addEventListener("input", () => { box.checked = true; apply(); });
    apply();
    list.appendChild(row);
  });
  fit();
}

view.addEventListener("wheel", (ev) => {
  ev.preventDefault();
  const r = view.getBoundingClientRect(), x = ev.clientX - r.left, y = ev.clientY - r.top;
  const next = Math.min(Math.max(scale * Math.exp(-ev.deltaY * 0.0015), 0.002), 40);
  panX = x - (x - panX) * next / scale; panY = y - (y - panY) * next / scale; scale = next; render();
}, { passive: false });
let drag = null;
view.addEventListener("pointerdown", (ev) => { drag = [ev.clientX - panX, ev.clientY - panY]; view.classList.add("dragging");
                                              view.setPointerCapture(ev.pointerId); });
view.addEventListener("pointermove", (ev) => {
  const r = view.getBoundingClientRect(), sx = (ev.clientX - r.left - panX) / scale, sy = (ev.clientY - r.top - panY) / scale;
  const x = world.half - sy, y = world.half - sx;
  const here = place.kind === "continent"
    ? place.zones.filter((z) => z.box[0] >= x && x >= z.box[1] && z.box[2] >= y && y >= z.box[3])
        .sort((a, b) => (a.box[2] - a.box[3]) * (a.box[0] - a.box[1]) - (b.box[2] - b.box[3]) * (b.box[0] - b.box[1]))
        .map((z) => z.name)
    : [];
  where.textContent = `x ${x.toFixed(0)}  y ${y.toFixed(0)}  tile ${Math.floor(sy / world.tile)},${Math.floor(sx / world.tile)}`
                      + (here.length ? `  ${here.slice(0, 2).join(" / ")}` : "");
  if (drag) { panX = ev.clientX - drag[0]; panY = ev.clientY - drag[1]; render(); }
});
view.addEventListener("pointerup", () => { drag = null; view.classList.remove("dragging"); });
window.addEventListener("resize", render);
document.getElementById("fit").addEventListener("click", fit);
document.getElementById("names").addEventListener("change", drawLabels);

fetch("world.json").then((r) => r.json()).then((data) => {
  world = data;
  const places = [
    ...world.continents.map((c) => ({ ...c, kind: "continent", key: "c" + c.id })),
    ...world.instances.map((i) => ({ ...i, id: i.name, kind: "instance", key: i.name, name: i.title,
                                     layers: i.layers.map((l) => ({ ...l, kind: "images", images: [{ file: l.file, box: l.box }] })) })),
  ];
  const only = new URLSearchParams(location.search).get("only");   // one kind alone (world-map serve --only)
  const select = document.getElementById("place");   // the world's continents, then every instance: views of their own
  for (const [label, kind] of [["World map", "continent"], ["Instances", "instance"]].filter(([, k]) => !only || k === only)) {
    const group = document.createElement("optgroup");
    group.label = label;
    for (const p of places.filter((p) => p.kind === kind).sort((a, b) => kind === "instance" ? a.name.localeCompare(b.name) : 0)) {
      const option = document.createElement("option");
      option.value = p.key; option.textContent = p.name;
      group.appendChild(option);
    }
    if (group.children.length) select.appendChild(group);
  }
  select.addEventListener("change", () => {
    const p = places.find((p) => p.key === select.value);
    show(p); store.set("place", p.key);
  });
  const shown = places.filter((p) => !only || p.kind === only);
  if (only === "instance") document.title = document.querySelector("h1").textContent = "Instance Maps Offline";
  show(shown.find((p) => p.key === store.get("place", "c0")) || shown[0]);
});
