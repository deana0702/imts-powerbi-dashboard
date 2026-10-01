/*
  CurrentConcreteSpecimenStatus - initial operational view
  Grain: one row per dbo.FieldConcreteTestRows.id, assuming source join keys
  are unique as in the supplied historical extract.
  Run in the intended IMTS database using SSMS. SQL Server 2016 SP1+ / Azure SQL.
  Creates/updates a view only; does not update test records.
  Not executed against IMTS or performance-tested by the author.

  Scope: US units only; preserves exclusions for offices 1, 26, 64.
  No Verified-only filter, date cutoff, or result-present filter.
  This view has no per-user authorization: configure RLS/read-only access.
  Uses only source columns shown in the supplied Test and Specimen extracts.
  Yellow UI values may be calculated AND persisted; retain supplied calc* fields.
  Uses the stored calculated strength; correction factor is not recalculated.

  ScheduledTestDate = CAST(c.castDate AS date) + r.daysToAge (confirmed).
  Age 0 means Hold; scheduled date remains NULL. Negative/missing ages and
  invalid/overflowing dates also return NULL. Hours are outside this prototype.
  Scheduling classification is separate from result-entry status.
  Do not infer physical completion from missing strength alone.
  Zero strength is preserved as recorded; it may be a legacy default.
  ResultEntryStatus describes recorded fields, not physical break completion.
  Required and Design values are separate. No fallback across ages or types.
  Row counts include NULL strengths; distinct counts count non-NULL values.
  A single distinct value plus NULL rows retains that value, as in the original.

  Tests without any specimen rows cannot appear in this specimen-grain view.
  Use a separate test-grain source for total project tests and report counts.
  The companion test view supplies test-level context and fresh measurements.
  Power BI relationship: test.ConcreteTestDataId (1) -> specimen (many),
  single-direction filtering. Use Office/Project slicers from the test view.
  Sample report counts and AllBreaksCompleted are sample-scoped: do not sum
  repeated values over tests or specimens. Configure permissions separately.
*/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
/* Test grain: includes tests with no specimen rows. All workflow states. */
CREATE OR ALTER VIEW dbo.vw_CurrentConcreteTestStatus
AS
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
    s.workflowStateId AS SampleWorkflowStateId,
    t.workflowStateId AS TestWorkflowStateId,
    s.unapprovedReportCount AS UnapprovedReportCount,
    s.amendNumber AS AmendmentNumber,
    s.lastAmendDate AS LastAmendDate,
    s.requiresAmendment AS RequiresAmendment,
    s.fieldConcreteAllBreaksCompleted AS AllBreaksCompleted,
    CASE WHEN c.uwSlump_afterSPNA = 0 AND c.uwSlump_afterSP IS NOT NULL
             THEN c.uwSlump_afterSP
         WHEN c.uwSlump_actualNA = 0 THEN c.uwSlump_actual
    END AS EffectiveSlump_in,
    CASE WHEN c.uwSlump_afterSPNA = 0 AND c.uwSlump_afterSP IS NOT NULL
             THEN 'AfterSP'
         WHEN c.uwSlump_actualNA = 0 AND c.uwSlump_actual IS NOT NULL
             THEN 'Actual' END AS SlumpMeasurementSource,
    CASE WHEN c.uwSlump_specMinNA = 0 THEN c.uwSlump_specMin
    END AS SlumpSpecMin_in,
    CASE WHEN c.uwSlump_specMaxNA = 0 THEN c.uwSlump_specMax
    END AS SlumpSpecMax_in,
    CASE WHEN c.uwSpread_afterSPNA = 0 AND c.uwSpread_afterSP IS NOT NULL
             THEN c.uwSpread_afterSP
         WHEN c.uwSpread_actualNA = 0 THEN c.uwSpread_actual
    END AS EffectiveSpread_in,
    CASE WHEN c.uwSpread_afterSPNA = 0 AND c.uwSpread_afterSP IS NOT NULL
             THEN 'AfterSP'
         WHEN c.uwSpread_actualNA = 0 AND c.uwSpread_actual IS NOT NULL
             THEN 'Actual' END AS SpreadMeasurementSource,
    CASE WHEN c.uwSpread_specMinNA = 0 THEN c.uwSpread_specMin
    END AS SpreadSpecMin_in,
    CASE WHEN c.uwSpread_specMaxNA = 0 THEN c.uwSpread_specMax
    END AS SpreadSpecMax_in,
    CASE WHEN c.uwAir_afterSPNA = 0 AND c.uwAir_afterSP IS NOT NULL
             THEN c.uwAir_afterSP
         WHEN c.uwAir_actualNA = 0 THEN c.uwAir_actual
    END AS EffectiveAir_percent,
    CASE WHEN c.uwAir_afterSPNA = 0 AND c.uwAir_afterSP IS NOT NULL
             THEN 'AfterSP'
         WHEN c.uwAir_actualNA = 0 AND c.uwAir_actual IS NOT NULL
             THEN 'Actual' END AS AirMeasurementSource,
    CASE WHEN c.uwAir_specMinNA = 0 THEN c.uwAir_specMin
    END AS AirSpecMin_percent,
    CASE WHEN c.uwAir_specMaxNA = 0 THEN c.uwAir_specMax
    END AS AirSpecMax_percent,
    CASE WHEN c.uwWeight_afterSPNA = 0 AND c.uwWeight_afterSP IS NOT NULL
             THEN c.uwWeight_afterSP
         WHEN c.uwWeight_actualNA = 0 THEN c.uwWeight_actual
    END AS EffectiveUnitWeight_lb_ft3,
    CASE WHEN c.uwWeight_afterSPNA = 0 AND c.uwWeight_afterSP IS NOT NULL
             THEN 'AfterSP'
         WHEN c.uwWeight_actualNA = 0 AND c.uwWeight_actual IS NOT NULL
             THEN 'Actual' END AS UnitWeightMeasurementSource,
    CASE WHEN c.uwWeight_specMinNA = 0 THEN c.uwWeight_specMin
    END AS UnitWeightSpecMin_lb_ft3,
    CASE WHEN c.uwWeight_specMaxNA = 0 THEN c.uwWeight_specMax
    END AS UnitWeightSpecMax_lb_ft3,
    CASE WHEN c.uwConcreteTemp_afterSPNA = 0 AND c.uwConcreteTemp_afterSP IS NOT NULL
             THEN c.uwConcreteTemp_afterSP
         WHEN c.uwConcreteTemp_actualNA = 0 THEN c.uwConcreteTemp_actual
    END AS EffectiveConcreteTemp_F,
    CASE WHEN c.uwConcreteTemp_afterSPNA = 0 AND c.uwConcreteTemp_afterSP IS NOT NULL
             THEN 'AfterSP'
         WHEN c.uwConcreteTemp_actualNA = 0 AND c.uwConcreteTemp_actual IS NOT NULL
             THEN 'Actual' END AS ConcreteTempMeasurementSource,
    CASE WHEN c.uwConcreteTemp_specMinNA = 0 THEN c.uwConcreteTemp_specMin
    END AS ConcreteTempSpecMin_F,
    CASE WHEN c.uwConcreteTemp_specMaxNA = 0 THEN c.uwConcreteTemp_specMax
    END AS ConcreteTempSpecMax_F,
    CASE WHEN c.ambientTempNA = 0 THEN c.ambientTemp END AS AmbientTemp_F,
    c.hiTemp AS InitialCuringHighTemp_F,
    c.lowTemp AS InitialCuringLowTemp_F,
    NULLIF(LTRIM(RTRIM(c.initialCuringCondition)), '') AS InitialCuringCondition,
    c.batchTime AS BatchTime,
    c.sampleTime AS SampleTime,
    c.finishTime AS CastTime,
    CASE WHEN c.waterAddedNA = 0 THEN c.waterAdded END AS WaterAddedRaw,
    CASE WHEN c.LoadBatchVolumneNA = 0 THEN c.batchSize END AS LoadBatchVolumeRaw,
    c.loadVolumeUnits AS LoadVolumeUnits,
    c.specStrength AS TestSpecifiedStrengthRaw,
    c.specStrengthDays AS TestSpecifiedStrengthDaysRaw,
    c.specStrengthType AS TestSpecifiedStrengthTypeIdRaw,
    req28.RequiredStrength28_psi,
    req28.RequiredStrength28RowCount,
    req28.RequiredStrength28DistinctValueCount,
    des28.DesignStrength28_psi,
    des28.DesignStrength28RowCount,
    des28.DesignStrength28DistinctValueCount,
    c.audit_lastUpdDt AS ConcreteTestLastUpdatedAt
