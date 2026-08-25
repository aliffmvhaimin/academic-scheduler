# Changelog

All notable changes to the Academic Task Scheduling project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.1.0] - 2026-08-25

### Added
- Repository directory structure and documentation files:
  - `AGENTS.md`, `PROJECT_SPEC.md`, `DESIGN_SYSTEM.md`, `ARCHITECTURE.md`, `GA_SPECIFICATION.md`, `API_CONTRACT.md`, `DEVELOPMENT_PLAN.md`, `RESEARCH_PLAN.md`, `DECISIONS.md`, `README.md`.
- **Backend Architecture & Domain Models**:
  - `Task`, `FreeSlot`, `TimeBlock`, `ScheduleBlock`, `ScheduleResult` domain models.
  - Pydantic v2 schemas for tasks, availability, schedule generation, and dynamic recalculation requests.
- **Core Constraint & Priority Engine**:
  - 15-minute time discretization module (`time_blocks.py`).
  - Task priority scoring based on urgency, credit weight, and difficulty (`priority.py`).
  - Hard constraint checkers ($C1$–$C5$) and fast preliminary feasibility analysis (`constraints.py`).
- **Schedulers**:
  - Deterministic `GreedyScheduler` baseline.
  - Full `GeneticScheduler` optimization engine with DEAP:
    - Chromosome representation, multi-objective fitness evaluation, tournament selection ($k=3$), single-point crossover ($P_c=0.8$), random block reassignment mutation ($P_m=0.02$), hard-constraint repair operator, elitism, and plateau termination.
- **FastAPI REST API**:
  - `GET /health` and `GET /api/v1/health`.
  - `POST /api/v1/schedule` and `POST /api/v1/schedule/recalculate`.
  - CORS middleware and service orchestration layer.
- **Automated Testing Suite**:
  - 18 unit and integration tests passing in 2.1s.
- **Research Evaluation Suite**:
  - Benchmark scenario generators (Scenarios A–D).
  - Multi-seed benchmark runner logging runtime, fitness scores, and feasibility.
