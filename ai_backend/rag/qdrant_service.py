import hashlib
from typing import List, Dict, Any, Optional
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct
from .knowledge_base import TRUSTED_HEALTH_DOCUMENTS
from ..services.gemini_service import gemini_service
from ..config import settings

VECTOR_DIM = 3072
COLLECTION_NAME = "health_knowledge"

class QdrantRAGService:
    def __init__(self):
        # Use embedded in-memory Qdrant client for zero-dependency operation
        self.client = QdrantClient(":memory:")
        self._initialized = False

    def _fallback_vector(self, text: str) -> List[float]:
        """
        Deterministic normalized 3072-dim hash vector used when Gemini API is unavailable or offline.
        """
        vec = [0.0] * VECTOR_DIM
        tokens = text.lower().split()
        for i, token in enumerate(tokens):
            h = int(hashlib.md5(token.encode("utf-8")).hexdigest(), 16)
            idx = h % VECTOR_DIM
            vec[idx] += 1.0
        # Normalize
        norm = sum(x*x for x in vec) ** 0.5
        if norm > 0:
            vec = [x / norm for x in vec]
        return vec

    async def _get_embedding(self, text: str) -> List[float]:
        if gemini_service.is_configured:
            try:
                emb = await gemini_service.get_embedding(text)
                if emb and len(emb) == VECTOR_DIM and any(x != 0 for x in emb):
                    return emb
            except Exception as e:
                print(f"[WARN] [QdrantRAG] Gemini embedding failed ({e}), using fallback vector.")

        return self._fallback_vector(text)

    async def initialize(self):
        if self._initialized:
            return

        # Check if collection exists
        collections = self.client.get_collections().collections
        exists = any(c.name == COLLECTION_NAME for c in collections)
        if not exists:
            self.client.create_collection(
                collection_name=COLLECTION_NAME,
                vectors_config=VectorParams(size=VECTOR_DIM, distance=Distance.COSINE)
            )

        points = []
        for idx, doc in enumerate(TRUSTED_HEALTH_DOCUMENTS):
            full_text = f"{doc['title']} - {doc['topic']}: {doc['content']}"
            vector = await self._get_embedding(full_text)
            points.append(
                PointStruct(
                    id=idx + 1,
                    vector=vector,
                    payload=doc
                )
            )

        if points:
            self.client.upsert(
                collection_name=COLLECTION_NAME,
                points=points
            )

        self._initialized = True
        print(f"[QdrantRAG] Initialized collection '{COLLECTION_NAME}' with {len(points)} clinical documents.")


    async def search(self, query: str, limit: int = 2) -> List[Dict[str, Any]]:
        """
        Performs semantic vector search across trusted health guidelines.
        """
        if not self._initialized:
            await self.initialize()

        query_vector = await self._get_embedding(query)
        # Use query_points (supported in modern qdrant_client)
        if hasattr(self.client, "query_points"):
            res = self.client.query_points(
                collection_name=COLLECTION_NAME,
                query=query_vector,
                limit=limit
            )
            search_results = res.points
        else:
            search_results = self.client.search(
                collection_name=COLLECTION_NAME,
                query_vector=query_vector,
                limit=limit
            )

        results = []
        for hit in search_results:
            results.append({
                "id": hit.payload.get("id"),
                "topic": hit.payload.get("topic"),
                "title": hit.payload.get("title"),
                "content": hit.payload.get("content"),
                "score": hit.score
            })
        return results

rag_service = QdrantRAGService()

