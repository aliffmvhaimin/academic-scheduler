"""Deterministic greedy baseline scheduler."""
import time
from datetime import datetime
from typing import List, Dict, Optional
from app.models.task import Task
from app.models.availability import FreeSlot
from app.models.schedule import ScheduleBlock, ScheduleResult
from app.schedulers.base import BaseScheduler
from app.core.time_blocks import generate_time_blocks_from_slots, TimeBlock
from app.core.priority import calculate_task_priority
from app.core.constraints import (
    check_preliminary_feasibility,
    validate_schedule_constraints,
)


class GreedyScheduler(BaseScheduler):
    """
    Greedy Priority Scheduler.
    Sorts tasks by composite priority (urgency, credit, difficulty) and
    assigns the earliest available 15-minute time blocks before deadlines.
    """

    def schedule(
        self,
        tasks: List[Task],
        free_slots: List[FreeSlot],
        reference_time: Optional[datetime] = None,
        **kwargs
    ) -> ScheduleResult:
        start_time_perf = time.perf_counter()

        if not tasks or not free_slots:
            return ScheduleResult(
                success=True,
                feasible=False,
                fitness_score=None,
                generation_count=0,
                execution_time_ms=0,
                schedule=[],
                diagnostics={"reason": "Empty task list or no free slots provided."}
            )

        time_blocks = generate_time_blocks_from_slots(free_slots)
        if not time_blocks:
            return ScheduleResult(
                success=True,
                feasible=False,
                fitness_score=None,
                generation_count=0,
                execution_time_ms=0,
                schedule=[],
                diagnostics={"reason": "No valid 15-minute time blocks could be formed."}
            )

        if reference_time is None:
            reference_time = time_blocks[0].start

        # Step 1: Capacity & Deadline preliminary check
        is_prelim_feasible, prelim_diag = check_preliminary_feasibility(tasks, time_blocks)
        if not is_prelim_feasible:
            exec_time = int((time.perf_counter() - start_time_perf) * 1000)
            return ScheduleResult(
                success=True,
                feasible=False,
                fitness_score=None,
                generation_count=1,
                execution_time_ms=exec_time,
                schedule=[],
                diagnostics=prelim_diag
            )

        # Step 2: Sort tasks by priority descending (break ties with earlier deadline)
        sorted_tasks = sorted(
            tasks,
            key=lambda t: (calculate_task_priority(t, reference_time), -t.deadline.timestamp()),
            reverse=True
        )

        occupied_indices = set()
        scheduled_blocks: List[ScheduleBlock] = []

        # Step 3: Sequential greedy assignment
        for task in sorted_tasks:
            assigned_for_task = 0
            for block in time_blocks:
                if block.index in occupied_indices:
                    continue
                if block.end <= task.deadline:
                    occupied_indices.add(block.index)
                    scheduled_blocks.append(ScheduleBlock(
                        task_id=task.id,
                        start=block.start,
                        end=block.end
                    ))
                    assigned_for_task += 1
                    if assigned_for_task == task.required_blocks:
                        break

            if assigned_for_task < task.required_blocks:
                # Could not fulfill this task's required blocks
                exec_time = int((time.perf_counter() - start_time_perf) * 1000)
                return ScheduleResult(
                    success=True,
                    feasible=False,
                    fitness_score=None,
                    generation_count=1,
                    execution_time_ms=exec_time,
                    schedule=[],
                    diagnostics={
                        "task_id": task.id,
                        "task_name": task.task_name,
                        "required_blocks": task.required_blocks,
                        "assigned_blocks": assigned_for_task,
                        "shortfall_hours": round((task.required_blocks - assigned_for_task) * 0.25, 2),
                        "reason": f"Greedy assignment could not find enough free slots before deadline for task '{task.task_name}'."
                    }
                )

        # Step 4: Sort scheduled blocks chronologically
        scheduled_blocks.sort(key=lambda b: b.start)

        # Step 5: Constraint validation
        is_valid, violations = validate_schedule_constraints(scheduled_blocks, tasks, time_blocks)
        exec_time = int((time.perf_counter() - start_time_perf) * 1000)

        if not is_valid:
            return ScheduleResult(
                success=True,
                feasible=False,
                fitness_score=None,
                generation_count=1,
                execution_time_ms=exec_time,
                schedule=[],
                diagnostics={"violations": [v.to_dict() for v in violations]}
            )

        # Step 6: Simple normalized objective score calculation
        # Objective rewards earlier scheduling for higher priority tasks
        total_score = 0.0
        for block in scheduled_blocks:
            task = next(t for t in tasks if t.id == block.task_id)
            priority = calculate_task_priority(task, reference_time)
            # Distance from horizon start (earlier is better)
            hours_from_start = max(0.0, (block.start - reference_time).total_seconds() / 3600.0)
            decay = 1.0 / (1.0 + 0.01 * hours_from_start)
            total_score += priority * decay

        normalized_fitness = round(total_score / max(1, len(scheduled_blocks)), 4)

        return ScheduleResult(
            success=True,
            feasible=True,
            fitness_score=normalized_fitness,
            generation_count=1,
            execution_time_ms=exec_time,
            schedule=scheduled_blocks,
            diagnostics=None
        )
