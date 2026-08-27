"""Deterministic greedy baseline scheduler."""
import time
from datetime import datetime
from typing import List, Dict, Optional
from app.models.task import Task
from app.models.availability import FreeSlot
from app.models.schedule import ScheduleBlock, ScheduleResult
from app.schedulers.base import BaseScheduler
from app.core.time_blocks import generate_time_blocks_from_slots, TimeBlock, blocks_to_hours
from app.core.priority import calculate_task_priority, sort_tasks_by_priority
from app.core.constraints import (
    check_preliminary_feasibility,
    validate_schedule_constraints,
)


class GreedyScheduler(BaseScheduler):
    """
    Greedy Priority Scheduler.
    Sorts tasks by composite priority (urgency, credit, difficulty) and
    assigns the earliest available 15-minute time blocks before deadlines.

    Guarantees:
    - 100% deterministic results for identical inputs.
    - Zero hard constraint violations on feasible results.
    """

    def __init__(
        self,
        w_urgency: float = 0.5,
        w_credit: float = 0.3,
        w_difficulty: float = 0.2
    ):
        self.w_urgency = w_urgency
        self.w_credit = w_credit
        self.w_difficulty = w_difficulty

    def schedule(
        self,
        tasks: List[Task],
        free_slots: List[FreeSlot],
        reference_time: Optional[datetime] = None,
        **kwargs
    ) -> ScheduleResult:
        start_time_perf = time.perf_counter()

        # Handle empty inputs
        if not tasks:
            return ScheduleResult(
                success=True,
                feasible=False,
                fitness_score=None,
                generation_count=0,
                execution_time_ms=0,
                schedule=[],
                diagnostics={"reason": "Empty task list provided."}
            )

        if not free_slots:
            total_req_hours = sum(t.study_duration_hours for t in tasks)
            return ScheduleResult(
                success=True,
                feasible=False,
                fitness_score=None,
                generation_count=0,
                execution_time_ms=0,
                schedule=[],
                diagnostics={
                    "required_hours": total_req_hours,
                    "available_hours": 0.0,
                    "available_hours_before_deadline": 0.0,
                    "shortfall_hours": total_req_hours,
                    "reason": "No free study slots provided."
                }
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
                diagnostics={"reason": "No valid 15-minute time blocks could be formed from the provided free slots."}
            )

        if reference_time is None:
            reference_time = time_blocks[0].start

        # Step 1: Preliminary capacity and deadline feasibility check
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

        # Step 2: Deterministic task priority calculation and sorting
        sorted_scored_tasks = sort_tasks_by_priority(
            tasks=tasks,
            reference_time=reference_time,
            w_urgency=self.w_urgency,
            w_credit=self.w_credit,
            w_difficulty=self.w_difficulty
        )

        occupied_indices = set()
        scheduled_blocks: List[ScheduleBlock] = []

        # Step 3: Sequential greedy assignment to earliest feasible time blocks
        for task, priority_score in sorted_scored_tasks:
            assigned_for_task = 0
            for block in time_blocks:
                if block.index in occupied_indices:
                    continue
                # Hard Constraint C2: Block must occur before deadline
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

            # If task could not receive its full required duration
            if assigned_for_task < task.required_blocks:
                exec_time = int((time.perf_counter() - start_time_perf) * 1000)
                shortfall = round((task.required_blocks - assigned_for_task) * 0.25, 2)
                avail_hours_before = blocks_to_hours(len([b for b in time_blocks if b.end <= task.deadline]))
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
                        "required_hours": task.study_duration_hours,
                        "available_hours_before_deadline": avail_hours_before,
                        "shortfall_hours": shortfall,
                        "reason": f"Greedy assignment could not find enough free slots before deadline for task '{task.task_name}'."
                    }
                )

        # Step 4: Chronological ordering of scheduled study blocks
        scheduled_blocks.sort(key=lambda b: b.start)

        # Step 5: Constraint validation on final schedule
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

        # Step 6: Normalized objective fitness score calculation
        # Objective rewards scheduling earlier slots for higher priority tasks
        total_score = 0.0
        for block in scheduled_blocks:
            task = next(t for t in tasks if t.id == block.task_id)
            priority = calculate_task_priority(
                task,
                reference_time,
                w_urgency=self.w_urgency,
                w_credit=self.w_credit,
                w_difficulty=self.w_difficulty
            )
            # Distance from horizon start (earlier assignments yield higher reward)
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
