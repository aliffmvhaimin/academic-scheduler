"""Utilities for discretizing time into 15-minute blocks."""
from datetime import datetime, timedelta
from typing import List, Tuple
from dataclasses import dataclass
from app.models.availability import FreeSlot


@dataclass(frozen=True)
class TimeBlock:
    """A discrete 15-minute time window available for study."""
    index: int
    start: datetime
    end: datetime

    def __post_init__(self):
        if self.end - self.start != timedelta(minutes=15):
            raise ValueError(f"TimeBlock duration must be exactly 15 minutes, got {self.end - self.start}.")


def generate_time_blocks_from_slots(free_slots: List[FreeSlot]) -> List[TimeBlock]:
    """
    Converts a list of FreeSlot intervals into an ordered list of discrete 15-minute TimeBlocks.
    Sorts slots chronologically and avoids overlapping duplicate blocks.
    """
    sorted_slots = sorted(free_slots, key=lambda s: s.start_datetime)
    blocks: List[TimeBlock] = []
    seen_starts = set()
    block_index = 0

    for slot in sorted_slots:
        curr_time = slot.start_datetime
        end_time = slot.end_datetime

        while curr_time + timedelta(minutes=15) <= end_time:
            next_time = curr_time + timedelta(minutes=15)
            if curr_time not in seen_starts:
                seen_starts.add(curr_time)
                blocks.append(TimeBlock(index=block_index, start=curr_time, end=next_time))
                block_index += 1
            curr_time = next_time

    return blocks


def hours_to_blocks(duration_hours: float) -> int:
    """Converts hours into exact number of 15-minute blocks."""
    return int(round(duration_hours * 4))


def blocks_to_hours(block_count: int) -> float:
    """Converts 15-minute block count into hours."""
    return block_count * 0.25
