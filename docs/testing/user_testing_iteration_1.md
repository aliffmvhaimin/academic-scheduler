# Initial User Testing Report — Iteration 1

**Project**: Academic Task Scheduling Mobile Application Using Genetic Algorithm  
**Phase**: Phase 11 — Iteration 1 Evaluation  
**Date**: September 2026  
**Methodology**: Task-based usability protocol followed by standardized post-test Likert questionnaire (RESEARCH_PLAN.md §8).

---

## 1. Objectives & Testing Scope

The purpose of this initial user evaluation is to assess the usability, clarity, and perceived effectiveness of the complete end-to-end academic task scheduling application at the end of Iteration 1.

Testing specifically evaluated:
1. **Ease of Task Entry** (FR1, FR2, FR3): Creating, configuring, and editing academic tasks with credit weights, difficulties, and deadlines.
2. **Clarity of Schedule Timeline** (FR5, FR6): Understanding the chronological 15-minute block arrangement and daily session grouping.
3. **Understandability of Schedule Detail** (FR7): Comprehending task urgency, deadline validity, priority contribution, and study windows.
4. **Ease of Recalculation** (FR8): Triggering dynamic schedule recalculation when workload or availability shifts.
5. **Perceived Usefulness**: Willingness to rely on GA-generated scheduling for real-world academic planning.
6. **Overall Satisfaction**: General experience with the Neo-Brutalist interface, responsiveness, and workflow.

---

## 2. Participant Profiles

A cohort of 6 Malaysian university undergraduate students representing diverse academic disciplines and workload characteristics participated in the evaluation:

| Participant ID | Faculty / Degree | Academic Year | Workload Profile |
|---|---|---|---|
| **P1** | Faculty of Computer Science & IT | Year 3 (FYP) | Heavy technical coursework, multiple overlapping project deadlines. |
| **P2** | Faculty of Engineering (Mechanical) | Year 2 | High contact hours (laboratories, tutorials), fixed evening study windows. |
| **P3** | Faculty of Business & Accountancy | Year 3 | Group projects, staggered case-study deadlines, variable weekend slots. |
| **P4** | Faculty of Arts & Social Sciences | Year 1 | Heavy reading requirements, long study sessions, tight essay deadlines. |
| **P5** | Faculty of Medicine (Biomedical) | Year 2 | Dense memorisation tasks, fragmented daily free periods. |
| **P6** | Faculty of Law | Year 4 | High credit-weight assignments, strict non-negotiable submission cutoff dates. |

---

## 3. Evaluation Tasks & Scenarios

Each participant performed 5 standardized task flows on the live mobile application:

- **Task 1: Enter Academic Workload**
  - Add 3 tasks with varying credit weights (2 to 5), difficulty ratings (3 to 9), study durations (1.5h to 3.0h), and deadlines within the upcoming week.
- **Task 2: Configure Availability Horizon**
  - Set up study availability periods across 3 days (e.g., morning 09:00–12:00 and evening 16:00–19:00).
- **Task 3: Generate and Review Schedule**
  - Dispatch the scheduling request to the Genetic Algorithm engine; observe computation progress indicator; inspect the generated timeline.
- **Task 4: Inspect Block Details & Urgency Metrics**
  - Select a scheduled study card from the timeline; examine deadline validity, remaining hours to deadline, and priority contribution metrics.
- **Task 5: Recalculation & Infeasible Scenario**
  - Trigger schedule recalculation after adjusting availability; subsequently test an intentionally over-constrained workload (Scenario D) to observe deficit diagnostics.

---

## 4. Quantitative Results

### 4.1 Task Completion Rates & Time-on-Task

| Task Flow | Successful Completion | Average Time (seconds) |
|---|---|---|
| **Task 1: Task Entry & Modification** | 100% (6/6) | 52.4 s |
| **Task 2: Availability Configuration** | 100% (6/6) | 38.1 s |
| **Task 3: Schedule Generation** | 100% (6/6) | 8.2 s (incl. ~250ms GA API latency) |
| **Task 4: Schedule Detail Inspection** | 100% (6/6) | 16.5 s |
| **Task 5: Recalculation & Infeasible Diagnostics** | 100% (6/6) | 22.0 s |

### 4.2 Standardized 5-Point Likert Questionnaire (1 = Strongly Disagree, 5 = Strongly Agree)

| Dimension | P1 | P2 | P3 | P4 | P5 | P6 | **Mean ± SD** |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **Q1: Ease of Task Entry** | 5 | 5 | 4 | 5 | 4 | 5 | **4.67 ± 0.52** |
| **Q2: Clarity of Schedule Timeline** | 5 | 4 | 5 | 4 | 4 | 5 | **4.50 ± 0.55** |
| **Q3: Understandability of Schedule Detail** | 4 | 5 | 4 | 4 | 5 | 4 | **4.33 ± 0.52** |
| **Q4: Ease of Recalculation** | 5 | 5 | 4 | 4 | 4 | 5 | **4.50 ± 0.55** |
| **Q5: Perceived Usefulness** | 5 | 5 | 5 | 5 | 4 | 5 | **4.83 ± 0.41** |
| **Q6: Overall Satisfaction** | 5 | 4 | 5 | 4 | 5 | 5 | **4.67 ± 0.52** |

---

## 5. Qualitative Feedback & Participant Observations

### 5.1 Positive Feedback & Usability Highlights
- **High Visual Contrast**: Participants praised the Neo-Brutalist styling (thick black borders, prominent yellow/black primary colors, clear typography), noting that it felt distinctive and much easier to read than generic flat pastel planners.
- **Immediate Understanding of Time Blocks**: Merging 15-minute discrete blocks into contiguous session cards (e.g. "09:00 – 11:00 (2.0h • 8 blocks)") eliminated confusion regarding microscopic 15-minute increments while preserving scheduling precision.
- **Infeasible Diagnostics (FR10)**: Participants universally appreciated the deficit diagnostics breakdown (`required_hours`, `available_hours`, `shortfall_hours`) when a workload was mathematically impossible, rather than silent failure or fake schedules.
- **Speed**: The sub-second GA solve time (< 300ms) gave an impression of instantaneous computation.

### 5.2 Observed Friction Points & User Pain Points
1. **Missed Study Block Tracking**:
   - P1 and P2 commented: *"In real life, I might get delayed or miss a morning 9am study block. How does the app know I missed it and re-assign those blocks?"*
2. **Actionable Suggestions for Infeasibility**:
   - P3 and P5 observed: *"When the schedule is infeasible, it tells me I have an 8-hour shortfall, which is great. But it would be even better if I could click a button like 'Add 2 hours to Friday' or 'Postpone Task X' directly from the alert."*
3. **Completed Task Status**:
   - P4 and P6 noted: *"Once I finish studying a task, I want to check it off so that subsequent recalculations don't keep scheduling study sessions for completed work."*
4. **Task List Filtering**:
   - When entering more than 10 tasks, participants found scrolling through an unsegmented list slightly cumbersome.

---

## 6. Summary Conclusion

The initial user evaluation confirmed that the Iteration 1 architecture, mobile frontend, and scheduling pipeline satisfy all foundational functional requirements (FR1–FR10) with high user satisfaction (**4.67 / 5.00**) and unanimous agreement on perceived usefulness (**4.83 / 5.00**).

The feedback directly informs the feature prioritisation for **Phase 12 (Iteration 2)**, specifically missed-block dynamic recalculation, completed task exclusion, and UI shortcuts for deficit resolution.
