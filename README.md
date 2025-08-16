Gameseprite
===========

A set of Aseprite scripts that sync sprites between GameMaker and Aseprite.

# Features
- Open a GameMaker sprite directly in Aseprite with one click.
- Script automatically creates the Aseprite animation file from the GameMaker sprite.
- Aseprite file is automatically renamed when its asset is renamed.
- Export changes from Aseprite back into the original GameMaker sprite.
- Optional console logging for successful imports/exports.

# Installation
1. Extract the archive and place its contents into your Aseprite scripts folder:
`%appdata%\Aseprite\scripts\`
1. Edit launch_aseprite.bat and set ASEPRITE_EXE to your Aseprite executable.
Default Steam install path:
`C:\Program Files (x86)\Steam\steamapps\common\Aseprite\Aseprite.exe`
1. Launch GameMaker.
1. Open Preferences (Ctrl+Shift+P).
1. Navigate to: General Settings > Paths.
1. Set Bitmap files External Editor to the launch_aseprite.bat located in your Aseprite scripts folder.

# Usage
1. In GameMaker, open a sprite asset and click Edit Sprite.
1. Aseprite will launch and either use an existing Aseprite file or create a new one.
1. To export back to GameMaker, run the export_to_GameMaker script in Aseprite.
1. When prompted by GameMaker’s file watcher, click Reload.
1. Optional: Clean the graphics before building.

# Console Logging
By default, console logging is disabled and only prints a message when an issue occurs.
To enable console logging for successful imports and exports, set `Console_log = true` in either the import or export Lua scripts.

# Contributions
Contributions are welcome. You can help improve Gameseprite in the following ways:
- Submit a pull request after making changes in a Forked repository.
- Report issues or bugs by opening an issue in the repository with steps to reproduce the problem.
- Suggest enhancements by opening an issue with details about the feature request. (Note that I may be busy with other projects)

All contributions, whether code improvements, documentation updates, or testing feedback, are greatly appreciated.
