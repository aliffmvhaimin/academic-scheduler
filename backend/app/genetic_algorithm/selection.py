"""Tournament selection operator for Genetic Algorithm."""
import random
from typing import List
from app.genetic_algorithm.chromosome import Chromosome


def tournament_selection(
    population: List[Chromosome],
    k_tournament: int = 3
) -> Chromosome:
    """
    Selects one chromosome using tournament selection of size k.
    """
    selected_sample = random.sample(population, min(k_tournament, len(population)))
    best = max(selected_sample, key=lambda ind: ind.fitness_values[0] if ind.fitness_values else float('-inf'))
    return best.clone()
