"""Unit tests for Phase 3 Deterministic Greedy Baseline Scheduler."""
import pytest
from datetime import datetime, timedelta
from app.models.task import Task
from app.models.availability import FreeSlot
from app.models.schedule import ScheduleResult, ScheduleBlock
from app.core.priority import calculate_task_priority, calculate_urgency_score, sort_tasks_by_priority
from app.schedulers.greedy import GreedyScheduler
from app.core.constraints import validate_schedule_constraints
from app.core.time_blocks import generate_time_blocks_from_slots


# ==========================================
# Priority Calculation & Task Sorting Tests
# ==========================================

def test_priority_calculation_weights():
    ref_time = datetime(2026, 8, 25, 8, 0)
    task = Task(
        id="t1", task_name="Test", credit_weight=6, difficulty_score=10,
        deadline=ref_time + timedelta(hours=24), study_duration_hours=2.0
    )
    # Urgency only
    p_urgency_only = calculate_task_priority(task, ref_time, w_urgency=1.0, w_credit=0.0, w_difficulty=0.0)
    u_score = calculate_urgency_score(task.deadline, ref_time)
    assert pytest.approx(p_urgency_only, 0.001) == u_score

    # Credit only (credit=6 -> max normalized 1.0)
    p_credit_only = calculate_task_priority(task, ref_time, w_urgency=0.0, w_credit=1.0, w_difficulty=0.0)
    assert pytest.approx(p_credit_only, 0.001) == 1.0

    # Difficulty only (difficulty=10 -> max normalized 1.0)
    p_diff_only = calculate_task_priority(task, ref_time, w_urgency=0.0, w_credit=0.0, w_difficulty=1.0)
    assert pytest.approx(p_diff_only, 0.001) == 1.0


def test_sort_tasks_by_priority_deterministic():
    ref_time = datetime(2026, 8, 25, 8, 0)
    t_high = Task(id="t_high", task_name="High Priority", credit_weight=6, difficulty_score=10,
                  deadline=ref_time + timedelta(hours=12), study_duration_hours=1.0)
    t_med = Task(id="t_med", task_name="Med Priority", credit_weight=3, difficulty_score=5,
                 deadline=ref_time + timedelta(days=2), study_duration_hours=1.0)
    t_low = Task(id="t_low", task_name="Low Priority", credit_weight=1, difficulty_score=1,
                 deadline=ref_time + timedelta(days=7), study_duration_hours=1.0)

    # Shuffled input
    tasks = [t_med, t_low, t_high]
    sorted_res = sort_tasks_by_priority(tasks, ref_time)

    assert [item[0].id for item in sorted_res] == ["t_high", "t_med", "t_low"]
    assert sorted_res[0][1] > sorted_res[1][1] > sorted_res[2][1]


# ==========================================
# Deterministic Greedy Scheduler Tests
# ==========================================

def test_greedy_scheduler_success_and_order():
    ref_time = datetime(2026, 8, 25, 8, 0)
    # t1 has higher credit and difficulty than t2, both due in 2 days
    t1 = Task(id="task-math", task_name="Advanced Math", credit_weight=5, difficulty_score=9,
              deadline=ref_time + timedelta(days=2), study_duration_hours=1.0)  # 4 blocks
    t2 = Task(id="task-art", task_name="Art Appreciation", credit_weight=1, difficulty_score=2,
              deadline=ref_time + timedelta(days=2), study_duration_hours=0.5)  # 2 blocks

    slots = [
        FreeSlot(date="2026-08-25", start="09:00", end="12:00")  # 3 hours = 12 blocks
    ]
    scheduler = GreedyScheduler()
    result = scheduler.schedule([t2, t1], slots, reference_time=ref_time)

    assert result.success is True
    assert result.feasible is True
    assert len(result.schedule) == 6  # 4 + 2 = 6 blocks
    assert result.fitness_score is not None
    assert result.generation_count == 1
    assert result.execution_time_ms >= 0

    # Verify that higher priority task (task-math) was assigned earlier blocks (09:00 to 10:00)
    math_blocks = [b for b in result.schedule if b.task_id == "task-math"]
    art_blocks = [b for b in result.schedule if b.task_id == "task-art"]
    assert len(math_blocks) == 4
    assert len(art_blocks) == 2
    assert math_blocks[-1].end <= art_blocks[0].start


