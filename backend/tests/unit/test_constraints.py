"""Comprehensive unit tests for Phase 2 Constraint Engine & Infeasibility Diagnostics."""
import pytest
from datetime import datetime, timedelta
from app.models.task import Task
from app.models.availability import FreeSlot
from app.models.schedule import ScheduleBlock
from app.core.time_blocks import generate_time_blocks_from_slots, TimeBlock
from app.core.constraints import (
    validate_availability_constraint,
    validate_deadline_constraint,
    validate_overlap_constraint,
    validate_duration_constraint,
    validate_granularity_constraint,
    validate_schedule_constraints,
    is_schedule_feasible,
    check_preliminary_feasibility,
)


@pytest.fixture
def sample_data():
    base_time = datetime(2026, 8, 25, 10, 0)
    slots = [
        FreeSlot(date="2026-08-25", start="10:00", end="12:00")  # 2 hours = 8 blocks
    ]
    blocks = generate_time_blocks_from_slots(slots)
    task1 = Task(
        id="t1",
        task_name="Algorithms",
        credit_weight=4,
        difficulty_score=8,
        deadline=datetime(2026, 8, 25, 12, 0),
        study_duration_hours=1.0  # 4 blocks
    )
    task2 = Task(
        id="t2",
        task_name="Database Systems",
        credit_weight=3,
        difficulty_score=6,
        deadline=datetime(2026, 8, 25, 12, 0),
        study_duration_hours=1.0  # 4 blocks
    )
    return {"base_time": base_time, "slots": slots, "blocks": blocks, "task1": task1, "task2": task2}


# ==========================================
# C1: Availability Constraint Tests
# ==========================================

def test_availability_constraint_valid(sample_data):
    blocks = sample_data["blocks"]
    valid_intervals = {(b.start, b.end) for b in blocks}
    schedule = [
        ScheduleBlock(task_id="t1", start=blocks[0].start, end=blocks[0].end)
    ]
    violations = validate_availability_constraint(schedule, valid_intervals)
    assert len(violations) == 0


def test_availability_constraint_invalid(sample_data):
    blocks = sample_data["blocks"]
    valid_intervals = {(b.start, b.end) for b in blocks}
    # Schedule block outside available slot (e.g. 14:00 to 14:15)
    outside_block = ScheduleBlock(
        task_id="t1",
        start=datetime(2026, 8, 25, 14, 0),
        end=datetime(2026, 8, 25, 14, 15)
    )
    violations = validate_availability_constraint([outside_block], valid_intervals)
    assert len(violations) == 1
    assert violations[0].constraint_code == "C1"
    assert "outside available free slots" in violations[0].message


# ==========================================
# C2: Deadline Constraint Tests
# ==========================================

def test_deadline_constraint_valid(sample_data):
    task1 = sample_data["task1"]
    blocks = sample_data["blocks"]
    schedule = [
        ScheduleBlock(task_id="t1", start=blocks[0].start, end=blocks[0].end)
    ]
    violations = validate_deadline_constraint(schedule, {"t1": task1})
    assert len(violations) == 0


def test_deadline_constraint_invalid():
    deadline = datetime(2026, 8, 25, 11, 0)
    task = Task(id="t1", task_name="Test Task", credit_weight=3, difficulty_score=5,
                deadline=deadline, study_duration_hours=1.0)

    # Block ending at 11:15 (after 11:00 deadline)
    late_block = ScheduleBlock(
        task_id="t1",
        start=datetime(2026, 8, 25, 11, 0),
        end=datetime(2026, 8, 25, 11, 15)
    )
    violations = validate_deadline_constraint([late_block], {"t1": task})
    assert len(violations) == 1
    assert violations[0].constraint_code == "C2"
    assert "after deadline" in violations[0].message


# ==========================================
# C3: Overlap Constraint Tests
# ==========================================

def test_overlap_constraint_valid(sample_data):
    blocks = sample_data["blocks"]
    schedule = [
        ScheduleBlock(task_id="t1", start=blocks[0].start, end=blocks[0].end),
        ScheduleBlock(task_id="t2", start=blocks[1].start, end=blocks[1].end),
    ]
    violations = validate_overlap_constraint(schedule)
    assert len(violations) == 0


def test_overlap_constraint_invalid(sample_data):
    blocks = sample_data["blocks"]
    # Two tasks assigned to the same start/end time
    schedule = [
        ScheduleBlock(task_id="t1", start=blocks[0].start, end=blocks[0].end),
        ScheduleBlock(task_id="t2", start=blocks[0].start, end=blocks[0].end),
    ]
    violations = validate_overlap_constraint(schedule)
    assert len(violations) == 1
    assert violations[0].constraint_code == "C3"
    assert "Overlapping block" in violations[0].message


# ==========================================
# C4: Duration Constraint Tests
# ==========================================

def test_duration_constraint_valid(sample_data):
    task1 = sample_data["task1"]  # 4 blocks needed
    blocks = sample_data["blocks"]
    schedule = [
        ScheduleBlock(task_id="t1", start=blocks[i].start, end=blocks[i].end)
        for i in range(4)
    ]
    violations = validate_duration_constraint(schedule, [task1])
    assert len(violations) == 0


def test_duration_constraint_under_and_over_allocated(sample_data):
    task1 = sample_data["task1"]  # 4 blocks needed
    blocks = sample_data["blocks"]

    # Under-allocated: 3 blocks instead of 4
    under_schedule = [
        ScheduleBlock(task_id="t1", start=blocks[i].start, end=blocks[i].end)
        for i in range(3)
    ]
    violations_under = validate_duration_constraint(under_schedule, [task1])
    assert len(violations_under) == 1
    assert violations_under[0].constraint_code == "C4"

    # Over-allocated: 5 blocks instead of 4
    over_schedule = [
        ScheduleBlock(task_id="t1", start=blocks[i].start, end=blocks[i].end)
        for i in range(5)
    ]
    violations_over = validate_duration_constraint(over_schedule, [task1])
    assert len(violations_over) == 1
    assert violations_over[0].constraint_code == "C4"


