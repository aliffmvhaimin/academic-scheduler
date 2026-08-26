"""Hard constraint validation, feasibility checking, and infeasibility diagnostics."""
from datetime import datetime, timedelta
from typing import List, Dict, Tuple, Optional, Any, Set
from app.models.task import Task
from app.models.schedule import ScheduleBlock
from app.core.time_blocks import TimeBlock, blocks_to_hours, hours_to_blocks


class ConstraintViolation:
    """Represents a violation of a hard scheduling constraint."""
    def __init__(self, constraint_code: str, message: str, task_id: Optional[str] = None):
        self.constraint_code = constraint_code  # C1, C2, C3, C4, C5, C0
        self.message = message
        self.task_id = task_id

    def to_dict(self) -> Dict[str, Any]:
        return {
            "code": self.constraint_code,
            "message": self.message,
            "task_id": self.task_id
        }

    def __repr__(self) -> str:
        return f"ConstraintViolation({self.constraint_code}, task_id={self.task_id}, message='{self.message}')"


# ==========================================
# Individual Hard Constraint Checkers
# ==========================================

def validate_availability_constraint(
    schedule: List[ScheduleBlock],
    valid_intervals: Set[Tuple[datetime, datetime]]
) -> List[ConstraintViolation]:
    """
    C1: A study block must occur within a student's available time.
    """
    violations = []
    for block in schedule:
        interval = (block.start, block.end)
        if interval not in valid_intervals:
            violations.append(ConstraintViolation(
                "C1",
                f"Block {block.start.isoformat()} to {block.end.isoformat()} is outside available free slots",
                block.task_id
            ))
    return violations


def validate_deadline_constraint(
    schedule: List[ScheduleBlock],
    task_map: Dict[str, Task]
) -> List[ConstraintViolation]:
    """
    C2: A study block must occur before the task deadline.
    """
    violations = []
    for block in schedule:
        task = task_map.get(block.task_id)
        if task and block.end > task.deadline:
            violations.append(ConstraintViolation(
                "C2",
                f"Block for task '{task.task_name}' ends at {block.end.isoformat()}, after deadline {task.deadline.isoformat()}",
                task.id
            ))
    return violations


def validate_overlap_constraint(
    schedule: List[ScheduleBlock]
) -> List[ConstraintViolation]:
    """
    C3: A time block cannot contain multiple tasks (no overlapping assignments).
    """
    violations = []
    occupied_times: Set[Tuple[datetime, datetime]] = set()
    for block in schedule:
        interval = (block.start, block.end)
        if interval in occupied_times:
            violations.append(ConstraintViolation(
                "C3",
                f"Overlapping block assignment at {block.start.isoformat()}",
                block.task_id
            ))
        occupied_times.add(interval)
    return violations


def validate_duration_constraint(
    schedule: List[ScheduleBlock],
    tasks: List[Task]
) -> List[ConstraintViolation]:
    """
    C4: Each task must receive its exact required study duration.
    """
    violations = []
    assigned_counts: Dict[str, int] = {t.id: 0 for t in tasks}
    for block in schedule:
        if block.task_id in assigned_counts:
            assigned_counts[block.task_id] += 1

    for task in tasks:
        count = assigned_counts.get(task.id, 0)
        if count != task.required_blocks:
            violations.append(ConstraintViolation(
                "C4",
                f"Task '{task.task_name}' requires {task.required_blocks} blocks ({task.study_duration_hours}h), but got {count} blocks ({blocks_to_hours(count)}h)",
                task.id
            ))
    return violations


def validate_granularity_constraint(
    schedule: List[ScheduleBlock]
) -> List[ConstraintViolation]:
    """
    C5: All study blocks must be exactly 15 minutes.
    """
    violations = []
    for block in schedule:
        duration = block.end - block.start
        if duration != timedelta(minutes=15):
            violations.append(ConstraintViolation(
                "C5",
                f"Block duration is {duration.total_seconds() / 60.0} minutes; must be exactly 15 minutes.",
                block.task_id
            ))
    return violations


# ==========================================
# Integrated Feasibility Checker
# ==========================================

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

    # Verify task IDs exist
    for block in schedule:
        if block.task_id not in task_map:
            violations.append(ConstraintViolation("C0", f"Unknown task ID '{block.task_id}' in schedule", block.task_id))

    valid_intervals = {(b.start, b.end) for b in time_blocks}

    # Run individual constraint validations
    violations.extend(validate_granularity_constraint(schedule))
    violations.extend(validate_availability_constraint(schedule, valid_intervals))
    violations.extend(validate_deadline_constraint(schedule, task_map))
    violations.extend(validate_overlap_constraint(schedule))
    violations.extend(validate_duration_constraint(schedule, tasks))

    is_valid = (len(violations) == 0)
    return is_valid, violations


