/* ============================================================
   PMO Controls Lab — Repository 3
   Milestone 1: Schema Design + Load
   Target: SQL Server 2014+

   Design intent (read this before the CREATE statements):

   1. dbo.Sponsors is split out from Projects because a sponsor
      (CRO, CFO, CTO...) is a stable attribute of the org chart,
      not of any one project. Normalizing it once means portfolio
      health can be rolled up "by sponsor" with a join instead of
      a GROUP BY on a free-text string that could be mistyped
      differently on every project row.

   2. dbo.Projects holds only what is true about a project
      regardless of when you ask: its ID, name, delivery type,
      sponsor, and baseline/forecast dates and budget. Nothing
      here changes week to week.

   3. dbo.ProjectSnapshots is deliberately separate from Projects.
      SPI, CPI, RAG status, EAC — these are all measured AS OF a
      report date, not permanent facts about the project. Today
      the register only has one snapshot (2026-02-28), so this
      looks like overkill for 10 rows. It isn't: the moment this
      register gets refreshed monthly, storing EVM data on the
      Projects table would mean overwriting history every month.
      This structure means "show me P005's SPI trend over the
      last 6 months" is a query, not a redesign.

   4. dbo.EscalationLookup is a small governance reference table
      lifted from the register's "lookup" sheet (escalation type,
      status, whether it goes to SteerCo). It is NOT joined to
      Projects in this milestone — the register doesn't currently
      link escalations to specific projects — it is loaded as-is
      as a standalone governance reference, flagged honestly as
      such rather than force-joined to invent a relationship that
      isn't in the source data.

   What was deliberately NOT built: a DeliveryTypes lookup table
   for the four delivery type values (Project/Regulatory/Product/
   Change). Four low-cardinality values with no attributes of
   their own don't earn a table — a CHECK constraint keeps the
   values controlled without an unnecessary join. Over-normalizing
   a 10-row demo dataset is its own tell.
   ============================================================ */

IF DB_ID(N'PMOControlsLab') IS NULL
BEGIN
    CREATE DATABASE PMOControlsLab;
END
GO

USE PMOControlsLab;
GO

IF OBJECT_ID(N'dbo.ProjectSnapshots', N'U') IS NOT NULL DROP TABLE dbo.ProjectSnapshots;
IF OBJECT_ID(N'dbo.Projects', N'U') IS NOT NULL DROP TABLE dbo.Projects;
IF OBJECT_ID(N'dbo.Sponsors', N'U') IS NOT NULL DROP TABLE dbo.Sponsors;
IF OBJECT_ID(N'dbo.EscalationLookup', N'U') IS NOT NULL DROP TABLE dbo.EscalationLookup;
GO

CREATE TABLE dbo.Sponsors (
    SponsorCode      VARCHAR(10)   NOT NULL PRIMARY KEY,
    SponsorTitle     VARCHAR(60)   NOT NULL,
    WhatTheyOwn      VARCHAR(200)  NOT NULL,
    WhyPMOCares      VARCHAR(300)  NOT NULL
);
GO

CREATE TABLE dbo.Projects (
    ProjectID          CHAR(4)        NOT NULL PRIMARY KEY,
    ProjectName        VARCHAR(100)   NOT NULL,
    DeliveryType       VARCHAR(20)    NOT NULL
        CONSTRAINT CK_Projects_DeliveryType
        CHECK (DeliveryType IN ('Project','Regulatory','Product','Change')),
    SponsorCode        VARCHAR(10)    NOT NULL
        CONSTRAINT FK_Projects_Sponsors REFERENCES dbo.Sponsors(SponsorCode),
    BaselineStart      DATE           NOT NULL,
    BaselineEnd        DATE           NOT NULL,
    ForecastStart      DATE           NOT NULL,
    ForecastEnd        DATE           NOT NULL,
    ActualStart        DATE           NULL,       -- NULL = not yet started
    BaselineBudgetK    DECIMAL(10,2)  NOT NULL,
    ForecastCostK      DECIMAL(10,2)  NOT NULL,
    CONSTRAINT CK_Projects_ForecastAfterBaselineStart CHECK (ForecastEnd >= ForecastStart)
);
GO

CREATE TABLE dbo.ProjectSnapshots (
    SnapshotID         INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ProjectID          CHAR(4)        NOT NULL
        CONSTRAINT FK_Snapshots_Projects REFERENCES dbo.Projects(ProjectID),
    SnapshotDate       DATE           NOT NULL,
    ActualCostK        DECIMAL(10,2)  NOT NULL,
    PctComplete        DECIMAL(5,4)   NOT NULL,
    PV_K               DECIMAL(10,2)  NOT NULL,
    EV_K               DECIMAL(10,2)  NOT NULL,
    AC_K               DECIMAL(10,2)  NOT NULL,
    SPI                DECIMAL(6,4)   NULL,        -- NULL where not yet started (register shows N/A)
    CPI                DECIMAL(6,4)   NULL,
    RAGSchedule        VARCHAR(10)    NULL,
    RAGCost            VARCHAR(10)    NULL,
    RAGOverall         VARCHAR(10)    NULL,
    EAC_K              DECIMAL(10,2)  NOT NULL,
    EACvsBudgetK       DECIMAL(10,2)  NOT NULL,
    EACStatus          VARCHAR(10)    NULL,
    EACvsForecastCostK DECIMAL(10,2)  NULL,
    CONSTRAINT UQ_Snapshots_ProjectDate UNIQUE (ProjectID, SnapshotDate)
);
GO

CREATE TABLE dbo.EscalationLookup (
    EscalationType       VARCHAR(30) NOT NULL PRIMARY KEY,
    Status               VARCHAR(20) NULL,
    EscalatedToSteerCo   VARCHAR(5)  NULL
);
GO
