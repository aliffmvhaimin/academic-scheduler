"""Domain models for scheduled study blocks and overall schedule results."""
from datetime import datetime
from dataclasses import dataclass, field
from typing import List, Optional, Dict, Any


@dataclass(frozen=True)
class ScheduleBlock:
    """Represents a discrete 15-minute scheduled study block."""
    task_id: str
    start: datetime
    end: datetime

    def __post_init__(self):
        if not self.task_id:
            raise ValueError("task_id cannot be empty.")
        if self.start >= self.end:
            raise ValueError(f"Block start ({self.start}) must be before end ({self.end}).")


@dataclass
class ScheduleResult:
    """Represents the complete result of a scheduling operation."""
    success: bool
    feasible: bool
    fitness_score: Optional[float]
    generation_count: int
    execution_time_ms: int
    schedule: List[ScheduleBlock] = field(default_factory=list)
    diagnostics: Optional[Dict[str, Any]] = None
