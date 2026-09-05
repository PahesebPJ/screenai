#!/usr/bin/env python3
"""
ScreenAI — Cliente multimodal para Google Gemini
Envía una captura de pantalla + prompt y retorna la respuesta.

Uso: screenai_query.py <imagen> <prompt> <config.toml>
"""
import sys
import tomllib
from pathlib import Path


def load_config(config_path: str) -> dict:
    with open(config_path, "rb") as f:
        return tomllib.load(f)


def load_system_prompt() -> str:
    path = Path.home() / ".config/screenai/system_prompt.txt"
    return path.read_text().strip() if path.exists() else ""


def query_gemini(image_path: str, prompt_or_audio: str, config: dict, is_voice: bool = False) -> str:
    from google import genai
    from google.genai import types

    api_key = config["api"]["api_key"]
    primary_model = config["api"].get("model", "gemini-3.8-flash")

    client = genai.Client(api_key=api_key)

    # Leer imagen
    with open(image_path, "rb") as f:
        image_data = f.read()

    contents = [types.Part.from_bytes(data=image_data, mime_type="image/png")]

    system_ctx = load_system_prompt()

    if is_voice:
        # Modo voz: inyectar archivo de audio WAV y system prompt
        with open(prompt_or_audio, "rb") as f:
            audio_data = f.read()
        contents.append(types.Part.from_bytes(data=audio_data, mime_type="audio/wav"))
        if system_ctx:
            contents.append(f"{system_ctx}\n\nInstrucción: Escucha la pregunta del usuario en el audio adjunto, analiza lo que se ve en la imagen y responde en español.")
        else:
            contents.append("Escucha la pregunta del usuario en el audio adjunto, analiza la imagen y responde en español de forma concisa.")
    else:
        # Modo texto estándar
        full_prompt = f"{system_ctx}\n\nPregunta del usuario: {prompt_or_audio}" if system_ctx else prompt_or_audio
        contents.append(full_prompt)

    # Modelos candidatos con fallback automático ante alta demanda (503) o cambio de versión
    candidate_models = [primary_model]
    for fallback in ["gemini-3.8-flash", "gemini-3.7-flash", "gemini-flash-latest"]:
        if fallback not in candidate_models:
            candidate_models.append(fallback)

    last_error = None
    for model_name in candidate_models:
        try:
            response = client.models.generate_content(
                model=model_name,
                contents=contents
            )
            if response and response.text:
                return response.text
        except Exception as e:
            last_error = e
            continue

    raise last_error if last_error else RuntimeError("No se pudo obtener respuesta de Gemini")


def main():
    if len(sys.argv) == 5 and sys.argv[1] == "--voice":
        image_path, audio_path, config_path = sys.argv[2], sys.argv[3], sys.argv[4]
        is_voice = True
        prompt_arg = audio_path
    elif len(sys.argv) == 4:
        image_path, prompt_arg, config_path = sys.argv[1], sys.argv[2], sys.argv[3]
        is_voice = False
    else:
        print("Uso: screenai_query.py [--voice] <imagen> <prompt/audio.wav> <config.toml>", file=sys.stderr)
        sys.exit(1)

    try:
        config = load_config(config_path)
        result = query_gemini(image_path, prompt_arg, config, is_voice=is_voice)
        print(result)
    except Exception as e:
        print(f"Error al consultar Gemini: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
