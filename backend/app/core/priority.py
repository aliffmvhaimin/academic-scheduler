"""Priority calculation for academic tasks."""
from datetime import datetime
from typing import Dict
from app.models.task import Task


def calculate_urgency_score(deadline: datetime, reference_time: datetime) -> float:
    """
    Calculates normalized urgency score [0, 1].
    Shorter time to deadline yields higher urgency score.
    """
    hours_left = max(0.1, (deadline - reference_time).total_seconds() / 3600.0)
    # Exponential decay / reciprocal: tasks due in < 24h get ~1.0, 72h gets ~0.5, > 1 week gets lower
    urgency = 24.0 / (24.0 + hours_left)
    return min(1.0, max(0.0, urgency))


def calculate_task_priority(
    task: Task,
    reference_time: datetime,
    w_urgency: float = 0.5,
    w_credit: float = 0.3,
    w_difficulty: float = 0.2
) -> float:
    """
    Calculates weighted composite priority score in range [0, 1].
    - urgency score: normalized [0, 1]
    - credit weight: normalized [0, 1] from range [1, 6]
    - difficulty score: normalized [0, 1] from range [1, 10]
    """
    u_score = calculate_urgency_score(task.deadline, reference_time)
    c_score = (task.credit_weight - 1) / 5.0  # 1..6 -> 0..1
    d_score = (task.difficulty_score - 1) / 9.0  # 1..10 -> 0..1

    total_weight = w_urgency + w_credit + w_difficulty
    if total_weight <= 0:
        total_weight = 1.0

    priority = (w_urgency * u_score + w_credit * c_score + w_difficulty * d_score) / total_weight
    return priority
