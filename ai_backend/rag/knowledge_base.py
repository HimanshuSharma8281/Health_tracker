from typing import List, Dict, Any

TRUSTED_HEALTH_DOCUMENTS: List[Dict[str, Any]] = [
    {
        "id": "doc_sleep_circadian",
        "topic": "sleep",
        "title": "Circadian Rhythms, Sleep Architecture, and Recovery",
        "content": (
            "Adults typically require 7 to 9 hours of restorative sleep per night to maintain "
            "optimal cardiovascular health, metabolic regulation, and cognitive function. Deep slow-wave sleep "
            "facilitates tissue repair, growth hormone release, and immune restoration, while REM sleep supports "
            "emotional processing and memory consolidation. Maintaining consistent bedtime and wake times anchors "
            "circadian phase, preventing circadian misalignment and daytime fatigue."
        ),
        "tags": ["sleep", "circadian", "recovery", "rem", "wellness"]
    },
    {
        "id": "doc_hydration_physiology",
        "topic": "hydration",
        "title": "Hydration Physiology and Cognitive/Physical Performance",
        "content": (
            "The human body is approximately 60% water. Baseline hydration demands for moderately active adults "
            "range from 2,000 to 3,000 mL daily, adjusted upward for ambient temperature, humidity, and intense exercise. "
            "Even mild dehydration (a 1-2% loss of total body mass) impairs thermoregulation, lowers stroke volume, "
            "elevates resting heart rate, and degrades executive mental function. Distributing fluid intake evenly throughout "
            "the day with electrolytes prevents acute hypovolemia."
        ),
        "tags": ["hydration", "water", "performance", "heart_rate", "electrolytes"]
    },
    {
        "id": "doc_step_activity_metabolism",
        "topic": "activity",
        "title": "Daily Step Counts, Non-Exercise Activity Thermogenesis (NEAT), and Longevity",
        "content": (
            "Daily ambulation serves as the cornerstone of Non-Exercise Activity Thermogenesis (NEAT). Epidemiological "
            "studies demonstrate that achieving 7,500 to 10,000 steps daily significantly reduces all-cause mortality, improves "
            "insulin sensitivity, and stabilizes glycemic variability compared to sedentary thresholds (<5,000 steps). "
            "Breaking prolonged periods of sitting with brief 2-minute walking intervals enhances postprandial glucose clearance."
        ),
        "tags": ["steps", "walking", "activity", "neat", "metabolism", "longevity"]
    },
    {
        "id": "doc_cardiovascular_zones",
        "topic": "cardiovascular",
        "title": "Heart Rate Monitoring, Blood Pressure Regulation, and Zone 2 Conditioning",
        "content": (
            "Resting heart rate in healthy adults generally spans 60 to 100 beats per minute, with well-conditioned "
            "individuals often presenting between 50 and 65 bpm. Elevated resting pulse (>85-90 bpm) over multiple days can "
            "indicate systemic overtraining, sympathetic hyperactivity, infection, or dehydration. Blood pressure readings "
            "below 120/80 mmHg represent normal hemodynamics. Moderate aerobic training in Zone 2 (60-70% maximum heart rate) "
            "stimulates mitochondrial density and capillary growth."
        ),
        "tags": ["heart_rate", "cardio", "blood_pressure", "aerobic", "zone2"]
    },
    {
        "id": "doc_metabolic_nutrition",
        "topic": "nutrition",
        "title": "Caloric Homeostasis, Macronutrient Quality, and Energy Balance",
        "content": (
            "Sustainable energy balance requires matching total daily energy expenditure (TDEE) with nutrient-dense intake. "
            "Prioritizing lean proteins (1.6 to 2.2 g/kg for active adults), complex carbohydrates, and fiber enhances satiety "
            "and supports muscular glycogen replenishment without causing volatile blood glucose spikes. Excessive caloric deficits "
            "(>500-750 kcal/day below expenditure) trigger adaptive thermogenesis and elevate circulating cortisol."
        ),
        "tags": ["calories", "nutrition", "metabolism", "energy_balance", "blood_sugar"]
    }
]
