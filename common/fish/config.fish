# All static env (XDG base dirs + personal/session vars) lives in
# /etc/environment (pam_env), so it applies to every session before any shell or
# xinitrc runs and every shell inherits it. This file is fish-specific and
# interactive-only — it does NOT declare env.

# My own config lives under user/: functions/ are lazily autoloaded, conf.d/
# snippets are sourced below. Everything else in this tree is fisher-managed.
if not contains -- $__fish_config_dir/user/functions $fish_function_path
    set -p fish_function_path $__fish_config_dir/user/functions
end

# gpg-agent's ssh socket has a hashed path, so it can't be a static
# /etc/environment value. Graphical sessions inherit it from xinitrc; for
# TTY/non-graphical fish, compute it here.
if not set -q SSH_AUTH_SOCK
    set -l agent_sock (gpgconf --list-dirs agent-ssh-socket 2>/dev/null)
    test -n "$agent_sock"; and set -gx SSH_AUTH_SOCK "$agent_sock"
end

set -g DOW "$HOME/Documents/Downloads/"

if status is-interactive
    set -g fish_greeting
    set -g fish_key_bindings fish_vi_key_bindings
    set -gx EZA_COLORS "di=38;5;132:fi=0;37:ln=3;37:lp=0;37:pi=33:so=35:bd=0;33:cd=0;33:ex=0;32:or=0;30:*.tar=0;31:*.jpg=0;35:*.png=0;35:*.zip=0;31:*.gz=0;31:*.pdf=0;35:*.doc=0;34:*.xls=0;32:*.ppt=0;33:*.mp3=0;36:*.mp4=0;36:*.py=0;32:*.c=0;34:*.h=0;34:*.cpp=0;34:*.hpp=0;34:*.js=0;33:*.html=0;35:*.css=0;35"

    if command -q zoxide
        zoxide init --cmd cd fish | source
    end

    # Load my aliases / prompt overrides / fzf bindings
    for f in $__fish_config_dir/user/conf.d/*.fish
        source $f
    end
end
