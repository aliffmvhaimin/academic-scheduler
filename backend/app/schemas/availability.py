"""Pydantic schemas for free study slot availability."""
from datetime import datetime
from pydantic import BaseModel, Field, field_validator


class FreeSlotSchema(BaseModel):
    """Schema for a single available time slot on a specific date."""
    date: str = Field(..., description="Date in YYYY-MM-DD format", pattern=r"^\d{4}-\d{2}-\d{2}$")
    start: str = Field(..., description="Start time in HH:MM format", pattern=r"^\d{2}:\d{2}$")
    end: str = Field(..., description="End time in HH:MM format", pattern=r"^\d{2}:\d{2}$")

    @field_validator("date")
    @classmethod
    def validate_date(cls, v: str) -> str:
        try:
            datetime.strptime(v, "%Y-%m-%d")
        except ValueError:
            raise ValueError(f"Invalid date: {v}. Must be a valid YYYY-MM-DD date.")
        return v

    @field_validator("end")
    @classmethod
    def validate_time_order(cls, v: str, info) -> str:
        start = info.data.get("start")
        if start:
            try:
                t_start = datetime.strptime(start, "%H:%M").time()
                t_end = datetime.strptime(v, "%H:%M").time()
                if t_start >= t_end:
                    raise ValueError(f"Start time ({start}) must be before end time ({v}).")
            except ValueError as e:
                raise e
        return v
