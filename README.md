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
- 📦 **Packs temáticos** — descarga sets de GIFs (Apple, espacio, naturaleza...) desde la app
- 🖐️ **Arrastrar y soltar** — suelta cualquier `.gif` / `.png` sobre la app para añadirlo

## Instalar

```bash
./install.sh
```

Instala dependencias (fastfetch, ImageMagick, Pillow) vía Homebrew, copia todo a
`~/.config/sereno/` y añade el saludo a `~/.zshrc`. Si vienes de **pokefetch**, el
instalador migra automáticamente tus sprites y ajustes.

## Sprites

Los sprites viven en `~/.config/sereno/sprites/`. Hay tres formas de añadirlos:

1. **Packs temáticos** — pulsa el botón **+** en la app y descarga los sets de
   [`sprite-packs/`](sprite-packs/): *Apple*, *Espacio*, *Naturaleza*, *Animales*,
   *Retro*, *Caritas* y *Comida*. Cada pack mezcla pixel art clásico y emojis
   animados en HD; todos los GIFs tienen fondo transparente (ver
   [`sprite-packs/ATTRIBUTION.md`](sprite-packs/ATTRIBUTION.md)).
2. **Arrastrar y soltar** — suelta cualquier `.gif` / `.png` sobre la lista de
   sprites de la app.
3. **A mano** — copia los ficheros directamente a `~/.config/sereno/sprites/`.

Los GIFs se animan en terminales compatibles (kitty graphics / iTerm inline
images, incluido [vidrio](../vidrio)).

## App de gestión

```bash
cd sereno-app && make run
```

## Desinstalar

```bash
./uninstall.sh
```
