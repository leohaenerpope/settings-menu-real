@tool
extends HBoxContainer

# Default value is handled by InputMap in project settings!

@export var id := ""
@export_enum("game", "video", "audio", "controls") var type := "controls"


@export var settingName := "":
	set(val):
		settingName = val
		if label != null:
			label.text = settingName
@export_multiline var settingDescription := ""

@onready var label : RichTextLabel = $label
@onready var keyText : RichTextLabel = $key
@onready var configureButton : Button = $configure
@onready var resetButton : Button = $reset

var value : Array[InputEvent] = [] 

func _ready() -> void:
	label.text = settingName
	if InputMap.has_action(id):
		
		value = InputMap.action_get_events(id)
	visual()
	

func conf(val, save := true):
	if val is Array:
		value = val
	elif InputMap.has_action(id):
		SM.settings.processHotkey(val, id)
		value = InputMap.action_get_events(id)
	
	visual()
	
	if save:
		SM.settings.saveSetting(value, id, type)


func visual():
	if value.is_empty():
		keyText.text = "None"
	else:
		keyText.text = value[0].as_text().trim_suffix(" - Physical")
func listeningVisual():
	keyText.text = "Listening..."



func _on_configure_button_down() -> void:
	listeningVisual()
	SM.settings.settingControlInput.emit(self)


func _on_reset_button_down() -> void:
	SM.settings.settingControlReset.emit(self)
