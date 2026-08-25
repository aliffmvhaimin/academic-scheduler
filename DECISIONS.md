# Architecture and Technical Decisions

## ADR-001 — Flutter

Decision:
Use Flutter for the mobile frontend.

Reason:
Cross-platform development and consistency with the project scope.

---

## ADR-002 — FastAPI

Decision:
Use FastAPI for the REST backend.

Reason:
Clear API contracts, validation, automatic OpenAPI documentation,
and straightforward Python integration.

---

## ADR-003 — DEAP

Decision:
Use DEAP for the Genetic Algorithm.

Reason:
Python evolutionary-computation framework suitable for implementing
the specified GA operations.

---

## ADR-004 — GA as Core Research Algorithm

Decision:
Use GA as the proposed optimisation method.

Reason:
The research evaluates GA-based academic task scheduling.

Important:
This does not imply GA is universally optimal.

---

## ADR-005 — Greedy Baseline

Decision:
Implement greedy priority scheduling.

Reason:
Provides a simple deterministic baseline for evaluating whether GA
provides meaningful improvement.

---

## ADR-006 — CP-SAT

Decision:
CP-SAT is optional and research-only.

Reason:
Can provide a strong reference for small/medium benchmark instances
without unnecessarily increasing production application complexity.

---

## ADR-007 — 15-Minute Blocks

Decision:
Use fixed 15-minute scheduling granularity.

Reason:
Defined by project requirements and simplifies scheduling representation.

---

## ADR-008 — Local Persistence

Decision:
Persist active task data locally.

Reason:
The project does not require cloud accounts or behavioural analytics.

---

## ADR-009 — No Feature Creep

Decision:
Do not implement broad productivity features.

Reason:
The research contribution is academic scheduling optimisation.