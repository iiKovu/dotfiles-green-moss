status is-interactive; or return

function __set_tide_uvar -a name
    set -l values $argv[2..-1]
    if not set -q $name; or test "$$name" != "$values"
        set -U $name $values
    end
end

__set_tide_uvar VIRTUAL_ENV_DISABLE_PROMPT true
__set_tide_uvar tide_context_always_display true
__set_tide_uvar tide_context_color_default FFFFFF
__set_tide_uvar tide_context_color_root FFFFFF
__set_tide_uvar tide_context_color_ssh FFFFFF
__set_tide_uvar tide_context_hostname_parts 1
__set_tide_uvar tide_left_prompt_frame_enabled false
__set_tide_uvar tide_left_prompt_items context pwd python git newline character
__set_tide_uvar tide_left_prompt_prefix ''
__set_tide_uvar tide_left_prompt_separator_diff_color ''
__set_tide_uvar tide_left_prompt_separator_same_color ''
__set_tide_uvar tide_left_prompt_suffix ''
__set_tide_uvar tide_prompt_add_newline_before false
__set_tide_uvar tide_prompt_color_frame_and_connection 6C6C6C
__set_tide_uvar tide_prompt_icon_connection ' '
__set_tide_uvar tide_prompt_pad_items true
__set_tide_uvar tide_prompt_transient_enabled false
__set_tide_uvar tide_pwd_color_anchors FFFFFF
__set_tide_uvar tide_pwd_color_dirs FFFFFF
__set_tide_uvar tide_pwd_color_truncated_dirs BCBCBC
__set_tide_uvar tide_python_color FFFFFF
__set_tide_uvar tide_python_icon ''
__set_tide_uvar tide_git_color_branch FFFFFF
__set_tide_uvar tide_git_color_dirty FFFFFF
__set_tide_uvar tide_git_color_staged FFFFFF
__set_tide_uvar tide_git_color_untracked FFFFFF
__set_tide_uvar tide_git_color_upstream FFFFFF
__set_tide_uvar tide_git_icon ''
__set_tide_uvar tide_right_prompt_frame_enabled false
__set_tide_uvar tide_right_prompt_items time
__set_tide_uvar tide_right_prompt_prefix ''
__set_tide_uvar tide_right_prompt_separator_diff_color ''
__set_tide_uvar tide_right_prompt_separator_same_color ''
__set_tide_uvar tide_right_prompt_suffix ''
__set_tide_uvar tide_time_bg_color normal
__set_tide_uvar tide_time_color 9E9E9E
__set_tide_uvar tide_time_format "%I:%M %p"
__set_tide_uvar tide_character_color 9E9E9E
__set_tide_uvar tide_character_color_failure 9E9E9E
__set_tide_uvar tide_character_icon '⯈'
__set_tide_uvar tide_character_vi_icon_default '⯈'
__set_tide_uvar tide_character_vi_icon_replace '⯈'
__set_tide_uvar tide_character_vi_icon_visual '⯈'

source ~/.config/themes/current/fish.fish
functions -e __set_tide_uvar
