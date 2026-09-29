#!/bin/bash

# Directorio donde reside este script, independientemente de desde dónde se ejecute.
# Permite que el proyecto funcione en cualquier ruta tras clonarlo o descargarlo.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

banner() {
clear
echo "   ███╗   ███╗██╗   ██╗██╗  ████████╗██╗    ████████╗ ██████╗  ██████╗ ██╗"
echo "   ████╗ ████║██║   ██║██║  ╚══██╔══╝██║    ╚══██╔══╝██╔═══██╗██╔═══██╗██║"
echo "   ██╔████╔██║██║   ██║██║     ██║   ██║       ██║   ██║   ██║██║   ██║██║"
echo "   ██║╚██╔╝██║██║   ██║██║     ██║   ██║       ██║   ██║   ██║██║   ██║██║"
echo "   ██║ ╚═╝ ██║╚██████╔╝███████╗██║   ██║       ██║   ╚██████╔╝╚██████╔╝███████╗"
echo "   ╚═╝     ╚═╝ ╚═════╝ ╚══════╝╚═╝   ╚═╝       ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝"
}

menu() {
while true; do
    clear
    banner
    echo
    echo "   ╚══(1) Ataques Web"
    echo "   ╚══(2) Ataques Contraseñas"
    echo "   ╚══(3) Exit"
    echo "   ║"
    read -p "       ╚══════> " input

    case $input in
        1) web ;;
        2) contraseñas ;;
        3) exit;;
        *) echo "Opción no válida"; sleep 1 ;;
    esac
done
}

web() {
while true; do
    clear
    banner
    cd "$SCRIPT_DIR/web/" || return
    echo "Has seleccionado Ataques Web"
    echo
    echo "   ╚══(1) Gobuster(VHOST)"
    echo "   ╚══(2) FinalRecon - Reconocimiento Web"
    echo "   ╚══(3) ffuf"
    echo "   ╚══(4) Volver"
    echo "   ║"
    read -p "       ╚══════> " input

    case $input in
        1) ./vhost_search ;;
        2) finalrecon_menu ;;
        3) ./dir_search_web_ffuf ;;
        4) menu ;;
        *) echo "Opción no válida"; sleep 1 ;;
    esac
    read -p "Pulsa enter para volver..."
done
}

# -------------------------------------------------------------------
# FinalRecon
# -------------------------------------------------------------------

# Devuelve 0 si una opción está seleccionada.
fr_selected() {
    case "$1" in
        headers)  [[ "$FR_HEADERS" == "1" ]] ;;
        sslinfo)  [[ "$FR_SSLINFO" == "1" ]] ;;
        whois)    [[ "$FR_WHOIS" == "1" ]] ;;
        crawl)    [[ "$FR_CRAWL" == "1" ]] ;;
        dns)      [[ "$FR_DNS" == "1" ]] ;;
        sub)      [[ "$FR_SUB" == "1" ]] ;;
        dir)      [[ "$FR_DIR" == "1" ]] ;;
        wayback)  [[ "$FR_WAYBACK" == "1" ]] ;;
        ps)       [[ "$FR_PS" == "1" ]] ;;
        full)     [[ "$FR_FULL" == "1" ]] ;;
        *)        return 1 ;;
    esac
}

fr_toggle() {
    case "$1" in
        1) [[ "$FR_HEADERS" == "1" ]] && FR_HEADERS=0 || FR_HEADERS=1 ;;
        2) [[ "$FR_SSLINFO" == "1" ]] && FR_SSLINFO=0 || FR_SSLINFO=1 ;;
        3) [[ "$FR_WHOIS" == "1" ]] && FR_WHOIS=0 || FR_WHOIS=1 ;;
        4) [[ "$FR_CRAWL" == "1" ]] && FR_CRAWL=0 || FR_CRAWL=1 ;;
        5) [[ "$FR_DNS" == "1" ]] && FR_DNS=0 || FR_DNS=1 ;;
        6) [[ "$FR_SUB" == "1" ]] && FR_SUB=0 || FR_SUB=1 ;;
        7) [[ "$FR_DIR" == "1" ]] && FR_DIR=0 || FR_DIR=1 ;;
        8) [[ "$FR_WAYBACK" == "1" ]] && FR_WAYBACK=0 || FR_WAYBACK=1 ;;
        9) [[ "$FR_PS" == "1" ]] && FR_PS=0 || FR_PS=1 ;;
    esac
}

