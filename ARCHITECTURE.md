# System Architecture

## 1. Architecture Style

Three-tier architecture:

1. Presentation Layer
2. Business Logic Layer
3. Data Layer

---

# 2. Presentation Layer

Technology:

Flutter / Dart

Responsibilities:

- display UI
- collect user input
- validate basic input
- display schedules
- display errors
- communicate with API
- maintain local active task state

The Flutter layer must not implement the Genetic Algorithm.

---

# 3. Business Logic Layer

Technology:

Python / FastAPI / DEAP

Responsibilities:

- API handling
- request validation
- scheduling
- Genetic Algorithm execution
- greedy baseline execution
- constraint checking
- repair
- schedule generation

---

# 4. Data Layer

Local mobile persistence:

- active tasks
- user availability
- current schedule state where appropriate

No behavioural analytics are required.

---

# 5. Backend Architecture

API
 ↓
Scheduling Service
 ↓
Scheduler Interface
 ├── Greedy Scheduler
 └── Genetic Scheduler
       ↓
GA Engine
 ├── Chromosome
 ├── Fitness
 ├── Selection
 ├── Crossover
 ├── Mutation
 └── Repair

---

# 6. Separation of Concerns

Flutter:
"What does the user want?"

API:
"Receive and validate the request."

Scheduler:
"How should the schedule be generated?"

GA:
"How can candidate schedules be optimised?"

This separation must be preserved.