def test_greedy_scheduler_determinism():
    """Verify that GreedyScheduler produces 100% identical outputs on repeated runs."""
    ref_time = datetime(2026, 8, 25, 8, 0)
    tasks = [
        Task(id=f"t{i}", task_name=f"Task {i}", credit_weight=(i % 5) + 1,
             difficulty_score=(i % 9) + 1, deadline=ref_time + timedelta(days=3),
             study_duration_hours=0.75)
        for i in range(5)
    ]
    slots = [
        FreeSlot(date="2026-08-25", start="09:00", end="15:00")
    ]
    scheduler = GreedyScheduler()

    first_result = scheduler.schedule(tasks, slots, reference_time=ref_time)

    for _ in range(10):
        repeat_result = scheduler.schedule(tasks, slots, reference_time=ref_time)
        assert repeat_result.feasible == first_result.feasible
        assert repeat_result.fitness_score == first_result.fitness_score
        assert len(repeat_result.schedule) == len(first_result.schedule)
        for b1, b2 in zip(first_result.schedule, repeat_result.schedule):
            assert b1.task_id == b2.task_id
            assert b1.start == b2.start
            assert b1.end == b2.end


def test_greedy_scheduler_no_constraint_violations():
    """Verify that all generated feasible schedules strictly satisfy all 5 hard constraints."""
    ref_time = datetime(2026, 8, 25, 8, 0)
    tasks = [
        Task(id="t1", task_name="Task 1", credit_weight=4, difficulty_score=7,
             deadline=ref_time + timedelta(days=1, hours=4), study_duration_hours=1.25),
        Task(id="t2", task_name="Task 2", credit_weight=3, difficulty_score=5,
             deadline=ref_time + timedelta(days=1, hours=8), study_duration_hours=1.50)
    ]
    slots = [
        FreeSlot(date="2026-08-25", start="10:00", end="14:00")
    ]
    scheduler = GreedyScheduler()
    result = scheduler.schedule(tasks, slots, reference_time=ref_time)

    assert result.feasible is True
    blocks = generate_time_blocks_from_slots(slots)
    is_valid, violations = validate_schedule_constraints(result.schedule, tasks, blocks)
    assert is_valid is True
    assert len(violations) == 0


# ==========================================
# Infeasible Cases & Diagnostics Tests
# ==========================================

def test_greedy_scheduler_infeasible_deadline_shortfall():
    ref_time = datetime(2026, 8, 25, 8, 0)
    tasks = [
        Task(id="t_urgent", task_name="Urgent Physics", credit_weight=5, difficulty_score=9,
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
    assert result.diagnostics["shortfall_hours"] == 0.5
    assert result.diagnostics["task_id"] == "t_urgent"


def test_greedy_scheduler_infeasible_capacity_shortfall():
    ref_time = datetime(2026, 8, 25, 8, 0)
    tasks = [
        Task(id="t1", task_name="Massive Task", credit_weight=3, difficulty_score=5,
             deadline=ref_time + timedelta(days=2), study_duration_hours=5.0)  # 5.0h
    ]
    slots = [
        FreeSlot(date="2026-08-25", start="09:00", end="11:00")  # Only 2.0h
    ]
    scheduler = GreedyScheduler()
    result = scheduler.schedule(tasks, slots, reference_time=ref_time)

    assert result.success is True
    assert result.feasible is False
    assert result.schedule == []
    assert result.diagnostics is not None
    assert result.diagnostics["shortfall_hours"] == 3.0


def test_greedy_scheduler_empty_inputs():
    scheduler = GreedyScheduler()

    # Empty tasks
    res_empty_tasks = scheduler.schedule([], [FreeSlot(date="2026-08-25", start="09:00", end="11:00")])
    assert res_empty_tasks.feasible is False
    assert res_empty_tasks.schedule == []

    # Empty free slots
    t = Task(id="t1", task_name="T1", credit_weight=3, difficulty_score=5,
             deadline=datetime(2026, 8, 26, 12, 0), study_duration_hours=1.0)
    res_empty_slots = scheduler.schedule([t], [])
    assert res_empty_slots.feasible is False
    assert res_empty_slots.schedule == []
    assert res_empty_slots.diagnostics["shortfall_hours"] == 1.0
