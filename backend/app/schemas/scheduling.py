"""Pydantic schemas for schedule generation and recalculation."""
from datetime import datetime
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
from app.schemas.task import TaskSchema
from app.schemas.availability import FreeSlotSchema


class ScheduleBlockSchema(BaseModel):
    """Schema for an individual 15-minute scheduled study block."""
    task_id: str = Field(..., description="ID of the task assigned to this block")
    start: datetime = Field(..., description="Block start datetime (ISO-8601)")
    end: datetime = Field(..., description="Block end datetime (ISO-8601)")


class ScheduleRequest(BaseModel):
    """Request payload to generate a study schedule."""
    tasks: List[TaskSchema] = Field(..., min_length=1, description="List of tasks to schedule")
    free_slots: List[FreeSlotSchema] = Field(..., min_length=1, description="List of available study time windows")


class ScheduleResponse(BaseModel):
    """Response payload containing generated schedule or infeasibility report."""
    success: bool = Field(..., description="Indicates if request was processed without system error")
    feasible: bool = Field(..., description="True if a valid schedule satisfies all hard constraints")
    fitness_score: Optional[float] = Field(None, description="Soft objective fitness score of best schedule")
    generation_count: int = Field(..., description="Number of generations executed by the GA (or iterations)")
    execution_time_ms: int = Field(..., description="Algorithm execution time in milliseconds")
    schedule: List[ScheduleBlockSchema] = Field(default_factory=list, description="Ordered list of study blocks")
    diagnostics: Optional[Dict[str, Any]] = Field(None, description="Detailed diagnostic metrics if infeasible or analytical stats")


class RecalculateScheduleRequest(BaseModel):
    """Request payload to dynamically recalculate schedule."""
    tasks: List[TaskSchema] = Field(..., description="Current active task list")
    free_slots: List[FreeSlotSchema] = Field(..., description="Current available free slots")
    missed_blocks: Optional[List[ScheduleBlockSchema]] = Field(default_factory=list, description="Blocks missed by user")
    completed_task_ids: Optional[List[str]] = Field(default_factory=list, description="IDs of already completed tasks")
