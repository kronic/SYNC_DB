USE [Copy_DV]
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET CONCAT_NULL_YIELDS_NULL ON;
GO
-- =============================================
-- Author:		Иван Берлинец
-- Create date: 14.11.2012
-- Description:	Скрипит создает триггер на добавления контактных данных из DV в CRM.
-- Необходимо заминить имя Copy_DV на имя базы DV.
-- =============================================

--Удаляем триггер если он существует.
/*********************************************/
IF OBJECT_ID(N'DV_CRM_Upd_Req_GL_BUH', 'TR') IS NOT NULL
DROP TRIGGER DV_CRM_Upd_Req_GL_BUH
GO
/*********************************************/

--Добавляем триггер. Обновления  телефона в DV при добовление в CRM.
/*********************************************/
CREATE TRIGGER	DV_CRM_Upd_Req_GL_BUH
ON				[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
AFTER UPDATE
/*********************************************/
AS
IF UPDATE(ChiefAccountant)
BEGIN

	DECLARE		@_BEF_ChiefAccountant						nvarchar(128)
	DECLARE		@_AFT_ChiefAccountant						nvarchar(128)

	-- Получим значение до обноления
	/*********************************************/		
	SELECT	@_BEF_ChiefAccountant					=		UPD.ChiefAccountant
	FROM	DELETED AS UPD
	/*********************************************/	
	  	
	--Заполняем переменные после добавленния значения.	
	/*********************************************/
	SELECT 
	TOP 1		@_AFT_ChiefAccountant				=		UPD.ChiefAccountant
	FROM		INSERTED as UPD;
	/*********************************************/

	IF(	@_BEF_ChiefAccountant	=	@_AFT_ChiefAccountant 
	OR  @_AFT_ChiefAccountant	IS	NULL 
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

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON
	--execute [CBaseCRM_Fresh].[dbo]._log '', 'Запуск триггера обновление тел.'
	-- Очистим лог
	/*********************************************/
	--DELETE		[CBaseCRM_Fresh].[dbo].[Log]
	/*********************************************/
	
	--Переменные добавленного значения должность
	/*********************************************/
	DECLARE		@_DV_ID_CHIEFACCOUNTANT			uniqueidentifier
	DECLARE		@_ID_COMPANY					int	
	DECLARE		@_FirstName						nvarchar(32)
	DECLARE		@_LastName						nvarchar(32)
	DECLARE		@_MiddleName					nvarchar(32)
	DECLARE		@_COUNT							int
	/*********************************************/
	
	--Заполняем переменные добавленным значениями.
	/*********************************************/
	SELECT
	TOP 1		@_DV_ID_CHIEFACCOUNTANT	=		INS.ChiefAccountant,
				@_ID_COMPANY			=		INS.Telex				
	FROM		INSERTED as INS;

	SELECT
	TOP 1		@_FirstName				=		ISNULL(FirstName, ''),
				@_LastName				=		ISNULL(LastName , ''),
				@_MiddleName			=		ISNULL(MiddleName,'')
	FROM		[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}]
	WHERE		RowID					=		@_DV_ID_CHIEFACCOUNTANT
	/*********************************************/
	
	--execute [CBaseCRM_Fresh].[dbo]._log '@_DV_ID_COMPANY', @_DV_ID_COMPANY
	--execute [CBaseCRM_Fresh].[dbo]._log '@_ID_COMPANY', @_ID_COMPANY
	
	/*********************************************/
	SELECT		@_COUNT					=		COUNT(ID_COMPANY)
	FROM		[CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
	WHERE		ID_COMPANY				=		@_ID_COMPANY					
	/*********************************************/
	
	--execute [CBaseCRM_Fresh].[dbo]._log '@_COUNT', @_COUNT
	
	--Если нет реквизитов добавляем по умолчанию добовляем их.
	/*********************************************/
	
	--Отключаем Триггер в DV
	/*********************************************/
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
	DISABLE TRIGGER ALL
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
		
		--Обновляем существующие почтовый адресс
		/*********************************************/	
		UPDATE
		TOP (1)		[CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
		SET			GL_BUH					=		@_LastName + ' ' + @_FirstName + ' ' + @_MiddleName
		WHERE		ID_COMPANY 				=		@_ID_COMPANY			
		/*********************************************/					
	END
	ELSE
	BEGIN
		
		--Обновляем существующие почтовый адресс
		/*********************************************/	
		UPDATE
		TOP (1)		[CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
		SET			GL_BUH					=		@_LastName + ' ' + @_FirstName + ' ' + @_MiddleName
		WHERE		ID_COMPANY 				=		@_ID_COMPANY
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