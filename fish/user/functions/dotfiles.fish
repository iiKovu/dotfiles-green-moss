function dotfiles --description 'Run git against the bare dotfiles repository'
    git --git-dir="$HOME/.config/dotfiles" --work-tree="$HOME" $argv
end
