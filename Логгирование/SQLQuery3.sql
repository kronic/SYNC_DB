				 -- удаление всех экземпл€ров карточек, дл€ которых нет типа карточки
DELETE FROM [dvsys_instances_date]    
WHERE InstanceID NOT IN (SELECT InstanceID FROM [dvsys_instances] )
/****** —крипт дл€ команды SelectTopNRows из среды SSMS  ******/
SELECT 
      *
  FROM [Copy_DV].[dbo].[dvsys_instances_date]
  order by [ChangeDateTime] 
  --where instanceID = '7B24CF26-16E5-410E-B7D2-39BB00B452C8'
  --6C40B7C7-ECD5-4E49-9B1B-7B40191C27B3
  --D125BE6B-1EE5-4DD4-AC33-7391B517A7CD
  --65FF9382-17DC-4E9F-8E93-84D6D3D8FE8C