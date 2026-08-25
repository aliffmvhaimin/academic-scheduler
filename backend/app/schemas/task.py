"""Pydantic schemas for task input validation."""
from datetime import datetime
from pydantic import BaseModel, Field, field_validator


class TaskSchema(BaseModel):
    """Schema for incoming task payload."""
    id: str = Field(..., description="Unique identifier for the task (e.g. UUID or task-001)")
    task_name: str = Field(..., min_length=1, max_length=200, description="Name or title of the academic task")
    credit_weight: int = Field(..., ge=1, le=6, description="Course credit weight (1 to 6)")
    difficulty_score: int = Field(..., ge=1, le=10, description="Perceived task difficulty (1 to 10)")
    deadline: datetime = Field(..., description="Due date and time in ISO format")
    study_duration_hours: float = Field(..., gt=0.0, description="Required study time in hours (positive float)")

    @field_validator("id", "task_name")
    @classmethod
    def check_non_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Field cannot be empty or whitespace only.")
        return v.strip()
