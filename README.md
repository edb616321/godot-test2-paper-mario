# TEST2 - Paper Mario Style Game

A Godot 4.3 project featuring Paper Mario-style gameplay with 2D sprites in a 3D world.

## Features

### Core Gameplay
- **Paper Mario Camera**: 45-degree elevated view with player positioned lower in frame
- **WASD Movement**: Smooth 8-directional character movement
- **Sprite Billboarding**: All character sprites face the camera
- **Invisible Boundaries**: Prevents falling off the map edges

### Chat System
- **Interactive NPCs**: Press 'E' near NPCs to initiate conversation
- **Modern Chat UI**: 
  - Large character talksprites on the right side
  - Character names displayed at top of dialogue boxes
  - 25% black overlay for focus during conversations
  - Smooth talksprite transitions between speaking/listening states
- **LLM Integration**: NPCs powered by AI for dynamic conversations
- **Robust Focus Management**: Input field maintains cursor focus throughout conversation

### Visual Features
- **Dynamic Shadows**: Semi-transparent shadow quads under characters
- **Proper Sprite Alignment**: Characters properly positioned on floor
- **Captain Talksprites**: Animated transitions between two talksprite states

## Controls

- **WASD/Arrow Keys**: Move character
- **E**: Interact with nearby NPCs
- **ESC**: Close chat window

## NPCs

### Captain
- Pirate-themed character with custom talksprites
- Located at position (-5, 0, -5)
- Features animated mouth movements during conversation

### Hickory
- Friendly woodland character
- Located at position (5, 0, -5)
- Uses standard sprite for conversations

## Technical Details

### Project Structure
```
TEST2/
├── scenes/
│   ├── mygaia_single_floor.tscn (Main scene)
│   └── ChatUI.tscn (Chat interface)
├── scripts/
│   ├── PlayerController.gd (Movement and interaction)
│   ├── ChatUI.gd (Chat system with focus management)
│   ├── NPCController_Captain.gd (Captain NPC behavior)
│   ├── NPCController_Hickory.gd (Hickory NPC behavior)
│   ├── SimpleMarioCamera.gd (Camera following system)
│   ├── InvisibleBoundaries.gd (Map boundary walls)
│   └── ShadowCaster.gd (Character shadows)
└── sprites/
    ├── MYGAIA_Sprite_*.png (Character sprites)
    └── Captain_Talksprite_*.png (Captain chat sprites)
```

### Recent Updates (2025-08-25)

1. **Camera System**: Adjusted to elevated Paper Mario perspective
2. **Chat UI Redesign**: Complete overhaul matching modern game design
3. **Focus Fix**: Implemented robust input focus management using gui_release_focus()
4. **Sprite Billboarding**: Changed from Y-billboard to full billboard mode
5. **Shadow System**: Added fake shadow quads for 2D sprites
6. **Boundary System**: Invisible walls prevent falling off map

## Requirements

- Godot 4.3 or later
- Network access to 10.0.0.251:8300 for NPC chat API

## Setup

1. Open project in Godot 4.3+
2. Ensure main scene is set to `scenes/mygaia_single_floor.tscn`
3. Run the project
4. Use WASD to move and E to chat with NPCs

## Known Issues

- Shadows are rendered as simple quads (engine limitation with billboarded sprites)
- Chat requires active connection to LLM endpoint

## Credits

- Character sprites: MYGAIA sprite collection
- Chat system: Custom implementation with LLM integration
- Camera system: Paper Mario inspired implementation