# Images

How a picture becomes a texture the game draws sharply and cheaply. Read this before adding or changing
any picture the addon ships (banners, icons, logos, backgrounds). Whether to draw own art at all is in
[gui-development.md](gui-development.md), *Art*: Blizzard's atlases and files come first.

The choices below were measured on 2026-10-14 on Sane UI's banners and icons (numbers in each section,
the experiments under [Tried and rejected](#tried-and-rejected)); `dev/tools/art-measure` repeats the
measurements. Use it as it stands: the format, the sizes, the encoder and the filter are decided. Measure
again only if the client changes how it draws, or for a picture unlike ours (fine lines, only text, a
photo). What was reasoned and not measured says so.

**Target:** a 4K screen. The pictures are interface parts, a small share of the screen, so a texture
sharp at 4K costs little memory in total; smaller screens draw it smaller, and the mipmaps keep it clean
far below its size.

## The recipe

1. Put the drawing into `assets/` as a PNG with transparency, large (1-2k pixels is fine). It is the
   source and never ships. The tool crops it; it needs no exact size or margin.
2. Decide the size it is drawn at in the game, in UI units (what `SetSize` gets).
3. In `dev/tools/art`, give its kind that drawn size in `KINDS` (or use a kind that has it), and add the
   picture to `PICTURES`: the file in `assets/` (a pattern), the name in `assets/optimized/`, the kind, and
   the module that ships it (`None` if none does yet).
4. Run `dev/tools/art`. It writes `assets/optimized/<name>.blp` (and `src/<Module>/Art/...` for what
   ships), and prints the texture's size, the `SetTexCoord` numbers and a check of the written file.
5. Draw it as in [Drawing it](#drawing-it): the drawn size, the printed texture coordinates, the game's
   own filter, and a fall-back when `SetTexture` reports the file missing.
6. List the file in the module's README (*Files*): what it is, that it is original art of Sane UI (the
   project's `LICENSE`, point 3), made by `dev/tools/art` from which PNG.
7. `dev/build`, then **restart** the game: the client only finds files that were there when it started.
   A changed file needs only `/reload`.

Needs Python with Pillow and NumPy, and ImageMagick 7 (`magick`).

## The format

| | What | Why |
| --- | --- | --- |
| File | **BLP2** | The client's own format: all of Blizzard's interface art is BLP (about 134,000 files in `references/BlizzardInterfaceArt`). No PNG or JPEG. Uncompressed TGA only for tiny shapes made by code (`dev/tools/tooltip-art`); a shape made by code that is drawn large (the masks of Core's round corners) is BLP2 with DXT5 and mipmaps like the art (`dev/tools/shape-art`). |
| Compression | **DXT5** (BLP encoding 2, alpha depth 8, alpha encoding 7) | Like Blizzard's logos (`Interface/GLUES/PROMOTIONS/*-SBC-LOGO.BLP`, `Glues-CharacterSelect-Logo-BG.blp`). One byte per texel, and it stays compressed on the graphics card: a quarter of TGA. Our art has soft edges, which need DXT5's full alpha; DXT1 has only on/off alpha. |
| Mipmaps | **The full chain, down to 1 x 1** | Like Blizzard's. A third more memory. They keep a picture clean when it is drawn at less than half its size (small screens, small UI scale). |
| Sides | **Powers of two, at most 1024** | Mipmaps halve evenly, DXT works in blocks of 4 x 4, Blizzard's are. |
| Name and place | `src/<Module>/Art/<name>.blp`, lower case | Not listed in the TOC: only Lua and XML are. The build copies it. |

## The size

**A UI unit** is `screen height / 768` pixels at UI scale 1 (`PixelUtil.GetPixelToUIUnitFactor` in
`Blizzard_SharedXML/PixelUtil.lua`), times the UI scale, which the player sets between 0.65 and 1.15
(`Blizzard_SettingsDefinitions_Shared/Graphics.lua`).

| Screen | Pixels per unit at scale 1 | from scale 0.65 to 1.15 |
| --- | --- | --- |
| 4K (2160 high) | **2.81** | 1.83 to 3.23 |
| 1440p | 1.88 | 1.22 to 2.16 |
| 1080p | 1.41 | 0.91 to 1.62 |

**The rule** (`side()` in the tool): each side of the texture is the smallest power of two that holds at
least **85 %** of `drawn units x 2.81` texels, at most 1024. The picture keeps its proportions in the
texture (the same texels per unit both ways); the rest of the texture stays clear and is cut off with
`SetTexCoord`.

| Texture side | Full 4K sharpness for up to | With the 85 % rule, up to |
| --- | --- | --- |
| 64 | 22 units | 26 units |
| 128 | 45 units | 53 units |
| 256 | 91 units | 107 units |
| 512 | 182 units | 214 units |
| 1024 | 364 units | 428 units |

What Sane UI has now:

| Kind | Drawn (units) | Texture | Used part, `SetTexCoord` | Of 4K's sharpness | File |
| --- | --- | --- | --- | --- | --- |
| banner | 300 x 100 | 1024 x 256 | 768 x 256, `(0, 0.75, 0, 1)` | 91 % | 342 KB |
| icon | up to 40 x 40 (not drawn yet) | 128 x 128 | all | 114 % | 22 KB |
| button | 24 x 24 (the smiley in Social, drawn by `dev/tools/smiley-art`) | 64 x 64 | all | 95 % | 6 KB |
| logo | up to 96 x 96 (not drawn yet) | 256 x 256 | all | 95 % | 86 KB |

Something drawn larger than 428 units on a side does not fit 1024: draw it in pieces, or ask first.

**Why this size and not another.** The sampler simulated as the graphics card works, the result compared
with the original drawing resized perfectly to the same pixels, on the options' dark background (the
Abilities banner; PSNR in dB, higher is closer; a few dB show in the letters' edges):

| Banner texture | Memory | 4K x1.15 | 4K x1.0 | 4K x0.65 | 1440p x1.0 | 1080p x1.0 |
| --- | --- | --- | --- | --- | --- | --- |
| 512 x 256, the 3 : 1 box squeezed in | 171 KB | 26.8 | 27.9 | 27.7 | 27.9 | 26.5 |
| 1024 x 256, the box squeezed in | 342 KB | 29.7 | 29.4 | 27.5 | 27.4 | 27.0 |
| **1024 x 256, proportions kept (768 used)** | 342 KB | 29.0 | **30.6** | **30.4** | **30.6** | **29.4** |
| 1024 x 512, proportions kept (1024 x 341 used) | 684 KB | 32.8 | 31.4 | 27.2 | 27.4 | 27.0 |

(All with `TRILINEAR`, to compare the textures alone; with the game's own filter the chosen texture gets
35.8 at 4K x0.65 and 36.0 at 1440p, see [Drawing it](#drawing-it).)

- **Never squeeze** a picture into a texture of other proportions. The graphics card picks the mipmap by
  the side that is shrunk most and blurs the other one: the same memory, 1 to 3 dB worse on every screen
  but 4K at UI scale above 1.
- **Twice the size is not better.** It wins only on 4K at UI scale above 1 and loses on every smaller
  screen, where it is drawn far below its size. The 85 % rule gives the best result over all screens.

## Drawing it

```lua
art:SetSize(300, 100)                         -- the drawn size the tool was given (or <Size> in XML)
local found = art:SetTexture("Interface\\AddOns\\SaneUI_Abilities\\Art\\banner")
art:SetTexCoord(0, 0.75, 0, 1)                -- as the tool printed, always after SetTexture
if not found then --[[ the file is missing: fall back to the game's default ]] end
```

- **Path** without the extension: `Interface\AddOns\<addon folder>\Art\<name>`.
- **Size** in units: the drawn size the tool was given. **Texture coordinates** as the tool printed, set
  right after `SetTexture`, so they hold whatever `SetTexture` does to them (not checked in the client).
- **The filter: the game's own** (pass none). Not `"TRILINEAR"`. Blizzard uses `"TRILINEAR"` only on the
  world map (`Blizzard_MapCanvas/Blizzard_MapCanvasDetailLayer.lua`), which zooms far out. Drawn at half
  its size or more, which is what the size rule gives on 4K, `TRILINEAR` blurs: it mixes in the half-sized
  copy. Below half, the mipmaps are what keeps the picture clean. Measured (PSNR in dB, as above):

  | Drawn at, of the texture's size | Game's filter, if it reads only the full picture | Game's filter, if it takes the nearest mipmap | `TRILINEAR` |
  | --- | --- | --- | --- |
  | Banner on 4K x1.0: 1.10 | 30.6 | 30.6 | 30.6 |
  | Icon on 4K x1.0: 0.88 | 30.8 | 30.8 | 28.5 |
  | Banner on 1440p x1.0: 0.73 | 36.0 | 36.0 | 30.6 |
  | Icon on 4K x0.65: 0.57 | 31.1 | 24.6 | 26.4 |
  | Banner on 1080p x0.65: 0.36 | 26.5 | 33.5 | 28.1 |
  | Icon drawn 16 units on 1080p x0.65: 0.12 | 16.2 | 24.3 | 23.6 |

  Which of the two the game's own filter is, the client does not document. On 4K at UI scale 1, the
  target, it is as sharp as `TRILINEAR` or sharper either way. Between half and three quarters of the
  size (4K at a small UI scale, 1440p) it is up to 5 dB sharper if it reads the full picture, or about
  2 dB less sharp if it takes the nearest mipmap. Below half, the nearest mipmap is mostly better, the
  full picture worse. So: the game's own filter, as Blizzard draws its own interface. A texture that is
  regularly drawn at less than a third of its size needs a smaller texture of its own for that place
  (or, last, `"TRILINEAR"`).
- **`SetTexture` returns whether it found the file** (`SimpleTextureBaseAPIDocumentation.lua`: `success`;
  Blizzard's own `LFGFrame.lua` falls back on it). Use it for the fall-back the project's *Resilience*
  principle asks for.
- **Blend mode:** the default (`"BLEND"`). The files hold plain alpha, not premultiplied.
- **Load on use:** set the texture when its window or page is first shown, not at login: then nothing is
  read for it until the player opens that window, and a hidden texture costs nothing to draw.

## What the tool does to a picture, and why

1. **Cropped** to what is not clear (alpha above 8 of 255).
2. **Solid made solid:** alpha from 250 up becomes 255. Our drawings' solid parts came with alpha 252-253
   (left by cutting the background away), which the game draws faintly see-through; fully solid blocks also
   compress best.
3. **Fitted into the drawn box** with 2 clear texels around it, so the texture's border never cuts an edge;
   at the left (banners) or in the middle (icons, logos). The box goes to the top left of the texture.
4. **Resized in premultiplied alpha with Lanczos**, every mipmap from the full drawing, not by halving the
   level before (sharper small copies, no dark fringe).
5. **Edge colour carried outwards:** a clear texel takes the colour of the edge near it (blurred colour
   divided by blurred alpha). The game's filter blends neighbouring texels; without this it blends in
   black and leaves a dark seam.
6. **Compressed** level by level by ImageMagick:
   `magick png:- -define dds:compression=dxt5 -define dds:mipmaps=0 -define dds:cluster-fit=true dds:-`,
   the blocks taken after the DDS file's 128-byte header.
7. **Written as BLP2:** `"BLP2"`, then little-endian: type 1, encoding 2, alpha depth 8, alpha encoding 7,
   has mipmaps 1 (four bytes), width, height, 16 offsets and 16 sizes of the levels (largest first, 0 for
   none); then a 1024-byte palette DXT does not use (zeros); then the levels. The first level starts at
   byte 1172.
8. **Read back** with Pillow's BLP reader and compared with what went in.

## Checking the result

- The tool prints, per file, how close the read-back is (PSNR) and the largest alpha error. Usual for our
  art: banners 25-28 dB, icons 21-23 dB, alpha off by 25 at most (DXT5 has 8 alpha steps per block of
  4 x 4; detailed art at icon size is at DXT's limit). Clearly lower means the encoder or the file is
  wrong; Pillow's own encoder gives 16 dB and alpha off by 51.
- Look at it before shipping: decode the `.blp` (Pillow opens it), cut it with the texture coordinates,
  scale it to `drawn units x 2.81` pixels with a bilinear filter, and put it on a dark background next to
  the original scaled the same way. At 4K x1.0 the two are hard to tell apart.
- How it looks in the game cannot be tested here. Say so, and leave the in-game check open.

## Memory

DXT5 is one byte per texel; the mipmaps add a third. The file holds the data as the graphics card keeps
it, so its size is about the memory it takes:

| Texture | BLP, DXT5 with mipmaps | Uncompressed TGA, no mipmaps |
| --- | --- | --- |
| 128 x 128 | 22 KB | 64 KB |
| 256 x 256 | 86 KB | 256 KB |
| 512 x 512, 1024 x 256 | 342 KB | 1 MB |
| 1024 x 512 | 684 KB | 2 MB |
| 1024 x 1024 | 1.3 MB | 4 MB |

All of Sane UI's pictures together: 1.5 MB in `assets/optimized/` (from 15.3 MB of drawings). What
ships now: one banner per options page (looked for when the options first open, drawn when its page
is), the Tooltips module's six small TGA shapes (`src/Tooltips/Art/`, 72 KB together, made by
`dev/tools/tooltip-art`), and Core's two masks for round corners (`src/Core/Art/circle.blp` and
`circle-hole.blp`, 86 KB each, made by `dev/tools/shape-art`), read when a window first draws its plate.

## Tried and rejected

Measured unless the row says *not tried* (then it is reasoned, and could be measured with
`dev/tools/art-measure` or a variant of `dev/tools/art`).

| Tried | Result |
| --- | --- |
| Pillow's DXT5 writer | Washed-out letters, red specks on gold. Icon: 16.5 dB, alpha off by 51; ImageMagick's cluster fit 23.4 dB, alpha off by 22; ImageMagick without cluster fit 20.2 dB. |
| `-define dds:weight-by-alpha=true` | No difference. |
| A picture squeezed into a texture of other proportions | 1 to 3 dB worse than keeping them, same memory (table under *The size*). |
| Banner 512 x 256 | Enlarged 1.65 times on 4K; 2.8 dB worse there. |
| Banner 1024 x 512 | Twice the memory; better only on 4K at UI scale above 1, worse on all smaller screens. |
| `"TRILINEAR"` for interface art | Up to 5 dB blurrier when drawn between half and full size. |
| Uncompressed (TGA, or BLP without compression) | *Not tried.* Four times the memory (arithmetic); DXT5 is already hard to tell from the drawing at 4K x1.0. |
| Palette BLP (256 colours) | *Not tried.* 256 colours for the gold and blue gradients would band. |

## Sources

| Source | Used for |
| --- | --- |
| `references/BlizzardInterfaceCode/.../Blizzard_SharedXML/PixelUtil.lua` | a UI unit is `768 / screen height` |
| `.../Blizzard_SettingsDefinitions_Shared/Graphics.lua` | UI scale 0.65 to 1.15 |
| `.../Blizzard_APIDocumentationGenerated/SimpleTextureBaseAPIDocumentation.lua` | `SetTexture(file, wrapH, wrapV, filterMode)` returns `success` |
| `.../Blizzard_GroupFinder/Shared/LFGFrame.lua` (line 726) | Blizzard falls back when `SetTexture` finds no file |
| `.../Blizzard_MapCanvas/Blizzard_MapCanvasDetailLayer.lua` | `TRILINEAR` only where art zooms far out |
| `dev/tools/art-measure` (the sampler as the graphics card works, PSNR against a perfect resize) | the tables under *The size* and *Drawing it* |
| `references/BlizzardInterfaceArt` (the logos' headers) | BLP2, DXT5, full mipmaps |
| `dev/tools/art` | the recipe and the format as code |
