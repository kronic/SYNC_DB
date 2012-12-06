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
IF OBJECT_ID(N'DV_CRM_Upd_Contact', 'TR') IS NOT NULL
DROP TRIGGER DV_CRM_Upd_Contact
GO
/*********************************************/

--Добавляем триггер. Обновления  контактов в DV при добовление в CRM.
/*********************************************/
CREATE TRIGGER	DV_CRM_Upd_Contact
ON				[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}]
/*********************************************/
AFTER UPDATE
AS
IF(UPDATE(FirstName) OR UPDATE(MiddleName) OR UPDATE(LastName))
BEGIN
	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON
	
	-- Очистим лог
	/*********************************************/
	--DELETE	[CBaseCRM_Fresh].[dbo].[Log]
	/*********************************************/
	
	DECLARE	@_ID_CONTACT_MAN					int
	DECLARE	@_LASTNAME							nvarchar(32)
	DECLARE	@_FIRSTNAME							nvarchar(32)
	DECLARE	@_MIDDLENAME						nvarchar(32)
	DECLARE	@_BEF_CONTACT_MAN_NAME				varchar(200)
	DECLARE	@_AFT_CONTACT_MAN_NAME				varchar(200)
	
	-- Получим значение до обноления
	/*********************************************/	
	SELECT	@_BEF_CONTACT_MAN_NAME			=	ISNULL(UPD.LastName, '')  +
												' '	+
												ISNULL(UPD.FirstName, '') +
												' ' +
												ISNULL(UPD.MiddleName, '')
	FROM	DELETED AS UPD
	/*********************************************/	

	-- Получим значение после обноления
	/*********************************************/		
	SELECT	@_LASTNAME				=			ISNULL(UPD.LastName, ''),
			@_FIRSTNAME				=			ISNULL(UPD.FirstName, ''),
			@_MIDDLENAME			=			ISNULL(UPD.MiddleName, ''),
			@_ID_CONTACT_MAN		=			CRM_ID			
	FROM	INSERTED AS UPD
	/*********************************************/	
	SET		@_AFT_CONTACT_MAN_NAME	= @_LASTNAME + ' ' + @_FIRSTNAME + ' ' + @_MIDDLENAME		
	
	IF(@_BEF_CONTACT_MAN_NAME = @_AFT_CONTACT_MAN_NAME) RETURN	
	BEGIN	
		--Получаем имя запущеного триггера
		/*********************************************/
		DECLARE		@S			varchar(100)
		DECLARE		@K			int
		SET			@K		=	(@@PROCID)
		SELECT		@S		=	[name] 
		FROM		sysobjects 
		WHERE		[id]	=	@K
		/*********************************************/
		execute [CBaseCRM_Fresh].[dbo]._log 'Start', @S

		IF(@_ID_CONTACT_MAN IS NULL)
		BEGIN
		   execute [CBaseCRM_Fresh].[dbo]._log 'обновления контакта не произошло @_ID_CONTACT_MAN', @_ID_CONTACT_MAN 
		   RETURN
		END
		--Отключаем Триггер в CRM
		/*********************************************/
		ALTER TABLE [CBaseCRM_Fresh].[dbo].[LIST_CONTACT_MAN]
		DISABLE TRIGGER ALL
		/*********************************************/

		--execute [CBaseCRM_Fresh].[dbo]._log '@_BEF_CONTACT_MAN_NAME', @_BEF_CONTACT_MAN_NAME
		--execute [CBaseCRM_Fresh].[dbo]._log '@_AFT_CONTACT_MAN_NAME', @_BEF_CONTACT_MAN_NAME

		UPDATE
		TOP (1)	[CBaseCRM_Fresh].[dbo].[LIST_CONTACT_MAN]
		SET		NAME_PART						=		@_FIRSTNAME,
				OTCH_PART						=		@_MIDDLENAME,
				FAM_PART						=		@_LASTNAME,
				CONTACT_MAN_NAME				=		@_AFT_CONTACT_MAN_NAME		
		WHERE	ID_CONTACT_MAN					=		@_ID_CONTACT_MAN
				
		/*********************************************/

		--Включение триггера CRM
		/*********************************************/
		ALTER TABLE [CBaseCRM_Fresh].[dbo].[LIST_CONTACT_MAN]
		ENABLE TRIGGER ALL
		/*********************************************/
		
		execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S
	END
END
GO