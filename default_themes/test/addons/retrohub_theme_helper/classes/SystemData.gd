extends Resource
class_name RetroHubSystemData

## Short identifier name for this system. You can use this to uniquely identify this system 
var name : String

## Full descriptive system name. Use this to present the system's name for the user
var fullname : String

## Platform of this system. Multiple systems might belong to the same platform
## (for example, n64 and 64dd are different consoles but on same platform: n64)
var platform : String

## Num of games detected for thhis system
var num_games : int
