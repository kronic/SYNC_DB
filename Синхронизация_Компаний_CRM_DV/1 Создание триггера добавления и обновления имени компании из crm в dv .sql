USE [CBaseCRM_Fresh]
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET CONCAT_NULL_YIELDS_NULL ON;
GO
SET TRANSACTION ISOLATION
LEVEL SERIALIZABLE
GO
-- =============================================
-- Author:		Иван Берлинец
-- Create date: 14.11.2012
-- Description:	Скрипит создает триггер на добавления email в DV из CRM.
-- Необходимо заминить имя Copy_DV на имя базы DV. 
-- =============================================

--Удаляем триггер если он существует.
/*********************************************/
IF object_id('CRM_DV_COMPANY_NAME', 'TR') IS NOT NULL
DROP TRIGGER CRM_DV_COMPANY_NAME
GO
/*********************************************/

--Добавляем триггер. добовления  контактов в DV при добовление в CRM.
/*********************************************/
CREATE TRIGGER CRM_DV_COMPANY_NAME
   ON [dbo].[COMPANY]
   AFTER INSERT, UPDATE
/*********************************************/
AS
IF(UPDATE(COMPANY_NAME))
BEGIN
	BEGIN TRAN tr1 
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
	DECLARE     @_COMPANY_NAME				varchar(200)

	DECLARE		@_DV_ID_COMPANY				int
	/*********************************************/
	

	--Заполняем переменные значениями
	/*********************************************/
	SELECT		@_ID_COMPANY		=		INS.ID_COMPANY,				
				@_COMPANY_NAME		=		INS.COMPANY_NAME
	FROM		INSERTED AS INS
	/*********************************************/

	--Приведем к виду DV
	/*********************************************/
	DECLARE		@_DV_COMPANY_NAME			nvarchar(128)	
	SET			@_DV_COMPANY_NAME	=		LEFT(@_COMPANY_NAME, 128)
	/*********************************************/

	--Проверяем наличе записии в DV
	/*********************************************/
	SELECT		@_DV_ID_COMPANY		=		Telex
	FROM		[Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
	WHERE		Telex = @_ID_COMPANY
	/*********************************************/

	--Если нет компании добавим её в DV	
	IF(@_DV_ID_COMPANY IS NULL)
	BEGIN
		--execute [CBaseCRM_Fresh].[dbo]._log '', 'Добовляем'		
		--Новый Ключ
		/*********************************************/
		DECLARE		@NEW_RowID					uniqueidentifier 
		SET			@NEW_RowID		=			NEWID()
		/*********************************************/

		--Константы
		/*********************************************/
		DECLARE		@CONST_SDID					uniqueidentifier
		DECLARE		@CONST_InstanceID			uniqueidentifier
		DECLARE		@CONST_ParentRowID			uniqueidentifier
		DECLARE		@CONST_ParentTreeRowID		uniqueidentifier
		SET			@CONST_SDID				=	'{8F51A892-10C4-4723-9EEA-B93DA63414C1}'
		SET			@CONST_InstanceID		=	'{65FF9382-17DC-4E9F-8E93-84D6D3D8FE8C}'
		SET			@CONST_ParentRowID		=	'{00000000-0000-0000-0000-000000000000}'
		SET			@CONST_ParentTreeRowID	=	'{00000000-0000-0000-0000-000000000000}'
		/*********************************************/
		--Отключаем Триггер в CRM
		/*********************************************/
		ALTER TABLE [Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
		DISABLE TRIGGER ALL
		/*********************************************/	
		
		--execute [CBaseCRM_Fresh].[dbo]._log '@_ID_COMPANY', @_ID_COMPANY		
		
		INSERT INTO [Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}] 
			(
				[RowID],
				[SDID],				--CONST
				[InstanceID],		--CONST
				[ParentRowID],		--CONST
				[ParentTreeRowID],	--CONST
				[Name],			
				[FullName],
				[Telex],
				[Type],
				[NotAvailable]
			)
		VALUES
			(
				@NEW_RowID,				--RowID
				@CONST_SDID,			--SDID
				@CONST_InstanceID,		--InstanceID
				@CONST_ParentRowID,
				@CONST_ParentTreeRowID,	--ParentTreeRowID
				@_DV_COMPANY_NAME,		--Name
				@_DV_COMPANY_NAME,		--Name
				@_ID_COMPANY,			--[Telex]
				0,
				0
			)
		
		--Обновляем ключ dv_id
		/*********************************************/	
		UPDATE
		TOP (1)	[dbo].[COMPANY]
		SET		[DV_ID]							=			@NEW_RowID
		WHERE	ID_COMPANY						=			@_ID_COMPANY
		/*********************************************/	

		--Включаем Триггер в CRM
		/*********************************************/		
		ALTER TABLE [Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
		ENABLE TRIGGER ALL
		/*********************************************/	
	END
	--Иначе обновим её.
	ELSE
	BEGIN
		--execute [CBaseCRM_Fresh].[dbo]._log '', 'Обновляем'	
			
		--Отключаем Триггер в CRM
		/*********************************************/
		ALTER TABLE [Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
		DISABLE TRIGGER ALL
		/*********************************************/	

		UPDATE		
		TOP (1)		[Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
		SET			--FullName						=		@_DV_COMPANY_NAME
					Name							=		@_DV_COMPANY_NAME
		WHERE		[Telex]							=		@_ID_COMPANY

		--Включаем Триггер в CRM
		/*********************************************/		
		ALTER TABLE [Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
		ENABLE TRIGGER ALL
		/*********************************************/	

	END			
	
	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S
	COMMIT TRAN tr1
END
--Выполнение триггера первым
--exec sp_settriggerorder 'CRM_DV_COMPANY_NAME', 'first', 'insert'
--GO
--exec sp_settriggerorder 'CRM_DV_COMPANY_NAME', 'first', 'update'
--GO