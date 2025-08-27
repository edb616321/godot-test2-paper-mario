#!/bin/bash

# Script to read Godot logs from Template1 project
# This finds and displays the Godot log files

echo "=== GODOT LOG READER FOR TEMPLATE1 ==="
echo "======================================="
echo ""

# Check for project runtime log (easiest to access)
PROJECT_LOG="/mnt/data1/GodotProjects/Template1/godot_runtime.log"
if [ -f "$PROJECT_LOG" ]; then
    echo "📋 PROJECT RUNTIME LOG:"
    echo "------------------------"
    tail -50 "$PROJECT_LOG"
    echo ""
    echo "Full log at: $PROJECT_LOG"
else
    echo "⚠️ Project runtime log not found yet. Run the game first."
fi

echo ""
echo "======================================="

# Find Godot user data directory logs
GODOT_USER_DIR="$HOME/.local/share/godot/app_userdata/Template1"
if [ -d "$GODOT_USER_DIR" ]; then
    echo "📁 GODOT USER DATA LOGS:"
    echo "------------------------"
    
    # Console log
    if [ -f "$GODOT_USER_DIR/godot_console.log" ]; then
        echo "✓ Console log found"
        echo "Last 20 lines:"
        tail -20 "$GODOT_USER_DIR/godot_console.log"
        echo ""
    fi
    
    # Error log
    if [ -f "$GODOT_USER_DIR/godot_errors.log" ]; then
        echo "❌ ERROR LOG:"
        cat "$GODOT_USER_DIR/godot_errors.log"
        echo ""
    fi
else
    # Try alternative location
    ALT_GODOT_DIR="$HOME/.config/godot/app_userdata/Template1"
    if [ -d "$ALT_GODOT_DIR" ]; then
        echo "Found logs at alternate location: $ALT_GODOT_DIR"
        ls -la "$ALT_GODOT_DIR"/*.log 2>/dev/null
    fi
fi

echo ""
echo "======================================="
echo "💡 TIP: Logs are updated in real-time while Godot runs"
echo "💡 Use 'tail -f $PROJECT_LOG' to watch live"