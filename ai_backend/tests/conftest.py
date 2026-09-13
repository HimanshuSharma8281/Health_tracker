import pytest
from ai_backend.services.firestore_service import firestore_service

@pytest.fixture(autouse=True)
def setup_test_env():
    # Enable test mode for in-memory isolated testing across all pytest tests
    firestore_service.set_test_mode(True)
    firestore_service._memory_store.clear()
    yield
    firestore_service.set_test_mode(False)
