"""Comprehensive unit tests for the Genetic Algorithm Engine and components."""
import random
from datetime import datetime, timedelta
import pytest

from app.models.task import Task
from app.models.availability import FreeSlot
from app.models.schedule import ScheduleResult
from app.core.time_blocks import generate_time_blocks_from_slots
from app.genetic_algorithm.chromosome import Chromosome, EMPTY_GENE
from app.genetic_algorithm.population import initialize_population, create_individual_greedy
from app.genetic_algorithm.fitness import evaluate_chromosome
from app.genetic_algorithm.selection import tournament_selection
from app.genetic_algorithm.crossover import single_point_crossover
from app.genetic_algorithm.mutation import mutate_chromosome
from app.genetic_algorithm.repair import repair_chromosome
from app.genetic_algorithm.engine import GeneticAlgorithmEngine
from app.schedulers.genetic import GeneticScheduler


@pytest.fixture
def base_reference_time():
    return datetime(2026, 8, 25, 8, 0)


@pytest.fixture
def sample_tasks(base_reference_time):
    return [
        Task(
            id="task_cs301",
            task_name="Algorithms Assignment",
            credit_weight=4,
            difficulty_score=9,
            deadline=base_reference_time + timedelta(days=2),
            study_duration_hours=1.5  # 6 blocks
        ),
        Task(
            id="task_cs302",
            task_name="Computer Networks Lab",
            credit_weight=3,
            difficulty_score=6,
            deadline=base_reference_time + timedelta(days=3),
            study_duration_hours=1.0  # 4 blocks
        ),
        Task(
            id="task_cs303",
            task_name="Ethics Essay",
            credit_weight=2,
            difficulty_score=3,
            deadline=base_reference_time + timedelta(days=1),
            study_duration_hours=0.5  # 2 blocks
        )
    ]


@pytest.fixture
def sample_slots():
    return [
        FreeSlot(date="2026-08-25", start="09:00", end="12:00"),  # 3 hours = 12 blocks
        FreeSlot(date="2026-08-26", start="14:00", end="17:00"),  # 3 hours = 12 blocks
    ]


def test_chromosome_representation_and_cloning():
    """Test Chromosome creation, indexing, EMPTY_GENE handling, and cloning."""
    genes = ["t1", "t1", EMPTY_GENE, "t2"]
    chrom = Chromosome(genes)
    chrom.fitness_values = (85.5,)

    assert len(chrom) == 4
    assert chrom[0] == "t1"
    assert chrom[2] is EMPTY_GENE
    assert chrom.fitness_values == (85.5,)

    # Test cloning
    clone = chrom.clone()
    assert clone == chrom
    assert clone.fitness_values == (85.5,)
    
    # Mutating clone should not mutate original
    clone[0] = "t3"
    assert chrom[0] == "t1"
    assert clone[0] == "t3"


def test_population_initialization(sample_tasks, sample_slots, base_reference_time):
    """Test initialize_population produces the required population size with valid individuals."""
    blocks = generate_time_blocks_from_slots(sample_slots)
    pop_size = 30

    population = initialize_population(
        pop_size=pop_size,
        tasks=sample_tasks,
        time_blocks=blocks,
        reference_time=base_reference_time
    )

    assert len(population) == pop_size
    for ind in population:
        assert isinstance(ind, Chromosome)
        assert len(ind) == len(blocks)
        # Check that individual gene values are valid task IDs or EMPTY_GENE
        valid_ids = {t.id for t in sample_tasks} | {EMPTY_GENE}
        assert all(g in valid_ids for g in ind)


def test_fitness_evaluation_soft_and_penalties(sample_tasks, sample_slots, base_reference_time):
    """Test fitness function scoring: positive for valid schedules, penalized for violations."""
    blocks = generate_time_blocks_from_slots(sample_slots)
    
    # Construct a valid chromosome matching required blocks
    valid_ind = create_individual_greedy(sample_tasks, blocks, base_reference_time, shuffle_ratio=0.0)
    fitness_valid = evaluate_chromosome(valid_ind, sample_tasks, blocks, base_reference_time)[0]

    # Valid fitness should be positive
    assert fitness_valid > 0.0

    # Construct an invalid chromosome with duration deficits (all empty)
    empty_ind = Chromosome([EMPTY_GENE] * len(blocks))
    fitness_empty = evaluate_chromosome(empty_ind, sample_tasks, blocks, base_reference_time)[0]

    # Empty chromosome violates required durations for all tasks, hence heavily penalized
    assert fitness_empty < 0.0
    assert fitness_valid > fitness_empty

    # Test deadline penalty
    tight_task = Task(
        id="tight_task",
        task_name="Tight Task",
        credit_weight=3,
        difficulty_score=5,
        deadline=blocks[2].start,  # Deadline before 3rd block
        study_duration_hours=0.5   # 2 blocks needed
    )
    late_chrom = Chromosome([EMPTY_GENE] * len(blocks))
    late_chrom[5] = tight_task.id  # Allocated after deadline
    late_chrom[6] = tight_task.id  # Allocated after deadline

    fitness_late = evaluate_chromosome(late_chrom, [tight_task], blocks, base_reference_time)[0]
    assert fitness_late < 0.0  # Should be heavily penalized for deadline breach


