"""Chromosome representation for the Genetic Algorithm."""
from typing import List, Optional
from dataclasses import dataclass
from app.models.task import Task
from app.core.time_blocks import TimeBlock

# Gene constant for empty/unassigned block
EMPTY_GENE: Optional[str] = None


class Chromosome(list):
    """
    A chromosome representing a candidate schedule.
    Length equals total number of available 15-minute TimeBlocks.
    Each gene is either a task.id string or None (EMPTY_GENE).
    """
    def __init__(self, genes: Optional[List[Optional[str]]] = None):
        if genes is not None:
            super().__init__(genes)
        else:
            super().__init__()
        self.fitness_values: Optional[tuple] = None

    def clone(self) -> "Chromosome":
        c = Chromosome(list(self))
        c.fitness_values = self.fitness_values
        return c
