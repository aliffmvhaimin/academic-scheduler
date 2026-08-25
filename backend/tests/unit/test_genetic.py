"""Unit tests for the Genetic Algorithm scheduler and genetic operators."""
from datetime import datetime, timedelta
from app.models.task import Task
from app.models.availability import FreeSlot
from app.core.time_blocks import generate_time_blocks_from_slots
from app.genetic_algorithm.chromosome import Chromosome, EMPTY_GENE
from app.genetic_algorithm.crossover import single_point_crossover
from app.genetic_algorithm.mutation import mutate_chromosome
from app.genetic_algorithm.repair import repair_chromosome
from app.schedulers.genetic import GeneticScheduler


def test_genetic_crossover_and_mutation():
    p1 = Chromosome(["t1", "t1", EMPTY_GENE, EMPTY_GENE])
    p2 = Chromosome([EMPTY_GENE, EMPTY_GENE, "t2", "t2"])

    c1, c2 = single_point_crossover(p1, p2, cx_prob=1.0)
    assert len(c1) == 4
    assert len(c2) == 4

    tasks = [
        Task(id="t1", task_name="T1", credit_weight=3, difficulty_score=5,
             deadline=datetime(2026, 8, 25, 20, 0), study_duration_hours=0.5),
        Task(id="t2", task_name="T2", credit_weight=3, difficulty_score=5,
             deadline=datetime(2026, 8, 25, 20, 0), study_duration_hours=0.5)
    ]
    mutated = mutate_chromosome(c1, tasks, mut_prob=1.0)
    assert len(mutated) == 4


def test_repair_operator():
    slots = [FreeSlot(date="2026-08-25", start="10:00", end="12:00")]  # 8 blocks
    blocks = generate_time_blocks_from_slots(slots)
    task = Task(id="t1", task_name="T1", credit_weight=3, difficulty_score=5,
                deadline=datetime(2026, 8, 25, 11, 0), study_duration_hours=0.5)  # 2 blocks needed, deadline at 11:00 (block index 4)

    # Deliberately corrupt chromosome: 4 allocations of t1, some after deadline
    corrupt = Chromosome(["t1", "t1", "t1", "t1", "t1", EMPTY_GENE, EMPTY_GENE, EMPTY_GENE])
    repaired = repair_chromosome(corrupt, [task], blocks)

    # Exactly 2 allocations of t1, all before deadline 11:00
    t1_indices = [i for i, g in enumerate(repaired) if g == "t1"]
    assert len(t1_indices) == 2
    for idx in t1_indices:
        assert blocks[idx].end <= task.deadline


def test_genetic_scheduler_execution():
    ref_time = datetime(2026, 8, 25, 8, 0)
    tasks = [
        Task(id="t1", task_name="Algorithms", credit_weight=4, difficulty_score=9,
             deadline=ref_time + timedelta(days=2), study_duration_hours=1.0),
        Task(id="t2", task_name="Networks", credit_weight=3, difficulty_score=6,
             deadline=ref_time + timedelta(days=2), study_duration_hours=0.75)
    ]
    slots = [
        FreeSlot(date="2026-08-25", start="09:00", end="13:00")  # 4 hours = 16 blocks
    ]
    scheduler = GeneticScheduler(
        pop_size=20,
        max_generations=15,
        random_seed=42
    )
    result = scheduler.schedule(tasks, slots, reference_time=ref_time)

    assert result.success is True
    assert result.feasible is True
    assert len(result.schedule) == 7  # 4 blocks (1h) + 3 blocks (0.75h) = 7 blocks
    assert result.fitness_score is not None
