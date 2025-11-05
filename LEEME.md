# 🛠️ Proyecto Bulldozer: Suite de Pre-Pentesting Asistido por Gemini

## 🎯 Objetivo
"Bulldozer" es una herramienta de automatización que combina la potencia de herramientas de seguridad estándar de Linux (`curl`, `nmap`) con la capacidad de análisis de **Google Gemini**. Su principal función es tomar la salida técnica de estas herramientas, analizar las vulnerabilidades, y generar **reportes intuitivos y humanizados** para desarrolladores o usuarios no técnicos.

---

## 🚀 Requisitos e Instalación (Paso a Paso Obligatorio)

Esta herramienta requiere un entorno Linux (idealmente WSL2 con Ubuntu) y varias dependencias clave de Google Cloud y del sistema. **El orden es importante.**

### 1. Preparación del Entorno Linux (WSL)

Abre tu terminal de WSL (ej: Ubuntu) y asegúrate de que todas las librerías necesarias estén instaladas.

| Dependencia | Comando de Instalación | Propósito |
| :--- | :--- | :--- |
| **`curl`** | `sudo apt install curl` | Necesario para realizar peticiones HTTP y comunicarse con la API de Gemini. |
| **`nmap`** | `sudo apt install nmap` | Herramienta esencial para el escaneo de puertos. |
| **`jq`** | `sudo apt install jq` | **CRÍTICO.** Necesario para extraer y limpiar la respuesta JSON de Gemini, mostrando solo el texto legible (Markdown). |

### 2. Configuración de Google Cloud CLI (gcloud)

El script de Bulldozer utiliza el binario de `gcloud` para la autenticación y el token de acceso.

1.  **Instalar el SDK de Google Cloud:** Sigue la guía oficial de Google para instalar el Cloud SDK en Linux.
2.  **Autenticación:** Ejecuta el comando para autenticar tu cuenta de usuario y establecer el proyecto predeterminado:
    ```bash
    gcloud auth application-default login
    ```
3.  **Habilitar la API de Gemini:** Asegúrate de que la API esté activada en tu proyecto de Google Cloud (esto también requiere que la facturación esté habilitada en tu cuenta).
    ```bash
    gcloud services enable aiplatform.googleapis.com
    ```
4.  **Ajustar la Ruta del Binario:** Si instalaste `gcloud` localmente, la ruta en los scripts de Bulldozer (`pre_analisis_encabezados.sh` y `pre_analisis_puertos.sh`) debe ser actualizada a la ubicación real de tu binario `gcloud`. (Nuestra conversación resolvió que tu ruta es `/home/unknown_ronin/google-cloud-sdk/bin/gcloud`).

---

## 📂 Estructura y Función de los Scripts

El proyecto se organiza en un directorio principal (`Bulldozer/`) y una carpeta de *scripts*. Los reportes finales se almacenan en la carpeta `resultados/`.

| Archivo | Función |
| :--- | :--- |
| **`ejecutar_todo.sh`** | **Script de control maestro.** Ejecuta secuencialmente `pre_analisis_encabezados.sh` y `pre_analisis_puertos.sh`. |
| **`pre_analisis_encabezados.sh`** | Usa **`curl`** para obtener los encabezados HTTP y los envía a Gemini para el análisis de seguridad y la generación del reporte. |
| **`pre_analisis_puertos.sh`** | Usa **`nmap -F`** para escanear los 100 puertos TCP más comunes y envía el resultado a Gemini para el análisis de riesgos. |
| **`resultados/`** | Directorio que almacena los archivos de reporte (`.txt`) generados por Gemini. Cada archivo es concatenado con la fecha y hora para evitar sobreescritura. |

---

## 📝 Uso de la Herramienta (Comando Final)

Una vez que todas las dependencias y la autenticación estén configuradas, ejecuta el script maestro `ejecutar_todo.sh` pasando los dos argumentos requeridos en orden: la URL para los encabezados y la IP/Dominio para el escaneo de puertos.

```bash
# SINTAXIS: ./scripts/ejecutar_todo.sh [URL_COMPLETA_HTTPS] [IP_O_DOMINIO]
 
./scripts/ejecutar_todo.sh [https://www.google.com](https://www.google.com) 127.0.0.1




---------------
Resultados
La terminal mostrará un resumen ejecutivo del análisis de encabezados y puertos generado por Gemini.

Se generarán dos archivos .txt en la carpeta resultados/ con los nombres:

REPORTE_ENCABEZADOS_YYYYMMDD_HHMMSS.txt

REPORTE_PUERTOS_YYYYMMDD_HHMMSS.txt

Estos archivos contienen el análisis completo en formato de lista de chequeo concisa y en lenguaje natural.


