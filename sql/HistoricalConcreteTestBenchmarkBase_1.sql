/* ============================================================
   HistoricalConcreteTestBenchmarkBase

   Grain:
       One row per historical concrete test

   Purpose:
       Pre-calculated values used for historical matching

   Historical population:
       US units only
       Approved samples only (workflowStateId = 1000)
       Offices 1, 26, 64 excluded
   ============================================================ */

IF OBJECT_ID(
    'dbo.HistoricalConcreteTestBenchmarkBase',
    'U'
) IS NOT NULL
BEGIN
    DROP TABLE dbo.HistoricalConcreteTestBenchmarkBase;
END;
GO


SELECT
    c.id AS ConcreteTestDataId,

    t.testId AS TestId,
    s.id AS SampleId,
    s.labNo AS LabNo,

    o.officeId AS OfficeId,
    o.name AS OfficeName,

    p.projectId AS ProjectId,
    p.projectNo AS ProjectNo,
    p.name AS ProjectName,

    c.testSubTypeId AS TestSubTypeId,
    c.unitSystem AS ConcreteTestUnitSystem,

    CAST(c.castDate AS date) AS CastDate,

    /* --------------------------------------------------------
       Fields we may use now or later for comparable matching
       -------------------------------------------------------- */

    NULLIF(
        LTRIM(RTRIM(c.placementType)),
        ''
    ) AS PlacementType,

    NULLIF(
        LTRIM(RTRIM(c.placementLocation)),
        ''
    ) AS PlacementLocation,

    NULLIF(
        LTRIM(RTRIM(c.sampledFrom)),
        ''
    ) AS SampledFrom,

    c.supplierId AS SupplierId,

    sp.name AS SupplierName,

    NULLIF(
        LTRIM(RTRIM(c.plantNumber)),
        ''
    ) AS PlantNumber,

    NULLIF(
        LTRIM(RTRIM(c.mixNumber)),
        ''
    ) AS MixNumber,


    /* --------------------------------------------------------
       Effective Slump
       -------------------------------------------------------- */

    CASE
        WHEN c.uwSlump_afterSPNA = 0
             AND c.uwSlump_afterSP IS NOT NULL
            THEN c.uwSlump_afterSP

        WHEN c.uwSlump_actualNA = 0
            THEN c.uwSlump_actual
    END AS EffectiveSlump_in,


    /* --------------------------------------------------------
       Effective Air
       -------------------------------------------------------- */

    CASE
        WHEN c.uwAir_afterSPNA = 0
             AND c.uwAir_afterSP IS NOT NULL
            THEN c.uwAir_afterSP

        WHEN c.uwAir_actualNA = 0
            THEN c.uwAir_actual
    END AS EffectiveAir_percent,


    /* --------------------------------------------------------
       Effective Concrete Temperature
       -------------------------------------------------------- */

    CASE
        WHEN c.uwConcreteTemp_afterSPNA = 0
             AND c.uwConcreteTemp_afterSP IS NOT NULL
            THEN c.uwConcreteTemp_afterSP

        WHEN c.uwConcreteTemp_actualNA = 0
            THEN c.uwConcreteTemp_actual
    END AS EffectiveConcreteTemp_F,


    /* --------------------------------------------------------
       28-day Required Strength

       Important matching criterion.
       -------------------------------------------------------- */

    req28.RequiredStrength28_psi,


    /* Useful for refresh/audit */
    c.audit_lastUpdDt AS ConcreteTestLastUpdatedAt,

    GETDATE() AS BenchmarkLoadedAt


INTO dbo.HistoricalConcreteTestBenchmarkBase


FROM dbo.FieldConcreteTestDatumBases AS c

INNER JOIN dbo.Tests AS t
    ON t.testId = c.testBaseId

INNER JOIN dbo.Samples AS s
    ON s.id = t.sampleId

INNER JOIN dbo.Projects AS p
    ON p.projectId = s.projectId

INNER JOIN dbo.Offices AS o
    ON o.officeId = p.officeId

LEFT JOIN dbo.Suppliers AS sp
    ON sp.id = c.supplierId


/* ------------------------------------------------------------
   28-day Required Strength
   ------------------------------------------------------------ */

OUTER APPLY
(
    SELECT
        CASE
            WHEN COUNT(DISTINCT cs.strength) = 1
                THEN MAX(cs.strength)
        END AS RequiredStrength28_psi

    FROM dbo.FieldConcreteStrengthRows AS cs

    WHERE
        cs.concreteTestId = c.id
        AND cs.days = 28
        AND cs.strengthType = 30010

) AS req28


WHERE
    c.unitSystem = 0

    /* Historical / approved population */
    AND s.workflowStateId = 1000

    AND p.officeId NOT IN
    (
        1,
        26,
        64
    );
GO