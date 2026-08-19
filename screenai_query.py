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


def query_gemini(image_path: str, prompt: str, config: dict) -> str:
    from google import genai
    from google.genai import types

    api_key = config["api"]["api_key"]
    model   = config["api"].get("model", "gemini-2.5-flash")

    client = genai.Client(api_key=api_key)

    # Leer imagen
    with open(image_path, "rb") as f:
        image_data = f.read()

    # Construir prompt completo con contexto del sistema
    system_ctx = load_system_prompt()
    full_prompt = f"{system_ctx}\n\nPregunta del usuario: {prompt}" if system_ctx else prompt

    response = client.models.generate_content(
        model=model,
        contents=[
            types.Part.from_bytes(data=image_data, mime_type="image/png"),
            full_prompt,
        ]
    )

    return response.text


def main():
    if len(sys.argv) != 4:
        print("Uso: screenai_query.py <imagen> <prompt> <config.toml>", file=sys.stderr)
        sys.exit(1)

    image_path, prompt, config_path = sys.argv[1], sys.argv[2], sys.argv[3]

    try:
        config = load_config(config_path)
        result = query_gemini(image_path, prompt, config)
        print(result)
    except Exception as e:
        print(f"Error al consultar Gemini: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
