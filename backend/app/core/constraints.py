"""Hard constraint validation and feasibility checking for schedules."""
from datetime import datetime
from typing import List, Dict, Tuple, Optional, Any
from app.models.task import Task
from app.models.schedule import ScheduleBlock
from app.core.time_blocks import TimeBlock, blocks_to_hours


class ConstraintViolation:
    """Represents a violation of a hard scheduling constraint."""
    def __init__(self, constraint_code: str, message: str, task_id: Optional[str] = None):
        self.constraint_code = constraint_code  # C1, C2, C3, C4, C5
        self.message = message
        self.task_id = task_id

    def to_dict(self) -> Dict[str, Any]:
        return {
            "code": self.constraint_code,
            "message": self.message,
            "task_id": self.task_id
        }


def check_preliminary_feasibility(
    tasks: List[Task],
    time_blocks: List[TimeBlock]
) -> Tuple[bool, Optional[Dict[str, Any]]]:
    """
    Checks basic capacity and deadline feasibility before scheduling.
    Returns (is_feasible, diagnostics).
    """
    total_required_blocks = sum(t.required_blocks for t in tasks)
    total_available_blocks = len(time_blocks)
    total_required_hours = blocks_to_hours(total_required_blocks)
    total_available_hours = blocks_to_hours(total_available_blocks)

    # 1. Total capacity check
    if total_required_blocks > total_available_blocks:
        shortfall = total_required_hours - total_available_hours
        return False, {
            "required_hours": total_required_hours,
            "available_hours": total_available_hours,
            "shortfall_hours": round(shortfall, 2),
            "reason": f"Total required study time ({total_required_hours}h) exceeds total available time ({total_available_hours}h)."
        }

    # 2. Individual task deadline check
    for task in tasks:
        blocks_before_deadline = [b for b in time_blocks if b.end <= task.deadline]
        avail_hours_before_deadline = blocks_to_hours(len(blocks_before_deadline))
        if len(blocks_before_deadline) < task.required_blocks:
            shortfall = task.study_duration_hours - avail_hours_before_deadline
            return False, {
                "required_hours": task.study_duration_hours,
                "available_hours_before_deadline": avail_hours_before_deadline,
                "shortfall_hours": round(shortfall, 2),
                "task_id": task.id,
                "task_name": task.task_name,
                "reason": (
                    f"Task '{task.task_name}' requires {task.study_duration_hours}h, but only "
                    f"{avail_hours_before_deadline}h of free time exists before its deadline ({task.deadline.isoformat()})."
                )
            }

    return True, None


def validate_schedule_constraints(
    schedule: List[ScheduleBlock],
    tasks: List[Task],
    time_blocks: List[TimeBlock]
) -> Tuple[bool, List[ConstraintViolation]]:
    """
    Validates all hard constraints (C1-C5) on a candidate schedule.
    Returns (is_valid, list_of_violations).
    """
    violations: List[ConstraintViolation] = []
    task_map: Dict[str, Task] = {t.id: t for t in tasks}
    assigned_blocks_per_task: Dict[str, int] = {t.id: 0 for t in tasks}
    occupied_times = set()

    # Valid available block intervals
    valid_intervals = {(b.start, b.end) for b in time_blocks}

    for block in schedule:
        # C3: No Overlap
        interval = (block.start, block.end)
        if interval in occupied_times:
            violations.append(ConstraintViolation("C3", f"Overlapping block assignment at {block.start}", block.task_id))
        occupied_times.add(interval)

        # C1: Availability
        if interval not in valid_intervals:
            violations.append(ConstraintViolation("C1", f"Block {block.start} to {block.end} is outside available free slots", block.task_id))

        task = task_map.get(block.task_id)
        if not task:
            violations.append(ConstraintViolation("C0", f"Unknown task id '{block.task_id}' in schedule", block.task_id))
            continue

        # C2: Deadline
        if block.end > task.deadline:
            violations.append(ConstraintViolation("C2", f"Block for task '{task.task_name}' ends at {block.end}, after deadline {task.deadline}", task.id))

        assigned_blocks_per_task[task.id] += 1

    # C4: Duration satisfaction
    for task in tasks:
        count = assigned_blocks_per_task.get(task.id, 0)
        if count != task.required_blocks:
            violations.append(ConstraintViolation(
                "C4",
                f"Task '{task.task_name}' requires {task.required_blocks} blocks ({task.study_duration_hours}h), but got {count} blocks ({blocks_to_hours(count)}h)",
                task.id
            ))

    is_valid = (len(violations) == 0)
    return is_valid, violations
