"""Fitness function calculation for Genetic Algorithm chromosomes."""
from datetime import datetime
from typing import List, Dict, Tuple, Optional
from app.models.task import Task
from app.core.time_blocks import TimeBlock
from app.core.priority import calculate_task_priority, calculate_urgency_score
from app.genetic_algorithm.chromosome import Chromosome, EMPTY_GENE


def evaluate_chromosome(
    chromosome: Chromosome,
    tasks: List[Task],
    time_blocks: List[TimeBlock],
    reference_time: datetime,
    w_urgency: float = 0.45,
    w_credit: float = 0.30,
    w_difficulty: float = 0.25,
    hard_penalty_weight: float = 50.0,
    task_map: Optional[Dict[str, Task]] = None,
    task_priorities: Optional[Dict[str, float]] = None,
    block_time_factors: Optional[List[float]] = None
) -> Tuple[float]:
    """
    Evaluates fitness for a chromosome. Higher is better.
    Calculates soft objectives (urgency, credit weight, difficulty, spacing)
    and applies penalties for any unresolved hard constraint violations.
    Optimized with precomputed task priorities and block discount factors.
    """
    if task_map is None:
        task_map = {t.id: t for t in tasks}

    if task_priorities is None:
        task_priorities = {
            t.id: calculate_task_priority(
                t,
                reference_time,
                w_urgency=w_urgency,
                w_credit=w_credit,
                w_difficulty=w_difficulty
            )
            for t in tasks
        }

    if block_time_factors is None:
        block_time_factors = [
            1.0 / (1.0 + 0.005 * max(0.0, (b.start - reference_time).total_seconds() / 3600.0))
            for b in time_blocks
        ]

    task_assigned_counts: Dict[str, int] = {t.id: 0 for t in tasks}

    soft_score = 0.0
    penalty_score = 0.0
    total_assigned_blocks = 0

    for i, gene in enumerate(chromosome):
        if gene is EMPTY_GENE:
            continue

        block = time_blocks[i]
        task = task_map.get(gene)
        if not task:
            penalty_score += hard_penalty_weight
            continue

        task_assigned_counts[task.id] += 1
        total_assigned_blocks += 1

        # Check Hard Constraint C2: Deadline
        if block.end > task.deadline:
            # Heavy penalty for scheduling after deadline
            penalty_score += hard_penalty_weight * 2.0
            continue

        # Soft objective: Priority contribution with precomputed time factor
        soft_score += task_priorities[task.id] * block_time_factors[i]

    # Check Hard Constraint C4: Duration satisfaction
    for task in tasks:
        diff = abs(task_assigned_counts[task.id] - task.required_blocks)
        if diff > 0:
            penalty_score += diff * hard_penalty_weight

    # Normalize soft score
    total_required = sum(t.required_blocks for t in tasks)
    if total_required > 0:
        normalized_soft = (soft_score / total_required) * 100.0
    else:
        normalized_soft = 0.0

    final_fitness = normalized_soft - penalty_score
    return (final_fitness,)
