#!/usr/bin/bash

REPO_NAME="dotfiles"
# these directories should exist in this repo
dirs=(
  ".config"
  ".gnupg"
)
debian_files=(
  ".xinitrc"
  ".xprofile"
  ".Xresources"
)
files=(
  ".bashrc"
  ".gitconfig"
  ".tmux.conf"
  ".vimrc"
  ".zshrc"
)
packages=(
  "chromium"
  "curl"
  "fzf"
  "git"
  "gnupg"
  "i3"
  "jq"
  "mesa-utils"
  "neovim"
  "rxvt-unicode"
  "silversearcher-ag"
  "suckless-tools"
  "tmux"
  "unzip"
  "unp"
  "xinit"
  "xorg"
  "xserver-xorg"
  "xutils"
  "zsh"
  "zplug" # zsh plugin manager
)

check_packages_installed() {
  for package in "${packages[@]}"; do
    if [[ $package == "silversearcher-ag" ]]; then
      which ag > /dev/null || echo "$package is not installed"
    elif [[ $package == "neovim" ]]; then
      which nvim > /dev/null || echo "$package is not installed"
    else
      which $package > /dev/null || echo "$package is not installed"
    fi
  done
}

# $1 one of the dirs defined in $dirs in an absolute path format
generate_nested_configs() {
  echo "working with $1"
  [[ -d $1 ]] && ls -a $1 | while read content; do
    if [[ ! $content == "." && ! $content == ".." ]]; then
      file_path=$1/$content
      # remove the "dotfiles/" string
      destination=${file_path//$REPO_NAME\/''}

      if [[ -d $1/$content ]]; then
        mkdir -p $destination && generate_nested_configs $1/$content
      elif [[ -f $1/$content ]]; then
        # TODO: handle file already exists
        ln -s $1/$content $destination
      fi
    fi
  done
}

install_packages() {
  for package in "${packages[@]}"; do
    echo -e "Installing $package..."
    sudo apt install -y $package
  done
}

link_files() {
  for file in "${files[@]}"; do
    [[ -f $HOME/$file ]] && mv $HOME/$file $HOME/$file_$(date +"%Y-%m-%d_%H:%M:%S").bkp
    ln -sf $HOME/$REPO_NAME/$file $HOME/$file
  done
}

link_debian_files() {
  for file in "${debian_files[@]}"; do
    [[ -f $HOME/$file ]] && mv $HOME/$file $HOME/$file_$(date +"%Y-%m-%d_%H:%M:%S").bkp
    ln -sf $HOME/$REPO_NAME/setup/debian/$file $HOME/$file
  done
}

setup_tmux() {
  tpm="$HOME/.tmux/plugins"
  export TMUX_PLUGIN_MANAGER_PATH=$tpm
  git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
  $tpm/tpm/bin/install_plugins
  unset TMUX_PLUGIN_MANAGER_PATH
}

setup_vim() {
  [[ ! -d $HOME/.vim/plugged ]] && curl -fLo $HOME/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  nvim -c "PlugInstall" -c "qa!"
}

main() {
  echo "Starting Debian based system setup..."

  install_packages
  link_files
  link_debian_files
  for dir in "${dirs[@]}"; do
    generate_nested_configs $HOME/$REPO_NAME/$dir
  done
  setup_tmux
  setup_vim
  # set zsh as the default shell
  # NOTE: this requires a logout to take effect
  chsh -s $(which zsh)

  echo "Debian based system setup finished. Restart the system now"
}

main