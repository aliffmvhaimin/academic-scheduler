"""Core domain and constraint logic."""
from app.core.time_blocks import TimeBlock, generate_time_blocks_from_slots, hours_to_blocks, blocks_to_hours
from app.core.priority import calculate_task_priority, calculate_urgency_score
from app.core.constraints import (
    ConstraintViolation,
    check_preliminary_feasibility,
    validate_schedule_constraints,
)

__all__ = [
    "TimeBlock",
    "generate_time_blocks_from_slots",
    "hours_to_blocks",
    "blocks_to_hours",
    "calculate_task_priority",
    "calculate_urgency_score",
    "ConstraintViolation",
    "check_preliminary_feasibility",
    "validate_schedule_constraints",
]
