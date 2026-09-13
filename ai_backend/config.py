import os
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    GEMINI_API_KEY: str = ""
    GEMINI_MODEL: str = "gemini-flash-lite-latest"
    GEMINI_EMBEDDING_MODEL: str = "models/gemini-embedding-001"



    FIREBASE_PROJECT_ID: str = "healthtracker-e3acf"
    FIREBASE_SERVICE_ACCOUNT_PATH: str = ""
    FIREBASE_SERVICE_ACCOUNT_JSON: str = ""
    FIREBASE_SERVICE_ACCOUNT_BASE64: str = ""
    DEV_AUTH_BYPASS: bool = True

    QDRANT_STORAGE_PATH: str = "./data/qdrant_db"
    QDRANT_URL: str = ""

    HOST: str = "0.0.0.0"
    PORT: int = 8000

    model_config = SettingsConfigDict(
        env_file=os.path.join(os.path.dirname(__file__), ".env"),
        env_file_encoding="utf-8",
        extra="ignore"
    )

settings = Settings()
