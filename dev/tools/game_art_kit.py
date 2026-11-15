"""The kit (Saneroki, 2026-11-15): Saneroki's references for Sane UI's new look, each rebuilt from Forever's own pieces.

dev/tools/game-art kit (saneui makegamekit) writes the pictures into assets/generated/game-art/kit/, the page /art/kit/
on the tools' web server: one picture per reference, his screenshot beside it where there is one
(kit/references/, kept from the chat), and board.png with all of them.

Every piece is cut from the newest export's sheets as the catalogue cuts them (dev/tools/game-art), but here with all
of an atlas' sizes: Forever's own member of a name first, the largest, drawn at a 2x screen (the size Saneroki's
screenshots are taken at). The layouts follow Blizzard's templates of the export (the XML named at each part), so
the pictures show what the game itself would draw. The text is the game's own Friz Quadrata, pulled from the game's
install into game-art/fonts/fonts/frizqt__.ttf (file 615960); a stand-in serif when it is missing.
"""
import textwrap
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

S = 2                                    # a 2x screen: Forever's -2x pictures at their own pixels
NAV = (214, 179, 128, 255)               # Forever's top bar text: CAMELOT_NAV_BAR_TEXT_COLOR_NORMAL
NAV_HI = (255, 226, 183, 255)            # and _HIGHLIGHT
GOLD = (255, 209, 0, 255)                # NORMAL_FONT_COLOR
WHITE = (255, 255, 255, 255)
GREY = (128, 128, 128, 255)
WARRIOR = (199, 156, 110, 255)
HUNTER = (171, 212, 115, 255)
GREEN = (26, 255, 26, 255)
SHOP_BLUE = (63, 160, 200, 255)          # the shop's backdrop behind the grey box, for comparison


