#!/bin/bash

# --- 1. 보안 비밀번호 입력 ---
echo -n "사용할 Termux 비밀번호를 입력하세요: "
read -s USER_PWD
echo "" 

# --- 2. 미러 및 시스템 업데이트 ---
echo "원찬 미러 설정 및 패키지 업데이트 중..."
echo "deb https://mirror.wonchan.net/termux/termux-main stable main" > $PREFIX/etc/apt/sources.list
termux-setup-storage
pkg update -y && pkg upgrade -y

# --- 3. 필수 패키지 설치 ---
pkg install -y git neovim termux-api ffmpeg zip openssh eza nodejs-lts tur-repo glibc-repo tree curl wget termux-services bat tmux htop zoxide yazi dust duf net-tools tar procs python tealdeer zsh jq
pkg update -y
pkg i glibc-runner python3.11 -y

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

# --- 7. Styling (Gruvbox Material & Font) ---
mkdir -p ~/.termux
cat <<EOF > ~/.termux/colors.properties
background: #1D2021
foreground: #D4BE98
cursor: #D4BE98
color0: #665C54
color8: #928374
color1: #EA6962
color9: #EA6962
color2: #A9B665
color10: #A9B665
color3: #D8A657
color11: #D8A657
color4: #7DAEA3
color12: #7DAEA3
color5: #D3869B
color13: #D3869B
color6: #89B482
color14: #89B482
color7: #D4BE98
color15: #D4BE98
EOF

curl -L "https://github.com/1COWOO/termux-config/raw/refs/heads/main/font.ttf" -o ~/.termux/font.ttf
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

# --- 9. 서비스 활성화 및 마무리 ---
sv-enable sshd

echo "===================================="
echo " kowoo-termux 세팅이 완료되었습니다! "
echo " Termux를 완전히 종료 후 다시 시작하세요. "
echo "===================================="
