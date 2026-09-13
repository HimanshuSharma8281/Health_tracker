from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field

class ActionItem(BaseModel):
    action_id: str = Field(..., description="Unique identifier for the action")
    action_type: str = Field(..., description="Type of action, e.g. log_water, update_water_goal")
    parameters: Dict[str, Any] = Field(default_factory=dict, description="Parameters for the action")
    requires_confirmation: bool = Field(default=False, description="Whether human confirmation is required")
    confirmation_prompt: Optional[str] = Field(default=None, description="Prompt shown to user for confirmation")
    executed: bool = Field(default=False, description="Whether the action has already been executed")
    result: Optional[Dict[str, Any]] = Field(default=None, description="Result payload if executed")

class MetricScoreDetail(BaseModel):
    score: int
    available: bool
    reason: Optional[str] = None
    target: Optional[str] = None
    reading: Optional[float] = None

class HealthScoreSummary(BaseModel):
    overall: int
    label: str
    date: str
    available_metrics: int
    metrics: Dict[str, Any] = Field(default_factory=dict)

class ActionExecutionResponse(BaseModel):
    success: bool
    message: str
    action: Optional[str] = None
    data: Optional[Dict[str, Any]] = None

class ActionConfirmationPrompt(BaseModel):
    action_id: str
    action_type: str
    message: str
    warning: Optional[str] = None
    payload: Dict[str, Any] = Field(default_factory=dict)

class ChatResponse(BaseModel):
    success: bool = Field(default=True, description="Whether the request succeeded")
    error_code: Optional[str] = Field(default=None, description="Standardized error code if failed")
    message: Optional[str] = Field(default=None, description="Optional system or status message")
    response: str = Field(..., description="Aurora's conversational or analytical response")
    response_type: str = Field(
        default="health_analysis",
        description="Type of response: 'health_analysis', 'general_knowledge', 'action_executed', 'action_confirmation_required'"
    )
    tools_called: List[str] = Field(default_factory=list, description="List of tools invoked during reasoning")
    score_details: Optional[HealthScoreSummary] = Field(default=None, description="Deterministic Wellness Score details")
    pending_action: Optional[Dict[str, Any]] = Field(default=None, description="Action awaiting user confirmation")
    executed_action: Optional[Dict[str, Any]] = Field(default=None, description="Action successfully executed")
    sources: List[str] = Field(default_factory=list, description="References/knowledge sources used for RAG responses")

