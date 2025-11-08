# 🧩 Memory Efficiency Score (MES) – Initial Assessment

**Goal:** Establish baseline working memory capacity, recall speed, and retention strength.  
**Formula:** (Accuracy × Retention Curve Fit) ÷ Average Recall Time  
**Duration:** ~3 minutes

---

## 1. Immediate Recall (Accuracy + Latency)

**Format:**  
Display **8 random words** for **10 seconds**.  
User must recall as many words as possible by typing them after the display period.

**Example Word Set:**  
> orbit — lantern — meadow — fracture — velvet — mirror — canyon — thunder

**Measures:**
- **Accuracy:** % of correct words recalled.
- **Latency:** Average time taken (seconds) per correctly recalled word.

**Mechanism:**
1. System presents words sequentially or all at once.
2. 10-second timer automatically hides list.
3. User types recalled words in any order.
4. App logs timestamp per entry → computes recall latency.

---

## 2. Distractor Task (Interference Control)

**Purpose:** Prevent rehearsal; simulate real-world memory decay.  
**Duration:** 30 seconds.  
**Format:** **Stroop-like mini-task** — identify the color of the word, not the word itself.

**Example:**

| Word | Color to Identify |
|------|-------------------|
| **BLUE** (in red text) | red |
| **YELLOW** (in green text) | green |
| **RED** (in blue text) | blue |

Identify the color of the word
[BLUE] -> [RED] -> [YELLOW] -> [GREEN] -> [BLUE] -> [RED] -> [YELLOW] 
[User input]
timer


**Mechanism:**
1. 10–15 randomized trials.
2. Measures interference resistance and engagement.
3. User's accuracy not graded in MES, only used to ensure focus and timing integrity.

---

## 3. Delayed Recall (Retention Curve + Item Mastery)

**Format:**  
After the distractor task, prompt the user:  
> "Type as many words as you remember from the earlier list."

**Measures:**
- **Retention Curve Fit:**  
  ```
  R = Delayed Recall Accuracy ÷ Immediate Recall Accuracy
  ```
  Indicates how well short-term memory is retained over interference.
  
- **Item Mastery:**  
  Words recalled in both trials are flagged as mastered.

**Example:**  
If user recalled 6/8 immediately and 4/8 after the delay →  
Retention curve = 4 ÷ 6 = 0.67

---

## 4. Scoring Computation

```
MES = (Accuracy × Retention Curve Fit) ÷ Average Recall Time
```

- **Accuracy:** % correct in immediate recall.
- **Retention Curve Fit:** Ratio of delayed to immediate recall accuracy.
- **Average Recall Time:** Mean seconds per word recalled.

**Output:** Normalized score (0–100).

---

## ✅ Final Output

User receives:
- **Immediate Recall Accuracy (%)**
- **Retention Curve (%)**
- **Average Recall Time (s/word)**
- **Memory Efficiency Score (MES)**
- **Item Mastery List:** Words consistently remembered.