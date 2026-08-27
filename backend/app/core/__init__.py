"""Core domain and constraint logic."""
from app.core.time_blocks import TimeBlock, generate_time_blocks_from_slots, hours_to_blocks, blocks_to_hours
from app.core.priority import calculate_task_priority, calculate_urgency_score, sort_tasks_by_priority
from app.core.constraints import (
    ConstraintViolation,
    validate_availability_constraint,
    validate_deadline_constraint,
    validate_overlap_constraint,
    validate_duration_constraint,
    validate_granularity_constraint,
    validate_schedule_constraints,
    is_schedule_feasible,
    check_preliminary_feasibility,
)

__all__ = [
    "TimeBlock",
    "generate_time_blocks_from_slots",
    "hours_to_blocks",
    "blocks_to_hours",
    "calculate_task_priority",
    "calculate_urgency_score",
    "sort_tasks_by_priority",
    "ConstraintViolation",
    "validate_availability_constraint",
    "validate_deadline_constraint",
    "validate_overlap_constraint",
    "validate_duration_constraint",
    "validate_granularity_constraint",
    "validate_schedule_constraints",
    "is_schedule_feasible",
    "check_preliminary_feasibility",
]
