"""Population initialization for Genetic Algorithm."""
import random
from typing import List
from datetime import datetime
from app.models.task import Task
from app.core.time_blocks import TimeBlock
from app.core.priority import calculate_task_priority
from app.genetic_algorithm.chromosome import Chromosome, EMPTY_GENE
from app.genetic_algorithm.repair import repair_chromosome


def create_individual_greedy(
    tasks: List[Task],
    time_blocks: List[TimeBlock],
    reference_time: datetime,
    shuffle_ratio: float = 0.0
) -> Chromosome:
    """
    Creates a single chromosome using heuristic priority or randomized task ordering.
    """
    chromosome = Chromosome([EMPTY_GENE] * len(time_blocks))
    task_order = list(tasks)

    if shuffle_ratio > 0.0:
        # Partially shuffle or fully random order
        if random.random() < shuffle_ratio:
            random.shuffle(task_order)
        else:
            # Perturb priorities with random noise
            task_order.sort(
                key=lambda t: calculate_task_priority(t, reference_time) * random.uniform(0.7, 1.3),
                reverse=True
            )
    else:
        # Strict priority ordering
        task_order.sort(
            key=lambda t: calculate_task_priority(t, reference_time),
            reverse=True
        )

    occupied = set()
    for task in task_order:
        assigned = 0
        valid_indices = [
            i for i, b in enumerate(time_blocks)
            if i not in occupied and b.end <= task.deadline
        ]
        # Distribute / pick slots
        for idx in valid_indices:
            chromosome[idx] = task.id
            occupied.add(idx)
            assigned += 1
            if assigned == task.required_blocks:
                break

    return repair_chromosome(chromosome, tasks, time_blocks)


def initialize_population(
    pop_size: int,
    tasks: List[Task],
    time_blocks: List[TimeBlock],
    reference_time: datetime
) -> List[Chromosome]:
    """
    Initializes a diverse population of chromosomes.
    Includes deterministic greedy seed + randomized priority seeds + randomized permutations.
    """
    population: List[Chromosome] = []

    # 1. Deterministic greedy seed
    greedy_seed = create_individual_greedy(tasks, time_blocks, reference_time, shuffle_ratio=0.0)
    population.append(greedy_seed)

    # 2. Perturbed heuristic individuals
    while len(population) < pop_size:
        ind = create_individual_greedy(tasks, time_blocks, reference_time, shuffle_ratio=0.7)
        population.append(ind)

    return population
