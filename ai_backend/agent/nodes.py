import re
import time
import datetime
from typing import Dict, Any, List
from .state import AuroraState
from .prompts import AURORA_SYSTEM_PROMPT
from ..tools.health_tools import get_user_profile, get_today_readings, get_reading_history
from ..tools.score_tools import get_daily_score, get_weekly_scores
from ..tools.analytics_tools import compare_periods, detect_trends, detect_anomalies
from ..tools.action_tools import log_water, log_calories, update_water_goal, update_step_goal, extract_water_amount_ml
from ..rag.qdrant_service import rag_service
from ..services.gemini_service import gemini_service
from ..services.firestore_service import firestore_service, get_today_ist
from ..tools.date_resolver import resolve_relative_date

async def route_intent_node(state: AuroraState) -> AuroraState:
    t_start = time.perf_counter()
    message = (state.get("original_user_message") or state.get("user_message", "")).lower().strip()

    # Deterministically resolve any relative or explicit date mentioned in the query
    rel_date, rel_label = resolve_relative_date(message)
    if rel_date:
        state["requested_date"] = rel_date
        state["date_label"] = rel_label

    # 1. Action intents (user intends to log or change something)
    is_action_keyword = any(k in message for k in ["log", "drank", "drink ", "drunk", "had ", "consumed", "add", "ate", "record"])
    has_number = any(c.isdigit() for c in message) or any(k in message for k in ["half a liter", "half liter", "half a litre", "quarter liter"])

    if ("water" in message or "drank" in message or "drink" in message or "hydrat" in message) and has_number and is_action_keyword and not any(k in message for k in ["schedule", "plan", "when to", "how to", "routine", "timetable"]):
        state["intent"] = "action_log_water"
    elif any(k in message for k in ["calorie", "kcal", "ate", "food", "meal"]) and has_number and any(k in message for k in ["log", "add", "record", "ate", "consumed"]) and not any(k in message for k in ["plan", "dinner", "recipe", "budget"]):
        state["intent"] = "action_log_calories"
    elif any(k in message for k in ["water goal", "goal for water"]) and has_number and any(k in message for k in ["update", "change", "set", "make"]):
        state["intent"] = "action_update_water_goal"
    elif any(k in message for k in ["step goal", "goal for step"]) and has_number and any(k in message for k in ["update", "change", "set", "make"]):
        state["intent"] = "action_update_step_goal"

    # 2. Specific health metric queries (personal health query)
    elif any(k in message for k in ["hydration", "how much water", "water have i", "water intake", "water today", "water status"]):
        state["intent"] = "hydration_query"
    elif any(k in message for k in ["step", "walked", "distance", "activity"]) and any(k in message for k in ["how many", "count", "today", "my step", "status", "taken"]):
        state["intent"] = "steps_query"
    elif any(k in message for k in ["sleep", "slept", "bedtime"]) and any(k in message for k in ["how did i", "how was my", "last night", "my sleep", "hours did i", "quality"]):
        state["intent"] = "sleep_query"
    elif any(k in message for k in ["heart rate", "pulse", "bpm", "heart"]):
        state["intent"] = "heart_rate_query"

    # 3. Score queries and analysis
    elif any(k in message for k in ["why did my score", "score change", "score drop", "score increase", "score fluctuate", "why is my score", "explain why my score", "reason for my score"]):
        state["intent"] = "score_analysis"
    elif any(k in message for k in ["improve", "boost", "raise", "increase", "better"]) and any(k in message for k in ["score", "wellness score"]):
        state["intent"] = "score_improvement"
    elif any(k in message for k in ["score", "wellness score", "daily score", "points"]) and rel_date and rel_date != get_today_ist():
        state["intent"] = "score_history"
    elif any(k in message for k in ["wellness score", "daily score", "my score", "what is my score", "points", "score"]):
        state["intent"] = "score_query"

    # 4. Weekly progress & analytics
    elif any(k in message for k in ["progress this week", "weekly progress", "weekly summary", "how did i do this week", "week progress", "compare this week"]):
        state["intent"] = "weekly_progress_query"

    # 5. Planning & guidance
    elif any(k in message for k in ["dinner", "meal plan", "healthy meal", "what should i eat", "what to eat", "calories left", "calorie left", "diet"]):
        state["intent"] = "meal_planning"
    elif any(k in message for k in ["schedule", "timing", "when should i drink", "when to drink", "routine", "timetable"]):
        state["intent"] = "schedule_guidance"
    elif any(k in message for k in ["sleep", "adult", "need"]) and any(k in message for k in ["how much", "how many hours", "recommend", "why do we", "benefits"]):
        state["intent"] = "sleep_guidance"
    elif any(k in message for k in ["benefit", "why is", "why do", "general", "science"]):
        state["intent"] = "general_wellness"
    else:
        state["intent"] = "general_wellness"

    intent_ms = round((time.perf_counter() - t_start) * 1000)
    print(f"[Aurora] Intent detection: {intent_ms} ms")
    print(f"[Aurora] Intent: {state['intent']}")
    return state

