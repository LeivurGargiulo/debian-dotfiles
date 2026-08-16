# --- Monokai Pro: fzf ---
export FZF_DEFAULT_OPTS="--color=fg:#FCFCFA,bg:#2D2A2E,hl:#FF6188,fg+:#FCFCFA,bg+:#221F22,hl+:#FC9867,info:#AB9DF2,prompt:#78DCE8,pointer:#FF6188,marker:#A9DC76,spinner:#FFD866,header:#939293,border:#939293,gutter:#2D2A2E,query:#FCFCFA"

# --- Monokai Pro: bat / delta ---
export BAT_THEME="Monokai Pro"

# --- Monokai Pro: zsh-syntax-highlighting ---
# NOTE: this block must be sourced/placed AFTER oh-my-zsh loads the
# zsh-syntax-highlighting plugin (oh-my-zsh is installed by install.sh's
# "not automated yet" manual step per README — this styles block is inert
# until that plugin is actually sourced).
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]='fg=#FCFCFA'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#FF6188'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#FF6188'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#A9DC76'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#A9DC76'
ZSH_HIGHLIGHT_STYLES[function]='fg=#A9DC76'
ZSH_HIGHLIGHT_STYLES[command]='fg=#A9DC76'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#A9DC76,italic'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#939293'
ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=#A9DC76'
ZSH_HIGHLIGHT_STYLES[path]='fg=#78DCE8'
ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=#939293'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#AB9DF2'
ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=#AB9DF2'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#FC9867'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#FC9867'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#FFD866'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#FFD866'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#FFD866'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#FFD866'
ZSH_HIGHLIGHT_STYLES[command-substitution]='fg=#78DCE8'
ZSH_HIGHLIGHT_STYLES[process-substitution]='fg=#78DCE8'
ZSH_HIGHLIGHT_STYLES[assign]='fg=#FCFCFA'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#FF6188'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#939293,italic'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=#A9DC76'
