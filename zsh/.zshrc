###############################################################################
#                                Prompt                                       #
###############################################################################

# Function to calculate the length of a prompt string
function prompt-length() {
  emulate -L zsh
  local -i COLUMNS=${2:-COLUMNS}
  local -i x y=${#1} m
  if (( y )); then
    while (( ${${(%):-$1%$y(l.1.0)}[-1]} )); do
      x=y
      (( y *= 2 ))
    done
    while (( y > x + 1 )); do
      (( m = x + (y - x) / 2 ))
      (( ${${(%):-$1%$m(l.x.y)}[-1]} = m ))
    done
  fi
  typeset -g REPLY=$x
}

# Function to fill the line with prompt components
function fill-line() {
  emulate -L zsh
  prompt-length "$1"
  local -i left_len=REPLY
  prompt-length "$2" 9999
  local -i right_len=REPLY
  local -i pad_len=$((COLUMNS - left_len - right_len - ${ZLE_RPROMPT_INDENT:-1}))
  if (( pad_len < 1 )); then
    # Not enough space for the right part. Drop it.
    typeset -g REPLY="$1"
  else
    local pad="${(pl.$pad_len.. .)}"  # pad_len spaces
    typeset -g REPLY="${1}${pad}${2}"
  fi
}

# Function to set the prompt
function set-prompt() {
  emulate -L zsh
  
  # Get the current Git branch if inside a Git repository
  local git_branch=""
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    git_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
    git_branch=${git_branch//\%/%%}  # Escape '%'
  fi

  # Define the prompt components
  local top_left='%K{#6e735f} %F{white}%n@%M %k%K{black}%F{#6e735f} %F{white}%~%k%F{black}'
  local top_right
  if [[ -n $git_branch ]]; then
    top_right="%F{10}%f%K{10}%F{white} ${git_branch}  %f%k%F{10} %F{247}%D{%I:%M %p}%f"
  else
    top_right="%F{247}%D{%I:%M %p}%f"
  fi

  local bottom_left='%F{247}⯈%f '
  local bottom_right=""

  # Assemble the prompt
  local REPLY
  fill-line "$top_left" "$top_right"
  PROMPT="${REPLY}"$'\n'"${bottom_left}"
  RPROMPT="$bottom_right"
}

# Set prompt options
setopt no_prompt_bang
setopt no_prompt_subst
setopt prompt_cr
setopt prompt_percent
setopt prompt_sp

# Load the add-zsh-hook function
autoload -Uz add-zsh-hook

# Add set-prompt to the precmd hook
add-zsh-hook precmd set-prompt
