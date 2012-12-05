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
IF object_id('CRM_DV_KPP', 'TR') IS NOT NULL
DROP TRIGGER CRM_DV_KPP
GO
/*********************************************/

--Добавляем триггер. добовления  контактов в DV при добовление в CRM.
/*********************************************/
CREATE TRIGGER CRM_DV_KPP
   ON [dbo].[LIST_REQUIS_COMPANY]
   AFTER INSERT, UPDATE
/*********************************************/
AS
IF(UPDATE(KPP))
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
	DECLARE		@_KPP						varchar(20) -- DV type nvarchar(128) привод типа и длинны не нужен
	DECLARE		@_COUNT_REQ					int
	DECLARE		@_USE_DEFAULT				varchar(10)
	/*********************************************/
	
	--Заполняем переменные значениями
	/*********************************************/
	SELECT		@_ID_COMPANY		=		INS.ID_COMPANY,				
				@_KPP				=		INS.KPP,
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
	--execute [CBaseCRM_Fresh].[dbo]._log '@_FAX', @_FAX
	--Отключаем Триггер в DV
	/*********************************************/
	ALTER TABLE [Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
	DISABLE TRIGGER [DV_CRM_Upd_Req_KPP]
	/*********************************************/	

	UPDATE		[Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
	SET			[KPP]			=	@_KPP
	WHERE		[Telex]			=	@_ID_COMPANY	
	

	--Включаем Триггер в CRM
	/*********************************************/		
	ALTER TABLE [Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
	ENABLE TRIGGER [DV_CRM_Upd_Req_KPP]
	/*********************************************/	
		
	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S
END