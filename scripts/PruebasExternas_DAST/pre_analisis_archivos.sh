#!/bin/bash

# =========================================================================
# SCRIPT: pre_analisis_archivos.sh
# ALIAS: PRE_ANALISIS_ARCHIVOS
# FUNCION: Busca archivos y directorios sensibles comúnmente expuestos.
# =========================================================================

# --- 1. Requerir Argumento (URL) ---
if [ -z "$1" ]; then
    echo " "
    echo "🚨 USO: ./scripts/pre_analisis_archivos.sh [URL_COMPLETA]"
    echo "Ejemplo: ./scripts/pre_analisis_archivos.sh https://localhost:8080"
    exit 1
fi

# --- Variables de Configuración y Archivos ---
URL_BASE="$1"
FECHA_HORA=$(date +"%Y%m%d_%H%M%S")
ARCHIVO_SALIDA_TEMPORAL="archivos_output_temp.txt"
ARCHIVO_REPORTE="resultados/REPORTE_ARCHIVOS_${FECHA_HORA}.txt"

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
echo "--- 🔎 Ejecutando prueba de 'PRE_ANALISIS_ARCHIVOS' en: ${URL_BASE} ---"

# --- 2. Lista de Archivos y Directorios Comunes a Probar (Fuzzing Básico) ---
# Se verifica si el servidor responde con 200 (OK) o 403 (Forbidden) a estas rutas,
# en lugar del 404 (Not Found).
TARGETS=(
    "robots.txt"
    "/.git/config"
    "/vendor/composer.json"
    "/wp-config.php"
    "/.env"
    "/admin/"
)

echo "--- 📋 Buscando archivos sensibles (200 OK / 403 Forbidden) ---"
echo "--- INICIO DE RESULTADOS ---" > "${ARCHIVO_SALIDA_TEMPORAL}"

for target in "${TARGETS[@]}"; do
    full_url="${URL_BASE}${target}"
    # -I: solo encabezados, -s: silencioso, -k: ignora SSL, -w: formato de salida
    RESPONSE=$(curl -I -s -k -o /dev/null -w "%{http_code}" "${full_url}")
    
    # Si la respuesta es 200 (OK) o 403 (Forbidden), es un indicador de presencia.
    if [ "$RESPONSE" = "200" ] || [ "$RESPONSE" = "403" ]; then
        echo "ENCONTRADO: ${full_url} (Código: ${RESPONSE})" | tee -a "${ARCHIVO_SALIDA_TEMPORAL}"
    else
        echo "NO ENCONTRADO: ${full_url} (Código: ${RESPONSE})" >> "${ARCHIVO_SALIDA_TEMPORAL}"
    fi
done

echo "--- FIN DE RESULTADOS ---" >> "${ARCHIVO_SALIDA_TEMPORAL}"

# --- 3. Definir y Ejecutar el Prompt a Gemini ---
echo " "
echo "🤖 Enviando datos de archivos encontrados a Gemini para análisis..."

DATOS_ENCONTRADOS=$(grep "ENCONTRADO" "${ARCHIVO_SALIDA_TEMPORAL}")
if [ -z "${DATOS_ENCONTRADOS}" ]; then
    DATOS_ENCONTRADOS="No se encontraron archivos sensibles de alto riesgo."
fi

PROMPT="Eres un experto en ciberseguridad que genera reportes ejecutivos e intuitivos. Analiza la siguiente lista de archivos que se encontraron en el servidor web ${URL_BASE}. Tu respuesta debe ser una lista de chequeo concisa. Para cada archivo ENCONTRADO, indica: 1) El Archivo/Ruta. 2) El Riesgo (ALTO si es información sensible como .env o .git/config, BAJO si es solo informativo como robots.txt). 3) Una recomendación de acción de una línea (Ej: 'Bloquear con .htaccess' o 'Eliminar/Mover'). Si no se encontró nada de alto riesgo, solo indica un estado de OK. La respuesta DEBE empezar con el encabezado # CHECKLIST DE ARCHIVOS EXPUESTOS. Responde únicamente con el reporte formateado de lista concisa en lenguaje natural y humanizado:"

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
        {"text": "Archivos encontrados:\n${DATOS_ENCONTRADOS}"}
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
echo "${TEXTO_REPORTE}" > "${ARCHIVO_REPORTE}"

# Imprimir el análisis final al usuario
echo "--- ✅ Análisis de Gemini (Resumen) ---"
echo "${TEXTO_REPORTE}"

# --- 5. Limpieza ---
rm -f "${ARCHIVO_SALIDA_TEMPORAL}"

echo " "
echo "---------------------------------------------------------"
echo "✅ Prueba de archivos finalizada. Reporte guardado."