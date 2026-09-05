# Guía de Uso Rápido — ScreenAI 🤖🔊

Esta guía te explica cómo utilizar **ScreenAI** en tu día a día en Arch Linux / Omarchy, con ejemplos prácticos y comandos esenciales.

---

## ⌨️ Atajos de Teclado Principales

ScreenAI cuenta con dos formas de interacción según lo que necesites en cada momento:

| Atajo | Modo | ¿Cuándo usarlo? |
|-------|------|-----------------|
| **`Super + V`** | 🎙️ **Modo Voz Directo** | Cuando quieres hacer una pregunta rápida hablando sin que aparezca ninguna ventana. |
| **`Super + Shift + V`** | 🎙️ **Modo Voz (Alternativo)** | Igual que el anterior, por si prefieres la combinación con Shift. |
| **`Super + Shift + S`** | 📋 **Modo Menú Walker** | Cuando prefieres elegir una pregunta predefinida o escribir con el teclado. |

---

## 1. 🎙️ Cómo usar el Modo Voz (`Super + V`)

Este es el modo más rápido y natural. Funciona como un **Walkie-Talkie (Toggle)**:

```
[Pulsar Super + V] ──► [Hablar tu pregunta] ──► [Volver a pulsar Super + V] ──► [Escuchar respuesta]
```

### Paso a paso:
1. **Pon en pantalla lo que quieras analizar** (código, un error en la terminal, un diagrama, un correo, etc.).
2. Presiona **`Super + V`**.
   - En ese mismo instante se toma la captura de pantalla.
   - Verás una notificación: `🎙️ ScreenAI: Escuchando... Habla y presiona el atajo de nuevo para enviar.`
3. **Habla tu pregunta con normalidad al micrófono.**
   - *Ejemplos:*
     - *"¿Por qué está fallando este comando en la terminal?"*
     - *"Explícame qué hace este bloque de código."*
     - *"Traduce al español lo que dice este párrafo en inglés."*
     - *"¿Qué pasos debo seguir para resolver este error?"*
4. Cuando termines de hablar, **vuelve a presionar `Super + V`**.
   - La grabación se detiene.
   - Verás la notificación `🤖 Procesando tu voz y pantalla...`.
   - **Google Gemini** analiza lo que ve en la pantalla junto con lo que dijiste.
   - **Piper TTS** te leerá la respuesta directamente a tus auriculares/altavoces.

---

## 2. 📋 Cómo usar el Modo Menú (`Super + Shift + S`)

Si estás en un lugar donde no puedes hablar o prefieres seleccionar una acción típica:

### Paso a paso:
1. Presiona **`Super + Shift + S`**.
2. Aparecerá el menú de **Walker** con la lista de opciones rápidas:
   - *¿Qué hay en esta pantalla?*
   - *Explica este error*
   - *Resume este texto*
   - *Traduce al español*
   - *¿Cómo se hace esto?*
   - *Dame el código de lo que veo*
   - *Describe lo que está pasando*
3. **Selecciona una opción con las flechas y presiona `Enter`**.
   - *(O escribe directamente cualquier pregunta en el buscador y presiona `Enter`)*.
4. Gemini analizará la captura y escucharás la respuesta explicada por voz, además de ver un resumen en tus notificaciones.

---

## 3. 💡 Ejemplos de Casos de Uso Reales

### A. Depuración de errores en Terminal
- Abre tu terminal con el error o traza de excepción visible.
- Presiona `Super + V` ➜ di: *"Dime exactamente qué comando debo correr para arreglar esto"* ➜ `Super + V`.

### B. Explicación de Código
- En tu editor (VS Code, Neovim, etc.), deja visible la función compleja.
- Presiona `Super + V` ➜ di: *"Explícame la lógica de esta función y si tiene algún bug"* ➜ `Super + V`.

### C. Traducción de Documentación Técnica
- Tienes una página web en inglés o japonés en pantalla.
- Presiona `Super + Shift + S` ➜ Elige *"Traduce al español"* (o pídelo por voz).

### D. Lectura de Gráficos o Diagramas
- Con un diagrama de arquitectura o flujo en pantalla.
- Presiona `Super + V` ➜ di: *"Resume los componentes principales de este diagrama"* ➜ `Super + V`.

---

## 4. ⚙️ Personalización Rápida

Todos los archivos de configuración están en tu carpeta de usuario:

### Agregar o quitar opciones del Menú Walker:
```bash
nano ~/.local/share/screenai/prompts.txt
```
*(Agrega cada pregunta en una línea nueva).*

### Cambiar las instrucciones base de la IA (System Prompt):
```bash
nano ~/.config/screenai/system_prompt.txt
```
*(Aquí puedes indicarle que sea aún más conciso, que responda en cierto tono, etc.).*

### Ajustar velocidad o voz de Piper:
```bash
nano ~/.config/screenai/config.toml
```

---

## 5. 🛠️ Comandos de Terminal Útiles

También puedes invocar ScreenAI manualmente desde tu consola:

```bash
# Lanzar el modo menú visual
screenai

# Lanzar el modo de voz directo
screenai-voice

# Recargar los atajos de Hyprland si editaste algo
hyprctl reload
```
