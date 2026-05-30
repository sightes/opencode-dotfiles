# ============================================
# Fish Shell Configuration
# ============================================

# PATH local
fish_add_path ~/.local/bin
fish_add_path /usr/local/bin

# ============================================
# NVM para fish (agrega Node/opencode al PATH)
# ============================================
set -gx NVM_DIR "$HOME/.nvm"

# Busca la versión default o cualquier versión instalada
if test -d "$NVM_DIR/versions/node"
    set -l nvm_default (cat "$NVM_DIR/alias/default" 2>/dev/null)
    # Si el alias apunta a 'lts/*', busca la versión real
    if string match -q "lts/*" "$nvm_default"
        set nvm_default (ls "$NVM_DIR/versions/node/" | sort -V | tail -1)
    end
    # Si no hay alias, usa la última versión instalada
    if test -z "$nvm_default"
        set nvm_default (ls "$NVM_DIR/versions/node/" | sort -V | tail -1)
    end
    if test -d "$NVM_DIR/versions/node/$nvm_default/bin"
        fish_add_path "$NVM_DIR/versions/node/$nvm_default/bin"
    end
end

# Editor por defecto
set -gx EDITOR nano

# Colores basicos estilo Monokai
set -g fish_color_normal F8F8F2
set -g fish_color_command A6E22E
set -g fish_color_param F8F8F2
set -g fish_color_keyword F92672
set -g fish_color_quote E6DB74
set -g fish_color_redirection AE81FF
set -g fish_color_end F92672
set -g fish_color_error F92672
set -g fish_color_operator 66D9EF
set -g fish_color_escape A1EFE4
set -g fish_color_autosuggestion 75715E
set -g fish_color_cwd 66D9EF
set -g fish_color_user A6E22E
set -g fish_color_host AE81FF
set -g fish_color_host_remote F92672

# ============================================
# Solo configuraciones interactivas
# ============================================
if status is-interactive
    # Detectar si estamos en consola pura (TTY real)
    # En TTY los iconos de Nerd Fonts no se renderizan bien
    set -l current_tty (tty 2>/dev/null)
    if string match -q "/dev/tty*" $current_tty
        set -g IS_TTY 1
    else
        set -g IS_TTY 0
    end

    # --- Alias comunes ---
    alias gs="git status"
    alias ga="git add"
    alias gc="git commit -m"
    alias gp="git push"
    alias gl="git pull"
    alias dps="docker ps"
    alias dpsa="docker ps -a"
    alias di="docker images"
    alias dc="docker compose"
    alias dcu="docker compose up -d"
    alias dcd="docker compose down"
    alias dlogs="docker logs -f"
    alias pps="podman ps"
    alias ppsa="podman ps -a"
    alias pi="podman images"
    alias ports="lsof -iTCP -sTCP:LISTEN -P -n 2>/dev/null"
    alias myip="curl ifconfig.me"
    alias disk="df -h"
    alias mem="memory_pressure 2>/dev/null | head -4"
    alias cpu="btop"
    alias update="brew update && brew upgrade && brew cleanup"

    # --- Alias con iconos (solo si NO estamos en TTY) ---
    if test $IS_TTY -eq 0
        # Terminal grafica: eza con colores (sin iconos para evitar cuadrados)
        alias ls="eza --group-directories-first"
        alias ll="eza -lah --group-directories-first"
        alias la="eza -la --group-directories-first"
        alias lt="eza --tree --level=2"
        alias cat="bat"
        alias grep="rg"
        alias find="fd"

        # Starship prompt con system info (CPU/RAM)
        starship init fish | source

        # Oh My Posh (desactivado mientras se usa Starship)
        # if test -f ~/.config/oh-my-posh/nordtron-ascii.omp.json
        #     oh-my-posh init fish --config ~/.config/oh-my-posh/nordtron-ascii.omp.json | source
        # end
    else
        # Consola pura (TTY): sin iconos para evitar cuadrados raros
        alias ls="eza --group-directories-first"
        alias ll="eza -lah --group-directories-first"
        alias la="eza -la --group-directories-first"
        alias lt="eza --tree --level=2"
        alias cat="bat --style=plain --paging=never"
        alias grep="rg"
        alias find="fd"

        # Paleta de colores moderna para TTY
        # Solo en consolas virtuales reales (no en terminales graficas)
        function __set_tty_colors
            printf '\e]P01e1e1e'  # Negro
            printf '\e]P1ff5555'  # Rojo
            printf '\e]P250fa7b'  # Verde
            printf '\e]P3f1fa8c'  # Amarillo
            printf '\e]P4bd93f9'  # Azul
            printf '\e]P5ff79c6'  # Magenta
            printf '\e]P68be9fd'  # Cyan
            printf '\e]P7f8f8f2'  # Blanco
            printf '\e]P86272a4'  # Negro brillante
            printf '\e]P9ff6e6e'  # Rojo brillante
            printf '\e]PA69ff94'  # Verde brillante
            printf '\e]PBf4f99d'  # Amarillo brillante
            printf '\e]PCd6acff'  # Azul brillante
            printf '\e]PDff92df'  # Magenta brillante
            printf '\e]PEa4ffff'  # Cyan brillante
            printf '\e]PFffffff'  # Blanco brillante
            printf '\e[0m'
        end
        __set_tty_colors

        # ============================================
        # Prompt nativo para TTY (con efecto Polaris)
        # ============================================

        # El simbolo del prompt cambia de color en cada Enter
        function fish_prompt
            set -l last_status $status
            set -l prompt_symbol '$'
            if fish_is_root_user
                set prompt_symbol '#'
            end

            # Efecto brillo: rota entre Amarillo, Blanco, Cyan, Magenta
            set -l polaris_colors bryellow brwhite brcyan brmagenta
            if not set -q __polaris_phase
                set -g __polaris_phase 0
            end
            set __polaris_phase (math "($__polaris_phase + 1) % 4")
            set -l polaris_color $polaris_colors[(math $__polaris_phase + 1)]

            # Indicador de error del ultimo comando
            if test $last_status -ne 0
                set_color red
                echo -n "[$last_status] "
            end

            # Usuario y host
            set_color green
            echo -n (whoami)
            set_color normal
            echo -n "@"
            set_color cyan
            echo -n (hostname -s)
            set_color normal
            echo -n " "

            # Directorio actual
            set_color yellow
            echo -n "["(prompt_pwd)"]"
            set_color normal

            # Rama de Git (si estamos en un repo)
            set -l git_branch (git rev-parse --abbrev-ref HEAD 2>/dev/null)
            if test -n "$git_branch"
                set_color magenta
                echo -n " (git:$git_branch)"
                set_color normal
            end

            # Salto de linea y simbolo brillante
            echo
            set_color $polaris_color
            echo -n "$prompt_symbol "
            set_color normal
        end

        function fish_right_prompt
            # Vacio para no saturar
        end
    end

    # --- System Info (una vez por sesion) ---
    if not set -q __fish_sysinfo_displayed
        set -g __fish_sysinfo_displayed 1
        set_color brcyan
        echo -n "  OS: "
        set_color normal
        sw_vers -productName 2>/dev/null; or echo -n "macOS"
        echo -n " "
        sw_vers -productVersion 2>/dev/null
        set_color brcyan
        echo -n "  Kernel: "
        set_color normal
        uname -r
        set_color brcyan
        echo -n "  Uptime: "
        set_color normal
        uptime | sed 's/.*up //' | sed 's/,.*//'
        set_color brcyan
        echo -n "  Shell: "
        set_color normal
        echo "fish "(fish --version | string split " " | tail -1)
        echo ""
    end
end
