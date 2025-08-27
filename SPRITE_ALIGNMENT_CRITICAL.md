# 🚨 CRITICAL SPRITE ALIGNMENT DOCUMENTATION 🚨
**THIS IS THE CORRECT FORMULA - DO NOT CHANGE!**

## MYGAIA Sprite Specifications
- **Sprite Dimensions**: 600x800 pixels (WIDTH x HEIGHT)
- **Height**: 800 pixels
- **Width**: 600 pixels

## THE CORRECT FORMULA

### For Sprite3D nodes:
```gdscript
pixel_size = 0.01  # MUST BE 0.01, NOT 0.001!
sprite.position.y = 4.0  # MUST BE 4.0, NOT 0.4!
```

### Mathematical Formula:
```
sprite_offset_y = (sprite_height * pixel_size) / 2.0
sprite_offset_y = (800 * 0.01) / 2.0 = 4.0
```

## CORRECT VALUES FOR MYGAIA SPRITES

| Property | CORRECT Value | WRONG Value | 
|----------|--------------|-------------|
| pixel_size | **0.01** | ~~0.001~~ |
| Y position | **4.0** | ~~0.4~~ |
| Billboard | 1 (enabled) | 0 (disabled) |
| Texture Filter | 0 (nearest) | any other |

## Example Implementation

### Player Setup (player_park.gd):
```gdscript
sprite.pixel_size = 0.01  # Standard pixel size for MYGAIA sprites
sprite.position.y = 4.0   # Properly aligned to ground
sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
```

### NPC Setup (in .tscn files):
```
[node name="Sprite3D" type="Sprite3D" parent="NPCs/Captain"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 4, 0)
billboard = 1
texture_filter = 0
texture = ExtResource("13")
pixel_size = 0.01
```

## WORKING REFERENCE PROJECTS
- **TEST2**: Uses AnimatedSprite3D with Y=4.0
- **core_02_single_platform_test**: Confirmed Y offset = 4.0

## WHY THIS FORMULA WORKS
The sprites are 800 pixels tall. With pixel_size of 0.01, each pixel becomes 0.01 world units.
- Total sprite height in world = 800 * 0.01 = 8 units
- To center vertically from ground = 8 / 2 = 4 units
- Therefore Y position = 4.0

## COMMON MISTAKES TO AVOID
❌ Using pixel_size = 0.001 (makes sprites 10x smaller than intended)
❌ Using Y = 0.4 (buries sprites in the ground)
❌ Using pixel_size = 0.02 (makes sprites too large)
❌ Using Y = 1.0 (arbitrary value not based on formula)

## VERIFICATION CHECKLIST
- [ ] All MYGAIA sprites are 600x800 pixels
- [ ] All Sprite3D nodes use pixel_size = 0.01
- [ ] All Sprite3D nodes have Y position = 4.0
- [ ] Billboard is enabled (= 1)
- [ ] Texture filter is nearest (= 0)

---
**REMEMBER**: The formula was tested and proven over DAYS. DO NOT CHANGE IT!