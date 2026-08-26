# Development Plan

## Phase 0 — Repository Setup

- [x] Create repository structure
- [x] Create Flutter project
- [x] Create FastAPI project
- [x] Create all specification files
- [x] Configure Git
- [x] Verify Flutter
- [x] Verify Python
- [x] Verify DEAP
- [x] Verify FastAPI

Acceptance:
- both frontend and backend start successfully
- repository structure matches ARCHITECTURE.md

---

# Phase 1 — Domain Models

- [x] Task model
- [x] Availability model
- [x] ScheduleBlock model
- [x] ScheduleResult model
- [x] Input validation
- [x] 15-minute block conversion
- [x] Unit tests

Acceptance:
- all domain tests pass

---

# Phase 2 — Constraint Engine

- [x] availability constraint
- [x] deadline constraint
- [x] overlap constraint
- [x] duration constraint
- [x] feasibility checker
- [x] infeasibility diagnostics

Acceptance:
- valid schedules accepted
- invalid schedules rejected
- infeasible cases identified

---

# Phase 3 — Greedy Baseline

- [ ] priority calculation
- [ ] task sorting
- [ ] earliest feasible assignment
- [ ] output model
- [ ] tests

Acceptance:
- deterministic result for same input
- no hard constraint violations

---

# Phase 4 — GA Engine

- [ ] chromosome
- [ ] population
- [ ] fitness
- [ ] selection
- [ ] crossover
- [ ] mutation
- [ ] repair
- [ ] termination
- [ ] deterministic seed support
- [ ] tests

Acceptance:
- GA produces valid schedules for benchmark cases
- infeasible cases are reported
- all GA tests pass

---

# Phase 5 — Backend API

- [ ] FastAPI application
- [ ] health endpoint
- [ ] POST /schedule
- [ ] POST /schedule/recalculate
- [ ] request validation
- [ ] error handling
- [ ] API tests
- [ ] OpenAPI inspection

Acceptance:
- API works independently of Flutter

---

# Phase 6 — Flutter Foundation

- [ ] theme
- [ ] navigation
- [ ] models
- [ ] API client
- [ ] local persistence
- [ ] loading/error states

Acceptance:
- Flutter application launches

---

# Phase 7 — Task Management

- [ ] task list
- [ ] create task
- [ ] edit task
- [ ] delete task
- [ ] validation

Acceptance:
- complete task CRUD flow works locally

---

# Phase 8 — Availability

- [ ] availability UI
- [ ] daily time windows
- [ ] validation
- [ ] persistence

Acceptance:
- availability can be created and edited

---

# Phase 9 — Schedule UI

- [ ] schedule timeline
- [ ] task blocks
- [ ] schedule detail
- [ ] deadline information
- [ ] priority contribution
- [ ] empty state
- [ ] infeasible state

Acceptance:
- generated API schedules render correctly

---

# Phase 10 — Integration

- [ ] Flutter → API
- [ ] API → GA
- [ ] GA → API
- [ ] API → Flutter
- [ ] loading state
- [ ] network failure
- [ ] infeasible schedule
- [ ] malformed response

Acceptance:
- complete end-to-end scheduling flow works

---

# Phase 11 — Iteration 1 Evaluation

- [ ] benchmark tests
- [ ] initial user testing
- [ ] collect feedback
- [ ] document issues
- [ ] identify required changes

Acceptance:
- evaluation results documented

---

# Phase 12 — Iteration 2

- [ ] dynamic recalculation
- [ ] missed study block handling
- [ ] new task recalculation
- [ ] GA parameter tuning
- [ ] UI refinement
- [ ] performance improvements

Acceptance:
- dynamic recalculation works end-to-end

---

# Phase 13 — Final Evaluation

- [ ] generate benchmark dataset
- [ ] run greedy
- [ ] run GA
- [ ] repeated seeds
- [ ] calculate metrics
- [ ] optional CP-SAT benchmark
- [ ] UAT
- [ ] produce graphs/tables

Acceptance:
- reproducible results exist

---

# Phase 14 — Finalisation

- [ ] bug fixing
- [ ] code cleanup
- [ ] documentation
- [ ] screenshots
- [ ] architecture diagram
- [ ] testing evidence
- [ ] Android build
- [ ] final demo scenario