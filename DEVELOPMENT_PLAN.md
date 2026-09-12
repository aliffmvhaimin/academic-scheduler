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

- [x] priority calculation
- [x] task sorting
- [x] earliest feasible assignment
- [x] output model
- [x] tests

Acceptance:
- deterministic result for same input
- no hard constraint violations

---

# Phase 4 — GA Engine

- [x] chromosome
- [x] population
- [x] fitness
- [x] selection
- [x] crossover
- [x] mutation
- [x] repair
- [x] termination
- [x] deterministic seed support
- [x] tests

Acceptance:
- GA produces valid schedules for benchmark cases
- infeasible cases are reported
- all GA tests pass

---

# Phase 5 — Backend API

- [x] FastAPI application
- [x] health endpoint
- [x] POST /schedule
- [x] POST /schedule/recalculate
- [x] request validation
- [x] error handling
- [x] API tests
- [x] OpenAPI inspection

Acceptance:
- API works independently of Flutter

---

# Phase 6 — Flutter Foundation

- [x] theme
- [x] navigation
- [x] models
- [x] API client
- [x] local persistence
- [x] loading/error states

Acceptance:
- Flutter application launches

---

# Phase 7 — Task Management

- [x] task list
- [x] create task
- [x] edit task
- [x] delete task
- [x] validation

Acceptance:
- complete task CRUD flow works locally

---

# Phase 8 — Availability

- [x] availability UI
- [x] daily time windows
- [x] validation
- [x] persistence

Acceptance:
- availability can be created and edited

---

# Phase 9 — Schedule UI

- [x] schedule timeline
- [x] task blocks
- [x] schedule detail
- [x] deadline information
- [x] priority contribution
- [x] empty state
- [x] infeasible state

Acceptance:
- generated API schedules render correctly

---

# Phase 10 — Integration

- [x] Flutter → API
- [x] API → GA
- [x] GA → API
- [x] API → Flutter
- [x] loading state
- [x] network failure
- [x] infeasible schedule
- [x] malformed response

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