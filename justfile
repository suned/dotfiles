dotfiles := justfile_directory()
home := env('HOME')

all: bat zed direnv ssh starship git fish nix ipython

ipython:
    cp -rsn {{ dotfiles }}/ipython/* {{ home }}/.ipython
fish:
    cp -rsn {{ dotfiles }}/fish {{ home }}/.config

bat:
    cp -rsn {{ dotfiles }}/bat/ {{ home }}/.config/

zed:
    cp -rsn {{ dotfiles }}/zed {{ home }}/.config/

direnv:
    cp -rsn {{ dotfiles }}/direnv {{ home }}/.config/

ssh:
    cp -rsn {{ dotfiles }}/ssh/* {{ home }}/.ssh/

starship:
    cp -sn {{ dotfiles }}/starship.toml {{ home }}/.config/

git:
    cp -rsn {{ dotfiles }}/git/ {{ home }}/.config/

nix:
    cp -rsn {{ dotfiles }}/nix {{ home }}/.config
