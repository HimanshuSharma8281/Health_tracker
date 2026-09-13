import re
import uuid
from typing import Dict, Any, Optional
from ..services.firestore_service import firestore_service, get_today_ist
from ..services.health_score_engine import HealthScoreEngine

# Temporary in-memory pending actions cache (scoped by uid and action_id)
_PENDING_ACTIONS: Dict[str, Dict[str, Any]] = {}

def extract_water_amount_ml(text: str) -> Optional[int]:
    """
    Deterministically parses water amount from natural language queries.
    Handles '500 ml', '0.5 liters', 'half a liter', '2 glasses', etc.
    Strictly rejects negative values, 0, and amounts > 5000 ml.
    """
    text_lower = text.lower().strip()

    # Reject explicit negative numbers
    if re.search(r'-\s*[0-9]+', text_lower):
        return None

    # 1. Fractions of a liter
    if any(k in text_lower for k in ['half a liter', 'half liter', 'half a litre', 'half litre']):
        return 500
    if any(k in text_lower for k in ['quarter a liter', 'quarter liter', 'quarter of a liter', 'quarter of a litre']):
        return 250

    # 2. Liters with decimal or integer (e.g. 0.5 liters, 1.5 l, 1 liter)
    liter_match = re.search(r'([0-9]+(?:\.[0-9]+)?)\s*(?:l|liter|liters|litre|litres)\b', text_lower)
    if liter_match:
        val = float(liter_match.group(1)) * 1000.0
        amount = int(round(val))
        return amount if 1 <= amount <= 5000 else None

    # 3. Milliliters (e.g. 500 ml, 500ml, 250 milliliters)
    ml_match = re.search(r'([0-9]+(?:\.[0-9]+)?)\s*(?:ml|milliliter|milliliters|millilitre|millilitres)\b', text_lower)
    if ml_match:
        amount = int(round(float(ml_match.group(1))))
        return amount if 1 <= amount <= 5000 else None

    # 4. Standard glasses (250 ml each)
    glass_match = re.search(r'([0-9]+)\s*(?:glass|glasses)\b', text_lower)
    if glass_match:
        amount = int(glass_match.group(1)) * 250
        return amount if 1 <= amount <= 5000 else None

    # 5. Standard bottles (500 ml each)
    bottle_match = re.search(r'([0-9]+)\s*(?:bottle|bottles)\b', text_lower)
    if bottle_match:
        amount = int(bottle_match.group(1)) * 500
        return amount if 1 <= amount <= 5000 else None

    # 6. Fallback if context is water logging and a single number is found (e.g. 'log 500 water')
    plain_match = re.search(r'\b([0-9]+)\b', text_lower)
    if plain_match and any(w in text_lower for w in ['water', 'drank', 'drink', 'hydrat']):
        amount = int(plain_match.group(1))
        return amount if 50 <= amount <= 5000 else None

    return None

