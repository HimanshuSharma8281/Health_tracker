from langgraph.graph import StateGraph, START, END
from .state import AuroraState
from .nodes import (
    route_intent_node,
    execute_tools_node,
    retrieve_rag_node,
    synthesize_response_node
)

def build_aurora_graph():
    builder = StateGraph(AuroraState)

    builder.add_node("route_intent", route_intent_node)
    builder.add_node("execute_tools", execute_tools_node)
    builder.add_node("retrieve_rag", retrieve_rag_node)
    builder.add_node("synthesize_response", synthesize_response_node)

    builder.add_edge(START, "route_intent")
    builder.add_edge("route_intent", "execute_tools")
    builder.add_edge("execute_tools", "retrieve_rag")
    builder.add_edge("retrieve_rag", "synthesize_response")
    builder.add_edge("synthesize_response", END)

    return builder.compile()

# Compile single instance
aurora_app = build_aurora_graph()
