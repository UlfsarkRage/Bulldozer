#!/bin/bash

# =========================================================================
# SCRIPT: ejecutar_todo.sh
# FUNCION: Ejecuta todos los scripts de pre-pentesting de Bulldozer en orden.
# NOTA: Este script solo ejecutará los scripts si pasan la verificación de argumentos.
# REQUIERE: Permisos de ejecución en todos los scripts de la carpeta.
# =========================================================================

# --- 1. Requerir Argumentos ---
if [ -z "$1" ] || [ -z "$2" ]; then
    echo " "
    echo "🚨 USO: ./scripts/ejecutar_todo.sh [URL_COMPLETA] [IP_O_DOMINIO]"
    echo "Ejemplo: ./scripts/ejecutar_todo.sh https://localhost:8080 127.0.0.1"
    echo " "
    echo "NOTA: Se necesitan dos argumentos: uno para Encabezados (URL) y otro para Puertos (IP/Dominio)."
    exit 1
fi

# Definición de variables en español
URL_OBJETIVO="$1"
IP_O_DOMINIO="$2"

echo " "
echo "========================================================="
echo "       🚀 Iniciando Suite de Pre-Pentesting BULLDOZER"
echo "========================================================="
echo "URL para Encabezados: ${URL_OBJETIVO}"
echo "IP/Dominio para Puertos: ${IP_O_DOMINIO}"
echo "---------------------------------------------------------"

# --- 2. Ejecutar Análisis de Encabezados ---
echo " "
echo "### PASO 1/2: Ejecutando Análisis de Encabezados (cURL + Gemini) ###"
# El script se ejecuta con el primer argumento (la URL)
./scripts/pre_analisis_encabezados.sh "${URL_OBJETIVO}"

# Manejo de error si el script anterior falló
if [ $? -ne 0 ]; then
    echo "--- ⚠️ ADVERTENCIA: Análisis de Encabezados falló. Continuado con Puertos. ---"
fi

echo "---------------------------------------------------------"

# --- 3. Ejecutar Análisis de Puertos ---
echo " "
echo "### PASO 2/2: Ejecutando Análisis de Puertos (Nmap + Gemini) ###"
# El script se ejecuta con el segundo argumento (la IP/Dominio)
./scripts/pre_analisis_puertos.sh "${IP_O_DOMINIO}"

# Manejo de error si el script anterior falló
if [ $? -ne 0 ]; then
    echo "--- ⚠️ ADVERTENCIA: Análisis de Puertos falló. Finalizando suite. ---"
fi

echo " "
echo "========================================================="
echo "          ✅ Suite BULLDOZER Finalizada"
echo "========================================================="