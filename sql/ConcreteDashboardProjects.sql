SELECT OfficeId, OfficeName, ProjectId, ProjectName, ProjectNo
  FROM [imts-main-master].[dbo].[vw_CurrentConcreteSpecimenStatus]
  where OfficeId =2 
  group by projectId, ProjectNo, OfficeId, OfficeName, ProjectName

  SELECT COUNT(*) 
FROM (
    SELECT ProjectId, ProjectNo, OfficeId 
    FROM [imts-main-master].[dbo].[vw_CurrentConcreteSpecimenStatus] 
    WHERE OfficeId = 2 
    GROUP BY ProjectId, ProjectNo, OfficeId
) AS SubqueryAlias;
