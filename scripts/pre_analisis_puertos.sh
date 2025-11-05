#!/bin/bash

# =========================================================================
# SCRIPT: pre_analisis_puertos.sh
# ALIAS: PRE_ANALISIS_PUERTOS
# FUNCION: Ejecuta un escaneo de puertos básico con Nmap y analiza la salida.
# =========================================================================

# --- 1. Requerir Argumento (IP/Dominio) ---
if [ -z "$1" ]; then
    echo " "
    echo "🚨 USO: ./scripts/pre_analisis_puertos.sh [IP_O_DOMINIO]"
    echo "Ejemplo: ./scripts/pre_analisis_puertos.sh 127.0.0.1"
    exit 1
fi

# --- Variables de Configuración y Archivos ---
OBJETIVO="$1"
FECHA_HORA=$(date +"%Y%m%d_%H%M%S")
ARCHIVO_SALIDA_TEMPORAL="nmap_output_temp.txt"
ARCHIVO_REPORTE="resultados/REPORTE_PUERTOS_${FECHA_HORA}.txt"

# --- RUTA CORREGIDA DEL BINARIO GCLOUD (CRÍTICO) ---
GCLOUD_BIN="/home/unknown_ronin/google-cloud-sdk/bin/gcloud"
PROJECT_ID="$(${GCLOUD_BIN} config get-value project)"
REGION="us-central1"

echo " "
echo "--- 🔎 Ejecutando prueba de 'PRE_ANALISIS_PUERTOS' en: ${OBJETIVO} ---"

# --- 2. Ejecutar la prueba de seguridad (Nmap) ---
nmap -F "${OBJETIVO}" -oN "${ARCHIVO_SALIDA_TEMPORAL}"

if [ $? -ne 0 ]; then
    echo "❌ Error al ejecutar nmap. Verifica la instalación de nmap o el objetivo."
    rm -f "${ARCHIVO_SALIDA_TEMPORAL}"
    exit 1
fi

# --- CORRECCIÓN: USAR TODO EL ARCHIVO ---
DATOS_NMAP=$(cat "${ARCHIVO_SALIDA_TEMPORAL}")

# --- 3. Definir y Ejecutar el Prompt a Gemini (usando cURL/API REST) ---
echo " "
echo "🤖 Enviando datos a Gemini para análisis..."

PROMPT="Eres un analista de seguridad de infraestructura que genera reportes ejecutivos e intuitivos. Analiza los siguientes resultados de escaneo de puertos Nmap para el objetivo ${OBJETIVO}. Tu respuesta debe ser una lista de chequeo concisa. Para cada puerto ABIERTO, indica: 1) Su estado (RIESGO ALTO, RIESGO BAJO, OK). 2) El servicio detectado. 3) Una recomendación de acción de una línea (Ej: 'Bloquear en firewall', 'Actualizar servicio'). Si no hay puertos abiertos, indica solo el estado OK y la recomendación de una línea de monitoreo. La respuesta DEBE empezar con el encabezado # CHECKLIST DE PUERTOS. Responde únicamente con el reporte formateado de lista concisa en lenguaje natural y humanizado:"

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
        {"text": "Nmap Data:\n${DATOS_NMAP}"}
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
rm -f "${ARCHIVO_SALIDA_TEMPORAL}"

echo " "
echo "---------------------------------------------------------"
echo "✅ Prueba de puertos finalizada. Reporte guardado."