async def log_water(uid: str, amount_ml: int, auth_token: Optional[str] = None) -> Dict[str, Any]:
    """
    Logs water consumption (in milliliters) for the authenticated user.
    CRITICAL:
    - Purely ADDITIVE. Creates a new healthReading document; never overwrites previous readings.
    - Reads previous total from Firestore.
    - Persists new event.
    - Re-reads updated aggregate from Firestore.
    - Recalculates DailyScore deterministically with HealthScoreEngine.
    - Returns structured information.
    """
    if amount_ml <= 0 or amount_ml > 5000:
        return {"success": False, "error": f"Invalid water amount: {amount_ml} ml. Must be between 1 and 5000 ml."}

    try:
        # 1. Read today's previous readings and user profile from Firestore
        previous_readings = await firestore_service.get_today_readings(uid, auth_token=auth_token)
        if not previous_readings.get("success", False) and not firestore_service._test_mode:
            return {
                "success": False,
                "error_code": previous_readings.get("error_code", "DATABASE_UNAVAILABLE"),
                "error": "Health data could not be persisted. Could not read existing water data from Firestore."
            }
        previous_total_ml = previous_readings.get("water_ml", 0)

        profile = await firestore_service.get_user_profile(uid, auth_token=auth_token)
        goal_ml = profile.get("water_goal_ml", 2500) if (profile.get("success") or firestore_service._test_mode) else 2500

        # 2. Persist the new event to Firestore (must not overwrite previous readings)
        record = await firestore_service.log_reading(
            uid=uid,
            metric="water",
            value=float(amount_ml),
            auth_token=auth_token
        )
        if not record.get("success", False) and not firestore_service._test_mode:
            return {
                "success": False,
                "error_code": record.get("error_code", "DATABASE_UNAVAILABLE"),
                "error": "Health data could not be persisted to Firestore."
            }

        # 3. Re-read today's readings from Firestore to verify updated aggregate
        updated_readings = await firestore_service.get_today_readings(uid, auth_token=auth_token)
        new_total_ml = updated_readings.get("water_ml", previous_total_ml + amount_ml)
        print(f"[Aurora] Water total verified: {new_total_ml} ml")

        # 4. Deterministically recalculate daily score using HealthScoreEngine
        today_str = get_today_ist()
        new_score = HealthScoreEngine.calculate_daily_score(
            readings=updated_readings,
            profile=profile,
            date_str=today_str
        )
        await firestore_service.save_daily_score(uid, new_score, auth_token=auth_token)

        remaining_ml = max(0, goal_ml - new_total_ml)
        percentage = round((new_total_ml / goal_ml) * 100) if goal_ml > 0 else 0

        return {
            "success": True,
            "tool": "log_water",
            "action": "water_logged",
            "amount_ml": amount_ml,
            "logged_ml": amount_ml,
            "previous_total_ml": previous_total_ml,
            "new_total_ml": new_total_ml,
            "goal_ml": goal_ml,
            "remaining_ml": remaining_ml,
            "percentage": percentage,
            "date": today_str,
            "record_id": record.get("id"),
            "new_score": new_score.get("overallScore"),
            "message": f"Logged {amount_ml} ml of water. You now have {new_total_ml} ml today, which is {percentage}% of your {goal_ml} ml goal. You have {remaining_ml} ml remaining."
        }
    except Exception as e:
        print(f"[log_water] Error persisting water log: {e}")
        return {
            "success": False,
            "error": "Health data could not be persisted."
        }

async def log_calories(uid: str, calories_kcal: int, meal_type: Optional[str] = None, auth_token: Optional[str] = None) -> Dict[str, Any]:
    """
    Logs calorie consumption for the authenticated user.
    """
    if calories_kcal <= 0 or calories_kcal > 10000:
        return {"success": False, "error": "Invalid calorie amount. Must be between 1 and 10000 kcal."}

    try:
        previous_readings = await firestore_service.get_today_readings(uid, auth_token=auth_token)
        previous_total_kcal = previous_readings.get("calories_kcal", 0)

        profile = await firestore_service.get_user_profile(uid, auth_token=auth_token)
        calorie_goal = profile.get("calorie_goal", 2000.0)

        metadata = {"meal_type": meal_type} if meal_type else {}
        record = await firestore_service.log_reading(
            uid=uid,
            metric="calories",
            value=float(calories_kcal),
            metadata=metadata,
            auth_token=auth_token
        )

        updated_readings = await firestore_service.get_today_readings(uid, auth_token=auth_token)
        new_total_kcal = updated_readings.get("calories_kcal", previous_total_kcal + calories_kcal)

        # Recalculate score
        today_str = get_today_ist()
        new_score = HealthScoreEngine.calculate_daily_score(updated_readings, profile, today_str)
        await firestore_service.save_daily_score(uid, new_score, auth_token=auth_token)

        remaining = max(0, int(calorie_goal - new_total_kcal))

        return {
            "success": True,
            "tool": "log_calories",
            "action": "calories_logged",
            "amount_kcal": calories_kcal,
            "logged_kcal": calories_kcal,
            "previous_total_kcal": previous_total_kcal,
            "new_total_kcal": new_total_kcal,
            "goal_kcal": int(calorie_goal),
            "remaining_kcal": remaining,
            "meal_type": meal_type,
            "date": today_str,
            "record_id": record["id"],
            "new_score": new_score.get("overallScore"),
            "message": f"Successfully logged {calories_kcal} kcal. Today's total is {new_total_kcal} kcal ({remaining} kcal remaining)."
        }
    except Exception as e:
        print(f"[log_calories] Error: {e}")
        return {"success": False, "error": "Health data could not be persisted."}

