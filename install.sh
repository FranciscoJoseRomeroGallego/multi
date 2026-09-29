#!/bin/bash
#
# ================================================================
#  MULTI-TOOL - Instalador
# ----------------------------------------------------------------
#  Analiza qué hay instalado y qué no, instala las dependencias
#  que falten, prepara el entorno de FinalRecon y deja el proyecto
#  listo para ejecutar ./multi.bash
#
#  Uso:
#     git clone --recurse-submodules <URL>
#     cd multi
#     ./install.sh
#     ./multi.bash
# ================================================================

set -u

# ----------------------------------------------------------------
#  Rutas y utilidades
# ----------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FINALRECON_DIR="$SCRIPT_DIR/web/FinalRecon"
VENV_DIR="$FINALRECON_DIR/.venv"

# Colores (se desactivan si la salida no es un terminal).
if [ -t 1 ]; then
    C_OK="\033[0;32m"; C_ERR="\033[0;31m"; C_WARN="\033[0;33m"
    C_INFO="\033[0;36m"; C_RST="\033[0m"
else
    C_OK=""; C_ERR=""; C_WARN=""; C_INFO=""; C_RST=""
fi

ok()   { echo -e "   ${C_OK}[OK]${C_RST}   $*"; }
info() { echo -e "   ${C_INFO}[..]${C_RST}   $*"; }
warn() { echo -e "   ${C_WARN}[!!]${C_RST}   $*"; }
err()  { echo -e "   ${C_ERR}[XX]${C_RST}   $*"; }

section() {
    echo
    echo -e "${C_INFO}================================================================${C_RST}"
    echo -e "${C_INFO}  $*${C_RST}"
    echo -e "${C_INFO}================================================================${C_RST}"
}

have() { command -v "$1" >/dev/null 2>&1; }

# ----------------------------------------------------------------
#  Elevación de privilegios (para apt)
# ----------------------------------------------------------------

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    if have sudo; then
        SUDO="sudo"
    else
        SUDO=""
        warn "No se encontró 'sudo' y no eres root. La instalación de paquetes del"
        warn "sistema puede fallar. Ejecuta este script como root si es necesario."
    fi
fi

# ----------------------------------------------------------------
#  Detección del gestor de paquetes
# ----------------------------------------------------------------

PKG_MGR=""
if   have apt-get; then PKG_MGR="apt"
elif have pacman;  then PKG_MGR="pacman"
elif have dnf;     then PKG_MGR="dnf"
elif have zypper;  then PKG_MGR="zypper"
fi

APT_UPDATED=0

# Instala un paquete del sistema según el gestor detectado.
pkg_install() {
    local pkg="$1"
    case "$PKG_MGR" in
        apt)
            if [ "$APT_UPDATED" -eq 0 ]; then
                info "Actualizando índice de paquetes (apt update)..."
                $SUDO apt-get update -y >/dev/null 2>&1
                APT_UPDATED=1
            fi
            $SUDO apt-get install -y "$pkg"
            ;;
        pacman) $SUDO pacman -S --noconfirm "$pkg" ;;
        dnf)    $SUDO dnf install -y "$pkg" ;;
        zypper) $SUDO zypper install -y "$pkg" ;;
        *)      return 1 ;;
    esac
}

# ----------------------------------------------------------------
#  Comprobación / instalación de una herramienta por comando
#  $1 = comando que debe existir   $2 = paquete a instalar
# ----------------------------------------------------------------

MISSING_MANUAL=()

ensure_tool() {
    local cmd="$1"
    local pkg="${2:-$1}"

    if have "$cmd"; then
        ok "$cmd ya está instalado"
        return 0
    fi

    warn "$cmd no está instalado -> se intentará instalar '$pkg'"

    if [ -z "$PKG_MGR" ]; then
        err "No se detectó un gestor de paquetes compatible."
        MISSING_MANUAL+=("$cmd")
        return 1
    fi

    if pkg_install "$pkg" >/dev/null 2>&1; then
        if have "$cmd"; then
            ok "$cmd instalado correctamente"
            return 0
        fi
    fi

    err "No se pudo instalar '$cmd' automáticamente."
    MISSING_MANUAL+=("$cmd")
    return 1
}

# ----------------------------------------------------------------
#  Comprobación de wordlists (rutas usadas por los scripts)
#  $1 = ruta que debe existir    $2 = paquete que la aporta
# ----------------------------------------------------------------

ensure_wordlist() {
    local path="$1"
    local pkg="$2"

    if [ -e "$path" ]; then
        ok "wordlist presente: $path"
        return 0
    fi

    warn "Falta la wordlist: $path -> se intentará instalar '$pkg'"

    if [ -z "$PKG_MGR" ]; then
        MISSING_MANUAL+=("wordlist:$path (paquete $pkg)")
        return 1
    fi

    pkg_install "$pkg" >/dev/null 2>&1
    if [ -e "$path" ]; then
        ok "wordlist instalada: $path"
        return 0
    fi

    warn "No se pudo asegurar la wordlist: $path"
    MISSING_MANUAL+=("wordlist:$path (paquete $pkg)")
    return 1
}

