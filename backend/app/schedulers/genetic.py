"""Genetic algorithm scheduler implementing BaseScheduler."""
import time
from datetime import datetime
from typing import List, Optional
from app.models.task import Task
from app.models.availability import FreeSlot
from app.models.schedule import ScheduleBlock, ScheduleResult
from app.schedulers.base import BaseScheduler
from app.core.time_blocks import generate_time_blocks_from_slots
from app.core.constraints import check_preliminary_feasibility, validate_schedule_constraints
from app.genetic_algorithm.engine import GeneticAlgorithmEngine
from app.genetic_algorithm.chromosome import EMPTY_GENE


class GeneticScheduler(BaseScheduler):
    """
    Academic task scheduler utilizing the Genetic Algorithm.
    Optimizes soft objectives while enforcing hard constraints through construction and repair.
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
        self.engine = GeneticAlgorithmEngine(
            pop_size=pop_size,
            max_generations=max_generations,
            tournament_size=tournament_size,
            crossover_prob=crossover_prob,
            mutation_prob=mutation_prob,
            plateau_limit=plateau_limit,
            random_seed=random_seed
        )

    def schedule(
        self,
        tasks: List[Task],
        free_slots: List[FreeSlot],
        reference_time: Optional[datetime] = None,
        **kwargs
    ) -> ScheduleResult:
        start_time_perf = time.perf_counter()

        if not tasks or not free_slots:
            return ScheduleResult(
                success=True,
                feasible=False,
                fitness_score=None,
                generation_count=0,
                execution_time_ms=0,
                schedule=[],
                diagnostics={"reason": "Empty task list or free slots provided."}
            )

        time_blocks = generate_time_blocks_from_slots(free_slots)
        if not time_blocks:
            return ScheduleResult(
                success=True,
                feasible=False,
                fitness_score=None,
                generation_count=0,
                execution_time_ms=0,
                schedule=[],
                diagnostics={"reason": "No valid 15-minute time blocks could be generated."}
            )

        if reference_time is None:
            reference_time = time_blocks[0].start

        # Preliminary capacity and deadline feasibility check
        is_prelim_feasible, prelim_diag = check_preliminary_feasibility(tasks, time_blocks)
        if not is_prelim_feasible:
            exec_time = int((time.perf_counter() - start_time_perf) * 1000)
            return ScheduleResult(
                success=True,
                feasible=False,
                fitness_score=None,
                generation_count=self.engine.max_generations,
                execution_time_ms=exec_time,
                schedule=[],
                diagnostics=prelim_diag
            )

        # Execute GA Engine
        best_chromosome, best_fitness, gen_count, exec_time_ms = self.engine.run(
            tasks=tasks,
            time_blocks=time_blocks,
            reference_time=reference_time
        )

        # Convert best chromosome into ScheduleBlocks
        scheduled_blocks: List[ScheduleBlock] = []
        for i, gene in enumerate(best_chromosome):
            if gene is not EMPTY_GENE:
                block = time_blocks[i]
                scheduled_blocks.append(ScheduleBlock(
                    task_id=gene,
                    start=block.start,
                    end=block.end
                ))

        scheduled_blocks.sort(key=lambda b: b.start)

        # Validate hard constraints on best chromosome
        is_valid, violations = validate_schedule_constraints(scheduled_blocks, tasks, time_blocks)

        if not is_valid:
            return ScheduleResult(
                success=True,
                feasible=False,
                fitness_score=None,
                generation_count=gen_count,
                execution_time_ms=exec_time_ms,
                schedule=[],
                diagnostics={"violations": [v.to_dict() for v in violations]}
            )

        return ScheduleResult(
            success=True,
            feasible=True,
            fitness_score=round(best_fitness, 4),
            generation_count=gen_count,
            execution_time_ms=exec_time_ms,
            schedule=scheduled_blocks,
            diagnostics=None
        )
