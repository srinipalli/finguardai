import os
from typing import Dict, Any, Tuple, Optional
from ..utils.schemas import PerceivedEvent
from ..config import settings as config

# Provider: "openai" or "mock"
PROVIDER = os.getenv("FINGUARD_LLM_PROVIDER", "mock").lower()
MODEL = os.getenv("FINGUARD_LLM_MODEL", "gpt-4o-mini")
ENABLE = os.getenv("FINGUARD_LLM_ENABLED", "false").lower() in ("1","true","yes")

 
def _gemini_score(prompt: str) -> Tuple[float, str]:
    try:
        from google import genai
        api_key = os.getenv("GOOGLE_API_KEY")
        print("Gemini API key:", "set" if api_key else "NOT set")
        if api_key:
            # Use the official configure API from google.genai
            client = genai.Client(api_key=api_key)
            model = os.getenv("FINGUARD_LLM_MODEL", "gemini-1.5-flash")
        # try chat-style create
       # if hasattr(genai, "chat") and hasattr(genai.chat, "create"):
            # Define the system instruction and model
            SYSTEM_INSTRUCTION = "You are a risk analyst. Return a JSON with fields: delta (0-40) and rationale (short)."
            model = "gemini-1.5-flash"

            # Create a chat session with the specified system instruction and model
            chat = client.chats.create(
                model="gemini-1.5-flash",
                config={
                    "temperature": 0.2,
                    "system_instruction": SYSTEM_INSTRUCTION
                }
            )
            print("Gemini chat created with model:", model)
            # Send the user's prompt to the chat session
            prompt = "Analyze the risk of a new financial product in a volatile market."
            resp = chat.send_message(prompt)
            print("Gemini chat response:", resp)
            # best-effort text extraction
            if hasattr(resp, "last"):
                text = str(resp.last)
            elif hasattr(resp, "outputs"):
                try:
                    text = resp.outputs[0]["content"][0]["text"]
                except Exception:
                    text = str(resp)
            else:
                text = str(resp)
        """  elif hasattr(genai, "generate_text"):
            #resp = genai.generate_text(model=model, input=prompt)
            chat = client.chats.create(model="gemini-1.5-flash")
            resp = chat.send_message(prompt)

            text = getattr(resp, "text", str(resp))
        else:
            raise RuntimeError("No known Gemini call available") 
            """

        import json as _json, re
        m = re.search(r'\{[\s\S]*\}', text)
        if m:
            data = _json.loads(m.group(0))
            return float(data.get("delta", 0.0)), str(data.get("rationale",""))
        return 0.0, "No JSON returned"
    except Exception as e:
        return 0.0, f"LLM error: {e}"

def llm_adjustment(p: PerceivedEvent) -> Tuple[float, str]:
    if not ENABLE:
        return 0.0, "LLM disabled"
    prompt = f"""
Given these transaction features, provide a risk adjustment delta between 0 and 40 and a brief rationale.
Features: {p.features}
Channel: {p.event.channel}, MCC: {p.event.mcc}, Amount: {p.event.amount}, Time: {p.event.timestamp.isoformat()}
Respond as JSON: {{"delta": <0-40>, "rationale": "<short>"}}
"""
    
    print("LLM prompt:", prompt)
    if PROVIDER == "gemini":
        # try gemini first, fall back to openai
        delta, rationale = _gemini_score(prompt)
        print("delta,rationale:", delta,rationale)
        return delta, rationale
    
    # Mock provider for offline/dev
    base = 0.0
    if p.features.get("is_new_device"): base += 5
    if p.features.get("geo_velocity_km_per_min", 0) >= 50: base += 10
    if p.features.get("amount", 0) >= 100000: base += 8
    delta = min(40.0, base)
    return delta, "Mock heuristic adjustment"
