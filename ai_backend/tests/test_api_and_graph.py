import pytest
from httpx import AsyncClient, ASGITransport
from ai_backend.main import app

@pytest.mark.asyncio
async def test_health_endpoint():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        res = await client.get("/health")
        assert res.status_code == 200
        data = res.json()
        assert data["status"] == "healthy"
        assert data["service"] == "aurora-health-backend"

@pytest.mark.asyncio
async def test_chat_endpoint_agent_workflow():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        payload = {
            "message": "I just drank 400 ml of water",
            "history": []
        }
        headers = {"Authorization": "Bearer dev_test_user_789"}
        res = await client.post("/api/v1/chat", json=payload, headers=headers)
        assert res.status_code == 200
        data = res.json()
        assert "response" in data
        assert "log_water" in data.get("tools_called", [])
        assert data["executed_action"] is not None
        assert data["executed_action"]["logged_ml"] == 400

@pytest.mark.asyncio
async def test_chat_endpoint_score_query():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        payload = {
            "message": "What is my wellness score today?",
            "history": []
        }
        headers = {"Authorization": "Bearer dev_test_user_789"}
        res = await client.post("/api/v1/chat", json=payload, headers=headers)
        assert res.status_code == 200
        data = res.json()
        assert "response" in data
        assert "get_daily_score" in data.get("tools_called", [])
