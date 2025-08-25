extends Control

# Chat UI matching the design requirements
signal chat_closed

@onready var dialogue_text = $ChatPanel/DialogueBox/DialogueText
@onready var player_input = $ChatPanel/InputBox/LineEdit
@onready var npc_talksprite = $ChatPanel/NPCTalksprite
@onready var npc_name_label = $ChatPanel/DialogueBox/NPCNameBG/NPCName
@onready var player_name_label = $ChatPanel/InputBox/PlayerNameBG/PlayerName
@onready var black_overlay = $BlackOverlay
@onready var blur_effect = $BlurEffect

var current_npc_name: String = ""
var current_npc_texture: Texture2D
var llm_endpoint: String = "http://10.0.0.251:8300/npc-chat"
var conversation_history: Array = []
var is_waiting_for_response: bool = false

# Talksprite animation system
var captain_talksprite_1: Texture2D  # NPC speaking (mouth open)
var captain_talksprite_2: Texture2D  # Player typing (mouth closed/listening)
var current_talksprite_state: String = "idle"  # "idle", "npc_speaking", "player_typing"
var talksprite_blend: float = 0.0  # 0 = fully sprite 2, 1 = fully sprite 1
var target_blend: float = 0.0

func _ready():
	visible = false
	player_input.text_submitted.connect(_on_player_input_submitted)
	player_input.text_changed.connect(_on_player_typing)
	
	# Load Captain's talksprites
	captain_talksprite_1 = load("res://sprites/Captain_Talksprite_1.png")
	captain_talksprite_2 = load("res://sprites/Captain_Talksprite_2.png")
	
	# Set player name (can be customized later)
	player_name_label.text = "Player"
	
	# Setup proper focus management
	_setup_focus_hygiene()
	
	# When panel becomes visible, refocus robustly
	visibility_changed.connect(func():
		if visible:
			_refocus_input_robust()
	)
	
	# Enable process for talksprite animation only
	set_process(true)

func _setup_focus_hygiene():
	"""Ensure only intended widgets can take focus"""
	# Input should be focusable
	player_input.focus_mode = Control.FOCUS_ALL
	player_input.editable = true
	player_input.caret_blink = true
	player_input.select_all_on_focus = false
	
	# The 25% black overlay must not intercept mouse or focus
	if black_overlay:
		black_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		black_overlay.focus_mode = Control.FOCUS_NONE
	
	if blur_effect:
		blur_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		blur_effect.focus_mode = Control.FOCUS_NONE
	
	# Make everything else unfocusable except the input
	var allow = [player_input]
	_defocus_children(self, allow)
	
	# Make sure specific controls are definitely unfocusable
	if dialogue_text:
		dialogue_text.focus_mode = Control.FOCUS_NONE
		dialogue_text.mouse_filter = Control.MOUSE_FILTER_PASS
		dialogue_text.selection_enabled = false
	
	if npc_name_label:
		npc_name_label.focus_mode = Control.FOCUS_NONE
		npc_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if player_name_label:
		player_name_label.focus_mode = Control.FOCUS_NONE
		player_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if npc_talksprite:
		npc_talksprite.focus_mode = Control.FOCUS_NONE
		npc_talksprite.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _defocus_children(node: Node, except_nodes: Array = []):
	"""Make all child controls unfocusable except specified nodes"""
	if node is Control and not except_nodes.has(node):
		node.focus_mode = Control.FOCUS_NONE
	for c in node.get_children():
		_defocus_children(c, except_nodes)

func _refocus_input_robust():
	"""Robust refocus using multiple strategies"""
	if not is_instance_valid(player_input) or not visible:
		return
	
	# Pass 1: next idle frame
	await get_tree().process_frame
	if not visible or not is_instance_valid(player_input):
		return
	
	# Release any existing focus first, then grab it
	get_viewport().gui_release_focus()
	player_input.grab_focus()
	player_input.caret_column = player_input.text.length()
	
	# Pass 2: if something stole focus during the same cycle, retry quickly
	if not player_input.has_focus():
		await get_tree().create_timer(0.02).timeout
		if visible and is_instance_valid(player_input):
			get_viewport().gui_release_focus()
			player_input.grab_focus()
			player_input.caret_column = player_input.text.length()
			print("[FOCUS] Robust refocus applied")

