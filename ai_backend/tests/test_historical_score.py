import pytest
from unittest.mock import patch, AsyncMock
from ai_backend.tools.date_resolver import resolve_relative_date, get_today_ist, get_yesterday_ist
from ai_backend.tools.score_tools import get_daily_score
from ai_backend.agent.nodes import route_intent_node, execute_tools_node, synthesize_response_node
from ai_backend.agent.state import AuroraState

@pytest.mark.asyncio
async def test_date_resolver_yesterday():
    today = get_today_ist()
    yesterday = get_yesterday_ist()
    
    date_val, label = resolve_relative_date("What was my yesterday score?")
    assert date_val == yesterday
    assert label == "yesterday"

    date_val2, label2 = resolve_relative_date("how did I do yesterday?")
    assert date_val2 == yesterday

    date_val3, label3 = resolve_relative_date("yesterday's wellness score")
    assert date_val3 == yesterday

@pytest.mark.asyncio
async def test_route_intent_historical_score():
    state = AuroraState(
        user_id="test_user",
        user_message="What was my yesterday score?",
        original_user_message="What was my yesterday score?",
    )
    routed_state = await route_intent_node(state)
    assert routed_state.get("intent") == "score_history"
    assert routed_state.get("requested_date") == get_yesterday_ist()
    assert routed_state.get("date_label") == "yesterday"

@pytest.mark.asyncio
async def test_historical_score_execution_and_synthesis_found():
    uid = "test_user_123"
    yesterday_str = get_yesterday_ist()
    today_str = get_today_ist()

    # Mock historical score = 74, today score = 28
    hist_score_data = {
        "overallScore": 74,
        "label": "Good",
        "components": {"water": 8.0, "activity": 7.5, "sleep": 7.0, "calories": 7.0},
        "date": yesterday_str,
        "success": True,
    }

    state = AuroraState(
        user_id=uid,
        user_message="What was my yesterday score?",
        original_user_message="What was my yesterday score?",
        intent="score_history",
        requested_date=yesterday_str,
        date_label="yesterday",
        tool_results={
            "profile": {"water_goal_ml": 2500, "step_goal": 10000},
            "today_readings": {"water_ml": 1000, "steps": 2500},
            "daily_score": {"overallScore": 28, "label": "Low"},
            "historical_score": hist_score_data,
        }
    )

    # In synthesis without external LLM call (deterministic fallback):
    synthesized = await synthesize_response_node(state)
    resp = synthesized.get("final_response", "")

    # Must contain 74
    assert "74" in resp
    # Must NOT claim yesterday was 28
    assert "28" not in resp
    # Must NOT contain hallucinated May 18
    assert "May 18" not in resp

@pytest.mark.asyncio
async def test_historical_score_missing_date():
    uid = "test_user_123"
    yesterday_str = get_yesterday_ist()

    # Firestore returns NO_SCORE_FOR_DATE
    hist_score_data = {
        "success": False,
        "date": yesterday_str,
        "reason": "NO_SCORE_FOR_DATE",
        "message": f"No DailyScore recorded in Firestore for date {yesterday_str}."
    }

    state = AuroraState(
        user_id=uid,
        user_message="What was my yesterday score?",
        original_user_message="What was my yesterday score?",
        intent="score_history",
        requested_date=yesterday_str,
        date_label="yesterday",
        tool_results={
            "profile": {"water_goal_ml": 2500, "step_goal": 10000},
            "today_readings": {"water_ml": 1000, "steps": 2500},
            "daily_score": {"overallScore": 28, "label": "Low"},
            "historical_score": hist_score_data,
        }
    )

    synthesized = await synthesize_response_node(state)
    resp = synthesized.get("final_response", "")

    # Must explicitly state that no score was recorded for yesterday
    assert "I don't have a recorded Wellness Score for yesterday" in resp
    # Must NOT fall back to today's score (28)
    assert "28" not in resp