# ================================================================
#  INICIO
# ================================================================

clear
section "MULTI-TOOL - Instalador"
echo
info "Directorio del proyecto : $SCRIPT_DIR"
if [ -n "$PKG_MGR" ]; then
    info "Gestor de paquetes      : $PKG_MGR"
else
    warn "No se detectó gestor de paquetes (apt/pacman/dnf/zypper)."
    warn "Las herramientas que falten deberás instalarlas manualmente."
fi

# ----------------------------------------------------------------
#  1) Herramientas de línea de comandos
# ----------------------------------------------------------------

section "1/5  Herramientas necesarias"

# Nota: los nombres de paquete usados corresponden a Debian/Kali/Parrot (apt).
# En otras distribuciones puede que el paquete tenga otro nombre.
ensure_tool git         git
ensure_tool python3     python3
ensure_tool pip3        python3-pip
ensure_tool gobuster    gobuster
ensure_tool ffuf        ffuf
ensure_tool dirsearch   dirsearch
ensure_tool hydra       hydra
ensure_tool sshpass     sshpass

# python3-venv no aporta un comando propio: se comprueba el módulo.
if python3 -c "import venv" >/dev/null 2>&1; then
    ok "módulo python venv disponible"
else
    warn "módulo python venv no disponible -> se intentará instalar 'python3-venv'"
    pkg_install python3-venv >/dev/null 2>&1
    if python3 -c "import venv" >/dev/null 2>&1; then
        ok "python3-venv instalado correctamente"
    else
        err "No se pudo preparar python3-venv (necesario para FinalRecon)."
        MISSING_MANUAL+=("python3-venv")
    fi
fi

# ----------------------------------------------------------------
#  2) Wordlists usadas por los scripts
# ----------------------------------------------------------------

section "2/5  Wordlists"

ensure_wordlist "/usr/share/seclists"                        seclists
ensure_wordlist "/usr/share/wordlists/dirb/common.txt"       dirb
ensure_wordlist "/usr/share/dirb/wordlists/big.txt"          dirb

# ----------------------------------------------------------------
#  rockyou.txt y rockyou-rev.txt
#  Son demasiado grandes para el repositorio (>100 MB), asi que se
#  generan a partir del rockyou del sistema:
#    - rockyou.txt      = descomprimir /usr/share/wordlists/rockyou.txt.gz
#    - rockyou-rev.txt  = rockyou.txt con las lineas en orden inverso
# ----------------------------------------------------------------

ROCKYOU_DST="$SCRIPT_DIR/diccionarios/contraseñas/rockyou.txt"
ROCKYOU_REV="$SCRIPT_DIR/diccionarios/contraseñas/rockyou-rev.txt"
ROCKYOU_GZ="/usr/share/wordlists/rockyou.txt.gz"
ROCKYOU_SYS="/usr/share/wordlists/rockyou.txt"

mkdir -p "$SCRIPT_DIR/diccionarios/contraseñas"

if [ -s "$ROCKYOU_DST" ]; then
    ok "rockyou.txt ya presente en diccionarios/contraseñas"
else
    # Asegurar que existe algun rockyou en el sistema.
    if [ ! -f "$ROCKYOU_GZ" ] && [ ! -f "$ROCKYOU_SYS" ]; then
        warn "No se encontró rockyou en el sistema -> se intentará instalar 'wordlists'"
        pkg_install wordlists >/dev/null 2>&1
    fi

    if [ -f "$ROCKYOU_SYS" ]; then
        info "Copiando rockyou.txt desde el sistema..."
        cp "$ROCKYOU_SYS" "$ROCKYOU_DST" && ok "rockyou.txt listo"
    elif [ -f "$ROCKYOU_GZ" ]; then
        info "Descomprimiendo rockyou.txt.gz del sistema..."
        if gunzip -c "$ROCKYOU_GZ" > "$ROCKYOU_DST"; then
            ok "rockyou.txt generado"
        else
            err "No se pudo descomprimir rockyou.txt.gz"
            rm -f "$ROCKYOU_DST"
        fi
    else
        warn "No hay rockyou disponible. Coloca manualmente tu rockyou.txt en:"
        warn "   diccionarios/contraseñas/rockyou.txt"
        MISSING_MANUAL+=("diccionarios/contraseñas/rockyou.txt")
    fi
fi

# rockyou-rev.txt = rockyou.txt invertido linea a linea.
if [ -s "$ROCKYOU_REV" ]; then
    ok "rockyou-rev.txt ya presente"
