"""Local Windows CUDA frontend for Qwen Image 2.1 Turbo GGUF."""

import subprocess
import tempfile
import threading
import time
from pathlib import Path

import gradio as gr
from huggingface_hub import hf_hub_download
from PIL import Image


ROOT = Path(__file__).resolve().parent
MODEL_DIR = ROOT / "models"
OUTPUT_DIR = ROOT / "outputs"
LOCK = threading.Lock()
STATE = {"message": "Modell-Dateien werden vorbereitet …", "paths": None}
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
    ratio, edge = RATIOS[ratio_name], SIZES[size_name]
    if ratio >= 1:
        return edge, max(32, round(edge / ratio / 32) * 32)
    return max(32, round(edge * ratio / 32) * 32), edge


def engine():
    matches = list((ROOT / "engine").rglob("sd-cli.exe"))
    if not matches:
        raise RuntimeError("CUDA-Engine fehlt. Bitte START_GPU.cmd erneut starten.")
    return matches[0]


def prepare():
    try:
        engine()
        paths = {}
        for key, (repo, filename) in FILES.items():
            STATE["message"] = f"Lade {key}: {filename} …"
            paths[key] = hf_hub_download(repo_id=repo, filename=filename, cache_dir=str(MODEL_DIR))
        STATE.update(message="Bereit: CUDA-Engine und Modelle vorhanden.", paths=paths)
    except Exception as exc:
        STATE["message"] = f"Vorbereitung fehlgeschlagen: {exc}"


def readiness():
    return STATE["message"], gr.update(interactive=STATE["paths"] is not None)


def generate(prompt, references, ratio_name, size_name, seed, progress=gr.Progress()):
    if STATE["paths"] is None:
        raise gr.Error(STATE["message"])
    if not prompt or not prompt.strip():
        raise gr.Error("Bitte einen Prompt eingeben.")
    refs = references or []
    if len(refs) > 5:
        raise gr.Error("Maximal fünf Referenzbilder hochladen.")
    if not LOCK.acquire(blocking=False):
        raise gr.Error("Ein Bild wird bereits erzeugt.")
    try:
        paths = STATE["paths"]
        width, height = dimensions(ratio_name, size_name)
        OUTPUT_DIR.mkdir(exist_ok=True)
        output = OUTPUT_DIR / f"qwen-{time.time_ns()}.png"
        command = [
            str(engine()), "--diffusion-model", paths["diffusion"], "--vae", paths["vae"],
            "--llm", paths["llm"], "--sigmas", SIGMAS, "--steps", "8", "--cfg-scale", "1.0",
            "--sampling-method", "euler", "--offload-to-cpu", "--max-vram", "-1",
            "--fa", "--vae-tiling", "-W", str(width), "-H", str(height),
            "-p", prompt.strip(), "--seed", str(int(seed)), "-o", str(output),
        ]
        with tempfile.TemporaryDirectory(prefix="qwen-refs-") as folder:
            if refs:
                command += ["--llm_vision", paths["vision"]]
            for i, path in enumerate(refs):
                converted = Path(folder) / f"reference-{i+1}.png"
                with Image.open(path) as image:
                    image.convert("RGB").save(converted)
                command += ["-r", str(converted)]
            progress(0.1, desc=f"CUDA berechnet {width} × {height} …")
            result = subprocess.run(command, capture_output=True, text=True, timeout=7200)
        if result.returncode or not output.is_file():
            raise RuntimeError((result.stderr + "\n" + result.stdout)[-2500:])
        progress(1, desc="Fertig")
        return str(output), str(output), f"Fertig: {width} × {height} px. Datei: {output}"
    except Exception as exc:
        raise gr.Error(f"Bildberechnung fehlgeschlagen: {exc}") from exc
    finally:
        LOCK.release()


def build_ui():
    with gr.Blocks(title="Paschy Qwen Image GPU") as demo:
        gr.Markdown("# 🎨 Qwen Image 2.1 Turbo · GPU\nBilder erzeugen, bearbeiten oder bis zu fünf Referenzen kombinieren. Beim ersten Start werden die GGUF-Dateien geladen. Warte auf **Bereit**.")
        with gr.Row():
            with gr.Column():
                references = gr.File(label="Referenzbilder (0–5, Reihenfolge beachten)", file_count="multiple", file_types=["image"], type="filepath")
                prompt = gr.Textbox(label="Was soll auf dem Bild passieren?", lines=4)
                ratio = gr.Radio(choices=list(RATIOS), value="⬜ Quadratisch 1:1", label="Format")
                size = gr.Radio(choices=list(SIZES), value="Schnelltest (512 px)", label="Auflösung (lange Kante)")
                seed = gr.Number(value=-1, precision=0, label="Seed (-1 = zufällig)")
                button = gr.Button("✨ Bild erzeugen", variant="primary", interactive=False)
            with gr.Column():
                result = gr.Image(label="Ergebnis", type="filepath", interactive=False)
                download = gr.File(label="Bild herunterladen")
                status = gr.Textbox(label="Status", interactive=False)
        button.click(generate, inputs=[prompt, references, ratio, size, seed], outputs=[result, download, status], concurrency_limit=1)
        timer = gr.Timer(5)
        demo.load(readiness, outputs=[status, button])
        timer.tick(readiness, outputs=[status, button])
    return demo


if __name__ == "__main__":
    threading.Thread(target=prepare, daemon=True).start()
    build_ui().queue(max_size=2).launch(server_name="127.0.0.1", inbrowser=True)
