status is-interactive; or return

# Named ANSI colours, so fish follows the active theme preset's kitty palette.
# Set as global (not universal) so they live here in a tracked file
# instead of the untracked fish_variables, and re-apply every session.

set -g fish_color_normal         normal
set -g fish_color_command        brblue               # valid commands
set -g fish_color_keyword        brcyan               # if / for / function / and / or
set -g fish_color_builtin        brcyan
set -g fish_color_function       brcyan
set -g fish_color_error          brred                # unknown command / syntax errors
set -g fish_color_param          normal               # arguments
set -g fish_color_option         bryellow             # -flags / --options
set -g fish_color_quote          brgreen              # 'single' and "double" quoted strings
set -g fish_color_escape         cyan                 # \n \x1b and other escapes
set -g fish_color_operator       cyan                 # math / expansion operators
set -g fish_color_redirection    cyan                 # > < | redirections
set -g fish_color_end            cyan                 # ; & command terminators
set -g fish_color_comment        brblack              # # comments
set -g fish_color_valid_path     magenta --underline  # paths that exist
set -g fish_color_autosuggestion brblack              # history suggestions
set -g fish_color_selection      --background=black
set -g fish_color_search_match   --background=black

# Completion pager (Tab menu)
set -g fish_pager_color_prefix                magenta --bold
set -g fish_pager_color_completion            normal
set -g fish_pager_color_description           brblack
set -g fish_pager_color_progress              brblack
set -g fish_pager_color_selected_background   --background=black
set -g fish_pager_color_selected_prefix       magenta --bold
set -g fish_pager_color_selected_completion   normal
set -g fish_pager_color_selected_description  brblack
