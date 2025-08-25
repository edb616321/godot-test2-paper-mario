extends Node

# Debug script to verify character alignment
func _ready():
    print("=== CHARACTER ALIGNMENT DEBUG ===")
    
    # Find all CharacterBody3D nodes
    var characters = []
    _find_characters(get_tree().root, characters)
    
    for character in characters:
        var name = character.name
        var pos = character.global_position
        print(f"{name} position: Y={pos.y:.2f}")
        
        # Check for AnimatedSprite3D children
        for child in character.get_children():
            if child is AnimatedSprite3D:
                var sprite_pos = child.position
                print(f"  - Sprite offset: Y={sprite_pos.y:.2f}")
                print(f"  - Pixel size: {child.pixel_size}")
                
                # Calculate expected offset for 800px sprite
                var expected_offset = 4.0  # (800 * 0.01) / 2
                if abs(sprite_pos.y - expected_offset) > 0.5:
                    print(f"  ⚠️ WARNING: Sprite may be misaligned! Expected Y≈{expected_offset}")
    
    print("=================================")

func _find_characters(node, characters):
    if node is CharacterBody3D:
        characters.append(node)
    for child in node.get_children():
        _find_characters(child, characters)
