
USE [CBaseCRM_Fresh]
GO
/****** Скрипт для команды SelectTopNRows из среды SSMS  ******/
SELECT *
FROM [CBaseCRM_Fresh].[dbo].[Log]
ORDER BY [TIME]

DELETE [CBaseCRM_Fresh].[dbo].[Log]