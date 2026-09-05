# ScreenAI 🤖🔊

> Presiona un atajo → Gemini analiza tu pantalla → te responde en voz

Asistente visual de escritorio para **Arch Linux / Omarchy (Hyprland + Wayland)**.  
Captura la pantalla completa, la envía a **Google Gemini Flash** junto con tu pregunta (por texto o hablando por tu micrófono), y lee la respuesta en voz alta usando **piper TTS**.

---

## ✨ Modos de Uso y Atajos

ScreenAI ofrece dos modos complementarios:

### 1. 🎙️ Modo Voz Directo (¡Sin menús!) — `Super + V` o `Super + Shift + V`
```
Presiona Super + V  ──► Captura pantalla y empieza a grabar tu micrófono
Hablas tu pregunta  ──► "Explica qué error tengo aquí en la terminal"
Vuelves a presionar ──► Detiene grabación, manda pantalla + audio a Gemini
Respuesta en voz    ──► 🔊 Piper lee la solución directamente a tus auriculares
```

### 2. 📋 Modo Menú Visual — `Super + Shift + S`
```
Presiona Super + Shift + S ──► Captura pantalla y abre el menú Walker de Omarchy
Eliges un prompt o escribes ──► "¿Qué hay en pantalla?", "Traduce", etc.
Respuesta en voz           ──► 🔊 Piper lee la respuesta y ves una notificación
```

---

## 📚 Documentación Técnica Detallada

Para una comprensión profunda de la arquitectura y configuración del sistema, consulta los siguientes documentos:

- 🏛️ **[Arquitectura y Flujo de Datos (`docs/ARCHITECTURE.md`)](docs/ARCHITECTURE.md)**: Diagramas Mermaid, ciclo de vida de procesos, llamadas Wayland e interacción de audio.
- 🧩 **[Catálogo de Componentes (`docs/COMPONENTS.md`)](docs/COMPONENTS.md)**: Explicación detallada de cada script, parámetros, dependencias y responsabilidades.
- ⚙️ **[Guía de Configuración y Personalización (`docs/CONFIGURATION.md`)](docs/CONFIGURATION.md)**: Cómo cambiar modelos de Gemini, descargar nuevas voces para Piper, personalizar prompts y atajos de teclado.
- 🛠️ **[Diagnóstico y Resolución de Problemas (`docs/TROUBLESHOOTING.md`)](docs/TROUBLESHOOTING.md)**: Pruebas unitarias en una sola línea, errores comunes y soluciones para audio y Wayland.

---

## 📁 Estructura del Repositorio

```
screenai/
├── README.md               ← este archivo
├── docs/                   ← documentación técnica extendida
│   ├── ARCHITECTURE.md     ← diagramas y flujo de datos
│   ├── COMPONENTS.md       ← catálogo detallado de scripts
│   ├── CONFIGURATION.md    ← personalización de modelos, voces y atajos
│   └── TROUBLESHOOTING.md  ← resolución de problemas y pruebas
├── .gitignore              ← excluye config.toml (contiene API key)
├── install.sh              ← instalador automático
│
├── screenai.sh             ← script principal (entry point)
├── screenai_query.py       ← cliente multimodal para Gemini API
├── screenai_tts.py         ← motor TTS (piper + espeak-ng fallback)
│
├── prompts.txt             ← prompts predefinidos del menú wofi
├── system_prompt.txt       ← instrucciones base para Gemini
├── wofi.css                ← estilo del menú de prompts
├── hypr_screenai.conf      ← keybind Super+Shift+S para Hyprland
│
└── config.toml.example     ← plantilla de configuración (SIN API key)
```

---

## 📍 Dónde va cada archivo en el sistema

Después de correr `install.sh`, los archivos quedan así:

