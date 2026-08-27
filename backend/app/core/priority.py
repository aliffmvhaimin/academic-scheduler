"""Priority calculation and task sorting for academic tasks."""
from datetime import datetime
from typing import List, Tuple
from app.models.task import Task


def calculate_urgency_score(deadline: datetime, reference_time: datetime) -> float:
    """
    Calculates normalized urgency score [0, 1].
    Shorter time to deadline yields higher urgency score.
    """
    hours_left = max(0.0, (deadline - reference_time).total_seconds() / 3600.0)
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
    c_score = (task.credit_weight - 1) / 5.0   # 1..6 -> 0..1
    d_score = (task.difficulty_score - 1) / 9.0  # 1..10 -> 0..1

    total_weight = w_urgency + w_credit + w_difficulty
    if total_weight <= 0:
        total_weight = 1.0

    priority = (w_urgency * u_score + w_credit * c_score + w_difficulty * d_score) / total_weight
    return priority


def sort_tasks_by_priority(
    tasks: List[Task],
    reference_time: datetime,
    w_urgency: float = 0.5,
    w_credit: float = 0.3,
    w_difficulty: float = 0.2
) -> List[Tuple[Task, float]]:
    """
    Sorts tasks deterministically in descending order of composite priority score.
    Tie-breaking:
    1. Highest priority score first.
    2. Earlier deadline first.
    3. Lexicographical task ID for strict determinism.

    Returns:
        List of (task, priority_score) tuples.
    """
    scored_tasks = [
        (
            t,
            calculate_task_priority(
                t,
                reference_time,
                w_urgency=w_urgency,
                w_credit=w_credit,
                w_difficulty=w_difficulty
            )
        )
        for t in tasks
    ]

    scored_tasks.sort(
        key=lambda item: (item[1], -item[0].deadline.timestamp(), item[0].id),
        reverse=True
    )
    return scored_tasks
