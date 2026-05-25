extends CanvasLayer




signal settingHovered(description: String, name : String)

signal settingControlInput(node: Node)
signal settingControlReset(node: Node)






@export var gameSettings: Control
@export var videoSettings: Control
@export var audioSettings: Control
@export var controlsSettings: Control
@export var control : Control

@export var settingDescriptionHint : RichTextLabel

@export var monitorSetting : Control



var config := ConfigFile.new()
const PATH_SETTINGS_FILE := "user://settings.ini"


var settingsIds := {}
const settingsTypes : Array[String] = ["game", "video", "audio", "controls"]
const settingsGroups : Array[String] = ["video"]

# On ready, turned into like {"game": "windowmode": {"node": dropdownnodeforwindowmode, "value": 0}}

var defaultSettings := {}
var groupSetSettings := {}

var open : bool

var isRemapping := false
var remapNode : Node


func toggleOpenSettings():
	if open:
		closeSettings()
	else:
		openSettings()

func openSettings() -> void:
	set_process_input(true)
	show()
	open = true

func closeSettings() -> void:
	set_process_input(false)
	hide()
	settingDescriptionHint.text = ""
	open = false



func _ready() -> void:
	set_process_input(false)
	showSettingsType(gameSettings)
	settingHovered.connect(updateSettingDescriptionHint)
	settingControlInput.connect(newControlInput)
	settingControlReset.connect(resetControlInput)
	settingDescriptionHint.text = ""

	monitorsUpdate()
	

	# hideSettings()
	var count1 := 0
	for settingParent in [gameSettings, videoSettings, audioSettings, controlsSettings]:
		var settingType : String = settingsTypes[count1]
		settingsIds[settingType] = []
		for child in settingParent.get_children():
			var settingId = child.get("id")
			if settingId != null:
				settingsIds[settingType].append(settingId)
		count1 += 1
	

	if !FileAccess.file_exists(PATH_SETTINGS_FILE):
		config.save(PATH_SETTINGS_FILE)
	else:
		config.load(PATH_SETTINGS_FILE)
	
	# Create dictionary for all saved values
	var savedSettings := {}
	for settingType in settingsIds:
		for setting in settingsIds[settingType]:
			var savedValue = config.get_value(settingType, setting, {})
			if savedValue is not Dictionary:
				savedSettings[setting] = savedValue
	# Now use that dic (pause) to conf all potential settings
	count1 = 0 # used for tracking game setting type for default settings
	for settingParent in [gameSettings, videoSettings, audioSettings, controlsSettings]:
		defaultSettings[settingsTypes[count1]] = {}
		for child in settingParent.get_children():
			# Initialize setting part in default settings

			var settingId = child.get("id")
			if settingId != null and child.has_method("conf"):
				# Save default settings
				defaultSettings[settingsTypes[count1]][child] = child.value
				
				if savedSettings.has(settingId):
					child.conf(savedSettings[settingId], false)
				else:
					child.conf(child.value, false)
		count1 += 1


	

func updateSettingDescriptionHint(to: String, settingName: String):
	if to == "":
		settingDescriptionHint.text = ""
	else:
		settingDescriptionHint.text = settingName + ": " + to




func saveSetting(val, id := "", type := ""):
	if id == "" or type == "":
		print("Setting not configured properly: saveSetting in settingsmanager.gd")
		return
	config.set_value(type, id, val)
	config.save(PATH_SETTINGS_FILE)

func processSetting(val, id := ""):
	
	if id == "":
		print("Setting not configured properly: processSetting in settingsmanager.gd")
		return
	if val is bool:
		match id:
	
			#GAME

			#VIDEO GRAPHICS

			#VIDEO SCREEN
			"vsync":
				DisplayServer.window_set_vsync_mode(
					DisplayServer.VSYNC_ENABLED if val else DisplayServer.VSYNC_DISABLED
				)
			"windowstretch":
				get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP if val else Window.CONTENT_SCALE_ASPECT_IGNORE

			#AUDIO
			"tinnitus":
				var masterBus = AudioServer.get_bus_index("Master")
				AudioServer.set_bus_effect_enabled(masterBus, 0, val)
			# CONTROLS
			_:
				print("Setting not configured properly: processSetting in settingsmanager.gd with setting id ", id)
				return
	elif val is float or val is int:
		match id:
			#GAME

			#VIDEO GRAPHICS
			"3dresolution":
				get_window().scaling_3d_scale = val
				

			#VIDEO SCREEN


			#AUDIO
			"mastervol":
				setVolSetting("Master", val)
			"musicvol":
				setVolSetting("Music", val)
			"sfxvol":
				setVolSetting("SFX", val)


			# CONTROLS
			_:
				print("Setting not configured properly: processSetting in settingsmanager.gd with setting id ", id)
				return
	elif val is String:
		match id:
			#GAME

			#VIDEO GRAPHICS
			"windowmode":
				changeWindowMode(val)
			"aspectratio":
				changeAspectRatio(val)
			"currentmonitor":
				changeDisplayMonitor(val)

			#VIDEO SCREEN


			#AUDIO

			# CONTROLS
			_:
				print("Setting not configured properly: processSetting in settingsmanager.gd with setting id ", id)
				return

