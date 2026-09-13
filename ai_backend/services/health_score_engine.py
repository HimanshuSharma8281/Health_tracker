import math
import datetime
from typing import Dict, Any, Optional

class MetricKeys:
    HEART_RATE = "heart_rate"
    BLOOD_PRESSURE = "blood_pressure"
    SLEEP = "sleep"
    WATER = "water"
    CALORIES = "calories"
    ACTIVITY = "activity"

def get_activity_multiplier(activity_level: Optional[str]) -> float:
    level = (activity_level or "moderate").lower()
    if level == "sedentary":
        return 1.0
    elif level == "light":
        return 1.1
    elif level == "moderate":
        return 1.2
    elif level == "active":
        return 1.3
    elif level in ["very_active", "very active", "extreme"]:
        return 1.4
    return 1.2

def calculate_hydration_score(
    water_ml: Optional[int],
    weight_kg: Optional[float] = 70.0,
    activity_level: Optional[str] = "moderate"
) -> Dict[str, Any]:
    if water_ml is None or water_ml <= 0:
        return {"metric": MetricKeys.WATER, "score": 0, "available": False, "reading": 0, "target": "2500ml", "reason": "No water logged today"}

    weight = weight_kg if (weight_kg and weight_kg > 0) else 70.0
    multiplier = get_activity_multiplier(activity_level)
    target_ml = round(weight * 35.0 * multiplier)
    pct = water_ml / target_ml if target_ml > 0 else 0

    if pct >= 1.0:
        score = 10
        reason = f"{water_ml}ml — met/exceeded target of {target_ml}ml"
    elif pct >= 0.9:
        score = 9
        reason = f"{water_ml}ml — 90%+ of {target_ml}ml target"
    elif pct >= 0.75:
        score = 7
        reason = f"{water_ml}ml — 75–90% of {target_ml}ml target"
    elif pct >= 0.6:
        score = 5
        reason = f"{water_ml}ml — 60–75% of {target_ml}ml target"
    elif pct >= 0.4:
        score = 3
        reason = f"{water_ml}ml — 40–60% of {target_ml}ml target"
    else:
        score = 1
        reason = f"{water_ml}ml — below 40% of {target_ml}ml target"

    return {
        "metric": MetricKeys.WATER,
        "score": score,
        "available": True,
        "reading": water_ml,
        "target": f"{target_ml}ml",
        "reason": reason
    }

def calculate_activity_score(steps: Optional[int], step_goal: int = 10000) -> Dict[str, Any]:
    if steps is None or steps <= 0:
        return {"metric": MetricKeys.ACTIVITY, "score": 0, "available": False, "reading": 0, "target": f"{step_goal} steps", "reason": "No steps recorded today"}

    goal = step_goal if step_goal > 0 else 10000
    pct = steps / goal

    if pct >= 1.0:
        score = 10
        reason = f"{steps} steps — goal achieved ({round(pct*100)}%)"
    elif pct >= 0.8:
        score = 9
        reason = f"{steps} steps — near goal ({round(pct*100)}%)"
    elif pct >= 0.6:
        score = 7
        reason = f"{steps} steps — moderate activity ({round(pct*100)}%)"
    elif pct >= 0.4:
        score = 5
        reason = f"{steps} steps — fair activity ({round(pct*100)}%)"
    elif pct >= 0.2:
        score = 3
        reason = f"{steps} steps — low activity ({round(pct*100)}%)"
    else:
        score = 1
        reason = f"{steps} steps — very low activity"

    return {
        "metric": MetricKeys.ACTIVITY,
        "score": score,
        "available": True,
        "reading": steps,
        "target": f"{goal} steps",
        "reason": reason
    }

