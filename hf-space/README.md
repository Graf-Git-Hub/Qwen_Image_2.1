---
title: Paschy Qwen Image CPU Test
emoji: 🎨
colorFrom: purple
colorTo: blue
sdk: gradio
app_file: app.py
python_version: 3.11
suggested_hardware: cpu-basic
---

# Paschy Qwen Image 2.1 Turbo

Private CPU Basic experiment. On first generation, the app builds stable-diffusion.cpp and downloads only the selected model components. Models are kept in the Space's temporary cache; a restarted Space may download them again. Two vCPU and 16 GB RAM may be too slow or insufficient, especially for multiple references.

Model: Unsloth Qwen Image 2.1 Turbo Q4_K_M; Qwen3-VL-8B-Instruct Q4_K_M and F16 vision projector; Qwen Image 2.1 VAE. Research license of the upstream model applies.
