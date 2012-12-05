USE [CBaseCRM_Fresh]
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET CONCAT_NULL_YIELDS_NULL ON;
GO
-- =============================================
-- Author:		Иван Берлинец
-- Create date: 14.11.2012
-- Description:	Скрипит создает триггер на добавления email в DV из CRM.
-- Необходимо заминить имя Copy_DV на имя базы DV. 
-- =============================================

--Удаляем триггер если он существует.
/*********************************************/
IF object_id('CRM_DV_COMPANY_URL', 'TR') IS NOT NULL
DROP TRIGGER CRM_DV_COMPANY_URL
GO
/*********************************************/

--Добавляем триггер. добовления  контактов в DV при добовление в CRM.
/*********************************************/
CREATE TRIGGER CRM_DV_COMPANY_URL
   ON [dbo].[COMPANY]
   AFTER INSERT, UPDATE
/*********************************************/
AS
IF(UPDATE(URL_COMPANY))
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

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	--Переменные
	/*********************************************/
	DECLARE		@_ID_COMPANY				int
	DECLARE     @_URL_COMPANY				varchar(150) --DV nvarchar(256)
	/*********************************************/
	

	--Заполняем переменные значениями
	/*********************************************/
	SELECT		@_ID_COMPANY		=		INS.ID_COMPANY,				
				@_URL_COMPANY		=		INS.URL_COMPANY
	FROM		INSERTED AS INS
	/*********************************************/
	
	execute [CBaseCRM_Fresh].[dbo]._log '', 'Обновляем'		
	--Отключаем Триггер в CRM
	/*********************************************/
	ALTER TABLE [Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
	DISABLE TRIGGER [DV_CRM_Upd_Url_Company]
	/*********************************************/	
	UPDATE
	TOP (1)		[Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
	SET			[URL]							=		@_URL_COMPANY					
	WHERE		[Telex]							=		@_ID_COMPANY
	
	--Включаем Триггер в CRM
	/*********************************************/		
	ALTER TABLE [Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
	ENABLE TRIGGER [DV_CRM_Upd_Url_Company]
	/*********************************************/	
	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S
END