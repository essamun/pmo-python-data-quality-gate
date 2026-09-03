# PMO Python Data Quality Gate

This script is the data quality gate that sits between messy weekly project register exports and SQL Server load. It takes a deliberately messy CSV (11 rows with inconsistent RAG casing, currency symbols, 5 different date formats, a duplicate ProjectID, and a blank cost on a started project) and produces a clean CSV ready for the database, plus an audit log of every change made.

The script handles four specific data quality problems: RAG status normalization (green → Green, RED → Red, AMBER → Amber) with invalid values like "Redd" flagged for human review rather than auto-corrected; currency cleaning that strips $ signs, commas, and whitespace (converting $610 to 610.0); multi-format date parsing using an explicit list of 5 formats rather than pandas inference to avoid silently misreading ambiguous dates like 02/03/2026; and duplicate handling that drops the second P005 row but logs it rather than discarding it silently.

The single most important judgment call in this script is the cross-field check that distinguishes a legitimate blank cost (a not-started project like P001 where SPI and CPI are also blank) from a real data gap (a started project like P010 where SPI is 0.8152 and CPI is 0.8, but ActualCostK is missing). That distinction can't be made by looking at one column alone — it requires looking across SPI, CPI, and ActualCostK together.

The script outputs clean_register.csv with 10 rows (1 duplicate dropped) and data_quality_log.csv with 12 issues logged — 10 are formatting fixes applied automatically, and 2 require manual review (the P005 duplicate and P010 missing cost). The 5-line execution summary confirms: 11 rows read, 1 duplicate dropped, 10 clean rows written, 12 issues logged, 2 requiring manual review.

This repository sits within a larger PMO Controls Lab portfolio that includes SQL Server schema design (normalized sponsors, projects, and project snapshots tables), data load scripts, and upcoming SQL analytics for portfolio health dashboards. The entire pipeline demonstrates how a PMO Analyst can take raw weekly exports, clean them consistently, log every decision, and produce audit-ready data for steering committee reporting.

Skills demonstrated: Python/pandas for data cleaning, data quality validation with controlled vocabularies, cross-field anomaly detection, ETL pre-processing patterns, audit logging, PMO domain knowledge (RAG status, EVM metrics like SPI/CPI), and judgment about which data problems need automation versus human review. The restraint shown here — no config files, no logging frameworks, no class hierarchies — is intentional, matching the tool to the problem rather than over-engineering a 10-row dataset.

## Screenshots

Terminal output showing the 5-line execution summary:
![Terminal Output](screenshots/terminal_output.png)

Side-by-side comparison showing transformations: RAG (green → Green, RED → Red, AMBER → Amber), currency ($610 → 610.0,   180   → 180.0), and dates normalized to YYYY-MM-DD:
![Clean vs Messy](screenshots/clean_vs_messy.png)

Data quality log showing 12 issues, with the 2 manual review rows highlighted (P005 duplicate and P010 missing cost):
![Data Quality Log](screenshots/data_quality_log.png)