fr_checkbox() {
    [[ "$1" == "1" ]] && echo "[X]" || echo "[ ]"
}

fr_show_options() {
    clear
    banner
    echo
    echo "   FinalRecon - Selección de reconocimiento"
    echo "   Selecciona/desmarca con el número y pulsa C para continuar."
    echo
    printf "   %s 1) Información de cabeceras HTTP\n" "$(fr_checkbox "$FR_HEADERS")"
    printf "   %s 2) Información del certificado SSL/TLS\n" "$(fr_checkbox "$FR_SSLINFO")"
    printf "   %s 3) Información WHOIS del dominio\n" "$(fr_checkbox "$FR_WHOIS")"
    printf "   %s 4) Rastreo de enlaces y recursos del sitio\n" "$(fr_checkbox "$FR_CRAWL")"
    printf "   %s 5) Enumeración de registros DNS\n" "$(fr_checkbox "$FR_DNS")"
    printf "   %s 6) Enumeración de subdominios\n" "$(fr_checkbox "$FR_SUB")"
    printf "   %s 7) Búsqueda de directorios y archivos\n" "$(fr_checkbox "$FR_DIR")"
    printf "   %s 8) Consulta de URLs históricas de Wayback\n" "$(fr_checkbox "$FR_WAYBACK")"
    printf "   %s 9) Escaneo rápido de puertos\n" "$(fr_checkbox "$FR_PS")"
    echo
    echo "   [C] Continuar"
    echo "   [X] Cancelar"
}

fr_ask_yes_no() {
    local prompt="$1"
    local answer
    while true; do
        read -r -p "   $prompt [s/N]: " answer
        case "${answer,,}" in
            s|si|sí|y|yes) return 0 ;;
            n|no|"") return 1 ;;
            *) echo "   Responde S o N." ;;
        esac
    done
}

