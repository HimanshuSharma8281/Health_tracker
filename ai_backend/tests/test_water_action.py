import pytest
import datetime
from unittest.mock import patch
from ai_backend.services.firestore_service import firestore_service, get_today_ist
from ai_backend.services.health_score_engine import HealthScoreEngine
from ai_backend.tools.action_tools import log_water, extract_water_amount_ml
from ai_backend.agent.aurora_graph import aurora_app

@pytest.fixture(autouse=True)
def setup_test_env():
    # Enable test mode for in-memory isolated testing in pytest
    firestore_service.set_test_mode(True)
    firestore_service._memory_store.clear()
    yield
    firestore_service.set_test_mode(False)

@pytest.mark.asyncio
async def test_1_water_addition():
    """TEST 1 — WATER ADDITION: 1000 ml + 500 ml = 1500 ml"""
    uid = "test_user_1"
    today_str = get_today_ist()
    # Initial state: 1000 ml (e.g. two earlier events: 600 + 400)
    await firestore_service.log_reading(uid, metric="water", value=600.0)
    await firestore_service.log_reading(uid, metric="water", value=400.0)

    # User says: "I drank 500 ml of water"
    extracted = extract_water_amount_ml("I drank 500 ml of water")
    assert extracted == 500

    result = await log_water(uid, extracted)
    assert result["success"] is True
    assert result["amount_ml"] == 500
    assert result["previous_total_ml"] == 1000
    assert result["new_total_ml"] == 1500
    assert result["goal_ml"] == 2500
    assert result["remaining_ml"] == 1000
    assert result["percentage"] == 60

    # Verify Firestore aggregate
    readings = await firestore_service.get_today_readings(uid)
    assert readings["water_ml"] == 1500

@pytest.mark.asyncio
async def test_2_multiple_water_events():
    """TEST 2 — MULTIPLE WATER EVENTS: 1000 + 500 + 300 = 1800 ml (additive, not overwritten)"""
    uid = "test_user_2"
    await firestore_service.log_reading(uid, metric="water", value=1000.0)

    # Log 500 ml
    res1 = await log_water(uid, 500)
    assert res1["new_total_ml"] == 1500

    # Log 300 ml
    res2 = await log_water(uid, 300)
    assert res2["previous_total_ml"] == 1500
    assert res2["new_total_ml"] == 1800
    assert res2["remaining_ml"] == 700

    # Check that individual events are preserved
    user_readings = [r for r in firestore_service._memory_store[uid]["readings"] if r["metric"] == "water"]
    assert len(user_readings) == 3
    assert [r["value"] for r in user_readings] == [1000.0, 500.0, 300.0]

@pytest.mark.asyncio
async def test_3_persistence():
    """TEST 3 — PERSISTENCE: Simulate restarting or fresh service read"""
    uid = "test_user_3"
    await firestore_service.log_reading(uid, metric="water", value=1000.0)
    await log_water(uid, 500)

    # Simulate fresh reading query
    readings = await firestore_service.get_today_readings(uid)
    assert readings["water_ml"] == 1500

@pytest.mark.asyncio
async def test_4_uid_isolation():
    """TEST 4 — UID ISOLATION: User A logs 500 ml; User B must NOT see it"""
    uid_a = "user_alpha"
    uid_b = "user_beta"

    await log_water(uid_a, 500)

    readings_b = await firestore_service.get_today_readings(uid_b)
    assert readings_b["water_ml"] == 0

    readings_a = await firestore_service.get_today_readings(uid_a)
    assert readings_a["water_ml"] == 500

@pytest.mark.asyncio
async def test_5_invalid_water():
    """TEST 5 — INVALID WATER: 500000 ml, -500 ml, 0 ml must be rejected"""
    assert extract_water_amount_ml("I drank 500000 ml") is None
    assert extract_water_amount_ml("I drank -500 ml") is None
    assert extract_water_amount_ml("I drank 0 ml") is None

    res_huge = await log_water("test_uid", 500000)
    assert res_huge["success"] is False

    res_zero = await log_water("test_uid", 0)
    assert res_zero["success"] is False

    res_neg = await log_water("test_uid", -500)
    assert res_neg["success"] is False

