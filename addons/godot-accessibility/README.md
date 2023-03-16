# Godot Accessibility Plugin

_Warning: Still in early development. Only use if you're willing and able to roll up your sleeves and help._

This plugin implements a screen reader for user interfaces created with the [Godot game engine](https://godotengine.org). The goal is to enable the creation of [audio games](https://en.wikipedia.org/wiki/Audio_game) with Godot, as well as to add accessibility functionality to user interfaces and to encourage the creation of accessible games. 3.2 is the minimum supported version, though most functionality should work on 3.1 as well.

Note that only 64-bit versions of Godot are supported for now. If you need 32-bit support, you'll need to rebuild [godot-tts](https://github.com/lightsoutgames/godot-tts). Patches to automate 32-bit builds are welcome, but I'm not a Windows person and haven't been able to manage it.

## Why?

As a blind gamer and software developer, I've long had an interest in developing games. But while I can assemble and integrate bunches of individual libraries to achieve the functionality I need, game engines already ship battle-tested components for almost every feature I could possibly want, all of which are well-integrated and nicely documented. Accessibility is a glaring exception.

If so many developers are flocking to engines like Unity, it must be that they derive some advantage from the platform. But because the Unity development environment isn't accessible, I as a blind developer have no way of knowing whether that style of development would work for me. This addon is my way of exploring those possibilities and, with any luck, of making compelling games of my own.

Anecdotally, I've learned that building games with Godot is not only possible, but is becoming very fast as I refine my workflow. My process probably looks nothing like that of most other Godot users. I use the editor to set up scenes, edit properties, etc. Then I drop to a shell prompt, edit the _.tscn_ files by hand, edit scripts in VSCode, then run the game from the shell. The editor is more of an exploratory interface for the work I mostly do by hand, and has been invaluable at helping me discover property and signal values without pouring through pages of documentation for multiple classes. But even though this approach is a bit more obtuse than just picking a scripting language, what I get from Godot is a set of components that can perform just about any game-related task I need. I also can export games to just about any platform--Windows, Linux, MacOS, Android, HTML 5, iOS, and UWP for the Xbox One.

## Installation

There is an [accessible starter project](https://github.com/lightsoutgames/godot-accessible-starter) that does most of this for you, and sets up a basic project with an in-game screen reader and editor accessibility. But here are the steps from an empty Godot project:

1. Place this repository in a directory named _addons/godot-accessibility_ inside your project. This plugins root directory should be reachable at the Godot path _res://addons/godot-accessibility_.

2. Download the [latest release of the Godot TTS addon](https://github.com/lightsoutgames/godot-tts/releases) and place its files in _addons/godot-tts_. When complete, you should have paths like _addons/godot-tts/TTS.gd_.

3. Enable the Godot Accessibility plugin from the editor UI. Or, if you have a _project.godot_ file, ensure that you have a section like:

    ```ini
    [editor_plugins]
    
    enabled=[ "godot-accessibility" ]
    ```

4. Optionally, configure the plugin by creating a file named _.godot-accessibility-editor-settings.ini_ in your project directory. This file is entirely optional, and defaults are shown below:

    ```ini
    [global]
    editor_accessibility__enabled = true ; Set to false if you'd like this plugin's accessibility nodes but don't need editor speech, good for sighted collaborators.
    [speech]
    rate = 50 ; range is 0 to 100.
    ```

    This file shouldn't be checked into version control, so add it to your ignore patterns.

5. Optionally, set up Android TTS. After performing [Android export setup](https://docs.godotengine.org/en/3.2/getting_started/workflow/export/exporting_for_android.html) and downloading templates, click _Project -> Install Android Build Template_. Copy, or link, _addons/godot-tts/android_ to _android/godot-tts_.

6. Perform the below Windows-only procedure if you would prefer that editor speech be done with your screen reader. Note that these steps aren't necessary if all you want is speech in exports.

7. Launch your project in the editor by running `godot -e` in the top-level directory. Or, to launch the game normally, simply run `godot`.

Windows-only: If you need speech in the editor and would prefer to use your screen reader, please perform the following additional steps:

 * Place godot.exe in the working directory of your game.
 * Copy all DLLs from addons\godot-tts\target\release to the game's working directory.
 * Use the godot.exe executable in your game directory to edit and run the game.

Without these changes, you'll only get SAPI speech in the editor. Exporting games correctly places dependent DLLs alongside the game executable, so these steps aren't needed if you only want accessibility during the game itself.

## What is provided?

### `ScreenReader` node

Add the `ScreenReader` node to any `SceneTree` to make any UI accessible. Many of the most common UI controls are supported.

`ScreenReader` also customizes keyboard handling to account for the fact that Godot's is somewhat lacking. It attempts to set an initial focus whenever a new scene is initialized so keyboard focus works more often than not.

Further, `ScreenReader` automatically intercepts all touchscreen interactions to emulate basic explore-by-touch and swipe navigation as found on Android and iOS. Currently, left and right swipes emulate _Tab_ and _Shift-tab_. The touchscreen can also be explored, and a double-tap anywhere triggers the last item to gain focus.

### Editor accessibility

Since the Godot editor is itself a Godot UI, the plugin optionally injects a `ScreenReader` node into the editor. The interface isn't accessible enough to create games entirely from within the editor, but games can still be created by using Godot's editor to get an idea for how files should be structured, then editing them by hand in a more accessible IDE. In particular, VSCode with its [Godot plugin](https://github.com/godotengine/godot-vscode-plugin/releases) is helpful. Please install a GitHub release, since the version in the marketplace doesn't seem to work with Godot 3.2.

## Gotchas

Here are some issues that I know about now, along with recommended workarounds where possible:

### Tab and Shift-tab stop working.

If focus ever lands outside of a UI widget, Tab and Shift-tab will stop working because there is no focused control from which to find a new focus candidate. This used to happen lots in the editor, but seems to have gone away. Game UIs should be explicit about setting an initial focus when transitioning between screens.

### File navigation is confusing.

Yeah it is, and I'm not immediately sure of a fix. This is where I need a sighted person to help me understand the layout of some of these dialogs, along with the behavior of the controls they contain. They're usable but confusing. Here is my workflow for opening a scene. Say I have _scenes/Player/Player.tscn_ in my project and want to open it:

1. Press Ctrl-o.
2. Tab until I hear "Path".
3. Tab once more. I'm now on an editable text field that speaks something like "res://scenes/Main".
4. Update this to be "res://scenes/Player" (I.e. the directory containing _Player.tscn_. Press _Enter_.
5. Tab until I hear "File". Tab once more and I'm on the filename.
6. Update this to read "Player.tscn" and press _Enter_.

The Player scene should now be loaded, and tabbing bunches of times should land you on the node tree. Speaking of:

### I'm going to break a finger tab/shift-tabbing everywhere.

I know. This interface was designed for mouse users. I can probably add a hotkey for jumping between major UI elements, but as a blind developer, I don't know the boundaries of these major UI areas. Help with this would be greatly appreciated.

One promising area of exploration is Godot 3.2's ability to disable editor features. Audio-only games might get away with disabling 3-D and other views, thus at least minimizing tab fatigue. But that feature crashed when I last attempted it (3.2 alphas) and I haven't tried again.

You can also arrow around the UI, though arrow navigation isn't quite as deterministic as tab/shift-tab navigation.

### How do I bind an action to a key?

This is a fun one. First, the controls to do this need to be accessed in a non-standard way. Then, you've got a non-discoverable dialog. But here's the process:

1. From the top menu, click Project.
2. In the submenu, click Project Settings.
3. Tab until you reach the tab list.
4. Arrow right to Input Map.
5. Here you can either create a new bindable action by typing a name into the text field, or tab to the tree and select an existing action to bind a new key/controller button to.
6. When in the tree, you'll need to access controls for the individual items. Godot is a bit odd in how it associates controls with tree items. Sometimes they're context menus. Others, as here, they're a horizontal row of buttons in one of the tree row cells. To access these, select an action, arrow right twice, and use Home/End to switch between individual buttons on each row. There should be an _Add_ button of some sort. Select it and press _Space_ or _enter_.
7. You then land on a popup menu allowing you to bind a key, joystick button, etc. Arrow to _Key_ and press _Enter_.
8. If you select the option to add a key to an action, focus lands in a dialog. You won't get any speech for this. I think you're supposed to do this by pressing the desired key, then clicking a Close button. Naturally, for us this would bind everything to _Space_ or _enter_. Instead, the addon closes the dialog automatically after five seconds, so press your desired key or combination and wait. Pressing a second key or combination clears the first, so if you make a mistake, just press the correct key combination. You won't get speech feedback until the dialog closes.

A better workflow for this is welcome, but it took so long to figure out how to *reach* this dialog that, when I finally did, I was just damned happy to get *anything* working. :)

Note that _right-arrow_ only navigates between cells in a row for expanded tree items. Fortunately, I think most rows with controls are fully-expanded anyway, and others use more traditional context menus.

### How do I right-click?

There's no keyboard-equivalent for this, but fortunately the addon has your back. Use the _Application_ key as you normally would. Note that this key performs a right-click. I can't guarantee that will always open a context menu, but it does just that for the scene tree and other nodes with documented context menus.

Note that right-clicks are currently a bit broken. I have to manually position the mouse and inject the correct events, but I seem to be picking the wrong coordinates. Sometimes it works, others it doesn't. Help welcome.

### Some controls don't work.

Working on it. Help welcome, since sometimes I can't figure out how a control is intended to work. Sometimes keyboard support isn't implemented at all. Others, I'm not hooking the correct events. This is one huge puzzle.