fr_extra_options() {
    local value

    # Siempre puede ser útil: permite no seguir redirecciones si no se desea.
    if fr_ask_yes_no "¿Permitir redirecciones HTTP?"; then
        FR_REDIRECT=1
    else
        FR_REDIRECT=0
    fi

    # Timeout: relevante para cualquier módulo que haga peticiones.
    if fr_ask_yes_no "¿Quieres modificar el tiempo máximo de espera de las peticiones?"; then
        while true; do
            read -r -p "   Timeout en segundos [30]: " value
            value="${value:-30}"
            if [[ "$value" =~ ^[0-9]+([.][0-9]+)?$ ]] && awk "BEGIN {exit !($value > 0)}"; then
                FR_TIMEOUT="$value"
                break
            fi
            echo "   Introduce un número positivo."
        done
    else
        FR_TIMEOUT=""
    fi

    # SSL verification solo tiene sentido si se consulta HTTPS.
    if fr_selected sslinfo || fr_selected headers || fr_selected crawl || \
       fr_selected sub || fr_selected dir || fr_selected wayback || fr_selected ps; then
        if fr_ask_yes_no "¿Desactivar la verificación SSL/TLS?"; then
            FR_SSL_VERIFY=0
        else
            FR_SSL_VERIFY=1
        fi
    fi

    if fr_selected sslinfo; then
        if fr_ask_yes_no "¿Quieres especificar un puerto SSL distinto de 443?"; then
            while true; do
                read -r -p "   Puerto SSL [443]: " value
                value="${value:-443}"
                if [[ "$value" =~ ^[0-9]+$ ]] && (( value >= 1 && value <= 65535 )); then
                    FR_SSL_PORT="$value"
                    break
                fi
                echo "   Puerto no válido."
            done
        else
            FR_SSL_PORT=""
        fi
    fi

    if fr_selected dir; then
        if fr_ask_yes_no "¿Quieres cambiar el número de hilos de búsqueda de directorios?"; then
            while true; do
                read -r -p "   Hilos [30]: " value
                value="${value:-30}"
                if [[ "$value" =~ ^[0-9]+$ ]] && (( value >= 1 )); then
                    FR_DT="$value"
                    break
                fi
                echo "   Introduce un entero positivo."
            done
        else
            FR_DT=""
        fi

        if fr_ask_yes_no "¿Quieres usar una wordlist personalizada?"; then
            read -r -p "   Ruta de la wordlist: " value
            FR_WORDLIST="$value"
        else
            FR_WORDLIST=""
        fi

        if fr_ask_yes_no "¿Quieres especificar extensiones de archivos?"; then
            read -r -p "   Extensiones (ej. txt,xml,php): " value
            FR_EXTENSIONS="$value"
        else
            FR_EXTENSIONS=""
        fi
    fi

    if fr_selected ps; then
        if fr_ask_yes_no "¿Quieres cambiar el número de hilos del escaneo de puertos?"; then
            while true; do
                read -r -p "   Hilos [50]: " value
                value="${value:-50}"
                if [[ "$value" =~ ^[0-9]+$ ]] && (( value >= 1 )); then
                    FR_PT="$value"
                    break
                fi
                echo "   Introduce un entero positivo."
            done
        else
            FR_PT=""
        fi
    fi

    if fr_selected dns; then
        if fr_ask_yes_no "¿Quieres usar servidores DNS personalizados?"; then
            read -r -p "   Servidor(es) DNS: " value
            FR_DNS_SERVER="$value"
        else
            FR_DNS_SERVER=""
        fi
    fi

    # Exportación: se ofrece si se ha seleccionado al menos una fase.
    if fr_ask_yes_no "¿Quieres cambiar el formato de exportación?"; then
        while true; do
            read -r -p "   Formato (txt/json/csv) [txt]: " value
            value="${value:-txt}"
            case "${value,,}" in
                txt|json|csv)
                    FR_OUTPUT="${value,,}"
                    break
                    ;;
                *) echo "   Formato no reconocido." ;;
            esac
        done
    else
        FR_OUTPUT=""
    fi

    # API key solo se pregunta si el usuario realmente quiere añadir una.
    if fr_ask_yes_no "¿Quieres añadir una API key de un servicio compatible?"; then
        read -r -p "   API key (formato servicio@clave): " value
        FR_API_KEY="$value"
    else
        FR_API_KEY=""
    fi
}

