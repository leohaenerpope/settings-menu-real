@tool
extends HBoxContainer

## Also the default value
@export var functionName := ""

@export var specificNode : Node
@export var args := []

@export var isEnabled := true:
	set(val):
		isEnabled = val
		visual()

@export_multiline var buttonText := "On":
	set(val):
		buttonText = val
		visual()

@export_multiline var description := ""

@onready var button : Button = $button

func _ready() -> void:
	visual()
	button.button_down.connect(buttonPress)


func visual():
	if is_inside_tree() and button != null:
		button.disabled = !isEnabled
		button.text = buttonText
	
func buttonPress():
	if specificNode != null and specificNode.has_method(functionName):
		specificNode.callv(functionName, args)
		

func _on_mouse_entered() -> void:
	SM.settings.settingHovered.emit(description, buttonText)


func _on_mouse_exited() -> void:
	SM.settings.settingHovered.emit("", "")
