from typing import TypedDict, List, Dict, Any, Optional

class AuroraState(TypedDict, total=False):
    # Core architectural state keys required by spec
    user_id: str
    original_user_message: str
    intent: Optional[str]
    requested_date: Optional[str]
    date_label: Optional[str]
    tool_calls: List[str]
    tool_results: Dict[str, Any]
    retrieved_documents: List[Dict[str, Any]]
    current_health_data: Dict[str, Any]
    data_available: bool
    database_error: Optional[str]
    final_response: str
    errors: List[str]

    # Context & authorization
    uid: str
    auth_token: Optional[str]
    user_message: str
    history: List[Dict[str, str]]
    client_snapshot: Optional[Dict[str, Any]]

    # Tool and graph execution tracking
    tools_called: List[str]
    rag_docs: List[Dict[str, Any]]
    pending_action: Optional[Dict[str, Any]]
    executed_action: Optional[Dict[str, Any]]
    sources: List[str]