async def execute_tools_node(state: AuroraState) -> AuroraState:
    t_start = time.perf_counter()
    uid = state.get("user_id") or state.get("uid")
    auth_token = state.get("auth_token")
    intent = state.get("intent", "general_wellness")
    user_msg = state.get("original_user_message") or state.get("user_message", "")
    tools_called = []
    tool_results = {}

    # 1. Authoritative base state from Firestore
    profile = await get_user_profile(uid, auth_token=auth_token)
    today = await get_today_readings(uid, auth_token=auth_token)
    tool_results["profile"] = profile
    tool_results["today_readings"] = today
    tools_called.extend(["get_user_profile", "get_today_readings"])

    profile_ok = profile.get("success", False) or firestore_service._test_mode
    readings_ok = today.get("success", False) or firestore_service._test_mode
    state["data_available"] = profile_ok and readings_ok
    if not profile_ok or not readings_ok:
        err_code = today.get("error_code") or profile.get("error_code") or "DATABASE_UNAVAILABLE"
        state["errors"] = state.get("errors", []) + [err_code]
        state["database_error"] = err_code

    # Merge client snapshot ONLY if database is available and Firestore reading is zero but client has live readings
    if state.get("data_available", True) and state.get("client_snapshot"):
        snap = state["client_snapshot"]
        for key in ["water_ml", "steps", "calories_kcal", "sleep_hours", "heart_rate_bpm"]:
            if key in snap and snap[key] is not None and snap[key] > 0:
                if today.get(key) is None or today.get(key) == 0:
                    today[key] = snap[key]
        if "today_score" in snap and snap["today_score"] is not None:
            tool_results["client_score"] = snap["today_score"]

    # 2. Intent-specific tool execution
    if intent == "action_log_water":
        parsed_amount = extract_water_amount_ml(user_msg)
        if parsed_amount is None:
            err = "Invalid or unparseable water amount. Please specify a positive amount up to 5000 ml (e.g., 500 ml, 0.5 L)."
            tool_results["action_result"] = {"success": False, "error": err}
            state["errors"] = state.get("errors", []) + [err]
        else:
            print(f"[Aurora] Parsed water amount: {parsed_amount} ml")
            prev_water = today.get("water_ml", 0)
            print(f"[Aurora] Previous water total: {prev_water} ml")

            res = await log_water(uid, parsed_amount, auth_token=auth_token)
            if res.get("success"):
                print("[Aurora] Firestore write: SUCCESS")
                print(f"[Aurora] New water total: {res.get('new_total_ml')} ml")
                print("[Aurora] Daily score recalculated: SUCCESS")
                today["water_ml"] = res.get("new_total_ml", prev_water + parsed_amount)
                state["executed_action"] = res
            else:
                state["errors"] = state.get("errors", []) + [res.get("error", "Persistence failure")]
            tool_results["action_result"] = res
            tools_called.append("log_water")

    elif intent == "action_log_calories":
        numbers = re.findall(r"\d+", user_msg)
        if numbers:
            kcal = int(numbers[0])
            res = await log_calories(uid, kcal, auth_token=auth_token)
            if res.get("success"):
                today["calories_kcal"] += kcal
                state["executed_action"] = res
            tool_results["action_result"] = res
            tools_called.append("log_calories")

    elif intent == "action_update_water_goal":
        numbers = re.findall(r"\d+", user_msg)
        if numbers:
            new_goal = int(numbers[0])
            res = await update_water_goal(uid, new_goal, auth_token=auth_token)
            tool_results["action_result"] = res
            tools_called.append("update_water_goal")
            if res.get("requires_confirmation"):
                state["pending_action"] = res.get("confirmation")
            else:
                state["executed_action"] = res

    elif intent == "action_update_step_goal":
        numbers = re.findall(r"\d+", user_msg)
        if numbers:
            new_goal = int(numbers[0])
            res = await update_step_goal(uid, new_goal, auth_token=auth_token)
            tool_results["action_result"] = res
            tools_called.append("update_step_goal")
            if res.get("requires_confirmation"):
                state["pending_action"] = res.get("confirmation")
            else:
                state["executed_action"] = res

    elif intent == "hydration_query":
        tool_results["hydration_details"] = {
            "current_ml": today.get("water_ml", 0),
            "goal_ml": profile.get("water_goal_ml", 2500)
        }

    elif intent == "steps_query":
        tool_results["steps_details"] = {
            "steps": today.get("steps", 0),
            "step_goal": profile.get("step_goal", 10000)
        }

    elif intent == "sleep_query":
        history = await get_reading_history(uid, "sleep", days=3, auth_token=auth_token)
        tool_results["sleep_details"] = {
            "today_sleep": today.get("sleep_hours"),
            "sleep_goal": profile.get("sleep_goal_hours", 8.0),
            "history": history
        }
        tools_called.append("get_reading_history")

    elif intent == "heart_rate_query":
        history = await get_reading_history(uid, "heart_rate", days=3, auth_token=auth_token)
        tool_results["heart_rate_details"] = {
            "current_bpm": today.get("heart_rate_bpm"),
            "history": history
        }
        tools_called.append("get_reading_history")

    elif intent == "score_history":
        req_date = state.get("requested_date")
        date_lbl = state.get("date_label", "that date")
        print(f"[Aurora] Fetching historical score for date: {req_date} ({date_lbl})")
        hist_score = await get_daily_score(uid, date_str=req_date, auth_token=auth_token)
        tool_results["historical_score"] = hist_score
        tools_called.append("get_daily_score")

    elif intent in ["score_query", "score_analysis", "score_improvement"]:
        daily_score = await get_daily_score(uid, auth_token=auth_token)
        weekly = await get_weekly_scores(uid, days=7, auth_token=auth_token)
        tool_results["daily_score"] = daily_score
        tool_results["weekly_scores"] = weekly
        tools_called.extend(["get_daily_score", "get_weekly_scores"])

        if intent in ["score_analysis", "score_improvement"]:
            trends = await detect_trends(uid)
            anomalies = await detect_anomalies(uid)
            tool_results["trends"] = trends
            tool_results["anomalies"] = anomalies
            tools_called.extend(["detect_trends", "detect_anomalies"])

    elif intent == "weekly_progress_query":
        weekly = await get_weekly_scores(uid, days=7, auth_token=auth_token)
        steps_comp = await compare_periods(uid, "steps", days=7)
        water_comp = await compare_periods(uid, "water", days=7)
        tool_results["weekly_scores"] = weekly
        tool_results["steps_comparison"] = steps_comp
        tool_results["water_comparison"] = water_comp
        tools_called.extend(["get_weekly_scores", "compare_periods"])

    elif intent == "meal_planning":
        calorie_goal = profile.get("calorie_goal", 2000.0)
        calories_consumed = today.get("calories_kcal", 0)
        remaining = max(0, int(calorie_goal - calories_consumed))
        tool_results["calorie_budget"] = {
            "goal": int(calorie_goal),
            "consumed": int(calories_consumed),
            "remaining": remaining
        }

    state["tools_called"] = tools_called
    state["tool_calls"] = tools_called
    state["tool_results"] = tool_results
    state["current_health_data"] = today
    tools_ms = round((time.perf_counter() - t_start) * 1000)
    print(f"[Aurora] Firestore tools: {tools_ms} ms")
    return state