def calculate_sleep_score(hours: Optional[float], age: Optional[int] = 28) -> Dict[str, Any]:
    if hours is None or hours <= 0:
        return {"metric": MetricKeys.SLEEP, "score": 0, "available": False, "reading": 0, "target": "7–9 hours", "reason": "No sleep recorded"}

    user_age = age or 28
    if user_age >= 65:
        min_target, max_target = 7.0, 8.0
    elif user_age < 18:
        min_target, max_target = 8.0, 10.0
    else:
        min_target, max_target = 7.0, 9.0

    target_str = f"{int(min_target)}–{int(max_target)} hours"
    if min_target <= hours <= max_target:
        score = 10
        reason = f"{hours:.1f}h — within recommended {target_str}"
    elif abs(hours - (min_target + max_target) / 2) <= 0.5:
        score = 8
        reason = f"{hours:.1f}h — slightly outside {target_str}"
    elif abs(hours - (min_target + max_target) / 2) <= 1.0:
        score = 6
        reason = f"{hours:.1f}h — moderately outside {target_str}"
    elif abs(hours - (min_target + max_target) / 2) <= 1.5:
        score = 4
        reason = f"{hours:.1f}h — significantly outside {target_str}"
    elif hours < 5 or hours > 12:
        score = 2
        reason = f"{hours:.1f}h — very far from {target_str}"
    else:
        score = 3
        reason = f"{hours:.1f}h — outside {target_str}"

    return {
        "metric": MetricKeys.SLEEP,
        "score": score,
        "available": True,
        "reading": hours,
        "target": target_str,
        "reason": reason
    }

def calculate_heart_rate_score(bpm: Optional[float], age: Optional[int] = 28) -> Dict[str, Any]:
    if bpm is None or bpm <= 0:
        return {"metric": MetricKeys.HEART_RATE, "score": 0, "available": False, "reading": 0, "target": "60–100 bpm", "reason": "No heart rate recorded"}

    if 60 <= bpm <= 80:
        score = 10
        reason = f"{round(bpm)} bpm — optimal resting heart rate"
    elif 80 < bpm <= 90:
        score = 8
        reason = f"{round(bpm)} bpm — normal resting heart rate"
    elif 50 <= bpm < 60:
        score = 9
        reason = f"{round(bpm)} bpm — athletic resting heart rate"
    elif 90 < bpm <= 100:
        score = 6
        reason = f"{round(bpm)} bpm — elevated resting heart rate"
    elif bpm > 100:
        score = 4
        reason = f"{round(bpm)} bpm — tachycardia range (high)"
    else:
        score = 5
        reason = f"{round(bpm)} bpm — bradycardia range (low)"

    return {
        "metric": MetricKeys.HEART_RATE,
        "score": score,
        "available": True,
        "reading": bpm,
        "target": "60–100 bpm",
        "reason": reason
    }

def calculate_blood_pressure_score(systolic: Optional[int], diastolic: Optional[int]) -> Dict[str, Any]:
    if systolic is None or diastolic is None or systolic <= 0 or diastolic <= 0:
        return {"metric": MetricKeys.BLOOD_PRESSURE, "score": 0, "available": False, "reading": 0, "target": "<120/<80 mmHg", "reason": "No blood pressure recorded"}

    if systolic < 120 and diastolic < 80:
        score = 10
        reason = f"{systolic}/{diastolic} mmHg — optimal"
    elif systolic <= 129 and diastolic < 80:
        score = 8
        reason = f"{systolic}/{diastolic} mmHg — elevated"
    elif systolic <= 139 or diastolic <= 89:
        score = 6
        reason = f"{systolic}/{diastolic} mmHg — stage 1 hypertension"
    elif systolic <= 179 or diastolic <= 119:
        score = 4
        reason = f"{systolic}/{diastolic} mmHg — stage 2 hypertension"
    else:
        score = 2
        reason = f"{systolic}/{diastolic} mmHg — hypertensive crisis"

    return {
        "metric": MetricKeys.BLOOD_PRESSURE,
        "score": score,
        "available": True,
        "reading": f"{systolic}/{diastolic}",
        "target": "<120/<80 mmHg",
        "reason": reason
    }

