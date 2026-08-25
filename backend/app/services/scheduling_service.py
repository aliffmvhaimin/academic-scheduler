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

    def recalculate_schedule(self, request: RecalculateScheduleRequest) -> ScheduleResponse:
        # Filter out completed tasks
        completed_set = set(request.completed_task_ids or [])
        active_task_schemas = [t for t in request.tasks if t.id not in completed_set]

        tasks = self._convert_tasks(active_task_schemas)
        slots = self._convert_slots(request.free_slots)

        # Execute recalculation with GA
        result = self.scheduler.schedule(tasks, slots)
        return self._map_result_to_response(result)
