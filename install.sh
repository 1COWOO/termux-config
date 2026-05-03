#!/bin/bash

# --- 1. 보안 비밀번호 입력 ---
echo -n "사용할 Termux 비밀번호를 입력하세요: "
read -s USER_PWD
echo "" 

# --- 2. 시스템 업데이트 및 미러 서버 설정 ---
echo "패키지 업데이트 시작..."
termux-setup-storage

# 1. 일단 기본 미러에서 업데이트/업그레이드 진행 (중간 멈춤 방지)
pkg update -y
pkg upgrade -y -o Dpkg::Options::="--force-confnew"

# 2. 업그레이드가 끝난 후, 원찬 미러로 주소를 강제 교체
echo "원찬 미러 서버로 교체 중..."
echo "deb https://mirror.wonchan.net/termux/termux-main stable main" > $PREFIX/etc/apt/sources.list

# 3. 바뀐 주소로 다시 한 번 업데이트 (리스트 갱신)
pkg update -y

# --- 3. 필수 패키지 설치 ---
pkg install -y git neovim termux-api ffmpeg zip openssh eza nodejs-lts tur-repo glibc-repo tree curl wget termux-services bat tmux htop zoxide yazi dust duf net-tools tar procs python tealdeer zsh jq openjdk-21 python-psutil
pkg update -y
pkg i glibc-runner python3.11 build-essential -y

# --- 4. 파이썬 도구 설치 ---
pip install yt-dlp trash-cli
pip3.11 install thefuck
tldr --update

# --- 5. 비밀번호 및 기본 쉘 설정 ---
printf "$USER_PWD\n$USER_PWD\n" | passwd
chsh -s zsh

# --- 6. Oh My Zsh 및 플러그인 ---
rm -rf ~/.oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting

# --- 7. Styling (Dracula & Font) ---
mkdir -p ~/.termux
cat <<EOF > ~/.termux/colors.properties
# Dracula Theme for Termux
foreground: #f8f8f2
cursor: #f8f8f2
background: #282a36
color0: #000000
color1: #ff5555
color2: #50fa7b
color3: #f1fa8c
color4: #bd93f9
color5: #ff79c6
color6: #8be9fd
color7: #bfbfbf
color8: #4d4d4d
color9: #ff6e67
color10: #5af78e
color11: #f4f99d
color12: #caa9fa
color13: #ff92d0
color14: #9aedfe
color15: #e6e6e6
EOF

curl -L "https://github.com/1COWOO/termux-config/raw/refs/heads/main/font.ttf" -o ~/.termux/font.ttf
# --- 7-2. Termux 특수키(Extra Keys) 설정 ---
echo "특수키 바 설정 중..."
mkdir -p ~/.termux
cat <<EOF > ~/.termux/termux.properties
extra-keys = [['ESC','/','-','HOME','UP','END','PGUP'],['TAB','CTRL','ALT','LEFT','DOWN','RIGHT','PGDN']]
EOF
termux-reload-settings


# --- 8. .zshrc 설정 파일 생성 ---
cat <<'EOF' > ~/.zshrc
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git fast-syntax-highlighting zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

# --- 프롬프트 설정 (kowoo) ---
function precmd() {
  local EXIT="$?"
  if [[ "$EUID" -eq 0 ]]; then
    USER_COLOR="%F{red}"
    SYMBOL="#"
  else
    USER_COLOR="%F{39}"
    SYMBOL="$"
  fi

  if [[ $EXIT -eq 0 ]]; then
    SYMBOL_COLOR="%f"
  else
    SYMBOL_COLOR="%F{red}"
  fi
  ENDCHAR="${SYMBOL_COLOR}${SYMBOL}%f"
}
PROMPT='${USER_COLOR}kowoo%f@%F{208}kowoo-termux%f %F{39}%~%f ${ENDCHAR} '

# --- Alias 설정 ---
alias ls='eza --icons --group-directories-first'
alias ll='ls -l --git'
alias la='ls -a'
alias l='ls --classify'
alias lt='ls --tree'
alias vi='nvim'

# thefuck & zoxide 초기화
eval $(TF_SHELL=zsh thefuck --alias)
eval "$(zoxide init zsh)"

# trash-cli 설정
alias trash-list='TRASH_VOLUMES=$PWD trash-list'
alias trash-empty='TRASH_VOLUMES=$PWD trash-empty'
alias trash-put='TRASH_VOLUMES=$PWD trash-put'
alias trash-rm='TRASH_VOLUMES=$PWD trash-rm'
alias trash-restore='trash-restore --trash-dir=$HOME/.local/share/Trash'

# --- LS_COLORS 설정 ---
LS_COLORS="${LS_COLORS}:*.jar=32:*.dis=31:*.gz=38;5;208:*.xz=38;5;208:*.zip=38;5;208:di=38;5;220"
LS_COLORS="${LS_COLORS}:fi=38;5;208:ln=38;5;208:ex=38;5;208:or=38;5;208:mi=38;5;208:so=38;5;208:pi=38;5;208:bd=38;5;208:cd=38;5;208"
LS_COLORS="${LS_COLORS}:su=38;5;208:sg=38;5;208:tw=38;5;208:ow=38;5;208:st=38;5;208:ca=38;5;208"
export LS_COLORS
EOF

# --- 8-2. .tmux.conf 설정 파일 생성 ---
echo ".tmux.conf 설정 중..."
cat <<EOF > ~/.tmux.conf
# prefix 설정
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# 창 분할 단축키 (| 와 -)
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %

# Alt + 방향키로 창 이동 (Prefix 없이)
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# 마우스 사용 활성화
set -g mouse on

# 터미널 색상 최적화 (True Color 지원)
set -ga terminal-overrides ",xterm:Tc"

# vi 모드 키 바인딩
set-window-option -g mode-keys vi
EOF

# --- 8-3. NvChad Starter 설치 및 커스텀 설정 ---
echo "NvChad Starter 설치 및 테마 설정 중..."
rm -rf ~/.config/nvim ~/.local/share/nvim ~/.cache/nvim
git clone https://github.com/NvChad/starter ~/.config/nvim --depth 1

# [중요] 테마 설정을 '먼저' 생성합니다
mkdir -p ~/.config/nvim/lua
cat <<'EOF' > ~/.config/nvim/lua/chadrc.lua
---@type ChadrcConfig
local M = {}
M.base46 = { theme = "chadracula" }
M.ui = { theme_toggle = { "chadracula", "one_light" } }
return M
EOF

# 그 다음 플러그인 동기화를 진행합니다
echo "NvChad 플러그인 및 테마 에셋 동기화 중..."
nvim --headless "+Lazy! sync" +qa

pkg upgrade -y

echo "===================================================="
echo "      🚀 kowoo-termux 세팅이 모두 끝났습니다!       "
echo "===================================================="
echo " 1. Termux를 완전히 종료(Exit) 후 다시 여세요.      "
echo " 2. SSH 접속 포트는 8022 입니다.                    "
echo " 3. 멋진 Dracula 테마와 NvChad를 즐기세요!          "
echo "===================================================="