def calculate_calorie_score(consumed: Optional[float], calorie_goal: float = 2000.0) -> Dict[str, Any]:
    if consumed is None or consumed <= 0:
        return {"metric": MetricKeys.CALORIES, "score": 0, "available": False, "reading": 0, "target": f"{int(calorie_goal)} kcal", "reason": "No calories logged today"}

    goal = calorie_goal if calorie_goal > 0 else 2000.0
    pct = consumed / goal

    if 0.85 <= pct <= 1.1:
        score = 10
        reason = f"{int(consumed)} kcal — on target with daily budget"
    elif (0.75 <= pct < 0.85) or (1.1 < pct <= 1.25):
        score = 8
        reason = f"{int(consumed)} kcal — slightly off calorie budget"
    elif (0.60 <= pct < 0.75) or (1.25 < pct <= 1.4):
        score = 6
        reason = f"{int(consumed)} kcal — moderately off calorie budget"
    else:
        score = 4
        reason = f"{int(consumed)} kcal — significantly off target"

    return {
        "metric": MetricKeys.CALORIES,
        "score": score,
        "available": True,
        "reading": consumed,
        "target": f"{int(goal)} kcal",
        "reason": reason
    }

class HealthScoreEngine:
    @staticmethod
    def calculate_daily_score(
        readings: Dict[str, Any],
        profile: Dict[str, Any],
        date_str: str
    ) -> Dict[str, Any]:
        """
        DETERMINISTIC scoring engine identical to the Flutter HealthScoreEngine.
        GEMINI MUST NEVER CALCULATE OR INVENT THIS SCORE.
        """
        weight_kg = profile.get("weight_kg") or 70.0
        activity_level = profile.get("activity_level") or "moderate"
        step_goal = profile.get("step_goal") or 10000
        calorie_goal = profile.get("calorie_goal") or 2000.0
        age = profile.get("age") or 28

        metrics = {
            MetricKeys.WATER: calculate_hydration_score(
                water_ml=readings.get("water_ml"),
                weight_kg=weight_kg,
                activity_level=activity_level
            ),
            MetricKeys.ACTIVITY: calculate_activity_score(
                steps=readings.get("steps"),
                step_goal=step_goal
            ),
            MetricKeys.SLEEP: calculate_sleep_score(
                hours=readings.get("sleep_hours"),
                age=age
            ),
            MetricKeys.CALORIES: calculate_calorie_score(
                consumed=readings.get("calories_kcal"),
                calorie_goal=calorie_goal
            ),
            MetricKeys.HEART_RATE: calculate_heart_rate_score(
                bpm=readings.get("heart_rate_bpm"),
                age=age
            ),
        }

        # Parse blood pressure if present
        bp_str = readings.get("blood_pressure")
        if bp_str and "/" in str(bp_str):
            try:
                parts = str(bp_str).split("/")
                metrics[MetricKeys.BLOOD_PRESSURE] = calculate_blood_pressure_score(
                    systolic=int(parts[0]),
                    diastolic=int(parts[1])
                )
            except Exception:
                pass

        weighted_sum = 0.0
        weight_total = 0.0

        for key, m in metrics.items():
            if m.get("available", False):
                weighted_sum += m.get("score", 0) * 1.0
                weight_total += 1.0

        if weight_total == 0:
            overall = 0
        else:
            overall = int(round((weighted_sum / weight_total) * 10.0))
            overall = max(0, min(100, overall))

        if overall >= 90:
            label = "Excellent"
        elif overall >= 75:
            label = "Good"
        elif overall >= 60:
            label = "Fair"
        elif overall >= 40:
            label = "Needs Attention"
        else:
            label = "Poor"

        components = {k: v.get("score", 0) for k, v in metrics.items() if v.get("available")}

        return {
            "date": date_str,
            "overallScore": overall,
            "label": label,
            "components": components,
            "metrics": metrics,
            "scoredAt": datetime.datetime.now().isoformat(),
            "availableMetricCount": int(weight_total)
        }
