cd ~
git clone git@github.com:jhuggart/dotfiles.git ~/.vim
ln -s ~/.vim/.vimrc ~/.vimrc
ln -s ~/.vim/.tmux.conf ~/.tmux.conf
ln -s ~/.vim/.zshrc ~/.zshrc
cd ~/.vim
git submodule update --init
