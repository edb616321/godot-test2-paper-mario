# TEST2 Project Updates - August 22, 2025

## Changes Applied:

### 1. ✅ Characters Face Camera/Front
- **Player**: Always faces forward (removed directional flipping)
- **NPCs**: Always face forward during patrol and idle
- All `sprite.flip_h = false` to ensure front-facing

### 2. ✅ Camera Angled Down
- Changed from 45° to 60° downward angle
- Position adjusted from (0, 15, 10) to (0, 12, 6)
- Provides better top-down perspective while showing character details

### 3. ✅ Idle States Implemented
**Player:**
- Stops animation when not moving
- Shows frame 0 (Idle1/Walk1) when stationary
- Properly transitions between idle and walking

**NPCs:**
- Start in idle state on game load
- Show idle (frame 0) at each patrol waypoint
- Proper idle during wait periods between patrol points

### 4. ✅ Starting State
- All characters start in idle state (frame 0)
- Using Idle1/Walk1 PNG as the idle frame
- No animation playing on game start

## Technical Details:

### Files Modified:
1. `scripts/PlayerController.gd`
   - Added idle state logic
   - Removed directional sprite flipping
   - Start with sprite.stop() and frame 0

2. `scripts/NPCMovement.gd`
   - NPCs start in waiting/idle state
   - Show frame 0 when not moving
   - Always face forward (no flipping)

3. `scripts/SimpleMarioCamera.gd`
   - Increased angle to 60 degrees
   - Adjusted position for better view

## How It Works:
- Frame 0 of "walk" animation serves as idle sprite
- `sprite.stop()` pauses animation on frame 0
- `sprite.play()` resumes walking animation
- All sprites maintain `flip_h = false` for front-facing

## Testing:
1. Start game - all characters should be idle facing forward
2. Move player with WASD - walking animation plays
3. Stop moving - player returns to idle
4. Watch NPCs - they idle at waypoints, walk between them
5. Camera provides angled-down view of the action