func open_chat(npc_name: String, _npc_texture: Texture2D = null):
	"""Open chat with an NPC"""
	print("Opening chat with NPC: ", npc_name)
	current_npc_name = npc_name
	visible = true
	
	# Update NPC name in dialogue box
	npc_name_label.text = npc_name
	
	# Set initial talksprite based on NPC
	if npc_name == "Captain":
		# Start with talksprite 1 (mouth open for greeting)
		npc_talksprite.texture = captain_talksprite_1
		current_talksprite_state = "npc_speaking"
		talksprite_blend = 1.0
		target_blend = 1.0
	else:
		# Use the NPC's actual sprite as talksprite
		_set_default_talksprite(npc_name)
	
	# Clear previous conversation
	dialogue_text.text = ""
	player_input.text = ""
	
	# Apply blur effect to background
	_apply_blur_effect(true)
	
	# Start with greeting from the NPC
	var greeting = _get_npc_greeting(npc_name)
	_display_npc_message(greeting)
	
	# After greeting, switch to listening mode
	if npc_name == "Captain":
		await get_tree().create_timer(1.5).timeout  # Wait for greeting to be read
		_set_talksprite_state("idle")
	
	# Use robust refocus after layout settles
	call_deferred("_refocus_input_robust")

func _set_default_talksprite(npc_name: String):
	"""Set appropriate talksprite based on NPC name"""
	match npc_name:
		"Captain":
			# Captain uses special talksprites
			npc_talksprite.texture = captain_talksprite_2  # Start with listening face
		"Hickory":
			# Hickory uses his own walk sprite
			var hickory_sprite = load("res://sprites/MYGAIA_Sprite_Hickory_Walk1.png")
			if hickory_sprite:
				npc_talksprite.texture = hickory_sprite
		_:
			# Default to base sprite
			var base_sprite = load("res://sprites/MYGAIA_Sprite_Base_Walk1.png")
			if base_sprite:
				npc_talksprite.texture = base_sprite

func _get_npc_greeting(npc_name: String) -> String:
	"""Get appropriate greeting based on NPC"""
	match npc_name:
		"Captain":
			return "Ahoy, matey! How're you doin' this here fine evenin'?"
		"Hickory":
			return "Well hello there, friend! Beautiful day, isn't it?"
		_:
			return "Hello! How can I help you today?"

func _apply_blur_effect(enable: bool):
	"""Apply or remove blur effect"""
	if enable:
		# The black overlay provides the 25% transparency
		black_overlay.visible = true
		# Optional: Add actual blur if supported
		blur_effect.visible = false  # Set to true if you add blur shader
	else:
		black_overlay.visible = false
		blur_effect.visible = false

func _on_player_typing(_new_text: String):
	"""Called when player is typing"""
	if current_npc_name == "Captain":
		_set_talksprite_state("player_typing")

func _on_player_input_submitted(text: String):
	"""Handle player input"""
	if text.strip_edges() == "" or is_waiting_for_response:
		return
		
	# Display player's message
	_display_player_message(text)
	
	# Clear input text but do not release focus
	player_input.text = ""
	
	# Use robust refocus after submit
	call_deferred("_refocus_input_robust")
	
	# Switch to idle/waiting state for Captain
	if current_npc_name == "Captain":
		_set_talksprite_state("idle")
	
	# Send to LLM
	_send_to_llm(text)

func _display_player_message(message: String):
	"""Display player's message in chat history"""
	# Add to dialogue text (keeping history visible)
	dialogue_text.append_text("\n\n[color=cyan]You:[/color] " + message)

