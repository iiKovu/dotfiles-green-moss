status is-interactive; or return

alias ls="eza -alm --icons --group-directories-first --no-permissions --no-user --no-time --git"
alias grep="grep --color=auto"
alias mpv="mpv --sub-auto=all"

abbr -a ll eza -alm
abbr -a db nvim -c DBUIToggle
abbr -a bt bluetoothctl
abbr -a a trash-empty
abbr -a ff fastfetch
abbr -a z sudoedit
abbr -a o $OPENER
abbr -a e $EDITOR
abbr -a aa tmux a
abbr -a i $IMAGE
abbr -a v $VIDEO
abbr -a p python3
