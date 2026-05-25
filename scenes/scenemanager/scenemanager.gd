extends Node


@export var settings : Node



var canPause := true



enum windowStretches {letterbox, fill}
var windowStretch := windowStretches.fill

var monitorCount := -1
var monitorCurrent := -1


func _ready() -> void:
	settings.closeSettings()

func _input(event: InputEvent) -> void:
	if SM.canPause and event.is_action_pressed("escape"):
		settings.toggleOpenSettings()
