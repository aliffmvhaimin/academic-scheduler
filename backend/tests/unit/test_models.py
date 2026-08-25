"""Unit tests for Phase 1 domain models, validation, and Pydantic schemas."""
import pytest
from datetime import datetime, timedelta
from app.models.task import Task
from app.models.availability import FreeSlot
from app.models.schedule import ScheduleBlock, ScheduleResult
from app.schemas.task import TaskSchema
from app.schemas.availability import FreeSlotSchema
from app.schemas.scheduling import (
    ScheduleBlockSchema,
    ScheduleRequest,
    ScheduleResponse,
    RecalculateScheduleRequest,
)


# ==========================================
# Task Model Tests
# ==========================================

def test_task_model_valid():
    task = Task(
        id="task-1",
        task_name="Data Structures",
        credit_weight=4,
        difficulty_score=8,
        deadline=datetime(2026, 8, 30, 23, 59),
        study_duration_hours=2.0
    )
    assert task.id == "task-1"
    assert task.task_name == "Data Structures"
    assert task.credit_weight == 4
    assert task.difficulty_score == 8
    assert task.study_duration_hours == 2.0
    assert task.required_blocks == 8


def test_task_model_validation_errors():
    with pytest.raises(ValueError, match="Task id cannot be empty"):
        Task(id="", task_name="A", credit_weight=3, difficulty_score=5, deadline=datetime.now(), study_duration_hours=1.0)

    with pytest.raises(ValueError, match="Task name cannot be empty"):
        Task(id="1", task_name="", credit_weight=3, difficulty_score=5, deadline=datetime.now(), study_duration_hours=1.0)

    with pytest.raises(ValueError, match="Credit weight"):
        Task(id="1", task_name="A", credit_weight=7, difficulty_score=5, deadline=datetime.now(), study_duration_hours=1.0)

    with pytest.raises(ValueError, match="Credit weight"):
        Task(id="1", task_name="A", credit_weight=0, difficulty_score=5, deadline=datetime.now(), study_duration_hours=1.0)

    with pytest.raises(ValueError, match="Difficulty score"):
        Task(id="1", task_name="A", credit_weight=3, difficulty_score=0, deadline=datetime.now(), study_duration_hours=1.0)

    with pytest.raises(ValueError, match="Difficulty score"):
        Task(id="1", task_name="A", credit_weight=3, difficulty_score=11, deadline=datetime.now(), study_duration_hours=1.0)

    with pytest.raises(ValueError, match="positive"):
        Task(id="1", task_name="A", credit_weight=3, difficulty_score=5, deadline=datetime.now(), study_duration_hours=0.0)

    with pytest.raises(ValueError, match="positive"):
        Task(id="1", task_name="A", credit_weight=3, difficulty_score=5, deadline=datetime.now(), study_duration_hours=-2.5)


# ==========================================
# Availability (FreeSlot) Model Tests
# ==========================================

def test_free_slot_model():
    slot = FreeSlot(date="2026-08-25", start="18:00", end="20:00")
    assert slot.date == "2026-08-25"
    assert slot.start == "18:00"
    assert slot.end == "20:00"
    assert slot.duration_hours == 2.0
    assert slot.available_blocks == 8
    assert slot.start_datetime == datetime(2026, 8, 25, 18, 0)
    assert slot.end_datetime == datetime(2026, 8, 25, 20, 0)


def test_free_slot_invalid_times():
    with pytest.raises(ValueError, match="strictly before"):
        FreeSlot(date="2026-08-25", start="20:00", end="18:00")

    with pytest.raises(ValueError, match="strictly before"):
        FreeSlot(date="2026-08-25", start="18:00", end="18:00")


def test_free_slot_invalid_formats():
    with pytest.raises(ValueError, match="Invalid date format"):
        FreeSlot(date="25-08-2026", start="18:00", end="20:00")

    with pytest.raises(ValueError, match="Invalid time format"):
        FreeSlot(date="2026-08-25", start="6pm", end="20:00")


# ==========================================
# Schedule Models Tests
# ==========================================

def test_schedule_block_valid():
    start = datetime(2026, 8, 25, 18, 0)
    end = datetime(2026, 8, 25, 18, 15)
    block = ScheduleBlock(task_id="t1", start=start, end=end)
    assert block.task_id == "t1"
    assert block.start == start
    assert block.end == end


def test_schedule_block_invalid():
    with pytest.raises(ValueError, match="task_id cannot be empty"):
        ScheduleBlock(task_id="", start=datetime(2026, 8, 25, 18, 0), end=datetime(2026, 8, 25, 18, 15))

    with pytest.raises(ValueError, match="must be before end"):
        ScheduleBlock(task_id="t1", start=datetime(2026, 8, 25, 18, 15), end=datetime(2026, 8, 25, 18, 0))


def test_schedule_result_structure():
    res = ScheduleResult(
        success=True,
        feasible=True,
        fitness_score=0.85,
        generation_count=120,
        execution_time_ms=150,
        schedule=[
            ScheduleBlock(task_id="t1", start=datetime(2026, 8, 25, 18, 0), end=datetime(2026, 8, 25, 18, 15))
        ],
        diagnostics=None
    )
    assert res.success is True
    assert res.feasible is True
    assert len(res.schedule) == 1


# ==========================================
# Pydantic Schemas Validation Tests
# ==========================================

def test_pydantic_task_schema():
    data = {
        "id": "task-001",
        "task_name": "Calculus II",
        "credit_weight": 3,
        "difficulty_score": 7,
        "deadline": "2026-08-28T12:00:00",
        "study_duration_hours": 3.5
    }
    schema = TaskSchema(**data)
    assert schema.id == "task-001"
    assert schema.credit_weight == 3
    assert schema.difficulty_score == 7
    assert schema.study_duration_hours == 3.5


def test_pydantic_free_slot_schema():
    data = {
        "date": "2026-08-25",
        "start": "18:00",
        "end": "20:00"
    }
    schema = FreeSlotSchema(**data)
    assert schema.date == "2026-08-25"
    assert schema.start == "18:00"
    assert schema.end == "20:00"


def test_pydantic_schedule_request_and_response():
    req_data = {
        "tasks": [
            {
                "id": "task-1",
                "task_name": "Operating Systems",
                "credit_weight": 4,
                "difficulty_score": 8,
                "deadline": "2026-08-29T23:59:00",
                "study_duration_hours": 2.0
            }
        ],
        "free_slots": [
            {
                "date": "2026-08-25",
                "start": "10:00",
                "end": "12:00"
            }
        ]
    }
    req = ScheduleRequest(**req_data)
    assert len(req.tasks) == 1
    assert len(req.free_slots) == 1

    resp_data = {
        "success": True,
        "feasible": True,
        "fitness_score": 0.92,
        "generation_count": 80,
        "execution_time_ms": 110,
        "schedule": [
            {
                "task_id": "task-1",
                "start": "2026-08-25T10:00:00",
                "end": "2026-08-25T10:15:00"
            }
        ]
    }
    resp = ScheduleResponse(**resp_data)
    assert resp.feasible is True
    assert len(resp.schedule) == 1
