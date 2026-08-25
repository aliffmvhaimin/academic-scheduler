# Academic Scheduler Backend

FastAPI & DEAP-based Academic Task Scheduling Engine.

## Overview

The backend is responsible for receiving task and availability payloads, converting time horizons into 15-minute discrete blocks, verifying constraint feasibility, and executing the Genetic Algorithm (and Greedy baseline) scheduler.

## Project Structure

```
backend/
├── app/
│   ├── main.py                     # FastAPI application entry point
│   ├── api/
│   │   └── routes/
│   │       ├── health.py           # Health check endpoint (/api/v1/health)
│   │       └── scheduling.py       # Schedule generation & recalculation endpoints
│   ├── models/                     # Domain models
│   ├── schemas/                    # Pydantic request/response schemas
│   ├── services/                   # Business logic (scheduling_service.py)
│   ├── schedulers/                 # Scheduler interface, Greedy & Genetic implementations
│   ├── genetic_algorithm/          # DEAP chromosome, fitness, repair, operators, engine
│   └── core/                       # Constraints, time block utilities, priority scoring
├── tests/
│   ├── unit/                       # Unit tests for domain, GA operators, constraints
│   ├── integration/                # API route integration tests
│   └── fixtures/                   # Test fixtures and benchmark cases
├── requirements.txt                # Python dependencies
└── .env.example                    # Environment variable template
```

## Setup & Running

1. **Create Virtual Environment**:
   ```bash
   python -m venv venv
   # Windows:
   venv\Scripts\activate
   # Linux/macOS:
   source venv/bin/activate
   ```

2. **Install Dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Run Dev Server**:
   ```bash
   uvicorn app.main:app --reload --port 8000
   ```

4. **Run Tests**:
   ```bash
   pytest
   ```
