# API Contract

Base path:

/api/v1

---

# GET /health

Response:

{
  "status": "ok"
}

---

# POST /schedule

Generates a schedule.

Request:

{
  "tasks": [
    {
      "id": "task-001",
      "task_name": "Data Structures",
      "credit_weight": 4,
      "difficulty_score": 8,
      "deadline": "2026-08-28T23:59:00",
      "study_duration_hours": 2.0
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

Response:

{
  "success": true,
  "feasible": true,
  "fitness_score": 0.84,
  "generation_count": 143,
  "execution_time_ms": 218,
  "schedule": [
    {
      "task_id": "task-001",
      "start": "2026-08-25T18:00:00",
      "end": "2026-08-25T18:15:00"
    }
  ]
}

---

# Infeasible Response

{
  "success": true,
  "feasible": false,
  "fitness_score": null,
  "generation_count": 200,
  "execution_time_ms": 220,
  "schedule": [],
  "diagnostics": {
    "required_hours": 10,
    "available_hours_before_deadline": 2,
    "shortfall_hours": 8
  }
}

---

# POST /schedule/recalculate

Used when:

- new task added
- task modified
- availability changed
- study block missed

Request contains the current task and availability state.

The server treats the supplied state as authoritative and generates a
new schedule.

---

# API Principles

The frontend must not know whether scheduling uses:

- Genetic Algorithm
- Greedy
- CP-SAT

The API exposes scheduling behaviour, not implementation details.