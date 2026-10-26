function q --description 'Find files with fzf and open the selection in nvim'
    fd --hidden --no-ignore --exclude .git | fzf --height ~60% --layout reverse --border --preview='bat --style=numbers --color=always {}' --bind 'enter:become(nvim {})'
end
