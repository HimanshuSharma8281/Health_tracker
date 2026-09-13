import pytest
from ai_backend.services.firestore_service import firestore_service
from ai_backend.tools.health_tools import get_user_profile, get_today_readings
from ai_backend.tools.action_tools import update_water_goal, execute_confirmed_action

@pytest.mark.asyncio
async def test_multi_user_data_isolation():
    user_a = "user_alpha_123"
    user_b = "user_beta_456"

    # Seed different data for User A and User B
    firestore_service.set_mock_data(
        user_a,
        profile={"name": "Alice", "water_goal_ml": 2200, "step_goal": 8000},
        readings=[{"metric": "water", "value": 1500, "date": "2026-09-13"}]
    )

    firestore_service.set_mock_data(
        user_b,
        profile={"name": "Bob", "water_goal_ml": 3500, "step_goal": 15000},
        readings=[{"metric": "water", "value": 500, "date": "2026-09-13"}]
    )

    # Verify User A queries return only User A data
    prof_a = await get_user_profile(user_a)
    read_a = await get_today_readings(user_a, date_str="2026-09-13")
    assert prof_a["name"] == "Alice"
    assert prof_a["water_goal_ml"] == 2200
    assert read_a["water_ml"] == 1500

    # Verify User B queries return only User B data
    prof_b = await get_user_profile(user_b)
    read_b = await get_today_readings(user_b, date_str="2026-09-13")
    assert prof_b["name"] == "Bob"
    assert prof_b["water_goal_ml"] == 3500
    assert read_b["water_ml"] == 500

@pytest.mark.asyncio
async def test_action_authorization_check():
    user_a = "user_alpha_123"
    user_b = "user_beta_456"

    # User A initiates a drastic change requiring confirmation
    res = await update_water_goal(user_a, 5000)
    assert res["requires_confirmation"] is True
    action_id = res["confirmation"]["action_id"]

    # User B attempts to hijack and execute User A's pending action
    hijack_res = await execute_confirmed_action(user_b, action_id, confirmed=True)
    assert hijack_res["success"] is False
    assert "Unauthorized" in hijack_res["error"]

    # User A successfully confirms their own action
    legit_res = await execute_confirmed_action(user_a, action_id, confirmed=True)
    assert legit_res["success"] is True
    assert legit_res["new_goal_ml"] == 5000
