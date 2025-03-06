```
git
eza
doas
neovim
kitty
i3
i3status
dusnt
picom
fish
feh
dmenu
```

# Install dotfiles
```bash
echo "OBS: Install Doas if you use gentoo"

cat portage/package.use >> /etc/portage/package.use/dotfiles.use
./setup.sh -os gentoo
```

## Post Install

* Set Wallpaper
```bash
mkdir ~/Pictures
cp wallpaper.jpg ~/Pictures
cp .fehbg ~/
```

### Fonts

* Install fonts:
```bash
cp -r fonts ~/.local/share/
fc-cache -f -v
```

#### Install Discord Emoji/Fonts:

* Gentoo
```bash
echo "media-libs/freetype png" > /etc/portage/package.use/freetype
emerge noto noto-emoji noto-cjk
```
* Arch
```bash
pacman -S noto-fonts
pacman -S noto-fonts-emoji

# for bumblebee-status:
sudo pacman -S ttf-nerd-fonts-symbols
```
