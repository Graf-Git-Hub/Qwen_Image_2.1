# Qwen Image 2.1 Standalone for Windows

Lokale Windows-Oberfläche für **Qwen Image 2.1** mit Text-to-Image, Bildbearbeitung, bis zu 10 Referenzbildern, Warteschlange, Galerie, Fortschrittsanzeige und optionaler lokaler Ollama-Prompt-KI.

## Installation

Du brauchst nur **eine Datei**:

**[`INSTALL_QWEN_IMAGE_2_1.cmd`](./INSTALL_QWEN_IMAGE_2_1.cmd)**

Die CMD lädt automatisch den aktuellen Installer aus diesem Repository und erledigt danach selbstständig:

- Installationsordner anlegen
- Python 3.11 finden oder installieren
- virtuelle Python-Umgebung erstellen
- PyTorch, Diffusers, Transformers und weitere Abhängigkeiten installieren
- Qwen-Image-2.1 von Hugging Face herunterladen
- aktuelle Programmdateien installieren
- Desktop-Verknüpfung **Qwen Image 2.1** erstellen

Auf dem Rechner des Projektbesitzers wird der bekannte K:-Projektordner bevorzugt, falls dessen übergeordneter Ordner vorhanden ist. Auf anderen Rechnern wird standardmäßig unter `%LOCALAPPDATA%\Qwen-Image-2.1-Standalone` installiert.

## Automatische Updates

Nach der Installation benutzt du nur noch die Desktop-Verknüpfung **Qwen Image 2.1**.

Beim Start passiert automatisch:

1. lokale `VERSION.txt` lesen
2. aktuelle Version auf GitHub prüfen
3. bei neuer Version zuerst aktualisieren
4. danach Qwen starten
5. wenn GitHub gerade nicht erreichbar ist, die vorhandene Version starten

`model`, `venv`, `outputs`, Hugging-Face-Cache und lokale Ollama-Einstellungen bleiben bei Updates erhalten.

## Aktuelle Version

Siehe [`VERSION.txt`](./VERSION.txt).

## Voraussetzungen

- Windows 10 oder 11
- NVIDIA-GPU mit aktuellem Treiber
- Internetzugang für Erstinstallation und Updates
- ausreichend freier Speicherplatz für Qwen-Image-2.1
- Ollama nur optional für die Prompt-Optimierung

## Hinweise

Der Modelldownload ist groß und kann lange dauern. Ein abgebrochener Hugging-Face-Download kann beim nächsten Installer-Lauf fortgesetzt werden.

Die offizielle Qwen-Image-2.1-Nutzung basiert auf `QwenImage21Pipeline`, `transformers>=5.17`, aktuellem Diffusers, Accelerate und PyTorch.
