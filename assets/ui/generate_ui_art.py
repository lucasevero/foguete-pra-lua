#!/usr/bin/env python3
"""Gera a arte de UI (pixel art) do HUD: ícones, medidor de combustível,
painel e botão de menu. Reproduzível — rode `python3 generate_ui_art.py`.

Convenções (ver assets/README.md): PNG transparente, pixel art sem
anti-aliasing (desenhado em baixa resolução, Godot escala com filtro nearest).
Paleta única entre todos os assets pra manter coesão visual.
"""
from PIL import Image
import os

HERE = os.path.dirname(os.path.abspath(__file__))

# --- Paleta (espaço retrô) ------------------------------------------------
T      = (0, 0, 0, 0)            # transparente
INK    = (26, 26, 46, 255)       # contorno / sombra escura (navy quase preto)
PANEL  = (36, 40, 66, 235)       # fundo do painel (semi-transparente)
PANEL2 = (48, 54, 88, 235)       # highlight interno do painel
EDGE   = (86, 122, 168, 255)     # borda clara (azul aço)
WHITE  = (232, 240, 255, 255)    # branco frio

# combustível (âmbar)
AMB_D  = (191, 87, 0, 255)
AMB    = (251, 133, 0, 255)
AMB_L  = (255, 183, 3, 255)

# tempo (ciano)
CY_D   = (20, 83, 107, 255)
CY     = (33, 158, 188, 255)
CY_L   = (142, 202, 230, 255)

# botão (verde-azulado positivo)
BTN_D  = (20, 83, 107, 255)
BTN    = (42, 157, 143, 255)
BTN_L  = (90, 199, 184, 255)


def new(w, h):
    return Image.new("RGBA", (w, h), T)


def px(img, x, y, c):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), c)


def rect(img, x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            px(img, x, y, c)


def save(img, name):
    path = os.path.join(HERE, name)
    img.save(path)
    print("wrote", name, img.size)


# --------------------------------------------------------------------------
# Ícone de combustível — jerry can (16x16)
# --------------------------------------------------------------------------
def fuel_icon():
    im = new(16, 16)
    # corpo
    rect(im, 3, 5, 11, 14, AMB)
    # contorno do corpo
    rect(im, 3, 5, 3, 14, INK)
    rect(im, 11, 5, 11, 14, INK)
    rect(im, 3, 14, 11, 14, INK)
    rect(im, 3, 5, 11, 5, INK)
    # sombra interna (direita/baixo)
    rect(im, 10, 6, 10, 13, AMB_D)
    rect(im, 4, 13, 10, 13, AMB_D)
    # highlight (esquerda)
    rect(im, 4, 6, 4, 12, AMB_L)
    # alça em cima
    rect(im, 4, 2, 8, 4, INK)
    rect(im, 5, 3, 7, 3, T)  # vazado da alça
    # bico
    rect(im, 11, 3, 14, 5, INK)
    rect(im, 12, 4, 14, 4, AMB_L)
    # tampa
    rect(im, 6, 4, 9, 4, INK)
    return im


# --------------------------------------------------------------------------
# Ícone de tempo — relógio (16x16)
# --------------------------------------------------------------------------
def clock_icon():
    im = new(16, 16)
    face = [
        "....XXXXXX....",
        "..XXccccccXX..",
        ".XccccccccccX.",
        ".XccccXccccccX",
        "XcccccXcccccccX",
        "XcccccXcccccccX",
        "XccccccXXXcccccX",
    ]
    # desenho simétrico via círculo simples
    cx, cy, r = 8, 9, 6
    for y in range(16):
        for x in range(16):
            d2 = (x - cx) ** 2 + (y - cy) ** 2
            if r * r - 5 <= d2 <= r * r + r:      # anel (borda)
                px(im, x, y, CY)
            elif d2 < r * r - 5:                    # face
                px(im, x, y, CY_L)
    # sombra do anel embaixo/direita
    for y in range(16):
        for x in range(16):
            d2 = (x - cx) ** 2 + (y - cy) ** 2
            if r * r - 5 <= d2 <= r * r + r and (x >= cx or y >= cy):
                px(im, x, y, CY_D)
    # ponteiros
    rect(im, cx, cy - 4, cx, cy, INK)   # ponteiro grande (12h)
    rect(im, cx, cy, cx + 3, cy, INK)   # ponteiro pequeno (3h)
    px(im, cx, cy, WHITE)
    # topo do relógio (botãozinho)
    rect(im, cx - 1, 1, cx + 1, 2, CY_D)
    return im


# --------------------------------------------------------------------------
# Painel do HUD — nine-patch 24x24, margens 8
# --------------------------------------------------------------------------
def panel():
    im = new(24, 24)
    rect(im, 1, 1, 22, 22, PANEL)          # fundo
    rect(im, 2, 2, 21, 6, PANEL2)          # brilho superior
    # borda
    rect(im, 1, 0, 22, 0, EDGE)
    rect(im, 1, 23, 22, 23, INK)
    rect(im, 0, 1, 0, 22, EDGE)
    rect(im, 23, 1, 23, 22, INK)
    # cantos suavizados
    for (x, y) in [(0, 0), (23, 0), (0, 23), (23, 23)]:
        px(im, x, y, T)
    return im


# --------------------------------------------------------------------------
# Medidor (barra) de combustível — nine-patch horizontal 32x16, margem 6
# frame vazio + fill (usados por TextureProgressBar)
# --------------------------------------------------------------------------
def gauge_frame():
    im = new(32, 16)
    rect(im, 1, 1, 30, 14, INK)            # trilho escuro
    rect(im, 2, 2, 29, 13, (18, 20, 34, 255))
    # borda
    rect(im, 1, 0, 30, 0, EDGE)
    rect(im, 1, 15, 30, 15, INK)
    rect(im, 0, 1, 0, 14, EDGE)
    rect(im, 31, 1, 31, 14, INK)
    for (x, y) in [(0, 0), (31, 0), (0, 15), (31, 15)]:
        px(im, x, y, T)
    return im


def gauge_fill():
    im = new(32, 16)
    rect(im, 0, 0, 31, 15, AMB)
    rect(im, 0, 0, 31, 3, AMB_L)           # highlight topo
    rect(im, 0, 13, 31, 15, AMB_D)         # sombra base
    return im


# --------------------------------------------------------------------------
# Botão de menu — nine-patch 32x24, margem 8 (normal + pressed)
# --------------------------------------------------------------------------
def button(base, light, dark, pressed=False):
    im = new(32, 24)
    rect(im, 1, 1, 30, 22, base)
    if not pressed:
        rect(im, 2, 2, 29, 6, light)       # brilho topo
        rect(im, 2, 19, 29, 21, dark)      # sombra base (relevo)
    else:
        rect(im, 2, 2, 29, 4, dark)        # afundado
    # borda
    rect(im, 1, 0, 30, 0, light if not pressed else dark)
    rect(im, 1, 23, 30, 23, INK)
    rect(im, 0, 1, 0, 22, dark)
    rect(im, 31, 1, 31, 22, INK)
    for (x, y) in [(0, 0), (31, 0), (0, 23), (31, 23)]:
        px(im, x, y, T)
    return im


if __name__ == "__main__":
    save(fuel_icon(), "fuel_icon.png")
    save(clock_icon(), "clock_icon.png")
    save(panel(), "panel.png")
    save(gauge_frame(), "gauge_frame.png")
    save(gauge_fill(), "gauge_fill.png")
    save(button(BTN, BTN_L, BTN_D, pressed=False), "button_normal.png")
    save(button(BTN, BTN_L, BTN_D, pressed=True), "button_pressed.png")
    print("done")
