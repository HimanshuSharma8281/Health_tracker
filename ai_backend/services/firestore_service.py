import os
import datetime
from zoneinfo import ZoneInfo
from typing import Dict, Any, List, Optional, Tuple
import firebase_admin
from firebase_admin import firestore
from ..config import settings

# Canonical IST Timezone for consistent Indian calendar date alignment
IST = ZoneInfo("Asia/Kolkata")

def get_today_ist() -> str:
    return datetime.datetime.now(IST).date().isoformat()

def get_now_ist_iso() -> str:
    return datetime.datetime.now(IST).isoformat()

class BackendFirestoreService:
    """
    Production Firestore Service using Firebase Admin SDK.
    Eliminates all silent in-memory fallbacks in production.
    Returns structured results {success, data, error_code, message}.
    Logs safe diagnostics without exposing secrets.
    """
    def __init__(self):
        self._db: Optional[firestore.firestore.Client] = None
        self._test_mode: bool = False
        self._init_error_reason: str = ""
        self._memory_store: Dict[str, Dict[str, Any]] = {}
        self._init_admin_client()

    def _init_admin_client(self):
        try:
            if firebase_admin._apps:
                self._db = firestore.client()
                self._init_error_reason = ""
            else:
                self._db = None
                self._init_error_reason = "Firebase Admin app not initialized."
        except Exception as e:
            self._db = None
            err_msg = str(e)
            if "DefaultCredentialsError" in err_msg or "credentials" in err_msg.lower():
                self._init_error_reason = "Service account credentials not found. Configure FIREBASE_SERVICE_ACCOUNT_PATH or FIREBASE_SERVICE_ACCOUNT_JSON."
            elif "permission" in err_msg.lower() or "403" in err_msg:
                self._init_error_reason = "Missing or insufficient permissions (403 PERMISSION_DENIED)."
            else:
                self._init_error_reason = f"Firestore client error: {err_msg[:100]}"

    def check_connectivity(self) -> Tuple[bool, str]:
        """
        Performs a safe connectivity check to Firestore at startup.
        Never exposes secrets or credentials.
        """
        if self._test_mode:
            return True, "Test mode active"
        if not self._db:
            return False, self._init_error_reason or "Firestore Admin client not initialized."
        try:
            # Perform a lightweight metadata probe
            _ = self._db.collection("users").limit(1).get()
            return True, "Connected to Cloud Firestore"
        except Exception as e:
            err_msg = str(e)
            if "permission" in err_msg.lower() or "403" in err_msg:
                reason = "Missing or insufficient permissions (403 PERMISSION_DENIED)."
            elif "DefaultCredentialsError" in err_msg or "credentials" in err_msg.lower():
                reason = "Service account credentials invalid or not found."
            else:
                reason = f"Firestore check error: {err_msg[:100]}"
            return False, reason

    @property
    def is_cloud_connected(self) -> bool:
        return self._db is not None

    def set_test_mode(self, enabled: bool):
        self._test_mode = enabled

    def _get_user_mem(self, uid: str) -> Dict[str, Any]:
        if uid not in self._memory_store:
            self._memory_store[uid] = {
                "profile": {
                    "uid": uid,
                    "name": "User",
                    "step_goal": 10000,
                    "water_goal_ml": 2500,
                    "calorie_goal": 2000,
                    "sleep_goal_hours": 8.0,
                    "age": 28,
                    "weight_kg": 70.0,
                    "activity_level": "moderate"
                },
                "readings": [],
                "scores": {}
            }
        return self._memory_store[uid]

    def set_mock_data(self, uid: str, profile: Optional[dict] = None, readings: Optional[list] = None, scores: Optional[dict] = None):
        user_mem = self._get_user_mem(uid)
        if profile:
            user_mem["profile"].update(profile)
        if readings is not None:
            user_mem["readings"] = list(readings)
        if scores is not None:
            user_mem["scores"] = dict(scores)

    # ─── User Profile & Goals ──────────────────────────────────────────────────
    async def get_user_profile(self, uid: str, auth_token: Optional[str] = None) -> Dict[str, Any]:
        """
        Retrieves user profile from real Firestore (users/{uid}).
        Returns structured dictionary with 'success' status.
        Never fabricates fallback data in production when database is unavailable.
        """
        if self._test_mode:
            mem = self._get_user_mem(uid)["profile"]
            return {"success": True, **mem}

        if not self._db:
            print("[Aurora] Firestore read FAILED")
            print("[Aurora] Operation: get_user_profile")
            print("[Aurora] Error type: DATABASE_UNAVAILABLE")
            print(f"[Aurora] Error message: {self._init_error_reason or 'Firestore Admin SDK is not initialized with server credentials.'}")
            return {
                "success": False,
                "error_code": "DATABASE_UNAVAILABLE",
                "message": "Firestore Admin SDK is not initialized with server credentials.",
                "uid": uid
            }

        try:
            doc = self._db.collection("users").document(uid).get()
            if doc.exists:
                print("[Aurora] Firestore profile read: SUCCESS")
                data = doc.to_dict() or {}
                data["uid"] = uid
                data["success"] = True
                return data
            else:
                print("[Aurora] Firestore read FAILED")
                print("[Aurora] Operation: get_user_profile")
                print("[Aurora] Error type: NOT_FOUND")
                print(f"[Aurora] Error message: User profile document does not exist.")
                return {
                    "success": False,
                    "error_code": "NOT_FOUND",
                    "message": f"User profile for UID {uid} does not exist in Firestore.",
                    "uid": uid
                }
        except Exception as e:
            error_str = str(e).lower()
            error_code = "FIRESTORE_PERMISSION_DENIED" if ("permission" in error_str or "403" in error_str) else "DATABASE_UNAVAILABLE"
            print("[Aurora] Firestore read FAILED")
            print("[Aurora] Operation: get_user_profile")
            print(f"[Aurora] Error type: {error_code}")
            print(f"[Aurora] Error message: {str(e)[:120]}")
            return {
                "success": False,
                "error_code": error_code,
                "message": f"Unable to retrieve profile from Firestore: {str(e)[:120]}",
                "uid": uid
            }

    async def update_user_goals(self, uid: str, updates: Dict[str, Any], auth_token: Optional[str] = None) -> Dict[str, Any]:
        """
        Updates user goal fields in users/{uid} with merge=True.
        """
        if self._test_mode:
            user_mem = self._get_user_mem(uid)
            user_mem["profile"].update(updates)
            return {"success": True, **user_mem["profile"]}

        if not self._db:
            print("[Aurora] Firestore write FAILED")
            print("[Aurora] Operation: update_user_goals")
            print("[Aurora] Error type: DATABASE_UNAVAILABLE")
            print(f"[Aurora] Error message: {self._init_error_reason or 'Firestore Admin SDK is not initialized.'}")
            return {
                "success": False,
                "error_code": "DATABASE_UNAVAILABLE",
                "message": "Firestore Admin SDK is not initialized."
            }

        try:
            self._db.collection("users").document(uid).set(updates, merge=True)
            print("[Aurora] Firestore write: SUCCESS")
            return {"success": True, **updates}
        except Exception as e:
            print("[Aurora] Firestore write FAILED")
            print("[Aurora] Operation: update_user_goals")
            print("[Aurora] Error type: FIRESTORE_WRITE_FAILED")
            print(f"[Aurora] Error message: {str(e)[:120]}")
            return {
                "success": False,
                "error_code": "FIRESTORE_WRITE_FAILED",
                "message": f"Goal updates could not be persisted to Firestore: {str(e)[:120]}"
            }

    # ─── Health Readings ───────────────────────────────────────────────────────
    async def log_reading(self, uid: str, metric: str, value: float, metadata: Optional[Dict[str, Any]] = None, auth_token: Optional[str] = None) -> Dict[str, Any]:
        """
        Persists a new reading to users/{uid}/healthReadings/{docId}.
        Strictly additive: writes a new document.
        """
        today_str = get_today_ist()
        timestamp_str = get_now_ist_iso()
        doc_id = f"log_{metric}_{datetime.datetime.now(IST).strftime('%Y%m%d%H%M%S%f')}"

        record = {
            "id": doc_id,
            "userId": uid,
            "metric": metric,
            "value": float(value),
            "date": today_str,
            "timestamp": timestamp_str,
            "metadata": metadata or {}
        }

        if self._test_mode:
            user_mem = self._get_user_mem(uid)
            user_mem["readings"].append(record)
            if metric == "water":
                print("[Aurora] Water write: SUCCESS")
            return {"success": True, **record}

        if not self._db:
            print("[Aurora] Firestore write FAILED")
            print("[Aurora] Operation: log_reading")
            print("[Aurora] Error type: DATABASE_UNAVAILABLE")
            print(f"[Aurora] Error message: {self._init_error_reason or 'Firestore Admin SDK is not initialized.'}")
            return {
                "success": False,
                "error_code": "DATABASE_UNAVAILABLE",
                "message": "Firestore Admin SDK is not initialized. Health reading could not be persisted."
            }

        try:
            self._db.collection("users").document(uid).collection("healthReadings").document(doc_id).set(record)
            print(f"[Aurora] Firestore write: SUCCESS (metric: {metric})")
            if metric == "water":
                print("[Aurora] Water write: SUCCESS")
            return {"success": True, **record}
        except Exception as e:
            print("[Aurora] Firestore write FAILED")
            print("[Aurora] Operation: log_reading")
            print("[Aurora] Error type: FIRESTORE_WRITE_FAILED")
            print(f"[Aurora] Error message: {str(e)[:120]}")
            return {
                "success": False,
                "error_code": "FIRESTORE_WRITE_FAILED",
                "message": f"Health reading could not be written to Firestore: {str(e)[:120]}"
            }

    async def get_today_readings(self, uid: str, date_str: Optional[str] = None, auth_token: Optional[str] = None) -> Dict[str, Any]:
        """
        Retrieves and aggregates readings for target_date from users/{uid}/healthReadings.
        Never fabricates zeroes when database access fails.
        """
        target_date = date_str or get_today_ist()
        result: Dict[str, Any] = {
            "date": target_date,
            "water_ml": 0,
            "steps": 0,
            "sleep_hours": None,
            "calories_kcal": 0,
            "heart_rate_bpm": None,
            "blood_pressure": None,
            "blood_sugar_mg_dl": None,
        }

        if self._test_mode:
            user_mem = self._get_user_mem(uid)
            readings_list = [r for r in user_mem["readings"] if r.get("date") == target_date]
            for r in readings_list:
                metric = r.get("metric")
                val = r.get("value", 0)
                if metric == "water":
                    result["water_ml"] += int(round(float(val)))
                elif metric == "steps":
                    result["steps"] = max(result["steps"], int(val))
                elif metric == "calories":
                    result["calories_kcal"] += int(round(float(val)))
                elif metric == "sleep":
                    result["sleep_hours"] = float(val)
                elif metric == "heart_rate":
                    result["heart_rate_bpm"] = float(val)
                elif metric == "blood_pressure":
                    sys = r.get("valueSystolic", 120)
                    dia = r.get("valueDiastolic", 80)
                    result["blood_pressure"] = f"{sys}/{dia}"
                elif metric == "blood_sugar":
                    result["blood_sugar_mg_dl"] = float(val)
            print("[Aurora] Firestore today's readings: SUCCESS")
            return {"success": True, "raw_count": len(readings_list), **result}

        if not self._db:
            print("[Aurora] Firestore read FAILED")
            print("[Aurora] Operation: get_today_readings")
            print("[Aurora] Error type: DATABASE_UNAVAILABLE")
            print(f"[Aurora] Error message: {self._init_error_reason or 'Firestore Admin SDK is not initialized with server credentials.'}")
            return {
                "success": False,
                "error_code": "DATABASE_UNAVAILABLE",
                "message": "Firestore Admin SDK is not initialized.",
                "date": target_date,
                "water_ml": None,
                "steps": None,
                "sleep_hours": None,
                "calories_kcal": None,
                "heart_rate_bpm": None,
                "blood_pressure": None,
                "blood_sugar_mg_dl": None,
                "raw_count": 0
            }

        try:
            docs = self._db.collection("users").document(uid).collection("healthReadings")\
                .where("date", "==", target_date).stream()
            readings_list = []
            for doc in docs:
                readings_list.append(doc.to_dict())

            print("[Aurora] Firestore today's readings: SUCCESS")
            for r in readings_list:
                metric = r.get("metric")
                val = r.get("value", 0)
                if metric == "water":
                    result["water_ml"] += int(round(float(val)))
                elif metric == "steps":
                    result["steps"] = max(result["steps"], int(val))
                elif metric == "calories":
                    result["calories_kcal"] += int(round(float(val)))
                elif metric == "sleep":
                    result["sleep_hours"] = float(val)
                elif metric == "heart_rate":
                    result["heart_rate_bpm"] = float(val)
                elif metric == "blood_pressure":
                    sys = r.get("valueSystolic", 120)
                    dia = r.get("valueDiastolic", 80)
                    result["blood_pressure"] = f"{sys}/{dia}"
                elif metric == "blood_sugar":
                    result["blood_sugar_mg_dl"] = float(val)

            return {"success": True, "raw_count": len(readings_list), **result}
        except Exception as e:
            error_str = str(e).lower()
            error_code = "FIRESTORE_PERMISSION_DENIED" if ("permission" in error_str or "403" in error_str) else "DATABASE_UNAVAILABLE"
            print("[Aurora] Firestore read FAILED")
            print("[Aurora] Operation: get_today_readings")
            print(f"[Aurora] Error type: {error_code}")
            print(f"[Aurora] Error message: {str(e)[:120]}")
            return {
                "success": False,
                "error_code": error_code,
                "message": f"Unable to read health readings from Firestore: {str(e)[:120]}",
                "date": target_date,
                "water_ml": None,
                "steps": None,
                "sleep_hours": None,
                "calories_kcal": None,
                "heart_rate_bpm": None,
                "blood_pressure": None,
                "blood_sugar_mg_dl": None,
                "raw_count": 0
            }

    async def get_reading_history(self, uid: str, metric: str, days: int = 7, auth_token: Optional[str] = None) -> List[Dict[str, Any]]:
        """
        Retrieves historical log entries for a metric over the past N days.
        """
        cutoff_date = (datetime.datetime.now(IST).date() - datetime.timedelta(days=days)).isoformat()
        results: List[Dict[str, Any]] = []

        if self._test_mode:
            user_mem = self._get_user_mem(uid)
            for r in user_mem["readings"]:
                if r.get("metric") == metric and r.get("date", "") >= cutoff_date:
                    results.append(r)
            results.sort(key=lambda r: r.get("date", ""))
            return results

        if not self._db:
            print("[Aurora] Firestore read FAILED")
            print("[Aurora] Operation: get_reading_history")
            print("[Aurora] Error type: DATABASE_UNAVAILABLE")
            print(f"[Aurora] Error message: {self._init_error_reason or 'Firestore Admin SDK is not initialized.'}")
            return []

        try:
            docs = self._db.collection("users").document(uid).collection("healthReadings")\
                .where("metric", "==", metric)\
                .where("date", ">=", cutoff_date).stream()
            for doc in docs:
                data = doc.to_dict()
                if data:
                    results.append(data)
            results.sort(key=lambda r: r.get("date", ""))
            return results
        except Exception as e:
            print("[Aurora] Firestore read FAILED")
            print("[Aurora] Operation: get_reading_history")
            print(f"[Aurora] Error message: {str(e)[:120]}")
            return []

    # ─── Daily Scores ──────────────────────────────────────────────────────────
    async def get_daily_score(self, uid: str, date_str: Optional[str] = None, auth_token: Optional[str] = None) -> Dict[str, Any]:
        """
        Authoritative DailyScore lookup for specified date.
        Never falls back to today's score if requested date is different.
        """
        target_date = date_str or get_today_ist()
        print("[Aurora] Tool: get_daily_score")
        print(f"[Aurora] Requested date: {target_date}")

        if self._test_mode:
            user_mem = self._get_user_mem(uid)
            score = user_mem["scores"].get(target_date)
            if score:
                print("[Aurora] Firestore score read: SUCCESS")
                overall = score.get("overallScore", score.get("overall", 0))
                return {
                    "success": True,
                    "date": target_date,
                    "overall": overall,
                    "overallScore": overall,
                    "label": score.get("label", "Good"),
                    "components": score.get("components", {}),
                    "metrics": score.get("metrics", {}),
                    "availableMetricCount": score.get("availableMetricCount", len(score.get("components", {})))
                }
            return {
                "success": False,
                "error_code": "NO_SCORE_FOR_DATE",
                "reason": "NO_SCORE_FOR_DATE",
                "date": target_date,
                "message": f"No wellness score recorded for date {target_date}."
            }

        if not self._db:
            print("[Aurora] Firestore read FAILED")
            print("[Aurora] Operation: get_daily_score")
            print("[Aurora] Error type: DATABASE_UNAVAILABLE")
            print(f"[Aurora] Error message: {self._init_error_reason or 'Firestore Admin SDK is not initialized with server credentials.'}")
            return {
                "success": False,
                "error_code": "DATABASE_UNAVAILABLE",
                "message": "Firestore Admin SDK is not initialized.",
                "date": target_date
            }

        try:
            doc = self._db.collection("users").document(uid).collection("dailyScores").document(target_date).get()
            if doc.exists:
                print("[Aurora] Firestore score read: SUCCESS")
                data = doc.to_dict() or {}
                overall = data.get("overallScore", data.get("overall", 0))
                return {
                    "success": True,
                    "date": target_date,
                    "overall": overall,
                    "overallScore": overall,
                    "label": data.get("label", "Good"),
                    "components": data.get("components", {}),
                    "metrics": data.get("metrics", {}),
                    "availableMetricCount": data.get("availableMetricCount", len(data.get("components", {})))
                }
            else:
                return {
                    "success": False,
                    "error_code": "NO_SCORE_FOR_DATE",
                    "reason": "NO_SCORE_FOR_DATE",
                    "date": target_date,
                    "message": f"No wellness score recorded for date {target_date}."
                }
        except Exception as e:
            error_str = str(e).lower()
            error_code = "FIRESTORE_PERMISSION_DENIED" if ("permission" in error_str or "403" in error_str) else "DATABASE_UNAVAILABLE"
            print("[Aurora] Firestore read FAILED")
            print("[Aurora] Operation: get_daily_score")
            print(f"[Aurora] Error type: {error_code}")
            print(f"[Aurora] Error message: {str(e)[:120]}")
            return {
                "success": False,
                "error_code": error_code,
                "message": f"Unable to read score from Firestore: {str(e)[:120]}",
                "date": target_date
            }

    async def save_daily_score(self, uid: str, score_data: Dict[str, Any], auth_token: Optional[str] = None) -> bool:
        target_date = score_data.get("date") or get_today_ist()

        if self._test_mode:
            user_mem = self._get_user_mem(uid)
            user_mem["scores"][target_date] = score_data
            return True

        if not self._db:
            print("[Aurora] Firestore write FAILED")
            print("[Aurora] Operation: save_daily_score")
            print("[Aurora] Error type: DATABASE_UNAVAILABLE")
            print(f"[Aurora] Error message: {self._init_error_reason or 'Firestore Admin SDK is not initialized.'}")
            return False

        try:
            self._db.collection("users").document(uid).collection("dailyScores").document(target_date).set(score_data)
            print("[Aurora] Daily score recalculated: SUCCESS")
            return True
        except Exception as e:
            print("[Aurora] Firestore write FAILED")
            print("[Aurora] Operation: save_daily_score")
            print(f"[Aurora] Error message: {str(e)[:120]}")
            return False

    async def get_weekly_scores(self, uid: str, days: int = 7, auth_token: Optional[str] = None) -> List[Dict[str, Any]]:
        cutoff_date = (datetime.datetime.now(IST).date() - datetime.timedelta(days=days)).isoformat()
        scores: List[Dict[str, Any]] = []

        if self._test_mode:
            user_mem = self._get_user_mem(uid)
            for d, s in user_mem["scores"].items():
                if d >= cutoff_date:
                    scores.append(s)
            scores.sort(key=lambda s: s.get("date", ""))
            return scores

        if not self._db:
            return []

        try:
            docs = self._db.collection("users").document(uid).collection("dailyScores")\
                .where("date", ">=", cutoff_date).stream()
            for doc in docs:
                data = doc.to_dict()
                if data:
                    scores.append(data)
            scores.sort(key=lambda s: s.get("date", ""))
            return scores
        except Exception as e:
            print("[Aurora] Firestore read FAILED")
            print("[Aurora] Operation: get_weekly_scores")
            print(f"[Aurora] Error message: {str(e)[:120]}")
            return []

    async def get_user_challenges(self, uid: str) -> List[Dict[str, Any]]:
        if self._test_mode:
            return []

        if not self._db:
            return []

        try:
            docs = self._db.collection("challenges").where("participants", "array_contains", uid).stream()
            return [d.to_dict() for d in docs]
        except Exception as e:
            print("[Aurora] Firestore read FAILED")
            print("[Aurora] Operation: get_user_challenges")
            print(f"[Aurora] Error message: {str(e)[:120]}")
            return []

firestore_service = BackendFirestoreService()
