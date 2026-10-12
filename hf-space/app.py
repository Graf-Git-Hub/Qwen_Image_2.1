"""Mobile-friendly Qwen Image 2.1 Turbo GGUF CPU experiment for HF Spaces."""

import os
import subprocess
import tempfile
import threading
import time
from pathlib import Path

import gradio as gr
from huggingface_hub import hf_hub_download
from PIL import Image


ROOT = Path("/tmp/paschy-qwen")
SRC = ROOT / "stable-diffusion.cpp"
MODEL_DIR = ROOT / "models"
OUTPUT_DIR = ROOT / "output"
LOCK = threading.Lock()
PREPARATION = {"state": "preparing", "message": "Engine und Modelle werden vorbereitet …", "cli": None, "paths": None}
SIGMAS = "1.0,0.978453,0.95418,0.926626,0.89508,0.845148,0.704534,0.414568,0.0"
FILES = {
    "diffusion": ("unsloth/Qwen-Image-2.1-Turbo-GGUF", "qwen-image-2.1-turbo-Q4_K_M.gguf"),
    "llm": ("Qwen/Qwen3-VL-8B-Instruct-GGUF", "Qwen3VL-8B-Instruct-Q4_K_M.gguf"),
    "vision": ("Qwen/Qwen3-VL-8B-Instruct-GGUF", "mmproj-Qwen3VL-8B-Instruct-F16.gguf"),
    "vae": ("Comfy-Org/Qwen-Image-2.1", "vae/qwen_image_2.1_vae_bf16.safetensors"),
}
RATIOS = {
    "⬜ Quadratisch 1:1": 1.0,
    "📱 Handy 9:16": 9 / 16,
    "🖥️ Querformat 16:9": 16 / 9,
    "🖼️ Hochformat 3:4": 3 / 4,
    "🌄 Querformat 4:3": 4 / 3,
    "📄 A4 ungefähr 1:√2": 1 / 2**0.5,
}
SIZES = {"Schnelltest (512 px)": 512, "Mittel (768 px)": 768, "Groß (1024 px)": 1024}


def dimensions(ratio_name, size_name):
    ratio = RATIOS[ratio_name]
    long_edge = SIZES[size_name]
    if ratio >= 1:
        return long_edge, max(32, round(long_edge / ratio / 32) * 32)
    return max(32, round(long_edge * ratio / 32) * 32), long_edge


def binary():
    executable = SRC / "build" / "bin" / "sd-cli"
    if executable.exists():
        return executable
    ROOT.mkdir(parents=True, exist_ok=True)
    if not SRC.exists():
        subprocess.run(["git", "clone", "--depth", "1", "--recursive", "https://github.com/leejet/stable-diffusion.cpp", str(SRC)], check=True, timeout=900)
    subprocess.run(["cmake", "-S", str(SRC), "-B", str(SRC / "build"), "-DCMAKE_BUILD_TYPE=Release"], check=True, timeout=300)
    subprocess.run(["cmake", "--build", str(SRC / "build"), "--config", "Release", "-j", "2"], check=True, timeout=1800)
    if not executable.exists():
        raise RuntimeError("Der Build hat sd-cli nicht erzeugt. Bitte die Build-Logs des Space prüfen.")
    return executable


def models():
    paths = {}
    for key, (repo, filename) in FILES.items():
        paths[key] = hf_hub_download(repo_id=repo, filename=filename, cache_dir=str(MODEL_DIR))
    return paths


def prepare():
    try:
        PREPARATION["message"] = "Engine wird gebaut …"
        cli = binary()
        PREPARATION["message"] = "Modell-Dateien werden geladen (etwa 11 GB) …"
        paths = models()
        PREPARATION.update(state="ready", message="Bereit: Engine und alle Modell-Dateien sind vorhanden.", cli=cli, paths=paths)
    except Exception as exc:
        PREPARATION.update(state="error", message=f"Vorbereitung fehlgeschlagen: {exc}")


def readiness():
    return PREPARATION["message"], gr.update(interactive=PREPARATION["state"] == "ready")


