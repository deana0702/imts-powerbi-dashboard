/* ConcreteSpecimenHistory
   Grain: one row per FieldConcreteTestRows.id
   Read-only extract.
*/
SELECT
    r.id AS SpecimenRowId,
    r.specimenId AS SpecimenLabel,
    c.id AS ConcreteTestDataId,
    t.testId AS TestId,
    s.id AS SampleId,
    s.labNo AS LabNo,

    c.testSubTypeId AS TestSubTypeId,
    c.unitSystem AS ConcreteTestUnitSystem,

    CAST(c.castDate AS date) AS CastDate,
    r.daysToAge AS BreakAgeDays,
    r.receiveDate AS ReceivedAt,
    r.testedOnDate AS TestedAt,

    r.wasFieldCured AS WasFieldCured,
    CASE
        WHEN r.wasFieldCured = 0 THEN 'Standard'
        WHEN r.wasFieldCured = 1 THEN 'Field'
        ELSE 'Unknown'
    END AS CuringType,

    NULLIF(LTRIM(RTRIM(r.curingLocation)), '') AS CuringLocation,

    /* Preserve missing versus recorded zero. */
    r.testLoad AS TestLoadRaw,
    r.widthDiameter AS WidthOrDiameterRaw,
    r.heightLength AS HeightOrLengthRaw,
    r.calcArea AS CalculatedAreaRaw,

    r.calcCompressiveStrength AS CompressiveStrengthRounded_psi,
    r.calcCompressiveStrengthUnrounded
        AS CompressiveStrengthUnrounded_psi,

    COALESCE
    (
        r.calcCompressiveStrengthUnrounded,
        r.calcCompressiveStrength
    ) AS ActualCompressiveStrength_psi,

    CASE
        WHEN COALESCE
        (
            r.calcCompressiveStrengthUnrounded,
            r.calcCompressiveStrength
        ) IS NOT NULL
            THEN 1
        ELSE 0
    END AS HasCompressiveStrengthResult,

    /* Specification for this specimen's recorded age.
       No 28-day fallback for 7-day or other ages.
       Required and Design are not interchangeable.
    */
    req.RequiredStrengthAtAge_psi,
    req.RequiredStrengthAtAgeRowCount,
    req.RequiredStrengthAtAgeDistinctValueCount,

    des.DesignStrengthAtAge_psi,
    des.DesignStrengthAtAgeRowCount,
    des.DesignStrengthAtAgeDistinctValueCount,

    r.resFractureType AS FractureTypeId,
    r.resCapType AS CapTypeId,
    r.technicianId AS TechnicianId,
    r.equipmentName AS EquipmentName,

    s.workflowStateId AS SampleWorkflowStateId,
    s.amendNumber AS AmendmentNumber,
    r.audit_lastUpdDt AS SpecimenLastUpdatedAt

FROM dbo.FieldConcreteTestRows AS r
INNER JOIN dbo.FieldConcreteTestDatumBases AS c
    ON c.id = r.concreteTestId
INNER JOIN dbo.Tests AS t
    ON t.testId = c.testBaseId
INNER JOIN dbo.Samples AS s
    ON s.id = t.sampleId
INNER JOIN dbo.Projects AS p
    ON p.projectId = s.projectId
INNER JOIN dbo.Offices AS o
    ON o.officeId = p.officeId

OUTER APPLY
(
    SELECT
        CASE
            WHEN COUNT(DISTINCT cs.strength) = 1
                THEN MAX(cs.strength)
        END AS RequiredStrengthAtAge_psi,
        COUNT(*) AS RequiredStrengthAtAgeRowCount,
        COUNT(DISTINCT cs.strength)
            AS RequiredStrengthAtAgeDistinctValueCount
    FROM dbo.FieldConcreteStrengthRows AS cs
    WHERE cs.concreteTestId = c.id
      AND cs.days = r.daysToAge
      AND cs.strengthType = 30010
) AS req

OUTER APPLY
(
    SELECT
        CASE
            WHEN COUNT(DISTINCT cs.strength) = 1
                THEN MAX(cs.strength)
        END AS DesignStrengthAtAge_psi,
        COUNT(*) AS DesignStrengthAtAgeRowCount,
        COUNT(DISTINCT cs.strength)
            AS DesignStrengthAtAgeDistinctValueCount
    FROM dbo.FieldConcreteStrengthRows AS cs
    WHERE cs.concreteTestId = c.id
      AND cs.days = r.daysToAge
      AND cs.strengthType = 30011
) AS des

WHERE c.unitSystem = 0
  AND s.workflowStateId = 1000
  AND p.officeId NOT IN (1, 26, 64);