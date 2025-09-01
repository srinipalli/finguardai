import os
from google import genai

# Initialize the client
client = genai.Client(api_key="AIzaSyCU4iK8MXDD6U6O4VYUycPrjQvck_VIDmg")

# Create a chat session with the Gemini 1.5 Flash model
chat = client.chats.create(model="gemini-1.5-flash")

# Start a conversation
response1 = chat.send_message("Hello, tell me a short story about a brave knight.")
print("Knight's story:")
print(response1.text)

# Continue the conversation
response2 = chat.send_message("What was the name of his dragon?")
print("\nDragon's name:")
print(response2.text)