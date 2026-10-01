/* One row per historical test */
CREATE UNIQUE CLUSTERED INDEX
    IX_HistoricalConcreteTestBenchmarkBase_Id
ON dbo.HistoricalConcreteTestBenchmarkBase
(
    ConcreteTestDataId
);
GO


/* Main historical matching index */
CREATE NONCLUSTERED INDEX
    IX_HistoricalConcreteTestBenchmarkBase_Matching
ON dbo.HistoricalConcreteTestBenchmarkBase
(
    TestSubTypeId,
    ConcreteTestUnitSystem,
    RequiredStrength28_psi,
    EffectiveSlump_in,
    EffectiveAir_percent,
    EffectiveConcreteTemp_F
)
INCLUDE
(
    SupplierId,
    PlantNumber,
    MixNumber,
    PlacementType,
    PlacementLocation
);
GO