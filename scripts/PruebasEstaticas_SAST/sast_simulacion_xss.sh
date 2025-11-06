#!/bin/bash

# =========================================================================
# SCRIPT: sast_simulacion_xss.sh
# FUNCION: Analiza el riesgo de XSS en un archivo de código provisto.
# =========================================================================

# --- 1. Requerir Argumento (Ruta del Archivo) ---
if [ -z "$1" ]; then
    echo " "
    echo "🚨 ERROR: Se requiere la ruta completa del archivo de código."
    echo " USO: ./scripts/sast_simulacion_xss.sh /ruta/a/archivo.php"
    exit 1
fi

RUTA_ARCHIVO="$1"
FECHA_HORA=$(date +"%Y%m%d_%H%M%S")
ARCHIVO_REPORTE="resultados/REPORTE_SAST_XSS_${FECHA_HORA}.txt"

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
echo "--- 🔎 Ejecutando prueba de 'SAST_XSS' en archivo: ${RUTA_ARCHIVO} ---"

# --- 2. Leer y Codificar el Código Fuente del Archivo en Base64 (CORRECCIÓN) ---
CODIGO_FUENTE_BASE64=$(cat "${RUTA_ARCHIVO}" | base64)

echo "🤖 Enviando contenido del archivo codificado en Base64 para análisis de XSS..."

# --- 3. Definir y Ejecutar el Prompt a Gemini con Base64 ---
PROMPT="Eres un experto en ciberseguridad que genera reportes ejecutivos e intuitivos. El siguiente código está codificado en Base64. Primero, **DECODIFICA** el contenido. Luego, analiza el código decodificado buscando riesgos de **Cross-Site Scripting (XSS)**, donde la entrada del usuario se imprime directamente en el HTML sin sanitización. Tu respuesta debe ser una lista de chequeo concisa. Indica: 1) El Riesgo (ALTO, BAJO, o NO DETECTADO). 2) La Explicación (qué permite hacer la falla o por qué es seguro). 3) La Solución (un solo paso de refactorización de código usando escape o sanitización de salida). La respuesta DEBE empezar con el encabezado # CHECKLIST DE RIESGO SAST - XSS. Responde únicamente con el reporte formateado de lista concisa en lenguaje natural y humanizado:"

# Ejecutar CURL y guardar la respuesta JSON en una variable
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
        {"text": "CÓDIGO CODIFICADO EN BASE64 PARA ANÁLISIS:\n${CODIGO_FUENTE_BASE64}"}
      ]
    }
  ]
}
EOF
)

# Extraer el texto de la respuesta JSON usando jq
TEXTO_REPORTE=$(echo "${JSON_RESPONSE}" | jq -r '.candidates[0].content.parts[0].text')

# Generar el Archivo de Reporte
echo "--- 📝 GENERANDO REPORTE: ${ARCHIVO_REPORTE} ---"
echo "${TEXTO_REPORTE}" > "${ARCHIVO_REPORTE}"

# Imprimir el análisis final al usuario
echo "--- ✅ Análisis de Gemini (Resumen) ---"
echo "${TEXTO_REPORTE}"

echo " "
echo "---------------------------------------------------------"
echo "✅ Prueba SAST de XSS finalizada. Reporte guardado."