@pytest.mark.asyncio
async def test_6_different_questions():
    """TEST 6 — DIFFERENT QUESTIONS: Distinct intents and focused responses"""
    questions = [
        ("How is my hydration today?", "hydration_query"),
        ("How did I sleep?", "sleep_query"),
        ("How many steps have I taken today?", "steps_query"),
        ("Why did my wellness score change today?", "score_analysis"),
        ("Analyze my heart rate today.", "heart_rate_query"),
        ("What is my progress this week?", "weekly_progress_query"),
        ("I have some calories left, make me a healthy dinner plan", "meal_planning"),
    ]

    for q, expected_intent in questions:
        state = {
            "user_id": "test_user_q",
            "uid": "test_user_q",
            "original_user_message": q,
            "user_message": q,
            "history": [],
            "tool_calls": [],
            "tools_called": [],
            "tool_results": {},
            "retrieved_documents": [],
            "rag_docs": [],
            "current_health_data": {},
            "final_response": "",
            "errors": [],
            "sources": []
        }
        res = await aurora_app.ainvoke(state)
        assert res["intent"] == expected_intent
        assert len(res["final_response"]) > 0
        # Make sure responses are distinct and pertinent to the question
        if expected_intent == "hydration_query":
            assert any(w in res["final_response"].lower() for w in ["hydration", "water", "ml"])
        elif expected_intent == "steps_query":
            assert any(w in res["final_response"].lower() for w in ["step", "activity"])
        elif expected_intent == "sleep_query":
            assert any(w in res["final_response"].lower() for w in ["sleep", "hours"])
        elif expected_intent == "heart_rate_query":
            assert any(w in res["final_response"].lower() for w in ["heart rate", "bpm", "pulse"])

@pytest.mark.asyncio
async def test_7_action_plus_question():
    """TEST 7 — ACTION + QUESTION: 'I drank 500 ml of water. How much more do I need today?'"""
    uid = "test_user_action_q"
    await firestore_service.log_reading(uid, metric="water", value=1000.0)

    state = {
        "user_id": uid,
        "uid": uid,
        "original_user_message": "I drank 500 ml of water. How much more do I need today?",
        "user_message": "I drank 500 ml of water. How much more do I need today?",
        "history": [],
        "tool_calls": [],
        "tools_called": [],
        "tool_results": {},
        "retrieved_documents": [],
        "rag_docs": [],
        "current_health_data": {},
        "final_response": "",
        "errors": [],
        "sources": []
    }
    res = await aurora_app.ainvoke(state)
    assert res["intent"] == "action_log_water"
    assert res["executed_action"] is not None
    action = res["executed_action"]
    assert action["amount_ml"] == 500
    assert action["previous_total_ml"] == 1000
    assert action["new_total_ml"] == 1500
    assert action["goal_ml"] == 2500
    assert action["remaining_ml"] == 1000

@pytest.mark.asyncio
async def test_8_backend_success_payload():
    """TEST 8 — BACKEND SUCCESS: Structured executed_action returned for Flutter consumption"""
    uid = "test_user_flutter"
    await firestore_service.log_reading(uid, metric="water", value=1000.0)
    state = {
        "user_id": uid,
        "uid": uid,
        "original_user_message": "I drank 500 ml of water",
        "user_message": "I drank 500 ml of water",
        "history": [],
        "tool_calls": [],
        "tools_called": [],
        "tool_results": {},
        "retrieved_documents": [],
        "rag_docs": [],
        "current_health_data": {},
        "final_response": "",
        "errors": [],
        "sources": []
    }
    res = await aurora_app.ainvoke(state)
    assert res["executed_action"] is not None
    assert res["executed_action"]["success"] is True
    assert "1,500" in res["final_response"] or "1500" in res["final_response"]

@pytest.mark.asyncio
async def test_9_firestore_failure():
    """TEST 9 — FIRESTORE FAILURE: Fails clearly if Firestore cannot persist"""
    uid = "test_user_fail"
    firestore_service.set_test_mode(False) # Turn off test bypass to test error handling

    with patch.object(firestore_service, "log_reading", side_effect=RuntimeError("Firestore connection refused")):
        res = await log_water(uid, 500)
        assert res["success"] is False
        assert "Health data could not be persisted" in res["error"]

@pytest.mark.asyncio
async def test_10_score_protection():
    """TEST 10 — SCORE PROTECTION: Only HealthScoreEngine determines scores deterministically"""
    profile = {
        "weight_kg": 70.0,
        "activity_level": "sedentary",
        "step_goal": 10000,
        "calorie_goal": 2000.0,
        "age": 28
    }
    readings = {
        "water_ml": 2500,
        "steps": 10000,
        "sleep_hours": 8.0,
        "calories_kcal": 2000,
        "heart_rate_bpm": 70
    }

    score_result = HealthScoreEngine.calculate_daily_score(readings, profile, get_today_ist())
    assert score_result["overallScore"] == 100
    assert score_result["label"] == "Excellent"

    # Same input MUST produce exact same output every single time (zero hallucination)
    repeat_result = HealthScoreEngine.calculate_daily_score(readings, profile, get_today_ist())
    assert repeat_result["overallScore"] == score_result["overallScore"]
    assert repeat_result["components"] == score_result["components"]
