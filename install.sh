#!/bin/bash

# --- 1. 보안 비밀번호 입력 ---
echo -n "사용할 Termux 비밀번호를 입력하세요: "
read -s USER_PWD
echo "" 

# --- 2. [의존성 해결] 시스템 라이브러리 강제 업데이트 ---
# curl 실행 시 라이브러리 심볼 에러를 방지하기 위해 최우선적으로 실행합니다.
echo "라이브러리 의존성 복구 및 업데이트 시작..."
apt update && apt full-upgrade -y -o Dpkg::Options::="--force-confnew"

echo "패키지 매니저 준비 중..."
pkg update -y
pkg install -y dialog # 미러 선택기 실행을 위한 필수 패키지

# [추가] 1COWOO님의 리포지토리에서 미러 선택 도구 다운로드 및 실행
echo "가장 빠른 미러 서버를 찾는 중..."
curl -L "https://raw.githubusercontent.com/1COWOO/termux-config/main/termux-fastest-repo" -o $PREFIX/bin/termux-fastest-repo
chmod +x $PREFIX/bin/termux-fastest-repo

# 미러 선택기 실행 (사용자가 여기서 서버를 직접 선택합니다)
termux-fastest-repo

# 선택된 미러를 기반으로 전체 업그레이드 진행
echo "시스템 업그레이드 중..."
pkg upgrade -y -o Dpkg::Options::="--force-confnew"

# --- 3. 필수 패키지 설치 ---
echo "필수 패키지 설치 중..."
pkg install -y git neovim termux-api zip openssh eza nodejs-lts tur-repo glibc-repo tree wget termux-services bat tmux htop zoxide yazi dust duf net-tools tar procs python tealdeer zsh jq python-psutil
pkg update -y
pkg i glibc-runner python3.11 build-essential -y

# --- 4. 파이썬 도구 설치 ---
pip install trash-cli
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

# --- 7-2. Termux 특수키 설정 ---
echo "특수키 바 설정 중..."
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
alias kw-mirror='fastest-repo'

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
export LS_COLORS="${LS_COLORS}:*.jar=32:*.dis=31:*.gz=38;5;208:*.xz=38;5;208:*.zip=38;5;208:di=38;5;220:fi=38;5;208:ln=38;5;208:ex=38;5;208:or=38;5;208:mi=38;5;208:so=38;5;208:pi=38;5;208:bd=38;5;208:cd=38;5;208:su=38;5;208:sg=38;5;208:tw=38;5;208:ow=38;5;208:st=38;5;208:ca=38;5;208"
EOF

# --- 8-2. .tmux.conf 설정 파일 생성 ---
cat <<EOF > ~/.tmux.conf
set -g default-terminal "tmux-256color"
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D
set -g mouse on
set -as terminal-features ",tmux-256color:RGB"
set-window-option -g mode-keys vi

EOF

# --- 8-3. NvChad Starter 설치 및 커스텀 설정 ---
echo "NvChad Starter 설치 중..."
rm -rf ~/.config/nvim ~/.local/share/nvim ~/.cache/nvim
git clone https://github.com/NvChad/starter ~/.config/nvim --depth 1

mkdir -p ~/.config/nvim/lua
cat <<'EOF' > ~/.config/nvim/lua/chadrc.lua
---@type ChadrcConfig
local M = {}
M.base46 = { theme = "chadracula" }
M.ui = { theme_toggle = { "chadracula", "one_light" } }
return M
EOF

echo "NvChad 플러그인 동기화 중..."
nvim --headless "+Lazy! sync" +qa

# --- 9. 마무리 ---
pkg upgrade -y

echo "===================================================="
echo "      🚀 kowoo-termux 세팅이 모두 끝났습니다!       "
echo "===================================================="
echo " 1. Termux를 완전히 종료(Exit) 후 다시 여세요.      "
echo " 2. SSH 접속은 'sshd' 입력 후 8022 포트로 하세요.    "
echo " 3. 미러 변경이 필요하면 'termux-fastest-repo'를 입력하세요.   "
echo "===================================================="
