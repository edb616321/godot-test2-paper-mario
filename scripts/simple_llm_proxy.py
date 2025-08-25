#!/usr/bin/env python3
"""
Simple LLM proxy for MYGAIA chat system
CRITICAL: Only the PLAYER talks to the LLM
NPCs ARE the LLM responses - they don't make separate calls
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import requests
import json

app = Flask(__name__)
CORS(app)

# Configuration - update this to match your actual LLM server
ACTUAL_LLM_ENDPOINT = "http://localhost:8000/v1/chat/completions"  # vLLM server

@app.route('/v1/chat/completions', methods=['POST'])
def chat_proxy():
    """Proxy chat requests to the actual LLM"""
    try:
        data = request.json
        
        # Log the request (for debugging)
        print(f"Player message to NPC {data.get('messages', [{}])[-1].get('content', '')}")
        
        # For testing without a real LLM, return a mock response
        if not is_llm_available():
            return jsonify({
                "choices": [{
                    "message": {
                        "role": "assistant",
                        "content": get_mock_response(data)
                    }
                }]
            })
        
        # Forward to actual LLM
        response = requests.post(
            ACTUAL_LLM_ENDPOINT,
            json=data,
            headers={'Content-Type': 'application/json'},
            timeout=30
        )
        
        return jsonify(response.json())
        
    except Exception as e:
        print(f"Error in LLM proxy: {e}")
        return jsonify({
            "choices": [{
                "message": {
                    "role": "assistant",
                    "content": "I'm having trouble understanding right now..."
                }
            }]
        }), 200

def is_llm_available():
    """Check if the actual LLM server is running"""
    try:
        response = requests.get(ACTUAL_LLM_ENDPOINT.replace('/chat/completions', '/models'), timeout=2)
        return response.status_code == 200
    except:
        return False

def get_mock_response(data):
    """Generate mock responses for testing"""
    messages = data.get('messages', [])
    if not messages:
        return "Hello there, adventurer!"
    
    last_message = messages[-1].get('content', '').lower()
    
    # Simple mock responses based on keywords
    if 'hello' in last_message or 'hi' in last_message:
        return "Hello! It's a beautiful day in MYGAIA, isn't it?"
    elif 'help' in last_message:
        return "I'm here to help! You can explore the world, talk to NPCs, and have adventures!"
    elif 'quest' in last_message:
        return "Ah, looking for adventure? The village elder might have something for you."
    elif 'name' in last_message:
        return "I'm Captain, one of the guardians of this realm."
    elif 'bye' in last_message or 'goodbye' in last_message:
        return "Farewell, traveler! May your journey be safe!"
    else:
        return "That's interesting! Tell me more about your adventures."

if __name__ == '__main__':
    print("Starting MYGAIA LLM Proxy on port 8001...")
    print("CRITICAL: Remember - NPCs ARE the LLM, they don't make separate calls!")
    app.run(host='0.0.0.0', port=8001, debug=True)