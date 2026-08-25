"""Generates benchmark scenario datasets for experimental evaluation."""
import json
import os
from datetime import datetime, timedelta

DATASETS_DIR = os.path.join(os.path.dirname(__file__), "..", "datasets")


def generate_benchmark_datasets():
    os.makedirs(DATASETS_DIR, exist_ok=True)
    base_time = datetime(2026, 9, 1, 8, 0, 0)

    # Scenario A: Low Complexity (4 tasks, ample availability)
    scenario_a = {
        "name": "Scenario A - Low Complexity",
        "description": "4 tasks with generous availability over 3 days",
        "tasks": [
            {
                "id": "task-a1",
                "task_name": "Intro to Programming Assignment",
                "credit_weight": 3,
                "difficulty_score": 4,
                "deadline": (base_time + timedelta(days=2, hours=12)).isoformat(),
                "study_duration_hours": 2.0
            },
            {
                "id": "task-a2",
                "task_name": "Calculus I Tutorial",
                "credit_weight": 4,
                "difficulty_score": 7,
                "deadline": (base_time + timedelta(days=2, hours=18)).isoformat(),
                "study_duration_hours": 2.5
            },
            {
                "id": "task-a3",
                "task_name": "Technical Writing Lab Report",
                "credit_weight": 2,
                "difficulty_score": 3,
                "deadline": (base_time + timedelta(days=3, hours=10)).isoformat(),
                "study_duration_hours": 1.5
            },
            {
                "id": "task-a4",
                "task_name": "Discrete Mathematics Problem Set",
                "credit_weight": 3,
                "difficulty_score": 6,
                "deadline": (base_time + timedelta(days=3, hours=16)).isoformat(),
                "study_duration_hours": 2.0
            }
        ],
        "free_slots": [
            {"date": "2026-09-01", "start": "09:00", "end": "13:00"}, # 4h
            {"date": "2026-09-01", "start": "15:00", "end": "19:00"}, # 4h
            {"date": "2026-09-02", "start": "09:00", "end": "13:00"}, # 4h
            {"date": "2026-09-02", "start": "15:00", "end": "19:00"}, # 4h
            {"date": "2026-09-03", "start": "09:00", "end": "13:00"}  # 4h
        ]
    }

    # Scenario B: Medium Complexity (8 tasks, moderate availability)
    scenario_b = {
        "name": "Scenario B - Medium Complexity",
        "description": "8 tasks with moderate availability and staggered deadlines",
        "tasks": [
            {
                "id": f"task-b{i+1}",
                "task_name": f"Coursework Module {i+1}",
                "credit_weight": (i % 5) + 2,
                "difficulty_score": (i * 2 % 9) + 2,
                "deadline": (base_time + timedelta(days=(i // 2) + 1, hours=14 + (i % 4) * 2)).isoformat(),
                "study_duration_hours": 1.5 + (i % 3) * 0.5
            }
            for i in range(8)
        ],
        "free_slots": [
            {"date": f"2026-09-0{day}", "start": "10:00", "end": "13:00"}
            for day in range(1, 6)
        ] + [
            {"date": f"2026-09-0{day}", "start": "16:00", "end": "19:00"}
            for day in range(1, 6)
        ]
    }

    # Scenario C: High Complexity (15 tasks, tight availability, overlapping deadlines)
    scenario_c = {
        "name": "Scenario C - High Complexity",
        "description": "15 tasks under constrained availability with tight deadlines",
        "tasks": [
            {
                "id": f"task-c{i+1}",
                "task_name": f"Final Prep Component {i+1}",
                "credit_weight": (i % 6) + 1,
                "difficulty_score": ((i * 3) % 10) + 1,
                "deadline": (base_time + timedelta(days=(i % 4) + 1, hours=12 + (i % 6) * 2)).isoformat(),
                "study_duration_hours": 1.0 + (i % 4) * 0.25
            }
            for i in range(15)
        ],
        "free_slots": [
            {"date": f"2026-09-0{day}", "start": "08:00", "end": "12:00"}
            for day in range(1, 5)
        ] + [
            {"date": f"2026-09-0{day}", "start": "14:00", "end": "18:00"}
            for day in range(1, 5)
        ]
    }

    # Scenario D: Infeasible (Required duration strictly exceeds available free time)
    scenario_d = {
        "name": "Scenario D - Infeasible Horizon",
        "description": "Total required study time (16 hours) exceeds available slots (6 hours)",
        "tasks": [
            {
                "id": "task-d1",
                "task_name": "Capstone Project Final Draft",
                "credit_weight": 6,
                "difficulty_score": 10,
                "deadline": (base_time + timedelta(days=1, hours=18)).isoformat(),
                "study_duration_hours": 16.0
            }
        ],
        "free_slots": [
            {"date": "2026-09-01", "start": "09:00", "end": "15:00"} # 6h total
        ]
    }

    scenarios = {
        "scenario_a.json": scenario_a,
        "scenario_b.json": scenario_b,
        "scenario_c.json": scenario_c,
        "scenario_d.json": scenario_d
    }

    for filename, data in scenarios.items():
        filepath = os.path.join(DATASETS_DIR, filename)
        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
        print(f"Generated {filepath}")


if __name__ == "__main__":
    generate_benchmark_datasets()
