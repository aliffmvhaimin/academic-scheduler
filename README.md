# Academic Task Scheduling Mobile Application Using Genetic Algorithm

Final-Year Project (Bachelor of Computer Science)

## 📌 Project Overview

This repository contains the implementation of an **Academic Task Scheduling Mobile Application** that generates personalized, constraint-aware study schedules from student-defined academic tasks and available study time windows.

The research focus is evaluating the efficacy of a **Genetic Algorithm (GA)** for combinatorial academic schedule optimization against a deterministic **Greedy priority baseline**.

---

## 🏛️ System Architecture

The project follows a decoupled three-tier architecture:

- **Frontend (`/frontend`)**: Mobile interface built with Flutter (Dart), featuring a custom Neo-Brutalist design system.
- **Backend (`/backend`)**: REST API built with FastAPI (Python) and evolutionary computation using DEAP.
- **Experiments (`/experiments`)**: Benchmark datasets, evaluation scripts, and comparison notebooks.
- **Documentation (`/docs`)**: Architecture diagrams, testing assets, and technical documentation.

```
academic-scheduler/
├── AGENTS.md               # Antigravity master instructions & coding rules
├── README.md               # Repository overview and setup guide
├── PROJECT_SPEC.md         # Source of truth for functional requirements & scope
├── DESIGN_SYSTEM.md        # Neo-brutalist design guidelines and design tokens
├── ARCHITECTURE.md         # System architecture and layer boundaries
├── GA_SPECIFICATION.md     # Exact Genetic Algorithm chromosome, operators & fitness
├── API_CONTRACT.md         # REST API schema specification (/api/v1)
├── DEVELOPMENT_PLAN.md     # 15-phase implementation roadmap
├── RESEARCH_PLAN.md        # Experimental methodology, benchmarks & metrics
├── DECISIONS.md            # Architecture Decision Records (ADRs)
├── CHANGELOG.md            # Version and modification history
├── backend/                # FastAPI + DEAP scheduling engine
├── frontend/               # Flutter mobile application
├── experiments/            # Research evaluation scripts & datasets
└── docs/                   # Diagrams, screenshots, and test artifacts
```

---

## 🔬 Core Scheduling Problem

### Hard Constraints (Must NEVER be violated in a feasible schedule):
1. **C1 (Availability)**: Study blocks can only be scheduled within user-defined free slots.
2. **C2 (Deadline)**: No study block may be scheduled after the task's deadline.
3. **C3 (No Overlap)**: A 15-minute time block can contain at most one task.
4. **C4 (Duration)**: Each task must be allocated its exact required study duration.
5. **C5 (Granularity)**: Fixed 15-minute time-slot discrete representation.

### Soft Objectives (Optimized by GA):
- **Deadline Urgency**: Prioritizing tasks due sooner.
- **Credit Weight**: Weighting study allocation relative to course credits (1–6).
- **Difficulty Score**: Allocating adequate focus for challenging subjects (1–10).

---

## 🛠️ Technology Stack

| Layer | Technology | Role |
|---|---|---|
| **Mobile Frontend** | Flutter & Dart | User interface, task CRUD, schedule visualization |
| **Backend Framework** | FastAPI (Python 3.11+) | REST API endpoints, validation, request routing |
| **Data Validation** | Pydantic v2 | Data schemas and serialization |
| **Optimization Algorithm** | DEAP (Python) | Chromosome operations, fitness calculation, repair |
| **Testing** | pytest, flutter_test | Unit, integration, and UI testing |

---

## 🚀 Getting Started

### Backend Setup
```bash
cd backend
python -m venv venv
# Windows:
venv\Scripts\activate
# Linux/macOS:
# source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```
API Documentation will be available at `http://localhost:8000/docs`.

### Frontend Setup
```bash
cd frontend
flutter pub get
flutter run
```

---

## 📜 Research & Academic Disclaimer

The Genetic Algorithm implemented here is an approximate heuristic optimization method. It is evaluated experimentally against a greedy baseline. It does not claim universal superiority or guaranteed global optimality across arbitrary combinatorial spaces.
