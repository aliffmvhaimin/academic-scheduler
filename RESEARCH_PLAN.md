# Research and Evaluation Plan

## 1. Research Question

How effectively can a Genetic Algorithm generate feasible and
prioritised academic study schedules under deadline, availability,
duration, credit-weight, and difficulty constraints?

---

# 2. Baseline

Greedy priority scheduling.

The greedy scheduler should:

1. calculate task priority
2. sort tasks by priority
3. assign the earliest feasible available blocks
4. continue until task duration is satisfied or no feasible blocks remain

---

# 3. GA Comparison

Both algorithms receive exactly the same input.

Compare:

- feasibility rate
- conflict rate
- deadline violation rate
- objective score
- computation time

---

# 4. Controlled Scenarios

Create datasets representing:

### Scenario A — Low complexity
3–5 tasks
large availability

### Scenario B — Medium complexity
6–10 tasks
moderate availability

### Scenario C — High complexity
10–20 tasks
limited availability
overlapping deadlines

### Scenario D — Infeasible
Required study time exceeds available time.

---

# 5. Repeated Runs

Because GA is stochastic, each scenario should be tested with
multiple random seeds.

Record:

- seed
- runtime
- fitness
- feasibility
- generations
- violations

Do not report only the best run.

Report mean and variation where appropriate.

---

# 6. Parameter Tuning

Experiment with:

Population:
50 / 100 / 150 / 200

Crossover:
0.7 / 0.8 / 0.9

Mutation:
0.01 / 0.02 / 0.05

Use a fixed benchmark dataset.

Select the configuration based on objective score, feasibility and
runtime.

---

# 7. Optional CP-SAT Benchmark

CP-SAT may be implemented only for offline research comparison.

Purpose:

Estimate how close GA solutions are to high-quality solver solutions
on small and medium instances.

CP-SAT is not required in the production application.

---

# 8. User Acceptance Testing

Test:

- ease of task entry
- clarity of schedule
- understandability of schedule detail
- ease of recalculation
- perceived usefulness
- overall satisfaction

Use the planned questionnaire methodology.

---

# 9. Research Integrity

Do not manipulate:
- datasets
- random seeds
- results
- metrics

All reported results must be reproducible from recorded experiments.