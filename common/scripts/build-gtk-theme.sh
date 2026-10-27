#!/usr/bin/env bash
# Build an Orchis GTK theme recolored for a preset:
#   build-gtk-theme.sh dark_red  ->  ~/.local/share/themes/Orchis-dark_red
# Colors come from the GTK_* variables in ~/.config/themes/<name>/preset.sh.

set -eu

name=${1:?usage: build-gtk-theme.sh <preset>}
. "${XDG_CONFIG_HOME:-$HOME/.config}/themes/$name/preset.sh"
[[ -n ${GTK_VARIANT:-} ]] || { echo "$name uses a stock GTK theme ($GTK_NAME)" >&2; exit 1; }

src="${XDG_CACHE_HOME:-$HOME/.local/cache}/build/Orchis-theme"
dest="${XDG_DATA_HOME:-$HOME/.local/share}/themes"
[[ -d $src ]] || git clone --depth 1 https://github.com/vinceliuice/Orchis-theme.git "$src"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cp -r "$src"/. "$tmp"

# Dark variant: accent is $<variant>-light; backgrounds e/f/g/h are grey-800..650
sed -i -E \
    -e "s/^\\\$${GTK_VARIANT}-light: .*/\$${GTK_VARIANT}-light: ${GTK_ACCENT};/" \
    -e "s/^\\\$grey-800: .*/\$grey-800: ${GTK_BG};/" \
    -e "s/^\\\$grey-750: .*/\$grey-750: ${GTK_BASE_ALT};/" \
    -e "s/^\\\$grey-700: .*/\$grey-700: ${GTK_BASE};/" \
    -e "s/^\\\$grey-650: .*/\$grey-650: ${GTK_SURFACE};/" \
    "$tmp/src/_sass/_color-palette-default.scss"

# Orchis' install.sh calls its blue variant "default"
(cd "$tmp" && ./install.sh -d "$tmp/out" -n Orchis -t "${GTK_VARIANT/#blue/default}" -c dark -s compact >/dev/null)

rm -rf "${dest:?}/$GTK_NAME"
mkdir -p "$dest"
mv "$tmp"/out/Orchis*-Dark-Compact "$dest/$GTK_NAME"
echo "built $dest/$GTK_NAME"
