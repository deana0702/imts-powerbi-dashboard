/* ConcreteTestHistory
   Grain: one row per FieldConcreteTestDatumBases.id
   Read-only extract.
*/
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

    NULLIF(LTRIM(RTRIM(c.placementType)), '') AS PlacementType,
    NULLIF(LTRIM(RTRIM(c.placementLocation)), '') AS PlacementLocation,
    NULLIF(LTRIM(RTRIM(c.sampledFrom)), '') AS SampledFrom,

    c.supplierId AS SupplierId,
    sp.name AS SupplierName,
    NULLIF(LTRIM(RTRIM(c.plantNumber)), '') AS PlantNumber,
    NULLIF(LTRIM(RTRIM(c.mixNumber)), '') AS MixNumber,
    c.truckNumber AS TruckNumber,
    c.ticketNumber AS TicketNumber,

    /* Verification is not the same as report approval. */
    s.workflowStateId AS SampleWorkflowStateId,
    t.workflowStateId AS TestWorkflowStateId,
    s.unapprovedReportCount AS UnapprovedReportCount,
    s.amendNumber AS AmendmentNumber,
    s.lastAmendDate AS LastAmendDate,
    s.requiresAmendment AS RequiresAmendment,
    s.fieldConcreteAllBreaksCompleted AS AllBreaksCompleted,

    /* Missing measurements remain NULL.
       AfterSP is preferred when its value exists and NA flag is false.
       Source columns allow this selection to be audited.
    */
    CASE
        WHEN c.uwSlump_afterSPNA = 0
         AND c.uwSlump_afterSP IS NOT NULL
            THEN c.uwSlump_afterSP
        WHEN c.uwSlump_actualNA = 0
            THEN c.uwSlump_actual
    END AS EffectiveSlump_in,

    CASE
        WHEN c.uwSlump_afterSPNA = 0
         AND c.uwSlump_afterSP IS NOT NULL THEN 'AfterSP'
        WHEN c.uwSlump_actualNA = 0
         AND c.uwSlump_actual IS NOT NULL THEN 'Actual'
    END AS SlumpMeasurementSource,

    CASE WHEN c.uwSlump_specMinNA = 0
         THEN c.uwSlump_specMin END AS SlumpSpecMin_in,
    CASE WHEN c.uwSlump_specMaxNA = 0
         THEN c.uwSlump_specMax END AS SlumpSpecMax_in,

    CASE
        WHEN c.uwSpread_afterSPNA = 0
         AND c.uwSpread_afterSP IS NOT NULL
            THEN c.uwSpread_afterSP
        WHEN c.uwSpread_actualNA = 0
            THEN c.uwSpread_actual
    END AS EffectiveSpread_in,

    CASE
        WHEN c.uwSpread_afterSPNA = 0
         AND c.uwSpread_afterSP IS NOT NULL THEN 'AfterSP'
        WHEN c.uwSpread_actualNA = 0
         AND c.uwSpread_actual IS NOT NULL THEN 'Actual'
    END AS SpreadMeasurementSource,

    CASE WHEN c.uwSpread_specMinNA = 0
         THEN c.uwSpread_specMin END AS SpreadSpecMin_in,
    CASE WHEN c.uwSpread_specMaxNA = 0
         THEN c.uwSpread_specMax END AS SpreadSpecMax_in,

    CASE
        WHEN c.uwAir_afterSPNA = 0
         AND c.uwAir_afterSP IS NOT NULL
            THEN c.uwAir_afterSP
        WHEN c.uwAir_actualNA = 0
            THEN c.uwAir_actual
    END AS EffectiveAir_percent,

    CASE
        WHEN c.uwAir_afterSPNA = 0
         AND c.uwAir_afterSP IS NOT NULL THEN 'AfterSP'
        WHEN c.uwAir_actualNA = 0
         AND c.uwAir_actual IS NOT NULL THEN 'Actual'
    END AS AirMeasurementSource,

    CASE WHEN c.uwAir_specMinNA = 0
         THEN c.uwAir_specMin END AS AirSpecMin_percent,
    CASE WHEN c.uwAir_specMaxNA = 0
         THEN c.uwAir_specMax END AS AirSpecMax_percent,

    CASE
        WHEN c.uwWeight_afterSPNA = 0
         AND c.uwWeight_afterSP IS NOT NULL
            THEN c.uwWeight_afterSP
        WHEN c.uwWeight_actualNA = 0
            THEN c.uwWeight_actual
    END AS EffectiveUnitWeight_lb_ft3,

    CASE
        WHEN c.uwWeight_afterSPNA = 0
         AND c.uwWeight_afterSP IS NOT NULL THEN 'AfterSP'
        WHEN c.uwWeight_actualNA = 0
         AND c.uwWeight_actual IS NOT NULL THEN 'Actual'
    END AS UnitWeightMeasurementSource,

    CASE WHEN c.uwWeight_specMinNA = 0
         THEN c.uwWeight_specMin END AS UnitWeightSpecMin_lb_ft3,
    CASE WHEN c.uwWeight_specMaxNA = 0
         THEN c.uwWeight_specMax END AS UnitWeightSpecMax_lb_ft3,

    CASE
        WHEN c.uwConcreteTemp_afterSPNA = 0
         AND c.uwConcreteTemp_afterSP IS NOT NULL
            THEN c.uwConcreteTemp_afterSP
        WHEN c.uwConcreteTemp_actualNA = 0
            THEN c.uwConcreteTemp_actual
    END AS EffectiveConcreteTemp_F,

    CASE
        WHEN c.uwConcreteTemp_afterSPNA = 0
         AND c.uwConcreteTemp_afterSP IS NOT NULL THEN 'AfterSP'
        WHEN c.uwConcreteTemp_actualNA = 0
         AND c.uwConcreteTemp_actual IS NOT NULL THEN 'Actual'
    END AS ConcreteTempMeasurementSource,

    CASE WHEN c.uwConcreteTemp_specMinNA = 0
         THEN c.uwConcreteTemp_specMin END AS ConcreteTempSpecMin_F,
    CASE WHEN c.uwConcreteTemp_specMaxNA = 0
         THEN c.uwConcreteTemp_specMax END AS ConcreteTempSpecMax_F,

    CASE WHEN c.ambientTempNA = 0
         THEN c.ambientTemp END AS AmbientTemp_F,

    c.hiTemp AS InitialCuringHighTemp_F,
    c.lowTemp AS InitialCuringLowTemp_F,
    NULLIF(LTRIM(RTRIM(c.initialCuringCondition)), '')
        AS InitialCuringCondition,

    /* Preserve original time and volume context.
       Duration and volume conversions can be added after validation.
    */
    c.batchTime AS BatchTime,
    c.sampleTime AS SampleTime,
    c.finishTime AS CastTime,

    CASE WHEN c.waterAddedNA = 0
         THEN c.waterAdded END AS WaterAddedRaw,
    CASE WHEN c.LoadBatchVolumneNA = 0
         THEN c.batchSize END AS LoadBatchVolumeRaw,
    c.loadVolumeUnits AS LoadVolumeUnits,

    /* Parent-level specification fields preserved separately.
       Do not assume these replace FieldConcreteStrengthRows.
    */
    c.specStrength AS TestSpecifiedStrengthRaw,
    c.specStrengthDays AS TestSpecifiedStrengthDaysRaw,
    c.specStrengthType AS TestSpecifiedStrengthTypeIdRaw,

    /* 28-day requirements remain available for filtering
       even when viewing 7-day specimen results.
    */
    req28.RequiredStrength28_psi,
    req28.RequiredStrength28RowCount,
    req28.RequiredStrength28DistinctValueCount,

    des28.DesignStrength28_psi,
    des28.DesignStrength28RowCount,
    des28.DesignStrength28DistinctValueCount,

    c.audit_lastUpdDt AS ConcreteTestLastUpdatedAt

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

OUTER APPLY
(
    SELECT
        CASE
            WHEN COUNT(DISTINCT cs.strength) = 1
                THEN MAX(cs.strength)
        END AS RequiredStrength28_psi,
        COUNT(*) AS RequiredStrength28RowCount,
        COUNT(DISTINCT cs.strength)
            AS RequiredStrength28DistinctValueCount
    FROM dbo.FieldConcreteStrengthRows AS cs
    WHERE cs.concreteTestId = c.id
      AND cs.days = 28
      AND cs.strengthType = 30010
) AS req28

OUTER APPLY
(
    SELECT
        CASE
            WHEN COUNT(DISTINCT cs.strength) = 1
                THEN MAX(cs.strength)
        END AS DesignStrength28_psi,
        COUNT(*) AS DesignStrength28RowCount,
        COUNT(DISTINCT cs.strength)
            AS DesignStrength28DistinctValueCount
    FROM dbo.FieldConcreteStrengthRows AS cs
    WHERE cs.concreteTestId = c.id
      AND cs.days = 28
      AND cs.strengthType = 30011
) AS des28

WHERE c.unitSystem = 0
  AND s.workflowStateId = 1000
  AND p.officeId NOT IN (1, 26, 64);