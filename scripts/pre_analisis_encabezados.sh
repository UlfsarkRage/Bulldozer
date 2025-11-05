#!/bin/bash

# =========================================================================
# SCRIPT: pre_analisis_encabezados.sh
# ALIAS: PRE_ANALISIS_ENCABEZADOS
# FUNCION: Verifica la configuración de Encabezados (Headers) de Seguridad HTTP.
# REQUIERE: curl, gcloud y gemini CLI.
# =========================================================================

# --- 1. Requerir Argumento (URL) ---
if [ -z "$1" ]; then
    echo " "
    echo "🚨 USO: ./scripts/pre_analisis_encabezados.sh [URL_COMPLETA]"
    echo "Ejemplo: ./scripts/pre_analisis_encabezados.sh https://localhost:8080"
    exit 1
fi

# Definición de variables en español
URL_OBJETIVO="$1"
ARCHIVO_SALIDA_TEMPORAL="headers_output_temp.txt"

echo " "
echo "--- 🔎 Ejecutando prueba de 'PRE_ANALISIS_ENCABEZADOS' en: ${URL_OBJETIVO} ---"

# --- 2. Ejecutar la prueba de seguridad (curl) ---
# '-I': Solo obtiene los encabezados.
# '-s': Modo silencioso (no muestra la barra de progreso ni errores).
# '-k': Permite conexiones SSL no válidas/autofirmadas (útil para entornos de desarrollo local).
# '2>/dev/null': Redirige los errores de curl (salida 2) a un lugar vacío para limpiar la terminal.
curl -I -s -k "${URL_OBJETIVO}" > "${ARCHIVO_SALIDA_TEMPORAL}" 2>/dev/null

# Verificación de errores básicos
if [ $? -ne 0 ]; then
    echo "❌ Error al ejecutar curl. Verifica la URL o la conexión."
    rm -f "${ARCHIVO_SALIDA_TEMPORAL}" # Limpia el archivo temporal si existe
    exit 1
fi

# --- 3. Definir y Ejecutar el Prompt a Gemini ---
echo " "
echo "🤖 Enviando datos a Gemini para análisis..."

# El prompt es CRÍTICO: debe ser específico para asegurar una respuesta de calidad.
# Pedimos: 1) Análisis de riesgos y 2) Soluciones específicas de configuración (Nginx/Apache).
PROMPT="Soy un desarrollador web. Analiza los siguientes encabezados HTTP que capturé de la URL ${URL_OBJETIVO}. 1) Explica si hay riesgos de seguridad (e.g., falta de HSTS, X-Content-Type-Options, versiones de servidor). 2) Proporciona las directivas de configuración exactas para Nginx y Apache para solucionar los problemas y añadir encabezados de seguridad faltantes. Los encabezados están en el archivo adjunto:"

# Ejecutar Gemini CLI: utiliza --file para adjuntar la salida del escaneo (el archivo temporal).
gemini generate --prompt "${PROMPT}" --file "${ARCHIVO_SALIDA_TEMPORAL}"

# --- 4. Limpieza ---
# Eliminar el archivo temporal
rm -f "${ARCHIVO_SALIDA_TEMPORAL}"

echo " "
echo "---------------------------------------------------------"
echo "✅ Prueba de encabezados finalizada."