FROM dbo.FieldConcreteTestDatumBases AS c
INNER JOIN dbo.Tests AS t ON t.testId = c.testBaseId
INNER JOIN dbo.Samples AS s ON s.id = t.sampleId
INNER JOIN dbo.Projects AS p ON p.projectId = s.projectId
INNER JOIN dbo.Offices AS o ON o.officeId = p.officeId
LEFT JOIN dbo.Suppliers AS sp ON sp.id = c.supplierId
OUTER APPLY
(
    SELECT CASE WHEN COUNT(DISTINCT cs.strength) = 1 THEN MAX(cs.strength) END
               AS RequiredStrength28_psi,
           COUNT(*) AS RequiredStrength28RowCount,
           COUNT(DISTINCT cs.strength) AS RequiredStrength28DistinctValueCount
    FROM dbo.FieldConcreteStrengthRows AS cs
    WHERE cs.concreteTestId = c.id AND cs.days = 28 AND cs.strengthType = 30010
) AS req28
OUTER APPLY
(
    SELECT CASE WHEN COUNT(DISTINCT cs.strength) = 1 THEN MAX(cs.strength) END
               AS DesignStrength28_psi,
           COUNT(*) AS DesignStrength28RowCount,
           COUNT(DISTINCT cs.strength) AS DesignStrength28DistinctValueCount
    FROM dbo.FieldConcreteStrengthRows AS cs
    WHERE cs.concreteTestId = c.id AND cs.days = 28 AND cs.strengthType = 30011
) AS des28
WHERE c.unitSystem = 0
  AND p.officeId NOT IN (1, 26, 64);
