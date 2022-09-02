extends Resource
class_name RetroHubGameMediaData

### This class hold various pieces of raw media for the requested game
### You can use helper calls on RetroHubMedia to help build objects, or
### create custom objects

### Only use fields with non-null values

## Game logo as a 2D image with alpha values
var logo : ImageTexture = null

## In-game screenshot as a 2D image
var screenshot : ImageTexture = null

## In-game title screen, as a 2D image
var title_screen : ImageTexture = null

## Video clip of gameplay
var video : VideoStream = null

## 3D render of the game's box, as a 2D image with alpha values
var box_render : ImageTexture = null

## Full raw box texture to display on 3D models, as a 2D texture
## (use `RetroHubMedia.render3DBox` to get a corresponding 3D case with texture applied)
var box_texture : ImageTexture = null

## Game manual, WIP
var manual = null

## Game's support render, such as it's disc or cartridge,
## as a 2D image with alpha values.
var support_render : ImageTexture = null

## Game's support texture, such as it's disc image or cartridge picture,
## as a 2D texture to be used with 3D models
## (use `RetroHubMedia.render3DSupport` to get a corresponding 3D support with texture applied)
var support_texture : ImageTexture = null
