from typing import Dict, Any, List, Optional
from ..services.firestore_service import firestore_service, get_today_ist

async def get_daily_score(uid: str, date_str: Optional[str] = None, auth_token: Optional[str] = None) -> Dict[str, Any]:
    """
    Fetches the authoritative DailyScore for the specified date from Firestore.
    CRITICAL: Gemini NEVER calculates or invents numerical scores.
    This function returns the ground-truth score computed by HealthScoreEngine.
    If no score is found for the requested date, it returns:
        {"success": False, "date": target_date, "error_code": "NO_SCORE_FOR_DATE", "reason": "NO_SCORE_FOR_DATE"}
    NEVER silently falls back to today's score!
    """
    target_date = date_str or get_today_ist()
    return await firestore_service.get_daily_score(uid, date_str=target_date, auth_token=auth_token)

async def get_weekly_scores(uid: str, days: int = 7, auth_token: Optional[str] = None) -> List[Dict[str, Any]]:
    """
    Fetches the sequence of authoritative daily scores for the user over the past N days.
    Used for trend analysis and historical progression.
    """
    return await firestore_service.get_weekly_scores(uid, days=days, auth_token=auth_token)
