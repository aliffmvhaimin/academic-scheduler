"""Genetic Algorithm Engine for Academic Task Scheduling."""
import random
import time
from datetime import datetime
from typing import List, Tuple, Optional, Dict, Any
from app.models.task import Task
from app.models.schedule import ScheduleBlock, ScheduleResult
from app.core.time_blocks import TimeBlock, generate_time_blocks_from_slots
from app.core.constraints import check_preliminary_feasibility, validate_schedule_constraints
from app.genetic_algorithm.chromosome import Chromosome, EMPTY_GENE
from app.genetic_algorithm.population import initialize_population
from app.genetic_algorithm.fitness import evaluate_chromosome
from app.genetic_algorithm.selection import tournament_selection
from app.genetic_algorithm.crossover import single_point_crossover
from app.genetic_algorithm.mutation import mutate_chromosome
from app.genetic_algorithm.repair import repair_chromosome


class GeneticAlgorithmEngine:
    """
    Core engine executing the Genetic Algorithm optimization for study schedules.
    """
    def __init__(
        self,
        pop_size: int = 100,
        max_generations: int = 200,
        tournament_size: int = 3,
        crossover_prob: float = 0.8,
        mutation_prob: float = 0.02,
        plateau_limit: int = 20,
        random_seed: Optional[int] = None
    ):
        self.pop_size = pop_size
        self.max_generations = max_generations
        self.tournament_size = tournament_size
        self.crossover_prob = crossover_prob
        self.mutation_prob = mutation_prob
        self.plateau_limit = plateau_limit
        self.random_seed = random_seed

    def run(
        self,
        tasks: List[Task],
        time_blocks: List[TimeBlock],
        reference_time: datetime
    ) -> Tuple[Chromosome, float, int, int]:
        """
        Executes the Genetic Algorithm loop.

        Returns:
            (best_chromosome, best_fitness, generation_count, execution_time_ms)
        """
        start_time = time.perf_counter()

        if self.random_seed is not None:
            random.seed(self.random_seed)

        # 1. Initialize population
        population = initialize_population(
            pop_size=self.pop_size,
            tasks=tasks,
            time_blocks=time_blocks,
            reference_time=reference_time
        )

        # 2. Initial evaluation
        for ind in population:
            ind.fitness_values = evaluate_chromosome(ind, tasks, time_blocks, reference_time)

        best_ind = max(population, key=lambda ind: ind.fitness_values[0]).clone()
        best_fitness = best_ind.fitness_values[0]

        plateau_count = 0
        gen_count = 0

        # 3. Evolution loop
        for gen in range(1, self.max_generations + 1):
            gen_count = gen
            new_population: List[Chromosome] = []

            # Elitism: preserve top 2 individuals
            sorted_pop = sorted(population, key=lambda ind: ind.fitness_values[0], reverse=True)
            new_population.append(sorted_pop[0].clone())
            if len(sorted_pop) > 1:
                new_population.append(sorted_pop[1].clone())

            # Produce offspring
            while len(new_population) < self.pop_size:
                p1 = tournament_selection(population, k_tournament=self.tournament_size)
                p2 = tournament_selection(population, k_tournament=self.tournament_size)

                c1, c2 = single_point_crossover(p1, p2, cx_prob=self.crossover_prob)
                c1 = mutate_chromosome(c1, tasks, mut_prob=self.mutation_prob)
                c2 = mutate_chromosome(c2, tasks, mut_prob=self.mutation_prob)

                # Repair operator
                c1 = repair_chromosome(c1, tasks, time_blocks)
                c2 = repair_chromosome(c2, tasks, time_blocks)

                c1.fitness_values = evaluate_chromosome(c1, tasks, time_blocks, reference_time)
                c2.fitness_values = evaluate_chromosome(c2, tasks, time_blocks, reference_time)

                new_population.append(c1)
                if len(new_population) < self.pop_size:
                    new_population.append(c2)

            population = new_population

            current_best = max(population, key=lambda ind: ind.fitness_values[0])
            if current_best.fitness_values[0] > best_fitness + 1e-4:
                best_fitness = current_best.fitness_values[0]
                best_ind = current_best.clone()
                plateau_count = 0
            else:
                plateau_count += 1

            # Termination condition: plateau
            if plateau_count >= self.plateau_limit:
                break

        exec_time_ms = int((time.perf_counter() - start_time) * 1000)
        return best_ind, best_fitness, gen_count, exec_time_ms
