"""Scheduling API routes."""
from fastapi import APIRouter, Depends, HTTPException, status
from app.schemas.scheduling import ScheduleRequest, ScheduleResponse, RecalculateScheduleRequest
from app.services.scheduling_service import SchedulingService

router = APIRouter(prefix="/schedule", tags=["Scheduling"])


def get_scheduling_service() -> SchedulingService:
    return SchedulingService()


@router.post("", response_model=ScheduleResponse, status_code=status.HTTP_200_OK)
async def generate_schedule(
    request: ScheduleRequest,
    service: SchedulingService = Depends(get_scheduling_service)
) -> ScheduleResponse:
    """
    Generates an optimized academic study schedule using the Genetic Algorithm.
    """
    try:
        return service.generate_schedule(request)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error generating schedule: {str(e)}"
        )


@router.post("/recalculate", response_model=ScheduleResponse, status_code=status.HTTP_200_OK)
async def recalculate_schedule(
    request: RecalculateScheduleRequest,
    service: SchedulingService = Depends(get_scheduling_service)
) -> ScheduleResponse:
    """
    Dynamically recalculates the schedule upon task addition/edit or missed study block.
    """
    try:
        return service.recalculate_schedule(request)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error recalculating schedule: {str(e)}"
        )
