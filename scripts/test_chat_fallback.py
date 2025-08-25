#!/usr/bin/env python3
"""
Test fallback responses for MYGAIA chat
This provides basic responses while we fix the LLM integration
"""

import random

CAPTAIN_RESPONSES = [
    "Ahoy there, adventurer! Welcome to MYGAIA!",
    "The seas be calm today, perfect for adventure.",
    "I've been guarding these lands for many years.",
    "Have you explored the tower yet? It's quite a sight!",
    "Stay alert, there be mysteries in these lands."
]

HICKORY_RESPONSES = [
    "Well hello there, friend!",
    "Beautiful day for a stroll, isn't it?",
    "I've been walking these paths for as long as I can remember.",
    "The village is peaceful, just how I like it.",
    "Have you met the Captain? Quite a character!"
]

def get_fallback_response(npc_name, player_message):
    """Get a fallback response for testing"""
    
    npc_name_lower = npc_name.lower()
    
    if "captain" in npc_name_lower:
        responses = CAPTAIN_RESPONSES
    elif "hickory" in npc_name_lower:
        responses = HICKORY_RESPONSES
    else:
        responses = [
            f"Hello! I'm {npc_name}, nice to meet you!",
            f"Welcome to MYGAIA!",
            f"How can I help you today?"
        ]
    
    # Add some contextual responses
    player_msg_lower = player_message.lower()
    if "hello" in player_msg_lower or "hi" in player_msg_lower:
        return random.choice([
            f"Hello there! I'm {npc_name}. How are you today?",
            f"Greetings, adventurer! Welcome to our village!",
            f"Well met! What brings you to these parts?"
        ])
    elif "help" in player_msg_lower:
        return f"I'm {npc_name}, and I'm here to help! You can explore the village, talk to NPCs, and discover secrets!"
    elif "quest" in player_msg_lower:
        return "Ah, looking for adventure? Check with the village elder for quests!"
    elif "bye" in player_msg_lower or "goodbye" in player_msg_lower:
        return "Farewell, traveler! Safe journeys!"
    
    return random.choice(responses)

if __name__ == "__main__":
    # Test the responses
    print(get_fallback_response("Captain", "Hello!"))
    print(get_fallback_response("Hickory", "How are you?"))
    print(get_fallback_response("Merchant", "What's for sale?"))