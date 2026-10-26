status is-interactive; or return

if functions -q fzf_configure_bindings
    fzf_configure_bindings --directory=\ct --history=\cr --git_log=\el --git_status=\es --processes=\ep --variables=\ev
else if command -q fzf
    fzf --fish | source
end
