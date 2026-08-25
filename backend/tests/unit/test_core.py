"""Unit tests for core logic: time blocks, priority, and constraints."""
import pytest
from datetime import datetime, timedelta
from app.models.task import Task
from app.models.availability import FreeSlot
from app.models.schedule import ScheduleBlock
from app.core.time_blocks import generate_time_blocks_from_slots, hours_to_blocks, blocks_to_hours
from app.core.priority import calculate_task_priority, calculate_urgency_score
from app.core.constraints import (
    check_preliminary_feasibility,
    validate_schedule_constraints,
)


def test_time_block_generation():
    slots = [
        FreeSlot(date="2026-08-25", start="10:00", end="11:30")  # 1.5 hours = 6 blocks
    ]
    blocks = generate_time_blocks_from_slots(slots)
    assert len(blocks) == 6
    assert blocks[0].start == datetime(2026, 8, 25, 10, 0)
    assert blocks[0].end == datetime(2026, 8, 25, 10, 15)
    assert blocks[-1].end == datetime(2026, 8, 25, 11, 30)


def test_priority_calculation():
    ref_time = datetime(2026, 8, 25, 8, 0)
    urgent_task = Task(
        id="t1", task_name="Urgent", credit_weight=6, difficulty_score=10,
        deadline=ref_time + timedelta(hours=12), study_duration_hours=2.0
    )
    relaxed_task = Task(
        id="t2", task_name="Relaxed", credit_weight=1, difficulty_score=2,
        deadline=ref_time + timedelta(days=7), study_duration_hours=2.0
    )
    p_urgent = calculate_task_priority(urgent_task, ref_time)
    p_relaxed = calculate_task_priority(relaxed_task, ref_time)
    assert p_urgent > p_relaxed


def test_preliminary_feasibility_infeasible_capacity():
    tasks = [
        Task(id="t1", task_name="Big Task", credit_weight=3, difficulty_score=5,
             deadline=datetime(2026, 8, 26, 20, 0), study_duration_hours=5.0)
    ]
    slots = [FreeSlot(date="2026-08-25", start="10:00", end="12:00")]  # 2.0 hours
    blocks = generate_time_blocks_from_slots(slots)

    is_feasible, diagnostics = check_preliminary_feasibility(tasks, blocks)
    assert is_feasible is False
    assert diagnostics["required_hours"] == 5.0
    assert diagnostics["available_hours"] == 2.0
    assert diagnostics["shortfall_hours"] == 3.0


def test_schedule_constraint_validation_success():
    slots = [FreeSlot(date="2026-08-25", start="10:00", end="11:00")]  # 4 blocks
    blocks = generate_time_blocks_from_slots(slots)
    task = Task(id="t1", task_name="Task 1", credit_weight=3, difficulty_score=5,
                deadline=datetime(2026, 8, 25, 12, 0), study_duration_hours=1.0)

    schedule = [
        ScheduleBlock(task_id="t1", start=b.start, end=b.end)
        for b in blocks
    ]
    is_valid, violations = validate_schedule_constraints(schedule, [task], blocks)
    assert is_valid is True
    assert len(violations) == 0
