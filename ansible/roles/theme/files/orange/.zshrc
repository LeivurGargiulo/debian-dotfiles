if [[ -o interactive ]] && command -v fastfetch >/dev/null; then
    fastfetch
fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git sudo extract zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-history-substring-search)

source $ZSH/oh-my-zsh.sh

# User configuration

export PATH="$HOME/.local/bin:$PATH"

alias ls="eza --icons"
alias ll="eza -la --icons --git"
alias lt="eza --tree --icons -L 2"
alias cat="batcat --paging=never"
alias grep="grep --color=auto"

alias fd="fdfind"

alias cd="z"
alias cdi="zi"   # fuzzy-pick a visited dir

[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh 2>/dev/null
[ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh 2>/dev/null
export FZF_DEFAULT_COMMAND="fdfind --type f --hidden --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fdfind --type d --hidden --exclude .git"
# RiceOrange (Windows Terminal scheme, gamdias WSL)
export FZF_DEFAULT_OPTS=" \
--color=bg+:#3A3A3A,bg:#0A0A0A,spinner:#FFB768,hl:#FF4500 \
--color=fg:#E8E8E8,header:#FF4500,info:#FF7A00,pointer:#FFB768 \
--color=marker:#FFC670,fg+:#E8E8E8,prompt:#FF7A00,hl+:#FF4500 \
--color=selected-bg:#3A3A3A \
--color=border:#6E6E6E,label:#E8E8E8"

# quick nav
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
mkcd() { mkdir -p "$1" && cd "$1"; }

# misc QoL
alias c="clear"
alias h="history"
alias reload="source ~/.zshrc"
theme() { ansible-playbook ~/debian/ansible/site.yml --tags theme -e dotfiles_theme="$1" --ask-become-pass; }
alias myip="curl -s ifconfig.me"
alias ports="ss -tulpn"
alias path='echo -e ${PATH//:/\\n}'

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# --- claudio helpers -------------------------------------------------------
# Single source of truth for the StoryBible path on this machine.
export STORYBIBLE="$HOME/TuningTheHeart/TTH-StoryBible"

# claudio [dir] [claude args...]  -- runs in the current dir, or in [dir] if given
claudio() {
  if [ -d "$1" ]; then
    cd "$1" || return 1
    shift
  fi
  echo "claudio -> $PWD"
  claude --dangerously-skip-permissions "$@"
}

# tth [claude args...]  -- jump into the StoryBible repo and launch there
tth() {
  cd "$STORYBIBLE" || { echo "tth: $STORYBIBLE not found" >&2; return 1; }
  claudio "$@"
}
alias tth-claudio=tth
# ---------------------------------------------------------------------------

eval "$(starship init zsh)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# mcserver console access
alias mcattach='docker attach slaycraft-mcserver-1'
mcexec() { docker exec slaycraft-mcserver-1 sh -c "echo \"$*\" > /proc/1/fd/0"; docker logs --tail 1 slaycraft-mcserver-1; }
alias mclog='docker logs -f --tail 100 slaycraft-mcserver-1'

# persistent session, mainly for mobile ssh/mosh — detach-safe
# tm         -> attach/create "main"
# tm list    -> tmux ls
tm() {
  if [ "$1" = "list" ]; then
    tmux ls
  else
    tmux new -A -s main
  fi
}
# claudio-tmux — persistent detach-safe tmux session running claude --dangerously-skip-permissions
# reattaches if already running. wakelock (termux-wake-lock) only applies on Termux/Android, no-op on WSL.
alias claudio-tmux='command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock; tmux new -A -s claudio "zsh -ic claudio"'
alias mosh-phone='mosh phone'
alias mosh-tablet='mosh tablet'

# dev <project> — tmux session named after project, in ~/projects/<project>, launches claude.
# reattaches to existing session if already running (persists across mosh drops).
dev() {
  local name="$1"; shift
  [ -z "$name" ] && { echo "usage: dev <project-name>" >&2; return 1; }
  local dir
  case "$name" in
    minecraft-bot) dir="$HOME/Minecraft/minecraft-bot" ;;
    StoryCodex|storycodex) dir="$HOME/StoryCodex" ;;
    StoryBible|storybible|tth) dir="$STORYBIBLE" ;;
    *) dir="$HOME/projects/$name" ;;
  esac
  [ -d "$dir" ] || { echo "dev: $dir not found" >&2; return 1; }
  if tmux has-session -t "$name" 2>/dev/null; then
    tmux attach -t "$name"
  else
    tmux new-session -s "$name" -c "$dir" "zsh -ic 'claudio $*'"
  fi
}

mdv() { glow -p "$@"; }

# help [query] -- fuzzy search all alias/function defs in ~/.zshrc (always current, no separate doc to rot)
help() {
  grep -nE '^\s*(alias |[a-zA-Z_][a-zA-Z0-9_]*\s*\(\))' ~/.zshrc | fzf -q "$*"
}

# o [words...] -- fuzzy find file by name, open in mdv (glow pager)
o() {
  local f
  f=$(fdfind -t f . ~ 2>/dev/null | fzf -q "$*" -1 -0)
  [ -n "$f" ] && mdv "$f"
}

eval "$(zoxide init zsh)"
