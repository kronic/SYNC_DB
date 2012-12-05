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
IF object_id(N'DV_CRM_Upd_Url_Company') IS NOT NULL
DROP TRIGGER DV_CRM_Upd_Url_Company
GO
/*********************************************/

--Добавляем триггер. добовления  контактов в DV при добовление в CRM.
/*********************************************/
CREATE TRIGGER DV_CRM_Upd_Url_Company
   ON [dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
AFTER UPDATE
/*********************************************/
AS 
IF(UPDATE(URL))
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON
	
	DECLARE		@_BEF_URL						nvarchar(128)
	DECLARE		@_AFT_URL						nvarchar(128)

	-- Получим значение до обноления
	/*********************************************/		
	SELECT	@_BEF_URL					=		UPD.URL
	FROM	DELETED AS UPD
	/*********************************************/	
	  	
	--Заполняем переменные после добавленния значения.	
	/*********************************************/
	SELECT 
	TOP 1		@_AFT_URL				=		UPD.URL
	FROM		INSERTED as UPD;
	/*********************************************/

	IF(	@_BEF_URL	=	@_AFT_URL 
	OR  @_AFT_URL	IS	NULL 
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
	DISABLE TRIGGER [CRM_DV_COMPANY_URL]
	/*********************************************/	

	UPDATE
	TOP (1)	[CBaseCRM_Fresh].[dbo].[COMPANY]
	SET		URL_COMPANY						=		UPD.URL			
	FROM	INSERTED AS UPD
	WHERE	DV_ID							=		UPD.RowID
	
	--Включаем Триггер в CRM
	/*********************************************/		
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[COMPANY]
	ENABLE TRIGGER [CRM_DV_COMPANY_URL]
	/*********************************************/

	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S	
END