async def retrieve_rag_node(state: AuroraState) -> AuroraState:
    t_start = time.perf_counter()
    intent = state.get("intent", "general_wellness")
    user_msg = state.get("original_user_message") or state.get("user_message", "")

    # Only query RAG for general knowledge queries or mixed questions needing clinical evidence
    rag_needed = intent in ["general_wellness", "sleep_guidance", "schedule_guidance"] or any(k in user_msg.lower() for k in ["why", "benefit", "science", "how come", "adult need"])

    if rag_needed:
        docs = await rag_service.search(user_msg, limit=2)
        state["retrieved_documents"] = docs
        state["rag_docs"] = docs
        state["sources"] = [d["title"] for d in docs]
    else:
        state["retrieved_documents"] = []
        state["rag_docs"] = []
        state["sources"] = []

    rag_ms = round((time.perf_counter() - t_start) * 1000)
    print(f"[Aurora] RAG retrieval: {rag_ms} ms")
    return state

async def synthesize_response_node(state: AuroraState) -> AuroraState:
    t_start = time.perf_counter()
    print("[Aurora] Gemini synthesis started")
    user_msg = state.get("original_user_message") or state.get("user_message", "")
    history = state.get("history", [])
    tool_results = state.get("tool_results", {})
    rag_docs = state.get("retrieved_documents", state.get("rag_docs", []))
    executed_action = state.get("executed_action")
    pending_action = state.get("pending_action")
    intent = state.get("intent", "general_wellness")

    # CRITICAL: If an action failed, never pretend that the health data was saved
    if intent.startswith("action_") and not executed_action and not pending_action:
        err_msg = state.get("errors", ["Health data could not be persisted."])[-1] if state.get("errors") else "Health data could not be persisted."
        state["final_response"] = f"❌ Action failed: {err_msg}"
        print("[Aurora] Action failed response returned")
        return state

    profile = tool_results.get("profile", {})
    today = tool_results.get("today_readings", {})

    # Database Error Guard for Personal Health Queries
    is_personal_health_query = intent in [
        "hydration_query", "steps_query", "sleep_query", "heart_rate_query",
        "score_query", "score_analysis", "score_history"
    ]
    db_available = state.get("data_available")
    if db_available is None:
        db_available = (today.get("success", False) or firestore_service._test_mode) and (profile.get("success", False) or firestore_service._test_mode)

    if is_personal_health_query and not db_available:
        if intent == "score_history":
            hist = tool_results.get("historical_score")
            if hist and hist.get("error_code") == "NO_SCORE_FOR_DATE":
                date_lbl = state.get("date_label", "that day")
                req_date = state.get("requested_date", "")
                resp = f"I don't have a recorded Wellness Score for {date_lbl} ({req_date})." if req_date else f"I don't have a recorded Wellness Score for {date_lbl}."
                print(f"[Aurora] Score history missing for {req_date}: {resp}")
                state["final_response"] = resp
                return state
        resp = "I couldn't retrieve your health data right now. Please try again."
        print(f"[Aurora] Database failure guard triggered for intent: {intent}")
        state["final_response"] = resp
        return state
    today = tool_results.get("today_readings", {})
    daily_score = tool_results.get("daily_score")
    client_score = tool_results.get("client_score")

    context_lines = [
        f"USER QUESTION: {user_msg}",
        f"IDENTIFIED INTENT: {intent}",
        f"AUTHENTICATED USER (UID: {state.get('user_id') or state.get('uid')}):",
        f"- Target Goals: Steps: {profile.get('step_goal', 10000)}, Water: {profile.get('water_goal_ml', 2500)} ml, Sleep: {profile.get('sleep_goal_hours', 8.0)} hrs, Calories: {profile.get('calorie_goal', 2000)} kcal",
        f"- Today's Ground Truth Readings (from Firestore):",
        f"  * Water Intake: {today.get('water_ml', 0)} ml",
        f"  * Steps: {today.get('steps', 0)} steps",
        f"  * Sleep: {today.get('sleep_hours') if today.get('sleep_hours') is not None else 'No sleep recorded yet'} hours",
        f"  * Calories Consumed: {today.get('calories_kcal', 0)} kcal",
        f"  * Heart Rate: {today.get('heart_rate_bpm') if today.get('heart_rate_bpm') is not None else 'N/A'} bpm",
        f"  * Blood Pressure: {today.get('blood_pressure') or 'N/A'}",
    ]

    effective_score = daily_score.get("overallScore") if (daily_score and "overallScore" in daily_score) else client_score
    if effective_score is not None:
        context_lines.append(f"- Authoritative DailyScore (Computed by HealthScoreEngine): {effective_score} / 100")
        if daily_score and "components" in daily_score:
            comps = daily_score["components"]
            context_lines.append(f"  * Components: {comps}")
    else:
        context_lines.append(f"- Authoritative DailyScore: Compiling based on today's logged data.")

    if executed_action:
        context_lines.append(f"- EXECUTED TOOL RESULT: {executed_action}")

    if pending_action:
        context_lines.append(f"- PENDING ACTION REQUIRING CONFIRMATION: {pending_action.get('warning')}")

    if intent == "score_history":
        hist = tool_results.get("historical_score")
        date_lbl = state.get("date_label", "that day")
        req_date = state.get("requested_date", "")
        if not hist or not hist.get("success") or hist.get("overallScore") is None:
            resp = f"I don't have a recorded Wellness Score for {date_lbl}."
            print(f"[Aurora] Score history missing for {req_date}: {resp}")
            state["final_response"] = resp
            return state

        hist_score_val = hist.get("overallScore")
        hist_label = hist.get("label", "Good")
        hist_comps = hist.get("components", {})
        context_lines.append(f"- HISTORICAL WELLNESS SCORE FOR {date_lbl.upper()} ({req_date}): {hist_score_val} / 100 ({hist_label})")
        context_lines.append(f"  * Historical Components: {hist_comps}")
        context_lines.append(
            f"CRITICAL INSTRUCTION: The user is explicitly asking about their score for {date_lbl} ({req_date}). "
            f"Their exact score on {req_date} was {hist_score_val}/100 ({hist_label}). "
            f"State their {date_lbl} score clearly as {hist_score_val}/100. "
            f"DO NOT mention or confuse with today's score ({effective_score}/100). "
            f"DO NOT invent, fabricate, or hallucinate dates such as 'May 18' or any other date. The date is {req_date}."
        )

    if intent == "hydration_query":
        context_lines.append("INSTRUCTION: Answer specifically about the user's hydration today (water intake vs daily goal). Do NOT list all other metrics.")
    elif intent == "steps_query":
        context_lines.append("INSTRUCTION: Answer specifically about the user's steps today (steps taken vs step goal). Do NOT list all other metrics.")
    elif intent == "sleep_query":
        context_lines.append("INSTRUCTION: Answer specifically about the user's sleep. Do NOT list unrelated metrics.")
    elif intent == "heart_rate_query":
        context_lines.append("INSTRUCTION: Answer specifically about the user's heart rate. Do NOT list unrelated metrics.")
    elif intent == "action_log_water":
        context_lines.append("INSTRUCTION: State that the water was logged. Cite the logged amount, the newly verified total today, the percentage of goal reached, and the amount remaining. DO NOT invent scores.")

    if rag_docs:
        context_lines.append("\nTRUSTED CLINICAL EVIDENCE:")
        for doc in rag_docs:
            context_lines.append(f"[{doc['title']}]: {doc['content']}")

    system_instruction = f"{AURORA_SYSTEM_PROMPT}\n\nCURRENT AUTHORITATIVE STATE & QUERY CONTEXT:\n" + "\n".join(context_lines)

    conversation_msgs = []
    for h in history[-6:]:
        conversation_msgs.append({"role": h.get("role", "user"), "content": h.get("content", "")})
    conversation_msgs.append({"role": "user", "content": user_msg})

    if gemini_service.is_configured:
        try:
            response_text = await gemini_service.generate_response(
                system_prompt=system_instruction,
                messages=conversation_msgs,
                temperature=0.2
            )
            if response_text and len(response_text.strip()) > 0:
                gemini_ms = round((time.perf_counter() - t_start) * 1000)
                print(f"[Aurora] Gemini synthesis: {gemini_ms} ms")
                print("[Aurora] Final response generated")
                state["final_response"] = response_text
                return state
        except Exception as e:
            print(f"[SynthesizeNode] Gemini call failed: {str(e)[:100]}, using deterministic response.")

    state["final_response"] = _generate_deterministic_response(state)
    gemini_ms = round((time.perf_counter() - t_start) * 1000)
    print(f"[Aurora] Gemini synthesis: {gemini_ms} ms")
    print("[Aurora] Final response generated")
    return state

