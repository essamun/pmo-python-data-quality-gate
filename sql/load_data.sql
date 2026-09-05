/* ============================================================
   PMO Controls Lab — Repository 3
   Milestone 1: Data Load
   Source of truth: PMO_Controls_Lab_RegisterV2.xlsx
   Report Date Anchor (single snapshot for this load): 2026-02-28

   This is a clean load — every value here traces directly back
   to the register with no correction or guessing. The register's
   "N/A" text for SPI/CPI/RAG on not-yet-started projects is
   loaded as SQL NULL, not the string 'N/A' — NULL is what "not
   applicable yet" means to SQL, and it keeps SPI/CPI genuinely
   numeric columns instead of silently making them text.
   ============================================================ */

USE PMOControlsLab;
GO

-- Sponsors: sourced from the register's "eXECUTIVEtITLES" reference sheet,
-- filtered to the 7 sponsor codes that actually appear in Project Register.
INSERT INTO dbo.Sponsors (SponsorCode, SponsorTitle, WhatTheyOwn, WhyPMOCares) VALUES
('CFO',  'Chief Financial Officer',  'Money — budget, forecast, actuals',            'Approves project budgets, reviews cost overruns, controls reserves'),
('CTO',  'Chief Technology Officer', 'Technology infrastructure, architecture, development', 'Owns technical resources (architects, developers). Approves tech decisions'),
('CRO',  'Chief Risk Officer',       'Risk management, compliance, regulatory',      'Owns risk registers, compliance projects (like Basel IV). Approves risk responses'),
('COO',  'Chief Operating Officer',  'Day-to-day operations',                        'Owns operational projects (like Branch Refresh). Approves operational changes'),
('CDO',  'Chief Digital Officer',    'Digital transformation, online channels',      'Owns digital projects (Mobile App). Approves customer-facing tech'),
('CHRO', 'Chief Human Resources Officer', 'People, HR systems',                      'Owns HR projects (Self-Service Portal). Approves people-related changes'),
('CPO',  'Chief Procurement Officer','Vendor contracts, procurement',                'Owns vendor management systems, contract approvals');
GO

-- Projects: time-invariant master data, all 10 rows from Project Register.
INSERT INTO dbo.Projects (ProjectID, ProjectName, DeliveryType, SponsorCode, BaselineStart, BaselineEnd, ForecastStart, ForecastEnd, ActualStart, BaselineBudgetK, ForecastCostK) VALUES
('P001', 'CRM Platform Upgrade',       'Project',    'CRO',  '2026-03-15', '2027-03-15', '2026-03-15', '2027-04-30', NULL,         850,  875),
('P002', 'Data Centre Migration',      'Project',    'CTO',  '2026-06-01', '2027-12-01', '2026-06-01', '2027-12-01', NULL,         2500, 2500),
('P003', 'Basel IV Compliance',        'Regulatory', 'CFO',  '2025-10-01', '2026-07-31', '2025-10-01', '2026-08-31', '2025-10-01', 1200, 1280),
('P004', 'HR Self-Service Portal',     'Product',    'CHRO', '2026-04-01', '2026-12-31', '2026-04-01', '2026-12-31', NULL,         420,  420),
('P005', 'Enterprise Risk Dashboard',  'Project',    'CRO',  '2025-11-01', '2026-06-30', '2025-11-01', '2026-08-31', '2025-11-01', 680,  720),
('P006', 'Branch Network Refresh',     'Change',     'COO',  '2026-09-01', '2028-08-31', '2026-09-01', '2028-08-31', NULL,         3200, 3200),
('P007', 'Mobile Banking App v3',      'Product',    'CDO',  '2026-01-15', '2027-04-30', '2026-03-01', '2027-05-13', '2026-03-01', 1100, 1150),
('P008', 'Finance Reporting Auto.',    'Project',    'CFO',  '2025-12-01', '2026-05-31', '2025-12-01', '2026-05-14', '2025-12-01', 390,  375),
('P009', 'Vendor Management System',   'Project',    'CPO',  '2026-07-01', '2027-01-31', '2026-07-01', '2027-01-31', NULL,         310,  310),
('P010', 'Cloud Infrastructure Ph.1',  'Project',    'CTO',  '2026-01-01', '2027-08-15', '2026-01-01', '2027-10-15', '2026-01-01', 1800, 1900);
GO

