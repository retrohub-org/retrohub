@tool
extends Node

signal utterance_begin(utterance)
signal utterance_end(utterance)
signal utterance_stop(utterance)

func _init():
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_STARTED, _on_utterance_begin)
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, _on_utterance_end)
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_CANCELED, _on_utterance_stop)

var voice : String

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	var voices := DisplayServer.tts_get_voices_for_language("en")
	if not voices.is_empty():
		voice = voices[0]

func speak(text, interrupt := true):
	print("TTS: ", text)
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return ""
	DisplayServer.tts_speak(text, voice, 50, 1.0, 1.0, 0, interrupt)

func stop():
	DisplayServer.tts_stop()

func is_speaking():
	return DisplayServer.tts_is_speaking()

func singular_or_plural(count, singular, plural):
	if count == 1:
		return singular
	else:
		return plural

func _on_utterance_begin(utterance):
	emit_signal("utterance_begin", utterance)

func _on_utterance_end(utterance):
	emit_signal("utterance_end", utterance)

func _on_utterance_stop(utterance):
	emit_signal("utterance_stop", utterance)
