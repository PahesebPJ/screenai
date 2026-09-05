#!/usr/bin/env bash
# ============================================================
# ScreenAI — Instalador
# Corre este script una sola vez para configurar todo.
# ============================================================
set -euo pipefail

# ── Colores ──────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; BLUE='\033[0;34m'
BOLD='\033[1m'; NC='\033[0m'

ok()   { echo -e "  ${GREEN}✔${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC}  $1"; }
err()  { echo -e "  ${RED}✘${NC} $1"; }
step() { echo -e "\n${BLUE}${BOLD}→ $1${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Rutas de instalación ──────────────────────────────────────
INSTALL_DIR="$HOME/.local/share/screenai"
CONF_DIR="$HOME/.config/screenai"
BIN_DIR="$HOME/.local/bin"
VOICES_DIR="$HOME/.local/share/piper/voices"
HYPR_CONF_DIR="$HOME/.config/hypr/conf.d"
HYPR_MAIN="$HOME/.config/hypr/hyprland.conf"
HYPR_BINDINGS="$HOME/.config/hypr/bindings.conf"

echo ""
echo -e "${BOLD}╔══════════════════════════════════╗${NC}"
echo -e "${BOLD}║  🤖  ScreenAI Installer          ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════╝${NC}"

# ── Paso 1: Directorios ───────────────────────────────────────
step "Creando directorios"
mkdir -p "$INSTALL_DIR" "$CONF_DIR" "$BIN_DIR" "$VOICES_DIR" "$HYPR_CONF_DIR"
ok "Directorios listos"

# ── Paso 2: Dependencias del sistema ─────────────────────────
step "Instalando dependencias del sistema"
PKGS_TO_INSTALL=()
for pkg in grim espeak-ng python-pip; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        PKGS_TO_INSTALL+=("$pkg")
    fi
done

if [[ ${#PKGS_TO_INSTALL[@]} -gt 0 ]]; then
    echo "  Instalando: ${PKGS_TO_INSTALL[*]}"
    sudo pacman -S --noconfirm --needed "${PKGS_TO_INSTALL[@]}" && \
        ok "Dependencias del sistema instaladas" || \
        warn "Algunas dependencias no se pudieron instalar con pacman"
else
    ok "Dependencias del sistema ya instaladas"
fi

# ── Paso 3: Entorno Virtual y Dependencias Python ────────────
step "Configurando entorno virtual de Python"
VENV_DIR="$INSTALL_DIR/venv"
if [[ ! -d "$VENV_DIR" ]]; then
    python3 -m venv "$VENV_DIR"
    ok "Entorno virtual creado en $VENV_DIR"
else
    ok "Entorno virtual existente en $VENV_DIR"
fi

step "Instalando dependencias Python en el entorno virtual"
"$VENV_DIR/bin/pip" install --upgrade --quiet pip

# google-genai (cliente oficial de Gemini)
if ! "$VENV_DIR/bin/python3" -c "from google import genai" 2>/dev/null; then
    echo "  Instalando google-genai..."
    "$VENV_DIR/bin/pip" install --quiet google-genai && ok "google-genai instalado" || \
        warn "No se pudo instalar google-genai en el venv"
else
    ok "google-genai ya instalado en el venv"
fi

# piper-tts (TTS local de alta calidad)
if ! "$VENV_DIR/bin/python3" -c "from piper.voice import PiperVoice" 2>/dev/null && \
   ! command -v piper &>/dev/null; then
    echo "  Instalando piper-tts..."
    "$VENV_DIR/bin/pip" install --quiet piper-tts && ok "piper-tts instalado" || \
        warn "piper-tts no disponible — se usará espeak-ng como TTS"
else
    ok "piper-tts ya instalado en el venv"
fi

# ── Paso 4: Modelo de voz español ────────────────────────────
step "Descargando modelo de voz en español (es_ES-sharvard-medium)"
VOICE_NAME="es_ES-sharvard-medium"
VOICE_ONNX="$VOICES_DIR/${VOICE_NAME}.onnx"
VOICE_JSON="$VOICES_DIR/${VOICE_NAME}.onnx.json"
BASE_URL="https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/es/es_ES/sharvard/medium"

if [[ ! -f "$VOICE_ONNX" ]]; then
    echo "  Descargando ${VOICE_NAME}.onnx (~60MB)..."
    if wget -q --show-progress \
            -O "$VOICE_ONNX" "${BASE_URL}/${VOICE_NAME}.onnx" && \
       wget -q -O "$VOICE_JSON" "${BASE_URL}/${VOICE_NAME}.onnx.json"; then
        ok "Modelo de voz descargado"
    else
        rm -f "$VOICE_ONNX" "$VOICE_JSON"
        warn "No se pudo descargar el modelo de voz"
        warn "TTS usará espeak-ng. Para instalar piper manualmente:"
        warn "  wget -O $VOICE_ONNX ${BASE_URL}/${VOICE_NAME}.onnx"
    fi
else
    ok "Modelo de voz ya descargado"
fi

# ── Paso 5: Copiar archivos del proyecto ──────────────────────
step "Instalando archivos de ScreenAI"
cp "$SCRIPT_DIR/screenai.sh"       "$INSTALL_DIR/screenai.sh"
cp "$SCRIPT_DIR/screenai_voice.sh" "$INSTALL_DIR/screenai_voice.sh"
cp "$SCRIPT_DIR/screenai_query.py" "$INSTALL_DIR/screenai_query.py"
cp "$SCRIPT_DIR/screenai_tts.py"   "$INSTALL_DIR/screenai_tts.py"
cp "$SCRIPT_DIR/prompts.txt"       "$INSTALL_DIR/prompts.txt"
cp "$SCRIPT_DIR/wofi.css"          "$INSTALL_DIR/wofi.css"
chmod +x "$INSTALL_DIR/screenai.sh" "$INSTALL_DIR/screenai_voice.sh"
ok "Scripts copiados a $INSTALL_DIR"

# ── Paso 6: Configuración ─────────────────────────────────────
step "Configurando ScreenAI"

# Config principal (no sobreescribir si ya existe)
if [[ ! -f "$CONF_DIR/config.toml" ]]; then
    cp "$SCRIPT_DIR/config.toml" "$CONF_DIR/config.toml"
    chmod 600 "$CONF_DIR/config.toml"  # permisos solo para el usuario
    ok "config.toml creado"
else
    ok "config.toml ya existe (no sobreescrito)"
fi

# System prompt (siempre actualizar)
cp "$SCRIPT_DIR/system_prompt.txt" "$CONF_DIR/system_prompt.txt"
ok "system_prompt.txt actualizado"

# ── Paso 7: Symlink en PATH ───────────────────────────────────
ln -sf "$INSTALL_DIR/screenai.sh" "$BIN_DIR/screenai"
ln -sf "$INSTALL_DIR/screenai_voice.sh" "$BIN_DIR/screenai-voice"
ok "Symlinks creados: $BIN_DIR/screenai y $BIN_DIR/screenai-voice"

# Verificar que $BIN_DIR está en PATH
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    warn "$BIN_DIR no está en tu PATH"
    warn "Agrega esto a ~/.bashrc o ~/.zshrc:"
    warn "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# ── Paso 8: Configurar Hyprland ───────────────────────────────
step "Configurando keybind en Hyprland"
HYPR_CONF="$HYPR_CONF_DIR/screenai.conf"
cp "$SCRIPT_DIR/hypr_screenai.conf" "$HYPR_CONF"
ok "Archivo de keybind: $HYPR_CONF"

# Agregar source al archivo de configuración principal de Hyprland
SOURCE_LINE="source = $HYPR_CONF"
ADDED=false

# Omarchy usa bindings.conf; si existe, agregamos ahí
if [[ -f "$HYPR_BINDINGS" ]] && ! grep -qF "screenai.conf" "$HYPR_BINDINGS"; then
    echo "" >> "$HYPR_BINDINGS"
    echo "# ScreenAI" >> "$HYPR_BINDINGS"
    echo "$SOURCE_LINE" >> "$HYPR_BINDINGS"
    ok "Keybind agregado a bindings.conf"
    ADDED=true
fi

# También verificar hyprland.conf
if [[ -f "$HYPR_MAIN" ]] && ! grep -qF "screenai.conf" "$HYPR_MAIN" && [[ "$ADDED" == false ]]; then
    echo "" >> "$HYPR_MAIN"
    echo "# ScreenAI" >> "$HYPR_MAIN"
    echo "$SOURCE_LINE" >> "$HYPR_MAIN"
    ok "Keybind agregado a hyprland.conf"
    ADDED=true
fi

if [[ "$ADDED" == false ]]; then
    warn "No se pudo auto-configurar Hyprland. Agrega manualmente:"
    warn "  $SOURCE_LINE"
    warn "a ~/.config/hypr/bindings.conf o hyprland.conf"
fi

# ── Resumen final ─────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║  ✅  ScreenAI instalado con éxito!   ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}Próximos pasos:${NC}"
echo "  1. Recargar Hyprland:  hyprctl reload"
echo "  2. Presiona ${BOLD}Super+Shift+S${NC} para probar"
echo ""
echo -e "${BOLD}Archivos:${NC}"
echo "  Scripts:       $INSTALL_DIR/"
echo "  Config:        $CONF_DIR/config.toml"
echo "  Prompts:       $INSTALL_DIR/prompts.txt"
echo "  System prompt: $CONF_DIR/system_prompt.txt"
echo "  Voz piper:     $VOICES_DIR/"
echo ""
echo -e "${BOLD}Diagnóstico rápido:${NC}"
echo "  grim /tmp/test.png && echo 'grim OK'"
echo "  espeak-ng -v es 'Hola mundo'"
echo "  screenai  # prueba manual desde terminal"
echo ""
