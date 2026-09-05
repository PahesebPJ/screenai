#!/usr/bin/env bash
# ============================================================
# ScreenAI — Script principal
# Invocado por el atajo de teclado Super+Shift+S en Hyprland
# ============================================================
set -euo pipefail

SCREENAI_HOME="$HOME/.local/share/screenai"
CONF_DIR="$HOME/.config/screenai"
TMP="/tmp/screenai"
mkdir -p "$TMP"

# ── 1. Captura de pantalla completa (silenciosa) ──────────────
if ! grim "$TMP/screenshot.png" 2>/dev/null; then
    notify-send "ScreenAI" "❌ Error al capturar la pantalla" -u critical -t 5000
    exit 1
fi

# ── 2. Menú de prompts via wofi ───────────────────────────────
# Si el usuario escribe algo que no está en la lista, wofi lo
# devuelve tal cual → funciona como input personalizado también.
PROMPT=$(cat "$SCREENAI_HOME/prompts.txt" | wofi \
    --dmenu \
    --prompt "ScreenAI ✨" \
    --width 580 \
    --lines 10 \
    --insensitive \
    --style "$SCREENAI_HOME/wofi.css" \
    2>/dev/null) || exit 0

[[ -z "$PROMPT" ]] && exit 0

# ── Determinar intérprete de Python (venv prioritario) ────────
if [[ -x "$SCREENAI_HOME/venv/bin/python3" ]]; then
    PYTHON_BIN="$SCREENAI_HOME/venv/bin/python3"
else
    PYTHON_BIN="python3"
fi

# ── 3. Notificación de estado ─────────────────────────────────
notify-send "ScreenAI" "🤖 Consultando Gemini..." -t 20000 -u low -i dialog-information

# ── 4. Consultar Gemini multimodal ────────────────────────────
if ! "$PYTHON_BIN" "$SCREENAI_HOME/screenai_query.py" \
        "$TMP/screenshot.png" \
        "$PROMPT" \
        "$CONF_DIR/config.toml" \
        > "$TMP/response.txt" 2>"$TMP/error.txt"; then

    ERROR=$(head -n 1 "$TMP/error.txt" 2>/dev/null || echo "Error desconocido")
    notify-send "ScreenAI" "❌ $ERROR" -u critical -t 8000
    exit 1
fi

# ── 5. Notificación con preview del texto ────────────────────
PREVIEW=$(head -c 220 "$TMP/response.txt" | tr '\n' ' ')
notify-send "ScreenAI" "💬 $PREVIEW" -t 12000

# ── 6. Respuesta por voz (TTS) ────────────────────────────────
"$PYTHON_BIN" "$SCREENAI_HOME/screenai_tts.py" \
    "$TMP/response.txt" \
    "$CONF_DIR/config.toml"