def test_tournament_selection():
    """Test tournament selection picks the best individual from a candidate pool."""
    c1 = Chromosome(["t1"])
    c1.fitness_values = (10.0,)
    c2 = Chromosome(["t2"])
    c2.fitness_values = (50.0,)
    c3 = Chromosome(["t3"])
    c3.fitness_values = (30.0,)

    pop = [c1, c2, c3]
    
    # If tournament size is 3 (whole population), best individual (c2) must always be selected
    winner = tournament_selection(pop, k_tournament=3)
    assert winner.fitness_values == (50.0,)
    assert winner[0] == "t2"


def test_single_point_crossover():
    """Test single point crossover operator behavior."""
    p1 = Chromosome(["A", "A", "A", "A", "A", "A"])
    p2 = Chromosome(["B", "B", "B", "B", "B", "B"])
    p1.fitness_values = (10.0,)
    p2.fitness_values = (20.0,)

    # With cx_prob=1.0, crossover must occur
    random.seed(42)
    c1, c2 = single_point_crossover(p1, p2, cx_prob=1.0)

    assert len(c1) == 6
    assert len(c2) == 6
    assert c1.fitness_values is None
    assert c2.fitness_values is None
    assert "A" in c1 and "B" in c1
    assert "A" in c2 and "B" in c2

    # With cx_prob=0.0, parents are cloned without changes
    c3, c4 = single_point_crossover(p1, p2, cx_prob=0.0)
    assert c3 == p1
    assert c4 == p2


def test_mutation_operator(sample_tasks):
    """Test mutation operator reassigns genes and invalidates fitness."""
    chrom = Chromosome([EMPTY_GENE] * 10)
    chrom.fitness_values = (15.0,)

    # High mutation probability
    mutated = mutate_chromosome(chrom, sample_tasks, mut_prob=1.0)
    assert len(mutated) == 10
    assert mutated.fitness_values is None
    # Genes must be valid task IDs or EMPTY_GENE
    valid_ids = {t.id for t in sample_tasks} | {EMPTY_GENE}
    assert all(g in valid_ids for g in mutated)


def test_repair_operator_comprehensive():
    """Test repair operator enforces deadline, trims excess, and fills missing blocks."""
    slots = [FreeSlot(date="2026-08-25", start="10:00", end="12:00")]  # 8 blocks (10:00 - 12:00)
    blocks = generate_time_blocks_from_slots(slots)
    
    # Task 1: 2 blocks required, deadline at 11:00 (index 4)
    t1 = Task(
        id="t1",
        task_name="Task 1",
        credit_weight=3,
        difficulty_score=5,
        deadline=datetime(2026, 8, 25, 11, 0),
        study_duration_hours=0.5  # 2 blocks
    )
    # Task 2: 2 blocks required, deadline at 12:00 (index 8)
    t2 = Task(
        id="t2",
        task_name="Task 2",
        credit_weight=3,
        difficulty_score=5,
        deadline=datetime(2026, 8, 25, 12, 0),
        study_duration_hours=0.5  # 2 blocks
    )
    tasks = [t1, t2]

    # Deliberately corrupted chromosome:
    # - t1 placed 4 times (excess), with 2 instances past deadline 11:00 (indices 5, 6)
    # - t2 placed 0 times (deficit)
    # - unknown task 't_ghost' placed
    corrupt = Chromosome(["t1", "t1", "t_ghost", EMPTY_GENE, EMPTY_GENE, "t1", "t1", EMPTY_GENE])
    
    repaired = repair_chromosome(corrupt, tasks, blocks)

    # Check that ghost is removed
    assert "t_ghost" not in repaired

    # Check t1 exact count and deadline constraint
    t1_indices = [i for i, g in enumerate(repaired) if g == "t1"]
    assert len(t1_indices) == 2
    for idx in t1_indices:
        assert blocks[idx].end <= t1.deadline

    # Check t2 exact count and deadline constraint
    t2_indices = [i for i, g in enumerate(repaired) if g == "t2"]
    assert len(t2_indices) == 2
    for idx in t2_indices:
        assert blocks[idx].end <= t2.deadline


def test_engine_run_and_plateau_termination(sample_tasks, sample_slots, base_reference_time):
    """Test GeneticAlgorithmEngine executes evolution loop and terminates cleanly."""
    blocks = generate_time_blocks_from_slots(sample_slots)
    engine = GeneticAlgorithmEngine(
        pop_size=20,
        max_generations=50,
        tournament_size=3,
        crossover_prob=0.8,
        mutation_prob=0.02,
        plateau_limit=5,
        random_seed=42
    )

    best_chrom, best_fitness, gen_count, exec_time = engine.run(
        tasks=sample_tasks,
        time_blocks=blocks,
        reference_time=base_reference_time
    )

    assert isinstance(best_chrom, Chromosome)
    assert len(best_chrom) == len(blocks)
    assert best_fitness > 0.0
    assert 1 <= gen_count <= 50
    assert exec_time >= 0


