# Phase 11 — Iteration 1 Evaluation Report

**Project**: Academic Task Scheduling Mobile Application Using Genetic Algorithm  
**Degree**: Bachelor of Computer Science Final Year Project (FYP)  
**Evaluation Phase**: Phase 11 — Iteration 1 Evaluation  
**Status**: Completed  
**Acceptance Criterion**: Evaluation results documented  

---

## 1. Executive Summary

Phase 11 marks the formal experimental and user-centric evaluation of **Iteration 1**. Having established the complete end-to-end scheduling pipeline (Phases 1–10)—encompassing the Flutter Neo-Brutalist mobile application, the FastAPI REST services, the deterministic Greedy baseline, and the DEAP-based Genetic Algorithm (GA) engine—this evaluation assesses both:

1. **Algorithmic Performance**: Rigorous benchmark comparison of the proposed Genetic Algorithm against the deterministic Greedy priority scheduler across four controlled complexity scenarios with repeated stochastic runs.
2. **User Experience & Feasibility**: Standardized user acceptance testing (UAT) with representative university students evaluating task management, schedule comprehension, recalculation usability, and deficit diagnostics.
3. **Issue Identification & Roadmap**: Documenting observed algorithmic, architectural, and usability bottlenecks to formulate concrete development directives for **Phase 12 (Iteration 2)**.

---

## 2. Benchmark Evaluation Methodology & Results

### 2.1 Benchmark Experimental Setup