class Kit:
    """Forever's pieces with every size the tables give them, and the means to lay them out."""

    def __init__(self, ga, out):
        self.ga = ga
        self.art = ga.Art()
        self.out = out
        self.export_art = ga.export.required("art")
        self.code = ga.export.required("code")
        friz = out.parent / "fonts" / "fonts" / "frizqt__.ttf"
        self.font_file = str(friz) if friz.is_file() else "/usr/share/fonts/caladea/Caladea-Regular.ttf"
        if not friz.is_file():
            print(f"  the game's font is not in {friz}: a stand-in writes the words")
        sheets = {int(r["ID"]): int(r["FileDataID"]) for r in ga.rows_of(self.art.tables / "UiTextureAtlas.csv")}
        names = {int(r["ID"]): r["Name"].lower() for r in ga.rows_of(self.art.tables / "UiTextureAtlasElement.csv")}
        self.members = {}
        for r in ga.rows_of(self.art.tables / "UiTextureAtlasMember.csv"):
            sheet = sheets.get(int(r["UiTextureAtlasID"]))
            if sheet is None or not self.art.sheet_file(sheet):
                continue
            name = names.get(int(r["UiTextureAtlasElementID"])) or r["CommittedName"].lower()
            self.members.setdefault(name, []).append({
                "sheet": sheet, "w": int(r["Width"]), "h": int(r["Height"]), "ow": int(r["OverrideWidth"] or 0),
                "oh": int(r["OverrideHeight"] or 0), "forever": sheet not in self.art.retail,
                "box": (int(r["CommittedLeft"]), int(r["CommittedTop"]), int(r["CommittedRight"]),
                        int(r["CommittedBottom"]))})

    # The pieces ----------------------------------------------------------------------------------------------------
    def piece(self, name, scale=S):
        """Forever's largest picture of an atlas, drawn at scale times the size the game gives it on a 1x screen:
        its override size, else its smallest member; a name with one size only is taken as drawn at 2x."""
        found = self.members[name.lower()]
        own = [m for m in found if m["forever"]] or found
        big = max(own, key=lambda m: m["w"])
        small = min(own, key=lambda m: m["w"])
        image = self.art.sheet(big["sheet"]).crop(big["box"])
        if small["ow"]:
            w, h = small["ow"], small["oh"]
        elif len(own) == 1:
            w, h = big["w"] / 2, big["h"] / 2
        else:
            w, h = small["w"], small["h"]
        size = (max(1, round(w * scale)), max(1, round(h * scale)))
        return image.resize(size, Image.LANCZOS) if image.size != size else image

    def raw(self, name):
        """A piece at its own pixels, the member the catalogue keeps."""
        return self.art.cut(self.art.pieces[name.lower()])

    def slices(self, name):
        return self.art.slices.get(self.art.pieces[name.lower()]["element"])

    def file(self, path):
        return self.art.read(self.export_art / path)

    # Slicing and words ---------------------------------------------------------------------------------------------
    @staticmethod
    def three(image, left, right, width, height=None):
        """A three-slice across: the ends kept, the middle stretched."""
        h = height or image.height
        if h != image.height:
            image = image.resize((image.width, h), Image.LANCZOS)
        out = Image.new("RGBA", (width, h), (0, 0, 0, 0))
        out.alpha_composite(image.crop((0, 0, left, h)), (0, 0))
        out.alpha_composite(image.crop((image.width - right, 0, image.width, h)), (width - right, 0))
        if width - left - right > 0:
            middle = image.crop((left, 0, image.width - right, h)).resize((width - left - right, h), Image.LANCZOS)
            out.alpha_composite(middle, (left, 0))
        return out

    @staticmethod
    def nine(image, left, top, right, bottom, width, height):
        """A nine-slice: the corners kept, the edges and the middle stretched."""
        out = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        w, h = image.size
        xs = ((0, left, 0, left), (left, w - right, left, width - right), (w - right, w, width - right, width))
        ys = ((0, top, 0, top), (top, h - bottom, top, height - bottom), (h - bottom, h, height - bottom, height))
        for sx0, sx1, dx0, dx1 in xs:
            for sy0, sy1, dy0, dy1 in ys:
                if sx1 > sx0 and sy1 > sy0 and dx1 > dx0 and dy1 > dy0:
                    part = image.crop((sx0, sy0, sx1, sy1))
                    if part.size != (dx1 - dx0, dy1 - dy0):
                        part = part.resize((dx1 - dx0, dy1 - dy0), Image.LANCZOS)
                    out.alpha_composite(part, (dx0, dy0))
        return out

    def font(self, size):
        return ImageFont.truetype(self.font_file, size)

    def text(self, canvas, xy, words, size, color, anchor="mm", outline=0, shadow=(S, S)):
        """Words in the game's font with its black shadow and, for the outlined fonts, a thin outline."""
        layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(layer)
        font = self.font(size)
        if shadow:
            draw.text((xy[0] + shadow[0], xy[1] + shadow[1]), words, font=font, fill=(0, 0, 0, 255), anchor=anchor,
                      stroke_width=outline, stroke_fill=(0, 0, 0, 255))
        draw.text(xy, words, font=font, fill=color, anchor=anchor, stroke_width=outline, stroke_fill=(0, 0, 0, 255))
        canvas.alpha_composite(layer)

    @staticmethod
    def label(canvas, xy, words, size=20, color=(205, 190, 160, 255)):
        font = ImageFont.truetype("/usr/share/fonts/noto/NotoSans-Regular.ttf", size)
        ImageDraw.Draw(canvas).text(xy, words, font=font, fill=color)

    def strip(self, pictures, gap=8 * S, width=4000):
        return self.ga.strip(pictures, gap=gap, width=width)

    # The parts -----------------------------------------------------------------------------------------------------
    def red_button(self, width, words="", state="", gold=False, size=12):
        """SharedButtonTemplate (BigRedThreeSliceButtonTemplate): 128-RedButton's three slices fitted to a 42 px
        high button; its disabled state is the grey button. 128-GoldRedButton is the same with a golden rim."""
        kit = "128-goldredbutton" if gold else "128-redbutton"
        tail = f"-{state}" if state else ""
        h = 42 * S
        left, middle, right = (self.piece(f"{kit}-left{tail}", 1), self.piece(f"_{kit}-center{tail}", 1),
                               self.piece(f"{kit}-right{tail}", 1))
        k = h / left.height
        left = left.resize((round(left.width * k), h), Image.LANCZOS)
        right = right.resize((round(right.width * k), h), Image.LANCZOS)
        middle = middle.resize((max(1, width - left.width - right.width), h), Image.LANCZOS)
        out = Image.new("RGBA", (width, h), (0, 0, 0, 0))
        out.alpha_composite(left, (0, 0))
        out.alpha_composite(middle, (left.width, 0))
        out.alpha_composite(right, (width - right.width, 0))
        if words:
            self.text(out, (width // 2, h // 2 + 1), words, size * S, GREY if state == "disabled" else GOLD)
        return out

    def red_square(self, atlas):
        """UIButtonTemplate with a 128-RedButton art kit: the character list's delete and restore."""
        return self.piece(atlas, 1).resize((42 * S, 42 * S), Image.LANCZOS)

    def square(self, icon=None, kit="common-button-square-gray-up", size=42, icon_size=24):
        """CommonSquareIconButtonTemplate: the grey square with a golden rim and a yellow icon (the character
        select's rotate buttons, the character window's zoom and rotate)."""
        out = self.piece(kit, 1).resize((size * S, size * S), Image.LANCZOS)
        if icon:
            picture = self.piece(icon, 1).resize((icon_size * S, icon_size * S), Image.LANCZOS)
            out.alpha_composite(picture, ((out.width - picture.width) // 2, (out.height - picture.height) // 2))
        return out

    def heavybronze(self, width, height):
        """CharacterSelectListBGTemplate (Camelot): the plate, the border 9 and 15 px outside it, two brackets."""
        pad_x, pad_y = 9 * S, 15 * S
        out = Image.new("RGBA", (width + 2 * pad_x, height + 2 * pad_y), (0, 0, 0, 0))
        out.alpha_composite(self.piece("heavybronze-frame-background").resize((width, height), Image.LANCZOS),
                            (pad_x, pad_y))
        border = self.piece("heavybronze-frame-basic")
        out.alpha_composite(self.nine(border, *self.slices("heavybronze-frame-basic"), out.width, out.height))
        top, bottom = self.piece("heavybronze-vert-cornerbracket-tr"), self.piece("heavybronze-vert-cornerbracket-br")
        out.alpha_composite(top, (out.width - top.width, 0))
        out.alpha_composite(bottom, (out.width - bottom.width, out.height - bottom.height))
        return out, (pad_x, pad_y)

    def search_box(self, width, words="Search"):
        """The character list's search box: glues-characterSelect-searchbar (4 px ends) and its glass."""
        h = 24 * S
        out = self.three(self.piece("glues-characterselect-searchbar"), 4 * S, 4 * S, width, h)
        glass = self.piece("glues-characterselect-icon-search")
        out.alpha_composite(glass, (8 * S, (h - glass.height) // 2))
        self.text(out, (8 * S + glass.width + 6 * S, h // 2), words, 12 * S, GREY, anchor="lm", shadow=None)
        return out

    def top_bar(self, names=("SHOP", "MENU", "RULESET"), selected=None, width=150):
        """CharacterSelectNavBar (Camelot): the outer buttons' textures reach 27 px past them, a divider between
        two buttons, the selected one lit from below; its words GlueFontNormal in Forever's own colours."""
        h, over = 64 * S, 27 * S
        out = Image.new("RGBA", (width * S * len(names) + 2 * over, h), (0, 0, 0, 0))
        last = len(names) - 1
        for i in range(len(names)):
            x = over + i * width * S
            if i == 0:
                out.alpha_composite(self.three(self.piece("glues-characterselect-tophud-left-bg"), 100, 8,
                                               width * S + over, h), (x - over, 0))
            elif i == last:
                out.alpha_composite(self.three(self.piece("glues-characterselect-tophud-right-bg"), 8, 100,
                                               width * S + over, h), (x, 0))
            else:
                out.alpha_composite(self.piece("glues-characterselect-tophud-middle-bg").resize((width * S, h)), (x, 0))
        for i, name in enumerate(names):
            x = over + i * width * S
            if i == selected:
                kind = "left" if i == 0 else "right" if i == last else "middle"
                lit = self.piece(f"glues-characterselect-tophud-selected-{kind}")
                cut = self.slices(f"glues-characterselect-tophud-selected-{kind}") or (8, 0, 8, 0)
                out.alpha_composite(self.three(lit, cut[0], cut[2], width * S - 7 * S, 44 * S),
                                    (x + (4 * S if i == 0 else 0), h - 51 * S))
            if i < last:
                bar = self.piece("glues-characterselect-tophud-bg-divider")
                out.alpha_composite(bar, (x + width * S - bar.width // 2, (h - bar.height) // 2))
            color = NAV_HI if i == selected else NAV
            cx, cy = x + width * S // 2, h // 2 - 2 * S
            if name == "SHOP":
                icon = self.piece("glues-characterselect-iconshop" + ("-hover" if i == selected else ""))
                icon = icon.resize((24 * S, 24 * S))
                left = cx - (self.font(15 * S).getlength(name) + icon.width + 4 * S) / 2
                out.alpha_composite(icon, (int(left), cy - icon.height // 2))
                self.text(out, (int(left + icon.width + 4 * S), cy), name, 15 * S, color, anchor="lm", outline=1)
            else:
                self.text(out, (cx, cy), name, 15 * S, color, outline=1)
        return out

    def card(self, name, cls, zone, level, color, selected=False):
        """A character card (glues-characterselect-card-singles, -selected with its glow)."""
        plain = self.piece("glues-characterselect-card-singles")
        out = self.piece("glues-characterselect-card-selected" if selected else "glues-characterselect-card-singles")
        pad_x, pad_y = (out.width - plain.width) // 2, (out.height - plain.height) // 2
        x, y = pad_x + 22 * S, pad_y + 14 * S
        self.text(out, (x, y), name, 18 * S, GOLD, anchor="la", outline=1)
        self.text(out, (x, y + 26 * S), level, 15 * S, WHITE, anchor="la")
        self.text(out, (x + int(self.font(15 * S).getlength(level)), y + 26 * S), cls, 15 * S, color, anchor="la")
        self.text(out, (x, y + 48 * S), zone, 15 * S, GREY, anchor="la")
        emblem = self.piece("glues-characterselect-icon-faction-alliance" + ("-selected" if selected else ""))
        out.alpha_composite(emblem, (out.width - pad_x - emblem.width - 24 * S, (out.height - emblem.height) // 2))
        return out

    def character_list(self):
        """CharacterSelectListTemplate: the search box, the cards, Create Character with delete and restore."""
        w, h = 386 * S, 560 * S
        frame, (px, py) = self.heavybronze(w, h)
        frame.alpha_composite(self.search_box(330 * S), (px + 19 * S, py + 25 * S))
        y = py + 67 * S
        people = (("Sane Lunatic", "Warrior", "Duskwood", "Level 37 ", WARRIOR),
                  ("Backseat Driver", "Hunter", "Dun Morogh", "Level 1 ", HUNTER))
        for i, (name, cls, zone, level, color) in enumerate(people):
            card = self.card(name, cls, zone, level, color, selected=(i == 0))
            frame.alpha_composite(card, (px + (w - card.width) // 2 - 6 * S, y - (12 * S if i == 0 else 0)))
            y += 100 * S
        create = self.red_button(205 * S, "Create Character", size=13)
        y = py + h - 62 * S
        frame.alpha_composite(create, (px + 30 * S, y))
        frame.alpha_composite(self.red_square("128-redbutton-delete"), (px + 36 * S + create.width, y))
        frame.alpha_composite(self.red_square("128-redbutton-refresh"), (px + 84 * S + create.width, y))
        return frame

    def squares(self):
        icons = ("common-icon-zoomin", "common-icon-zoomout", "common-icon-rotateleft", "common-icon-rotateright",
                 "common-icon-undo")
        row = [self.square(i) for i in icons] + [self.square("common-icon-rotateleft", "common-button-square-gray-down")]
        return self.strip(row)

    def important(self):
        rows = [
            self.strip([self.red_button(205 * S, "Create Character", size=13)] + [self.red_square(f"128-redbutton-{k}")
                       for k in ("delete", "refresh", "exit", "plus", "minus")], gap=6 * S),
            self.strip([self.red_button(130 * S, "Yes"), self.red_button(130 * S, "No"),
                        self.red_button(130 * S, "Pressed", state="pressed"),
                        self.red_button(130 * S, "Disabled", state="disabled")], gap=10 * S),
            self.strip([self.red_button(160 * S, "Accept", gold=True),
                        self.red_button(160 * S, "Gold and red", gold=True, state="pressed"),
                        self.red_button(160 * S, "Disabled", gold=True, state="disabled")], gap=10 * S),
        ]
        return self.strip(rows, gap=12 * S, width=rows[0].width + 10)

    def mode_card(self, title, glow=False):
        """SuperDistrictButtonTemplate, laid out as Forever draws it (measured on Saneroki's screenshot): the title,
        a round icon in Mode-Selection-Ring, the words; Mode-Selection-Card-Regular-yellow-glow when picked."""
        out = self.piece("mode-selection-card-regular")
        if glow:
            light = self.piece("mode-selection-card-regular-yellow-glow")
            base = Image.new("RGBA", light.size, (0, 0, 0, 0))
            base.alpha_composite(out, ((light.width - out.width) // 2, (light.height - out.height) // 2))
            base.alpha_composite(light)
            out = base
        self.text(out, (out.width // 2, 130), title, 18 * S, GOLD)
        ring = self.piece("mode-selection-ring")
        rx, ry = (out.width - ring.width) // 2, 270 - ring.height // 2
        icon = self.file("Interface/ICONS/Ability_Warrior_BattleShout.blp")
        icon = icon.resize((ring.width - 24, ring.height - 24), Image.LANCZOS)
        mask = Image.new("L", icon.size, 0)
        ImageDraw.Draw(mask).ellipse((0, 0, icon.width - 1, icon.height - 1), fill=255)
        icon.putalpha(mask)
        out.alpha_composite(icon, (rx + 12, ry + 12))
        out.alpha_composite(ring, (rx, ry))
        words = ("This ruleset has strict", "naming conventions and", "behavior rules for players",
                 "interested in immersing", "themselves as a character", "in a fantasy-based world.")
        for i, line in enumerate(words):
            self.text(out, (out.width // 2, 445 + i * 33), line, 15 * S, WHITE)
        return out

    def grey_box(self, backdrop):
        """The shop's details box (CatalogShopDetailsFrame): generic-frame-chamfered-12d-2o, 20 px slices, 70%
        black inside, with a grey (disabled) and a red button."""
        w, h = 320 * S, 230 * S
        out = Image.new("RGBA", (w + 40 * S, h + 40 * S), backdrop)
        out.alpha_composite(self.nine(self.raw("generic-frame-chamfered-12d-2o"), 20, 20, 20, 20, w, h), (20 * S, 20 * S))
        cx = out.width // 2
        self.text(out, (cx, 52 * S), "Sane UI", 26 * S, WHITE)
        self.text(out, (cx, 88 * S), "A section that is no window", 12 * S, GOLD)
        self.text(out, (cx, 112 * S), "Text and buttons inside it", 12 * S, GREY)
        cancel = self.red_button(130 * S, "Cancel", state="disabled", size=14)
        details = self.red_button(130 * S, "Details", size=14)
        y = 20 * S + h - cancel.height - 18 * S
        out.alpha_composite(cancel, (36 * S, y))
        out.alpha_composite(details, (20 * S + w - 16 * S - details.width, y))
        return out

    def shop_header(self, width):
        """CatalogShop's header: shop-header-menu-bg (left, middle, right), a selected tab with its golden line, a
        divider, and the shared search box (common-search-border, common-search-magnifyingglass)."""
        h = 51 * S
        out = Image.new("RGBA", (width, h + 6 * S), (0, 0, 0, 0))
        left, right = self.piece("shop-header-menu-bg-left"), self.piece("shop-header-menu-bg-right")
        middle = self.piece("shop-header-menu-bg-middle").resize((max(1, width - left.width - right.width), left.height))
        out.alpha_composite(left, (0, 0))
        out.alpha_composite(middle, (left.width, 0))
        out.alpha_composite(right, (width - right.width, 0))
        tab = 150 * S
        lit = self.piece("shop-header-menu-selected-left")
        out.alpha_composite(self.three(lit, lit.width - 2, 2, tab, 47 * S), (60 * S, h - 47 * S))
        self.text(out, (60 * S + tab // 2, h // 2 + 2 * S), "GAME UPGRADES", 13 * S, WHITE)
        divider = self.piece("shop-header-menu-bg-divider")
        out.alpha_composite(divider, (60 * S + tab, (h - divider.height) // 2))
        self.text(out, (60 * S + tab + 80 * S, h // 2 + 2 * S), "MOUNTS", 13 * S, GOLD)
        bw, bh = 200 * S, 20 * S
        ends = [self.piece(f"common-search-border-{k}") for k in ("left", "middle", "right")]
        box = Image.new("RGBA", (bw, bh), (0, 0, 0, 0))
        a, b = ends[0].resize((ends[0].width, bh)), ends[2].resize((ends[2].width, bh))
        box.alpha_composite(a, (0, 0))
        box.alpha_composite(ends[1].resize((bw - a.width - b.width, bh)), (a.width, 0))
        box.alpha_composite(b, (bw - b.width, 0))
        glass = self.piece("common-search-magnifyingglass").resize((14 * S, 14 * S))
        box.alpha_composite(glass, (5 * S, (bh - glass.height) // 2))
        self.text(box, (22 * S, bh // 2), "Search", 10 * S, GREY, anchor="lm", shadow=None)
        out.alpha_composite(box, (width - bw - 20 * S, (h - bh) // 2))
        return out

    def shop_window(self):
        """The shop's top: PortraitFrameTemplate (the catalogue's window #3) with the header inside it."""
        layout = self.ga.layouts(self.code)["PortraitFrameTemplate"]
        window = self.ga.window(self.art, layout, width=960 * S, height=150 * S, margin=60)
        if window is None:
            return self.shop_header(900 * S)
        window.alpha_composite(self.shop_header(900 * S), (60 + 30 * S, 60 + 24 * S))
        self.text(window, (window.width // 2, 60 + 12 * S), "Sane UI", 13 * S, GOLD)
        return window.crop((0, 0, window.width, 60 + 100 * S))

    def loading_bar(self, width=700 * S, words=None, fill=0.0, buttons=False):
        """The loading screen's bar (Interface/Glues/LoadingBar, Loading-BarBorder-Frame-v2 over -Background-v2),
        40 px ends kept: empty, as a headline, with buttons inside, filled."""
        frame = self.file("Interface/GLUES/LoadingBar/Loading-BarBorder-Frame-v2.blp")
        back = self.file("Interface/GLUES/LoadingBar/Loading-BarBorder-Background-v2.blp")
        h, end = 32 * S, 40 * S
        frame = frame.resize((round(frame.width * h / frame.height), h), Image.LANCZOS)
        back = back.resize((round(back.width * h / back.height), h), Image.LANCZOS)
        out = Image.new("RGBA", (width, h), (0, 0, 0, 0))
        out.alpha_composite(self.three(back, end, end, width, h))
        if fill:
            bar = self.file("Interface/GLUES/LoadingBar/Loading-BarFill.blp")
            bar.putalpha(255)               # its picture has no alpha of its own
            bar = bar.resize((int((width - 44 * S) * fill), 14 * S))
            out.alpha_composite(bar, (22 * S, (h - bar.height) // 2))
        out.alpha_composite(self.three(frame, end, end, width, h))
        if words:
            self.text(out, (width // 2, h // 2), words, 14 * S, GOLD)
        if buttons:
            for i, icon in enumerate(("common-icon-zoomin", "common-icon-rotateleft", "common-icon-undo")):
                button = self.square(icon, size=22, icon_size=14)
                out.alpha_composite(button, (width - 40 * S - (i + 1) * (button.width + 3 * S),
                                             (h - button.height) // 2))
        return out

    def character_window(self):
        """The character window's pieces (Camelot's CharacterFrame and PaperDollFrame): a stats column of
        UI-Character-Info-Title heads and -Line-Bounce rows on -Stat-BG; the slots, the tabs, the side tabs, the
        small buttons and common-insideframe beside it."""
        w = 200 * S
        column = self.piece("ui-character-info-stat-bg").resize((w + 20 * S, 280 * S))
        y, band = 6 * S, 0
        rows = (("General", None), ("Health:", "1,605"), ("Rage:", "100"), ("Movement Speed:", "102%"),
                ("Primary Attributes", None), ("Strength:", "113"), ("Agility:", "92"), ("Stamina:", "124"))
        for name, value in rows:
            if value is None:
                head = self.piece("ui-character-info-title")
                column.alpha_composite(head, ((column.width - head.width) // 2, y))
                self.text(column, (column.width // 2, y + head.height // 2 + S), name, 13 * S, WHITE)
                y, band = y + head.height + 4 * S, 0
                continue
            if band % 2 == 0:
                column.alpha_composite(self.piece("ui-character-info-line-bounce").resize((w, 18 * S)), (10 * S, y))
            self.text(column, (14 * S, y + 9 * S), name, 13 * S, GOLD, anchor="lm")
            green = name in ("Strength:", "Agility:", "Stamina:")
            self.text(column, (w + 6 * S, y + 9 * S), value, 13 * S, GREEN if green else WHITE, anchor="rm")
            y, band = y + 22 * S, band + 1
        pieces = [
            self.strip([self.piece("ui-character-info-gearslot") for _ in range(3)], gap=4 * S),
            self.strip([self.piece("ui-character-info-stattab-selected")] + [self.piece("ui-character-info-stattab")] * 2,
                       gap=6 * S),
            self.strip([self.piece("common-sidetab-selected")] + [self.piece("common-sidetab")] * 2, gap=6 * S),
            self.strip([self.piece("common-button-collapseexpand-up"), self.square("common-icon-zoomin"),
                        self.square("common-icon-rotateleft")], gap=6 * S),
            self.nine(self.piece("common-insideframe"), 53, 53, 53, 53, 220 * S, 140 * S),
        ]
        return self.strip([column, self.strip(pieces, gap=10 * S, width=230 * S)], gap=20 * S)

    # The board -----------------------------------------------------------------------------------------------------
    def section(self, title, words, pictures, reference=None, height=None):
        pictures = list(pictures)
        found = sorted((self.out / "references").glob(f"{reference}-*")) if reference else []
        if found:
            ref = Image.open(found[0]).convert("RGBA")
            if height:
                ref = ref.resize((round(ref.width * height / ref.height), height), Image.LANCZOS)
            pictures.insert(0, ref)
        body = self.strip(pictures, gap=30, width=3000)
        lines = textwrap.wrap(words, 150)
        top = 66 + 28 * len(lines)
        out = Image.new("RGBA", (max(body.width, 1600) + 40, body.height + top + 14), (14, 12, 10, 255))
        self.label(out, (20, 14), title, 34, (240, 220, 170, 255))
        for i, line in enumerate(lines):
            self.label(out, (20, 58 + 28 * i), line)
        out.alpha_composite(body, (20, top))
        return out

    def make(self):
        mine = "your screenshot, then "
        parts = [
            ("Top bar of a full screen", mine + "glues-characterselect-tophud-* (#59-68) with its dividers, the words "
             "Friz Quadrata in Forever's (0.84, 0.70, 0.50); MENU selected below",
             [self.top_bar(), self.top_bar(selected=1)], 1, None),
            ("Windows: the character list", mine + "heavybronze-frame-basic, -frame-background, -vert-cornerbracket (#1, "
             "#29-40), the search box glues-characterselect-searchbar with its glass (#58, #52), the cards (#45)",
             [self.character_list()], 2, 1300),
            ("Normal buttons", mine + "common-button-square-gray-up and -down (#167) with common-icon-zoomin, -zoomout, "
             "-rotateleft, -rotateright, -undo; the last one pressed", [self.squares()], 3, 84),
            ("Important buttons", mine + "128-RedButton (#148, #151, #155) and its squares (#149 delete, #154 refresh, "
             "#150 exit, #153 plus, #152 minus); its disabled state is the grey button; 128-GoldRedButton below",
             [self.important()], 4, 114),
            ("Angled corners: the ruleset card", mine + "Mode-Selection-Card-Regular (#446) with Mode-Selection-Ring "
             "(#698); with its yellow glow (#447) when picked", [self.mode_card("Roleplay"),
                                                                 self.mode_card("Normal", glow=True)], 5, 1060),
            ("The grey box: sections that are no window", "generic-frame-chamfered-12d-2o, 20 px slices: 70% black "
             "inside, so the shop's blue shows through (left); over Forever's bronze plate (right)",
             [self.grey_box(SHOP_BLUE), self.grey_box((44, 33, 24, 255))], None, None),
            ("The shop's title bar", "PortraitFrameTemplate (#3) with shop-header-menu-* and the shared search box "
             "(common-search-border, common-search-magnifyingglass)", [self.shop_window()], None, None),
            ("The loading bar as a headline", "Interface/Glues/LoadingBar/Loading-BarBorder-Frame-v2 over "
             "-Background-v2: empty, with a headline, with buttons inside, filled",
             [self.strip([self.loading_bar(), self.loading_bar(words="Headline"),
                          self.loading_bar(words="Buttons inside", buttons=True), self.loading_bar(fill=0.2)],
                         gap=16, width=1500)], None, None),
            ("The character window", "UI-Character-Info-Title (#364), -Line-Bounce (#362), -Stat-BG (#559), -GearSlot "
             "(#403), -StatTab (#563), common-sidetab (#219), common-button-collapseexpand (#158), "
             "common-insideframe (#70)", [self.character_window()], None, None),
        ]
        self.out.mkdir(parents=True, exist_ok=True)
        made = []
        for i, (title, words, pictures, reference, height) in enumerate(parts, 1):
            picture = self.section(f"{i}  {title}", words, pictures, reference, height)
            picture.save(self.out / f"{i}.png")
            made.append((i, title, picture))
        board = self.strip([p for _, _, p in made], gap=0, width=max(p.width for _, _, p in made))
        board.save(self.out / "board.png")
        items = "\n".join(f'<h2 id="k{i}">{i}. {title}</h2><img src="{i}.png" alt="{title}">' for i, title, _ in made)
        (self.out / "index.html").write_text(PAGE.replace("ITEMS", items), encoding="utf-8")
        print(f"  {len(made)} parts and board.png in {self.out}")


PAGE = """<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>The kit</title>
<style>body{background:#0e0c0a;color:#e8dcc0;font:16px sans-serif;margin:16px}
h1{font-weight:400}h2{font-weight:400;margin:32px 0 8px}img{max-width:100%;height:auto;display:block}</style></head>
<body><h1>The kit: your references, rebuilt from Forever's own art</h1>
<p>Each part beside your screenshot, at a 2x screen. Numbers are the catalogue's (/art/).</p>
ITEMS
</body></html>
"""


def make(ga, out):
    Kit(ga, out).make()
