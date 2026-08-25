"""Domain models for academic tasks."""
from datetime import datetime
from dataclasses import dataclass, field
from typing import Optional


@dataclass(frozen=True)
class Task:
    """Represents an academic task to be scheduled."""
    id: str
    task_name: str
    credit_weight: int       # 1 to 6
    difficulty_score: int    # 1 to 10
    deadline: datetime
    study_duration_hours: float

    def __post_init__(self):
        if not self.id:
            raise ValueError("Task id cannot be empty.")
        if not self.task_name:
            raise ValueError("Task name cannot be empty.")
        if not (1 <= self.credit_weight <= 6):
            raise ValueError(f"Credit weight must be between 1 and 6, got {self.credit_weight}.")
        if not (1 <= self.difficulty_score <= 10):
            raise ValueError(f"Difficulty score must be between 1 and 10, got {self.difficulty_score}.")
        if self.study_duration_hours <= 0:
            raise ValueError(f"Study duration must be positive, got {self.study_duration_hours}.")

    @property
    def required_blocks(self) -> int:
        """Returns the required number of 15-minute time blocks."""
        return int(round(self.study_duration_hours * 4))
