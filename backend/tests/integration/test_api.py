"""Integration tests for FastAPI endpoints."""
import pytest
from datetime import datetime, timedelta
from unittest.mock import patch
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_health_check():
    """Test health check endpoints at root and under /api/v1."""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

    response_v1 = client.get("/api/v1/health")
    assert response_v1.status_code == 200
    assert response_v1.json() == {"status": "ok"}


def test_openapi_documentation():
    """Test OpenAPI JSON schema generation and interactive docs."""
    response_docs = client.get("/docs")
    assert response_docs.status_code == 200

    response_openapi = client.get("/openapi.json")
    assert response_openapi.status_code == 200
    schema = response_openapi.json()
    assert "paths" in schema
    assert "/api/v1/schedule" in schema["paths"]
    assert "/api/v1/schedule/recalculate" in schema["paths"]
    assert "/api/v1/health" in schema["paths"]


def test_post_schedule_feasible():
    """Test standard feasible schedule generation."""
    ref_time = datetime(2026, 8, 25, 8, 0)
    payload = {
        "tasks": [
            {
                "id": "task-001",
                "task_name": "Data Structures",
                "credit_weight": 4,
                "difficulty_score": 8,
                "deadline": (ref_time + timedelta(days=3)).isoformat(),
                "study_duration_hours": 1.0
            },
            {
                "id": "task-002",
                "task_name": "Operating Systems",
                "credit_weight": 3,
                "difficulty_score": 7,
                "deadline": (ref_time + timedelta(days=3)).isoformat(),
                "study_duration_hours": 0.5
            }
        ],
        "free_slots": [
            {
                "date": "2026-08-25",
                "start": "09:00",
                "end": "12:00"
            }
        ]
    }
    response = client.post("/api/v1/schedule", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["feasible"] is True
    # 1.0h (4 blocks) + 0.5h (2 blocks) = 6 blocks
    assert len(data["schedule"]) == 6
    assert data["fitness_score"] is not None
    assert data["execution_time_ms"] >= 0
    assert data["generation_count"] > 0


def test_post_schedule_infeasible_capacity():
    """Test schedule generation when required time exceeds total available time."""
    ref_time = datetime(2026, 8, 25, 8, 0)
    payload = {
        "tasks": [
            {
                "id": "task-big",
                "task_name": "Massive Project",
                "credit_weight": 5,
                "difficulty_score": 9,
                "deadline": (ref_time + timedelta(days=1)).isoformat(),
                "study_duration_hours": 10.0
            }
        ],
        "free_slots": [
            {
                "date": "2026-08-25",
                "start": "18:00",
                "end": "19:00"
            }
        ]
    }
    response = client.post("/api/v1/schedule", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["feasible"] is False
    assert data["schedule"] == []
    assert data["diagnostics"] is not None
    assert data["diagnostics"]["shortfall_hours"] == 9.0


def test_post_schedule_infeasible_deadline():
    """Test schedule generation when available time is strictly after task deadline."""
    ref_time = datetime(2026, 8, 25, 8, 0)
    payload = {
        "tasks": [
            {
                "id": "task-urgent",
                "task_name": "Urgent Lab",
                "credit_weight": 3,
                "difficulty_score": 5,
                "deadline": "2026-08-25T10:00:00",
                "study_duration_hours": 1.0  # 4 blocks needed
            }
        ],
        "free_slots": [
            {
                "date": "2026-08-25",
                "start": "14:00",
                "end": "18:00"
            }
        ]
    }
    response = client.post("/api/v1/schedule", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["feasible"] is False
    assert data["schedule"] == []
    assert data["diagnostics"] is not None


def test_post_schedule_validation_errors():
    """Test request body validation rules (422 Unprocessable Entity)."""
    # 1. Invalid credit weight (> 6)
    bad_credit = {
        "tasks": [
            {
                "id": "t1",
                "task_name": "T1",
                "credit_weight": 10,
                "difficulty_score": 5,
                "deadline": "2026-08-28T23:59:00",
                "study_duration_hours": 1.0
            }
        ],
        "free_slots": [{"date": "2026-08-25", "start": "09:00", "end": "11:00"}]
    }
    res = client.post("/api/v1/schedule", json=bad_credit)
    assert res.status_code == 422

    # 2. Invalid difficulty score (< 1)
    bad_diff = {
        "tasks": [
            {
                "id": "t1",
                "task_name": "T1",
                "credit_weight": 3,
                "difficulty_score": 0,
                "deadline": "2026-08-28T23:59:00",
                "study_duration_hours": 1.0
            }
        ],
        "free_slots": [{"date": "2026-08-25", "start": "09:00", "end": "11:00"}]
    }
    res = client.post("/api/v1/schedule", json=bad_diff)
    assert res.status_code == 422

    # 3. Invalid date format
    bad_date = {
        "tasks": [
            {
                "id": "t1",
                "task_name": "T1",
                "credit_weight": 3,
                "difficulty_score": 5,
                "deadline": "2026-08-28T23:59:00",
                "study_duration_hours": 1.0
            }
        ],
        "free_slots": [{"date": "25-08-2026", "start": "09:00", "end": "11:00"}]
    }
    res = client.post("/api/v1/schedule", json=bad_date)
    assert res.status_code == 422

    # 4. Invalid time order (start >= end)
    bad_time_order = {
        "tasks": [
            {
                "id": "t1",
                "task_name": "T1",
                "credit_weight": 3,
                "difficulty_score": 5,
                "deadline": "2026-08-28T23:59:00",
                "study_duration_hours": 1.0
            }
        ],
        "free_slots": [{"date": "2026-08-25", "start": "12:00", "end": "10:00"}]
    }
    res = client.post("/api/v1/schedule", json=bad_time_order)
    assert res.status_code == 422

    # 5. Empty task list (min_length=1)
    empty_tasks = {
        "tasks": [],
        "free_slots": [{"date": "2026-08-25", "start": "09:00", "end": "11:00"}]
    }
    res = client.post("/api/v1/schedule", json=empty_tasks)
    assert res.status_code == 422

    # 6. Empty free slots list (min_length=1)
    empty_slots = {
        "tasks": [
            {
                "id": "t1",
                "task_name": "T1",
                "credit_weight": 3,
                "difficulty_score": 5,
                "deadline": "2026-08-28T23:59:00",
                "study_duration_hours": 1.0
            }
        ],
        "free_slots": []
    }
    res = client.post("/api/v1/schedule", json=empty_slots)
    assert res.status_code == 422


def test_post_recalculate_schedule():
    """Test recalculate endpoint with task completion filtering."""
    ref_time = datetime(2026, 8, 25, 8, 0)
    payload = {
        "tasks": [
            {
                "id": "task-001",
                "task_name": "Data Structures",
                "credit_weight": 4,
                "difficulty_score": 8,
                "deadline": (ref_time + timedelta(days=3)).isoformat(),
                "study_duration_hours": 1.0
            },
            {
                "id": "task-completed",
                "task_name": "Completed Task",
                "credit_weight": 2,
                "difficulty_score": 3,
                "deadline": (ref_time + timedelta(days=3)).isoformat(),
                "study_duration_hours": 1.0
            }
        ],
        "free_slots": [
            {
                "date": "2026-08-25",
                "start": "18:00",
                "end": "20:00"
            }
        ],
        "completed_task_ids": ["task-completed"],
        "missed_blocks": []
    }
    response = client.post("/api/v1/schedule/recalculate", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["feasible"] is True
    # Only task-001 should be scheduled (4 blocks)
    assert len(data["schedule"]) == 4
    for block in data["schedule"]:
        assert block["task_id"] == "task-001"


def test_post_recalculate_all_tasks_completed():
    """Test recalculate endpoint when all tasks are completed."""
    payload = {
        "tasks": [
            {
                "id": "task-completed-1",
                "task_name": "Done 1",
                "credit_weight": 3,
                "difficulty_score": 5,
                "deadline": "2026-08-28T23:59:00",
                "study_duration_hours": 1.0
            }
        ],
        "free_slots": [
            {
                "date": "2026-08-25",
                "start": "18:00",
                "end": "20:00"
            }
        ],
        "completed_task_ids": ["task-completed-1"],
        "missed_blocks": []
    }
    response = client.post("/api/v1/schedule/recalculate", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["feasible"] is True
    assert data["schedule"] == []
    assert data["diagnostics"] is not None
    assert "All tasks are completed" in data["diagnostics"].get("info", "")


def test_internal_server_error_handling():
    """Test 500 status code when an unhandled internal exception occurs in service."""
    payload = {
        "tasks": [
            {
                "id": "task-001",
                "task_name": "Data Structures",
                "credit_weight": 4,
                "difficulty_score": 8,
                "deadline": "2026-08-28T23:59:00",
                "study_duration_hours": 1.0
            }
        ],
        "free_slots": [
            {
                "date": "2026-08-25",
                "start": "18:00",
                "end": "20:00"
            }
        ]
    }
    with patch("app.services.scheduling_service.SchedulingService.generate_schedule", side_effect=RuntimeError("Simulated engine failure")):
        response = client.post("/api/v1/schedule", json=payload)
        assert response.status_code == 500
        data = response.json()
        assert "Simulated engine failure" in data["detail"]
