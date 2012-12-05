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
IF object_id(N'DV_CRM_Upd_INN') IS NOT NULL
DROP TRIGGER DV_CRM_Upd_INN
GO
/*********************************************/

--Добавляем триггер. добовления  контактов в DV при добовление в CRM.
/*********************************************/
CREATE TRIGGER DV_CRM_Upd_INN
   ON [dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
AFTER UPDATE
/*********************************************/
AS
IF(UPDATE(INN))
BEGIN
	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON
	
	DECLARE		@_BEF_INN						nvarchar(128)
	DECLARE		@_AFT_INN						nvarchar(128)

	-- Получим значение до обноления
	/*********************************************/		
	SELECT	@_BEF_INN					=		UPD.INN
	FROM	DELETED AS UPD
	/*********************************************/	
	  	
	--Заполняем переменные после добавленния значения.	
	/*********************************************/
	SELECT 
	TOP 1		@_AFT_INN				=		UPD.INN
	FROM		INSERTED as UPD;
	/*********************************************/

	IF(	@_BEF_INN	=	@_AFT_INN 
	OR  @_AFT_INN	IS	NULL 
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
	TOP(1)	[CBaseCRM_Fresh].[dbo].[COMPANY]
	SET		INN								=		UPD.INN			
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