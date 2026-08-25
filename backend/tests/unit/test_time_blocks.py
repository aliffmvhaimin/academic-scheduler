"""Unit tests specifically for 15-minute time block discretization and conversions."""
import pytest
from datetime import datetime, timedelta
from app.models.availability import FreeSlot
from app.core.time_blocks import (
    TimeBlock,
    generate_time_blocks_from_slots,
    hours_to_blocks,
    blocks_to_hours,
)


def test_time_block_exact_15_minutes():
    start = datetime(2026, 8, 25, 9, 0)
    end = datetime(2026, 8, 25, 9, 15)
    tb = TimeBlock(index=0, start=start, end=end)
    assert tb.index == 0
    assert tb.start == start
    assert tb.end == end


def test_time_block_invalid_duration():
    start = datetime(2026, 8, 25, 9, 0)
    end = datetime(2026, 8, 25, 9, 30)  # 30 mins instead of 15
    with pytest.raises(ValueError, match="exactly 15 minutes"):
        TimeBlock(index=0, start=start, end=end)


def test_hours_and_blocks_conversion():
    assert hours_to_blocks(1.0) == 4
    assert hours_to_blocks(0.25) == 1
    assert hours_to_blocks(2.5) == 10
    assert hours_to_blocks(0.0) == 0

    assert blocks_to_hours(4) == 1.0
    assert blocks_to_hours(1) == 0.25
    assert blocks_to_hours(10) == 2.5
    assert blocks_to_hours(0) == 0.0


def test_generate_time_blocks_single_slot():
    slots = [FreeSlot(date="2026-08-25", start="10:00", end="11:00")]  # 1 hour = 4 blocks
    blocks = generate_time_blocks_from_slots(slots)
    assert len(blocks) == 4
    assert [b.index for b in blocks] == [0, 1, 2, 3]
    assert blocks[0].start == datetime(2026, 8, 25, 10, 0)
    assert blocks[0].end == datetime(2026, 8, 25, 10, 15)
    assert blocks[3].start == datetime(2026, 8, 25, 10, 45)
    assert blocks[3].end == datetime(2026, 8, 25, 11, 0)


def test_generate_time_blocks_multiple_days_chronological():
    slots = [
        FreeSlot(date="2026-08-26", start="08:00", end="09:00"),  # Day 2: 4 blocks
        FreeSlot(date="2026-08-25", start="18:00", end="19:00"),  # Day 1: 4 blocks
    ]
    blocks = generate_time_blocks_from_slots(slots)
    assert len(blocks) == 8
    # Verifying sort order: Day 1 first, then Day 2
    assert blocks[0].start == datetime(2026, 8, 25, 18, 0)
    assert blocks[3].end == datetime(2026, 8, 25, 19, 0)
    assert blocks[4].start == datetime(2026, 8, 26, 8, 0)
    assert blocks[7].end == datetime(2026, 8, 26, 9, 0)


def test_generate_time_blocks_empty():
    blocks = generate_time_blocks_from_slots([])
    assert blocks == []
