"""Single-point crossover operator."""
import random
from typing import Tuple
from app.genetic_algorithm.chromosome import Chromosome


def single_point_crossover(
    parent1: Chromosome,
    parent2: Chromosome,
    cx_prob: float = 0.8
) -> Tuple[Chromosome, Chromosome]:
    """
    Performs single-point crossover between two chromosomes with probability cx_prob.
    Returns two child chromosomes.
    """
    child1 = parent1.clone()
    child2 = parent2.clone()

    if len(parent1) < 2 or random.random() > cx_prob:
        return child1, child2

    # Choose split point
    point = random.randint(1, len(parent1) - 1)

    # Swap genes after point
    child1[point:] = parent2[point:]
    child2[point:] = parent1[point:]

    # Invalidate cached fitness
    child1.fitness_values = None
    child2.fitness_values = None

    return child1, child2
