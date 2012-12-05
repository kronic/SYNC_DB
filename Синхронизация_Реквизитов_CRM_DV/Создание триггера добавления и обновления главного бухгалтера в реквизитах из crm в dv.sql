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
IF object_id('CRM_DV_GL_BUH', 'TR') IS NOT NULL
DROP TRIGGER CRM_DV_GL_BUH
GO
/*********************************************/

--Добавляем триггер. добовления  контактов в DV при добовление в CRM.
/*********************************************/
CREATE TRIGGER CRM_DV_GL_BUH
   ON [dbo].[LIST_REQUIS_COMPANY]
   AFTER UPDATE
/*********************************************/
AS
IF(UPDATE(GL_BUH))
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
	DECLARE		@_GL_BUH					varchar(100)
	DECLARE		@_USE_DEFAULT				varchar(10)
	DECLARE		@_COUNT_REQ					int
	DECLARE		@_DV_CHIEFACCOUNTANT		uniqueidentifier
	/*********************************************/
	
	--Заполняем переменные значениями
	/*********************************************/
	SELECT		@_ID_COMPANY		=		INS.ID_COMPANY,				
				@_GL_BUH			=		INS.GL_BUH,
				@_USE_DEFAULT		=		INS.USE_DEFAULT
	FROM		INSERTED AS INS	
	
	SELECT		@_COUNT_REQ = COUNT(ID_COMPANY)
	FROM		[LIST_REQUIS_COMPANY]
	WHERE		ID_COMPANY			=		@_ID_COMPANY	
	/*********************************************/
	
	IF(@_USE_DEFAULT != 'True' AND @_COUNT_REQ > 1 )
	BEGIN
		execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S
		RETURN
	END
	IF (@_GL_BUH IS NOT NULL AND @_GL_BUH !='')
	BEGIN
		SELECT  @_DV_CHIEFACCOUNTANT=		[RowID] 
		FROM	Copy_DV.[dbo].[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}] 
		WHERE	([LastName] + ' ' + [FirstName] + ' ' + [MiddleName])	= @_GL_BUH
	END
	IF (@_DV_CHIEFACCOUNTANT IS NOT NULL)	
	BEGIN		
		--execute [CBaseCRM_Fresh].[dbo]._log '@_FAX', @_FAX
		--Отключаем Триггер в CRM
		/*********************************************/
		ALTER TABLE [Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
		DISABLE TRIGGER [DV_CRM_Upd_Req_GL_BUH]
		/*********************************************/	

		UPDATE
		TOP (1)		[Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
		SET			ChiefAccountant	=	@_DV_CHIEFACCOUNTANT
		WHERE		Telex			=	@_ID_COMPANY	

		--Включаем Триггер в CRM
		/*********************************************/		
		ALTER TABLE [Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
		ENABLE TRIGGER [DV_CRM_Upd_Req_GL_BUH]
		/*********************************************/	
	END

	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S
END