| Archivo del repo | Destino en el sistema | Para qué sirve |
|------------------|-----------------------|----------------|
| `screenai.sh` | `~/.local/share/screenai/screenai.sh` | Script principal, orquesta todo el flujo |
| `screenai_query.py` | `~/.local/share/screenai/screenai_query.py` | Llama a la API de Gemini con imagen + prompt |
| `screenai_tts.py` | `~/.local/share/screenai/screenai_tts.py` | Convierte el texto de respuesta a voz |
| `prompts.txt` | `~/.local/share/screenai/prompts.txt` | Lista de prompts del menú (editable) |
| `wofi.css` | `~/.local/share/screenai/wofi.css` | Estilo oscuro del menú wofi |
| `config.toml.example` | `~/.config/screenai/config.toml` | Tu API key y opciones (creado desde el ejemplo) |
| `system_prompt.txt` | `~/.config/screenai/system_prompt.txt` | Instrucciones para Gemini (editable) |
| `hypr_screenai.conf` | `~/.config/hypr/conf.d/screenai.conf` | Keybind `Super+Shift+S` |
| *(symlink)* | `~/.local/bin/screenai` | Comando disponible en el PATH |
| *(descargado)* | `~/.local/share/piper/voices/es_ES-sharvard-medium.onnx` | Modelo de voz español para piper |

---

## 🚀 Instalación

### Prerrequisitos

- Arch Linux con Hyprland (Omarchy u otra configuración)
- Wayland session activa
- Python 3.11+
- Conexión a internet (para descargar el modelo de voz ~60MB)

### 1. Clonar el repositorio

```bash
git clone https://github.com/TU_USUARIO/screenai.git
cd screenai
```

### 2. Configurar la API key

```bash
# Copiar la plantilla de config
cp config.toml.example config.toml

# Editar y poner tu Gemini API key
# Consíguela gratis en: https://aistudio.google.com
nano config.toml
```

### 3. Instalar

```bash
bash install.sh
```

El instalador hace automáticamente:
- ✅ Instala `grim` y `espeak-ng` con pacman
- ✅ Instala `google-genai` y `piper-tts` con pip
- ✅ Descarga el modelo de voz en español (~60MB desde Hugging Face)
- ✅ Copia todos los archivos a sus destinos correctos
- ✅ Configura el keybind `Super+Shift+S` en Hyprland
- ✅ Crea el symlink `screenai` en tu PATH

### 4. Activar el keybind

```bash
hyprctl reload
```

### 5. Probar

Presiona **`Super+Shift+S`** — deberías ver el menú de prompts.

---

## 🔧 Descripción de cada archivo

### `screenai.sh` — Script principal
El orquestador. Ejecuta los pasos en orden:
1. `grim` → captura la pantalla completa a `/tmp/screenai/screenshot.png`
2. `wofi` → muestra el menú de prompts y recibe la selección del usuario
3. `notify-send` → notificación "Consultando Gemini..."
4. `screenai_query.py` → llama a Gemini y escribe la respuesta en `/tmp/screenai/response.txt`
5. `notify-send` → muestra un preview del texto en notificación
6. `screenai_tts.py` → lee la respuesta en voz alta

### `screenai_query.py` — Cliente Gemini
Recibe tres argumentos: ruta de la imagen, prompt del usuario, y ruta al config.toml.  
Construye un mensaje multimodal (imagen PNG en base64 + texto), lo envía a Gemini 2.5 Flash y imprime la respuesta a stdout.  
Lee el system prompt desde `~/.config/screenai/system_prompt.txt`.

### `screenai_tts.py` — Motor de voz
Convierte el texto de respuesta a audio.  
- **Modo `piper`** (por defecto): usa el modelo neural `es_ES-sharvard-medium.onnx` para voz en español de alta calidad. Reproduce con `aplay`.
- **Fallback `espeak-ng`**: si piper no está disponible, usa espeak-ng que viene en los repos de Arch.

