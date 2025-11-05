#!/bin/bash

# =========================================================================
# SCRIPT: pre_analisis_puertos.sh
# ALIAS: PRE_ANALISIS_PUERTOS
# FUNCION: Escanea puertos comunes con nmap y analiza la salida con Gemini.
# REQUIERE: nmap, gcloud y gemini CLI.
# =========================================================================

# --- 1. Requerir Argumento (IP o Dominio) ---
if [ -z "$1" ]; then
    echo " "
    echo "🚨 USO: ./scripts/pre_analisis_puertos.sh [IP_O_DOMINIO]"
    echo "Ejemplo: ./scripts/pre_analisis_puertos.sh 127.0.0.1"
    exit 1
fi

# Definición de variables en español
IP_O_DOMINIO="$1"
PUERTOS_COMUNES="21,22,23,25,80,110,139,143,3389,443,8080" # Puertos comunes a verificar
ARCHIVO_SALIDA_TEMPORAL="puertos_output_temp.txt"

echo " "
echo "--- 🔎 Ejecutando prueba de 'PRE_ANALISIS_PUERTOS' en: ${IP_O_DOMINIO} ---"

# --- 2. Ejecutar la prueba de seguridad (nmap) ---
# '-Pn': Trata el host como activo (no hace ping para acelerar).
# '-p': Especifica los puertos a escanear.
# '-oN': Guarda la salida normal de nmap en el archivo temporal.
# '2>/dev/null': Suprime la salida de errores (salida 2) de nmap.
nmap -Pn -p ${PUERTOS_COMUNES} ${IP_O_DOMINIO} -oN ${ARCHIVO_SALIDA_TEMPORAL} 2>/dev/null

# Verificación de errores básicos
if [ $? -ne 0 ]; then
    echo "❌ Error al ejecutar nmap. Verifica si nmap está instalado."
    rm -f "${ARCHIVO_SALIDA_TEMPORAL}"
    exit 1
fi

# --- 3. Definir y Ejecutar el Prompt a Gemini ---
echo " "
echo "🤖 Enviando datos a Gemini para análisis..."

# El prompt debe enfocar a Gemini en el análisis de seguridad de los servicios encontrados.
PROMPT="Soy un desarrollador web. Analiza el siguiente resultado del escaneo de puertos Nmap para el host ${IP_O_DOMINIO}. 1) Explica brevemente si hay riesgos de seguridad por los puertos abiertos o servicios inusuales. 2) Sugiere acciones de configuración de firewall (ej: iptables o Windows Firewall) o medidas de seguridad para mitigar el riesgo de los puertos que deben estar cerrados."

# Ejecutar Gemini CLI, adjuntando la salida de nmap
gemini generate --prompt "${PROMPT}" --file "${ARCHIVO_SALIDA_TEMPORAL}"

# --- 4. Limpieza ---
# Eliminar el archivo temporal
rm -f "${ARCHIVO_SALIDA_TEMPORAL}"

echo " "
echo "---------------------------------------------------------"
echo "✅ Prueba de puertos finalizada."