def _generate_deterministic_response(state: AuroraState) -> str:
    user_msg = (state.get("original_user_message") or state.get("user_message", "")).lower()
    intent = state.get("intent", "general_wellness")
    results = state.get("tool_results", {})
    profile = results.get("profile", {})
    today = results.get("today_readings", {})
    daily_score = results.get("daily_score")
    executed = state.get("executed_action")
    pending = state.get("pending_action")

    # Database Error Guard for Personal Health Queries in deterministic mode
    is_personal_health_query = intent in [
        "hydration_query", "steps_query", "sleep_query", "heart_rate_query",
        "score_query", "score_analysis", "score_history"
    ]
    if is_personal_health_query and not state.get("data_available", True):
        if intent == "score_history":
            hist = results.get("historical_score")
            if hist and hist.get("error_code") == "NO_SCORE_FOR_DATE":
                date_lbl = state.get("date_label", "that day")
                req_date = state.get("requested_date", "")
                return f"I don't have a recorded Wellness Score for {date_lbl} ({req_date})." if req_date else f"I don't have a recorded Wellness Score for {date_lbl}."
        return "I couldn't retrieve your health data right now. Please try again."

    # 1. Action: Water logged
    if executed and executed.get("action") == "water_logged":
        amt = executed.get("amount_ml")
        new_total = executed.get("new_total_ml")
        goal = executed.get("goal_ml", 2500)
        pct = executed.get("percentage", round((new_total / goal) * 100))
        rem = executed.get("remaining_ml", max(0, goal - new_total))
        return (
            f"Logged {amt} ml of water. You now have {new_total:,} ml today, which is {pct}% of your {goal:,} ml goal. "
            f"You have {rem:,} ml remaining."
        )

    if executed:
        return f"✅ **Action Completed**: {executed.get('message', 'Action executed.')}"

    if pending:
        return f"⚠️ **Confirmation Required**: {pending.get('warning')}\n\n{pending.get('message')}"

    # 2. Hydration Query
    if intent == "hydration_query":
        water_ml = today.get("water_ml", 0)
        goal_ml = profile.get("water_goal_ml", 2500)
        pct = round((water_ml / goal_ml) * 100) if goal_ml > 0 else 0
        rem = max(0, goal_ml - water_ml)
        status_note = f"Great work! You have reached your daily hydration goal." if water_ml >= goal_ml else f"You have {rem:,} ml remaining to reach your daily goal."
        return (
            f"💧 **Hydration Status Today**\n\n"
            f"• **Current Intake**: {water_ml:,} ml\n"
            f"• **Daily Target**: {goal_ml:,} ml\n"
            f"• **Progress**: {pct}% achieved\n\n"
            f"{status_note}"
        )

    # 3. Steps Query
    if intent == "steps_query":
        steps = today.get("steps", 0)
        step_goal = profile.get("step_goal", 10000)
        pct = round((steps / step_goal) * 100) if step_goal > 0 else 0
        rem = max(0, step_goal - steps)
        status_note = "Congratulations! You have reached your step goal today." if steps >= step_goal else f"You are {rem:,} steps away from your daily goal."
        return (
            f"👟 **Activity & Steps Today**\n\n"
            f"• **Steps Taken**: {steps:,} steps\n"
            f"• **Daily Goal**: {step_goal:,} steps\n"
            f"• **Progress**: {pct}% completed\n\n"
            f"{status_note}"
        )

    # 4. Sleep Query
    if intent == "sleep_query":
        sleep_hrs = today.get("sleep_hours")
        goal_hrs = profile.get("sleep_goal_hours", 8.0)
        if sleep_hrs is not None and sleep_hrs > 0:
            diff = sleep_hrs - goal_hrs
            status_note = f"You reached your target of {goal_hrs:.1f} hours." if diff >= 0 else f"You were {abs(diff):.1f} hours short of your {goal_hrs:.1f}-hour goal."
            return (
                f"😴 **Sleep Analysis**\n\n"
                f"• **Recorded Sleep**: {sleep_hrs:.1f} hours\n"
                f"• **Target Duration**: {goal_hrs:.1f} hours\n\n"
                f"{status_note} Prioritize an early wind-down routine tonight to support recovery."
            )
        else:
            return (
                f"😴 **Sleep Status**\n\n"
                f"No sleep data has been recorded for today yet. "
                f"Your target sleep duration is **{goal_hrs:.1f} hours**. "
                f"You can log your sleep duration in your tracker to include it in your daily score."
            )

    # 5. Heart Rate Query
    if intent == "heart_rate_query":
        bpm = today.get("heart_rate_bpm")
        if bpm is not None and bpm > 0:
            category = "optimal resting" if 60 <= bpm <= 80 else ("elevated" if bpm > 80 else "athletic/low")
            return (
                f"❤️ **Heart Rate Analysis**\n\n"
                f"• **Current Reading**: {round(bpm)} bpm\n"
                f"• **Status**: In the **{category}** range (standard resting range: 60–100 bpm).\n\n"
                f"Consistent aerobic activity and adequate hydration help keep resting heart rate stable."
            )
        else:
            return (
                f"❤️ **Heart Rate Status**\n\n"
                f"No heart rate readings have been logged today. "
                f"Normal adult resting heart rate typically ranges between **60 and 100 bpm**."
            )

    # 6. Score Analysis & Why Score Changed
    if intent in ["score_analysis", "score_improvement"]:
        score_val = daily_score.get("overallScore") if daily_score else None
        comps = daily_score.get("components", {}) if daily_score else {}
        score_str = f"{score_val}/100" if score_val is not None else "currently compiling"

        return (
            f"📈 **Wellness Score Breakdown ({score_str})**\n\n"
            f"Your score is calculated deterministically by `HealthScoreEngine` across your core health pillars:\n\n"
            f"• **Hydration**: {today.get('water_ml', 0)} / {profile.get('water_goal_ml', 2500)} ml (Component: {comps.get('water', 'N/A')}/10)\n"
            f"• **Activity**: {today.get('steps', 0)} / {profile.get('step_goal', 10000)} steps (Component: {comps.get('activity', 'N/A')}/10)\n"
            f"• **Sleep**: {today.get('sleep_hours') or 'unlogged'} hrs / {profile.get('sleep_goal_hours', 8.0)} hrs (Component: {comps.get('sleep', 'N/A')}/10)\n"
            f"• **Nutrition**: {today.get('calories_kcal', 0)} / {int(profile.get('calorie_goal', 2000))} kcal (Component: {comps.get('calories', 'N/A')}/10)\n\n"
            f"💡 **Key Action to Improve Score**: Logging unrecorded metrics like sleep and completing your remaining hydration will immediately raise your overall score."
        )

    # 7. Score History Query
    if intent == "score_history":
        hist = results.get("historical_score")
        date_lbl = state.get("date_label", "that day")
        req_date = state.get("requested_date", "")
        if hist and hist.get("success") and hist.get("overallScore") is not None:
            val = hist.get("overallScore")
            lbl = hist.get("label", "Good")
            return (
                f"🌟 **Your Wellness Score for {date_lbl} was {val}/100 ({lbl})**\n\n"
                f"Calculated deterministically by `HealthScoreEngine` for {req_date}."
            )
        else:
            return f"I don't have a recorded Wellness Score for {date_lbl}."

    # 8. Score Query
    if intent == "score_query":
        score_val = daily_score.get("overallScore") if daily_score else None
        if score_val is not None:
            return (
                f"🌟 **Your Wellness Score Today is {score_val}/100 ({daily_score.get('label', 'Good')})**\n\n"
                f"Calculated deterministically by `HealthScoreEngine` from your Firestore logs:\n"
                f"• **Hydration**: {today.get('water_ml', 0)} / {profile.get('water_goal_ml', 2500)} ml\n"
                f"• **Steps**: {today.get('steps', 0)} / {profile.get('step_goal', 10000)} steps\n"
                f"• **Sleep**: {today.get('sleep_hours') if today.get('sleep_hours') is not None else 'Pending log'} hrs"
            )
        else:
            return (
                f"📊 **Daily Wellness Score**\n\n"
                f"Your daily wellness score is compiling from today's readings. "
                f"Log your water, steps, and sleep to generate your full score."
            )

    # 8. Weekly Progress
    if intent == "weekly_progress_query":
        weekly = results.get("weekly_scores", [])
        avg_score = round(sum(s.get("overallScore", 0) for s in weekly) / len(weekly)) if weekly else "N/A"
        return (
            f"📊 **Weekly Progress Summary**\n\n"
            f"• **Average Wellness Score**: {avg_score}/100\n"
            f"• **Days Logged**: {len(weekly)} of 7 days\n"
            f"• **Consistency**: Building consistent logging across hydration and steps creates the highest score stability."
        )

    # 9. Meal Planning
    if intent == "meal_planning":
        budget = results.get("calorie_budget", {})
        rem = budget.get("remaining", max(0, int(profile.get("calorie_goal", 2000) - today.get("calories_kcal", 0))))
        return (
            f"🥗 **Healthy Dinner Plan (Budget: ~{rem} kcal remaining)**\n\n"
            f"Here is a balanced, nutrient-dense evening dinner:\n\n"
            f"• **Option 1: Lean Protein & Greens (~{min(rem, 450)} kcal)**\n"
            f"  - Grilled chicken breast or grilled tofu steak\n"
            f"  - Steamed broccoli, spinach, and half a sweet potato\n\n"
            f"• **Option 2: Plant-Based Recovery Bowl (~{min(rem, 380)} kcal)**\n"
            f"  - Warm quinoa bowl with chickpeas, diced avocado, and cherry tomatoes\n"
            f"  - Light lemon-tahini dressing\n\n"
            f"Both options deliver quality micronutrients and dietary fiber without spiking late-night blood glucose."
        )

    # 10. Schedule Guidance
    if intent == "schedule_guidance":
        goal = profile.get("water_goal_ml", 2500)
        return (
            f"💧 **Daily Hydration Schedule (Target: {goal:,} ml)**\n\n"
            f"• **07:00 AM**: 500 ml upon waking to reverse overnight fluid deficit\n"
            f"• **10:30 AM**: 350 ml mid-morning cognitive hydration\n"
            f"• **01:00 PM**: 400 ml 30 mins before lunch\n"
            f"• **04:00 PM**: 400 ml afternoon energy support\n"
            f"• **07:30 PM**: 350 ml with dinner\n"
            f"• **09:30 PM**: 250 ml 1 hour before sleep\n\n"
            f"Current intake: **{today.get('water_ml', 0)} / {goal} ml**."
        )

    # 11. Sleep Guidance
    if intent == "sleep_guidance":
        return (
            f"😴 **Evidence-Based Sleep Guidelines for Adults**\n\n"
            f"Clinical evidence recommends **7 to 9 hours** of sleep per night for healthy adults:\n\n"
            f"• **Deep Sleep**: Essential for physical tissue repair, cellular restoration, and immune health.\n"
            f"• **REM Sleep**: Essential for memory consolidation and emotional equilibrium.\n"
            f"• **Circadian Tip**: Keep your wake-up time consistent every morning to anchor your sleep drive."
        )

    # General Fallback
    return (
        f"👋 **Hello! How can I assist your health journey today?**\n\n"
        f"You can ask me about your **hydration**, **step progress**, **sleep quality**, "
        f"or say **'I drank 500 ml of water'** to log your intake."
    )