# ==========================================
# C5: Granularity Constraint Tests
# ==========================================

def test_granularity_constraint_valid(sample_data):
    blocks = sample_data["blocks"]
    schedule = [
        ScheduleBlock(task_id="t1", start=blocks[0].start, end=blocks[0].end)
    ]
    violations = validate_granularity_constraint(schedule)
    assert len(violations) == 0


def test_granularity_constraint_invalid():
    # Block of 30 minutes instead of 15
    invalid_block = ScheduleBlock(
        task_id="t1",
        start=datetime(2026, 8, 25, 10, 0),
        end=datetime(2026, 8, 25, 10, 30)
    )
    violations = validate_granularity_constraint([invalid_block])
    assert len(violations) == 1
    assert violations[0].constraint_code == "C5"
    assert "must be exactly 15 minutes" in violations[0].message


# ==========================================
# Integrated Feasibility Checker Tests
# ==========================================

def test_validate_schedule_constraints_valid(sample_data):
    task1 = sample_data["task1"]  # 4 blocks
    task2 = sample_data["task2"]  # 4 blocks
    blocks = sample_data["blocks"]  # 8 blocks total

    schedule = [
        ScheduleBlock(task_id="t1", start=blocks[i].start, end=blocks[i].end)
        for i in range(4)
    ] + [
        ScheduleBlock(task_id="t2", start=blocks[i].start, end=blocks[i].end)
        for i in range(4, 8)
    ]

    is_valid, violations = validate_schedule_constraints(schedule, [task1, task2], blocks)
    assert is_valid is True
    assert len(violations) == 0
    assert is_schedule_feasible(schedule, [task1, task2], blocks) is True


def test_validate_schedule_constraints_invalid(sample_data):
    task1 = sample_data["task1"]
    blocks = sample_data["blocks"]

    # Incomplete schedule
    schedule = [
        ScheduleBlock(task_id="t1", start=blocks[0].start, end=blocks[0].end)
    ]

    is_valid, violations = validate_schedule_constraints(schedule, [task1], blocks)
    assert is_valid is False
    assert len(violations) > 0
    assert is_schedule_feasible(schedule, [task1], blocks) is False


# ==========================================
# Infeasibility Diagnostics Tests
# ==========================================

def test_check_preliminary_feasibility_capacity_shortfall():
    tasks = [
        Task(id="t1", task_name="Huge Task", credit_weight=4, difficulty_score=8,
             deadline=datetime(2026, 8, 26, 20, 0), study_duration_hours=6.0)
    ]
    slots = [FreeSlot(date="2026-08-25", start="10:00", end="12:00")]  # 2 hours
    blocks = generate_time_blocks_from_slots(slots)

    is_feasible, diag = check_preliminary_feasibility(tasks, blocks)
    assert is_feasible is False
    assert diag is not None
    assert diag["required_hours"] == 6.0
    assert diag["available_hours_before_deadline"] == 2.0
    assert diag["shortfall_hours"] == 4.0
    assert "exceeds total available time" in diag["reason"]


def test_check_preliminary_feasibility_individual_deadline_shortfall():
    tasks = [
        Task(id="t1", task_name="Urgent Assignment", credit_weight=5, difficulty_score=9,
             deadline=datetime(2026, 8, 25, 11, 0), study_duration_hours=2.0)  # Needs 2h, but only 1h exists before 11:00
    ]
    slots = [
        FreeSlot(date="2026-08-25", start="10:00", end="15:00")  # 5 hours total
    ]
    blocks = generate_time_blocks_from_slots(slots)

    is_feasible, diag = check_preliminary_feasibility(tasks, blocks)
    assert is_feasible is False
    assert diag is not None
    assert diag["task_id"] == "t1"
    assert diag["required_hours"] == 2.0
    assert diag["available_hours_before_deadline"] == 1.0
    assert diag["shortfall_hours"] == 1.0
    assert "before its deadline" in diag["reason"]


def test_check_preliminary_feasibility_cumulative_deadline_shortfall():
    # Total available: 3h (12 blocks) from 10:00 to 13:00
    # Task A: 2h, due at 11:30 (avail before 11:30 is 1.5h) -> Individual check catches this, but let's test cumulative:
    # Task 1: 1h, due at 12:00 (avail before 12:00 is 2h)
    # Task 2: 1.5h, due at 12:00 (total demand before 12:00 = 2.5h > 2.0h available before 12:00)
    tasks = [
        Task(id="t1", task_name="Task 1", credit_weight=3, difficulty_score=5,
             deadline=datetime(2026, 8, 25, 12, 0), study_duration_hours=1.0),
        Task(id="t2", task_name="Task 2", credit_weight=3, difficulty_score=5,
             deadline=datetime(2026, 8, 25, 12, 0), study_duration_hours=1.5),
    ]
    slots = [
        FreeSlot(date="2026-08-25", start="10:00", end="13:00")  # 3 hours total
    ]
    blocks = generate_time_blocks_from_slots(slots)

    is_feasible, diag = check_preliminary_feasibility(tasks, blocks)
    assert is_feasible is False
    assert diag is not None
    assert diag["required_hours"] == 2.5
    assert diag["available_hours_before_deadline"] == 2.0
    assert diag["shortfall_hours"] == 0.5
    assert "Cumulative study demand" in diag["reason"]
