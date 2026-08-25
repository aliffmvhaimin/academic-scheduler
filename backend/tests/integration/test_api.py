"""Integration tests for FastAPI endpoints."""
import pytest
from datetime import datetime, timedelta
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

    response_v1 = client.get("/api/v1/health")
    assert response_v1.status_code == 200
    assert response_v1.json() == {"status": "ok"}


def test_post_schedule_feasible():
    payload = {
        "tasks": [
            {
                "id": "task-001",
                "task_name": "Data Structures",
                "credit_weight": 4,
                "difficulty_score": 8,
                "deadline": (datetime.now() + timedelta(days=3)).strftime("%Y-%m-%dT23:59:00"),
                "study_duration_hours": 1.0
            }
        ],
        "free_slots": [
            {
                "date": datetime.now().strftime("%Y-%m-%d"),
                "start": "18:00",
                "end": "20:00"
            }
        ]
    }
    response = client.post("/api/v1/schedule", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["feasible"] is True
    assert len(data["schedule"]) == 4  # 1.0 hr = 4 blocks
    assert data["fitness_score"] is not None


def test_post_schedule_infeasible_capacity():
    payload = {
        "tasks": [
            {
                "id": "task-big",
                "task_name": "Massive Project",
                "credit_weight": 5,
                "difficulty_score": 9,
                "deadline": (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%dT23:59:00"),
                "study_duration_hours": 10.0
            }
        ],
        "free_slots": [
            {
                "date": datetime.now().strftime("%Y-%m-%d"),
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


def test_post_recalculate_schedule():
    payload = {
        "tasks": [
            {
                "id": "task-001",
                "task_name": "Data Structures",
                "credit_weight": 4,
                "difficulty_score": 8,
                "deadline": (datetime.now() + timedelta(days=3)).strftime("%Y-%m-%dT23:59:00"),
                "study_duration_hours": 1.0
            },
            {
                "id": "task-completed",
                "task_name": "Completed Task",
                "credit_weight": 2,
                "difficulty_score": 3,
                "deadline": (datetime.now() + timedelta(days=3)).strftime("%Y-%m-%dT23:59:00"),
                "study_duration_hours": 1.0
            }
        ],
        "free_slots": [
            {
                "date": datetime.now().strftime("%Y-%m-%d"),
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
