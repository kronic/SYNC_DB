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
IF OBJECT_ID(N'DV_CRM_Upd_Position', 'TR') IS NOT NULL
DROP TRIGGER DV_CRM_Upd_Position
GO
/*********************************************/

--Добавляем триггер. Обновления  телефона в DV при добовление в CRM.
/*********************************************/
CREATE TRIGGER	DV_CRM_Upd_Position
ON				[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}]
AFTER UPDATE   
/*********************************************/
AS
IF(UPDATE(Position))
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON			
	--Очистим лог
	/*********************************************/
	--DELETE		[CBaseCRM_Fresh].[dbo].[Log]
	/*********************************************/

	--Переменные добавленного значения должность
	/*********************************************/
	DECLARE		@_DV_ID_COMPANY					uniqueidentifier
	DECLARE		@_BEF_DV_ID_POSITION			uniqueidentifier
	DECLARE		@_AFT_DV_ID_POSITION			uniqueidentifier
	DECLARE		@_ID_CONTACT_MAN				int
	DECLARE		@_POSITION						nvarchar(128)	
	/*********************************************/

	-- Получим значение до обноления
	/*********************************************/		
	SELECT		@_BEF_DV_ID_POSITION	=		UPD.Position
	FROM		DELETED AS UPD
	/*********************************************/	
	  	
	--Заполняем переменные после добавленния значения.	
	/*********************************************/
	SELECT 
	TOP 1		@_ID_CONTACT_MAN		=		UPD.CRM_ID,
				@_AFT_DV_ID_POSITION	=		UPD.Position
	FROM		INSERTED as UPD;
	/*********************************************/		
		
	IF(			@_BEF_DV_ID_POSITION	=		@_AFT_DV_ID_POSITION 
	OR			@_AFT_DV_ID_POSITION	IS		NULL) 
	RETURN
	
	--Заполняем переменную должность
	/*********************************************/
	SELECT		
	TOP 1		@_POSITION			=		Name
	FROM		[dvtable_{bdafe82a-04fa-4391-98b7-5df6502e03dd}]
	WHERE		RowID					=		@_AFT_DV_ID_POSITION
	/*********************************************/
	--execute [CBaseCRM_Fresh].[dbo]._log '@_BEF_POSITION', @_BEF_POSITION
	--execute [CBaseCRM_Fresh].[dbo]._log '@_AFT_POSITION', @_AFT_POSITION
	
	IF(@_POSITION IS NULL OR @_POSITION	= '') RETURN
	
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
	--execute [CBaseCRM_Fresh].[dbo]._log '', 'Запуск триггера обновление должности'
	--execute [CBaseCRM_Fresh].[dbo]._log '@_DV_ID_POSITION', @_DV_ID_POSITION
	--execute [CBaseCRM_Fresh].[dbo]._log '@_POSITION', @_AFT_POSITION		
	--execute [CBaseCRM_Fresh].[dbo]._log '@_ID_CONTACT_MAN', @_ID_CONTACT_MAN
	--Отключаем Триггер в CRM
	/*********************************************/
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[LIST_CONTACT_MAN]
	DISABLE TRIGGER ALL
	/*********************************************/

	/*********************************************/
	UPDATE
	TOP(1)	[CBaseCRM_Fresh].[dbo].[LIST_CONTACT_MAN]
	SET		DISCRIPTION_CONTACT_MAN		=		@_POSITION
	WHERE	ID_CONTACT_MAN				=		@_ID_CONTACT_MAN
	/*********************************************/		

	--Включаем Триггер в CRM
	/*********************************************/
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[LIST_CONTACT_MAN]
	ENABLE TRIGGER ALL
	/*********************************************/
execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S
END
