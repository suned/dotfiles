dotfiles := justfile_directory()
home := env('HOME')

all: bat zed direnv ssh starship git fish nix ipython claude devbox zsh

ipython:
    mkdir -p {{ home }}/.ipython
    stow -d {{ dotfiles }} -t {{ home }}/.ipython -R ipython

fish:
    mkdir -p {{ home }}/.config/fish
    stow -d {{ dotfiles }} -t {{ home }}/.config/fish -R fish

bat:
    mkdir -p {{ home }}/.config/bat
    stow -d {{ dotfiles }} -t {{ home }}/.config/bat -R bat

zed:
    mkdir -p {{ home }}/.config/zed
    stow -d {{ dotfiles }} -t {{ home }}/.config/zed -R zed

direnv:
    mkdir -p {{ home }}/.config/direnv
    stow -d {{ dotfiles }} -t {{ home }}/.config/direnv -R direnv

ssh:
    mkdir -p {{ home }}/.ssh
    stow -d {{ dotfiles }} -t {{ home }}/.ssh -R ssh

starship:
    ln -sfn {{ dotfiles }}/starship.toml {{ home }}/.config/starship.toml

git:
    mkdir -p {{ home }}/.config/git
    stow -d {{ dotfiles }} -t {{ home }}/.config/git -R git

nix:
    mkdir -p {{ home }}/.config/nix
    stow -d {{ dotfiles }} -t {{ home }}/.config/nix -R nix

claude:
    mkdir -p {{ home }}/.claude
    stow -d {{ dotfiles }} -t {{ home }}/.claude -R claude

devbox:
    mkdir -p {{ home }}/.local/share/devbox/global/default
    stow -d {{ dotfiles }} -t {{ home }}/.local/share/devbox/global/default -R devbox

zsh:
    ln -sfn {{ dotfiles }}/zsh/.zshrc {{ home }}/.zshrc

install-fonts:
    mkdir -p ~/Library/Fonts/JetBrainsMono
    # Fonts on macos are only recognized in ~/Library/Fonts if they are regular files,
    # not symlinks
    fonts=$(nix-store -qR {{ home }}/.local/share/devbox/global/default/.devbox/nix/profile/default/ | grep 'jetbrains-mono') && \
    cp -rn "$fonts/share/fonts/truetype/NerdFonts/JetBrainsMono/." ~/Library/Fonts/JetBrainsMono || true
