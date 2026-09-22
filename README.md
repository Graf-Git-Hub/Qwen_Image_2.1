# Qwen Image 2.1 Standalone for Windows

## Empfohlen: Ein-Klick Setup / Update

Für eine bestehende oder neue Installation nimm am besten nur diese Datei:

**[`QWEN_IMAGE_2_1_EIN_KLICK_SETUP_UPDATE.cmd`](./QWEN_IMAGE_2_1_EIN_KLICK_SETUP_UPDATE.cmd)**

Sie prüft automatisch die vorhandene Installation, vergleicht die lokale Version mit GitHub, ergänzt fehlende Dateien, aktualisiert bei Bedarf und erstellt anschließend die Desktop-Verknüpfung **Qwen Image 2.1** mit Symbol.

Die Desktop-Verknüpfung startet später immer über `START_QWEN_IMAGE_2_1.cmd`. Diese prüft vor jedem Start `VERSION.txt` auf GitHub. Gibt es ein Update, wird zuerst aktualisiert und danach gestartet. Gibt es kein Update, startet Qwen direkt.

Eine eigenständige Windows-Oberfläche für **Qwen Image 2.1**, ohne ComfyUI. Sie ist auf Rechner mit NVIDIA-GPU und begrenztem VRAM ausgelegt und enthält Bildgenerierung, Bildbearbeitung mit mehreren Referenzbildern, Warteschlange, Galerie, Fortschrittsanzeige und eine optionale lokale Ollama-Prompt-KI.

## Schnellinstallation

Lade **nur diese Datei** herunter und doppelklicke sie:

**[`INSTALL_QWEN_IMAGE_2_1.cmd`](./INSTALL_QWEN_IMAGE_2_1.cmd)**

Direkter Download:

`https://raw.githubusercontent.com/Graf-Git-Hub/Qwen_Image_2.1/main/INSTALL_QWEN_IMAGE_2_1.cmd`

Der Installer prüft automatisch, was bereits vorhanden ist, und lädt nur die benötigten Programmdateien. Python, virtuelle Umgebung, Python-Pakete und das große Qwen-Image-2.1-Modell werden nur eingerichtet bzw. heruntergeladen, wenn sie fehlen.

## Updates

Nach der Installation liegt auf dem Desktop **Qwen Image 2.1**. Beim Doppelklick auf die Startdatei wird zuerst `VERSION.txt` aus diesem Repository geprüft.

- Keine neue Version: Qwen startet sofort.
- Neue Version: Die aktuelle Installer-Datei wird automatisch heruntergeladen und das Programm aktualisiert.
- `model/`, `venv/`, `outputs/`, `hf_cache/` und lokale Ollama-Einstellungen bleiben erhalten.

Dadurch dient dieselbe Installation gleichzeitig als **Updater**.

## Installationsort

Standardmäßig:

`%LOCALAPPDATA%\\Qwen-Image-2.1-Standalone`

Eine vorhandene ältere Installation unter

`K:\\Paschy_Tools_und_Projekte\\Qwen_image2.1\\Qwen-Image-2.1-Standalone`

wird automatisch erkannt und weiterverwendet.

Für einen eigenen Zielordner kann der Installer aus einer Eingabeaufforderung so gestartet werden:

```bat
INSTALL_QWEN_IMAGE_2_1.cmd /target "D:\\AI\\Qwen-Image-2.1-Standalone"
```

## Enthalten

- Qwen Image 2.1 Text-to-Image und Image Editing
- bis zu 10 Referenzbilder
- mehrere Bildformate und Auflösungen
- Auftrags-Warteschlange, strikt nacheinander
- Matrix-Video nur beim aktiven Auftrag, Standbild bei wartenden Jobs
- Galerie mit Löschen, Ausblenden, Download und Weiterbearbeiten
- Modell- und Schritt-Fortschrittsanzeige
- automatische Modellvorladung beim Öffnen
- Rechtschreibkorrektur
- Qwen-Image-2.1-spezifische Prompt-Optimierung über ein lokales Ollama-Modell
- auswählbares Ollama-Text-/Vision-Modell

## Voraussetzungen

- Windows 10 oder 11
- NVIDIA-GPU mit aktuellem Treiber
- Internet für Erstinstallation und Updates
- ausreichend Speicherplatz für das Qwen-Image-2.1-Modell
- Ollama nur optional für die Prompt-KI

## Wichtiger Hinweis

Der eigentliche Modell-Download ist groß. Ein abgebrochener Hugging-Face-Download kann beim nächsten Installer-Lauf fortgesetzt werden.
