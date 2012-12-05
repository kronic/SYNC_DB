/****** Скрипт для команды SelectTopNRows из среды SSMS  ******/
SELECT Telex, COUNT(Telex) AS 'Кол-во'
FROM [Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
WHERE Name = N'' or name is null
GROUP BY Telex

DELETE [Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
WHERE Name = N'' or name is null
