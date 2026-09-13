from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field

class ChatMessage(BaseModel):
    role: str = Field(..., description="Role: 'user' or 'assistant'")
    content: str = Field(..., description="Message text content")

class ClientHealthSnapshot(BaseModel):
    user_name: Optional[str] = None
    water_ml: Optional[int] = None
    water_goal: Optional[int] = None
    steps: Optional[int] = None
    step_goal: Optional[int] = None
    sleep_hours: Optional[float] = None
    sleep_goal: Optional[float] = None
    calories: Optional[int] = None
    calorie_goal: Optional[int] = None
    heart_rate: Optional[float] = None
    blood_pressure: Optional[str] = None
    today_score: Optional[int] = None
    score_label: Optional[str] = None

class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, description="User's query or prompt")
    history: List[ChatMessage] = Field(default_factory=list, description="Prior conversation messages")
    client_snapshot: Optional[ClientHealthSnapshot] = Field(
        default=None,
        description="Live in-memory health metrics from the Flutter client"
    )
    confirmed_action_id: Optional[str] = Field(
        default=None,
        description="ID of an action previously confirmed by the user"
    )

class ConfirmActionRequest(BaseModel):
    action_id: str = Field(..., description="Unique ID of the pending action")
    confirmed: bool = Field(..., description="True to execute, False to cancel")

# Alias for compatibility
ActionConfirmationRequest = ConfirmActionRequest

