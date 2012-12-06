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
IF object_id(N'CRM_DV_DISCRIPTION_CONTACT_MAN') IS NOT NULL
DROP TRIGGER CRM_DV_DISCRIPTION_CONTACT_MAN
GO
/*********************************************/

--Добавляем триггер. добовления  контактов в DV при добовление в CRM.
/*********************************************/
CREATE TRIGGER CRM_DV_DISCRIPTION_CONTACT_MAN
   ON LIST_CONTACT_MAN
   AFTER UPDATE, INSERT
/*********************************************/
AS
IF (UPDATE(DISCRIPTION_CONTACT_MAN))
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
	DECLARE		@_ID_CONTACT_MAN_INS				int
	DECLARE		@_ParentRowID						uniqueidentifier
	/*********************************************/

	--Переменные добавленного значения должность
	/*********************************************/
	DECLARE     @_DISCRIPTION_CONTACT_MAN			varchar(200)			
	/*********************************************/
	
	--Заполняем переменные значениями
	/*********************************************/
	SELECT 
	TOP 1		@_ID_COMPANY				=		INS.ID_COMPANY,
				@_ID_CONTACT_MAN_INS		=		INS.ID_CONTACT_MAN,
				@_DISCRIPTION_CONTACT_MAN	=		INS.DISCRIPTION_CONTACT_MAN				
	FROM		INSERTED as INS;
	/*********************************************/

	--execute _log '@_DISCRIPTION_CONTACT_MAN', @_DISCRIPTION_CONTACT_MAN
	
	--Для нового контакта добавляем новый ключ в DV и записываем его в CRM
	/*********************************************/
	SELECT		@_ParentRowID				=		DV_ID   
	FROM        COMPANY
	WHERE		ID_COMPANY	 				=		@_ID_COMPANY
	/*********************************************/
	--if (@_ParentRowID is null) print('Ошибка нет соответствия ключа в DV')
	
	--Ключ на должность	
	/*********************************************/
	DECLARE	    @_RowID_Position					uniqueidentifier
	/*********************************************/
	--Приводим к виду DV
	/*********************************************/
	DECLARE	@_DV_DISCRIPTION_CONTACT_MAN	nvarchar(128)
	SET		@_DV_DISCRIPTION_CONTACT_MAN=	LEFT(@_DISCRIPTION_CONTACT_MAN, 128)
	/*********************************************/


	--Если поля не заполнены добавляем без должности @_RowID_Position = NULL
	/*********************************************/
	IF(@_DISCRIPTION_CONTACT_MAN IS NOT NULL) AND (@_DISCRIPTION_CONTACT_MAN != '')
	BEGIN 		
		
		--Ищем должность, если не находим - добавляем	
		--Поиск сотвествуещей должности в DV.
		/*********************************************/
		SELECT		
		TOP 1	@_RowID_Position			=	RowID
		FROM	Copy_DV.[dbo].[dvtable_{bdafe82a-04fa-4391-98b7-5df6502e03dd}] 
		WHERE	Name						=	@_DV_DISCRIPTION_CONTACT_MAN
		/*********************************************/
		
		--Отключаем Триггер в DV
		/*********************************************/
		ALTER TABLE Copy_DV.[dbo].[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}] 
		DISABLE TRIGGER ALL
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
				Name																	
				)
		VALUES	(
				@_RowID_Position,
				@CONST_SDID,
				@CONST_InstanceID,
				@CONST_ParentTreeRowID,
				@_DV_DISCRIPTION_CONTACT_MAN
				) 
		END		
		--execute _log '@_ID_CONTACT_MAN_INS', @_ID_CONTACT_MAN_INS
		--execute _log '@_RowID_Position', @_RowID_Position		
		
		UPDATE
		TOP (1)		Copy_DV.[dbo].[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}]
		SET			Position		=	@_RowID_Position
		WHERE		CRM_ID			=	@_ID_CONTACT_MAN_INS
		
		
		--Включаем Триггер в DV
		/*********************************************/
		ALTER TABLE [Copy_DV].[dbo].[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}]
		ENABLE TRIGGER ALL
		/*********************************************/		
	END
	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S		
END
GO