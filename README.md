# Green Moss Dotfiles

![Screenshot](assets/First.png)
![Screenshot](assets/Second.png)

## Palette

| Role       | Colour |
| ---------- | ------ |
| Background | `#10120e` |
| Foreground | `#f3ece4` |
| Accent     | `#A3B18A` |
| Selection  | `#666b57` |


## Included

- `bspwm` / `sxhkd` - Window manager and keybindings
- `polybar` - Status bar
- `picom` - Compositor (v13 animations; extra `picom.conf.*` variants)
- `rofi` - Launcher and power menu (with a theme picker)
- `kitty` - Terminal
- `dunst` - Notifications
- `fish` - Shell, tide prompt and functions
- `nvim` - Neovim (lazy.nvim, noirbuddy)
- `yazi` - File manager
- `themes/green_moss` - This preset's colors and wallpapers; `themes/current` points at it
- `scripts` - `theme.sh` (switch presets), `wallpaper.sh`, `restartpicom.sh`, `build-gtk-theme.sh` (recolored Orchis GTK theme)

## Installation

Clone the repository and copy/link the folders into `~/.config/`, and
`scripts/` into `~/Documents/scripts/`.

```sh
git clone https://github.com/iiKovu/dotfiles-green-moss.git
cd dotfiles-green-moss
```

Wallpaper paths are set in `themes/green_moss/preset.sh`.
