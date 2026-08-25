"""Random block reassignment mutation operator."""
import random
from typing import List
from app.models.task import Task
from app.genetic_algorithm.chromosome import Chromosome, EMPTY_GENE


def mutate_chromosome(
    chromosome: Chromosome,
    tasks: List[Task],
    mut_prob: float = 0.02
) -> Chromosome:
    """
    Mutates chromosome by randomly reassigning genes with probability mut_prob.
    A gene can be reassigned to a valid task ID or EMPTY_GENE.
    """
    possible_genes = [t.id for t in tasks] + [EMPTY_GENE]
    mutated = chromosome.clone()

    for i in range(len(mutated)):
        if random.random() < mut_prob:
            mutated[i] = random.choice(possible_genes)

    mutated.fitness_values = None
    return mutated
