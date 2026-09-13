import os
from typing import Optional
from dataclasses import dataclass
from fastapi import HTTPException, Security, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import firebase_admin
from firebase_admin import auth as firebase_auth_admin, credentials
from ..config import settings

@dataclass
class AuthenticatedUser:
    uid: str
    email: str = ""
    name: str = ""
    token: str = ""

security_bearer = HTTPBearer(auto_error=False)

import json
import base64

_firebase_initialized = False

def init_firebase_admin():
    global _firebase_initialized
    if _firebase_initialized or firebase_admin._apps:
        _firebase_initialized = True
        return
    try:
        cred = None
        # 1. Direct JSON string from environment
        if settings.FIREBASE_SERVICE_ACCOUNT_JSON:
            try:
                cert_dict = json.loads(settings.FIREBASE_SERVICE_ACCOUNT_JSON)
                cred = credentials.Certificate(cert_dict)
                print("[Auth] Firebase Admin credentials loaded from FIREBASE_SERVICE_ACCOUNT_JSON.")
            except Exception as e:
                print(f"⚠️ [Auth] Could not parse FIREBASE_SERVICE_ACCOUNT_JSON: {e}")

        # 2. Base64 encoded JSON string from environment
        if not cred and settings.FIREBASE_SERVICE_ACCOUNT_BASE64:
            try:
                raw_json = base64.b64decode(settings.FIREBASE_SERVICE_ACCOUNT_BASE64).decode("utf-8")
                cert_dict = json.loads(raw_json)
                cred = credentials.Certificate(cert_dict)
                print("[Auth] Firebase Admin credentials loaded from FIREBASE_SERVICE_ACCOUNT_BASE64.")
            except Exception as e:
                print(f"⚠️ [Auth] Could not parse FIREBASE_SERVICE_ACCOUNT_BASE64: {e}")

        # 3. File path from settings or GOOGLE_APPLICATION_CREDENTIALS or standard locations
        if not cred:
            sa_path = settings.FIREBASE_SERVICE_ACCOUNT_PATH or os.environ.get("GOOGLE_APPLICATION_CREDENTIALS", "")
            if not sa_path:
                for p in ["./serviceAccountKey.json", "ai_backend/serviceAccountKey.json", "../serviceAccountKey.json"]:
                    if os.path.exists(p):
                        sa_path = p
                        break
            if sa_path and os.path.exists(sa_path):
                cred = credentials.Certificate(sa_path)
                print(f"[Auth] Firebase Admin credentials loaded from certificate file: {sa_path}")

        # 4. Initialize Firebase Admin
        if cred:
            firebase_admin.initialize_app(cred, options={"projectId": settings.FIREBASE_PROJECT_ID})
            _firebase_initialized = True
            print(f"[Auth] Firebase Admin initialized with service account for project: {settings.FIREBASE_PROJECT_ID}")
        else:
            try:
                # Try application default credentials
                app_default_cred = credentials.ApplicationDefault()
                firebase_admin.initialize_app(app_default_cred, options={"projectId": settings.FIREBASE_PROJECT_ID})
                _firebase_initialized = True
                print(f"[Auth] Firebase Admin initialized with Application Default Credentials for project: {settings.FIREBASE_PROJECT_ID}")
            except Exception:
                firebase_admin.initialize_app(options={"projectId": settings.FIREBASE_PROJECT_ID})
                _firebase_initialized = True
                print(f"[Auth] Firebase Admin initialized with project ID: {settings.FIREBASE_PROJECT_ID} (Note: no server credentials provided)")
    except Exception as e:
        print(f"[Auth] Firebase Admin initialization note: {str(e)[:120]}")

init_firebase_admin()

async def get_current_user(
    cred: Optional[HTTPAuthorizationCredentials] = Security(security_bearer)
) -> AuthenticatedUser:
    """
    Validates the bearer token against Firebase Authentication and extracts the verified UID.
    Rejects any unauthenticated or unauthorized requests with 401.
    NEVER logs full tokens or secrets.
    """
    if not cred or not cred.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing authentication credentials. Bearer token required.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = cred.credentials.strip()

    # Dev / test environment bypass for local mocking without live service account
    if settings.DEV_AUTH_BYPASS:
        if token.startswith("test_") or token.startswith("dev_") or token.startswith("mock_"):
            parts = token.split(":")
            uid = parts[0]
            name = parts[1] if len(parts) > 1 else "Test User"
            email = parts[2] if len(parts) > 2 else f"{uid}@test.com"
            return AuthenticatedUser(uid=uid, email=email, name=name, token=token)

    # Production Firebase ID token verification
    try:
        decoded_token = firebase_auth_admin.verify_id_token(token)
        uid = decoded_token.get("uid")
        if not uid:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token payload missing valid UID.",
                headers={"WWW-Authenticate": "Bearer"},
            )
        email = decoded_token.get("email", "")
        name = decoded_token.get("name", "")
        return AuthenticatedUser(uid=uid, email=email, name=name, token=token)
    except Exception as e:
        # If dev auth bypass is enabled, allow local dev token
        if settings.DEV_AUTH_BYPASS and len(token) > 0:
            dev_uid = token.split(":")[0] if ":" in token else "dev_user"
            return AuthenticatedUser(uid=dev_uid, email="", name="Dev User", token=token)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid or expired authentication token: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )

async def get_current_user_uid(
    user: AuthenticatedUser = Security(get_current_user)
) -> str:
    return user.uid
