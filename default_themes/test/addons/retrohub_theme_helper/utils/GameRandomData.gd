extends Node

# https://www.fantasynamegenerators.com/video-game-names.php
var titles_data = [
	"Age of Strategy",
	"Assassins of Tactics",
	"Astromania",
	"Awakening and Legend",
	"Backrain",
	"Basketballtime",
	"Battle System",
	"Battlefield Command",
	"Battlemind",
	"Betrayal and Monsters",
	"Bloodcrest",
	"Bordercraft",
	"Bulletrage",
	"Bullrider Super Challenge",
	"Cargo and Cities",
	"Castlefront",
	"Castleplan",
	"Castleside",
	"Celtic Ascension",
	"Chronoside",
	"Cityways",
	"Clans of Mercenaries",
	"Cloudside",
	"Colonies of Magic",
	"Combattale",
	"Corruption and Conquest",
	"Creatures and Castle",
	"Crossbow Sim",
	"Crown of Honor",
	"Dawn and Builders",
	"Dragonborne",
	"Dragonreign",
	"Dragonspace",
	"Dreadflight",
	"Dreadmore",
	"Dreadway",
	"Endorstorm",
	"Everchase",
	"Everstorm",
	"Failures of Games",
	"Fantasy Sports League",
	"Fantasy Vengeance",
	"Fear and Stars",
	"Fightingpro",
	"Full On Demon",
	"Garden and World",
	"Ghostside",
	"Gladiators and Armies",
	"Guardians and Armies",
	"Gunspeed",
	"Heavenspace",
	"Heavenstorm",
	"Heroic Force",
	"Hockey and Adrenaline",
	"Hockeypro",
	"Hope and Dreams",
	"Hunting Castle",
	"Huntpro",
	"Iron Unrest",
	"Jetcommand",
	"Jocks of Face Offs",
	"Karate Games",
	"Kingdoms of Warriors",
	"Knight Edge",
	"Knights of Hope",
	"Land of Anarchy",
	"Legends and Day",
	"Lightlight",
	"Lords of Legends",
	"Machines of Tragedy",
	"Master League Super Challenge",
	"Mechabase",
	"Medals and Champs",
	"Monster Assault",
	"Monsters of Sorrow",
	"Mortal Power",
	"Patrol Operation",
	"Peril and Wrath",
	"Phantomrise",
	"Phantoms of Sins",
	"Plan of Campaigns",
	"Revolution Expansion",
	"Rising Stars of Signatures",
	"Roads and Spaceflight",
	"Rugbysim",
	"Rugbytime",
	"Settlers and Legions",
	"Siegemania",
	"Skulls and Armor",
	"Space Core",
	"Spacehero",
	"Spellfighter",
	"Spirits of Myths",
	"SportX",
	"Strengthstar",
	"Tanksim",
	"Tennislife",
	"Tragedy and Flames",
	"Trainers of Signatures",
	"Village Elite",
	"Werewolves of Universes",
	"Witchmaster",
	"Witchrise",
	"World Class and Football"
]

# https://www.lipsum.com/feed/html
var description_data = [
	"Lorem ipsum dolor sit amet, consectetur adipiscing elit. In blandit mi in consequat auctor. Fusce quis mi elementum, rhoncus massa id, aliquam ante. Nullam in augue at urna venenatis scelerisque. Etiam auctor odio ligula, at interdum lectus aliquam fringilla. Phasellus lacinia, odio et faucibus semper, neque tellus ornare nunc, in pretium nulla sem vel nisl. Aliquam maximus cursus dapibus. Nunc ac ipsum egestas, auctor massa id, consectetur tortor. Nam suscipit euismod sem, non suscipit massa aliquam ornare.",
	"Pellentesque eu leo arcu. Praesent mi sem, volutpat vitae arcu vel, ultrices tincidunt metus. Vestibulum ligula augue, fringilla ac magna vehicula, ornare pharetra ex. In ullamcorper urna a massa euismod, sit amet egestas felis accumsan. Curabitur vitae elementum augue. Donec quis facilisis turpis. Cras quis viverra metus. Sed finibus finibus convallis. Duis efficitur tellus quis turpis ultrices placerat.",
	"Vivamus ante orci, sollicitudin quis mollis non, dictum in nibh. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec condimentum ipsum eget dapibus molestie. Etiam eget auctor arcu. Nullam viverra risus vel sapien imperdiet, eu tempus arcu gravida. Duis lobortis fringilla nisl, id rhoncus massa fermentum nec. Morbi ac varius mi. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas.",
	"Etiam commodo ligula eget pellentesque semper. Pellentesque eu massa at erat finibus ultricies. Nunc dapibus gravida porta. Ut lobortis magna odio, a feugiat mi tincidunt vitae. Aenean a hendrerit nisl. Aliquam efficitur interdum nibh gravida blandit. Ut aliquet ullamcorper molestie. Aenean vel suscipit ex, sed fringilla sapien. Etiam mollis nunc quis feugiat ultrices. Donec hendrerit sodales bibendum. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Etiam diam mauris, interdum a semper quis, vehicula ac nulla. In quis posuere metus.",
	"Pellentesque ligula lacus, auctor eu diam eu, imperdiet sodales felis. Praesent tincidunt nisi magna. Quisque in pharetra ligula. Donec feugiat diam odio, at sagittis tellus tempor ut. Integer ac interdum magna, vel suscipit libero. Ut placerat massa magna, id imperdiet justo venenatis in. Ut porttitor metus a venenatis tincidunt. Mauris euismod nec metus ac pharetra. Vivamus at est et ante placerat maximus placerat commodo felis."
]

var genre_data = [
	"Action",
	"Adventure",
	"Shooter",
	"Simulation",
	"Sports",
	"Strategy",
	"Racing",
	"Puzzle",
	"Platform",
]

var company_data = [
	"Nao Intendo",
	"CEGO",
	"Xoni",
	"Maricosoft",
	"Triangle Onix",
	"The Red Button",
	"Stonestar",
	"Firezard",
	"Cutty Dog",
	"Jangom",
	"In-vision",
	"Freaks of Nature",
	"Take-Sue",
	"Gameattic",
	"Ritaa",
]

var extension_data = [
	".ifl",
	".aol",
	".of",
	".9z",
	".map",
	".ufk",
	".ppo",
	".r22",
	".asd",
	".afv",
	".wlf",
	".wad",
	".mck",
	".oom"
]

func random_title() -> String:
	return titles_data[randi() % titles_data.size()]

func random_description() -> String:
	return description_data[randi() % description_data.size()]

func random_genre() -> String:
	return genre_data[randi() % genre_data.size()]

func random_company() -> String:
	return company_data[randi() % company_data.size()]

func random_extension() -> String:
	return extension_data[randi() % extension_data.size()]

func random_date() -> String:
	var day = randi() % 31 + 1
	var month = randi() % 12 + 1
	var year = 1960 + randi() % 100
	var hour = randi() % 24
	var minute = randi() % 60
	var second = randi() % 60
	
	# Handle invalid days
	if month == 2:
		day = int(min(day, 28))
	elif month == 4 or month == 6 or month == 9 or month == 11:
		day = int(min(day, 30))
	
	return "%4d%02d%02dT%02d%02d%02d" % [year, month, day, hour, minute, second]

func random_age_rating() -> ImageTexture:
	return ImageTexture.new()
