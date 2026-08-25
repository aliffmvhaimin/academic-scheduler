"""Unit tests for the greedy priority scheduler."""
from datetime import datetime, timedelta
from app.models.task import Task
from app.models.availability import FreeSlot
from app.schedulers.greedy import GreedyScheduler


def test_greedy_scheduler_success():
    ref_time = datetime(2026, 8, 25, 8, 0)
    tasks = [
        Task(id="task-1", task_name="Math", credit_weight=4, difficulty_score=8,
             deadline=ref_time + timedelta(days=2), study_duration_hours=1.0),
        Task(id="task-2", task_name="English", credit_weight=2, difficulty_score=3,
             deadline=ref_time + timedelta(days=2), study_duration_hours=0.5)
    ]
    slots = [
        FreeSlot(date="2026-08-25", start="09:00", end="12:00")  # 3 hours = 12 blocks
    ]
    scheduler = GreedyScheduler()
    result = scheduler.schedule(tasks, slots, reference_time=ref_time)

    assert result.success is True
    assert result.feasible is True
    assert len(result.schedule) == 6  # 4 blocks (1h) + 2 blocks (0.5h) = 6 blocks
    assert result.fitness_score is not None


def test_greedy_scheduler_infeasible_deadline():
    ref_time = datetime(2026, 8, 25, 8, 0)
    tasks = [
        Task(id="task-urgent", task_name="Urgent", credit_weight=5, difficulty_score=9,
             deadline=datetime(2026, 8, 25, 9, 30), study_duration_hours=2.0)  # Requires 2h, only 1.5h before 9:30
    ]
    slots = [
        FreeSlot(date="2026-08-25", start="08:00", end="12:00")
    ]
    scheduler = GreedyScheduler()
    result = scheduler.schedule(tasks, slots, reference_time=ref_time)

    assert result.success is True
    assert result.feasible is False
    assert result.schedule == []
    assert result.diagnostics is not None
    assert "shortfall_hours" in result.diagnostics
