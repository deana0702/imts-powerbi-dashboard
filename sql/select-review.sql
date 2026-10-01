SELECT
    h.ConcreteTestDataId,
    h.OfficeId,
    h.OfficeName,
    h.ProjectId,
    h.ProjectNo,

    h.TestSubTypeId,
    h.ConcreteTestUnitSystem,

    h.RequiredStrength28_psi,
    h.EffectiveSlump_in,
    h.EffectiveAir_percent,
    h.EffectiveConcreteTemp_F,

    s.BreakAgeDays,
    s.CuringType,
    s.TestAverageStrength_psi,
    s.SpecimenCount

FROM dbo.HistoricalConcreteTestBenchmarkBase AS h

INNER JOIN dbo.HistoricalConcreteStrengthSummary AS s
    ON s.ConcreteTestDataId = h.ConcreteTestDataId

WHERE
    h.TestSubTypeId = 30050
    AND h.ConcreteTestUnitSystem = 0

    AND h.RequiredStrength28_psi = 3000

    AND h.EffectiveSlump_in
        BETWEEN 4.0 - 0.5 AND 4.0 + 0.5

    AND h.EffectiveAir_percent
        BETWEEN 5.5 - 0.5 AND 5.5 + 0.5

    AND h.EffectiveConcreteTemp_F
        BETWEEN 69 - 5.0 AND 69 + 5.0

    AND s.BreakAgeDays = 7
    AND s.CuringType = 'Standard'

ORDER BY
    h.ConcreteTestDataId;