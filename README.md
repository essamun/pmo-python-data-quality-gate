# PMO Python Data Quality Gate

**Complete SQL Server + Python data pipeline for PMO portfolio reporting.**

This repository contains all 3 milestones of the PMO Controls Lab data layer:

1. **SQL Schema + Load** — normalized 4-table database
2. **Core SQL Queries** — 4 steering-committee reports
3. **Python Data Cleaning** — quality gate before SQL load
---

## What This Pipeline Does

| Milestone | What | Why |
|-----------|------|-----|
| **1** | SQL Server schema (Sponsors, Projects, ProjectSnapshots, EscalationLookup) | Separates project-master data from point-in-time EVM measures |
| **2** | 4 reporting queries | Answers real steering-committee questions |
| **3** | Python data cleaning script | Turns messy exports into clean, audit-ready data |

---

---

## The Pipeline End-to-End

**Step 1 — Python Cleaning:** `messy_register.csv` → `clean_register.csv` + `data_quality_log.csv`

**Step 2 — SQL Load:** `clean_register.csv` → SQL Server Database (4 tables)

**Step 3 — Reporting:** SQL Queries → Portfolio Reports & Dashboards
