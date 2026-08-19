#!/usr/bin/env python3
"""
ScreenAI — Motor TTS
Convierte texto a voz usando piper (local) con fallback a espeak-ng.

Uso: screenai_tts.py <archivo_respuesta> <config.toml>
"""
import sys
import wave
import subprocess
import tomllib
from pathlib import Path


def load_config(config_path: str) -> dict:
    with open(config_path, "rb") as f:
        return tomllib.load(f)


def speak_with_piper(text: str, voice_name: str) -> bool:
    """
    Usa piper-tts (Python API) para generar audio.
    Retorna True si tuvo éxito, False si falló.
    """
    voices_dir = Path.home() / ".local/share/piper/voices"
    model_path = voices_dir / f"{voice_name}.onnx"
    wav_path   = Path("/tmp/screenai/response.wav")
    wav_path.parent.mkdir(parents=True, exist_ok=True)

    if not model_path.exists():
        print(f"[TTS] Modelo no encontrado: {model_path}", file=sys.stderr)
        return False

    try:
        from piper.voice import PiperVoice  # type: ignore

        voice = PiperVoice.load(str(model_path))
        with wave.open(str(wav_path), "w") as wav_file:
            voice.synthesize(text, wav_file)

        # Intentar reproducir con aplay, paplay o mpv
        for player_cmd in [
            ["aplay", "-q", str(wav_path)],
            ["paplay", str(wav_path)],
            ["mpv", "--no-video", "--really-quiet", str(wav_path)],
        ]:
            try:
                subprocess.run(player_cmd, check=True,
                               capture_output=True, timeout=60)
                return True
            except (FileNotFoundError, subprocess.CalledProcessError):
                continue

        print("[TTS] No se encontró reproductor de audio (aplay/paplay/mpv)", file=sys.stderr)
        return False

    except ImportError:
        # piper-tts no instalado como paquete Python, intentar CLI
        return speak_with_piper_cli(text, str(model_path), str(wav_path))
    except Exception as e:
        print(f"[TTS] Error en piper: {e}", file=sys.stderr)
        return False


def speak_with_piper_cli(text: str, model_path: str, wav_path: str) -> bool:
    """Fallback: usar piper como comando CLI."""
    try:
        proc = subprocess.run(
            ["piper", "--model", model_path, "--output_file", wav_path],
            input=text.encode(),
            capture_output=True,
            timeout=30
        )
        if proc.returncode != 0:
            return False

        subprocess.run(["aplay", "-q", wav_path], check=True,
                       capture_output=True, timeout=60)
        return True
    except Exception:
        return False


def speak_with_espeak(text: str) -> bool:
    """Fallback: espeak-ng (siempre disponible en Arch)."""
    try:
        subprocess.run(
            ["espeak-ng", "-v", "es", "-s", "145", "-a", "85", text],
            check=True, timeout=60
        )
        return True
    except Exception as e:
        print(f"[TTS] Error en espeak-ng: {e}", file=sys.stderr)
        return False


def main():
    if len(sys.argv) != 3:
        print("Uso: screenai_tts.py <archivo_respuesta> <config.toml>", file=sys.stderr)
        sys.exit(1)

    response_file, config_path = sys.argv[1], sys.argv[2]

    # Leer texto de respuesta
    text = Path(response_file).read_text().strip()
    if not text:
        print("[TTS] Respuesta vacía, nada que hablar.", file=sys.stderr)
        sys.exit(0)

    # Cargar configuración
    config = load_config(config_path)
    tts_cfg = config.get("tts", {})
    engine  = tts_cfg.get("engine", "piper")
    voice   = tts_cfg.get("voice", "es_ES-sharvard-medium")

    # Intentar TTS según configuración
    success = False
    if engine == "piper":
        success = speak_with_piper(text, voice)
        if not success:
            print("[TTS] piper falló, usando espeak-ng como fallback", file=sys.stderr)
            success = speak_with_espeak(text)
    else:
        success = speak_with_espeak(text)

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
