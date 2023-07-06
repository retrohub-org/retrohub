extends TextureRect

var hint_pegi_3 := "PEGI 3\n\nThe content of games with a PEGI 3 rating is considered\nsuitable for all age groups. The game should not\ncontain any sounds or pictures that are likely to\nfrighten young children. A very mild form of violence\n(in a comical context or a childlike setting) is\nacceptable. No bad language should be heard."
var hint_pegi_7 := "PEGI 7\n\nGame content with scenes or sounds that can possibly be\nfrightening to younger children should fall in this\ncategory. Very mild forms of violence (implied, non-\ndetailed, or non-realistic violence) are acceptable for\na game with a PEGI 7 rating."
var hint_pegi_12 := "PEGI 12\n\nVideo games that show violence of a slightly more\ngraphic nature towards fantasy characters or non-\nrealistic violence towards human-like characters would\nfall in this age category. Sexual innuendo or sexual\nposturing can be present, while any bad language in\nthis category must be mild."
var hint_pegi_16 := "PEGI 16\n\nThis rating is applied once the depiction of violence\n(or sexual activity) reaches a stage that looks the\nsame as would be expected in real life. The use of bad\nlanguage in games with a PEGI 16 rating can be more\nextreme, while the use of tobacco, alcohol or illegal\ndrugs can also be present."
var hint_pegi_18 := "PEGI 18\n\nThe adult classification is applied when the level of\nviolence reaches a stage where it becomes a depiction\nof gross violence, apparently motiveless killing,\nor violence towards defenceless characters. The\nglamorisation of the use of illegal drugs and of the\nsimulation of gambling, and explicit sexual activity\nshould also fall into this age category. "

var _rating : String

func from_rating_str(rating_str: String, idx: int):
	var rating := rating_str.get_slice("/", idx)
	if not rating.is_empty():
		from_idx(int(rating), idx)

func from_idx(idx_age: int, idx_name: int):
	match idx_name:
		1:
			match idx_age:
					1:
						load_image("pegi/3")
						tooltip_text = hint_pegi_3
					2:
						load_image("pegi/7")
						tooltip_text = hint_pegi_7
					3:
						load_image("pegi/12")
						tooltip_text = hint_pegi_12
					4:
						load_image("pegi/16")
						tooltip_text = hint_pegi_16
					5:
						load_image("pegi/18")
						tooltip_text = hint_pegi_18
					0, _:
						load_image("pegi/unknown")
		2:
			match idx_age:
					1:
						load_image("cero/A")
					2:
						load_image("cero/B")
					3:
						load_image("cero/C")
					4:
						load_image("cero/D")
					5:
						load_image("cero/Z")
					0, _:
						load_image("cero/unknown")
		0, _:
			match idx_age:
					1:
						load_image("esrb/E")
					2:
						load_image("esrb/E10")
					3:
						load_image("esrb/T")
					4:
						load_image("esrb/M")
					5:
						load_image("esrb/AO")
					0, _:
						load_image("esrb/unknown")


func load_image(path: String):
	_rating = path
	texture = load("res://assets/ratings/" + path + ".png")

func tts_text(_focused: Control) -> String:
	var splits := _rating.split("/")
	var text := splits[0] + ": "
	match splits[0]:
		"esrb":
			match splits[1]:
				"E":
					text += "E for Everyone"
				"E10":
					text += "E10 for Everyone 10 plus"
				"T":
					text += "T for Teen"
				"M":
					text += "M for Mature"
				"AO":
					text += "AO for Adults Only"
				_:
					text += splits[1]
		"pegi", "cero":
			text += splits[1]
	return text
