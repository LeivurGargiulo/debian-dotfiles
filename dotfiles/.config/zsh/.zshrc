# Add user configurations here
# For HyDE to not touch your beloved configurations,
# we added a config file for you to customize HyDE before loading zshrc
# Edit $ZDOTDIR/.user.zsh to customize HyDE before loading zshrc

#  Plugins 
# oh-my-zsh plugins are loaded  in $ZDOTDIR/.user.zsh file, see the file for more information

#  Aliases 
# Override aliases here in '$ZDOTDIR/.zshrc' (already set in .zshenv)

# # Helpful aliases
# alias c='clear'                                                        # clear terminal
# alias l='eza -lh --icons=auto'                                         # long list
# alias ls='eza -1 --icons=auto'                                         # short list
# alias ll='eza -lha --icons=auto --sort=name --group-directories-first' # long list all
# alias ld='eza -lhD --icons=auto'                                       # long list dirs
# alias lt='eza --icons=auto --tree'                                     # list folder as tree
# alias un='$aurhelper -Rns'                                             # uninstall package
# alias up='$aurhelper -Syu'                                             # update system/package/aur
# alias pl='$aurhelper -Qs'                                              # list installed package
# alias pa='$aurhelper -Ss'                                              # list available package
# alias pc='$aurhelper -Sc'                                              # remove unused cache
# alias po='$aurhelper -Qtdq | $aurhelper -Rns -'                        # remove unused packages, also try > $aurhelper -Qqd | $aurhelper -Rsu --print -
# alias vc='code'                                                        # gui code editor
# alias fastfetch='fastfetch --logo-type kitty'

# # Directory navigation shortcuts
# alias ..='cd ..'
# alias ...='cd ../..'
# alias .3='cd ../../..'
# alias .4='cd ../../../..'
# alias .5='cd ../../../../..'

# # Always mkdir a path (this doesn't inhibit functionality to make a single dir)
# alias mkdir='mkdir -p'

#  This is your file 
# Add your configurations here
# export EDITOR=nvim
# export EDITOR=code

# unset -f command_not_found_handler # Uncomment to prevent searching for commands not found in package manager

#  Aliases (personal)
alias claudio='claude --dangerously-skip-permissions'

# fuzzy-find a file by (partial) name under $HOME, pick from matches, and open it
# e.g. `open list.txt` offers ~/market/list_market.txt among the matches
open() {
    local matches match
    matches=$(fd -t f -i "$1" ~ 2>/dev/null)
    if [[ -z "$matches" ]]; then
        echo "open: no match for '$1'" >&2
        return 1
    fi
    match=$(echo "$matches" | fzf --prompt="open> " --select-1)
    [[ -n "$match" ]] && xdg-open "$match"
}

# --- Monokai Pro: fzf ---
export FZF_DEFAULT_OPTS="--color=fg:#FCFCFA,bg:#2D2A2E,hl:#FF6188,fg+:#FCFCFA,bg+:#221F22,hl+:#FC9867,info:#AB9DF2,prompt:#78DCE8,pointer:#FF6188,marker:#A9DC76,spinner:#FFD866,header:#939293,border:#939293,gutter:#2D2A2E,query:#FCFCFA"

# --- Monokai Pro: bat / delta ---
export BAT_THEME="Monokai Pro"

# --- Monokai Pro: zsh-syntax-highlighting ---
# This HyDE fork's own oh-my-zsh plugin loading (conf.d/hyde/terminal.zsh)
# sources zsh-syntax-highlighting before this file, so the styles below take
# effect immediately — no ordering workaround needed here, unlike the old
# dead dotfiles/.zshrc this replaced.
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
