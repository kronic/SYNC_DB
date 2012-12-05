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
IF object_id(N'DV_CRM_Upd_Company_Name') IS NOT NULL
DROP TRIGGER DV_CRM_Upd_Company_Name
GO
/*********************************************/

--Добавляем триггер. добовления  контактов в DV при добовление в CRM.
/*********************************************/
CREATE TRIGGER DV_CRM_Upd_Company_Name
   ON [dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
AFTER UPDATE
/*********************************************/
AS
IF(UPDATE(Name))
BEGIN
	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON

	
	DECLARE		@_BEF_Name						nvarchar(128)
	DECLARE		@_AFT_Name						nvarchar(128)

	-- Получим значение до обноления
	/*********************************************/		
	SELECT	@_BEF_Name					=		UPD.Name
	FROM	DELETED AS UPD
	/*********************************************/	
	  	
	--Заполняем переменные после добавленния значения.	
	/*********************************************/
	SELECT 
	TOP 1		@_AFT_Name				=		UPD.Name
	FROM		INSERTED as UPD;
	/*********************************************/
	
	IF(	@_BEF_Name	=	@_AFT_Name 
	OR  @_AFT_Name	IS	NULL 
		) RETURN
	
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
	

	-- Очистим лог
	/*********************************************/
	--DELETE	[CBaseCRM_Fresh].[dbo].[Log]
	/*********************************************/

	--Отключаем Триггер в CRM
	/*********************************************/
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[COMPANY]
	DISABLE TRIGGER ALL
	/*********************************************/

	UPDATE
	TOP (1)	[CBaseCRM_Fresh].[dbo].[COMPANY]
	SET		COMPANY_NAME					=		UPD.Name			
	FROM	INSERTED AS UPD
	WHERE	DV_ID							=		UPD.RowID
	/*********************************************/

	--Включение триггера CRM
	/*********************************************/
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[COMPANY]
	ENABLE TRIGGER ALL
	/*********************************************/

	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S
END