-- ProjectSnapshots: EVM measures as of the register's single Report Date
-- Anchor (2026-02-28). Not-yet-started projects (ActualStart NULL) load
-- their PV/EV/AC/EAC as 0 and their SPI/CPI/RAG as NULL, matching the
-- register's 'N/A' exactly rather than defaulting them to 0 or 1.
INSERT INTO dbo.ProjectSnapshots
(ProjectID, SnapshotDate, ActualCostK, PctComplete, PV_K, EV_K, AC_K, SPI, CPI, RAGSchedule, RAGCost, RAGOverall, EAC_K, EACvsBudgetK, EACStatus, EACvsForecastCostK) VALUES
('P001', '2026-02-28', 0,   0.0000, 0,      0,      0,   NULL,   NULL,   NULL,    NULL,    NULL,    850,               0,                    NULL,    -25),
('P002', '2026-02-28', 0,   0.0000, 0,      0,      0,   NULL,   NULL,   NULL,    NULL,    NULL,    2500,              0,                    NULL,    0),
('P003', '2026-02-28', 610, 0.5000, 600,    610,    610, 1.0100, 0.9836, 'Green', 'Green', 'Green', 1220,              20,                   'Amber', -60),
('P004', '2026-02-28', 0,   0.0000, 0,      0,      0,   NULL,   NULL,   NULL,    NULL,    NULL,    420,               0,                    NULL,    0),
('P005', '2026-02-28', 280, 0.3800, 258.40, 280,    280, 0.7696, 0.9229, 'Red',   'Green', 'Red',   736.84,            56.84,                'Red',   16.84),
('P006', '2026-02-28', 0,   0.0000, 0,      0,      0,   NULL,   NULL,   NULL,    NULL,    NULL,    3200,              0,                    NULL,    0),
('P007', '2026-02-28', 180, 0.2000, 220,    180,    180, 2.1364, 1.2222, 'Green', 'Green', 'Green', 900.00,            -200.00,              'Green', -250.00),
('P008', '2026-02-28', 240, 0.7200, 280.80, 240,    240, 1.4643, 1.1700, 'Green', 'Green', 'Green', 333.33,            -56.67,               'Green', -41.67),
('P009', '2026-02-28', 0,   0.0000, 0,      0,      0,   NULL,   NULL,   NULL,    NULL,    NULL,    310,               0,                    NULL,    0),
('P010', '2026-02-28', 180, 0.0800, 176.65, 144,    180, 0.8152, 0.8000, 'Amber', 'Amber', 'Amber', 2250,              450,                  'Red',   350);
GO

-- EscalationLookup: standalone governance reference from the register's
-- "lookup" sheet. Loaded as-is — the register does not link these rows
-- to specific ProjectIDs, so no FK is implied here.
INSERT INTO dbo.EscalationLookup (EscalationType, Status, EscalatedToSteerCo) VALUES
('Issue',           'Open',        'Yes'),
('Overdue Update',  'In Progress', 'No'),
('Risk',            'Resolved',    NULL),
('Decision',        NULL,          NULL);
GO

-- Quick load sanity check
SELECT (SELECT COUNT(*) FROM dbo.Sponsors)          AS SponsorRows,
       (SELECT COUNT(*) FROM dbo.Projects)          AS ProjectRows,
       (SELECT COUNT(*) FROM dbo.ProjectSnapshots)  AS SnapshotRows,
       (SELECT COUNT(*) FROM dbo.EscalationLookup)  AS EscalationRows;
GO