Following the experimental design in [RESEARCH_PLAN.md](file:///c:/Users/Aliff/Documents/FYP/App/academic-scheduler/RESEARCH_PLAN.md), four controlled scenario datasets were evaluated:

- **Scenario A (Low Complexity)**: 4 academic tasks (9.0h total study), 20.0h ample availability over 3 days, staggered deadlines.
- **Scenario B (Medium Complexity)**: 8 academic tasks (18.0h total study), 30.0h moderate availability over 5 days, tight staggered deadlines.
- **Scenario C (High Complexity)**: 15 academic tasks (22.5h total study), 32.0h constrained availability over 4 days, overlapping tight deadlines.
- **Scenario D (Infeasible Horizon)**: 1 academic task requiring 16.0h study duration within a horizon offering only 6.0h total availability (mandatory deficit detection per FR10).

Both algorithms received identical inputs under reproducible configurations:
- **Greedy Scheduler**: Deterministic sorting by composite priority score ($P = 0.4 \cdot U + 0.35 \cdot C + 0.25 \cdot D$), assigning earliest feasible available 15-minute blocks.
- **Genetic Algorithm**: Population size $N = 50$, maximum generations $G = 50$, single-point crossover ($P_c = 0.8$), random gene reassignment mutation ($P_m = 0.02$), tournament selection ($k = 3$), constraint-repair chromosome construction, and plateau termination after 20 static generations.
- **Repeated Runs**: 5 independent runs per scenario with fixed seeds: `[42, 101, 2024, 777, 9999]`.

### 2.2 Quantitative Benchmark Results Table

| Scenario | Algorithm | Feasibility Rate | Fitness Score (Mean ± SD) | Runtime (Mean ± SD) | Generations (Mean ± SD) | Constraint Violations |
|---|---|:---:|:---:|:---:|:---:|:---:|
| **Scenario A**<br>(Low Complexity) | **Greedy Baseline** | **100.0%** (1/1) | 0.3349 | **0.0 ms** | 1 (single-pass) | Conflicts: 0<br>Overdue: 0 |
| | **Genetic Algorithm** | **100.0%** (5/5) | **35.2361 ± 0.0000** | 60.2 ± 4.4 ms | 20.0 ± 0.0 | Conflicts: 0<br>Overdue: 0 |
| **Scenario B**<br>(Medium Complexity) | **Greedy Baseline** | **0.0%** (0/1) | N/A (Failed) | 0.0 ms | 1 (single-pass) | Unscheduled: 8 tasks |
| | **Genetic Algorithm** | **100.0%** (5/5) | **37.0733 ± 0.0113** | 236.8 ± 31.4 ms | 46.0 ± 5.7 | Conflicts: 0<br>Overdue: 0 |
| **Scenario C**<br>(High Complexity) | **Greedy Baseline** | **0.0%** (0/1) | N/A (Failed) | 0.0 ms | 1 (single-pass) | Unscheduled: 15 tasks |
| | **Genetic Algorithm** | **100.0%** (5/5) | **34.0929 ± 0.0209** | 360.8 ± 7.8 ms | 50.0 ± 0.0 | Conflicts: 0<br>Overdue: 0 |
| **Scenario D**<br>(Infeasible Horizon) | **Greedy Baseline** | **0.0%** (0/1) | N/A (Infeasible) | 0.0 ms | 1 (pre-check) | Deficit: 10.0 hours |
| | **Genetic Algorithm** | **0.0%** (0/5) | N/A (Infeasible) | 0.0 ± 0.0 ms | 0.0 ± 0.0 (pre-check) | Deficit: 10.0 hours |

### 2.3 Algorithmic Findings & Analysis

1. **Fitness Optimization Superiority (Scenario A)**:
   - While both Greedy and GA successfully produced feasible schedules in Scenario A, the GA's soft objective score (**35.2361**) dramatically exceeded Greedy's score (**0.3349**). Greedy simply packs tasks into the earliest chronological slots, failing to strategically distribute study time closer to peak urgency or balance high-difficulty blocks. GA dynamically organized chromosome blocks to maximize credit and urgency alignment.
2. **Greedy Horizon Collapse (Scenarios B and C)**:
   - In both medium (8 tasks) and high (15 tasks) complexity scenarios, **Greedy failed completely (0% feasibility)**. Because the greedy heuristic makes locally irrevocable assignments based solely on instantaneous priority, early tasks exhaust front-loaded availability slots. Later tasks with impending deadlines are left with no valid slots before their deadlines, violating hard constraint C2 and leaving the problem unsolved.
   - Conversely, the Genetic Algorithm achieved **100% feasibility across all seeds**. By maintaining a diverse population of candidate schedules and applying crossover and chromosome repair, GA explores non-local slot assignments, interleaving study blocks to satisfy all deadlines simultaneously.
3. **Sub-Second Computational Efficiency**:
   - GA execution times ranged between **58 ms** (Scenario A) and **360 ms** (Scenario C). For mobile scheduling applications, sub-second latency ensures an interactive, seamless user experience without requiring background batch job spinners.
4. **Zero Constraint Violations**:
   - Across all feasible GA schedules (15 total runs across Scenarios A, B, and C), conflict rate was **0.0%** (0 overlapping blocks), deadline violation rate was **0.0%** (all blocks completed prior to task deadlines), and duration satisfaction was **100.0%** (each task received exactly its required blocks).

---

## 3. Initial User Acceptance Testing (UAT) Summary

User testing was conducted with a cohort of 6 undergraduate students (P1–P6) across multiple faculties using task-based usability protocols and a 5-point Likert questionnaire. Detailed individual scoring and verbatim transcripts are documented in [user_testing_iteration_1.md](file:///c:/Users/Aliff/Documents/FYP/App/academic-scheduler/docs/testing/user_testing_iteration_1.md).

### 3.1 Usability Dimension Scores

| Evaluation Dimension | Mean Score (1–5) | Standard Deviation | Qualitative Interpretation |
|---|:---:|:---:|---|
| **Ease of Task Entry** | **4.67** | ± 0.52 | Very High: Quick duration adjustment chips and clear field constraints facilitated rapid workload setup. |
| **Clarity of Schedule Timeline** | **4.50** | ± 0.55 | Very High: Aggregating 15-minute blocks into daily session cards provided high clarity without clutter. |
| **Understandability of Schedule Detail** | **4.33** | ± 0.52 | High: Urgency badges and deadline metrics were intuitive; priority contribution was understood after inspection. |
| **Ease of Recalculation** | **4.50** | ± 0.55 | Very High: Floating action button and app bar recalculate options were prominent and responsive. |
| **Perceived Usefulness** | **4.83** | ± 0.41 | Exceptional: Highest scoring dimension; students strongly endorsed algorithmic study planning over manual calendars. |
| **Overall Satisfaction** | **4.67** | ± 0.52 | Very High: Neo-Brutalist styling was praised for high contrast, clean typography, and purposeful appearance. |

---

## 4. Documented Issues & Limitations

Based on benchmark profiling and user feedback, the following concrete issues were documented:

### 4.1 Algorithmic Issues
- **Issue A1 — Fixed Generation Cap in High Complexity**:
  - In Scenario C (15 tasks), GA reached the 50-generation cap on all seeds before plateau convergence. While all schedules were feasible, soft objective fitness was still climbing marginally in the final generations ($34.07 \to 34.11$), indicating that complex instances benefit from a higher generation budget (e.g. 100–150 generations) or tuned operator probabilities.
- **Issue A2 — Plateau Premature Termination Risk**:
  - In certain seeded runs, the plateau early stopping criteria (static fitness over 20 generations) risked stopping before escaping local soft-objective basins. A dynamic stagnation threshold scaled to problem size is recommended.
- **Issue A3 — Greedy Heuristic Inability to Backtrack**:
  - The deterministic baseline lacks backtracking; when an early assignment causes a future task to fail, it aborts rather than attempting constraint propagation. (Documented as an experimental baseline limitation confirming ADR-005).

### 4.2 Usability & Functional Issues
- **Issue U1 — Missed Study Block Handling**:
  - Currently, when a student misses a scheduled study session (e.g., due to an unforeseen lecture or personal delay), there is no visual indicator or toggle to mark a specific 15-minute block as "missed". The system recalculates all uncompleted tasks, but cannot specifically shift only the missed portion to subsequent available slots.
- **Issue U2 — Actionable Guidance on Infeasible State**:
  - When the scheduler reports a deficit (FR10), the student is shown the shortfall in hours (e.g., "Shortfall: 8 hours"). However, the interface does not yet provide one-tap remedy actions (such as "Extend Friday evening by 2 hours" or "Reduce duration of lowest credit task").
- **Issue U3 — Interactive Task Completion Status**:
  - Completed task IDs can be sent to the recalculation endpoint, but the Flutter UI does not yet feature an interactive check-off action directly from the timeline cards to mark tasks done during study sessions.
- **Issue U4 — Large Task List Scrolling & Search**:
  - As task count exceeded 10 in Scenario C, scrolling through unorganized task items without search or deadline sorting created minor visual friction.

---

## 5. Identified Required Changes & Phase 12 Roadmap

The documented issues map directly into the prioritized deliverables for **Phase 12 — Iteration 2**:

| Phase 12 Requirement | Source Issue | Target Solution |
|---|---|---|
| **1. Dynamic Recalculation** | Issue U1, Issue U3 | Implement reactive schedule recalculation triggered by state changes: task additions, task edits, or availability modifications. |
| **2. Missed Study Block Handling** | Issue U1 | Add interactive status toggles on timeline study blocks (`completed`, `missed`, `pending`) and pass `missed_blocks` to `/api/v1/schedule/recalculate`. |
| **3. New Task Recalculation** | Issue U3 | Automatically preserve past completed study blocks while scheduling newly added tasks into remaining available horizon slots. |
| **4. GA Parameter Tuning** | Issue A1, Issue A2 | Conduct experimental parameter tuning grid search over population sizes (50, 100, 150), crossover rates (0.7, 0.8, 0.9), and mutation rates (0.01, 0.02, 0.05). |
| **5. UI Refinement** | Issue U2, Issue U4 | Add one-tap action suggestions to the Infeasible deficit view; add search/filter bar to the task list view; add completion checkboxes to timeline cards. |
| **6. Performance Improvements** | Issue A1 | Optimize chromosome evaluation loops in Python backend for larger task counts; refine stagnation check logic. |

---

## 6. Acceptance Criteria Verification

- **Acceptance Requirement**: *Evaluation results documented*
- **Verification**:
  - Full benchmark test results across Scenarios A, B, C, and D with 5 stochastic seeds documented and saved in [benchmark_results.json](file:///c:/Users/Aliff/Documents/FYP/App/academic-scheduler/experiments/results/benchmark_results.json) and [benchmark_summary.md](file:///c:/Users/Aliff/Documents/FYP/App/academic-scheduler/experiments/results/benchmark_summary.md).
  - Automated integration test suite implemented and passing in [test_benchmarks.py](file:///c:/Users/Aliff/Documents/FYP/App/academic-scheduler/backend/tests/integration/test_benchmarks.py).
  - Initial user acceptance testing protocol, 6-dimension Likert matrix, and qualitative feedback documented in [user_testing_iteration_1.md](file:///c:/Users/Aliff/Documents/FYP/App/academic-scheduler/docs/testing/user_testing_iteration_1.md).
  - Concrete issues, algorithmic limitations, and required changes mapped to Phase 12 development plan.

**Phase 11 Acceptance Criteria: FULLY MET.**
