@tool
extends HBoxContainer

## Also the default value
@export var value := 100.0:
	set(val):
		value = val
		exportVisual()

@export var sliderMin := 0.0
@export var sliderMax := 100.0
@export var sliderStep := 1.0
@export var percent := false

@export var id := ""
@export_enum("game", "video", "audio", "controls") var type := "game"
@export var group := ""

@export var settingName := "":
	set(val):
		settingName = val
		exportVisual()
@export_multiline var settingDescription := ""

@onready var label : RichTextLabel = $label
@onready var slider : HSlider = $slidercontainer/hslider
@onready var sliderText : RichTextLabel = $slidercontainer/slidertext

var sliderTextAddition := ""

var saveValue := -999.0


func _ready() -> void:
	if percent:
		sliderTextAddition = "%"
	if group == "":
		slider.value_changed.connect(conf)
	else:
		slider.value_changed.connect(groupConf)
	slider.min_value = sliderMin # Might keep these for now, may have some use for changing the min/max/step for whatever reason.
	slider.max_value = sliderMax
	slider.step = sliderStep
	label.text = settingName

	visual()


	

func conf(val := 100.0, save := true):
	if val < sliderMin:
		val = sliderMin
	elif val > sliderMax:
		val = sliderMax
	value = val
	visual()
	SM.settings.processSetting(val/100 if percent else val, id)
	if save:
		SM.settings.saveSetting(value, id, type)

func groupConf(val := 100.0):
	if saveValue == -999.0:
		saveValue = value
	if val < sliderMin:
		val = sliderMin
	elif val > sliderMax:
		val = sliderMax
	value = val
	visual()
	SM.settings.addToGroupSet(group, val/100 if percent else val, self)

func resetSaveValue():
	saveValue = -999.0



func exportVisual():
	if is_inside_tree():
		if label != null:
			label.text = settingName
		if slider != null and sliderText != null:
			slider.min_value = sliderMin # Might keep these for now, may have some use for changing the min/max/step for whatever reason.
			slider.max_value = sliderMax
			slider.step = sliderStep
			slider.value = value
			sliderText.text = str(value) + sliderTextAddition

func visual():
	sliderText.text = str(value) + sliderTextAddition
	if group != "":
		sliderText.add_theme_color_override("default_color", Color("#ffff00") if value != saveValue else Color("#dfdfdf"))
		label.add_theme_color_override("default_color", Color("#ffff00") if value != saveValue else Color("#dfdfdf"))
		
		


func _on_mouse_entered() -> void:
	SM.settings.settingHovered.emit(settingDescription, settingName)

func _on_mouse_exited() -> void:
	SM.settings.settingHovered.emit("", "")