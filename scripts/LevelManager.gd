extends Node
# MYGAIA Level Manager - Manages all level transitions

var levels = {}
var current_level = ""

func _ready():
    scan_for_levels()
    print("Level Manager initialized with ", levels.size(), " levels")

func scan_for_levels():
    """Find all MYGAIA level scenes"""
    var dir = DirAccess.open("res://scenes/")
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if file_name.ends_with(".tscn"):
                var level_name = file_name.replace(".tscn", "")
                levels[level_name] = "res://scenes/" + file_name
                print("Found level: ", level_name)
            file_name = dir.get_next()

func change_level(level_name: String):
    if level_name in levels:
        print("Loading level: ", level_name)
        current_level = level_name
        get_tree().change_scene_to_file(levels[level_name])
    else:
        push_error("Level not found: " + level_name)

func get_next_level():
    var level_keys = levels.keys()
    var current_index = level_keys.find(current_level)
    if current_index >= 0 and current_index < level_keys.size() - 1:
        return level_keys[current_index + 1]
    return null
