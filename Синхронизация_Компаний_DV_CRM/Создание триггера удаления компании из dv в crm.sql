USE [Copy_DV]
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Иван Берлинец
-- Create date: 14.11.2012
-- Description:	Скрипит создает триггер на добавления контактных данных из DV в CRM.
-- Необходимо заминить имя Copy_DV на имя базы DV. 
-- =============================================

--Удаляем триггер если он существует.
/*********************************************/
IF object_id(N'DV_CRM_Del_Company') IS NOT NULL
DROP TRIGGER DV_CRM_Del_Company
GO
/*********************************************/

--Добавляем триггер. добовления  контактов в DV при добовление в CRM.
/*********************************************/
CREATE TRIGGER DV_CRM_Del_Company
   ON [dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
AFTER DELETE
/*********************************************/
AS 
BEGIN
	--Получаем имя запучченого триггера
	/*********************************************/
	DECLARE		@S			varchar(100)
	DECLARE		@K			int
	SET			@K		=	(@@PROCID)
	SELECT		@S		=	[name] 
	FROM		sysobjects 
	WHERE		[id]	=	@K
	/*********************************************/
	execute [CBaseCRM_Fresh].[dbo]._log 'Start', @S
	
	DECLARE		@_ID_COMPANY					int
	/*********************************************/
	SELECT 
	TOP 1		@_ID_COMPANY			=		DEL.Telex
	FROM		DELETED as DEL
	/*********************************************/

	--Отключаем Триггер в CRM
	/*********************************************/
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[COMPANY]
	DISABLE TRIGGER ALL
	/*********************************************/
	--EXECUTE [CBaseCRM_Fresh].[dbo]._log '@_DV_ID_COMPANY', @_DV_ID_COMPANY	
	--Добовляем запись в crm.
	/*********************************************/
	DELETE
	TOP (1)
	FROM	[CBaseCRM_Fresh].[dbo].[COMPANY]
	WHERE	ID_COMPANY	=	@_ID_COMPANY
	/*********************************************/	
	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S
END