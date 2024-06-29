# NES example

Game for NES hardware and emulators completely made in 6502 assembler.

## How to compile

* [Download](https://github.com/cc65/cc65?#downloads) `ca65` compiler and `ld65` linker (part of the [cc65](https://cc65.github.io/) tool).
	Unfortunately there is no mac-version, but it is easy enough to install using brew (`brew install cc65`).
* Run the `compile.sh` file. It will compile and link to a `game.nes` file (file should be around 41k).

## How to play

* Load the `game.nes` file in your NES-emulator. (recommend [Pinky](https://koute.github.io/pinky-web/) for playing)

## Resources

### Emulators

#### With good debuggers for development

* [Mesen](https://www.mesen.ca/)
* [FCEUX](https://fceux.com)

#### For just playing the game

* [Pinky](https://koute.github.io/pinky-web/). I prefer emulators that are web-based (webassembly), because it works on "all" platforms and require no installs.

### Sprite and Tile Editors

* https://www.electricadventures.net/Pages/Category/34 (.NET with .MSI-installer)
* NES Screen Tool https://shiru.untergrund.net/software.shtml#thumb
* https://jimmarshall35.github.io/
* https://nesrocks.itch.io/naw
