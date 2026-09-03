"""
PMO Controls Lab — Repository 3
Milestone 3: Python Data Cleaning Script

Purpose: this is the quality gate that would sit BEFORE data reaches the
SQL Server tables built in Milestone 1. It reads a deliberately messy
export (messy_register.csv — the kind of file a manual weekly export
process actually produces) and writes a clean CSV shaped to match
dbo.ProjectSnapshots, plus a data-quality log of every value that was
fixed, flagged, or dropped and why.

Deliberately NOT built here: a config-driven pipeline framework, a
logging library, a class hierarchy, or a CLI with argument parsing.
This is a single readable script because the messiness in front of it
is real but small — four issue types, eleven rows. Reaching for
pipeline architecture on a dataset this size would be solving a
problem that doesn't exist yet, which is the same restraint this repo
has applied at every milestone so far.
"""

import pandas as pd
from datetime import datetime

INPUT_FILE = "messy_register.csv"
OUTPUT_CLEAN_FILE = "clean_register.csv"
OUTPUT_LOG_FILE = "data_quality_log.csv"

VALID_RAG = {"Red", "Amber", "Green"}

# The register export writes dates in whichever format the person doing
# the export happened to use that week. These are the five formats
# actually observed in messy_register.csv, tried in order.
DATE_FORMATS = ["%Y-%m-%d", "%m/%d/%Y", "%d-%b-%Y", "%b %d, %Y", "%Y/%m/%d"]

issues = []  # each entry: (row_index, ProjectID, field, original_value, resolution)


def log_issue(row_idx, project_id, field, original, resolution):
    issues.append({
        "row": row_idx, "ProjectID": project_id, "field": field,
        "original_value": original, "resolution": resolution,
    })


def clean_rag(value, row_idx, project_id):
    """Blank is legitimate (not-yet-started project) — not an issue.
    Anything present must match the controlled vocabulary exactly once
    normalized for case and whitespace; anything that doesn't is a real
    data quality problem and gets flagged, not guessed at."""
    if pd.isna(value) or str(value).strip() == "":
        return None
    cleaned = str(value).strip().title()
    if cleaned not in VALID_RAG:
        log_issue(row_idx, project_id, "RAGOverall", value,
                   f"INVALID VALUE — not in {VALID_RAG}, set to NULL, needs manual review")
        return None
    if cleaned != str(value):
        log_issue(row_idx, project_id, "RAGOverall", value, f"normalized to '{cleaned}'")
    return cleaned


def clean_currency(value, row_idx, project_id, field_name):
    """Strips $ signs, commas, and whitespace. Blank stays blank here —
    whether that blank is legitimate is decided later, once we know
    whether the project has actually started (see the cross-check below)."""
    if pd.isna(value) or str(value).strip() == "":
        return None
    raw = str(value)
    cleaned_str = raw.replace("$", "").replace(",", "").strip()
    try:
        cleaned = float(cleaned_str)
    except ValueError:
        log_issue(row_idx, project_id, field_name, value, "UNPARSEABLE NUMBER — set to NULL, needs manual review")
        return None
    if cleaned_str != raw.strip() or raw != raw.strip() or "$" in raw or "," in raw:
        log_issue(row_idx, project_id, field_name, value, f"normalized to {cleaned}")
    return cleaned


def clean_ratio(value, row_idx, project_id, field_name):
    """SPI/CPI: blank is legitimate for not-started projects. A negative
    ratio is not a formatting problem — it's a value that shouldn't
    exist, so it's flagged rather than silently accepted."""
    if pd.isna(value) or str(value).strip() == "":
        return None
    try:
        cleaned = float(str(value).strip())
    except ValueError:
        log_issue(row_idx, project_id, field_name, value, "UNPARSEABLE NUMBER — set to NULL, needs manual review")
        return None
    if cleaned < 0:
        log_issue(row_idx, project_id, field_name, value, "NEGATIVE RATIO — set to NULL, needs manual review")
        return None
    return cleaned


def clean_date(value, row_idx, project_id):
    raw = str(value).strip()
    for fmt in DATE_FORMATS:
        try:
            parsed = datetime.strptime(raw, fmt).date()
            if fmt != "%Y-%m-%d":
                log_issue(row_idx, project_id, "SnapshotDate", value, f"parsed as {fmt}, normalized to {parsed.isoformat()}")
            return parsed.isoformat()
        except ValueError:
            continue
    log_issue(row_idx, project_id, "SnapshotDate", value, "UNPARSEABLE DATE — set to NULL, needs manual review")
    return None


def main():
    df = pd.read_csv(INPUT_FILE, dtype=str, keep_default_na=False)

    # Duplicates: same ProjectID reported twice for what should be the
    # same snapshot. Keep the first occurrence, but LOG the drop instead
    # of silently discarding it — a duplicate row is evidence of an
    # upstream export problem, not just noise to remove quietly.
    dup_mask = df.duplicated(subset=["ProjectID"], keep="first")
    for idx in df[dup_mask].index:
        log_issue(idx, df.loc[idx, "ProjectID"], "ProjectID", df.loc[idx, "ProjectID"],
                   "DUPLICATE ROW — dropped, kept first occurrence, needs manual review of which is authoritative")
    df = df[~dup_mask].reset_index(drop=True)

    cleaned_rows = []
    for idx, row in df.iterrows():
        pid = row["ProjectID"]
        rag = clean_rag(row["RAGOverall"], idx, pid)
        actual_cost = clean_currency(row["ActualCostK"], idx, pid, "ActualCostK")
        spi = clean_ratio(row["SPI"], idx, pid, "SPI")
        cpi = clean_ratio(row["CPI"], idx, pid, "CPI")
        snap_date = clean_date(row["SnapshotDate"], idx, pid)

        # Cross-field check: this is the one rule that can't be applied
        # field-by-field. A blank ActualCostK is fine for a project that
        # hasn't started (SPI/CPI also blank) — but a blank ActualCostK
        # on a project that DOES have SPI/CPI values is a real gap, not
        # a legitimate "not started yet" blank.
        started = spi is not None or cpi is not None
        if started and actual_cost is None:
            log_issue(idx, pid, "ActualCostK", row["ActualCostK"],
                       "MISSING ON A STARTED PROJECT — set to NULL, needs manual follow-up before load")

        cleaned_rows.append({
            "ProjectID": pid,
            "ProjectName": row["ProjectName"],
            "SponsorCode": row["SponsorCode"],
            "RAGOverall": rag,
            "ActualCostK": actual_cost,
            "SPI": spi,
            "CPI": cpi,
            "SnapshotDate": snap_date,
        })

    clean_df = pd.DataFrame(cleaned_rows)
    clean_df.to_csv(OUTPUT_CLEAN_FILE, index=False)

    log_df = pd.DataFrame(issues)
    log_df.to_csv(OUTPUT_LOG_FILE, index=False)

    print(f"Rows read from {INPUT_FILE}: {len(pd.read_csv(INPUT_FILE, dtype=str))}")
    print(f"Duplicate rows dropped: {dup_mask.sum()}")
    print(f"Rows written to {OUTPUT_CLEAN_FILE}: {len(clean_df)}")
    print(f"Issues logged to {OUTPUT_LOG_FILE}: {len(issues)}")
    needs_review = [i for i in issues if "needs manual" in i["resolution"] or "review" in i["resolution"]]
    print(f"Issues requiring manual review before load: {len(needs_review)}")


if __name__ == "__main__":
    main()
