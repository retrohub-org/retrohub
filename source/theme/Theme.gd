extends Resource
class_name RetroHubTheme

## Identifier for this theme. Should be a short but unique identifiable name
var id : String

## Name of the theme
var name : String

## Full description of the theme
var description : String

## Icon for the theme
var icon : Texture

## Version of the theme
var version : String

## Upstream URL for updates/repo/contacts
var url : String

## Screenshot list for presenting
var screenshots : Array

## Main entry scene
var entry_scene : Node

## Custom configuration scene
var config_scene : Node

## Custom app theme
var app_theme : Theme