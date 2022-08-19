"""Generate the icon fonts."""

import os

import fontforge

glyphs = [
    ('add', 0xe108, 'add.svg'),
    ('edit', 0xe041, 'create.svg'),
    ('delete', 0xe12c, 'trash.svg'),
    ('cancel', 0xe10f, 'close.svg'),
    ('submit', 0xe029, 'checkmark-done.svg'),
    ('reset', 0xe10e, 'arrow-undo.svg'),
    ('up', 0xe039, 'arrow-up.svg'),
    ('down', 0xe03a, 'arrow-down.svg'),
    ('settings', 0xe401, 'settings.svg'),
    ('user', 0xe402, 'person.svg'),
    ('user-add', 0xe403, 'person-add.svg'),
    ('login', 0xe404, 'login.svg'),
    ('logout', 0xe405, 'logout.svg'),
    ('search', 0xe410, 'search.svg'),
    ('language', 0xe420, 'language.svg'),
    ('home', 0xe421, 'home.svg'),
    ('star', 0xe422, 'star.svg'),
    ('heart', 0x433, 'heart.svg')
]


font = fontforge.font()

for (name, char_code, filename) in glyphs:
    print(name)
    glyph = font.createChar(char_code)
    filename = os.path.join('priv/static/icons', filename)
    glyph.importOutlines(filename)
    glyph.removeOverlap()
    left, _, right, _ = glyph.boundingBox()
    glyph.width = 900

font.removeOverlap()
font.generate('priv/static/fonts/receptar-icons.woff2')
font.generate('priv/static/fonts/receptar-icons.woff')
font.generate('priv/static/fonts/receptar-icons.ttf')
font.generate('priv/static/fonts/receptar-icons.otf')
