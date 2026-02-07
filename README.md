# twigUI
Spruce for the GKD Pixel 2

## Installation

> [!CAUTION]
The installation process will wipe everything in your microSD card, make backups of any data you might want to preserve.

## Automatic Installation
- [You can use the new All-in-one installer tool!](https://github.com/spruceUI/spruceOS-Installer/releases/latest)
- It downloads and flashes the latest TwigUI release and it available for Windows, Mac and Linux!
- Just be sure to select TwigUI from the available options.

<img width="683" height="456" alt="twig" src="https://github.com/user-attachments/assets/afb2c699-11f1-4d10-ac5a-91e76718fd32" />

  
### Manual Installation
- Download [balenaEtcher](https://etcher.balena.io//#download-etcher)
- Download an install image from the [releases page](https://github.com/spruceUI/twigUI/releases) and extract the .img file.
- Remove the microSD card from your handheld and insert it into a microSD card reader.
- Run balenaEtcher, click on `Flash from file` and select the previously downloaded twigUI.img file.
- Click on `Select target` and select the microSD card previously inserted.
- Click on `Flash!` and wait for the process to finish.
- Once the flashing process is done remove the microSD card from the reader, insert it into your handheld and long press the power button to power it up.

## Updating

- Turn off your handheld and remove the microSD card
- Remove the microSD card from your handheld and insert it into a microSD card reader.
- Download an update image from the [releases page](https://github.com/spruceUI/twigUI/releases) and extract it.
- Open the `ROMS` partition of your microSD card and remove everything except the following folders:
  - Roms
  - Saves
  - BIOS
  - Persistent
  - Collections
  - Themes
- Copy the extracted files from the update .7z file into the `ROMS` partition of the microSD card.
- When prompted, allow the new files to replace the existing ones.
- Once the copying process is done remove the microSD card from the reader, insert it into your handheld and long press the power button to power it up.
  
