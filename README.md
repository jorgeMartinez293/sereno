<h1 align="center">✦ sereno</h1>

<p align="center">
  <b>Sprites animados con la info de tu sistema, cada vez que abres el terminal</b><br>
  <i>Parte de la familia <a href="https://github.com/jorgeMartinez293">vaho</a>. Antes conocido como pokefetch.</i>
</p>

---

Cada vez que abres el terminal, **sereno** elige un sprite, extrae su color dominante
y lo muestra junto a la información de tu sistema vía [fastfetch](https://github.com/fastfetch-cli/fastfetch).
Como el sereno de antes: te saluda al llegar.

## Características

- 🎲 **Sprite aleatorio** — una criatura distinta en cada terminal
- 🎨 **Colores dinámicos** — las etiquetas se tiñen con la paleta del sprite (pastel)
- 🔋 **Consciente de la batería** — muestra un frame estático con batería para ahorrar
- 🖼️ **Pixel-perfect** — reescalado nearest-neighbor, pixel art nítido
- 🖥️ **App de gestión** (`sereno-app/`) — elige sprite fijo o aleatorio, previsualiza en vivo

## Instalar

```bash
./install.sh
```

Instala dependencias (fastfetch, ImageMagick, Pillow) vía Homebrew, copia todo a
`~/.config/sereno/` y añade el saludo a `~/.zshrc`. Si vienes de **pokefetch**, el
instalador migra automáticamente tus sprites y ajustes.

## Sprites

El pack incluido son 180 criaturas de
["Tiny Creatures" de Clint Bellanger](https://opengameart.org/content/tiny-creatures)
(CC0). Puedes añadir cualquier `.gif` / `.png` propio a `~/.config/sereno/sprites/` —
los GIFs se animan en terminales compatibles (kitty graphics / iTerm inline images,
incluido [vidrio](../LiquidTerminal)).

## App de gestión

```bash
cd sereno-app && make run
```

## Desinstalar

```bash
./uninstall.sh
```
