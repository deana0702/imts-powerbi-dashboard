CREATE OR ALTER VIEW dbo.vw_CurrentConcreteBenchmarkInput
AS

WITH RequiredStrength28 AS
(
    SELECT
        cs.concreteTestId AS ConcreteTestDataId,

        CASE
            WHEN COUNT(DISTINCT cs.strength) = 1
                THEN MAX(cs.strength)
        END AS RequiredStrength28_psi

    FROM dbo.FieldConcreteStrengthRows AS cs

    WHERE
        cs.days = 28
        AND cs.strengthType = 30010

    GROUP BY
        cs.concreteTestId
)

SELECT
    /* Current specimen */
    r.id AS SpecimenRowId,

    /* Current concrete test */
    c.id AS ConcreteTestDataId,

    /* Useful for Project filtering */
    p.officeId AS OfficeId,
    p.projectId AS ProjectId,

    /* Historical matching keys */
    c.testSubTypeId AS TestSubTypeId,
    c.unitSystem AS ConcreteTestUnitSystem,

    req.RequiredStrength28_psi,

    /* Current specimen age */
    r.daysToAge AS BreakAgeDays,

    /* Current specimen curing */
    CASE
        WHEN r.wasFieldCured = 0 THEN 'Standard'
        WHEN r.wasFieldCured = 1 THEN 'Field'
        ELSE 'Unknown'
    END AS CuringType,

    /* Current Test Slump */
    CASE
        WHEN c.uwSlump_afterSPNA = 0
             AND c.uwSlump_afterSP IS NOT NULL
            THEN c.uwSlump_afterSP

        WHEN c.uwSlump_actualNA = 0
            THEN c.uwSlump_actual
    END AS EffectiveSlump_in,

    /* Current Test Air */
    CASE
        WHEN c.uwAir_afterSPNA = 0
             AND c.uwAir_afterSP IS NOT NULL
            THEN c.uwAir_afterSP

        WHEN c.uwAir_actualNA = 0
            THEN c.uwAir_actual
    END AS EffectiveAir_percent,

    /* Current Test Temperature */
    CASE
        WHEN c.uwConcreteTemp_afterSPNA = 0
             AND c.uwConcreteTemp_afterSP IS NOT NULL
            THEN c.uwConcreteTemp_afterSP

        WHEN c.uwConcreteTemp_actualNA = 0
            THEN c.uwConcreteTemp_actual
    END AS EffectiveConcreteTemp_F

FROM dbo.FieldConcreteTestRows AS r

INNER JOIN dbo.FieldConcreteTestDatumBases AS c
    ON c.id = r.concreteTestId

INNER JOIN dbo.Tests AS t
    ON t.testId = c.testBaseId

INNER JOIN dbo.Samples AS s
    ON s.id = t.sampleId

INNER JOIN dbo.Projects AS p
    ON p.projectId = s.projectId

LEFT JOIN RequiredStrength28 AS req
    ON req.ConcreteTestDataId = c.id

WHERE
    c.unitSystem = 0

    AND p.officeId NOT IN
    (
        1,
        26,
        64
    )

    /* Hold / invalid age is not historical strength comparison */
    AND r.daysToAge > 0

    /* Benchmark requires these values */
    AND req.RequiredStrength28_psi IS NOT NULL

    AND
    CASE
        WHEN c.uwSlump_afterSPNA = 0
             AND c.uwSlump_afterSP IS NOT NULL
            THEN c.uwSlump_afterSP

        WHEN c.uwSlump_actualNA = 0
            THEN c.uwSlump_actual
    END IS NOT NULL

    AND
    CASE
        WHEN c.uwAir_afterSPNA = 0
             AND c.uwAir_afterSP IS NOT NULL
            THEN c.uwAir_afterSP

        WHEN c.uwAir_actualNA = 0
            THEN c.uwAir_actual
    END IS NOT NULL

    AND
    CASE
        WHEN c.uwConcreteTemp_afterSPNA = 0
             AND c.uwConcreteTemp_afterSP IS NOT NULL
            THEN c.uwConcreteTemp_afterSP

        WHEN c.uwConcreteTemp_actualNA = 0
            THEN c.uwConcreteTemp_actual
    END IS NOT NULL;
GO