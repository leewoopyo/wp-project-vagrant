#! /bin/bash

### 환경변수 설정 ###
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown vagrant:vagrant  /home/vagrant/.kube/config

### Kubectl 자동완성 기능 설치 ###
yum install bash-completion -y
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc

# enable docker command 
sudo usermod -aG docker vagrant

# .vimrc config for yaml syntax
echo "autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab autoindent" > /home/vagrant/.vimrc

# .nanorc config yaml syntax
tee /home/vagrant/.nanorc <<EOF
# nano editor config for yaml syntax highliting
syntax "default"
color white,black ".*"
## Keys
color magenta "^\s*[\$A-Za-z0-9_-]+\:"
color brightmagenta "^\s*@[\$A-Za-z0-9_-]+\:"

# Values
color white ":\s.+$"
# Booleans
icolor brightcyan " (y|yes|n|no|true|false|on|off)$"
## Numbers
color brightred " [[:digit:]]+(\.[[:digit:]]+)?"
## Arrays
color red "\[" "\]" ":\s+[|>]" "^\s*- "
## Reserved
color green "(^| )!!(binary|bool|float|int|map|null|omap|seq|set|str) "

## Comments
color brightwhite "#.*$"

## Errors
color ,red ":\w.+$"
color ,red ":'.+$"
color ,red ":".+$"
color ,red "\s+$"

## Non closed quote
color ,red "['\"][^['\"]]*$"

## Closed quotes
color yellow "['\"].*['\"]"

## Equal sign
color brightgreen ":( |$)"
# tab size
set tabsize 2
set tabstospaces
EOF