elif [ -s "$ROCKYOU_DST" ]; then
    info "Generando rockyou-rev.txt (orden inverso)..."
    if command -v tac >/dev/null 2>&1; then
        tac "$ROCKYOU_DST" > "$ROCKYOU_REV" && ok "rockyou-rev.txt generado"
    else
        # Alternativa por si 'tac' no estuviera disponible.
        sed '1!G;h;$!d' "$ROCKYOU_DST" > "$ROCKYOU_REV" && ok "rockyou-rev.txt generado"
    fi
else
    warn "No se pudo generar rockyou-rev.txt (falta rockyou.txt)."
fi

# ----------------------------------------------------------------
#  3) Submódulo FinalRecon
# ----------------------------------------------------------------

section "3/5  Submódulo FinalRecon"

if [ ! -f "$FINALRECON_DIR/finalrecon.py" ]; then
    warn "FinalRecon no está clonado. Inicializando submódulo..."
    if [ -d "$SCRIPT_DIR/.git" ] || [ -f "$SCRIPT_DIR/.git" ]; then
        ( cd "$SCRIPT_DIR" && git submodule update --init --recursive )
    fi
fi

if [ -f "$FINALRECON_DIR/finalrecon.py" ]; then
    ok "FinalRecon presente en web/FinalRecon"
else
    err "No se encontró web/FinalRecon/finalrecon.py"
    err "Clona el repositorio con:  git clone --recurse-submodules <URL>"
    err "o ejecuta:                 git submodule update --init --recursive"
fi

# ----------------------------------------------------------------
#  4) Entorno virtual de FinalRecon
# ----------------------------------------------------------------

section "4/5  Entorno de Python para FinalRecon"

if [ -f "$FINALRECON_DIR/finalrecon.py" ]; then
    if [ ! -d "$VENV_DIR" ]; then
        info "Creando entorno virtual en web/FinalRecon/.venv ..."
        if python3 -m venv "$VENV_DIR"; then
            ok "Entorno virtual creado"
        else
            err "No se pudo crear el entorno virtual."
        fi
    else
        ok "El entorno virtual ya existe"
    fi

    if [ -d "$VENV_DIR" ]; then
        info "Instalando dependencias de Python de FinalRecon..."
        # shellcheck disable=SC1091
        source "$VENV_DIR/bin/activate"
        pip install --upgrade pip >/dev/null 2>&1
        if [ -f "$FINALRECON_DIR/requirements.txt" ]; then
            if pip install -r "$FINALRECON_DIR/requirements.txt"; then
                ok "Dependencias de FinalRecon instaladas"
            else
                err "Fallo al instalar las dependencias de FinalRecon."
            fi
        else
            warn "No se encontró requirements.txt en FinalRecon."
        fi
        deactivate 2>/dev/null || true
    fi
else
    warn "Se omite el entorno de Python (FinalRecon no está presente)."
fi

# ----------------------------------------------------------------
#  5) Permisos y directorios de resultados
# ----------------------------------------------------------------

section "5/5  Permisos y directorios"

info "Marcando scripts como ejecutables..."
chmod +x "$SCRIPT_DIR/multi.bash" 2>/dev/null
[ -f "$FINALRECON_DIR/finalrecon.py" ] && chmod +x "$FINALRECON_DIR/finalrecon.py" 2>/dev/null
find "$SCRIPT_DIR/web" -maxdepth 1 -type f -exec chmod +x {} \; 2>/dev/null
find "$SCRIPT_DIR/contraseñas" -maxdepth 1 -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null
ok "Permisos aplicados"

info "Creando directorios de resultados..."
mkdir -p "$SCRIPT_DIR/web/FinalRecon-Results"
mkdir -p "$SCRIPT_DIR/web/Vhosts_Discover"
ok "Directorios de resultados listos"

info "Asegurando carpetas de diccionarios..."
mkdir -p "$SCRIPT_DIR/diccionarios/listado-webs"
mkdir -p "$SCRIPT_DIR/diccionarios/contraseñas"
ok "Carpetas de diccionarios listas (coloca tus wordlists dentro)"

# ================================================================
#  RESUMEN
# ================================================================

section "Resumen"

if [ "${#MISSING_MANUAL[@]}" -eq 0 ]; then
    ok "Todo listo. Ejecuta el programa con:"
    echo
    echo -e "        ${C_OK}./multi.bash${C_RST}"
    echo
else
    warn "La instalación terminó, pero hay elementos que debes revisar/instalar a mano:"
    echo
    for m in "${MISSING_MANUAL[@]}"; do
        echo "        - $m"
    done
    echo
    warn "Instálalos con el gestor de paquetes de tu sistema y vuelve a ejecutar install.sh."
fi

echo
