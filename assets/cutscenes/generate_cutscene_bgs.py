#!/usr/bin/env python3
"""Gera backgrounds pixel-art da cutscene, SEM dependências (encoder PNG stdlib).
Rode: python3 generate_cutscene_bgs.py

- call_bg.png    : celular tocando (tela "Carlos chamando").
- office_bg.png  : escritório da Capim (empresa de tech, SP) — cores da marca
                   (verde #BEE41E + roxo #33215E) e o símbolo "C" da Capim na parede.

Baixa resolução (90x160, 9:16); o Godot escala com nearest (default_texture_filter=0).
Placeholders reproduzíveis — trocáveis por versões nano-banana nos mesmos arquivos.
"""
import os, zlib, struct, math

HERE = os.path.dirname(os.path.abspath(__file__))
W, H = 90, 160

# --- paleta ---------------------------------------------------------------
CAP_GREEN  = (190, 228, 30, 255)   # #BEE41E
CAP_GREEN_D= (150, 182, 22, 255)
CAP_PURP   = (51, 33, 94, 255)     # #33215E
CAP_PURP_L = (92, 72, 148, 255)
INK        = (18, 18, 30, 255)
WHITE      = (240, 244, 250, 255)
STEEL      = (52, 58, 82, 255)
STEEL_L    = (86, 96, 130, 255)

# escritório
WALL       = (224, 228, 218, 255)
WALL_D     = (200, 206, 194, 255)
FLOOR      = (150, 116, 84, 255)
FLOOR_D    = (120, 92, 66, 255)
SKY        = (150, 200, 235, 255)
SKY_D      = (110, 168, 214, 255)
SCREEN     = (26, 30, 40, 255)

# celular / quarto
ROOMT      = (30, 30, 48, 255)     # parede escura (noite)
ROOMB      = (44, 40, 60, 255)
DESK       = (70, 54, 42, 255)
PHONE      = (26, 28, 40, 255)
PHONE_L    = (60, 66, 92, 255)
RING       = (255, 210, 90, 255)   # ondas de som (âmbar)


def blank():
    return [[(0, 0, 0, 0) for _ in range(W)] for _ in range(H)]


def rect(g, x0, y0, x1, y1, c):
    for y in range(max(0, y0), min(H, y1 + 1)):
        for x in range(max(0, x0), min(W, x1 + 1)):
            g[y][x] = c


def px(g, x, y, c):
    if 0 <= x < W and 0 <= y < H:
        g[y][x] = c


def disc(g, cx, cy, r, c):
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                px(g, x, y, c)


def ring(g, cx, cy, r, w, c, gap_right=False):
    for y in range(cy - r - 1, cy + r + 2):
        for x in range(cx - r - 1, cx + r + 2):
            d = math.hypot(x - cx, y - cy)
            if r - w <= d <= r:
                if gap_right and x > cx and abs(y - cy) < w + 1:
                    continue
                px(g, x, y, c)


def capim_mark(g, ox, oy, s):
    """Símbolo da Capim: quadrado arredondado verde + 'c' roxo."""
    rect(g, ox, oy, ox + s, oy + s, CAP_GREEN)
    # cantos arredondados
    for cx, cy in [(ox, oy), (ox + s, oy), (ox, oy + s), (ox + s, oy + s)]:
        px(g, cx, cy, (0, 0, 0, 0))
    # sombra inferior/direita
    rect(g, ox, oy + s, ox + s, oy + s, CAP_GREEN_D)
    # 'c' roxo (anel com abertura à direita)
    ring(g, ox + s // 2, oy + s // 2, s // 3, max(2, s // 8), CAP_PURP, gap_right=True)


def write_png(path, g):
    raw = bytearray()
    for y in range(H):
        raw.append(0)
        for x in range(W):
            raw += bytes(g[y][x])
    def chunk(typ, data):
        return (struct.pack(">I", len(data)) + typ + data
                + struct.pack(">I", zlib.crc32(typ + data) & 0xffffffff))
    ihdr = struct.pack(">IIBBBBB", W, H, 8, 6, 0, 0, 0)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr)
                + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b""))


