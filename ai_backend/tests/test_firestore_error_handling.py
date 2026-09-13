import pytest
from ai_backend.services.firestore_service import firestore_service, get_today_ist
from ai_backend.tools.date_resolver import get_yesterday_ist
from ai_backend.tools.score_tools import get_daily_score
from ai_backend.tools.action_tools import log_water
from ai_backend.agent.aurora_graph import aurora_app

@pytest.fixture(autouse=True)
def cleanup():
    firestore_service.set_test_mode(False)
    firestore_service._memory_store.clear()
    yield
    firestore_service.set_test_mode(False)
    firestore_service._memory_store.clear()

@pytest.mark.asyncio
async def test_get_user_profile_distinguishes_errors():
    """Verify get_user_profile returns structured error and never silent default profile."""
    # When Admin SDK is not initialized, returns DATABASE_UNAVAILABLE
    firestore_service.set_test_mode(False)
    profile = await firestore_service.get_user_profile("non_existent_uid")
    assert profile["success"] is False
    assert profile["error_code"] in ["DATABASE_UNAVAILABLE", "NOT_FOUND", "FIRESTORE_PERMISSION_DENIED"]

@pytest.mark.asyncio
async def test_get_today_readings_never_fabricates_zeroes_on_error():
    """Verify get_today_readings returns success=False and does not fabricate 0s."""
    firestore_service.set_test_mode(False)
    readings = await firestore_service.get_today_readings("test_uid")
    if not firestore_service.is_cloud_connected:
        assert readings["success"] is False
        assert readings["error_code"] in ["DATABASE_UNAVAILABLE", "FIRESTORE_PERMISSION_DENIED"]
        assert readings["water_ml"] is None
        assert readings["steps"] is None

@pytest.mark.asyncio
async def test_historical_score_returns_no_score_and_never_falls_back_to_today():
    """Verify requesting yesterday score queries yesterday's date and returns NO_SCORE_FOR_DATE."""
    firestore_service.set_test_mode(True)
    uid = "test_user_hist"
    today_str = get_today_ist()
    yesterday_str = get_yesterday_ist()

    # Set today's score to 28
    firestore_service.set_mock_data(
        uid,
        scores={today_str: {"overallScore": 28, "label": "Needs Attention", "date": today_str}}
    )

    # Query yesterday score (which does not exist)
    score = await get_daily_score(uid, date_str=yesterday_str)
    assert score["success"] is False
    assert score["error_code"] == "NO_SCORE_FOR_DATE"
    assert score["date"] == yesterday_str
    # Must NOT return today's score of 28
    assert score.get("overallScore") is None or score.get("overallScore") != 28

@pytest.mark.asyncio
async def test_historical_score_returns_exact_yesterday_score_when_present():
    """Verify requesting yesterday score returns yesterday's exact score (74, not today's 28)."""
    firestore_service.set_test_mode(True)
    uid = "test_user_hist_2"
    today_str = get_today_ist()
    yesterday_str = get_yesterday_ist()

    # Set yesterday score = 74, today score = 28
    firestore_service.set_mock_data(
        uid,
        scores={
            yesterday_str: {"overallScore": 74, "label": "Good", "date": yesterday_str},
            today_str: {"overallScore": 28, "label": "Needs Attention", "date": today_str}
        }
    )

    score = await get_daily_score(uid, date_str=yesterday_str)
    assert score["success"] is True
    assert score["overallScore"] == 74
    assert score["date"] == yesterday_str

@pytest.mark.asyncio
async def test_water_action_additive_persistence_and_verification():
    """Verify logging 500 ml when previous is 1000 ml results in verified total 1500 ml."""
    firestore_service.set_test_mode(True)
    uid = "test_user_water"

    # Set initial water = 1000 ml
    await firestore_service.log_reading(uid, metric="water", value=1000.0)
    initial_readings = await firestore_service.get_today_readings(uid)
    assert initial_readings["water_ml"] == 1000

    # Execute water logging action
    result = await log_water(uid, 500)
    assert result["success"] is True
    assert result["previous_total_ml"] == 1000
    assert result["amount_ml"] == 500
    assert result["new_total_ml"] == 1500

    # Re-read to ensure persistence
    updated = await firestore_service.get_today_readings(uid)
    assert updated["water_ml"] == 1500

@pytest.mark.asyncio
async def test_agent_graph_database_failure_guard():
    """Verify that when Firestore is unavailable, agent returns clear safe failure without hallucinating zeroes."""
    firestore_service.set_test_mode(False)
    if not firestore_service.is_cloud_connected:
        state = {
            "user_id": "test_unconnected_user",
            "uid": "test_unconnected_user",
            "original_user_message": "How is my hydration today?",
            "user_message": "How is my hydration today?",
            "history": [],
            "client_snapshot": None,
            "intent": None,
            "tool_calls": [],
            "tools_called": [],
            "tool_results": {},
            "retrieved_documents": [],
            "rag_docs": [],
            "current_health_data": {},
            "pending_action": None,
            "executed_action": None,
            "final_response": "",
            "sources": [],
            "errors": []
        }
        res = await aurora_app.ainvoke(state)
        # Must return safe failure message, NOT pretending user drank 0 ml
        assert "couldn't retrieve your health data" in res["final_response"].lower() or "action failed" in res["final_response"].lower()
