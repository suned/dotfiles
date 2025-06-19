dotfiles := justfile_directory()
home := env('HOME')

all: bat zed

bat:
    cp -rsn {{ dotfiles }}/bat/ {{ home }}/.config/

zed:
    cp -rsn {{ dotfiles }}/zed {{ home }}/.config/
