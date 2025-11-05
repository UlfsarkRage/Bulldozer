# 🛠️ Proyecto Bulldozer: Suite de Pre-Pentesting Asistido por Gemini

## 🎯 Objetivo
"Bulldozer" es una herramienta que automatiza pruebas de penetración básicas (pre-pentesting) y utiliza la Interfaz de Línea de Comandos (CLI) de Google Gemini para analizar los resultados, explicar vulnerabilidades y sugerir soluciones de código concretas.

Diseñado para desarrolladores web que buscan incorporar la seguridad en el ciclo de despliegue (DevSecOps).

## 🚀 Requisitos

Para ejecutar "Bulldozer", necesitas:

1.  **Entorno:** Windows con **WSL2** instalado (idealmente con una distribución Ubuntu).
2.  **Editor:** **VS Code** con la extensión "Remote - WSL".
3.  **Herramientas Linux:**
    * **`curl`**: Para peticiones HTTP.
    * **`nmap`**: Para escaneo de puertos.
4.  **CLI de Google Cloud:**
    * **`gcloud`** y **`gemini`**: Para invocar el modelo de IA.
        * **Autenticación:** Asegúrate de estar autenticado en tu terminal de WSL con `gcloud auth login` o `gcloud auth application-default login`.

## 📂 Estructura del Repositorio

Bulldozer/ ├── scripts/ │ ├── pre_analisis_encabezados.sh # Verifica la seguridad de los Headers HTTP. │ └── pre_analisis_puertos.sh # Escanea y analiza puertos comunes con nmap. ├── documentacion/ └── LEEME.md

## 📝 Uso de la Herramienta

Todos los scripts se ejecutan desde la terminal de Bash dentro de WSL, pasando la URL objetivo como el primer argumento.

### 1. Análisis de Encabezados (Headers)

```bash
./scripts/pre_analisis_encabezados.sh [URL_COMPLETA] 
Ejemplo: ./scripts/pre_analisis_encabezados.sh https://localhost:8080

### 2. Análisis de Puertos Abiertos
```bash
./scripts/pre_analisis_puertos.sh [DOMINIO_O_IP]

Ejemplo: ./scripts/pre_analisis_puertos.sh 127.0.0.1

---

## 📄 Archivo 2: `.gitignore`

Este archivo asegura que los archivos temporales y la configuración de VS Code no se suban al repositorio.

```gitignore
# Archivos temporales de los scripts de Bulldozer
*_temp.txt
headers_output_temp.txt
puertos_output_temp.txt

# Directorios y archivos de VS Code
.vscode/

# Logs y paquetes
*.log
*.zip

