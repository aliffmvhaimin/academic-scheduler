"""Repair operator to enforce hard constraints on chromosomes."""
import random
from typing import List, Dict, Set
from app.models.task import Task
from app.core.time_blocks import TimeBlock
from app.genetic_algorithm.chromosome import Chromosome, EMPTY_GENE


def repair_chromosome(
    chromosome: Chromosome,
    tasks: List[Task],
    time_blocks: List[TimeBlock]
) -> Chromosome:
    """
    Repairs a chromosome to satisfy hard constraints:
    1. Removes assignments violating task deadlines (C2).
    2. Trims excess allocations if a task has > required_blocks.
    3. Fills deficits if a task has < required_blocks by finding valid available empty slots.
    4. Preserves valid gene assignments where possible.
    """
    repaired = chromosome.clone()
    task_map: Dict[str, Task] = {t.id: t for t in tasks}

    # Step 1: Remove invalid tasks or deadline-violating assignments
    for i, gene in enumerate(repaired):
        if gene is EMPTY_GENE:
            continue
        task = task_map.get(gene)
        if not task:
            repaired[i] = EMPTY_GENE
            continue

        block = time_blocks[i]
        if block.end > task.deadline:
            repaired[i] = EMPTY_GENE

    # Step 2: Count allocations and trim excess
    task_indices: Dict[str, List[int]] = {t.id: [] for t in tasks}
    for i, gene in enumerate(repaired):
        if gene is not EMPTY_GENE and gene in task_indices:
            task_indices[gene].append(i)

    for task in tasks:
        indices = task_indices[task.id]
        if len(indices) > task.required_blocks:
            # Randomly remove excess blocks
            excess_count = len(indices) - task.required_blocks
            to_remove = random.sample(indices, excess_count)
            for idx in to_remove:
                repaired[idx] = EMPTY_GENE
            task_indices[task.id] = [idx for idx in indices if idx not in to_remove]

    # Step 3: Fill deficits for tasks with fewer blocks than required
    # Find all empty slots that are valid before the task's deadline
    for task in tasks:
        current_count = len(task_indices[task.id])
        needed = task.required_blocks - current_count
        if needed <= 0:
            continue

        # Find empty slots before deadline
        available_empty_indices = [
            i for i, gene in enumerate(repaired)
            if gene is EMPTY_GENE and time_blocks[i].end <= task.deadline
        ]

        if available_empty_indices:
            # Pick slots (preferring earlier slots or random sample)
            slots_to_fill = available_empty_indices[:needed]
            for idx in slots_to_fill:
                repaired[idx] = task.id
                task_indices[task.id].append(idx)

    repaired.fitness_values = None
    return repaired
