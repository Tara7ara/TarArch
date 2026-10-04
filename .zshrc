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
alias taranas='cd ~/.mounts/TaraNAS'
alias bluetooth='bluetooth-menu.sh'
alias calendario='calendario.sh'
alias cal='calendario.sh'
alias fondos='wallpaper-flow'
alias wallpaper='wallpaper-flow'

# TaraScan contra el laboratorio Docker local (no hay que escribir el CIDR a mano)
alias tarascan-lab='tarascan --net 172.30.0.0/24'

# cb: portapapeles de Wayland. "algo | cb" copia; "cb" a secas pega.
cb() {
    if [ -t 0 ]; then
        wl-paste
    else
        wl-copy
    fi
}
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
alias cambiar-cursor='change-cursor.sh'
alias cambiar-curso='change-cursor.sh'
alias codex-acc='codex-acc'
alias codex-auth='codex-acc'
alias xampp-start='xampp-start'
alias xampp-stop='xampp-stop'
alias xampp-gui='xampp-gui'

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

# --- Objetivo de lab (set-target): $T en cada prompt, también en terminales ya abiertas ---
autoload -Uz add-zsh-hook
_load_target() {
    if [[ -s ~/.local/state/target ]]; then
        export T=$(<~/.local/state/target)
    else
        unset T
    fi
}
add-zsh-hook precmd _load_target

# --- Aviso de comando largo si estás en otra ventana ---
zmodload zsh/datetime 2>/dev/null
export LONG_CMD_THRESHOLD=${LONG_CMD_THRESHOLD:-15}
_cmd_start_time=0
_cmd_last_name=""

_long_cmd_preexec() {
    _cmd_start_time=$EPOCHSECONDS
    _cmd_last_name="$1"
}

_long_cmd_precmd() {
    local exit_code=$?
    if (( _cmd_start_time > 0 )); then
        local elapsed=$(( EPOCHSECONDS - _cmd_start_time ))
        if (( elapsed >= LONG_CMD_THRESHOLD )); then
            if (( exit_code != 130 && exit_code != 148 )); then
                local words=(${(z)_cmd_last_name})
                local first_word="${words[1]}"
                [[ "$first_word" == "sudo" ]] && first_word="${words[2]}"

                case "$first_word" in
                    nvim|vim|vi|nano|micro|emacs|man|less|more|top|htop|btop|glances|yazi|ranger|fzf|tmux|screen|ssh|lazygit)
                        ;;
                    *)
                        local term_pid="${KITTY_PID:-$PPID}"
                        local active_pid
                        active_pid=$(hyprctl activewindow 2>/dev/null | awk '/pid:/ {print $2}')
                        if [[ -n "$term_pid" && "$active_pid" != "$term_pid" ]]; then
                            local dur
                            if (( elapsed >= 3600 )); then
                                dur="$(printf '%dh %dm %ds' $(( elapsed / 3600 )) $(( (elapsed % 3600) / 60 )) $(( elapsed % 60 )))"
                            elif (( elapsed >= 60 )); then
                                dur="$(printf '%dm %ds' $(( elapsed / 60 )) $(( elapsed % 60 )))"
                            else
                                dur="${elapsed}s"
                            fi

                            local cmd_clean="${_cmd_last_name//[$'\t\r\n']/ }"
                            local cmd_short="${cmd_clean:0:45}"
                            [[ ${#cmd_clean} -gt 45 ]] && cmd_short="${cmd_short}…"

                            if (( exit_code == 0 )); then
                                notify-send -u normal -a "Terminal" -i "$HOME/.local/share/icons/tararch/terminal-done.png" \
                                    "Comando completado (${dur})" "$cmd_short" &!
                            else
                                notify-send -u critical -a "Terminal" -i "$HOME/.local/share/icons/tararch/terminal-error.png" \
                                    "Comando falló [exit ${exit_code}] (${dur})" "$cmd_short" &!
                            fi
                        fi
                        ;;
                esac
            fi
        fi
        _cmd_start_time=0
    fi
}
add-zsh-hook preexec _long_cmd_preexec
add-zsh-hook precmd _long_cmd_precmd

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

# --- Modo aplicación del terminal (arregla flechas que imprimen ^[[A etc.) ---
autoload -Uz add-zle-hook-widget
function zle_application_mode_start { echoti smkx }
function zle_application_mode_stop { echoti rmkx }
add-zle-hook-widget zle-line-init zle_application_mode_start
add-zle-hook-widget zle-line-finish zle_application_mode_stop

# --- Keybindings de Edición ---
bindkey '^H' backward-kill-word
bindkey '^W' backward-kill-word
bindkey '^[[3;5~' kill-word
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

# --- Esc Esc: antepone (o quita) sudo a la línea actual ---
_sudo_toggle() {
    [[ -z $BUFFER ]] && LBUFFER="$(fc -ln -1)"
    if [[ $BUFFER == sudo\ * ]]; then
        LBUFFER="${LBUFFER#sudo }"
    else
        LBUFFER="sudo $LBUFFER"
    fi
}
zle -N _sudo_toggle
bindkey '\e\e' _sudo_toggle
