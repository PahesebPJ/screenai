# Catálogo de Componentes — ScreenAI

Este documento describe en detalle cada archivo, script y plantilla que conforma el ecosistema de ScreenAI.

---

## Índice de Archivos

| Archivo | Tipo | Función Principal |
|---------|------|-------------------|
| [`screenai.sh`](#1-screenaish) | Bash Shell Script | Orquestador y punto de entrada principal |
| [`screenai_query.py`](#2-screenai_querypy) | Python Script | Cliente API de Google Gemini (inyección multimodal) |
| [`screenai_tts.py`](#3-screenai_ttspy) | Python Script | Motor de síntesis de voz (Piper + fallback espeak-ng) |
| [`prompts.txt`](#4-promptstxt) | Archivo de Texto | Catálogo de preguntas rápidas para el menú wofi |
| [`system_prompt.txt`](#5-system_prompttxt) | Archivo de Texto | Instrucciones de personalidad y formato para Gemini |
| [`config.toml`](#6-configtoml--configtomlexample) | Archivo TOML | Configuración de credenciales, modelos y motores |
| [`wofi.css`](#7-woficss) | Hoja de Estilos | Diseño visual y tema oscuro para el menú flotante |
| [`hypr_screenai.conf`](#8-hypr_screenaiconf) | Configuración Hyprland | Declaración de atajos globales y reglas de compositor |
| [`install.sh`](#9-installsh) | Bash Shell Script | Instalador automatizado y verificador de dependencias |

---

## 1. `screenai.sh`

### Ubicación
- Origen: `screenai.sh`
- Destino tras instalar: `~/.local/share/screenai/screenai.sh` (enlazado simbólicamente a `~/.local/bin/screenai`)

### Responsabilidades
1. Establece la política estricta de ejecución de bash (`set -euo pipefail`).
2. Dispara `grim` para volcar la imagen completa de la pantalla a `/tmp/screenai/screenshot.png`. Si la captura falla, alerta con `notify-send` y aborta.
3. Lee las líneas de `prompts.txt` y las pasa como entrada estándar a `wofi --dmenu`. Permite autocompletado y recepción de cadenas personalizadas arbitrarias escritas por el usuario.
4. Llama a `screenai_query.py` canalizando `stdout` hacia `/tmp/screenai/response.txt` y `stderr` a `/tmp/screenai/error.txt`.
5. Si la respuesta es exitosa, extrae los primeros 220 caracteres y emite una notificación de escritorio con `notify-send`.
6. Invoca inmediatamente a `screenai_tts.py` para vocalizar el resultado en segundo plano.

---

## 2. `screenai_query.py`

### Ubicación
- Origen: `screenai_query.py`
- Destino tras instalar: `~/.local/share/screenai/screenai_query.py`

### Parámetros CLI
```bash
python3 screenai_query.py <ruta_imagen> "<prompt_usuario>" <ruta_config_toml>
```

### Mecánica Interna
- **Manejo de Configuración:** Utiliza la librería estándar `tomllib` de Python 3.11+ para parsear el archivo `config.toml` sin requerir dependencias externas adicionales.
- **Inyección de Prompt de Sistema:** Si existe el archivo `~/.config/screenai/system_prompt.txt`, lo lee y lo antepone a la consulta:
  ```
  {system_prompt}

  Pregunta del usuario: {prompt}
  ```
- **Llamada Multimodal:**
  - Lee el archivo binario de la captura.
  - Instancia el cliente `genai.Client(api_key=...)` del paquete `google-genai`.
  - Invoca `client.models.generate_content(...)` pasando tanto el bloque binario PNG (`types.Part.from_bytes`) como la cadena de texto combinada.
- **Salida:** Imprime el texto de respuesta puro directamente en `sys.stdout` para que sea capturado por el orquestador.

---

## 3. `screenai_tts.py`

### Ubicación
- Origen: `screenai_tts.py`
- Destino tras instalar: `~/.local/share/screenai/screenai_tts.py`

### Parámetros CLI
```bash
python3 screenai_tts.py <archivo_respuesta_txt> <ruta_config_toml>
```

### Estrategia de Síntesis y Resiliencia
1. **Verificación de Entrada:** Lee el archivo de texto; si está vacío, finaliza silenciosamente sin emitir errores ni reproducir ruidos.
2. **Motor Principal — Piper Neural (`speak_with_piper`):**
   - Busca el modelo en `~/.local/share/piper/voices/<voz>.onnx`.
   - Intenta invocar la API nativa de Python `from piper.voice import PiperVoice`.
   - Sintetiza directamente a un buffer WAV (`/tmp/screenai/response.wav`).
   - Reproduce el archivo buscando secuencialmente el primer binario disponible entre: `aplay -q`, `paplay` o `mpv --no-video`.
3. **Fallback 1 — Piper CLI (`speak_with_piper_cli`):**
   - Si la librería de Python no estuviera instalada pero el binario `piper` está en el sistema, lo invoca por tubería subprocess.
4. **Fallback 2 — espeak-ng (`speak_with_espeak`):**
   - Si no existe el modelo `.onnx` o Piper falla, se activa automáticamente `espeak-ng -v es -s 145 -a 85 "<texto>"`, asegurando que la voz siempre se escuche.

---

## 4. `prompts.txt`

### Ubicación
- Origen: `prompts.txt`
- Destino tras instalar: `~/.local/share/screenai/prompts.txt`

### Formato
Texto plano, un prompt por línea.
```text
¿Qué hay en esta pantalla?
Explica este error
Resume este texto
Traduce al español
¿Cómo se hace esto?
Dame el código de lo que veo
Describe lo que está pasando
¿Qué pasos debo seguir?
¿Qué significa esto?
Encuentra problemas o bugs
```
> **Nota de uso:** El usuario puede agregar sus propios flujos recurrentes (por ejemplo: *"Corrige este SQL"*, *"Explica esta traza de Rust"*, *"Redacta un commit con este git diff"*).

---

## 5. `system_prompt.txt`

### Ubicación
- Origen: `system_prompt.txt`
- Destino tras instalar: `~/.config/screenai/system_prompt.txt`

### Función
Es el prompt rector que define la personalidad y límites de Gemini. Está calibrado específicamente para TTS:
- Obliga a responder siempre en idioma español.
- Limita la respuesta a un rango de 3 a 5 frases fluidas.
- Prohíbe saludos introductorios vacíos (como *"Claro, con gusto te ayudo"*).
- Prohíbe listas numeradas largas y tablas, las cuales resultan confusas al ser leídas por voz.

---

## 6. `config.toml` / `config.toml.example`

### Ubicación
- Plantilla pública: `config.toml.example` (incluida en el repositorio Git)
- Archivo privado local: `~/.config/screenai/config.toml` (ignorado en `.gitignore`, permisos `600`)

### Esquema de Opciones
```toml
[api]
provider = "gemini"
model    = "gemini-2.5-flash"  # o gemini-2.5-pro
api_key  = "TU_API_KEY"

[capture]
mode   = "fullscreen"
output = "/tmp/screenai/screenshot.png"

[tts]
engine = "piper"                  # "piper" o "espeak"
voice  = "es_ES-sharvard-medium"  # nombre base del modelo .onnx
speed  = 145                      # WPM para espeak-ng

[ui]
show_notification     = true
notification_duration = 12000     # duración en milisegundos
```

---

## 7. `wofi.css`

### Ubicación
- Origen: `wofi.css`
- Destino tras instalar: `~/.local/share/screenai/wofi.css`

### Estilizado
Configura un diseño moderno estilo *Glassmorphism* oscuro:
- Tipografía monoespaciada: JetBrains Mono / Fira Code.
- Fondo translúcido con desenfoque (`rgba(16, 16, 24, 0.96)`).
- Bordes sutiles con radio de 14px.
- Indicador de selección acentuado en color azul suave (`#7cb8ff`).

---

## 8. `hypr_screenai.conf`

### Ubicación
- Origen: `hypr_screenai.conf`
- Destino tras instalar: `~/.config/hypr/conf.d/screenai.conf`

### Contenido
```ini
bind = SUPER SHIFT, S, exec, screenai
```
Se integra de forma modular mediante una directiva `source = ~/.config/hypr/conf.d/screenai.conf` dentro de `~/.config/hypr/bindings.conf` o `~/.config/hypr/hyprland.conf`.

---

## 9. `install.sh`

### Ubicación
- Origen: `install.sh`

### Pipeline de Instalación Automatizado
1. **Creación de directorios XDG:**
   - `~/.local/share/screenai`
   - `~/.config/screenai`
   - `~/.local/bin`
   - `~/.local/share/piper/voices`
   - `~/.config/hypr/conf.d`
2. **Instalación de paquetes de sistema vía pacman:** Verifica y descarga `grim`, `espeak-ng` y `python-pip`.
3. **Instalación de módulos Python:** Verifica e instala `google-genai` y `piper-tts`.
4. **Descarga de activos de red:** Descarga el modelo neural ONNX en español (`es_ES-sharvard-medium.onnx` y su `.json`) desde el repositorio oficial de Hugging Face (~60MB).
5. **Instalación de scripts y permisos:** Copia los archivos ejecutables asignando `chmod +x`.
6. **Enlace simbólico en PATH:** Genera `~/.local/bin/screenai -> ~/.local/share/screenai/screenai.sh`.
7. **Inyección en el Compositor:** Añade la línea de carga en el archivo de bindings de Hyprland.
