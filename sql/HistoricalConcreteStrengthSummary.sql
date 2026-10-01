/* ============================================================
   HistoricalConcreteStrengthSummary

   Grain:
       ConcreteTestDataId
       + BreakAgeDays
       + CuringType

   Example:

       Test 100
       28 Day
       Standard
       specimen strengths:
           4100
           4200
           4300

       TestAverageStrength_psi = 4200
   ============================================================ */


IF OBJECT_ID(
    'dbo.HistoricalConcreteStrengthSummary',
    'U'
) IS NOT NULL
BEGIN
    DROP TABLE dbo.HistoricalConcreteStrengthSummary;
END;
GO


SELECT
    r.concreteTestId
        AS ConcreteTestDataId,

    r.daysToAge
        AS BreakAgeDays,

    CASE
        WHEN r.wasFieldCured = 0
            THEN 'Standard'

        WHEN r.wasFieldCured = 1
            THEN 'Field'

        ELSE 'Unknown'
    END AS CuringType,


    AVG
    (
        CAST
        (
            COALESCE
            (
                r.calcCompressiveStrengthUnrounded,
                r.calcCompressiveStrength
            )
            AS float
        )
    ) AS TestAverageStrength_psi,


    /* Optional but useful information */
    COUNT(*) AS SpecimenCount,

    GETDATE() AS BenchmarkLoadedAt


INTO dbo.HistoricalConcreteStrengthSummary


FROM dbo.FieldConcreteTestRows AS r

INNER JOIN dbo.FieldConcreteTestDatumBases AS c
    ON c.id = r.concreteTestId

INNER JOIN dbo.Tests AS t
    ON t.testId = c.testBaseId

INNER JOIN dbo.Samples AS s
    ON s.id = t.sampleId

INNER JOIN dbo.Projects AS p
    ON p.projectId = s.projectId


WHERE
    c.unitSystem = 0

    AND s.workflowStateId = 1000

    AND p.officeId NOT IN
    (
        1,
        26,
        64
    )

    /* Hold specimens are not benchmark strength results */
    AND r.daysToAge > 0

    /* Actual strength must exist */
    AND COALESCE
    (
        r.calcCompressiveStrengthUnrounded,
        r.calcCompressiveStrength
    ) IS NOT NULL


GROUP BY

    r.concreteTestId,

    r.daysToAge,

    CASE
        WHEN r.wasFieldCured = 0
            THEN 'Standard'

        WHEN r.wasFieldCured = 1
            THEN 'Field'

        ELSE 'Unknown'
    END;
GO

CREATE UNIQUE CLUSTERED INDEX
    IX_HistoricalConcreteStrengthSummary_Key
ON dbo.HistoricalConcreteStrengthSummary
(
    ConcreteTestDataId,
    BreakAgeDays,
    CuringType
);
GO