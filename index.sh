#!/bin/bash

# =========================================================================
# SCRIPT: index.sh (Anteriormente ejecutar_todo.sh)
# FUNCION: Menú interactivo para seleccionar el tipo de auditoría (DAST/SAST)
#          y el archivo/objetivo a escanear.
# EJECUCIÓN: Desde la raíz del proyecto: ./index.sh
# =========================================================================

# --- 1. Definir Rutas y Constantes ---
SCRIPTS_DIR="./scripts"
DAST_SCRIPTS_DIR="${SCRIPTS_DIR}/PruebasExternas_DAST"
SAST_SCRIPTS_DIR="${SCRIPTS_DIR}/PruebasEstaticas_SAST"
ARCHIVOS_ESTATICOS_DIR="./archivosEstaticos" 

# Validar carpeta de scripts principal
if [ ! -d "${SCRIPTS_DIR}" ]; then
    echo "🚨 ERROR: No se encuentra la carpeta de scripts: ${SCRIPTS_DIR}"
    exit 1
fi

# 2. Generar el listado dinámico de scripts disponibles y clasificarlos
echo " "
echo "========================================================="
echo "      🚀 Suite de Pre-Pentesting BULLDOZER v2.0"
echo "========================================================="

# Mapear los scripts desde sus nuevas ubicaciones
mapfile -t DAST_SCRIPTS < <(find "${DAST_SCRIPTS_DIR}" -maxdepth 1 -type f -name "*.sh" | sort)
mapfile -t SAST_SCRIPTS < <(find "${SAST_SCRIPTS_DIR}" -maxdepth 1 -type f -name "*.sh" | sort)

if [ ${#DAST_SCRIPTS[@]} -eq 0 ] && [ ${#SAST_SCRIPTS[@]} -eq 0 ]; then
    echo "🚨 ERROR: No se encontraron scripts de prueba en las carpetas DAST/SAST."
    exit 1
fi

# --- 3. Pregunta de Tipo de Prueba (Nivel 1) ---
echo "--- 📝 Seleccione el Tipo de Auditoría ---"
echo "  [1] PRUEBAS EXTERNAS (DAST - Dynamic Analysis)"
echo "  [2] PRUEBAS ESTÁTICAS (SAST - Static Analysis)"
echo "---------------------------------------------------------"

read -r -p "¿Qué tipo de prueba desea ejecutar? (1 o 2): " TYPE_SELECTION

case "${TYPE_SELECTION}" in
    1)
        SELECTED_CATEGORY="DAST"
        TARGET_SCRIPTS=("${DAST_SCRIPTS[@]}")
        ;;
    2)
        SELECTED_CATEGORY="SAST"
        TARGET_SCRIPTS=("${SAST_SCRIPTS[@]}")
        ;;
    *)
        echo "❌ Selección inválida. Saliendo."
        exit 1
        ;;
esac

# --- 4. Pregunta de Objetivo (DAST) o Selección de Archivo (SAST) ---
TARGET="" # Inicializar vacío

if [ "${SELECTED_CATEGORY}" == "DAST" ]; then
    echo " "
    read -r -p "▶️ Ingrese el Objetivo (URL para Encabezados/Archivos o IP para Puertos): " TARGET
    if [ -z "${TARGET}" ]; then
        echo "❌ El objetivo no puede estar vacío. Saliendo."
        exit 1
    fi
    
elif [ "${SELECTED_CATEGORY}" == "SAST" ]; then
    echo " "
    # Validar que la carpeta de archivos exista
    if [ ! -d "${ARCHIVOS_ESTATICOS_DIR}" ]; then
        echo "🚨 ERROR: No se encontró la carpeta de archivos estáticos: ${ARCHIVOS_ESTATICOS_DIR}"
        echo "🚨 Cree la carpeta y coloque los archivos de código a auditar dentro."
        exit 1
    fi

    # Generar listado dinámico de archivos en la carpeta
    mapfile -t TARGET_FILES < <(find "${ARCHIVOS_ESTATICOS_DIR}" -maxdepth 1 -type f | sort)

    if [ ${#TARGET_FILES[@]} -eq 0 ]; then
        echo "🚨 ERROR: La carpeta ${ARCHIVOS_ESTATICOS_DIR} está vacía. Coloque archivos de código para auditar."
        exit 1
    fi

    # Mostrar la lista de archivos para seleccionar
    echo "--- 📝 Archivos de Código a Auditar en ${ARCHIVOS_ESTATICOS_DIR}/ ---"
    for i in "${!TARGET_FILES[@]}"; do
        FILE_NAME=$(basename "${TARGET_FILES[$i]}")
        echo "  [$(($i + 1))] ${FILE_NAME}"
    done
    echo "---------------------------------------------------------"
    
    read -r -p "¿Qué número de archivo desea auditar? (1-$((${#TARGET_FILES[@]}))): " FILE_SELECTION
    
    if ! [[ "${FILE_SELECTION}" =~ ^[0-9]+$ ]] || [ "${FILE_SELECTION}" -lt 1 ] || [ "${FILE_SELECTION}" -gt ${#TARGET_FILES[@]} ]; then
        echo "❌ Selección de archivo inválida. Saliendo."
        exit 1
    fi
    
    # Asignar la RUTA COMPLETA del archivo seleccionado a la variable TARGET
    TARGET="${TARGET_FILES[$(($FILE_SELECTION - 1))]}"
fi

# --- 5. Selección del Script Específico (Nivel 2) ---
echo " "
echo "--- 📝 Scripts ${SELECTED_CATEGORY} Disponibles ---"
for i in "${!TARGET_SCRIPTS[@]}"; do
    SCRIPT_NAME=$(basename "${TARGET_SCRIPTS[$i]}")
    echo "  [$(($i + 1))] ${SCRIPT_NAME}"
done
echo "---------------------------------------------------------"

read -r -p "¿Qué número de prueba específica desea ejecutar? (1-$((${#TARGET_SCRIPTS[@]}))): " SCRIPT_SELECTION

if ! [[ "${SCRIPT_SELECTION}" =~ ^[0-9]+$ ]] || [ "${SCRIPT_SELECTION}" -lt 1 ] || [ "${SCRIPT_SELECTION}" -gt ${#TARGET_SCRIPTS[@]} ]; then
    echo "❌ Selección de script inválida. Saliendo."
    exit 1
fi

SELECTED_SCRIPT="${TARGET_SCRIPTS[$(($SCRIPT_SELECTION - 1))]}"
SCRIPT_NAME=$(basename "${SELECTED_SCRIPT}")
echo "✅ Ejecutando: ${SCRIPT_NAME}"

# --- 6. Ejecución ---
echo "--- 🚀 Ejecutando ${SCRIPT_NAME} en: ${TARGET} ---"

# Ejecutar el script, pasando el objetivo (URL/IP) o la RUTA COMPLETA del archivo
# La variable SELECTED_SCRIPT ya contiene la ruta completa (ej: ./scripts/PruebasExternas_DAST/pre_analisis_archivos.sh)
"${SELECTED_SCRIPT}" "${TARGET}"

echo "========================================================="
echo "       ✅ Suite BULLDOZER Finalizada"
echo "========================================================="