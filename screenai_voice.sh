#!/usr/bin/env bash
# ============================================================
# ScreenAI — Modo Voz Directo
# Invocado por Super+Shift+V en Hyprland (toggle start/stop)
#
# 1. Primera pulsación: Captura pantalla y comienza a grabar micrófono.
# 2. Segunda pulsación: Detiene grabación, envía audio + pantalla a Gemini
#    y lee la respuesta por voz con Piper.
# ============================================================
set -euo pipefail

SCREENAI_HOME="$HOME/.local/share/screenai"
CONF_DIR="$HOME/.config/screenai"
TMP="/tmp/screenai"
mkdir -p "$TMP"

PID_FILE="$TMP/recording.pid"
AUDIO_FILE="$TMP/voice_prompt.wav"
SCREENSHOT_FILE="$TMP/screenshot.png"

# Determinar intérprete de Python (venv prioritario)
if [[ -x "$SCREENAI_HOME/venv/bin/python3" ]]; then
    PYTHON_BIN="$SCREENAI_HOME/venv/bin/python3"
else
    PYTHON_BIN="python3"
fi

# ── CASO 1: Si ya está grabando -> Detener, procesar y responder ──
if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null; then
    REC_PID=$(cat "$PID_FILE")
    rm -f "$PID_FILE"

    # Enviar SIGINT a pw-record para cerrar limpiamente el encabezado WAV
    kill -2 "$REC_PID" 2>/dev/null || true
    sleep 0.3

    notify-send "ScreenAI 🤖" "Procesando tu voz y pantalla..." -t 20000 -u low -i dialog-information

    if ! "$PYTHON_BIN" "$SCREENAI_HOME/screenai_query.py" \
            --voice \
            "$SCREENSHOT_FILE" \
            "$AUDIO_FILE" \
            "$CONF_DIR/config.toml" \
            > "$TMP/response.txt" 2>"$TMP/error.txt"; then

        ERROR=$(head -n 1 "$TMP/error.txt" 2>/dev/null || echo "Error en la consulta")
        notify-send "ScreenAI" "❌ $ERROR" -u critical -t 8000
        exit 1
    fi

    # Notificación con preview
    PREVIEW=$(head -c 220 "$TMP/response.txt" | tr '\n' ' ')
    notify-send "ScreenAI" "💬 $PREVIEW" -t 12000

    # Reproducción de voz
    "$PYTHON_BIN" "$SCREENAI_HOME/screenai_tts.py" \
        "$TMP/response.txt" \
        "$CONF_DIR/config.toml"

    exit 0
fi

# ── CASO 2: Si no está grabando -> Capturar pantalla y grabar micrófono ──
# 1. Capturar pantalla inmediatamente en el momento en que se activa
if ! grim "$SCREENSHOT_FILE" 2>/dev/null; then
    notify-send "ScreenAI" "❌ Error al capturar la pantalla (grim)" -u critical -t 5000
    exit 1
fi

# 2. Limpiar grabación anterior
rm -f "$AUDIO_FILE" "$PID_FILE"

# 3. Iniciar grabación en segundo plano con pw-record
pw-record --rate 16000 --channels 1 "$AUDIO_FILE" &
REC_PID=$!
echo "$REC_PID" > "$PID_FILE"

notify-send "ScreenAI 🎙️" "Escuchando... Habla y presiona el atajo de nuevo para enviar." -t 15000 -u normal

# 4. Watchdog de seguridad: Si pasan 25 segundos sin pulsar de nuevo, procesar automáticamente
(
    sleep 25
    if [[ -f "$PID_FILE" ]] && [[ "$(cat "$PID_FILE" 2>/dev/null)" == "$REC_PID" ]]; then
        /home/alan/.local/bin/screenai-voice
    fi
) & disown
