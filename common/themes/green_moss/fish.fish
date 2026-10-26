__set_tide_uvar tide_context_bg_color 6B705C
__set_tide_uvar tide_git_bg_color 7F9A5E
__set_tide_uvar tide_git_bg_color_unstable 7F9A5E
__set_tide_uvar tide_git_bg_color_urgent 7F9A5E
__set_tide_uvar tide_pwd_bg_color 3A3F33
__set_tide_uvar tide_python_bg_color 3A3F33
set -gx EZA_COLORS (string replace -r '^di=[^:]*' 'di=38;2;210;198;184' -- $EZA_COLORS)
