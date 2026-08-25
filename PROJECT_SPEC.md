# Project Specification

## Project

Academic Task Scheduling Mobile Application Using Genetic Algorithm

## Purpose

Develop a mobile application that generates personalised academic
study schedules from student-defined tasks and available study periods.

The system focuses on constraint-aware academic scheduling.

---

# 1. Users

Primary user:

University student managing multiple academic tasks.

---

# 2. Task Inputs

Each academic task contains:

| Field | Type | Range/Rule |
|---|---|---|
| Task name | String | Required |
| Credit weight | Integer | 1–6 |
| Difficulty score | Integer | 1–10 |
| Deadline | DateTime | Required |
| Study duration | Float | Positive |
| Available time | Time ranges | User-defined |

Scheduling granularity:

15 minutes.

---

# 3. Functional Requirements

## FR1 — Create Task

User can create an academic task.

## FR2 — Edit Task

User can modify an existing task.

## FR3 — Delete Task

User can remove a task.

## FR4 — Configure Availability

User can define available study periods.

## FR5 — Generate Schedule

User can request a generated study schedule.

## FR6 — View Schedule

User can view the generated schedule chronologically.

## FR7 — View Schedule Detail

User can inspect details of a scheduled study block.

## FR8 — Recalculate Schedule

The system can regenerate the schedule when:
- a task is added
- a task changes
- a study block is missed
- availability changes

## FR9 — Persist Active Tasks

The active task list is stored locally on the device.

## FR10 — Handle Infeasible Problems

If no feasible schedule exists, the system must communicate this
clearly to the user.

---

# 4. Hard Constraints

1. A study block must occur within a student's available time.
2. A study block must occur before the task deadline.
3. A time block cannot contain multiple tasks.
4. A task must receive its required study duration.
5. All blocks are exactly 15 minutes.

---

# 5. Soft Objectives

Schedule quality should consider:

1. deadline urgency
2. credit weight
3. difficulty

The exact mathematical fitness definition is specified in
GA_SPECIFICATION.md.

---

# 6. Screens

The application contains:

1. Task Input
2. Schedule View
3. Schedule Detail
4. Settings

---

# 7. Out of Scope

Do not implement unless explicitly approved:

- user authentication
- cloud accounts
- social networking
- chat
- AI chatbot
- flashcards
- quizzes
- note-taking
- payment
- advertising
- Google Calendar integration
- wearable integration
- behavioural analytics

---

# 8. Platform

Target:
- Android 10 / API 29+
- iOS 15+

---

# 9. Privacy

The project does not require collection of behavioural or performance
analytics.

Active task data is stored locally for convenience.