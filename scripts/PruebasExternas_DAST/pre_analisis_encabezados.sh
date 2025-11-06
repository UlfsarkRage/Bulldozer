#!/bin/bash

# =========================================================================
# SCRIPT: pre_analisis_encabezados.sh
# ALIAS: PRE_ANALISIS_ENCABEZADOS
# FUNCION: Verifica la configuración de Encabezados (Headers) de Seguridad HTTP.
# =========================================================================

# --- 1. Requerir Argumento (URL) ---
if [ -z "$1" ]; then
    echo " "
    echo "🚨 USO: ./scripts/pre_analisis_encabezados.sh [URL_COMPLETA]"
    echo "Ejemplo: ./scripts/pre_analisis_encabezados.sh https://localhost:8080"
    exit 1
fi

# --- Variables de Configuración y Archivos ---
URL_OBJETIVO="$1"
FECHA_HORA=$(date +"%Y%m%d_%H%M%S")
ARCHIVO_SALIDA_TEMPORAL="headers_output_temp.txt"
ARCHIVO_LIMPIO="${ARCHIVO_SALIDA_TEMPORAL}.clean"
ARCHIVO_REPORTE="resultados/REPORTE_ENCABEZADOS_${FECHA_HORA}.txt"

# --- RUTA CORREGIDA DEL BINARIO GCLOUD (CRÍTICO) ---
GCLOUD_BIN="/home/unknown_ronin/google-cloud-sdk/bin/gcloud"
PROJECT_ID="$(${GCLOUD_BIN} config get-value project)"
REGION="us-central1"

# =================================================================
# BLOQUE DE VERIFICACIÓN DE CREDENCIALES (FUERZA LA RENOVACIÓN)
# =================================================================
if ! "${GCLOUD_BIN}" auth print-access-token > /dev/null 2>&1; then
    echo " "
    echo "🚨 ERROR: Las credenciales de Google Cloud han expirado o faltan."
    echo "🚨 Acción: Forzando la re-autenticación (Esto abrirá un navegador)."
    
    # Intenta forzar una nueva autenticación de credenciales de aplicación
    "${GCLOUD_BIN}" auth application-default login --scopes=https://www.googleapis.com/auth/cloud-platform
    
    if [ $? -ne 0 ]; then
        echo "❌ ERROR FATAL: Falló la re-autenticación. Revise su conexión o permisos."
        exit 1
    fi
    echo "✅ Autenticación renovada con éxito."
    echo " "
fi
# =================================================================

echo " "
echo "--- 🔎 Ejecutando prueba de 'PRE_ANALISIS_ENCABEZADOS' en: ${URL_OBJETIVO} ---"

# --- 2. Ejecutar la prueba de seguridad (curl) ---
curl -I -s -k "${URL_OBJETIVO}" > "${ARCHIVO_SALIDA_TEMPORAL}" 2>/dev/null

if [ $? -ne 0 ]; then
    echo "❌ Error al ejecutar curl. Verifica la URL o la conexión."
    rm -f "${ARCHIVO_SALIDA_TEMPORAL}"
    exit 1
fi

# --- LIMPIEZA CRÍTICA DE DATOS ---
cat "${ARCHIVO_SALIDA_TEMPORAL}" | tr -d '\n\r"' > "${ARCHIVO_LIMPIO}"

# --- 3. Definir y Ejecutar el Prompt a Gemini (usando cURL/API REST) ---
echo " "
echo "🤖 Enviando datos a Gemini para análisis..."

PROMPT="Eres un experto en ciberseguridad que genera reportes ejecutivos e intuitivos. Analiza los siguientes encabezados HTTP que capturé de la URL ${URL_OBJETIVO}. Tu respuesta debe ser una lista de chequeo concisa. Para cada encabezado de seguridad clave (Content-Security-Policy, X-Frame-Options, HSTS, X-XSS-Protection, Cookies), indica: 1) Su estado (OK, FALTANTE, A MEJORAR, RIESGO). 2) Una explicación de una línea. 3) Una recomendación de acción de una línea. La respuesta DEBE empezar con el encabezado # CHECKLIST DE SEGURIDAD. Responde únicamente con el reporte formateado de lista concisa en lenguaje natural y humanizado:"

# 3.1 Ejecutar CURL y guardar la respuesta JSON en una variable
JSON_RESPONSE=$(curl -s -X POST \
  -H "Authorization: Bearer $(${GCLOUD_BIN} auth print-access-token)" \
  -H "Content-Type: application/json" \
  "https://${REGION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${REGION}/publishers/google/models/gemini-2.5-flash:generateContent" \
  -d @- << EOF
{
  "contents": [
    {
      "role": "user",
      "parts": [
        {"text": "${PROMPT}"},
        {"text": "Data:\n$(cat ${ARCHIVO_LIMPIO})"}
      ]
    }
  ]
}
EOF
)

# 3.2 Extraer el texto de la respuesta JSON usando jq
TEXTO_REPORTE=$(echo "${JSON_RESPONSE}" | jq -r '.candidates[0].content.parts[0].text')

# 4. Generar el Archivo de Reporte
echo "--- 📝 GENERANDO REPORTE: ${ARCHIVO_REPORTE} ---"

# El reporte es el texto limpio de Gemini
echo "${TEXTO_REPORTE}" > "${ARCHIVO_REPORTE}"

# Imprimir el análisis final al usuario
echo "--- ✅ Análisis de Gemini (Resumen) ---"
echo "${TEXTO_REPORTE}"

# --- 5. Limpieza ---
rm -f "${ARCHIVO_SALIDA_TEMPORAL}" "${ARCHIVO_LIMPIO}"

echo " "
echo "---------------------------------------------------------"
echo "✅ Prueba de encabezados finalizada. Reporte guardado."