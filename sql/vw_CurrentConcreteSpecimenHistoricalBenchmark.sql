CREATE OR ALTER VIEW dbo.vw_CurrentConcreteSpecimenHistoricalBenchmark
AS

WITH CurrentTests AS
(
    SELECT DISTINCT
        i.ConcreteTestDataId,
        i.TestSubTypeId,
        i.ConcreteTestUnitSystem,
        i.RequiredStrength28_psi,
        i.EffectiveSlump_in,
        i.EffectiveAir_percent,
        i.EffectiveConcreteTemp_F

    FROM dbo.vw_CurrentConcreteBenchmarkInput AS i
),

CurrentTestAgeCuring AS
(
    SELECT DISTINCT
        i.ConcreteTestDataId,
        i.BreakAgeDays,
        i.CuringType

    FROM dbo.vw_CurrentConcreteBenchmarkInput AS i
),

MatchingHistoricalTests AS
(
    SELECT
        cur.ConcreteTestDataId
            AS CurrentConcreteTestDataId,

        hist.ConcreteTestDataId
            AS HistoricalConcreteTestDataId

    FROM CurrentTests AS cur

    INNER JOIN dbo.HistoricalConcreteTestBenchmarkBase AS hist
        ON hist.TestSubTypeId =
           cur.TestSubTypeId

        AND hist.ConcreteTestUnitSystem =
            cur.ConcreteTestUnitSystem

        AND hist.RequiredStrength28_psi =
            cur.RequiredStrength28_psi

        AND hist.ConcreteTestDataId <>
            cur.ConcreteTestDataId

        AND hist.EffectiveSlump_in
            BETWEEN cur.EffectiveSlump_in - 0.5
                AND cur.EffectiveSlump_in + 0.5

        AND hist.EffectiveAir_percent
            BETWEEN cur.EffectiveAir_percent - 0.5
                AND cur.EffectiveAir_percent + 0.5

        AND hist.EffectiveConcreteTemp_F
            BETWEEN cur.EffectiveConcreteTemp_F - 5.0
                AND cur.EffectiveConcreteTemp_F + 5.0
),

TestBenchmarks AS
(
    SELECT
        cac.ConcreteTestDataId,
        cac.BreakAgeDays,
        cac.CuringType,

        COUNT(hs.ConcreteTestDataId)
            AS ComparableCount,

        AVG(hs.TestAverageStrength_psi)
            AS HistoricalAvg_psi

    FROM CurrentTestAgeCuring AS cac

    LEFT JOIN MatchingHistoricalTests AS mh
        ON mh.CurrentConcreteTestDataId =
           cac.ConcreteTestDataId

    LEFT JOIN dbo.HistoricalConcreteStrengthSummary AS hs
        ON hs.ConcreteTestDataId =
           mh.HistoricalConcreteTestDataId

        AND hs.BreakAgeDays =
            cac.BreakAgeDays

        AND hs.CuringType =
            cac.CuringType

    GROUP BY
        cac.ConcreteTestDataId,
        cac.BreakAgeDays,
        cac.CuringType
)

SELECT
    i.SpecimenRowId,
    i.ConcreteTestDataId,
    i.OfficeId,
    i.ProjectId,
    i.BreakAgeDays,
    i.CuringType,

    b.ComparableCount,
    b.HistoricalAvg_psi

FROM dbo.vw_CurrentConcreteBenchmarkInput AS i

LEFT JOIN TestBenchmarks AS b
    ON b.ConcreteTestDataId =
       i.ConcreteTestDataId

    AND b.BreakAgeDays =
        i.BreakAgeDays

    AND b.CuringType =
        i.CuringType;
GO