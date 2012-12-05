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
IF object_id(N'DV_CRM_Upd_Req_RS') IS NOT NULL
DROP TRIGGER DV_CRM_Upd_Req_RS
GO
/*********************************************/

--Добавляем триггер. добовления  контактов в DV при добовление в CRM.
/*********************************************/
CREATE TRIGGER DV_CRM_Upd_Req_RS
   ON [dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
AFTER UPDATE
/*********************************************/
AS
IF(UPDATE(Account))
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
	SET NOCOUNT ON		
	
	-- Очистим лог
	/*********************************************/
	--DELETE	[CBaseCRM_Fresh].[dbo].[Log]
	/*********************************************/
	
		--Объявлям переменные
	/*********************************************/
	DECLARE		@_ID_COMPANY					int
	DECLARE		@_COUNT							int
	/*********************************************/
	
		--Заполняем переменные
	/*********************************************/
	SELECT
	TOP 1		@_ID_COMPANY			=		INS.Telex
	FROM		INSERTED AS INS
	/*********************************************/
	
	--Смотрим колличество реквизитов у компании по умолчанию
	
	/*********************************************/
	SELECT		@_COUNT					=		COUNT(ID_COMPANY)
	FROM [CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
	WHERE		ID_COMPANY				=		@_ID_COMPANY
	/*********************************************/
	
	--Отключаем Триггер в DV
	/*********************************************/
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
	DISABLE TRIGGER ALL
	/*********************************************/	

	--Если нет реквизитов добавляем по умолчанию добовляем их.
	/*********************************************/
	IF(@_COUNT = 0)
	BEGIN
		INSERT INTO	[CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
				(
			ID_COMPANY,
				USE_DEFAULT
				) 
		VALUES	(
			@_ID_COMPANY,
				1
				)
	END
	/*********************************************/		
	IF(@_COUNT = 1)
	BEGIN
		--Обновляем существующие реквизиты
		/*********************************************/	
		UPDATE		[CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
		SET			RS						=		UPD.Account
		FROM		INSERTED AS UPD
		WHERE		ID_COMPANY				=		UPD.Telex
		/*********************************************/
	END
	ELSE
	BEGIN
		--Обновляем существующие реквизиты
		/*********************************************/	
		UPDATE		[CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
		SET			RS						=		UPD.Account
		FROM		INSERTED AS UPD
		WHERE		ID_COMPANY				=		UPD.Telex
		AND			USE_DEFAULT				=		'True'
		/*********************************************/
	END

	--Включаем Триггер в CRM
	/*********************************************/		
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
	ENABLE TRIGGER ALL
	/*********************************************/	

	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S		
END