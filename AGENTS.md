# AGENTS.md

## Project Identity

This repository contains the implementation of a Bachelor of Computer
Science final-year project:

"Academic Task Scheduling Mobile Application Using Genetic Algorithm"

The system generates personalised academic study schedules from
student-provided academic tasks and available study time.

The primary research component is the scheduling algorithm.
The Flutter application is the delivery/interface component.

---

# 1. Agent Role

You are the implementation agent.

Your responsibilities:

- inspect the existing code before modifying it
- follow the project specifications in this repository
- implement incrementally
- write tests for non-trivial functionality
- run tests after changes
- report what changed
- never silently change architectural decisions
- never introduce features outside project scope

The human developer remains responsible for:
- research decisions
- algorithm design
- requirements
- acceptance criteria
- final code review

---

# 2. Source of Truth

Read these documents before implementing substantial functionality:

1. PROJECT_SPEC.md
2. ARCHITECTURE.md
3. GA_SPECIFICATION.md
4. API_CONTRACT.md
5. DEVELOPMENT_PLAN.md
6. RESEARCH_PLAN.md
7. DECISIONS.md

If documents conflict:

1. PROJECT_SPEC.md
2. GA_SPECIFICATION.md
3. API_CONTRACT.md
4. ARCHITECTURE.md
5. DEVELOPMENT_PLAN.md
6. DECISIONS.md

Do not invent requirements.

If a requirement is genuinely ambiguous, stop and explain
the ambiguity before making a consequential architectural decision.

---

# 3. Core Technology

Frontend:
- Flutter
- Dart

Backend:
- Python
- FastAPI
- Pydantic
- DEAP

Testing:
- Flutter/Dart test framework
- Python pytest

The backend is responsible for scheduling computation.

The frontend must not contain the Genetic Algorithm.

---

# 4. Core Scheduling Problem

The scheduler receives:

- task name
- credit weight
- difficulty score
- deadline
- required study duration
- available study time slots

Scheduling granularity is exactly 15 minutes.

The scheduler must distinguish:

## Hard constraints

Hard constraints must not be violated in a feasible schedule.

- study blocks must occur within available time
- study blocks must occur before the task deadline
- two tasks cannot occupy the same time block
- required study duration must be satisfied
- schedule blocks use 15-minute granularity

## Soft objectives

Soft objectives determine the quality of feasible schedules.

- deadline urgency
- credit weight
- difficulty
- other objectives explicitly approved in GA_SPECIFICATION.md

Do not convert a hard constraint into a soft preference without approval.

---

# 5. Scheduling Algorithms

The system contains:

1. Greedy baseline scheduler
2. Genetic Algorithm scheduler

The Greedy scheduler exists primarily as an experimental baseline.

The Genetic Algorithm is the proposed optimisation method.

Do not claim that GA is globally optimal.

Do not claim GA is universally superior.

Performance must be established experimentally.

Optional:
A CP-SAT solver may be implemented under experiments/ as an offline
benchmark/reference only. It must not become a production dependency
unless explicitly approved.

---

# 6. Genetic Algorithm

The GA must follow GA_SPECIFICATION.md.

Do not change:
- chromosome representation
- fitness definition
- population size
- crossover method
- mutation method
- selection method
- repair mechanism
- termination criteria

without documenting the change in DECISIONS.md.

Initial parameters:

- population size: 100
- generations: 200
- tournament selection k=3
- crossover probability: 0.8
- mutation probability: 0.02
- single-point crossover
- mutation by random block reassignment
- repair after genetic operators
- plateau termination after 20 generations

These parameters may later be experimentally tuned.

---

# 7. Feasibility

A schedule that violates hard constraints is not considered a valid
final schedule.

The implementation should prefer producing feasible chromosomes through
construction and repair rather than relying exclusively on large penalty
values.

If no feasible schedule exists, return an explicit infeasible result.

Never fabricate a schedule by silently violating constraints.

---

# 8. API Rules

Frontend/backend communication must use JSON over REST.

The API contract is defined in API_CONTRACT.md.

Do not expose GA implementation details to the Flutter application.

The frontend asks for a schedule.
It does not decide how the schedule is generated.

---

# 9. Flutter Rules

Keep business logic outside widgets.

Use clear separation between:
- views
- view models/state
- repositories/services
- models

Do not put scheduling logic inside Flutter widgets.

Do not introduce authentication, cloud sync, social functionality,
chatbots, gamification, calendar integration, or unrelated productivity
features unless explicitly approved.

---

# 10. Testing

Every non-trivial backend algorithm component must have tests.

At minimum test:

- input validation
- time-block conversion
- feasibility constraints
- fitness calculation
- chromosome operations
- crossover
- mutation
- repair
- greedy scheduler
- GA scheduler
- API endpoints

Flutter tests must cover:

- form validation
- task creation
- schedule rendering
- schedule detail
- error states
- recalculation flow

---

# 11. Development Behaviour

Before implementing a major feature:

1. inspect relevant files
2. explain the implementation plan
3. implement
4. run tests
5. fix failures
6. inspect the resulting code
7. report changed files
8. report test results

Do not make large unrelated refactors.

Do not overwrite working functionality merely to improve style.

---

# 12. Dependency Rules

Prefer the smallest dependency set that solves the problem.

Before adding a package:

- explain why it is necessary
- check whether existing dependencies already provide the functionality
- update the appropriate dependency file
- document the decision

---

# 13. Research Integrity

Never fabricate experimental results.

Never modify results to make GA appear better.

Never report a schedule as optimal unless an appropriate solver has
actually established optimality.

Record experimental configurations and random seeds where appropriate.

---

# 14. Completion Criteria

A feature is not complete merely because the code compiles.

A feature is complete when:

- implementation exists
- tests exist where appropriate
- tests pass
- integration works
- documentation is updated
- no known requirement is silently broken

# 15UI/UX Direction

The application should be inspired by the information architecture and
general usability patterns of modern Malaysian student planner
applications such as Rencana.

Do NOT copy proprietary:
- source code
- assets
- logos
- illustrations
- exact layouts
- exact typography
- exact colour systems
- screenshots
- proprietary design elements

The application must have its own Neo-Brutalist visual identity.

UX principles:
- familiar student-planner interaction patterns
- minimal cognitive load
- schedule is the primary feature
- task creation is fast
- generated schedule is immediately understandable
- availability setup is simple
- recalculation is obvious

Visual principles:
- thick black borders
- hard offset shadows
- high contrast
- bold typography
- limited corner radius
- flat surfaces
- restrained animation
- strong accent colours

The UI should feel intentionally Neo-Brutalist rather than
simply using random bright colours.