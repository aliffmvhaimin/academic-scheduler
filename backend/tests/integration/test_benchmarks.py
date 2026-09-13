"""Integration and regression tests for benchmark scenarios and metrics."""
import json
import os
import pytest
from datetime import datetime
from app.models.task import Task
from app.models.availability import FreeSlot
from app.schedulers.greedy import GreedyScheduler
from app.schedulers.genetic import GeneticScheduler

# Locate benchmark datasets relative to project root
DATASETS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "experiments", "datasets"))


def load_dataset(filename: str):
    filepath = os.path.join(DATASETS_DIR, filename)
    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)

    tasks = [
        Task(
            id=t["id"],
            task_name=t["task_name"],
            credit_weight=t["credit_weight"],
            difficulty_score=t["difficulty_score"],
            deadline=datetime.fromisoformat(t["deadline"]),
            study_duration_hours=float(t["study_duration_hours"])
        )
        for t in data["tasks"]
    ]
    slots = [
        FreeSlot(date=s["date"], start=s["start"], end=s["end"])
        for s in data["free_slots"]
    ]
    return tasks, slots


def test_scenario_datasets_exist_and_valid():
    """Verify all 4 benchmark scenario datasets exist and parse into valid models."""
    scenarios = ["scenario_a.json", "scenario_b.json", "scenario_c.json", "scenario_d.json"]
    for sc in scenarios:
        tasks, slots = load_dataset(sc)
        assert len(tasks) > 0, f"{sc} must have at least one task"
        assert len(slots) > 0, f"{sc} must have at least one free slot"
        for t in tasks:
            assert t.required_blocks == int(round(t.study_duration_hours * 4))
            assert 1 <= t.credit_weight <= 6
            assert 1 <= t.difficulty_score <= 10


def test_scenario_a_benchmark_execution():
    """Verify Scenario A (low complexity) is feasible on both algorithms, with GA optimizing fitness."""
    tasks, slots = load_dataset("scenario_a.json")

    greedy = GreedyScheduler()
    greedy_res = greedy.schedule(tasks, slots)
    assert greedy_res.feasible is True
    assert greedy_res.fitness_score is not None

    ga = GeneticScheduler(pop_size=50, max_generations=25, random_seed=42)
    ga_res = ga.schedule(tasks, slots)
    assert ga_res.feasible is True
    assert ga_res.fitness_score is not None
    assert ga_res.fitness_score > greedy_res.fitness_score
    assert len(ga_res.schedule) == sum(t.required_blocks for t in tasks)


def test_scenario_b_ga_solves_where_greedy_fails():
    """Verify Scenario B (medium complexity) exposes Greedy local failure while GA finds a feasible schedule."""
    tasks, slots = load_dataset("scenario_b.json")

    greedy = GreedyScheduler()
    greedy_res = greedy.schedule(tasks, slots)
    assert greedy_res.feasible is False

    ga = GeneticScheduler(pop_size=50, max_generations=50, random_seed=777)
    ga_res = ga.schedule(tasks, slots)
    assert ga_res.feasible is True
    assert ga_res.fitness_score is not None
    assert len(ga_res.schedule) == sum(t.required_blocks for t in tasks)

    # Verify zero deadline violations
    task_map = {t.id: t for t in tasks}
    for b in ga_res.schedule:
        assert b.end <= task_map[b.task_id].deadline


def test_scenario_c_high_complexity_constraints():
    """Verify Scenario C (high complexity) succeeds under GA with hard constraints strictly satisfied."""
    tasks, slots = load_dataset("scenario_c.json")

    ga = GeneticScheduler(pop_size=50, max_generations=50, random_seed=42)
    ga_res = ga.schedule(tasks, slots)
    assert ga_res.feasible is True
    assert ga_res.fitness_score is not None

    total_required = sum(t.required_blocks for t in tasks)
    assert len(ga_res.schedule) == total_required

    # No overlapping blocks
    intervals = [(b.start, b.end) for b in ga_res.schedule]
    assert len(intervals) == len(set(intervals))


def test_scenario_d_infeasible_deficit_detection():
    """Verify Scenario D (infeasible horizon) terminates immediately with feasible=False for both schedulers."""
    tasks, slots = load_dataset("scenario_d.json")

    greedy = GreedyScheduler()
    greedy_res = greedy.schedule(tasks, slots)
    assert greedy_res.feasible is False
    assert len(greedy_res.schedule) == 0

    ga = GeneticScheduler(pop_size=50, max_generations=20, random_seed=42)
    ga_res = ga.schedule(tasks, slots)
    assert ga_res.feasible is False
    assert len(ga_res.schedule) == 0
    assert ga_res.execution_time_ms < 50  # Must abort fast without running generations


def test_ga_seed_reproducibility():
    """Verify that identical random seeds yield identical schedules and fitness scores."""
    tasks, slots = load_dataset("scenario_a.json")

    ga1 = GeneticScheduler(pop_size=30, max_generations=20, random_seed=123)
    res1 = ga1.schedule(tasks, slots)

    ga2 = GeneticScheduler(pop_size=30, max_generations=20, random_seed=123)
    res2 = ga2.schedule(tasks, slots)

    assert res1.feasible == res2.feasible
    assert res1.fitness_score == res2.fitness_score
    assert len(res1.schedule) == len(res2.schedule)
    for b1, b2 in zip(res1.schedule, res2.schedule):
        assert b1.task_id == b2.task_id
        assert b1.start == b2.start
        assert b1.end == b2.end
