# Diagnóstico y Resolución de Problemas — ScreenAI

Si ScreenAI no responde, no emite sonido o presenta fallos tras presionar el atajo de teclado, utiliza esta guía para aislar y corregir el problema paso a paso.

---

## 1. Prueba Integral desde Terminal

Para visualizar la salida detallada y posibles mensajes de error, ejecuta ScreenAI directamente en una terminal en lugar de usar el atajo de Hyprland:

```bash
screenai
```

---

## 2. Diagnóstico Componente por Componente

Puedes probar cada eslabón de la cadena de forma aislada:

### Prueba 1: Captura de Pantalla (`grim`)
```bash
grim /tmp/test_screen.png && ls -lh /tmp/test_screen.png
```
- **Si falla con *"failed to create screencopy frame"*:** Asegúrate de estar en una sesión activa de Wayland con la variable `WAYLAND_DISPLAY` exportada (`echo $WAYLAND_DISPLAY`).
- **Si no se encuentra el binario:** Instala con `sudo pacman -S grim`.

---

### Prueba 2: Menú Emergente (`wofi`)
```bash
echo -e "Opción 1\nOpción 2" | wofi --dmenu --prompt "Test"
```
- **Si no abre:** Verifica que no haya otra instancia de wofi bloqueada (`killall wofi`).
- **Si falta el paquete:** Instala con `sudo pacman -S wofi`.

---

### Prueba 3: Conexión con la API de Google Gemini
Ejecuta este script rápido en Python para validar tu clave y conectividad:

```bash
python3 -c "
from google import genai
import tomllib
from pathlib import Path

conf = tomllib.loads(Path.home().joinpath('.config/screenai/config.toml').read_text())
client = genai.Client(api_key=conf['api']['api_key'])
res = client.models.generate_content(
    model=conf['api']['model'],
    contents='Di exactamente: Conexión con Gemini exitosa'
)
print(res.text)
"
```
#### Errores Comunes de Gemini:
- **`400 INVALID_ARGUMENT / API_KEY_INVALID`:** Tu clave de API es incorrecta o fue revocada. Reemplázala en `~/.config/screenai/config.toml`.
- **`429 RESOURCE_EXHAUSTED`:** Has superado la cuota de peticiones por minuto. Espera unos segundos o verifica tus límites en Google AI Studio.
- **`ModuleNotFoundError: No module named 'google'`:** Falta el SDK oficial. Instálalo con:
  ```bash
  pip install --break-system-packages google-genai
  ```

---

### Prueba 4: Síntesis de Voz (Audio y TTS)

#### Probar el motor local Piper:
```bash
echo "Hola, la prueba de audio con piper funciona correctamente." | \
  python3 ~/.local/share/screenai/screenai_tts.py /dev/stdin ~/.config/screenai/config.toml
```

#### Probar el reproductor de sonido ALSA / PipeWire:
```bash
aplay -l
```
Si `aplay` no encuentra dispositivos o PipeWire está suspendido:
```bash
systemctl --user restart pipewire wireplumber
```

#### Probar el fallback con espeak-ng:
```bash
espeak-ng -v es "Prueba de síntesis con espeak"
```
Si espeak-ng no está instalado:
```bash
sudo pacman -S espeak-ng
```

---

## 3. Revisión de Archivos de Registro y Errores Temporales

Tras ejecutar una consulta, revisa los archivos de depuración en `/tmp/screenai`:

```bash
# Ver el último error registrado por Python
cat /tmp/screenai/error.txt

# Ver el último texto de respuesta devuelto por Gemini
cat /tmp/screenai/response.txt

# Reproducir manualmente el último archivo de audio sintetizado
aplay /tmp/screenai/response.wav
```

---

## 4. Problemas con el Atajo de Teclado en Hyprland

Si el comando `screenai` funciona desde la terminal pero el atajo `Super + Shift + S` no hace nada:

1. **Verifica que el atajo esté registrado:**
   ```bash
   hyprctl binds | grep -i screenai
   ```
2. **Verifica la inclusión del archivo en tu configuración:**
   Abre `~/.config/hypr/bindings.conf` (o `hyprland.conf`) y asegúrate de que contenga:
   ```ini
   source = ~/.config/hypr/conf.d/screenai.conf
   ```
3. **Recarga Hyprland:**
   ```bash
   hyprctl reload
   ```
4. **Verifica el PATH de Hyprland:**
   Hyprland ejecuta comandos heredando el entorno del usuario. Asegúrate de que `~/.local/bin` esté en tu PATH exportado en `~/.bashrc`, `~/.zshrc` o `~/.config/hypr/envs.conf`:
   ```bash
   echo $PATH | grep -o '\.local/bin'
   ```
