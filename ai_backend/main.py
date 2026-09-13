import time
from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from .config import settings
from .auth.firebase_auth import get_current_user, AuthenticatedUser
from .models.requests import ChatRequest, ActionConfirmationRequest
from .models.responses import ChatResponse, ActionExecutionResponse
from .agent.aurora_graph import aurora_app
from .tools.action_tools import execute_confirmed_action
from .rag.qdrant_service import rag_service
from .services.gemini_service import gemini_service
from .services.firestore_service import firestore_service

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup Firestore connectivity check
    connected, reason = firestore_service.check_connectivity()
    if connected:
        print("[Aurora] Firestore initialization: SUCCESS")
        print("[Aurora] Firestore connectivity check: SUCCESS")
    else:
        print("[Aurora] Firestore initialization: FAILED")
        print("[Aurora] Firestore connectivity check: FAILED")
        print(f"[Aurora] Reason: {reason}")

    # Initialize Qdrant clinical knowledge collection on startup
    try:
        await rag_service.initialize()
    except Exception as e:
        print(f"[Startup] RAG initialization warning: {e}")
    yield

app = FastAPI(
    title="Aurora Health AI Backend",
    version="1.0.0",
    description="Production-grade Agentic AI backend for Health Tracker featuring LangGraph, Firestore isolation, and RAG.",
    lifespan=lifespan
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "aurora-health-backend",
        "version": "1.0.0",
        "gemini_connected": gemini_service.is_configured,
        "firestore_cloud_connected": firestore_service.is_cloud_connected
    }

@app.post("/api/v1/chat", response_model=ChatResponse)
async def chat_endpoint(
    req: ChatRequest,
    current_user: AuthenticatedUser = Depends(get_current_user)
):
    """
    Primary agentic chat endpoint. Invokes LangGraph agent with strict UID isolation and token security.
    """
    t_start = time.perf_counter()
    print("[Aurora] Request started")
    print("[Aurora] Firebase authentication: PASS")
    print("[Aurora] UID verified: true")
    auth_ms = round((time.perf_counter() - t_start) * 1000)
    print(f"[Aurora] Auth completed: {auth_ms} ms")

    try:
        initial_state = {
            "user_id": current_user.uid,
            "uid": current_user.uid,
            "auth_token": current_user.token,
            "original_user_message": req.message,
            "user_message": req.message,
            "history": [m.model_dump() for m in req.history],
            "client_snapshot": req.client_snapshot.model_dump() if req.client_snapshot else None,
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

        result = await aurora_app.ainvoke(initial_state)

        t_total_ms = round((time.perf_counter() - t_start) * 1000)
        print(f"[Aurora] Total request time: {t_total_ms} ms")
        print("[Aurora] Request completed: 200")

        db_err = result.get("database_error")
        is_success = db_err is None and not (result.get("errors") and any("Action failed" in e for e in result.get("errors", [])))

        return ChatResponse(
            success=is_success,
            error_code=db_err,
            message=result.get("final_response") if not is_success else None,
            response=result["final_response"],
            tools_called=result.get("tools_called", result.get("tool_calls", [])),
            pending_action=result.get("pending_action"),
            executed_action=result.get("executed_action"),
            sources=result.get("sources", [])
        )
    except Exception as e:
        print(f"[ChatEndpoint Error]: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Agent processing error: {str(e)}"
        )

@app.post("/api/v1/actions/confirm", response_model=ActionExecutionResponse)
async def confirm_action_endpoint(
    req: ActionConfirmationRequest,
    current_user: AuthenticatedUser = Depends(get_current_user)
):
    """
    Confirms and executes a pending action requiring confirmation.
    Strictly verifies action ownership against the authenticated UID.
    """
    result = await execute_confirmed_action(current_user.uid, req.action_id, req.confirmed, auth_token=current_user.token)
    if not result.get("success") and "error" in result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=result["error"]
        )
    return ActionExecutionResponse(
        success=result.get("success", False),
        message=result.get("message", ""),
        action=result.get("action")
    )