def test_deterministic_seed_reproducibility(sample_tasks, sample_slots, base_reference_time):
    """Test that specifying the same random seed produces identical results."""
    scheduler1 = GeneticScheduler(pop_size=20, max_generations=15, random_seed=12345)
    result1 = scheduler1.schedule(sample_tasks, sample_slots, reference_time=base_reference_time)

    scheduler2 = GeneticScheduler(pop_size=20, max_generations=15, random_seed=12345)
    result2 = scheduler2.schedule(sample_tasks, sample_slots, reference_time=base_reference_time)

    assert result1.success == result2.success
    assert result1.feasible == result2.feasible
    assert result1.fitness_score == result2.fitness_score
    assert result1.generation_count == result2.generation_count
    assert len(result1.schedule) == len(result2.schedule)

    for b1, b2 in zip(result1.schedule, result2.schedule):
        assert b1.task_id == b2.task_id
        assert b1.start == b2.start
        assert b1.end == b2.end


def test_genetic_scheduler_infeasible_cases(base_reference_time):
    """Test GeneticScheduler correctly flags and diagnoses infeasible scenarios."""
    scheduler = GeneticScheduler(pop_size=20, max_generations=10, random_seed=42)

    # 1. Insufficient total study capacity
    tasks = [
        Task(
            id="big_task",
            task_name="Huge Task",
            credit_weight=3,
            difficulty_score=5,
            deadline=base_reference_time + timedelta(days=2),
            study_duration_hours=5.0  # 20 blocks
        )
    ]
    slots = [
        FreeSlot(date="2026-08-25", start="09:00", end="10:00")  # 1 hour = 4 blocks
    ]
    res_capacity = scheduler.schedule(tasks, slots, reference_time=base_reference_time)
    assert res_capacity.success is True
    assert res_capacity.feasible is False
    assert res_capacity.schedule == []
    assert res_capacity.diagnostics is not None
    assert res_capacity.diagnostics.get("shortfall_hours") == 4.0
    assert "exceeds total available time" in res_capacity.diagnostics.get("reason", "")

    # 2. Free slots occur strictly after deadline
    slots_late = [
        FreeSlot(date="2026-08-27", start="09:00", end="17:00")  # 2 days after deadline
    ]
    res_deadline = scheduler.schedule(tasks, slots_late, reference_time=base_reference_time)
    assert res_deadline.success is True
    assert res_deadline.feasible is False
    assert res_deadline.schedule == []


def test_genetic_scheduler_empty_inputs(base_reference_time):
    """Test GeneticScheduler handles empty task or slot lists gracefully."""
    scheduler = GeneticScheduler(random_seed=42)

    res_no_tasks = scheduler.schedule([], [FreeSlot(date="2026-08-25", start="09:00", end="10:00")])
    assert res_no_tasks.success is True
    assert res_no_tasks.feasible is False
    assert res_no_tasks.schedule == []

    task = Task(
        id="t1",
        task_name="T1",
        credit_weight=3,
        difficulty_score=5,
        deadline=base_reference_time + timedelta(days=1),
        study_duration_hours=1.0
    )
    res_no_slots = scheduler.schedule([task], [])
    assert res_no_slots.success is True
    assert res_no_slots.feasible is False
    assert res_no_slots.schedule == []


def test_genetic_scheduler_benchmark_multi_task(sample_tasks, sample_slots, base_reference_time):
    """Test full benchmark scheduling for multiple tasks with constraint verification."""
    scheduler = GeneticScheduler(
        pop_size=30,
        max_generations=25,
        tournament_size=3,
        crossover_prob=0.8,
        mutation_prob=0.02,
        plateau_limit=10,
        random_seed=42
    )

    result = scheduler.schedule(sample_tasks, sample_slots, reference_time=base_reference_time)

    assert result.success is True
    assert result.feasible is True
    assert result.fitness_score is not None
    assert result.fitness_score > 0.0
    assert result.generation_count > 0

    # Total blocks: 6 + 4 + 2 = 12 blocks (3 hours)
    assert len(result.schedule) == 12

    # Verify task block counts
    counts = {}
    for block in result.schedule:
        counts[block.task_id] = counts.get(block.task_id, 0) + 1
    assert counts["task_cs301"] == 6
    assert counts["task_cs302"] == 4
    assert counts["task_cs303"] == 2

    # Verify all blocks are within deadlines
    task_map = {t.id: t for t in sample_tasks}
    for block in result.schedule:
        assert block.end <= task_map[block.task_id].deadline
