import pytest
from ai_backend.services.firestore_service import firestore_service
from ai_backend.tools.health_tools import get_user_profile, get_today_readings
from ai_backend.tools.score_tools import get_daily_score, get_weekly_scores
from ai_backend.tools.analytics_tools import compare_periods, detect_trends, detect_anomalies
from ai_backend.tools.action_tools import log_water, log_calories
from ai_backend.rag.qdrant_service import rag_service

@pytest.mark.asyncio
async def test_score_tools_authoritative_retrieval():
    uid = "test_user_score"
    firestore_service.set_mock_data(
        uid,
        scores={
            "2026-09-13": {
                "date": "2026-09-13",
                "overallScore": 88,
                "components": {"sleep": 90, "hydration": 85, "activity": 89}
            }
        }
    )

    score_data = await get_daily_score(uid, date_str="2026-09-13")
    assert score_data is not None
    assert score_data["overallScore"] == 88
    assert score_data["components"]["hydration"] == 85

@pytest.mark.asyncio
async def test_action_tools_logging():
    uid = "test_user_actions"
    # Log 350 ml of water
    w_res = await log_water(uid, 350)
    assert w_res["success"] is True
    assert w_res["logged_ml"] == 350

    # Log 450 kcal
    c_res = await log_calories(uid, 450, meal_type="lunch")
    assert c_res["success"] is True
    assert c_res["logged_kcal"] == 450

    # Verify reflected in today readings
    today = await get_today_readings(uid)
    assert today["water_ml"] == 350
    assert today["calories_kcal"] == 450

@pytest.mark.asyncio
async def test_analytics_tools_anomalies():
    uid = "test_user_anomaly"
    firestore_service.set_mock_data(
        uid,
        profile={"water_goal_ml": 3000},
        readings=[
            {"metric": "water", "value": 200, "date": "2026-09-13"}, # < 25%
            {"metric": "sleep", "value": 3.0, "date": "2026-09-13"}, # < 4 hrs
        ]
    )
    anomalies = await detect_anomalies(uid)
    types = [a["type"] for a in anomalies]
    assert "dehydration_risk" in types
    assert "severe_sleep_debt" in types

@pytest.mark.asyncio
async def test_qdrant_rag_search():
    results = await rag_service.search("circadian rhythm and sleep architecture", limit=2)
    assert len(results) > 0
    assert any("sleep" in r["topic"] or "sleep" in r["title"].lower() for r in results)
