function fish_user_key_bindings
    bind \cp history-search-backward
    bind \cn history-search-forward
    bind ctrl-space accept-autosuggestion
    bind -M insert \cp history-search-backward
    bind -M insert \cn history-search-forward
    bind -M insert ctrl-space accept-autosuggestion
end
