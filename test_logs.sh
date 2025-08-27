#!/bin/bash

# Test script to run Godot and check log generation

echo "=== GODOT LOG TEST ==="
echo "Starting Godot Template1 in headless mode to generate logs..."
echo ""

# Run Godot in headless mode briefly to generate logs
timeout 5 godot --headless --path /mnt/data1/GodotProjects/Template1 2>&1 | head -50

echo ""
echo "=== CHECKING FOR GENERATED LOGS ==="
echo ""

# Check if log was created
if [ -f "/mnt/data1/GodotProjects/Template1/godot_runtime.log" ]; then
    echo "✅ Runtime log created successfully!"
    echo ""
    echo "Log contents:"
    echo "-------------"
    cat /mnt/data1/GodotProjects/Template1/godot_runtime.log
else
    echo "⚠️ No runtime log found. Checking user directory..."
    find ~/.local/share/godot -name "*.log" 2>/dev/null | head -5
fi

echo ""
echo "=== DONE ==="
echo "You can now read logs with: ./read_godot_logs.sh"