extends SceneTree

func _initialize():
	print("Testing NPC movement...")
	
	# Wait for scene to load
	await process_frame
	await process_frame
	
	# Get NPCs
	var npcs = get_nodes_in_group("npcs")
	print("Found ", npcs.size(), " NPCs")
	
	for npc in npcs:
		if npc.has_method("get_npc_name"):
			print("NPC: ", npc.get_npc_name(), " at position ", npc.global_position)
	
	# Wait to see if they start moving
	for i in 10:
		await get_tree().create_timer(1.0).timeout
		print("Time: ", i+1, " seconds")
		for npc in npcs:
			if npc.has_method("get_npc_name"):
				print("  ", npc.get_npc_name(), ": pos=", npc.global_position, " velocity=", npc.velocity if npc.has("velocity") else "N/A")
	
	quit()