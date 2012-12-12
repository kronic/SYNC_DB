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
IF object_id(N'UPD_CRM_DV_LIST_CONTACT_MAN') IS NOT NULL
DROP TRIGGER UPD_CRM_DV_LIST_CONTACT_MAN
GO
/*********************************************/

--Добавляем триггер. добовления  контактов в DV при добовление в CRM.
/*********************************************/
CREATE TRIGGER UPD_CRM_DV_LIST_CONTACT_MAN
   ON LIST_CONTACT_MAN
   AFTER UPDATE, INSERT
/*********************************************/
AS
IF(UPDATE(NAME_PART) OR UPDATE(OTCH_PART) OR UPDATE(FAM_PART)) 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	
	SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
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
		
	-- Очистим лог
	/*********************************************/
	--DELETE [dbo].[Log]
	/*********************************************/	  
	
	--Переменные добавленного значения
	/*********************************************/
	DECLARE		@_NAME_PART							varchar(100)
	DECLARE		@_OTCH_PART							varchar(100)
	DECLARE		@_FAM_PART							varchar(100)		
	/*********************************************/

	--Заполняем переменные значениями
	/*********************************************/
	SELECT 
	TOP 1		@_NAME_PART					=  		INS.NAME_PART, 
				@_OTCH_PART					=		INS.OTCH_PART, 
				@_FAM_PART					=		INS.FAM_PART				
	FROM		INSERTED as INS;
	/*********************************************/
	--execute _log '@_ID_CONTACT_MAN_INS', @_ID_CONTACT_MAN_INS	
	
		
	--Приводим к виду DV
	/*********************************************/
	DECLARE		@_DV_NAME_PART						nvarchar(32)
	DECLARE		@_DV_OTCH_PART						nvarchar(32)
	DECLARE		@_DV_FAM_PART						nvarchar(32)
	SET			@_DV_NAME_PART				=		LEFT(@_NAME_PART, 32)
	SET			@_DV_OTCH_PART				=		LEFT(@_OTCH_PART, 32)
	SET			@_DV_FAM_PART				=		LEFT(@_FAM_PART, 32)
	/*********************************************/	
	
	--execute _log '@_ID_CONTACT_MAN_INS', @_ID_CONTACT_MAN_INS

	--Отключаем Триггер в DV
	/*********************************************/
	ALTER TABLE Copy_DV.[dbo].[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}] 
	DISABLE TRIGGER ALL
	/*********************************************/	

	UPDATE
	TOP(1)		Copy_DV.[dbo].[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}]
	SET			FirstName					=		@_DV_NAME_PART,
				MiddleName					=		@_DV_OTCH_PART,
				LastName					=		@_DV_FAM_PART
	FROM		INSERTED AS UPD
	WHERE		CRM_ID						=		UPD.ID_CONTACT_MAN

	--Включаем Триггер в DV
	/*********************************************/
	ALTER TABLE Copy_DV.[dbo].[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}] 
	ENABLE TRIGGER ALL
	/*********************************************/	
	
	--Обновляем время в dv для поевления объекта
	/*********************************************/		
	UPDATE [Copy_DV].[dbo].[dvsys_instances_date]
	SET  [ChangeDateTime] = CURRENT_TIMESTAMP
	WHERE [InstanceID] = N'65FF9382-17DC-4E9F-8E93-84D6D3D8FE8C'				
	/*********************************************/	
	--если ошибка откат транзакции
	/*********************************************/	
	IF @@ERROR != 0
	BEGIN		
		execute [CBaseCRM_Fresh].[dbo]._log 'ERROR TRAN = ', @S
		ROLLBACK TRANSACTION
		RETURN
	END
	/*********************************************/	
	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S	
	--комитим транзакцию
	/*********************************************/	
	COMMIT TRAN tr1
	/*********************************************/	
END
GO