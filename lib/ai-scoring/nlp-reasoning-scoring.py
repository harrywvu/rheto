# justification_scoring.py
from typing import List, Dict, Tuple
import re
import numpy as np

# embeddings & similarity
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity

# NLP parsing
import spacy
nlp = spacy.load("en_core_web_sm")

# --- Configuration / hyperparams ---
EMBEDDING_MODEL = "all-MiniLM-L6-v2"  # light, good performance
WEIGHTS = {
    "semantic": 0.4,
    "reasoning": 0.3,
    "complexity": 0.3
}

# Reasoning/discourse markers to detect
REASONING_MARKERS = [
    "because", "therefore", "thus", "hence", "so", "as a result",
    "consequently", "however", "but", "although", "therefore", "since", "due to", "for example", "for instance"
]

# Initialize embedding model once
EMBED_MODEL = SentenceTransformer(EMBEDDING_MODEL)


# --- Helpers: preprocessing & tokenization ---
def clean_text(text: str) -> str:
    """Basic text cleaning: normalize whitespace and remove weird chars but keep punctuation for parsing."""
    text = text.strip()
    text = re.sub(r"\s+", " ", text)
    return text

def sentences_and_tokens(text: str):
    """Return spacy doc, list of sentence strings, and list of tokens (strings)."""
    doc = nlp(text)
    sentences = [sent.text.strip() for sent in doc.sents]
    tokens = [token.text for token in doc if not token.is_space]
    return doc, sentences, tokens


# --- Feature extractors ---
def semantic_similarity_score(user_answer: str, reference_answer: str) -> float:
    """Compute cosine similarity between sentence embeddings (0..1 scaled)."""
    a_emb = EMBED_MODEL.encode([user_answer])
    r_emb = EMBED_MODEL.encode([reference_answer])
    sim = cosine_similarity(a_emb, r_emb)[0][0]
    # Clip and map from [-1,1] (rare) to [0,1]
    sim = float(np.clip((sim + 1) / 2, 0.0, 1.0))
    return sim

def reasoning_score(user_answer: str) -> float:
    """
    Rule-based reasoning score:
    - presence of discourse markers (counts normalized)
    - presence of subordinating clauses (approx via dependency labels)
    Returns 0..1
    """
    doc, sentences, tokens = sentences_and_tokens(user_answer.lower())
    text = user_answer.lower()
    # marker count (unique markers found)
    marker_hits = sum(1 for m in REASONING_MARKERS if m in text)
    marker_score = min(marker_hits / 4.0, 1.0)  # saturate at 4 markers

    # subordinate clause proxy: count advcl, ccomp, xcomp, relcl occurrences
    subordinating_deps = sum(1 for token in doc if token.dep_ in ("advcl", "ccomp", "xcomp", "relcl"))
    # normalize by sentence count to avoid rewarding verbosity too much
    sent_count = max(len(sentences), 1)
    subs_score = min((subordinating_deps / sent_count) / 1.0, 1.0)  # expect ~1 per sentence for strong reasoning

    # combine marker and subscores
    combined = 0.6 * marker_score + 0.4 * subs_score
    return float(np.clip(combined, 0.0, 1.0))

def complexity_score(user_answer: str) -> float:
    """
    Complexity signal: combination of average sentence length, type-token ratio (TTR),
    and vocabulary richness. Returns 0..1
    """
    doc, sentences, tokens = sentences_and_tokens(user_answer)
    token_texts = [t.lower() for t in tokens if t.isalpha()]  # only words
    if len(token_texts) == 0:
        return 0.0

    # average sentence length (in words)
    avg_sent_len = np.mean([len([t for t in nlp(s) if not t.is_space]) for s in sentences]) if sentences else 0.0
    # type-token ratio
    unique_words = len(set(token_texts))
    ttr = unique_words / len(token_texts)

    # simple heuristics to map to 0..1
    # avg_sent_len: 5->0, 20->1
    sent_len_score = (avg_sent_len - 5) / (20 - 5)
    # ttr: 0.2->0, 0.6->1
    ttr_score = (ttr - 0.2) / (0.6 - 0.2)

    combined = 0.5 * np.clip(sent_len_score, 0, 1) + 0.5 * np.clip(ttr_score, 0, 1)
    return float(np.clip(combined, 0.0, 1.0))


# --- Scoring & feedback ---
def combine_scores(semantic: float, reasoning: float, complexity: float, weights=WEIGHTS) -> float:
    """Weighted sum -> final score in 0..1"""
    final = semantic * weights["semantic"] + reasoning * weights["reasoning"] + complexity * weights["complexity"]
    return float(np.clip(final, 0.0, 1.0))

def generate_feedback(semantic: float, reasoning: float, complexity: float) -> List[str]:
    """Return short actionable feedback items based on thresholds."""
    feedback = []
    if semantic < 0.5:
        feedback.append("Your answer seems off-target compared to the expected response. Cite main points or definitions from the prompt.")
    if reasoning < 0.5:
        feedback.append("Add explicit reasoning: use 'because', 'therefore' or phrases that link cause and effect.")
    if complexity < 0.4:
        feedback.append("Expand your answer with an example or an extra sentence to show depth.")
    if not feedback:
        feedback.append("Good work — clear, relevant, and reasoned. Consider adding an example to strengthen it further.")
    return feedback


# --- Full pipeline function ---
def score_justification(user_answer: str, reference_answer: str) -> Dict[str, object]:
    user_answer = clean_text(user_answer)
    reference_answer = clean_text(reference_answer)
    # features
    semantic = semantic_similarity_score(user_answer, reference_answer)
    reasoning = reasoning_score(user_answer)
    complexity = complexity_score(user_answer)
    final = combine_scores(semantic, reasoning, complexity)
    feedback = generate_feedback(semantic, reasoning, complexity)
    # return a structured result
    return {
        "semantic": round(semantic, 3),
        "reasoning": round(reasoning, 3),
        "complexity": round(complexity, 3),
        "final_score": round(final, 3),
        "feedback": feedback
    }


# --- Example usage ---
if __name__ == "__main__":

    import sys, json

    raw = sys.stdin.read().strip()
    if raw:
        try:
            data = json.loads(raw);
            user_text = data.get("text", "")
            reference = data.get("reference", "")
            result = score_justification(user_text, reference)
            print(json.dumps(result))
        except Exception as err:
            print(json.dumps({"error": str(err)}))
            sys.exit(1)
    else:
        reference = (
            "Photosynthesis is the process by which plants convert sunlight into chemical energy. "
            "It involves chlorophyll capturing light and converting carbon dioxide and water into glucose and oxygen."
        )

        examples = [
            # strong answer
            "Photosynthesis is how plants turn sunlight into chemical energy. Because chlorophyll absorbs light, plants transform CO2 and water into glucose and oxygen — that's why leaves release oxygen.",
            # moderate answer
            "Plants use sunlight to make food. Chlorophyll helps them change carbon dioxide and water to sugar.",
            # weak/irrelevant
            "Plants are green and live in soil. They need water and sunlight, I guess."
        ]

        for i, ua in enumerate(examples, 1):
            out = score_justification(ua, reference)
            print(f"--- Example {i} ---")
            print("Answer:", ua)
            print("Scores:", out)
            print()