# ========================= call_bg (celular tocando) =====================
def build_call():
    g = blank()
    rect(g, 0, 0, W - 1, H - 1, ROOMT)                 # parede escura
    rect(g, 0, 96, W - 1, 96, INK)
    rect(g, 0, 97, W - 1, H - 1, DESK)                  # mesa
    for x in range(0, W, 6):
        px(g, x, 100, FLOOR_D)
    # ondas de som dos dois lados (celular tocando)
    for i, r in enumerate((10, 15, 20)):
        ring(g, 45, 66, r, 1, RING)
    # apaga metade das ondas p/ virar arcos laterais
    rect(g, 30, 40, 60, 92, (0, 0, 0, 0))              # limpa centro p/ redesenhar o fone
    # corpo do celular (em pé)
    rect(g, 33, 44, 57, 92, PHONE)
    rect(g, 32, 43, 58, 44, PHONE_L)                   # brilho topo
    rect(g, 35, 48, 55, 88, SCREEN)                    # tela
    # tela: avatar + nome + botões
    disc(g, 45, 58, 6, CAP_GREEN)                      # avatar (verde)
    px(g, 43, 57, CAP_PURP); px(g, 47, 57, CAP_PURP)   # olhinhos
    rect(g, 39, 68, 51, 70, STEEL_L)                   # barra do nome
    rect(g, 41, 73, 49, 74, STEEL)
    disc(g, 40, 83, 3, (70, 200, 90, 255))             # atender (verde)
    disc(g, 50, 83, 3, (220, 70, 60, 255))             # recusar (vermelho)
    # ondas laterais (arcos) reforçadas
    for r in (12, 17):
        for a in range(-40, 41, 6):
            rad = math.radians(a)
            px(g, int(31 - r * math.cos(rad) * 0.0 + (31 - r)), 66, RING)
    for side in (-1, 1):
        for r in (7, 11, 15):
            for a in range(-45, 46, 8):
                rad = math.radians(a)
                x = 45 + side * int(r * math.cos(rad))
                y = 66 + int(r * math.sin(rad))
                if abs(x - 45) > 13:
                    px(g, x, y, RING)
    return g


# ========================= office_bg (Capim) =============================
def build_office():
    g = blank()
    rect(g, 0, 0, W - 1, H - 1, WALL)                  # parede
    rect(g, 0, 0, W - 1, 3, WALL_D)
    rect(g, 0, 120, W - 1, 120, FLOOR_D)               # rodapé
    rect(g, 0, 121, W - 1, H - 1, FLOOR)               # piso
    for x in range(0, W, 10):
        rect(g, x, 121, x, H - 1, FLOOR_D)             # tábuas

    # janela (centro) com skyline de SP (roxo) e céu
    rect(g, 40, 16, 82, 60, INK)
    rect(g, 41, 17, 81, 59, SKY)
    rect(g, 41, 40, 81, 59, SKY_D)                     # céu mais baixo
    sp = [(44, 52), (48, 44), (52, 50), (56, 40), (60, 48),
          (64, 42), (68, 52), (72, 46), (76, 50)]      # prédios SP
    for bx, by in sp:
        rect(g, bx, by, bx + 3, 59, CAP_PURP_L)
        px(g, bx + 1, by + 2, WHITE)                   # janelinha
    rect(g, 61, 17, 61, 59, INK)                       # caixilho vert
    rect(g, 41, 38, 81, 38, INK)                       # caixilho horiz

    # símbolo da Capim na parede (esquerda, bem visível)
    capim_mark(g, 8, 14, 22)
    # "capim" sugerido (barra roxa) sob o símbolo
    rect(g, 8, 40, 30, 43, CAP_PURP)
    for i in range(5):
        px(g, 10 + i * 4, 41, CAP_GREEN)

    # mesa + monitor (esquerda-centro)
    rect(g, 6, 96, 40, 100, FLOOR_D)                   # tampo
    rect(g, 8, 100, 11, 120, FLOOR_D)                  # perna
    rect(g, 35, 100, 38, 120, FLOOR_D)
    rect(g, 14, 78, 34, 95, CAP_PURP)                  # moldura monitor
    rect(g, 16, 80, 32, 92, SCREEN)                    # tela
    for i, ly in enumerate(range(82, 91, 2)):          # "código" verde
        rect(g, 18, ly, 18 + (6 if i % 2 else 10), ly, CAP_GREEN)
    rect(g, 22, 95, 26, 97, CAP_PURP_L)                # pé do monitor

    # vaso com CAPIM (grama!) — trocadilho da marca
    rect(g, 60, 108, 72, 120, CAP_PURP)                # vaso
    rect(g, 60, 108, 72, 110, CAP_PURP_L)
    for i, bx in enumerate(range(61, 72, 2)):          # folhas de capim
        h = 108 - (7 if i % 2 else 5)
        for y in range(h, 108):
            px(g, bx + (1 if (108 - y) > 3 else 0), y, CAP_GREEN)
            px(g, bx, y, CAP_GREEN_D)
    return g


write_png(os.path.join(HERE, "call_bg.png"), build_call())
write_png(os.path.join(HERE, "office_bg.png"), build_office())
print("wrote call_bg.png e office_bg.png (%dx%d)" % (W, H))
