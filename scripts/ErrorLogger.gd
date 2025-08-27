extends Node

# Error Logger - Captures and reports Godot runtime errors
# Add this as autoload to capture all errors

var error_log = []
var max_errors = 100

func _ready():
	print("=== ERROR LOGGER INITIALIZED ===")
	
	# Connect to tree's error signals if available
	# Note: files_dropped is on Window, not SceneTree
	if get_window():
		get_window().connect("files_dropped", _on_files_dropped)
	
	# Start periodic error check
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.timeout.connect(_check_for_errors)
	timer.autostart = true
	add_child(timer)
	
	# Check for script errors on ready
	_check_initial_errors()

func _check_initial_errors():
	"""Check for any initialization errors"""
	print("\n=== CHECKING FOR ERRORS ===")
	
	# Check if all expected nodes exist
	var root = get_tree().root
	var park_level = root.get_node_or_null("ParkLevel")
	
	if not park_level:
		log_error("ParkLevel node not found!")
		return
		
	# Check player setup
	var player = park_level.get_node_or_null("Player")
	if player:
		print("✓ Player found at position: ", player.position)
		var sprite = player.get_node_or_null("Sprite3D")
		if sprite:
			print("  - Sprite Y position: ", sprite.position.y)
			print("  - Pixel size: ", sprite.pixel_size)
			print("  - Expected Y for 800px sprite: ", (800 * sprite.pixel_size) / 2.0)
		else:
			log_error("Player Sprite3D not found!")
	else:
		log_error("Player node not found!")
		
	# Check NPCs
	var npcs = park_level.get_node_or_null("NPCs")
	if npcs:
		print("✓ NPCs node found")
		for npc in npcs.get_children():
			print("  - NPC: ", npc.name, " at ", npc.position)
			var sprite = npc.get_node_or_null("Sprite3D")
			if sprite:
				print("    - Sprite Y: ", sprite.position.y, " Pixel size: ", sprite.pixel_size)
			else:
				log_error("NPC " + npc.name + " missing Sprite3D!")
	else:
		log_error("NPCs node not found!")
		
	# Check ChatUI
	var chat_ui = park_level.get_node_or_null("ChatUI")
	if chat_ui:
		print("✓ ChatUI found")
	else:
		log_error("ChatUI not found!")
		
	# Print all logged errors
	if error_log.size() > 0:
		print("\n=== ERRORS FOUND ===")
		for err in error_log:
			print("ERROR: ", err)
	else:
		print("\n✓ No errors detected during initialization")

func log_error(message: String):
	"""Log an error message"""
	var timestamp = Time.get_datetime_string_from_system()
	var error_entry = timestamp + " - " + message
	error_log.append(error_entry)
	
	if error_log.size() > max_errors:
		error_log.pop_front()
	
	push_error(message)  # Also push to Godot's error system
	print("ERROR: ", message)

func _check_for_errors():
	"""Periodic check for any runtime errors"""
	# This could check various game state issues
	pass

func _on_files_dropped(files):
	"""Handle file drop events"""
	# Use the files parameter to avoid unused warning
	if files and files.size() > 0:
		print("FILES: Files dropped: " + str(files.size()))
	pass

func get_error_report() -> String:
	"""Get a formatted error report"""
	if error_log.size() == 0:
		return "No errors logged"
	
	var report = "=== ERROR REPORT ===\n"
	report += "Total errors: " + str(error_log.size()) + "\n\n"
	
	for err in error_log:
		report += err + "\n"
	
	return report

func clear_errors():
	"""Clear the error log"""
	error_log.clear()
	print("Error log cleared")