finalrecon_menu() {
    local target
    local choice
    local -a args

    # Inicialización.
    FR_HEADERS=0
    FR_SSLINFO=0
    FR_WHOIS=0
    FR_CRAWL=0
    FR_DNS=0
    FR_SUB=0
    FR_DIR=0
    FR_WAYBACK=0
    FR_PS=0
    FR_FULL=0

    clear
    banner
    echo
    echo "   FinalRecon - Reconocimiento Web"
    echo
    read -r -p "   URL objetivo: " target

    if [[ -z "$target" ]]; then
        echo "   Debes indicar una URL."
        sleep 2
        return
    fi

    while true; do
        fr_show_options
        read -r -p "   Selección: " choice

        case "${choice,,}" in
            1|2|3|4|5|6|7|8|9)
                fr_toggle "$choice"
                ;;
            c)
                break
                ;;
            x)
                return
                ;;
            *)
                echo "   Opción no válida."
                sleep 1
                ;;
        esac
    done

    if ! fr_selected headers && ! fr_selected sslinfo && ! fr_selected whois && \
       ! fr_selected crawl && ! fr_selected dns && ! fr_selected sub && \
       ! fr_selected dir && ! fr_selected wayback && ! fr_selected ps; then
        echo
        echo "   No has seleccionado ningún módulo."
        sleep 2
        return
    fi

    fr_extra_options

    # Todos los resultados se guardan en esta ubicación.
    # FinalRecon seguirá creando dentro su estructura habitual
    # (host/fecha/hora, según su comportamiento por defecto).
    FR_EXPORT_DIR="$SCRIPT_DIR/web/FinalRecon-Results/"

    args=(--url "$target")

    fr_selected headers  && args+=(--headers)
    fr_selected sslinfo  && args+=(--sslinfo)
    fr_selected whois    && args+=(--whois)
    fr_selected crawl    && args+=(--crawl)
    fr_selected dns      && args+=(--dns)
    fr_selected sub      && args+=(--sub)
    fr_selected dir      && args+=(--dir)
    fr_selected wayback  && args+=(--wayback)
    fr_selected ps       && args+=(--ps)

    [[ -n "$FR_DT" ]]            && args+=(-dt "$FR_DT")
    [[ -n "$FR_PT" ]]            && args+=(-pt "$FR_PT")
    [[ -n "$FR_TIMEOUT" ]]       && args+=(-T "$FR_TIMEOUT")
    [[ -n "$FR_WORDLIST" ]]      && args+=(-w "$FR_WORDLIST")
    [[ "$FR_REDIRECT" == "1" ]]  && args+=(-r)
    [[ "$FR_SSL_VERIFY" == "0" ]] && args+=(-s)
    [[ -n "$FR_SSL_PORT" ]]      && args+=(-sp "$FR_SSL_PORT")
    [[ -n "$FR_DNS_SERVER" ]]    && args+=(-d "$FR_DNS_SERVER")
    [[ -n "$FR_EXTENSIONS" ]]    && args+=(-e "$FR_EXTENSIONS")
    [[ -n "$FR_OUTPUT" ]]        && args+=(-o "$FR_OUTPUT")
    args+=(-cd "$FR_EXPORT_DIR")
    [[ -n "$FR_API_KEY" ]]       && args+=(-k "$FR_API_KEY")

    clear
    banner
    echo
    echo "   Ejecutando FinalRecon..."
    echo "   Objetivo: $target"
    echo
    printf '   Comando: ./finalrecon.py'
    printf ' %q' "${args[@]}"
    echo
    echo
    cd "$SCRIPT_DIR/web/FinalRecon" || { echo "   No se encuentra web/FinalRecon"; sleep 2; return; }
    source .venv/bin/activate
    ./finalrecon.py  "${args[@]}"

    echo
    read -r -p "Pulsa enter para volver..."
}

contraseñas() {
while true; do
    clear
    banner
    echo "Has seleccionado Ataques Web"
    echo
    echo "   ╚══(1) Fuerza-Bruta"
    echo "   ╚══(2) Volver"
    echo "   ║"
    read -p "       ╚══════> " input

    case $input in
        1) bruteforce ;;
        2) menu ;;
        *) echo "Opción no válida"; sleep 1 ;;
    esac
done
}

bruteforce() {
while true; do
    clear
    banner
    cd "$SCRIPT_DIR/contraseñas/" || return
    echo "Has seleccionado Ataques Web"
    echo
    echo "   ╚══(1) SSH"
    echo "   ╚══(2) SSH-REV"
    echo "   ╚══(3) SSH-User"
    echo "   ╚══(4) Volver"
    echo "   ║"
    read -p "       ╚══════> " input

    case $input in
        1) ./bruteforce_ssh.sh ;;
        2) ./bruteforce_ssh-rev.sh ;;
        3) ./bruteforce_ssh-user.sh ;;
        4) contraseñas ;;
        *) echo "Opción no válida"; sleep 1 ;;
    esac
    read -p "Pulsa enter para volver..."
done
}

# ejecución
menu