func _display_npc_message(message: String):
	"""Display NPC's message"""
	if dialogue_text.text != "":
		dialogue_text.append_text("\n\n")
	dialogue_text.append_text(message)
	
	# Set Captain to speaking state
	if current_npc_name == "Captain":
		_set_talksprite_state("npc_speaking")
		# After message is displayed, return to idle
		await get_tree().create_timer(2.0).timeout
		_set_talksprite_state("idle")

func _set_talksprite_state(state: String):
	"""Set the talksprite animation state"""
	if current_npc_name != "Captain":
		return
		
	current_talksprite_state = state
	match state:
		"npc_speaking":
			target_blend = 1.0  # Sprite 1 (mouth open)
		"player_typing":
			target_blend = 0.0  # Sprite 2 (listening)
		"idle":
			target_blend = 0.0  # Sprite 2 (listening)

func _send_to_llm(message: String):
	"""Send message to LLM API"""
	is_waiting_for_response = true
	
	# Show thinking indicator with proper newlines
	dialogue_text.append_text("\n[color=gray][i](" + current_npc_name + " is thinking...)[/i][/color]\n")
	
	# Add to conversation history
	conversation_history.append({
		"role": "user",
		"content": message
	})
	
	# Prepare request
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_llm_response.bind(http_request))
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({
		"npc_data": {
			"name": current_npc_name,
			"type": "game",
			"tier": "basic",
			"id": current_npc_name.to_lower().replace(" ", "_"),
			"personality_traits": {
				"friendly": true,
				"helpful": true,
				"pirate": current_npc_name == "Captain"
			}
		},
		"player_message": message,
		"conversation_history": conversation_history,
		"response_type": "chat"
	})
	
	# Make request
	var error = http_request.request(llm_endpoint, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		is_waiting_for_response = false
		_display_npc_message("Sorry, I'm having trouble thinking right now...")
		http_request.queue_free()
		call_deferred("_refocus_input_robust")

func _on_llm_response(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, http_request: HTTPRequest):
	"""Handle LLM response"""
	http_request.queue_free()
	is_waiting_for_response = false
	
	if response_code != 200:
		dialogue_text.append_text("\n")  # Ensure new line
		_display_npc_message("I'm a bit confused right now...")
		call_deferred("_refocus_input_robust")
		return
	
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	
	if parse_result != OK:
		dialogue_text.append_text("\n")  # Ensure new line
		_display_npc_message("My thoughts are jumbled...")
		call_deferred("_refocus_input_robust")
		return
	
	var response_data = json.data
	
	if response_data.has("response"):
		var npc_response = response_data.response
		
		# Add to history
		conversation_history.append({
			"role": "assistant",
			"content": npc_response
		})
		
		# Display response on new line after thinking indicator
		dialogue_text.append_text("\n")  # Add newline after thinking message
		_display_npc_message(npc_response)
		
		# Use robust refocus after response arrives
		call_deferred("_refocus_input_robust")
	else:
		dialogue_text.append_text("\n")  # Add newline after thinking message
		_display_npc_message("...")
		call_deferred("_refocus_input_robust")

func _process(delta):
	"""Animate talksprites only - NO focus management here"""
	if visible and current_npc_name == "Captain" and captain_talksprite_1 and captain_talksprite_2:
		# Smooth transition between states
		var blend_speed = 3.0  # Adjust for transition speed
		talksprite_blend = lerp(talksprite_blend, target_blend, delta * blend_speed)
		
		# Switch texture based on blend value
		if talksprite_blend > 0.5:
			if npc_talksprite.texture != captain_talksprite_1:
				npc_talksprite.texture = captain_talksprite_1
		else:
			if npc_talksprite.texture != captain_talksprite_2:
				npc_talksprite.texture = captain_talksprite_2

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		close_chat()

func close_chat():
	"""Close the chat UI"""
	visible = false
	conversation_history.clear()
	is_waiting_for_response = false
	_apply_blur_effect(false)
	emit_signal("chat_closed")
