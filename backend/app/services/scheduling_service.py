"""Service layer orchestrating scheduling operations."""
from datetime import datetime
from typing import List, Optional
from app.models.task import Task
from app.models.availability import FreeSlot
from app.models.schedule import ScheduleResult, ScheduleBlock
from app.schemas.task import TaskSchema
from app.schemas.availability import FreeSlotSchema
from app.schemas.scheduling import (
    ScheduleRequest,
    ScheduleResponse,
    ScheduleBlockSchema,
    RecalculateScheduleRequest,
)
from app.schedulers.base import BaseScheduler
from app.schedulers.genetic import GeneticScheduler
from app.schedulers.greedy import GreedyScheduler


class SchedulingService:
    """Orchestrates validation, scheduling execution, and response transformation."""

    def __init__(self, scheduler: Optional[BaseScheduler] = None):
        self.scheduler = scheduler or GeneticScheduler()
        self.baseline_scheduler = GreedyScheduler()

    def _convert_tasks(self, task_schemas: List[TaskSchema]) -> List[Task]:
        return [
            Task(
                id=t.id,
                task_name=t.task_name,
                credit_weight=t.credit_weight,
                difficulty_score=t.difficulty_score,
                deadline=t.deadline,
                study_duration_hours=t.study_duration_hours
            )
            for t in task_schemas
        ]

    def _convert_slots(self, slot_schemas: List[FreeSlotSchema]) -> List[FreeSlot]:
        return [
            FreeSlot(date=s.date, start=s.start, end=s.end)
            for s in slot_schemas
        ]

    def _map_result_to_response(self, result: ScheduleResult) -> ScheduleResponse:
        schedule_blocks = [
            ScheduleBlockSchema(
                task_id=b.task_id,
                start=b.start,
                end=b.end
            )
            for b in result.schedule
        ]
        return ScheduleResponse(
            success=result.success,
            feasible=result.feasible,
            fitness_score=result.fitness_score,
            generation_count=result.generation_count,
            execution_time_ms=result.execution_time_ms,
            schedule=schedule_blocks,
            diagnostics=result.diagnostics
        )

    def generate_schedule(self, request: ScheduleRequest, use_baseline: bool = False) -> ScheduleResponse:
        tasks = self._convert_tasks(request.tasks)
        slots = self._convert_slots(request.free_slots)

        scheduler = self.baseline_scheduler if use_baseline else self.scheduler
        result = scheduler.schedule(tasks, slots)
        return self._map_result_to_response(result)

    @staticmethod
    def _exclude_missed_blocks_from_slots(
        slots: List[FreeSlot],
        missed_blocks: List[ScheduleBlockSchema]
    ) -> List[FreeSlot]:
        """Excises time blocks corresponding to missed study sessions from candidate free slots."""
        if not missed_blocks or not slots:
            return slots

        from app.core.time_blocks import generate_time_blocks_from_slots
        missed_intervals = {(b.start, b.end) for b in missed_blocks}
        time_blocks = generate_time_blocks_from_slots(slots)

        valid_blocks = [b for b in time_blocks if (b.start, b.end) not in missed_intervals]
        if not valid_blocks:
            return []

        # Merge contiguous 15-minute blocks on the same calendar day back into FreeSlot models
        merged_slots: List[FreeSlot] = []
        current_start = valid_blocks[0].start
        current_end = valid_blocks[0].end

        for i in range(1, len(valid_blocks)):
            b = valid_blocks[i]
            if b.start == current_end and b.start.date() == current_start.date():
                current_end = b.end
            else:
                merged_slots.append(FreeSlot(
                    date=current_start.strftime("%Y-%m-%d"),
                    start=current_start.strftime("%H:%M"),
                    end=current_end.strftime("%H:%M")
                ))
                current_start = b.start
                current_end = b.end

        merged_slots.append(FreeSlot(
            date=current_start.strftime("%Y-%m-%d"),
            start=current_start.strftime("%H:%M"),
            end=current_end.strftime("%H:%M")
        ))
        return merged_slots

    def recalculate_schedule(self, request: RecalculateScheduleRequest) -> ScheduleResponse:
        # Filter out completed tasks
        completed_set = set(request.completed_task_ids or [])
        active_task_schemas = [t for t in request.tasks if t.id not in completed_set]

        if not active_task_schemas:
            return ScheduleResponse(
                success=True,
                feasible=True,
                fitness_score=None,
                generation_count=0,
                execution_time_ms=0,
                schedule=[],
                diagnostics={"info": "All tasks are completed. No active tasks to schedule."}
            )

        tasks = self._convert_tasks(active_task_schemas)
        raw_slots = self._convert_slots(request.free_slots)

        # Remove missed study blocks from available time horizon so they are not re-assigned
        slots = self._exclude_missed_blocks_from_slots(raw_slots, request.missed_blocks or [])

        if not slots:
            return ScheduleResponse(
                success=True,
                feasible=False,
                fitness_score=None,
                generation_count=0,
                execution_time_ms=0,
                schedule=[],
                diagnostics={
                    "reason": "All available study time slots have been exhausted by missed sessions.",
                    "required_hours": sum(t.study_duration_hours for t in tasks),
                    "available_hours_before_deadline": 0.0,
                    "shortfall_hours": sum(t.study_duration_hours for t in tasks)
                }
            )

        # Execute dynamic recalculation with GA
        result = self.scheduler.schedule(tasks, slots)
        return self._map_result_to_response(result)
