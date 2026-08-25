# Genetic Algorithm Specification

## 1. Objective

Generate a feasible academic study schedule that prioritises tasks
according to deadline urgency, credit weight, and difficulty.

The GA produces an approximate solution.

It must not be described as guaranteeing global optimality.

---

# 2. Time Representation

The scheduling horizon is divided into 15-minute blocks.

Example:

08:00–08:15
08:15–08:30
08:30–08:45
...

Study duration conversion:

required_blocks = study_duration_hours × 4

Example:

2 hours = 8 blocks

---

# 3. Chromosome

A chromosome represents a complete candidate schedule.

Each gene corresponds to a scheduling time block.

Gene value:

- task ID
- or EMPTY

Example:

[TaskA, TaskA, TaskB, EMPTY, TaskC, TaskC]

---

# 4. Hard Constraints

C1 — Availability

Task blocks must be assigned only to available study periods.

C2 — Deadline

A task cannot be scheduled after its deadline.

C3 — No overlap

Each time block may contain at most one task.

C4 — Duration

Each task must receive the required number of blocks.

C5 — Granularity

Every block is exactly 15 minutes.

---

# 5. Priority

Each task has:

- deadline urgency
- credit weight
- difficulty score

These contribute to the soft objective.

---

# 6. Fitness

Fitness consists conceptually of:

Fitness =
    urgency contribution
  + credit contribution
  + difficulty contribution
  - constraint penalties

Hard constraint handling should primarily use feasibility and repair.

Fitness weights must be configurable.

Do not hard-code unexplained arbitrary weights.

---

# 7. Initial Parameters

Population size:
100

Maximum generations:
200

Selection:
Tournament selection

Tournament size:
3

Crossover:
Single-point crossover

Crossover probability:
0.8

Mutation:
Random block reassignment

Mutation probability:
0.02

Termination:
- maximum generations
OR
- no meaningful fitness improvement for 20 generations

---

# 8. Repair

Repair occurs after crossover and mutation.

Repair must attempt to:

1. remove conflicting assignments
2. move blocks outside availability
3. remove blocks after deadlines
4. satisfy task duration
5. fill missing required blocks
6. preserve valid assignments where possible

If repair cannot produce a feasible solution, the chromosome remains
infeasible and receives appropriate treatment.

---

# 9. Randomness

The GA must support a configurable random seed.

This is required for reproducible experiments.

Production mode may use a random seed.

Research experiments must record the seed.

---

# 10. Output

The scheduler returns:

- schedule blocks
- feasibility status
- fitness score
- generation count
- execution time
- optional diagnostic information

---

# 11. Parameter Tuning

Later experiments may test:

Population:
50, 100, 150, 200

Crossover:
0.7, 0.8, 0.9

Mutation:
0.01, 0.02, 0.05

The best configuration must be selected using documented experimental
evidence rather than arbitrary preference.