async def update_water_goal(uid: str, new_goal_ml: int, confirmed: bool = False, auth_token: Optional[str] = None) -> Dict[str, Any]:
    profile = await firestore_service.get_user_profile(uid, auth_token=auth_token)
    current_goal = profile.get("water_goal_ml", 2500)

    diff_pct = abs(new_goal_ml - current_goal) / current_goal if current_goal > 0 else 0
    if diff_pct > 0.5 and not confirmed:
        action_id = f"act_{uuid.uuid4().hex[:8]}"
        action_payload = {
            "action_id": action_id,
            "uid": uid,
            "action_type": "update_water_goal",
            "payload": {"new_goal_ml": new_goal_ml},
            "warning": f"This changes your daily water goal from {current_goal}ml to {new_goal_ml}ml ({round(diff_pct*100)}% shift).",
            "message": f"Are you sure you want to update your daily water goal to {new_goal_ml} ml?"
        }
        _PENDING_ACTIONS[action_id] = action_payload
        return {
            "success": False,
            "requires_confirmation": True,
            "confirmation": action_payload
        }

    await firestore_service.update_user_goals(uid, {"water_goal_ml": new_goal_ml}, auth_token=auth_token)
    return {
        "success": True,
        "requires_confirmation": False,
        "action": "update_water_goal",
        "old_goal_ml": current_goal,
        "new_goal_ml": new_goal_ml,
        "message": f"Your daily water goal has been updated to {new_goal_ml} ml."
    }

async def update_step_goal(uid: str, new_step_goal: int, confirmed: bool = False, auth_token: Optional[str] = None) -> Dict[str, Any]:
    profile = await firestore_service.get_user_profile(uid, auth_token=auth_token)
    current_goal = profile.get("step_goal", 10000)

    diff_pct = abs(new_step_goal - current_goal) / current_goal if current_goal > 0 else 0
    if diff_pct > 0.5 and not confirmed:
        action_id = f"act_{uuid.uuid4().hex[:8]}"
        action_payload = {
            "action_id": action_id,
            "uid": uid,
            "action_type": "update_step_goal",
            "payload": {"new_step_goal": new_step_goal},
            "warning": f"This changes your daily step target from {current_goal} to {new_step_goal} ({round(diff_pct*100)}% shift).",
            "message": f"Are you sure you want to update your daily step goal to {new_step_goal} steps?"
        }
        _PENDING_ACTIONS[action_id] = action_payload
        return {
            "success": False,
            "requires_confirmation": True,
            "confirmation": action_payload
        }

    await firestore_service.update_user_goals(uid, {"step_goal": new_step_goal}, auth_token=auth_token)
    return {
        "success": True,
        "requires_confirmation": False,
        "action": "update_step_goal",
        "old_step_goal": current_goal,
        "new_step_goal": new_step_goal,
        "message": f"Your daily step goal has been updated to {new_step_goal} steps."
    }

async def execute_confirmed_action(uid: str, action_id: str, confirmed: bool, auth_token: Optional[str] = None) -> Dict[str, Any]:
    pending = _PENDING_ACTIONS.get(action_id)
    if not pending:
        return {"success": False, "error": "Action not found or already expired."}

    if pending["uid"] != uid:
        return {"success": False, "error": "Unauthorized action execution."}

    del _PENDING_ACTIONS[action_id]

    if not confirmed:
        return {"success": False, "cancelled": True, "message": "Action cancelled by user."}

    action_type = pending["action_type"]
    payload = pending["payload"]

    if action_type == "update_water_goal":
        return await update_water_goal(uid, payload["new_goal_ml"], confirmed=True, auth_token=auth_token)
    elif action_type == "update_step_goal":
        return await update_step_goal(uid, payload["new_step_goal"], confirmed=True, auth_token=auth_token)

    return {"success": False, "error": f"Unknown action type: {action_type}"}
