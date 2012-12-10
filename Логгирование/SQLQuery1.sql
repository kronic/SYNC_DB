/****** для обновления сессие  ******/

UPDATE [Copy_DV].[dbo].[dvsys_instances_date]
SET  [ChangeDateTime] = CURRENT_TIMESTAMP
WHERE [InstanceID] = N'65FF9382-17DC-4E9F-8E93-84D6D3D8FE8C'

SELECT TOP 1000 [InstanceID]
      ,[Timestamp]
      ,[CreationDateTime]
      ,[ChangeDateTime]
  FROM [Copy_DV].[dbo].[dvsys_instances_date]
  WHERE [InstanceID] = N'65FF9382-17DC-4E9F-8E93-84D6D3D8FE8C'