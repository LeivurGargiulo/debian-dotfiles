#  Startup 
# Commands to execute on startup (before the prompt is shown)
# Check if the interactive shell option is set
if [[ $- == *i* ]]; then
    # This is a good place to load graphic/ascii art, display system information, etc.
    if command -v pokego >/dev/null; then
        pokego --no-title -r 1,3,6
    elif command -v pokemon-colorscripts >/dev/null; then
        pokemon-colorscripts --no-title -r 1,3,6
    elif command -v fastfetch >/dev/null; then
        if do_render "image"; then
            fastfetch --logo-type kitty
        fi
    fi
fi

#   Overrides 
# HYDE_ZSH_NO_PLUGINS=1 # Set to 1 to disable loading of oh-my-zsh plugins, useful if you want to use your zsh plugins system 
# unset HYDE_ZSH_PROMPT # Uncomment to unset/disable loading of prompts from HyDE and let you load your own prompts
# HYDE_ZSH_COMPINIT_CHECK=1 # Set 24 (hours) per compinit security check // lessens startup time
# HYDE_ZSH_OMZ_DEFER=1 # Set to 1 to defer loading of oh-my-zsh plugins ONLY if prompt is already loaded

alias glow='glow -p'
alias markdown='glow -p'
commands() {
    cat <<'EOF'
glow / markdown  - glow -p (render markdown in pager)
reload           - re-source .zshrc
mcc              - MinecraftClient
cd <name>        - zoxide, jumps by frecency (not plain cd)
cdi              - zoxide interactive fzf pick
index            - bulk-seed zoxide with every dir under $HOME
claudio [dir]    - run claude --dangerously-skip-permissions, cd first if dir given
dev <project>    - tmux session in ~/Projects/<project>, launches claudio (reattaches if running)
open <name>      - fuzzy-find a file under $HOME and xdg-open it
commands         - this list
EOF
}

if [[ ${HYDE_ZSH_NO_PLUGINS} != "1" ]]; then
    #  OMZ Plugins 
    # manually add your oh-my-zsh plugins here
    plugins=(
        "sudo"
    )
fi