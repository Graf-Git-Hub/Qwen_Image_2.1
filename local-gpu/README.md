# Lokale GPU-Variante (Windows)

Lade den Ordner `local-gpu` herunter, entpacke ihn auf deinem PC und doppelklicke `START_GPU.cmd`. Die Oberfläche öffnet sich im Browser auf deinem Rechner. Beim ersten Start werden eine fertige CUDA-Engine (~Windows-Binärdateien), Python-Pakete und die vier Modell-Dateien (~11 GB) heruntergeladen. Modelle und Ausgaben bleiben im selben Ordner und werden bei weiteren Starts wiederverwendet.

Benötigt Windows, NVIDIA-Treiber, Python 3.11, genügend freien Speicher und eine NVIDIA-GPU. Für Paschys RTX 3070 (8 GB VRAM) nutzt die App `--offload-to-cpu --max-vram -1 --fa`; dabei liegen Gewichte teils in den 64 GB RAM und werden bedarfsweise zur GPU übertragen. Das ist GPU-beschleunigt, aber weder die Geschwindigkeit noch das Verhalten bei mehreren Referenzen ist bislang auf dieser Hardware gemessen. Starte mit 512 px und ohne Referenzbild.

Der lokale Webserver ist nur an `127.0.0.1` gebunden; Zugriff vom Handy im Heimnetz ist erst nach einer separaten, abgesicherten Freigabe vorgesehen. Die bestehende große Qwen-Installation bleibt unabhängig.
