"""Abstract base class for all schedulers."""
from abc import ABC, abstractmethod
from typing import List, Optional
from app.models.task import Task
from app.models.availability import FreeSlot
from app.models.schedule import ScheduleResult


class BaseScheduler(ABC):
    """Base interface for scheduling algorithms."""

    @abstractmethod
    def schedule(
        self,
        tasks: List[Task],
        free_slots: List[FreeSlot],
        **kwargs
    ) -> ScheduleResult:
        """
        Generates a schedule for the given tasks within available free slots.

        Returns:
            ScheduleResult containing scheduled blocks or infeasibility diagnostics.
        """
        pass
