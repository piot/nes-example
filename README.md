# NES example

Game for NES hardware and emulators completely made in 6502 assembler.

## How to compile

* [Download](https://github.com/cc65/cc65?#downloads) the `ca65` compiler and the `ld65` linker (part of the [cc65](https://cc65.github.io/) tool). Unfortunately there is no pre-built mac executable, but it is easy enough to install using brew (`brew install cc65`).

* Run the [`compile.sh`](compile.sh) (or [`compile.bat`](compile.bat) on Windows) file or use the [vscode build task](.vscode/tasks.json). It will compile the assembler source and link to a `game.nes` file (file should be around 41k).

## How to play

* Load the [`game.nes`](game.nes) file in your NES-emulator. (recommend [Pinky](https://koute.github.io/pinky-web/) for playing)

## Resources

### Emulators

#### For development (debuggers)

* [Mesen](https://www.mesen.ca/). Great debugger and event-viewer.
* [FCEUX](https://fceux.com)

#### For playing the game

* [Pinky](https://koute.github.io/pinky-web/). I prefer emulators that are web-based (webassembly), because it works on "all" platforms and require no installs.
* [TetaNES](https://lukeworks.tech/tetanes-web).

### Sprite and Tile Editors

* https://www.electricadventures.net/Pages/Category/34 (.NET with .MSI-installer)
* NES Screen Tool https://shiru.untergrund.net/software.shtml#thumb
* https://nesrocks.itch.io/naw
* https://eonarheim.github.io/NES-Sprite-Editor/
* https://github.com/0x8BitDev/MAPeD-SPReD
