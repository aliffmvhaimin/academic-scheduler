"""Benchmark runner comparing Greedy baseline vs Genetic Algorithm."""
import json
import os
import sys
from datetime import datetime

# Add backend to path for importing modules
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "backend")))

from app.models.task import Task
from app.models.availability import FreeSlot
from app.schedulers.greedy import GreedyScheduler
from app.schedulers.genetic import GeneticScheduler

DATASETS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "datasets"))
RESULTS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "results"))


def parse_scenario(data):
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


def run_all_benchmarks(seeds=[42, 101, 2024, 777, 9999]):
    os.makedirs(RESULTS_DIR, exist_ok=True)
    scenario_files = ["scenario_a.json", "scenario_b.json", "scenario_c.json", "scenario_d.json"]
    all_results = {}

    greedy_scheduler = GreedyScheduler()

    for sf in scenario_files:
        filepath = os.path.join(DATASETS_DIR, sf)
        if not os.path.exists(filepath):
            continue

        with open(filepath, "r", encoding="utf-8") as f:
            sc_data = json.load(f)

        tasks, slots = parse_scenario(sc_data)
        sc_name = sc_data["name"]
        print(f"\n==========================================")
        print(f"Running Benchmark: {sc_name}")
        print(f"==========================================")

        # 1. Run Greedy Baseline
        greedy_res = greedy_scheduler.schedule(tasks, slots)
        print(f"  [Greedy] Feasible: {greedy_res.feasible} | Score: {greedy_res.fitness_score} | Time: {greedy_res.execution_time_ms}ms")

        # 2. Run GA across seeds
        ga_seed_runs = []
        for seed in seeds:
            ga_scheduler = GeneticScheduler(
                pop_size=50,
                max_generations=50,
                random_seed=seed
            )
            ga_res = ga_scheduler.schedule(tasks, slots)
            ga_seed_runs.append({
                "seed": seed,
                "feasible": ga_res.feasible,
                "fitness_score": ga_res.fitness_score,
                "generation_count": ga_res.generation_count,
                "execution_time_ms": ga_res.execution_time_ms
            })
            print(f"  [GA seed={seed}] Feasible: {ga_res.feasible} | Score: {ga_res.fitness_score} | Gen: {ga_res.generation_count} | Time: {ga_res.execution_time_ms}ms")

        all_results[sf] = {
            "scenario": sc_name,
            "greedy": {
                "feasible": greedy_res.feasible,
                "fitness_score": greedy_res.fitness_score,
                "execution_time_ms": greedy_res.execution_time_ms,
                "block_count": len(greedy_res.schedule)
            },
            "genetic_algorithm": ga_seed_runs
        }

    results_file = os.path.join(RESULTS_DIR, "benchmark_results.json")
    with open(results_file, "w", encoding="utf-8") as f:
        json.dump(all_results, f, indent=2)
    print(f"\nBenchmark results saved to {results_file}")


if __name__ == "__main__":
    run_all_benchmarks()
