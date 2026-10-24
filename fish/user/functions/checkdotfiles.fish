function checkdotfiles --description 'Check tracked dotfile status under .config'
    dotfiles -C $HOME status -u .config Documents/scripts \
        | grep -vE '\.config/(cava|Cemu|claude|chromium|codex|discord|dotfiles|easyeffects|eden|Gharmonize|GIMP|go|gtk[^/]*|heroic|libreoffice|me3|mozilla|obs-studio|obsidian|rpcs3|rustdesk|spicetify|spotify|transmission|unity3d|yuzu|zen)(/|$)' \
        | grep -vE '\.config/fish/(functions|completions|conf\.d)/|\.config/fish/fish_variables(/|$)|\.config/zsh/(plugins/|\.zcompdump|\.zsh_history)'
    echo "Dotfiles status checked!"
end
