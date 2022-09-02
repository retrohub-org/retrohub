extends Resource
class_name RetroHubTheme

## Name of the theme
export(String) var name : String

## Full description of the theme
export(String, MULTILINE) var description : String

## Icon for the theme
export(Texture) var icon : Texture

## Version of the theme
export(String) var version : String

## Upstream URL for updates/repo/contacts
export(String) var url : String

## Screenshot list for presenting
export(Array, Texture) var screenshots : Array

## Main entry scene
export(PackedScene) var entry_scene : PackedScene
