# Paper Mario AI - LLM-Powered RPG

![Godot](https://img.shields.io/badge/Godot-4.4-blue?logo=godot-engine&logoColor=white)
![GDScript](https://img.shields.io/badge/GDScript-100%25-purple)
![License](https://img.shields.io/badge/License-MIT-green)
![AI Powered](https://img.shields.io/badge/AI-LLM%20Integrated-orange)

> A modern Paper Mario-style RPG featuring **real-time AI-powered NPC conversations** using Large Language Models. Built with Godot 4.4, this project showcases the intersection of traditional game development with cutting-edge AI integration.

## Overview

This project demonstrates how to seamlessly integrate LLM (Large Language Model) technology into a classic RPG framework. NPCs don't just respond with pre-scripted dialogue - they use AI to generate contextual, dynamic conversations based on their personality traits, creating a truly immersive gaming experience.

### Why This Project Matters

- **AI Integration in Gaming**: Demonstrates production-ready LLM integration in game engines
- **Modern Architecture**: RESTful API design with async HTTP requests
- **Paper Mario Aesthetic**: Classic 2D sprites in 3D world with billboard rendering
- **Extensible Design**: Modular NPC system that can scale to dozens of characters

---

## Key Features

### AI-Powered NPCs
- **Dynamic Conversations**: NPCs powered by Hermes-3-Llama-3.1-8B model for natural dialogue
- **Personality System**: Each NPC has unique personality traits that influence responses
- **Contextual Memory**: Conversation history maintained for coherent interactions
- **Emotional States**: Talksprite animations reflect conversation mood and content

### Game Mechanics
- **Paper Mario-Style Camera**: 45-degree elevated perspective with smooth player tracking
- **WASD Movement**: Fluid 8-directional character control
- **Sprite Billboarding**: 2D characters always face camera in 3D space
- **Interaction System**: Proximity-based NPC interactions with 'E' key

### Visual & UI
- **Modern Chat Interface**: Fullscreen dialogue system with character portraits
- **Talksprite Animations**: Dynamic facial expressions based on dialogue content
- **Focus Overlay**: 25% black overlay for conversation immersion
- **Shadow System**: Dynamic shadow quads beneath billboarded sprites

---

## How the AI Works

### Architecture Overview

```
Player Input → ChatUI.gd → HTTP Request → LLM Server (10.0.0.251:8300)
                                              ↓
                                         vLLM Engine (Port 8100)
                                              ↓
                                    Hermes-3-Llama-3.1-8B Model
                                              ↓
Response ← JSON Parsing ← HTTP Response ← API Endpoint
```

### LLM Integration Details

**Endpoint**: `http://10.0.0.251:8300/npc-chat`

**Request Format**:
```json
{
  "npc_data": {
    "name": "Captain",
    "type": "game",
    "tier": "basic",
    "id": "captain",
    "personality_traits": {
      "friendly": true,
      "helpful": true,
      "pirate": true
    }
  },
  "player_message": "Hello!",
  "conversation_history": [...],
  "response_type": "chat"
}
```

**Key Design Decisions**:
- **Player-Centric Communication**: Only the player sends requests to the LLM
- **NPCs ARE the LLM**: NPCs represent the AI's responses, not separate entities
- **Async Processing**: HTTPRequest nodes prevent game freezing during API calls
- **Fallback Responses**: Graceful degradation if LLM unavailable

### Conversation Flow

1. **Player approaches NPC** → Proximity detection triggered
2. **Press 'E'** → ChatUI opens with greeting
3. **Player types message** → Message sent to LLM with NPC personality context
4. **LLM processes** → "Thinking..." indicator shown
5. **Response received** → NPC responds with contextual dialogue
6. **Talksprite updates** → Facial expression matches response tone
7. **Conversation continues** → History maintained for context

---

## Technical Features

### Paper Mario-Style Graphics
- **2D in 3D**: Sprites rendered as billboards in 3D world
- **Camera System**: Fixed 45-degree angle following player
- **Shadow Rendering**: Semi-transparent shadow quads beneath characters
- **Sprite Alignment**: Proper floor positioning with gravity simulation

### Chat UI System
- **Focus Management**: Robust input focus using `gui_release_focus()`
- **Rich Text**: BBCode formatting for colored player/NPC names
- **Portrait System**: Large character talksprites (328x355px)
- **Smooth Transitions**: Deferred loading prevents instantiation errors

### NPC Personality System
Each NPC has configurable traits that influence their AI responses:

**Captain** (Pirate-themed):
```gdscript
"personality_traits": {
  "friendly": true,
  "helpful": true,
  "pirate": true  // Influences vocabulary and tone
}
```

**Hickory** (Woodland character):
```gdscript
"personality_traits": {
  "friendly": true,
  "helpful": true,
  "pirate": false
}
```

### Advanced Features
- **Patrol AI**: NPCs follow 8-waypoint patrol paths
- **Walking Animations**: Frame-based sprite animation system
- **Boundary System**: Invisible walls prevent falling off map
- **Logger System**: Autoloaded GodotLogger and ErrorLogger for debugging

---

## Project Structure

```
godot-test2-paper-mario/
├── scenes/
│   ├── park_level.tscn           # Main game scene
│   └── ChatUI.tscn               # Chat interface layout
├── scripts/
│   ├── PlayerController.gd       # WASD movement + interaction
│   ├── ChatUI.gd                 # LLM chat system (370 lines)
│   ├── NPCMovement.gd            # Base patrol AI
│   ├── NPCController_Captain.gd  # Captain-specific behavior
│   ├── NPCController_Hickory.gd  # Hickory-specific behavior
│   ├── SimpleMarioCamera.gd      # Paper Mario camera
│   ├── InvisibleBoundaries.gd    # Map boundaries
│   ├── ShadowCaster.gd           # Dynamic shadows
│   ├── GodotLogger.gd            # Logging system (Autoload)
│   └── ErrorLogger.gd            # Error tracking (Autoload)
├── sprites/
│   ├── Captain_Talksprite_1.png  # Captain speaking
│   ├── Captain_Talksprite_2.png  # Captain listening
│   ├── Hickory_Talksprite_1.png  # Hickory speaking
│   ├── Hickory_Talksprite_2.png  # Hickory listening
│   └── MYGAIA_Sprite_*.png       # Player & NPC sprites
├── levels/                       # Additional level files
├── shaders/                      # Custom shaders
└── project.godot                 # Godot 4.4 project config
```

---

## Setup & Installation

### Requirements
- **Godot Engine**: 4.4 or later
- **LLM Server**: Access to LLM endpoint at `10.0.0.251:8300`
- **vLLM Engine**: (Optional) For local setup - Hermes-3-Llama-3.1-8B model

### Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/edb616321/godot-test2-paper-mario.git
   cd godot-test2-paper-mario
   ```

2. **Open in Godot**:
   - Launch Godot 4.4+
   - Select "Import" and choose `project.godot`
   - Wait for asset import to complete

3. **Configure LLM Endpoint** (Optional):
   - Edit `scripts/ChatUI.gd` line 16
   - Update `llm_endpoint` to your server URL

4. **Run the game**:
   - Press F5 or click "Run Project"
   - Main scene: `scenes/park_level.tscn`

### Controls

| Key | Action |
|-----|--------|
| **W/A/S/D** | Move character |
| **E** | Interact with nearby NPCs |
| **ESC** | Close chat window |
| **Q/R** | Rotate camera (if enabled) |

---

## Gameplay Features

### NPCs

#### Captain
- **Location**: (-5, 0, -5)
- **Personality**: Pirate-themed, friendly, helpful
- **Talksprites**: Animated mouth movements (2 states)
- **Patrol**: 8-waypoint route at 0.8 speed
- **Greeting**: "Ahoy, matey! How're you doin' this here fine evenin'?"

#### Hickory
- **Location**: (5, 0, -5)
- **Personality**: Woodland character, friendly, helpful
- **Talksprites**: Expressive facial states (2 states)
- **Patrol**: 8-waypoint route at 0.8 speed
- **Greeting**: "Well hello there, friend! Beautiful day, isn't it?"

### Conversation Examples

**Player**: "Tell me about yourself"
**Captain** (AI-generated): "Arr, I be Captain Redbeard, guardian of these here lands! Been sailin' the seven seas for nigh on thirty years before settlin' down in MYGAIA. What brings ye to these parts, matey?"

**Player**: "What's the weather like today?"
**Hickory** (AI-generated): "Oh, it's absolutely lovely! The sun is shining through the trees, and there's a gentle breeze rustling the leaves. Perfect day for a walk through the forest, wouldn't you say?"

---

## Development Roadmap

### Completed Features
- [x] Paper Mario-style camera system
- [x] LLM integration with conversation history
- [x] Dynamic talksprite animations
- [x] NPC patrol AI with waypoints
- [x] Chat UI with focus management
- [x] Personality-based AI responses
- [x] Shadow rendering system
- [x] Boundary collision detection

### Planned Features
- [ ] Multiple levels with transitions
- [ ] Inventory system
- [ ] Quest/dialogue tree integration
- [ ] Voice synthesis for NPC responses
- [ ] Multiplayer chat with shared AI NPCs
- [ ] NPC emotion/mood persistence
- [ ] Weather system integration
- [ ] Mobile platform support

---

## Screenshots

### In-Game Chat System
*Screenshot placeholder: Chat UI with Captain talksprite and dialogue*

**To add**: Capture screenshot of chat conversation with Captain showing:
- Fullscreen chat interface
- Large character portrait on right
- Dialogue text with NPC name
- 25% black overlay on game world

### Paper Mario Camera View
*Screenshot placeholder: 45-degree elevated camera perspective*

**To add**: Capture screenshot showing:
- Player character sprite
- NPCs patrolling
- Shadow quads beneath characters
- Isometric-style view angle

### NPC Interaction
*Screenshot placeholder: Player near NPC with interaction prompt*

**To add**: Capture screenshot demonstrating:
- Player approaching NPC
- Proximity detection visual
- Multiple NPCs visible in world

---

## Technical Deep Dives

### Talksprite Animation System

The game uses a content-aware sprite selection system:

```gdscript
func _choose_sprite_for_message(message: String):
    var msg_lower = message.to_lower()
    var use_speaking_sprite = false

    # Check for excited/loud content
    if "!" in message or "?" in message:
        use_speaking_sprite = true
    elif "ahoy" in msg_lower or "arrr" in msg_lower:
        use_speaking_sprite = true

    # Set appropriate sprite
    if use_speaking_sprite:
        npc_talksprite.texture = captain_talksprite_1
    else:
        npc_talksprite.texture = captain_talksprite_2
```

### Focus Management

Critical for seamless chat UX:

```gdscript
func _refocus_input_robust():
    await get_tree().process_frame
    get_viewport().gui_release_focus()
    player_input.grab_focus()
    player_input.caret_column = player_input.text.length()
```

### Async LLM Requests

Non-blocking API calls:

```gdscript
func _send_to_llm(message: String):
    is_waiting_for_response = true
    var http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.request_completed.connect(_on_llm_response)
    http_request.request(llm_endpoint, headers, HTTPClient.METHOD_POST, body)
```

---

## Known Issues

- **Shadow Rendering**: Shadows use simple quads due to billboard sprite limitations
- **LLM Dependency**: Requires active connection to LLM endpoint
- **Performance**: Large conversation histories may impact response time
- **Camera Rotation**: Q/R rotation keys currently disabled in main branch

---

## Contributing

Contributions welcome! Areas of interest:

- **AI Enhancements**: Improved personality systems, emotion tracking
- **Visual Polish**: Particle effects, lighting systems
- **Gameplay**: Quest systems, combat mechanics
- **Optimization**: Conversation history pruning, response caching

### Development Setup

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Test in Godot 4.4+
4. Commit changes: `git commit -m "Add amazing feature"`
5. Push to branch: `git push origin feature/amazing-feature`
6. Open Pull Request

---

## Credits

### Development
- **Game Engine**: Godot 4.4
- **LLM Model**: Hermes-3-Llama-3.1-8B (via vLLM)
- **Art Assets**: MYGAIA sprite collection
- **Camera System**: Paper Mario-inspired implementation

### Technologies
- **GDScript**: Primary language (100%)
- **vLLM**: LLM inference engine
- **HTTPRequest**: Async networking
- **Billboard Shaders**: Sprite rendering

---

## License

This project is open source and available under the MIT License.

---

## Contact & Links

- **Repository**: [github.com/edb616321/godot-test2-paper-mario](https://github.com/edb616321/godot-test2-paper-mario)
- **Issues**: [GitHub Issues](https://github.com/edb616321/godot-test2-paper-mario/issues)
- **Discussions**: [GitHub Discussions](https://github.com/edb616321/godot-test2-paper-mario/discussions)

---

## Acknowledgments

Special thanks to:
- The Godot community for excellent documentation
- vLLM project for efficient LLM inference
- Paper Mario series for gameplay inspiration
- The open-source AI community

---

*Built with Godot Engine and powered by AI*
