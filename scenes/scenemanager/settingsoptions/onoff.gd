@tool
extends HBoxContainer

## Also the default value
@export var value := false:
	set(val):
		value = val
		exportVisual()

@export var id := ""
@export_enum("game", "video", "audio", "controls") var type := "game"
@export var group := ""

@export var onButtonText := "On":
	set(val):
		onButtonText = val
		exportVisual()
@export var offButtonText := "Off":
	set(val):
		offButtonText = val
		exportVisual()
@export var settingName := "":
	set(val):
		settingName = val
		if label != null:
			label.text = settingName
@export_multiline var settingDescription := ""

@onready var label : RichTextLabel = $label
@onready var onButton : Button = $on
@onready var offButton : Button = $off

var saveValue := -1

func _ready() -> void:
	visual()
	label.text = settingName
	
	onButton.text = onButtonText
	
	offButton.text = offButtonText
	if group != "":
		onButton.button_down.connect(groupConf.bind(true))
		offButton.button_down.connect(groupConf.bind(false))
	else:
		onButton.button_down.connect(conf.bind(true))
		offButton.button_down.connect(conf.bind(false))
	

func conf(val := false, save := true):
	value = val
	visual()
	SM.settings.processSetting(val, id)
	if save:
		SM.settings.saveSetting(value, id, type)

func groupConf(val := false):
	if saveValue == -1:
		saveValue = 1 if val else 0
	value = val
	visual()
	SM.settings.addToGroupSet(group, val, self)

func resetSaveValue():
	saveValue = -1


func visual():
	onButton.disabled = value
	offButton.disabled = !value
	if group != "":
		if value: # could do this better
			offButton.add_theme_color_override("font_disabled_color", Color("#dfdfdf"))
			if saveValue == 1:
				onButton.add_theme_color_override("font_disabled_color", Color("#ffff00"))
				label.add_theme_color_override("default_color", Color("#ffff00"))
			else:
				onButton.add_theme_color_override("font_disabled_color", Color("#dfdfdf"))
				label.add_theme_color_override("default_color", Color("#dfdfdf"))
		else:
			onButton.add_theme_color_override("font_disabled_color", Color("#dfdfdf"))
			if saveValue == 0:
				offButton.add_theme_color_override("font_disabled_color", Color("#ffff00"))
				label.add_theme_color_override("default_color", Color("#ffff00"))
			else:
				offButton.add_theme_color_override("font_disabled_color", Color("#dfdfdf"))
				label.add_theme_color_override("default_color", Color("#dfdfdf"))
			

func exportVisual():
	if onButton != null and offButton != null:
		onButton.disabled = value
		offButton.disabled = !value
		onButton.text = onButtonText
		offButton.text = offButtonText
		

func _on_mouse_entered() -> void:
	SM.settings.settingHovered.emit(settingDescription, settingName)


func _on_mouse_exited() -> void:
	SM.settings.settingHovered.emit("", "")
