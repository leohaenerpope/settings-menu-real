@tool
extends HBoxContainer

## Also the default value
@export var value := 0:
	set(val):
		value = val
		exportVisual()

@export var values : Array[DropdownData] = []:
	set(val):
		values = val
		exportVisual()

@export var id := ""
@export_enum("game", "video", "audio", "controls") var type := "game"
@export var group := ""

@export var settingName := "":
	set(val):
		settingName = val
		exportVisual()
@export_multiline var settingDescription := ""

@onready var label : RichTextLabel = $label
@onready var dropdown : OptionButton = $dropdownbutton


var saveValue := -1


func _ready() -> void:
	if values.size() < 1:
		return
	if value < values.size() and value >= 0:
		visual()
	label.text = settingName

	if group != "":
		dropdown.item_selected.connect(groupConf)
	else:
		dropdown.item_selected.connect(conf)
	

func conf(newVal, save := true):
	if values.size() < 1:
		return
	var val : String = newVal if newVal is String else values[newVal].id
	var valueFound := false
	for i in range(values.size()):
		if values[i].id == val:
			value = i
			valueFound = true
			break
	if !valueFound:
		value = 0

	visual()
	SM.settings.processSetting(val, id)
	if save or !valueFound:
		SM.settings.saveSetting(values[value].id, id, type)

func groupConf(newVal):
	if values.size() < 1:
		return
	var val : String = newVal if newVal is String else values[newVal].id
	var valueFound := false
	
	if saveValue == -1:
		saveValue = value

	for i in range(values.size()):
		if values[i].id == val:
			value = i
			valueFound = true
			break
	if !valueFound:
		value = 0
	visual(value != saveValue)
	SM.settings.addToGroupSet(group, val, self)

func resetSaveValue():
	saveValue = -1


func visual(notApplied := false):
	dropdown.clear()
	for item in values:
		if item != null:
			dropdown.add_item(item.name)
	dropdown.select(value)
	if group != "":
		dropdown.add_theme_color_override("font_color", Color("#ffff00") if notApplied else Color("#dfdfdf"))
		dropdown.add_theme_color_override("font_hover_color", Color("#ffff00") if notApplied else Color("#dfdfdf"))
		dropdown.add_theme_color_override("font_hover_pressed_color", Color("#ffff00") if notApplied else Color("#dfdfdf"))
		dropdown.add_theme_color_override("font_pressed_color", Color("#ffff00") if notApplied else Color("#dfdfdf"))
		label.add_theme_color_override("default_color", Color("#ffff00") if notApplied else Color("#dfdfdf"))

func exportVisual():
	if is_inside_tree():
		if label != null:
			label.text = settingName
		if dropdown != null:
			dropdown.clear()
			for item in values:
				if item != null:
					dropdown.add_item(item.name)
			dropdown.select(value)

func _on_mouse_entered() -> void:
	SM.settings.settingHovered.emit(settingDescription, settingName)


func _on_mouse_exited() -> void:
	SM.settings.settingHovered.emit("", "")