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
IF object_id('CRM_DV_VID_COMPANY', 'TR') IS NOT NULL
DROP TRIGGER CRM_DV_VID_COMPANY
GO
/*********************************************/

--Добавляем триггер. добовления  контактов в DV при добовление в CRM.
/*********************************************/
CREATE TRIGGER CRM_DV_VID_COMPANY
   ON [dbo].[COMPANY]
   AFTER UPDATE
/*********************************************/
AS
IF(UPDATE(ID_VID_COMPANY))
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		
	--Переменные
	/*********************************************/
	DECLARE		@_ID_COMPANY				int
	DECLARE     @_ID_VID_COMPANY			int
	/*********************************************/	  	

	--Заполняем переменные значениями
	/*********************************************/
	SELECT		@_ID_COMPANY		=		INS.ID_COMPANY,				
				@_ID_VID_COMPANY	=		INS.ID_VID_COMPANY
	FROM		INSERTED AS INS
	/*********************************************/
	IF(@_ID_VID_COMPANY IS NULL) RETURN
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

	--execute [CBaseCRM_Fresh].[dbo]._log '@_ID_VID_COMPANY', @_ID_VID_COMPANY		
	--Отключаем Триггер в CRM
	/*********************************************/
	ALTER TABLE [Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
	DISABLE TRIGGER ALL
	/*********************************************/
	IF(@_ID_VID_COMPANY = 15)
	BEGIN
		UPDATE
		TOP (1)		[Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
		SET			[IsVendor]						=		1,
					[IsClient]						=		0
		WHERE		[Telex]							=		@_ID_COMPANY
	END
	ELSE IF(@_ID_VID_COMPANY = 15)
	BEGIN
		UPDATE
		TOP (1)		[Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
		SET			[IsVendor]						=		0,
					[IsClient]						=		0
		WHERE		[Telex]							=		@_ID_COMPANY
	END
	ELSE
	BEGIN
		UPDATE
		TOP (1)		[Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
		SET			[IsClient]						=		1,
					[IsVendor]						=		0
		WHERE		[Telex]							=		@_ID_COMPANY	
	END

	--Включаем Триггер в CRM
	/*********************************************/		
	ALTER TABLE [Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
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