# Si no es interactiva, salir
[[ $- != *i* ]] && return

# --- Historial ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# --- Completado ---
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select

# --- Prompt ---
# color4 = naranja #ff9e64 | color5 = morado #9d7cd8 | color6 = gris #787c99
autoload -Uz colors && colors
PROMPT='%F{4}[%m]%f %F{4}%1~%f %F{5}❯%f '

# --- Colores ls ---
eval "$(dircolors -p | sed 's/^DIR.*/DIR 36/' | dircolors -)"

# --- Extractor universal ---
ex() {
  case "$1" in
    *.tar.gz|*.tgz)   tar xzf "$1"   ;;
    *.tar.bz2|*.tbz2) tar xjf "$1"   ;;
    *.tar.xz)         tar xJf "$1"   ;;
    *.tar.zst)        tar xf  "$1"   ;;
    *.tar)            tar xf  "$1"   ;;
    *.zip)            unzip   "$1"   ;;
    *.rar)            unrar x "$1"   ;;
    *.7z)             7z x    "$1"   ;;
    *.gz)             gunzip  "$1"   ;;
    *.bz2)            bunzip2 "$1"   ;;
    *.xz)             unxz    "$1"   ;;
    *)                echo "No sé extraer '$1'" ;;
  esac
}

# --- Aliases Modernos ---
if command -v eza &>/dev/null; then
    alias ls='eza --icons=always --group-directories-first'
    alias ll='eza -la --icons=always --group-directories-first --git'
    alias lt='eza --tree --level=2 --icons=always'
else
    alias ls='ls --color=auto'
    alias ll='ls -la --color=auto'
fi

if command -v bat &>/dev/null; then
    alias cat='bat --paging=never --style=plain'
fi

alias grep='grep --color=auto'
alias fastfetch='fastfetch-adaptive.sh'
alias limpiar='limpieza-tararch.sh'
alias wifi='wifi-menu.sh'
alias bluetooth='bluetooth-menu.sh'
alias calendario='calendario.sh'
alias cal='calendario.sh'
alias fondos='wallpaper-picker.sh'
alias wallpaper='wallpaper-picker.sh'
alias taratrack='taratrack-app.sh'
alias series='taratrack-app.sh'
alias bateria='set-system-mode.sh uni'
alias uni='set-system-mode.sh uni'
alias normal='set-system-mode.sh normal'
alias gamer='set-system-mode.sh gamer'
alias modos='set-system-mode.sh'
alias rendimiento='set-system-mode.sh normal'
alias rdp='toggle-vpn-rdp.sh'
alias windows='toggle-vpn-rdp.sh'
alias raton='change-cursor.sh'
alias cursor='change-cursor.sh'
alias codex-acc='codex-acc'
alias codex-auth='codex-acc'

# --- Yazi Wrapper (cambia de carpeta al salir) ---
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# --- PATH ---
export PATH=~/.local/bin:~/.npm-global/bin:$PATH

# --- Variables ---
export BROWSER=/usr/bin/firefox

# --- Fastfetch solo en la primera Kitty de la sesión ---
_ff_lock="/tmp/fastfetch-done-${UID}"
if [[ -n "$KITTY_WINDOW_ID" && ! -f "$_ff_lock" ]]; then
    touch "$_ff_lock"
    fastfetch-adaptive.sh
fi
unset _ff_lock

# --- Zoxide ---
eval "$(zoxide init zsh)"

# --- FZF ---
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh
export FZF_DEFAULT_OPTS="
  --color=fg:#c9c9c9,fg+:#ffffff,bg:#0f0f0f,bg+:#2d2d2d
  --color=hl:#ff9e64,hl+:#ff9e64,info:#787c99,border:#2d2d2d
  --color=prompt:#ff9e64,pointer:#ff9e64,marker:#9ece6a"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:50 {}'"
export BAT_THEME="Monokai Extended"

# --- Plugins ---
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# --- Keybindings de Edición ---
bindkey '^H' backward-kill-word
bindkey '^W' backward-kill-word
bindkey '^[[3;5~' kill-word
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
