# Configuracion Fish para Mac

Guia paso a paso para replicar esta configuracion de Fish Shell en macOS.

## 1. Prerrequisitos: Homebrew

Si no tienes Homebrew instalado:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## 2. Instalar Fish Shell

```bash
brew install fish
```

Agregar fish como shell por defecto:

```bash
# Verificar que fish esta en /etc/shells
if ! grep -q "$(which fish)" /etc/shells; then
    echo "$(which fish)" | sudo tee -a /etc/shells
fi

# Cambiar shell por defecto
chsh -s $(which fish)
```

## 3. Instalar herramientas CLI modernas

```bash
brew install \
  eza \
  bat \
  fd \
  ripgrep \
  btop \
  starship \
  git \
  curl \
  fzf
```

| Herramienta | Reemplaza a |
|-------------|-------------|
| `eza`       | `ls`        |
| `bat`       | `cat`       |
| `fd`        | `find`      |
| `ripgrep`   | `grep`      |

## 4. Instalar NVM (Node Version Manager)

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
```

Luego instala una version de Node:

```bash
nvm install --lts
nvm alias default lts/*
```

## 5. Copiar configuracion de Fish

Usa el script `bootstrap.sh` incluido en este repo (ahora incluye `.config/fish`):

```bash
cd ~/Documentos/DEV/opencode-dotfiles  # o donde clonaste el repo
./bootstrap.sh
```

O manualmente:

```bash
# Backup de tu config actual
mv ~/.config/fish ~/.config/fish.backup.$(date +%Y%m%d)

# Crear symlink
ln -sf ~/Documentos/DEV/opencode-dotfiles/.config/fish ~/.config/fish
```

## 6. Instalar plugins de Fish (Fisher)

```bash
# Instalar Fisher (plugin manager)
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher

# Instalar plugins del repo (incluye fish-ai)
fisher install < ~/.config/fish/fish_plugins
```

**Nota:** `fish-ai` requiere configuracion adicional de API keys. Ejecuta `fish_ai_put_api_key` dentro de fish para configurarlo.

## 7. Configurar Starship (Prompt)

```bash
# Starship ya se instalo con brew
# Crea la configuracion basica si quieres personalizar:
mkdir -p ~/.config
touch ~/.config/starship.toml
```

El `config.fish` activa Starship automaticamente en terminales graficas (no TTY).

## 8. Ajustes especificos para Mac

El `config.fish` incluido funciona en macOS con algunos alias que cambian:

| Linux (actual) | macOS equivalente |
|----------------|-------------------|
| `free -h`      | `vm_stat` o `btop`|
| `sudo apt ...` | `brew update && brew upgrade` |
| `update`       | Editar `config.fish` linea con `apt` -> `brew` |

**Para adaptar el alias `update`:**

Edita `~/.config/fish/config.fish` y cambia:

```fish
# De:
alias update="sudo apt update && sudo apt upgrade -y"

# A:
alias update="brew update && brew upgrade"
```

**Para adaptar el alias `mem`:**

```fish
# De:
alias mem="free -h"

# A:
alias mem="vm_stat"
```

## 9. Abrir nueva terminal

Cierre y vuelve a abrir la terminal, o ejecuta:

```bash
exec fish -l
```

Deberias ver la constelacion Polaris de bienvenida y el prompt de Starship activo.

## 10. Verificacion rapida

Comandos para verificar que todo funciona:

```bash
fish --version          # Debe mostrar 4.x
which eza bat rg fd      # Deben encontrarse
starship --version       # Debe mostrar version
node --version           # Via NVM
opencode --version       # Si instalaste opencode via NVM
```

## Estructura de archivos

```
.config/fish/
├── config.fish          # Configuracion principal
├── fish_plugins         # Plugins de Fisher
├── fish_variables       # Variables universales de fish
├── functions/           # Funciones personalizadas
├── conf.d/              # Configuraciones por plugin
├── completions/         # Autocompletados
└── themes/              # Temas (si aplica)
```

## Notas

- La deteccion de TTY (`/dev/tty*`) no aplica en macOS normalmente; siempre usaras la rama de terminal grafica.
- Los colores Monokai y la constelacion Polaris funcionan igual en Mac.
- `fish-ai` es opcional; si no lo necesitas, eliminalo de `fish_plugins` y reinstala.
