extends Node

# Simple test script to verify chat is working
# Run this to simulate the chat interaction

func _ready():
	print("Testing Chat System...")
	
	# Simulate what happens when player presses E near NPC
	var chat_ui = preload("res://scenes/ChatUI.tscn").instantiate()
	get_tree().root.add_child(chat_ui)
	
	# Open chat with Captain
	chat_ui.open_chat("Captain", null)
	
	print("Chat UI opened for Captain")
	
	# Test sending a message
	await get_tree().create_timer(2.0).timeout
	print("Simulating player message...")
	
	# Clean up
	await get_tree().create_timer(5.0).timeout
	chat_ui.queue_free()
	print("Test complete")