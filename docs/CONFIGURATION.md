# Guía de Configuración y Personalización — ScreenAI

ScreenAI fue diseñado siguiendo la filosofía Unix: texto plano, configuración modular y desacoplamiento de componentes. En esta guía aprenderás a adaptar cada aspecto de la herramienta a tus necesidades.

---

## 1. Configuración de Modelos de Gemini

El archivo principal de configuración se encuentra en:
```bash
nano ~/.config/screenai/config.toml
```

### Opciones de Modelos

| Modelo | Identificador | Ideal Para | Velocidad |
|--------|---------------|------------|-----------|
| **Gemini 2.5 Flash** (Recomendado) | `gemini-2.5-flash` | Uso diario, análisis visual veloz, preguntas rápidas de pantalla | ⚡⚡⚡ Ultrarrápido |
| **Gemini 2.5 Pro** | `gemini-2.5-pro` | Razonamiento visual complejo, arquitectura de software, diagramas intrincados | ⚡ Calidad máxima |

Para cambiar de modelo, edita la directiva `model` bajo la sección `[api]`:
```toml
[api]
provider = "gemini"
model    = "gemini-2.5-pro"
api_key  = "TU_API_KEY"
```

### Actualización o Rotación de API Key
Si revocaste tu clave o generaste una nueva en [Google AI Studio](https://aistudio.google.com):
```bash
# Cambia el valor de api_key en:
nano ~/.config/screenai/config.toml
```

---

## 2. Personalización de Prompts Predefinidos

La lista que aparece al invocar `wofi` se administra en:
```bash
nano ~/.local/share/screenai/prompts.txt
```

### Ejemplos de Nuevos Prompts Útiles
Puedes agregar prompts específicos para tu flujo de trabajo:

```text
¿Qué hay en esta pantalla?
Explica este error
Resume este texto
Traduce al español
¿Cómo soluciono este fallo en terminal?
Genera una prueba unitaria para esta función
Explica qué hace este commit o diff de git
Corrige la ortografía y redacción de este texto
Extrae el texto de esta imagen (OCR)
```

> 💡 **Tip:** No necesitas limitarte a las opciones de la lista. En el cuadro de búsqueda de `wofi` puedes escribir cualquier pregunta personalizada al vuelo y presionar `Enter`.

---

## 3. Calibración del System Prompt (Comportamiento de la IA)

El comportamiento, tono y estilo de respuesta de Gemini se controlan desde:
```bash
nano ~/.config/screenai/system_prompt.txt
```

### Ejemplo: Respuestas ultra-cortas y directas
```text
Eres un asistente visual conciso.
Analiza la captura de pantalla y responde estrictamente en español.
Límite: Máximo 2 oraciones.
Ve directo al grano sin introducciones ni despedidas.
```

### Ejemplo: Asistente enfocado a programación y DevOps
```text
Eres un asistente de programación experto en Linux, Rust, Python y Bash.
Analiza el código o terminal visible en la pantalla.
Explica la causa raíz de los errores y di exactamente el comando o corrección a aplicar.
Responde de forma hablada y fluida en no más de 4 oraciones.
```

---

## 4. Personalización del Motor de Voz (TTS)

### Cambiar de Piper (Neural) a espeak-ng (Sintético Ligero)
En `~/.config/screenai/config.toml`:
```toml
[tts]
engine = "espeak"
speed  = 150 # Palabras por minuto
```

### Descargar Nuevas Voces para Piper
Piper dispone de una amplia variedad de modelos de voz en diferentes acentos y tonalidades en su [repositorio oficial de Hugging Face](https://huggingface.co/rhasspy/piper-voices).

#### Ejemplo: Descargar voz en español de México (Carlfm - medium)
```bash
VOICES_DIR="$HOME/.local/share/piper/voices"
BASE_URL="https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/es/es_MX/carlfm/medium"

# Descargar modelo .onnx y su metadata .json
wget -O "$VOICES_DIR/es_MX-carlfm-medium.onnx" "$BASE_URL/es_MX-carlfm-medium.onnx"
wget -O "$VOICES_DIR/es_MX-carlfm-medium.onnx.json" "$BASE_URL/es_MX-carlfm-medium.onnx.json"
```

Luego, en `~/.config/screenai/config.toml`, cambia la voz activa:
```toml
[tts]
engine = "piper"
voice  = "es_MX-carlfm-medium"
```

---

## 5. Modificación de Atajos de Teclado en Hyprland

El archivo modular de atajos reside en:
```bash
nano ~/.config/hypr/conf.d/screenai.conf
```

### Ejemplos de Combinaciones Alternativas

```ini
# Usar Alt + S
bind = ALT, S, exec, screenai

# Usar Super + Espacio
bind = SUPER, Space, exec, screenai

# Usar la tecla Impr Pant (Print Screen)
bind = , Print, exec, screenai
```

Para aplicar los cambios al instante sin reiniciar sesión:
```bash
hyprctl reload
```

---

## 6. Personalización Visual del Menú flotante (Wofi)

Para ajustar colores, tipografía, márgenes o bordes del menú emergente:
```bash
nano ~/.local/share/screenai/wofi.css
```

Por ejemplo, para aumentar el tamaño de fuente general:
```css
* {
    font-family: 'JetBrains Mono', monospace;
    font-size: 15px; /* Aumentar de 13px a 15px */
    color: #e2e2f0;
}
```
Los cambios se aplican automáticamente en la siguiente llamada a ScreenAI.
