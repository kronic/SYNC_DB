USE [CBaseCRM_Fresh]
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Иван Берлинец
-- Create date: 14.11.2012
-- Description:	Скрипит создает триггер на добавления Имени, Фамили, Отчества, Должности в DV из CRM.
-- Необходимо заминить имя Copy_DV на имя базы DV. 
-- =============================================

--Удаляем триггер если он существует.
/*********************************************/
IF object_id(N'CRM_DV_DIR_STATUS') IS NOT NULL
DROP TRIGGER CRM_DV_DIR_STATUS
GO
/*********************************************/

--Добавляем триггер. добовления  контактов в DV при добовление в CRM.
/*********************************************/
CREATE TRIGGER CRM_DV_DIR_STATUS
   ON [dbo].[LIST_REQUIS_COMPANY]
   AFTER INSERT, UPDATE
/*********************************************/
AS
IF (UPDATE(DIR_STATUS) OR UPDATE(DIR_STATUS_1) OR UPDATE(DIR_STATUS_2))
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
	--DELETE [dbo].[Log]
	/*********************************************/

	--Новый Ключ
	/*********************************************/
	DECLARE		@NEW_RowID							uniqueidentifier
	/*********************************************/
	
	--Константы
	/*********************************************/
	DECLARE		@CONST_SDID							uniqueidentifier
	DECLARE		@CONST_InstanceID					uniqueidentifier	
	DECLARE		@CONST_ParentTreeRowID				uniqueidentifier
	/*********************************************/
	
	--Заполняем константы значениями
	/*********************************************/
	SET			@NEW_RowID					=		NEWID()
	SET			@CONST_SDID					=		'8F51A892-10C4-4723-9EEA-B93DA63414C1'
	SET			@CONST_InstanceID			=		'65FF9382-17DC-4E9F-8E93-84D6D3D8FE8C'
	SET			@CONST_ParentTreeRowID		=		'00000000-0000-0000-0000-000000000000'
	/*********************************************/

	--Переменные добавленного значения
	/*********************************************/
	DECLARE     @_ID_COMPANY						int	
	DECLARE		@_DV_ID_Manager						uniqueidentifier
	
	/*********************************************/

	--Переменные добавленного значения должность
	/*********************************************/
	DECLARE     @_DIR_STATUS						varchar(200)
	DECLARE     @_DIR_STATUS_1						varchar(200)
	DECLARE     @_DIR_STATUS_2						varchar(200)
	/*********************************************/
	
	--Заполняем переменные значениями
	/*********************************************/
	SELECT 		@_ID_COMPANY				=		INS.ID_COMPANY,
				@_DIR_STATUS				=		INS.DIR_STATUS,
				@_DIR_STATUS_1				=		INS.DIR_STATUS_1,
				@_DIR_STATUS_2				=		INS.DIR_STATUS_2				
	FROM		INSERTED as INS

	SELECT 		@_DV_ID_Manager				=		Manager
	FROM		Copy_DV.[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
	WHERE		Telex						=		@_ID_COMPANY
	/*********************************************/
	execute _log '@@_ID_COMPANY', @_ID_COMPANY

	
	--Ключ на должность	
	/*********************************************/
	DECLARE	    @_RowID_Position					uniqueidentifier
	/*********************************************/	
	
	--Если поля не заполнены добавляем без должности @_RowID_Position = NULL
	/*********************************************/
	IF(@_DIR_STATUS IS NOT NULL AND @_DIR_STATUS != '')
	BEGIN

		--Приводим к виду DV
		/*********************************************/
		DECLARE	@_DV_DIR_STATUS						nvarchar(128)
		DECLARE	@_DV_DIR_STATUS_1					nvarchar(128)
		DECLARE	@_DV_DIR_STATUS_2					nvarchar(128)
		SET		@_DV_DIR_STATUS					=	LEFT(@_DIR_STATUS, 128)
		SET		@_DV_DIR_STATUS_1				=	LEFT(@_DIR_STATUS_1, 128)
		SET		@_DV_DIR_STATUS_2				=	LEFT(@_DIR_STATUS_2, 128)
		/*********************************************/
			
		--Ищем должность, если не находим - добавляем	
		--Поиск сотвествуещей должности в DV.
		/*********************************************/
		SELECT		
		TOP 1	@_RowID_Position			=	RowID
		FROM	Copy_DV.[dbo].[dvtable_{bdafe82a-04fa-4391-98b7-5df6502e03dd}] 
		WHERE	Name						=	@_DV_DIR_STATUS
		/*********************************************/
		
		--Отключаем Триггер в DV
		/*********************************************/
		ALTER TABLE Copy_DV.[dbo].[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}] 
		DISABLE TRIGGER DV_CRM_Upd_Position
		/*********************************************/	
		
		--Если отсутвует должность добавляем её
		/*********************************************/
		IF(@_RowID_Position IS NULL)		
		BEGIN
		--Новый Ключ	
		SET @_RowID_Position = NEWID()
		/*********************************************/
		--	print(@_DV_DISCRIPTION_CONTACT_MAN)	
		
		INSERT INTO Copy_DV.[dbo].[dvtable_{bdafe82a-04fa-4391-98b7-5df6502e03dd}]
				(	
				RowID,
				SDID,					--CONST 
				InstanceID,				--CONST																		
				ParentTreeRowID,		--CONST
				Name,
				Genitive,
				Dative
				)
		VALUES	(
				@_RowID_Position,
				@CONST_SDID,
				@CONST_InstanceID,
				@CONST_ParentTreeRowID,
				@_DV_DIR_STATUS,
				@_DV_DIR_STATUS_1,
				@_DV_DIR_STATUS_2
				) 
		END		

		--execute _log '@_RowID_Position', @_RowID_Position		
		IF(@_DV_ID_Manager IS NOT NULL)
		BEGIN
			UPDATE		Copy_DV.[dbo].[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}]
			SET			Position		=	@_RowID_Position
			WHERE		RowID			=	@_DV_ID_Manager
		END
		
		
		--Включаем Триггер в DV
		/*********************************************/
		ALTER TABLE [Copy_DV].[dbo].[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}]
		ENABLE TRIGGER DV_CRM_Upd_Position
		/*********************************************/		
	END
	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S		
END
GO