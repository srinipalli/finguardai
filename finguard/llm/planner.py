import os, json, re
from typing import Dict, Any, List, Tuple
from ..utils.schemas import PerceivedEvent
from google import genai

TOOLS_SPEC = [
    {"name":"recent_events", "desc":"Fetch account's recent events from Oracle for velocity features", "args":{"account_id":"str","window_sec":"int"}},
    {"name":"device_seen", "desc":"Check if device was seen for the account", "args":{"account_id":"str","device_id":"str"}},
    {"name":"merchant_blacklist", "desc":"Check if merchant is blacklisted", "args":{"merchant_id":"str"}},
    {"name":"score_rules", "desc":"Apply deterministic rule score", "args":{"features":"dict"}},
    {"name":"persist_decision", "desc":"Persist decision to Oracle", "args":{"event_id":"str","action":"str","risk_score":"float","reasons":"list"}},
    {"name":"publish_kafka", "desc":"Publish to Kafka topic", "args":{"topic":"str","key":"str","value":"dict"}},
    {"name":"create_alert", "desc":"Create alert for CHALLENGE/BLOCK", "args":{"severity":"str","title":"str","description":"str","event_id":"str","tags":"list"}}
]

SYSTEM_INSTRUCTIONS = """You are a FinGuard Orchestrator. Produce a minimal, correct tool WORKFLOW for fraud decisioning.
- Available tools are strictly the following with exact names and arguments:
{tools}
- You MUST respond with **machine-only JSON** (no prose) in this schema:
{{
  "workflow": [{{"tool":"<name>","args":{{...}}}}...],
  "expected_action": "ALLOW|CHALLENGE|BLOCK",
  "rationale": "<short reason>"
}}
Rules:
- Always include 'recent_events', 'device_seen', 'merchant_blacklist', then 'score_rules'.
- If expected_action is CHALLENGE or BLOCK, include 'create_alert' and 'publish_kafka' for alerts.
- Always include 'persist_decision' and 'publish_kafka' for decisions.
- Do not invent tools or arguments.
- Keep arguments concise and serializable.
"""

def _gemini_call(prompt: str) -> str:
    """Try calling Google Gemini (generative AI). If the gemini client is not
    available or fails, raise the exception to let caller decide to fallback.
    This wrapper attempts a few common SDK shapes; it's defensive because
    users may not have the library installed in every environment.
    """
    try:
        # prefer the official google generative ai client if present
        api_key = os.getenv("GOOGLE_API_KEY")
        print("Gemini API key:", "set" if os.getenv("GOOGLE_API_KEY") else "NOT set")

        # Latest google generative SDK exposes genai.configure(api_key=...)
        # Call it directly when provided; let exceptions propagate to the
        # outer try so the caller can fallback to OpenAI or mock.
        if api_key:
            client = genai.Client(api_key=api_key)

            model = os.getenv("FINGUARD_LLM_MODEL", "gemini-1.5-flash")
            print("gemini_call: using model", model)
        # try chat-style API first
         #if hasattr(genai, "chat") and hasattr(genai.chat, "create"):
            #SYSTEM_INSTRUCTIONS = "You are a helpful assistant with access to the following tools: {tools}"

            chat = client.chats.create(
            model=model,
            config={
                "system_instruction": SYSTEM_INSTRUCTIONS.format(
                    tools=json.dumps(TOOLS_SPEC, indent=2)
                ),
                 "temperature": 0.1
                    }
            )
            print("Gemini chat created with model:", model)
            resp = chat.send_message(prompt)
            print("Gemini chat response11:", resp)
             
            return resp.candidates[0].content.parts[0].text


    except Exception as e:
        # raise to allow the caller to fallback to OpenAI or mock
        import traceback
        traceback.print_exc()
        

 


def plan_workflow(p: PerceivedEvent) -> Dict[str, Any]:
    """
    Returns a dict with keys: workflow, expected_action, rationale
    """
    enable = os.getenv("FINGUARD_LLM_ENABLED","false").lower() in ("1","true","yes")
    provider = os.getenv("FINGUARD_LLM_PROVIDER","mock").lower()
    if not enable:
        # deterministic fallback mini-plan
        expected = "ALLOW"
        if p.features.get("amount",0) >= 100000 or p.features.get("geo_velocity_km_per_min",0)>=50:
            expected = "CHALLENGE"
        plan = [
            {"tool":"recent_events","args":{"account_id":p.event.account_id,"window_sec":60}},
            {"tool":"device_seen","args":{"account_id":p.event.account_id,"device_id":p.event.device_id or ""}},
            {"tool":"merchant_blacklist","args":{"merchant_id":p.event.merchant_id or ""}},
            {"tool":"score_rules","args":{"features":p.features}},
            {"tool":"persist_decision","args":{"event_id":p.event.event_id,"action":expected,"risk_score":0.0,"reasons":["mock-plan"]}},
            {"tool":"publish_kafka","args":{"topic":"finguard.decisions","key":p.event.event_id,"value":{"event_id":p.event.event_id,"action":expected}}},
        ]
        if expected in ("CHALLENGE","BLOCK"):
            plan.append({"tool":"create_alert","args":{"severity":"MEDIUM" if expected=="CHALLENGE" else "HIGH","title":f"Decision: {expected}","description":"mock-plan","event_id":p.event.event_id,"tags":["fraud","decision"]}})
            plan.append({"tool":"publish_kafka","args":{"topic":"finguard.alerts","key":p.event.event_id,"value":{"event_id":p.event.event_id,"severity":"MEDIUM" if expected=="CHALLENGE" else "HIGH"}}})
        return {"workflow": plan, "expected_action": expected, "rationale": "LLM disabled; deterministic plan"}
    print("plan_workflow: LLM enabled, provider=", provider)
    if provider == "gemini":
        user_prompt = f"""Produce a tool workflow for this transaction.\nFeatures: {json.dumps(p.features, default=str)}\nEvent: {p.event.dict()}"""
        try:
            content = _gemini_call(user_prompt)
            print("plan_workflow Gemini response:")
            json_string = content
            print("plan_workflow Gemini json_string ****:", json_string) 

            # 2. Clean the string by removing the markdown code block fences (```json and ```)
            # The strip() method removes leading/trailing whitespace
            cleaned_json_string = json_string.strip('` \njson')
            # 3. Parse the cleaned JSON string into a Python dictionary
            parsed_json = json.loads(cleaned_json_string)
            print("plan_workflow Gemini parsed_json:", parsed_json)
            # 4. Now you can access the data just like you would with any dictionary
            print("Workflow:", parsed_json['workflow'])
            print("Expected Action:", parsed_json['expected_action'])
            print("Rationale:", parsed_json['rationale'])

            # Example of accessing a nested value
            print("Tool from the first workflow step:", parsed_json['workflow'][0]['tool'])            
 
 
            return parsed_json

        except Exception:
            import traceback   
            traceback.print_exc() 
            return {"workflow": [], "expected_action": "ALLOW", "rationale": f"Parse error: {e}"}
    # mock provider same as disabled
    return {"workflow": [], "expected_action": "ALLOW", "rationale": "Unknown provider; returning empty plan"}