GO

CREATE OR ALTER VIEW dbo.vw_CurrentConcreteSpecimenStatus
AS
SELECT
    o.officeId AS OfficeId,
    o.name AS OfficeName,
    p.projectId AS ProjectId,
    p.projectNo AS ProjectNo,
    p.name AS ProjectName,
    r.id AS SpecimenRowId,
    r.specimenId AS SpecimenLabel,
    c.id AS ConcreteTestDataId,
    t.testId AS TestId,
    s.id AS SampleId,
    s.labNo AS LabNo,
    c.testSubTypeId AS TestSubTypeId,
    c.unitSystem AS ConcreteTestUnitSystem,
    c.castDate AS CastDateRaw,
    d.CastDate,
    r.daysToAge AS BreakAgeDays,
    /* Confirmed day-based schedule: zero days means Hold. */
    CASE WHEN r.daysToAge = 0 THEN 1
         WHEN r.daysToAge > 0 THEN 0 END AS IsHoldByDays,
    CASE WHEN r.daysToAge = 0 THEN 'Hold'
         WHEN d.AgeDays > 0 AND r.daysToAge = d.AgeDays
             THEN 'Day-based age'
         ELSE 'Age needs review' END AS AgeScheduleCategory,
    /* daysToAge is int; guard missing/invalid dates and DATEADD overflow. */
    DATEADD(DAY,
        CASE
            WHEN d.CastDate IS NOT NULL
             AND d.AgeDays > 0
             AND r.daysToAge = d.AgeDays
             AND d.AgeDays <= DATEDIFF(DAY, d.CastDate,
                                       CONVERT(date, '99991231', 112))
            THEN d.AgeDays
        END,
        d.CastDate) AS ScheduledTestDate,
    r.receiveDate AS ReceivedAt,
    r.testedOnDate AS TestedAt,
    CASE WHEN r.testedOnDate IS NOT NULL THEN 1 ELSE 0 END
        AS HasRecordedTestedDate,
    r.wasFieldCured AS WasFieldCured,
    CASE r.wasFieldCured
        WHEN 0 THEN 'Standard'
        WHEN 1 THEN 'Field'
        ELSE 'Unknown'
    END AS CuringType,
    NULLIF(LTRIM(RTRIM(r.curingLocation)), '') AS CuringLocation,
    r.testLoad AS TestLoadRaw,
    r.widthDiameter AS WidthOrDiameterRaw,
    r.heightLength AS HeightOrLengthRaw,
    r.calcArea AS CalculatedAreaRaw,
    r.calcCompressiveStrength AS CompressiveStrengthRounded_psi,
    r.calcCompressiveStrengthUnrounded AS CompressiveStrengthUnrounded_psi,
    a.ActualCompressiveStrength_psi,
    CASE WHEN a.ActualCompressiveStrength_psi IS NOT NULL THEN 1 ELSE 0 END
        AS HasCompressiveStrengthResult,
    CASE WHEN a.ActualCompressiveStrength_psi = 0 THEN 1 ELSE 0 END
        AS HasRecordedZeroStrength,
    CASE
        WHEN a.ActualCompressiveStrength_psi IS NOT NULL
            THEN 'Strength recorded'
        WHEN r.testedOnDate IS NOT NULL
            THEN 'Tested date recorded; strength missing'
        ELSE 'No strength or tested date recorded'
    END AS ResultEntryStatus,

    req.RequiredStrengthAtAge_psi,
    req.RequiredStrengthAtAgeRowCount,
    req.RequiredStrengthAtAgeDistinctValueCount,
    des.DesignStrengthAtAge_psi,
    des.DesignStrengthAtAgeRowCount,
    des.DesignStrengthAtAgeDistinctValueCount,
    /* For comparable-history matching, including 3-day / 7-day rows.
       Never substitute this value for RequiredStrengthAtAge_psi. */
    req28.RequiredStrength28_psi,
    req28.RequiredStrength28RowCount,
    req28.RequiredStrength28DistinctValueCount,
    r.resFractureType AS FractureTypeId,
    r.resCapType AS CapTypeId,
    r.technicianId AS TechnicianId,
    r.equipmentName AS EquipmentName,
    s.workflowStateId AS SampleWorkflowStateId,
    t.workflowStateId AS TestWorkflowStateId,
    s.amendNumber AS AmendmentNumber,
    r.audit_lastUpdDt AS SpecimenLastUpdatedAt
