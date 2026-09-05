/* ============================================================
   PMO Controls Lab — Repository 3
   Milestone 2: Core SQL Queries
   Run against the PMOControlsLab database built in Milestone 1.
   All four queries are anchored to SnapshotDate = '2026-02-28',
   the register's only current snapshot.
   ============================================================ */

USE PMOControlsLab;
GO

-- ------------------------------------------------------------
-- Query 1: RAG Rollup — portfolio health by overall status
-- Mirrors the register's own RAG Overall column, rolled up to
-- a portfolio count + budget exposure per status.
-- ------------------------------------------------------------
SELECT
    ISNULL(ps.RAGOverall, 'Not Started') AS RAGOverall,
    COUNT(*)                              AS ProjectCount,
    SUM(p.BaselineBudgetK)                AS TotalBaselineBudgetK
FROM dbo.ProjectSnapshots ps
JOIN dbo.Projects p ON p.ProjectID = ps.ProjectID
WHERE ps.SnapshotDate = '2026-02-28'
GROUP BY ISNULL(ps.RAGOverall, 'Not Started')
ORDER BY
    CASE ISNULL(ps.RAGOverall, 'Not Started')
        WHEN 'Red' THEN 1 WHEN 'Amber' THEN 2 WHEN 'Green' THEN 3 ELSE 4
    END;
GO

-- ------------------------------------------------------------
-- Query 2: SPI/CPI Outliers — started projects tracking behind
-- schedule (SPI < 1) or over cost (CPI < 1). Excludes not-started
-- projects, since their SPI/CPI are NULL by design (Milestone 1).
-- ------------------------------------------------------------
SELECT
    p.ProjectID, p.ProjectName, p.SponsorCode,
    ps.SPI, ps.CPI, ps.RAGOverall
FROM dbo.ProjectSnapshots ps
JOIN dbo.Projects p ON p.ProjectID = ps.ProjectID
WHERE ps.SnapshotDate = '2026-02-28'
  AND (ps.SPI < 1 OR ps.CPI < 1)
ORDER BY ps.SPI ASC;
GO

-- ------------------------------------------------------------
-- Query 3: EAC Variance — forecast-at-completion vs baseline
-- budget, every project, worst overrun first.
-- ------------------------------------------------------------
SELECT
    p.ProjectID, p.ProjectName,
    p.BaselineBudgetK, ps.EAC_K, ps.EACvsBudgetK, ps.EACStatus
FROM dbo.ProjectSnapshots ps
JOIN dbo.Projects p ON p.ProjectID = ps.ProjectID
WHERE ps.SnapshotDate = '2026-02-28'
ORDER BY ps.EACvsBudgetK DESC;
GO

-- ------------------------------------------------------------
-- Query 4: EAC Variance Rolled Up by Sponsor — same variance
-- measure as Query 3, aggregated to answer "which executive's
-- portfolio carries the most cost exposure right now."
-- ------------------------------------------------------------
SELECT
    s.SponsorCode, s.SponsorTitle,
    COUNT(*)                AS ProjectCount,
    SUM(p.BaselineBudgetK)  AS TotalBaselineK,
    SUM(ps.EAC_K)           AS TotalEACK,
    SUM(ps.EACvsBudgetK)    AS TotalVarianceK
FROM dbo.Projects p
JOIN dbo.Sponsors s ON s.SponsorCode = p.SponsorCode
JOIN dbo.ProjectSnapshots ps ON ps.ProjectID = p.ProjectID AND ps.SnapshotDate = '2026-02-28'
GROUP BY s.SponsorCode, s.SponsorTitle
ORDER BY TotalVarianceK DESC;
GO
