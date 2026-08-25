"""Domain models for user availability and free study slots."""
from datetime import datetime, date, time
from dataclasses import dataclass


@dataclass(frozen=True)
class FreeSlot:
    """Represents an available time window on a specific date."""
    date: str     # YYYY-MM-DD
    start: str    # HH:MM (24-hour format)
    end: str      # HH:MM (24-hour format)

    def __post_init__(self):
        # Validate format and chronological order
        try:
            d = datetime.strptime(self.date, "%Y-%m-%d").date()
        except ValueError:
            raise ValueError(f"Invalid date format: {self.date}. Expected YYYY-MM-DD.")

        try:
            t_start = datetime.strptime(self.start, "%H:%M").time()
            t_end = datetime.strptime(self.end, "%H:%M").time()
        except ValueError:
            raise ValueError(f"Invalid time format in start '{self.start}' or end '{self.end}'. Expected HH:MM.")

        if t_start >= t_end:
            raise ValueError(f"Start time ({self.start}) must be strictly before end time ({self.end}).")

    @property
    def start_datetime(self) -> datetime:
        return datetime.strptime(f"{self.date} {self.start}", "%Y-%m-%d %H:%M")

    @property
    def end_datetime(self) -> datetime:
        return datetime.strptime(f"{self.date} {self.end}", "%Y-%m-%d %H:%M")

    @property
    def duration_hours(self) -> float:
        delta = self.end_datetime - self.start_datetime
        return delta.total_seconds() / 3600.0

    @property
    def available_blocks(self) -> int:
        """Total 15-minute blocks in this slot."""
        return int(round(self.duration_hours * 4))
