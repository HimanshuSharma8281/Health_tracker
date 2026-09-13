import time
from typing import List, Dict, Any, Optional
from google import genai
from google.genai import types
from ..config import settings

class GeminiService:
    def __init__(self):
        self._api_key = settings.GEMINI_API_KEY
        self._client: Optional[genai.Client] = None
        self._exhausted_models: Dict[str, float] = {}  # model_name -> expiration_timestamp
        if self._api_key:
            try:
                self._client = genai.Client(api_key=self._api_key)
            except Exception as e:
                print(f"⚠️ [GeminiService] Initialization warning: {e}")

    @property
    def is_configured(self) -> bool:
        return bool(self._api_key and len(self._api_key) > 5 and self._client is not None)

    def _get_active_candidate_models(self) -> List[str]:
        now = time.time()
        # Clean up expired exhaustion records (60-second cooldown)
        self._exhausted_models = {m: exp for m, exp in self._exhausted_models.items() if exp > now}

        base_candidates = [
            settings.GEMINI_MODEL,
            "gemini-flash-lite-latest",
            "gemini-3.1-flash-lite-preview",
            "gemini-3-flash-preview",
            "gemini-flash-latest",
        ]
        # Remove duplicates while preserving priority order
        unique_candidates = list(dict.fromkeys(base_candidates))

        # Filter out currently exhausted models to top of list, but keep as fallback at the end
        available = [m for m in unique_candidates if m not in self._exhausted_models]
        exhausted = [m for m in unique_candidates if m in self._exhausted_models]
        return available + exhausted

    async def generate_response(
        self,
        system_prompt: str,
        messages: List[Dict[str, str]],
        temperature: float = 0.2,
    ) -> str:
        if not self.is_configured or not self._client:
            return ""

        # Format conversation messages into standard dialogue
        formatted_dialogue = []
        for msg in messages:
            role_label = "User" if msg["role"] == "user" else "Aurora"
            formatted_dialogue.append(f"{role_label}: {msg['content']}")
        full_content = "\n\n".join(formatted_dialogue)

        candidates = self._get_active_candidate_models()

        for model_name in candidates:
            try:
                print(f"[Aurora] Gemini request started (model: {model_name})")
                config = types.GenerateContentConfig(
                    system_instruction=system_prompt,
                    temperature=temperature,
                )
                # Use Chat.send_message pattern to eliminate AFC deprecation warning
                chat = self._client.chats.create(
                    model=model_name,
                    config=config
                )
                response = chat.send_message(full_content)
                if response and response.text:
                    print(f"[Aurora] Gemini response received from {model_name}")
                    return response.text
            except Exception as e:
                err_msg = str(e)
                if "429" in err_msg or "RESOURCE_EXHAUSTED" in err_msg or "quota" in err_msg.lower():
                    # Record 60-second cooldown for quota-exhausted model
                    self._exhausted_models[model_name] = time.time() + 60.0
                    print(f"⚠️ [GeminiService] Model {model_name} quota exhausted (429), switching to next available candidate...")
                else:
                    print(f"⚠️ [GeminiService] Model {model_name} failed: {err_msg[:120]}, trying next candidate...")

        return ""

    async def analyze_food_image(
        self,
        image_bytes: bytes,
        mime_type: str = "image/jpeg",
    ) -> Dict[str, Any]:
        """
        Analyze a food image with Gemini Vision.

        Returns structured nutrition information.
        The Gemini API key remains server-side.
        """

        if not self.is_configured or not self._client:
            raise RuntimeError("Gemini service is not configured")

        if not image_bytes:
            raise ValueError("Image is empty")

        prompt = """
Analyze the food in this image.

Identify the most likely food or dish and estimate its nutritional
information for the visible serving.

Return ONLY valid JSON with exactly these fields:

{
  "name": "specific food or dish name",
  "calories": 0,
  "protein": 0.0,
  "carbs": 0.0,
  "fat": 0.0,
  "confidence": 0
}

Rules:
- "name" must be specific when possible.
- calories must be an integer.
- protein, carbs and fat must be numbers in grams.
- confidence must be an integer from 0 to 100.
- Do not include markdown.
- Do not include explanations outside the JSON.
- If multiple foods are visible, identify the main dish/meal.
- Nutrition values are estimates, not medical measurements.
"""

        candidates = self._get_active_candidate_models()

        for model_name in candidates:
            try:
                print(
                    f"[FoodVision] Gemini image analysis started "
                    f"(model: {model_name})"
                )

                image_part = types.Part.from_bytes(
                    data=image_bytes,
                    mime_type=mime_type,
                )

                config = types.GenerateContentConfig(
                    temperature=0.1,
                    response_mime_type="application/json",
                )

                response = self._client.models.generate_content(
                    model=model_name,
                    contents=[
                        image_part,
                        prompt,
                    ],
                    config=config,
                )

                if response and response.text:
                    print(
                        f"[FoodVision] Gemini response received "
                        f"from {model_name}"
                    )

                    import json

                    data = json.loads(response.text)

                    name = str(data.get("name", "")).strip()

                    if not name:
                        raise ValueError(
                            "Gemini returned an empty food name"
                        )

                    result = {
                        "name": name,
                        "calories": int(data.get("calories", 0)),
                        "protein": float(data.get("protein", 0)),
                        "carbs": float(data.get("carbs", 0)),
                        "fat": float(data.get("fat", 0)),
                        "confidence": int(data.get("confidence", 0)),
                    }

                    print(
                        f"[FoodVision] Detected: {result['name']} | "
                        f"{result['calories']} kcal"
                    )

                    return result

            except Exception as e:
                err_msg = str(e)

                if (
                    "429" in err_msg
                    or "RESOURCE_EXHAUSTED" in err_msg
                    or "quota" in err_msg.lower()
                ):
                    self._exhausted_models[model_name] = (
                        time.time() + 60.0
                    )

                    print(
                        f"⚠️ [FoodVision] Model {model_name} "
                        f"quota exhausted"
                    )
                else:
                    print(
                        f"⚠️ [FoodVision] Model {model_name} failed: "
                        f"{err_msg[:200]}"
                    )

        raise RuntimeError(
            "Food image analysis failed for all available Gemini models"
        )

    async def get_embedding(self, text: str) -> List[float]:
        if not self.is_configured or not self._client or not text.strip():
            return [0.0] * 3072

        try:
            response = self._client.models.embed_content(
                model=settings.GEMINI_EMBEDDING_MODEL,
                contents=text,
            )
            if response and response.embeddings and len(response.embeddings) > 0:
                values = response.embeddings[0].values
                if values and len(values) == 3072:
                    return values
        except Exception as e:
            print(f"[WARN] [GeminiService] embed error: {str(e)[:120]}")

        return [0.0] * 3072

gemini_service = GeminiService()
