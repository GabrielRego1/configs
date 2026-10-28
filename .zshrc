export ZSH="$HOME/.oh-my-zsh"

# Plugins
plugins=(
  git
  zsh-autosuggestions
  dotnet
  docker
)

source "$ZSH/oh-my-zsh.sh"
autoload -Uz add-zsh-hook

function git_info() {
  command git rev-parse --is-inside-work-tree &>/dev/null || return

  local branch
  branch=$(command git branch --show-current 2>/dev/null) || return

  local changed
  changed=$(command git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

  print -r -- "%F{#9ECE6A} ${branch}%f %F{yellow}[${changed}]%f"
}


function prompt() {
  PROMPT='%F{white}╭─%f%F{#BB9AF7}%B%n%b@%B%m%b%f %F{#7DCFFF}%~%f$(git_info)
%F{white}╰─➤%f '

  RPROMPT='%F{yellow}%D{%H:%M:%S}%f'
}

add-zsh-hook precmd prompt
