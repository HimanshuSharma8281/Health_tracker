from typing import Dict, Any, List, Optional
from ..services.firestore_service import firestore_service

async def get_user_profile(uid: str, auth_token: Optional[str] = None) -> Dict[str, Any]:
    """
    Retrieves the user's profile and target goals (steps, water, sleep, calories).
    Strictly scoped to the authenticated uid.
    """
    return await firestore_service.get_user_profile(uid, auth_token=auth_token)

async def get_today_readings(uid: str, date_str: Optional[str] = None, auth_token: Optional[str] = None) -> Dict[str, Any]:
    """
    Retrieves the user's aggregated health readings for today or a specific date.
    Returns metrics: water_ml, steps, sleep_hours, calories_kcal, heart_rate_bpm, blood_pressure, blood_sugar_mg_dl.
    """
    return await firestore_service.get_today_readings(uid, date_str=date_str, auth_token=auth_token)

async def get_reading_history(uid: str, metric: str, days: int = 7, auth_token: Optional[str] = None) -> List[Dict[str, Any]]:
    """
    Retrieves historical log entries for a specific metric over the past N days.
    """
    return await firestore_service.get_reading_history(uid, metric=metric, days=days, auth_token=auth_token)

async def get_user_challenges(uid: str) -> List[Dict[str, Any]]:
    """
    Retrieves the list of active challenges the user is participating in.
    """
    return await firestore_service.get_user_challenges(uid)
