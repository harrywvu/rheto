# 🎨 Creativity Studio Score (CSS) – Initial Assessment

**Goal:** Measure baseline divergent thinking capacity and creative refinement ability.  
**Duration:** ~3–4 minutes  
**Metrics:**  
- **Fluency (30%)** – Number of unique ideas  
- **Flexibility (25%)** – Range of conceptual categories  
- **Originality (25%)** – Rarity of ideas vs dataset baseline  
- **Refinement Gain (20%)** – Quality improvement in idea development  

---

## 1. Divergent Uses Task  
**(Fluency + Flexibility + Originality)**

**Prompt:**  
> “List as many creative uses for a **brick** as possible in 90 seconds.”  
> Think beyond construction — consider survival, art, problem-solving, fun, and symbolism.

**Example responses:**  
- Paperweight  
- Doorstop  
- Heat source after being warmed  
- Canvas for miniature painting  
- Balance trainer for yoga  
- Emergency self-defense tool  
- Symbolic award (“brick of achievement”)  

**Mechanics:**  
1. Timer starts (90s).  
2. User types ideas one by one in free-text form.  
3. System parses entries, filters duplicates, and timestamps responses.  
4. NLP module categorizes ideas (e.g., structural, artistic, practical, abstract).  
5. Dataset comparison assigns rarity score per entry.  

**Scoring:**  
- **Fluency:** Count of valid unique ideas.  
- **Flexibility:** Number of conceptual categories covered.  
- **Originality:** Weighted average of rarity scores (inverse frequency).  

---

## 2. Thematic Remix Round  
**(Flexibility Booster – Optional Mid-Test Mini Twist)**  

**Prompt:**  
> “Now imagine the **brick** exists in a zero-gravity space station.  
> List 3 more creative uses under these conditions.”  

**Purpose:** Forces contextual shift and mental adaptability.  
**Scoring impact:** Adds bonus points to **Flexibility** for domain transfer.  

---

## 3. Refinement Task  
**(Refinement Gain)**

After the Divergent Uses Task, the system selects **one of the user’s ideas** at random (or the least original one) and prompts:

> “Improve or expand this idea. Make it more practical, detailed, or novel.”

**Example:**  
Original idea: “Use brick as a planter.”  
Refined idea: “Drill a cavity into the brick, line it with moss, and grow succulents — modular eco-sculpture bricks that can interlock into green walls.”  

**Mechanics:**  
1. User rewrites or elaborates within 45 seconds.  
2. NLP model analyzes the *delta* between initial and refined text.  
3. Scoring based on:  
   - **Added Detail (0–3):** Descriptive enhancement.  
   - **Novelty (0–3):** New dimension introduced.  
   - **Feasibility (0–4):** Realistic, applicable improvement.  
4. Weighted total (0–10 → normalized to 20% Refinement Gain).  

---

## 4. Scoring Overview

| Metric | Description | Weight |
|--------|--------------|--------|
| **Fluency** | Count of unique, valid ideas | 30% |
| **Flexibility** | Range of conceptual categories | 25% |
| **Originality** | Dataset rarity of ideas | 25% |
| **Refinement Gain** | Improvement depth in refinement task | 20% |

**Final CSS Formula:**
\[
\text{CSS} = (0.3F + 0.25X + 0.25O + 0.2R) \times 100
\]

---

## ✅ Final Output

User receives:  
- **Total Creativity Studio Score (0–100)**  
- **Subscores:** Fluency, Flexibility, Originality, Refinement Gain  
- **Idea Cloud:** Visual cluster of categories (structural, artistic, practical, abstract)  
- **Top 3 Most Original Ideas**  

---