def is_schedule_feasible(
    schedule: List[ScheduleBlock],
    tasks: List[Task],
    time_blocks: List[TimeBlock]
) -> bool:
    """Convenience boolean checker for schedule feasibility."""
    is_valid, _ = validate_schedule_constraints(schedule, tasks, time_blocks)
    return is_valid


# ==========================================
# Infeasibility Diagnostics & Preliminary Checker
# ==========================================

def check_preliminary_feasibility(
    tasks: List[Task],
    time_blocks: List[TimeBlock]
) -> Tuple[bool, Optional[Dict[str, Any]]]:
    """
    Analyzes capacity and deadline constraints to determine if a problem instance
    is mathematically infeasible before executing optimization.

    Checks:
    1. Total required study time vs total available free time (Capacity check).
    2. Individual task required study time vs available free time before deadline.
    3. Cumulative required study time for tasks sorted by deadline vs cumulative available slots.

    Returns:
        (is_feasible, diagnostics_dict)
    """
    if not tasks:
        return False, {
            "required_hours": 0.0,
            "available_hours": blocks_to_hours(len(time_blocks)),
            "shortfall_hours": 0.0,
            "reason": "Task list is empty."
        }

    if not time_blocks:
        total_req_hours = sum(t.study_duration_hours for t in tasks)
        return False, {
            "required_hours": total_req_hours,
            "available_hours": 0.0,
            "shortfall_hours": total_req_hours,
            "reason": "No available study slots provided."
        }

    total_required_blocks = sum(t.required_blocks for t in tasks)
    total_available_blocks = len(time_blocks)
    total_required_hours = blocks_to_hours(total_required_blocks)
    total_available_hours = blocks_to_hours(total_available_blocks)

    # 1. Total capacity check
    if total_required_blocks > total_available_blocks:
        shortfall = round(total_required_hours - total_available_hours, 2)
        return False, {
            "required_hours": total_required_hours,
            "available_hours": total_available_hours,
            "available_hours_before_deadline": total_available_hours,
            "shortfall_hours": shortfall,
            "reason": f"Total required study time ({total_required_hours}h) exceeds total available time ({total_available_hours}h)."
        }

    # 2. Individual task deadline check
    for task in tasks:
        blocks_before_deadline = [b for b in time_blocks if b.end <= task.deadline]
        avail_hours_before = blocks_to_hours(len(blocks_before_deadline))
        if len(blocks_before_deadline) < task.required_blocks:
            shortfall = round(task.study_duration_hours - avail_hours_before, 2)
            return False, {
                "required_hours": task.study_duration_hours,
                "available_hours": total_available_hours,
                "available_hours_before_deadline": avail_hours_before,
                "shortfall_hours": shortfall,
                "task_id": task.id,
                "task_name": task.task_name,
                "reason": (
                    f"Task '{task.task_name}' requires {task.study_duration_hours}h, but only "
                    f"{avail_hours_before}h of free time exists before its deadline ({task.deadline.isoformat()})."
                )
            }

    # 3. Cumulative deadline feasibility check (Pigeonhole principle across sorted deadlines)
    sorted_by_deadline = sorted(tasks, key=lambda t: t.deadline)
    cumulative_req_blocks = 0
    for task in sorted_by_deadline:
        cumulative_req_blocks += task.required_blocks
        avail_before_task = len([b for b in time_blocks if b.end <= task.deadline])
        if cumulative_req_blocks > avail_before_task:
            cum_req_hours = blocks_to_hours(cumulative_req_blocks)
            cum_avail_hours = blocks_to_hours(avail_before_task)
            shortfall = round(cum_req_hours - cum_avail_hours, 2)
            return False, {
                "required_hours": cum_req_hours,
                "available_hours": total_available_hours,
                "available_hours_before_deadline": cum_avail_hours,
                "shortfall_hours": shortfall,
                "task_id": task.id,
                "task_name": task.task_name,
                "reason": (
                    f"Cumulative study demand ({cum_req_hours}h) up to deadline {task.deadline.isoformat()} "
                    f"exceeds available free time ({cum_avail_hours}h)."
                )
            }

    return True, None
