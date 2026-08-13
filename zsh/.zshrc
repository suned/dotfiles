autoload -Uz compinit && compinit
autoload -Uz bashcompinit && bashcompinit

if command -v devbox &>/dev/null
then
    eval "$(devbox global shellenv)"
fi

if command -v direnv &>/dev/null
then
    eval "$(direnv hook zsh)"
fi