# Sets inputmap action array with new InputEvent given a slot (0) by default- slot used for if controller ever added
func processHotkey(val: InputEvent, id, slot := 0):
	var curEvents = InputMap.action_get_events(id)
	
	while curEvents.size() <= slot:
		curEvents.append(null)
		
	curEvents[slot] = val
	
	InputMap.action_erase_events(id)
	for event in curEvents:
		if event != null:
			InputMap.action_add_event(id, event)


func newControlInput(node: Node):
	remapNode = node
	isRemapping = true

func resetControlInput(node: Node):
	if !defaultSettings.has("controls") or !defaultSettings["controls"].has(node):
		return
	node.conf(defaultSettings["controls"][node])





func resetSettings(type: String):
	if !defaultSettings.has(type):
		return
	for node in defaultSettings[type]:
		node.conf(defaultSettings[type][node])
		await get_tree().process_frame

	# For any screen scaling issues
	if type == "video":
		safeUpdateWindow()
	
	# If group settings has type (like video), forget it, fuck that
	if groupSetSettings.has(type):
		groupSetSettings.erase(type)

func applyGroup(group: String):
	if !groupSetSettings.has(group):
		return
	for node in groupSetSettings[group]:
		node.resetSaveValue()
		node.conf(groupSetSettings[group][node])
		
		await get_tree().process_frame
	
	# For any screen scaling issues
	if group == "video":
		safeUpdateWindow()

	groupSetSettings.erase(group)
	

func addToGroupSet(group : String, val, node: Node):
	if !groupSetSettings.has(group):
		groupSetSettings[group] = {}
	
	# Check if val is now actually the saved value
	var savedValue = config.get_value(node.type, node.id, {})
	if savedValue is not Dictionary and val == savedValue:
		if groupSetSettings[group].has(node):
			groupSetSettings[group].erase(node)
		return
	
	groupSetSettings[group][node] = val
	








# This process is turned on/off when settings is opened/closed btw
func _input(event: InputEvent) -> void:
	monitorsUpdate()

	if ( # DashNothing, along with a lot of the other config stuff
		isRemapping and
		(
			event is InputEventKey or (event is InputEventMouseButton && event.pressed)
		) 
	):
		if event is InputEventMouseButton and event.double_click:
			event.double_click = false
		remapNode.conf(event)
		remapNode = null
		isRemapping = false

		control.accept_event()
	
	









func setVolSetting(type: String, to: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(type), linear_to_db(to))


func monitorsUpdate():
	var curScreenCount := DisplayServer.get_screen_count()
	var curMonitor := DisplayServer.window_get_current_screen()
	if curScreenCount == SM.monitorCount and curMonitor == SM.monitorCurrent:
		return
	SM.monitorCount = curScreenCount
	SM.monitorCurrent = curMonitor
	var dataArr : Array[DropdownData] = []
	for i in range(curScreenCount):
		var screenSize := DisplayServer.screen_get_size(i)
		var screenHz := DisplayServer.screen_get_refresh_rate(i)
		var newData := DropdownData.new()
		newData.id = str(i)
		newData.name = "Display " + str(i+1) + " - " + str(screenSize.x) + "x" + str(screenSize.y) + " " + str(int(screenHz)) + "Hz"
		dataArr.append(newData)
	monitorSetting.values = dataArr
	monitorSetting.value = curMonitor
	monitorSetting.visual()


## Checks for valid *to point* for display monitor, then switches using DisplayServer
func changeDisplayMonitor(newMonitor := ""):
	var to := int(newMonitor)
	var screenCount := DisplayServer.get_screen_count()
	if screenCount <= 0 or to >= screenCount or to < 0:
		return
	DisplayServer.window_set_current_screen(to)


func changeWindowMode(value : String):
	match value:
		"fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		"borderless":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"windowed":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)


# Due to a weird borderless fullscreen bug when changing displays when the scale of the windows aren't the same
func safeUpdateWindow():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)



func changeAspectRatio(value: String):
	var splitString := value.split("x")
	if splitString.size() != 2:
		return
	var newResolution := Vector2i(int(splitString[0]), int(splitString[1]))
	get_window().content_scale_size = newResolution









# config.set_value("keybind", "click", "mouse_1")
		# config.set_value("keybind", "left", "A")
		# config.set_value("keybind", "right", "D")
		# config.set_value("keybind", "up", "W")
		# config.set_value("keybind", "down", "S")
		# config.set_value("keybind", "jump", "Space")
		# config.set_value("keybind", "sprint", "Left Shift")
		# config.set_value("keybind", "crouch", "Left Control")
		# config.set_value("keybind", "tab", "Tab")
		# config.set_value("keybind", "rightclick", "mouse_2")


func showSettingsType(type : Node):
	for thing in [gameSettings, videoSettings, audioSettings, controlsSettings]:
		thing.hide()
	type.show()
	


func _on_gamebutton_button_down() -> void:
	showSettingsType(gameSettings)

func _on_videobutton_button_down() -> void:
	showSettingsType(videoSettings)


func _on_audiobutton_button_down() -> void:
	showSettingsType(audioSettings)


func _on_controlsbutton_button_down() -> void:
	showSettingsType(controlsSettings)
