import datetime
from typing import Dict, Any, List, Optional
from ..services.firestore_service import firestore_service

async def compare_periods(uid: str, metric: str, days: int = 7) -> Dict[str, Any]:
    """
    Compares the user's average reading for a metric in the recent period (past `days` days)
    with the previous period of the same length.
    """
    recent = await firestore_service.get_reading_history(uid, metric=metric, days=days)
    previous = await firestore_service.get_reading_history(uid, metric=metric, days=days * 2)
    # Exclude recent from previous
    cutoff_recent = (datetime.date.today() - datetime.timedelta(days=days)).isoformat()
    older = [r for r in previous if r.get("date", "") < cutoff_recent]

    recent_values = [float(r.get("value", 0)) for r in recent if "value" in r]
    older_values = [float(r.get("value", 0)) for r in older if "value" in r]

    avg_recent = sum(recent_values) / len(recent_values) if recent_values else 0.0
    avg_older = sum(older_values) / len(older_values) if older_values else 0.0
    delta = avg_recent - avg_older
    pct_change = ((delta / avg_older) * 100) if avg_older > 0 else 0.0

    return {
        "metric": metric,
        "recent_period_days": days,
        "recent_average": round(avg_recent, 1),
        "previous_average": round(avg_older, 1),
        "delta": round(delta, 1),
        "percentage_change": round(pct_change, 1),
        "direction": "up" if delta > 0 else ("down" if delta < 0 else "neutral")
    }

async def detect_trends(uid: str) -> Dict[str, Any]:
    """
    Evaluates consistency across sleep, water, steps, and wellness score over the past 7 days.
    """
    scores = await firestore_service.get_weekly_scores(uid, days=7)
    water_readings = await firestore_service.get_reading_history(uid, metric="water", days=7)
    steps_readings = await firestore_service.get_reading_history(uid, metric="steps", days=7)
    sleep_readings = await firestore_service.get_reading_history(uid, metric="sleep", days=7)

    score_vals = [s.get("overallScore", 0) for s in scores if "overallScore" in s]
    score_trend = "stable"
    if len(score_vals) >= 2:
        if score_vals[-1] > score_vals[0] + 3:
            score_trend = "improving"
        elif score_vals[-1] < score_vals[0] - 3:
            score_trend = "declining"

    return {
        "score_trend": score_trend,
        "days_tracked": len(scores),
        "logged_water_days": len(set(r.get("date") for r in water_readings)),
        "logged_step_days": len(set(r.get("date") for r in steps_readings)),
        "logged_sleep_days": len(set(r.get("date") for r in sleep_readings)),
        "consistency": "high" if len(scores) >= 5 else ("moderate" if len(scores) >= 3 else "low")
    }

async def detect_anomalies(uid: str) -> List[Dict[str, Any]]:
    """
    Detects potential anomalies or critical health drop-offs in recent readings.
    """
    anomalies = []
    today = await firestore_service.get_today_readings(uid)
    profile = await firestore_service.get_user_profile(uid)

    # Low water check
    water_goal = profile.get("water_goal_ml", 2500)
    today_water = today.get("water_ml", 0)
    if today_water < (water_goal * 0.25):
        anomalies.append({
            "type": "dehydration_risk",
            "message": f"Hydration is below 25% of target ({today_water}ml / {water_goal}ml)",
            "severity": "medium"
        })

    # Very short sleep
    sleep_hours = today.get("sleep_hours")
    if sleep_hours is not None and sleep_hours < 4.0:
        anomalies.append({
            "type": "severe_sleep_debt",
            "message": f"Sleep was critically low at {sleep_hours} hours",
            "severity": "high"
        })

    # Elevated heart rate at rest
    hr = today.get("heart_rate_bpm")
    if hr is not None and hr > 105:
        anomalies.append({
            "type": "elevated_heart_rate",
            "message": f"Resting heart rate reading is elevated at {hr} bpm",
            "severity": "medium"
        })

    return anomalies
