@tool
extends Node

signal utterance_begin(utterance)

signal utterance_end(utterance)

signal utterance_stop(utterance)

var TTS

var tts

var editor_accessibility_enabled : bool = false

func _init():
	if OS.get_name() == "Server" or OS.has_feature("JavaScript"):
		return
	elif Engine.has_singleton("TTS"):
		tts = Engine.get_singleton("TTS")
	else:
		TTS = preload("godot-tts.gdns")
	if TTS and (TTS.can_instantiate() or Engine.is_editor_hint()) and RetroHubConfig.config.accessibility_screen_reader_enabled:
		tts = TTS.new()
	if tts:
		if not tts is JNISingleton:
			self.add_child(tts)
		if self.are_utterance_callbacks_supported:
			tts.connect("utterance_begin", Callable(self, "_on_utterance_begin"))
			tts.connect("utterance_end", Callable(self, "_on_utterance_end"))
			tts.connect("utterance_stop", Callable(self, "_on_utterance_stop"))
	else:
		print_debug("TTS not available!")


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS


func _get_min_rate():
	if OS.has_feature('JavaScript'):
		return 0.1
	elif Engine.has_singleton("TTS"):
		return 0.1
	elif tts != null:
		return tts.min_rate
	else:
		return 0


var min_rate : get = _get_min_rate


func _get_max_rate():
	if OS.has_feature('JavaScript'):
		return 10.0
	elif Engine.has_singleton("TTS"):
		return 10.0
	elif tts != null:
		return tts.max_rate
	else:
		return 0


var max_rate : get = _get_max_rate


func _get_normal_rate():
	if OS.has_feature('JavaScript'):
		return 1.0
	elif Engine.has_singleton("TTS"):
		return 1.0
	elif tts != null:
		return tts.normal_rate
	else:
		return 0


var normal_rate : get = _get_normal_rate

var javascript_rate = self.normal_rate


func _set_rate(rate):
	if rate < self.min_rate:
		rate = self.min_rate
	elif rate > self.max_rate:
		rate = self.max_rate
	if Engine.has_singleton("TTS") and tts:
		return tts.set_rate(rate)
	elif tts != null:
		tts.rate = rate
	elif OS.has_feature('JavaScript'):
		javascript_rate = rate


func _get_rate():
	if Engine.has_singleton("TTS") and tts:
		return tts.get_rate()
	elif tts != null:
		return tts.rate
	elif OS.has_feature('JavaScript'):
		return javascript_rate
	else:
		return 0


var rate : get = _get_rate, set = _set_rate


func _get_rate_percentage():
	return remap(self.rate, self.min_rate, self.max_rate, 0, 100)


func _set_rate_percentage(v):
	self.rate = remap(v, 0, 100, self.min_rate, self.max_rate)


var rate_percentage : get = _get_rate_percentage, set = _set_rate_percentage


func _get_normal_rate_percentage():
	return remap(self.normal_rate, self.min_rate, self.max_rate, 0, 100)


var normal_rate_percentage : get = _get_rate_percentage


func speak(text, interrupt := true):
	if not RetroHubConfig.config.accessibility_screen_reader_enabled:
		return ""
	var utterance
	if tts != null:
		utterance = tts.speak(text, interrupt)
	elif OS.has_feature('JavaScript'):
		var code = (
			"""
			let utterance = new SpeechSynthesisUtterance("%s")
			utterance.rate = %s
		"""
			% [text.replace("\n", " "), javascript_rate]
		)
		if interrupt:
			code += """
				window.speechSynthesis.cancel()
			"""
		code += "window.speechSynthesis.speak(utterance)"
		JavaScript.eval(code)
	else:
		print_debug("%s: %s" % [text, interrupt])
	return utterance

func stop():
	if tts != null:
		tts.stop()
	elif OS.has_feature('JavaScript'):
		JavaScript.eval("window.speechSynthesis.cancel()")


func _get_is_rate_supported():
	if Engine.has_singleton("TTS"):
		return true
	elif OS.has_feature('JavaScript'):
		return true
	elif tts != null:
		return tts.is_rate_supported()
	else:
		return false


var is_rate_supported : get = _get_is_rate_supported


func _get_are_utterance_callbacks_supported():
	if Engine.has_singleton("TTS"):
		return true
	elif OS.has_feature('JavaScript'):
		return false
	elif tts != null:
		return tts.are_utterance_callbacks_supported()
	else:
		return false


var are_utterance_callbacks_supported : get = _get_are_utterance_callbacks_supported


func _get_can_detect_is_speaking():
	if Engine.has_singleton("TTS"):
		return true
	elif OS.has_feature('JavaScript'):
		return true
	elif tts != null:
		return tts.can_detect_is_speaking
	return false


var can_detect_is_speaking : get = _get_can_detect_is_speaking


func _get_is_speaking():
	if Engine.has_singleton("TTS") and tts:
		return tts.is_speaking()
	elif OS.has_feature('JavaScript'):
		return JavaScript.eval("window.speechSynthesis.speaking")
	elif tts != null:
		return tts.is_speaking
	return false


var is_speaking : get = _get_is_speaking


func _get_can_detect_screen_reader():
	if Engine.has_singleton("TTS"):
		return true
	elif OS.has_feature('JavaScript'):
		return false
	elif tts != null:
		return tts.can_detect_screen_reader
	return false


var can_detect_screen_reader : get = _get_can_detect_screen_reader


func _get_has_screen_reader():
	if Engine.has_singleton("TTS") and tts:
		return tts.has_screen_reader()
	elif OS.has_feature('JavaScript'):
		return false
	elif tts != null:
		return tts.has_screen_reader
	return false


var has_screen_reader : get = _get_has_screen_reader


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


func _exit_tree():
	if not tts or not TTS:
		return
	tts.free()