def generate(prompt, references, ratio_name, size_name, seed, progress=gr.Progress()):
    if PREPARATION["state"] != "ready":
        raise gr.Error(PREPARATION["message"])
    if not prompt or not prompt.strip():
        raise gr.Error("Bitte erst einen Prompt eingeben.")
    refs = references or []
    if len(refs) > 5:
        raise gr.Error("Maximal fünf Referenzbilder hochladen.")
    if not LOCK.acquire(blocking=False):
        raise gr.Error("Ein Bild wird bereits erzeugt. Bitte warten.")
    try:
        cli = PREPARATION["cli"]
        paths = PREPARATION["paths"]
        width, height = dimensions(ratio_name, size_name)
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        name = f"qwen-{int(time.time())}.png"
        output = OUTPUT_DIR / name
        command = [
            str(cli), "--diffusion-model", paths["diffusion"], "--vae", paths["vae"],
            "--llm", paths["llm"], "--sigmas", SIGMAS, "--steps", "8",
            "--cfg-scale", "1.0", "--sampling-method", "euler",
            "--offload-to-cpu", "--vae-tiling", "-W", str(width), "-H", str(height),
            "-p", prompt.strip(), "--seed", str(int(seed)), "-o", str(output),
        ]
        if refs:
            command += ["--llm_vision", paths["vision"]]
            with tempfile.TemporaryDirectory(prefix="qwen-refs-") as folder:
                for i, path in enumerate(refs):
                    converted = Path(folder) / f"reference-{i+1}.png"
                    with Image.open(path) as im:
                        im.convert("RGB").save(converted)
                    command += ["-r", str(converted)]
                progress(0.3, desc=f"Erzeuge {width} × {height}; auf CPU kann das lange dauern")
                result = subprocess.run(command, capture_output=True, text=True, timeout=7200)
        else:
            progress(0.3, desc=f"Erzeuge {width} × {height}; auf CPU kann das lange dauern")
            result = subprocess.run(command, capture_output=True, text=True, timeout=7200)
        if result.returncode or not output.is_file():
            tail = (result.stderr + "\n" + result.stdout)[-1800:]
            raise RuntimeError(f"Bildberechnung fehlgeschlagen: {tail}")
        progress(1, desc="Fertig")
        return str(output), str(output), f"Fertig: {width} × {height} px. Bei 4K erst ein kleineres Bild erzeugen und später hochskalieren."
    except Exception as exc:
        raise gr.Error(str(exc)) from exc
    finally:
        LOCK.release()


with gr.Blocks(title="Paschy Qwen Image", theme=gr.themes.Soft()) as demo:
    gr.Markdown("# 🎨 Qwen Image 2.1 Turbo\nBild erzeugen, verändern oder Referenzen kombinieren. Nach dem Start lädt der Space die Modelle automatisch. Warte auf **Bereit**. **CPU Basic ist ein Versuch:** 16 GB RAM und 2 Kerne können an ihre Grenzen kommen.")
    with gr.Row():
        with gr.Column():
            references = gr.File(label="Referenzbilder (0–5, in gewünschter Reihenfolge)", file_count="multiple", file_types=["image"], type="filepath")
            prompt = gr.Textbox(label="Was soll auf dem Bild passieren?", lines=4, placeholder="Zum Beispiel: Kombiniere das Motiv aus Bild 1 mit dem Stil von Bild 2 …")
            ratio = gr.Radio(choices=list(RATIOS), value="⬜ Quadratisch 1:1", label="Format")
            size = gr.Radio(choices=list(SIZES), value="Schnelltest (512 px)", label="Auflösung (lange Kante)")
            seed = gr.Number(value=-1, precision=0, label="Seed (-1 = zufällig)")
            button = gr.Button("✨ Bild erzeugen", variant="primary", interactive=False)
        with gr.Column():
            result = gr.Image(label="Ergebnis", type="filepath", interactive=False)
            download = gr.File(label="Bild herunterladen")
            status = gr.Textbox(label="Status", interactive=False)
    gr.Markdown("**Hinweis:** Full HD und 4K sind keine direkten CPU-Presets. Erst prüfen wir, ob 512 px mit Referenzen überhaupt zuverlässig läuft. Der Space ist privat; gib die URL nicht als offenen Bilddienst weiter.")
    button.click(generate, inputs=[prompt, references, ratio, size, seed], outputs=[result, download, status], concurrency_limit=1)
    timer = gr.Timer(5)
    demo.load(readiness, outputs=[status, button])
    timer.tick(readiness, outputs=[status, button])

threading.Thread(target=prepare, daemon=True).start()
demo.queue(max_size=2).launch()