FROM dbo.FieldConcreteTestRows AS r
INNER JOIN dbo.FieldConcreteTestDatumBases AS c ON c.id = r.concreteTestId
INNER JOIN dbo.Tests AS t ON t.testId = c.testBaseId
INNER JOIN dbo.Samples AS s ON s.id = t.sampleId
INNER JOIN dbo.Projects AS p ON p.projectId = s.projectId
INNER JOIN dbo.Offices AS o ON o.officeId = p.officeId
CROSS APPLY
(
    SELECT TRY_CONVERT(date, c.castDate) AS CastDate,
           TRY_CONVERT(int, r.daysToAge) AS AgeDays
) AS d
CROSS APPLY
(
    SELECT COALESCE(r.calcCompressiveStrengthUnrounded,
                    r.calcCompressiveStrength) AS ActualCompressiveStrength_psi
) AS a
OUTER APPLY
(
    SELECT CASE WHEN COUNT(DISTINCT cs.strength) = 1 THEN MAX(cs.strength) END
               AS RequiredStrengthAtAge_psi,
           COUNT(*) AS RequiredStrengthAtAgeRowCount,
           COUNT(DISTINCT cs.strength) AS RequiredStrengthAtAgeDistinctValueCount
    FROM dbo.FieldConcreteStrengthRows AS cs
    WHERE cs.concreteTestId = c.id
      AND cs.days = r.daysToAge
      AND r.daysToAge > 0 -- Hold has no age-specific break requirement
      AND cs.strengthType = 30010
) AS req
OUTER APPLY
(
    SELECT CASE WHEN COUNT(DISTINCT cs.strength) = 1 THEN MAX(cs.strength) END
               AS DesignStrengthAtAge_psi,
           COUNT(*) AS DesignStrengthAtAgeRowCount,
           COUNT(DISTINCT cs.strength) AS DesignStrengthAtAgeDistinctValueCount
    FROM dbo.FieldConcreteStrengthRows AS cs
    WHERE cs.concreteTestId = c.id
      AND cs.days = r.daysToAge
      AND r.daysToAge > 0 -- Hold has no age-specific break requirement
      AND cs.strengthType = 30011
) AS des
OUTER APPLY
(
    SELECT CASE WHEN COUNT(DISTINCT cs.strength) = 1 THEN MAX(cs.strength) END
               AS RequiredStrength28_psi,
           COUNT(*) AS RequiredStrength28RowCount,
           COUNT(DISTINCT cs.strength) AS RequiredStrength28DistinctValueCount
    FROM dbo.FieldConcreteStrengthRows AS cs
    WHERE cs.concreteTestId = c.id
      AND cs.days = 28
      AND cs.strengthType = 30010
) AS req28
WHERE c.unitSystem = 0
  AND p.officeId NOT IN (1, 26, 64);
GO

/* Read-only verification: replace the two IDs with one known project.
DECLARE @OfficeId int = 2;
DECLARE @ProjectId int = 4407;

SELECT TOP (100) *
FROM dbo.vw_CurrentConcreteSpecimenStatus
WHERE OfficeId = @OfficeId AND ProjectId = @ProjectId
ORDER BY CastDate DESC, ConcreteTestDataId, BreakAgeDays, SpecimenRowId;

-- Expected: no rows. Investigate joins if any specimen is duplicated.
SELECT SpecimenRowId, COUNT(*) AS RowCount
FROM dbo.vw_CurrentConcreteSpecimenStatus
WHERE OfficeId = @OfficeId AND ProjectId = @ProjectId
GROUP BY SpecimenRowId
HAVING COUNT(*) > 1;

-- Compare one known unbroken and one known broken specimen with IMTS.
SELECT SampleWorkflowStateId, ResultEntryStatus, COUNT(*) AS SpecimenCount
FROM dbo.vw_CurrentConcreteSpecimenStatus
WHERE OfficeId = @OfficeId AND ProjectId = @ProjectId
GROUP BY SampleWorkflowStateId, ResultEntryStatus;
*/

/* Read-only verification.
-- Test-grain uniqueness: expected no rows.
SELECT ConcreteTestDataId, COUNT(*) AS RowCount
FROM dbo.vw_CurrentConcreteTestStatus
GROUP BY ConcreteTestDataId
HAVING COUNT(*) > 1;
*/
