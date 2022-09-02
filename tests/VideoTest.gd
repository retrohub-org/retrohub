extends VideoPlayer

func _ready():
	var _stream := VideoStreamWebm.new()
	_stream.set_file("/home/ricardo/.retrohub/gamemedia/nes/video/Kirby's Adventure (USA) (Rev A).webm")
	stream = _stream
	play()