### `prompts.txt` — Prompts predefinidos
Una línea = un prompt. Se muestra en el menú de wofi.  
**Puedes editar este archivo libremente** — agrega, quita o cambia prompts sin tocar el código.  
Si escribes texto libre en el buscador de wofi, ese texto se usa como prompt personalizado.

### `system_prompt.txt` — Instrucciones para Gemini
Define el comportamiento base del modelo: responder en español, ser conciso (para TTS), ir directo al punto, etc.  
**Personalízalo** según tus necesidades. Se aplica a todas las consultas.

### `wofi.css` — Estilo del menú
CSS que da el aspecto oscuro y elegante al menú de wofi. Usa tipografía monoespaciada y colores con transparencia.

### `hypr_screenai.conf` — Keybind de Hyprland
Define el atajo `Super+Shift+S → exec screenai`.  
El instalador agrega `source = ~/.config/hypr/conf.d/screenai.conf` a tu `bindings.conf` o `hyprland.conf`.

### `config.toml.example` — Plantilla de configuración
Modelo del archivo de configuración **sin API key**.  
El usuario copia este archivo como `config.toml` y agrega su propia key.  
⚠️ **`config.toml` nunca debe subirse a git** (está en `.gitignore`).

### `install.sh` — Instalador
Script bash que automatiza toda la instalación. Idempotente: se puede correr varias veces sin romper nada.  
Detecta qué ya está instalado y solo instala lo que falta.

---

## ⚙️ Configuración

### `~/.config/screenai/config.toml`

```toml
[api]
provider = "gemini"
model    = "gemini-2.5-flash"   # o "gemini-2.5-pro" para máxima calidad
api_key  = "TU_API_KEY_AQUI"

[capture]
mode   = "fullscreen"
output = "/tmp/screenai/screenshot.png"

[tts]
engine = "piper"                    # "piper" o "espeak"
voice  = "es_ES-sharvard-medium"    # modelo de voz piper
speed  = 145                        # palabras por minuto (solo espeak)

[ui]
show_notification     = true
notification_duration = 12000
```

### Cambiar el atajo de teclado

Edita `~/.config/hypr/conf.d/screenai.conf`:

```ini
# Ejemplo: Alt+S en vez de Super+Shift+S
bind = ALT, S, exec, screenai
```

Luego recarga Hyprland: `hyprctl reload`

---

## 🔍 Diagnóstico y Solución de Problemas

```bash
# ¿grim funciona?
grim /tmp/test.png && echo "OK" || echo "FALLA"

# ¿La API de Gemini responde?
python3 -c "
from google import genai
c = genai.Client(api_key='TU_KEY')
r = c.models.generate_content(model='gemini-2.5-flash', contents='Hola')
print(r.text)
"

# ¿piper TTS funciona?
echo "Hola mundo" | piper --model ~/.local/share/piper/voices/es_ES-sharvard-medium.onnx --output_file /tmp/test.wav
aplay /tmp/test.wav

# ¿espeak-ng funciona?
espeak-ng -v es "Hola mundo"

# Probar ScreenAI completo desde terminal
screenai
```

---

## 🔒 Seguridad

- `config.toml` está en `.gitignore` — **nunca se sube al repositorio**
- El archivo se crea con permisos `600` (solo lectura para tu usuario)
- La API key solo viaja de tu máquina a los servidores de Google (cifrado TLS)

---

## 📦 Dependencias

| Dependencia | Fuente | Propósito |
|-------------|--------|-----------|
| `grim` | pacman | Captura de pantalla en Wayland |
| `wofi` | pacman | Menú de prompts |
| `espeak-ng` | pacman | TTS fallback |
| `mako` / `dunst` | pacman | Notificaciones (ya en Omarchy) |
| `google-genai` | pip | Cliente oficial de Gemini API |
| `piper-tts` | pip | Motor TTS neural local |
| Modelo piper `es_ES-sharvard-medium` | Hugging Face | Voz española de alta calidad |

---

## 📝 Licencia

MIT — úsalo, modifícalo, compártelo libremente.
