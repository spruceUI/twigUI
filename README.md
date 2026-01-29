# twigUI
Spruce for the GKD Pixel 2

## Installation

> [!CAUTION]
The installation process will wipe everything in your microSD card, make backups of any data you might want to preserve.

To install:
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
  
