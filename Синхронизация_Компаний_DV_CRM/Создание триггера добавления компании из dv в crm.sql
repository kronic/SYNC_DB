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
IF object_id(N'DV_CRM_Ins_Add_Company') IS NOT NULL
DROP TRIGGER DV_CRM_Ins_Add_Company
GO
/*********************************************/

--Добавляем триггер. добовления  контактов в DV при добовление в CRM.
/*********************************************/
CREATE TRIGGER DV_CRM_Ins_Add_Company
   ON [dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
AFTER INSERT
/*********************************************/
AS 
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
	--DELETE [CBaseCRM_Fresh].[dbo].[Log]
	/*********************************************/

	--Новый Ключ
	/*********************************************/
	DECLARE		@_NEW_ID_COMPANY					int			
	/*********************************************/	

	--Переменные добавленного значения должность
	/*********************************************/
	DECLARE		@_DV_ID_COMPANY					uniqueidentifier
	DECLARE		@_ID_COMPANY					int
	/*********************************************/
		
	--Заполняем переменные значениями добавленным значение.
	/*********************************************/
	SELECT 
	TOP 1		@_DV_ID_COMPANY			=		INS.RowID				
	FROM		INSERTED as INS
	/*********************************************/
	
	--Отключаем Триггер в CRM
	/*********************************************/
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[COMPANY]
	DISABLE TRIGGER ALL
	/*********************************************/
	--EXECUTE [CBaseCRM_Fresh].[dbo]._log '@_DV_ID_COMPANY', @_DV_ID_COMPANY	
	--Добовляем запись в crm.
	/*********************************************/
	INSERT INTO	[CBaseCRM_Fresh].[dbo].[COMPANY]
			(
				DV_ID
			) 
	VALUES	(
				@_DV_ID_COMPANY
			)
	/*********************************************/


	--Записываем в переменную значение нового ключа добавленного в CRM
	/*********************************************/
	SET			@_NEW_ID_COMPANY		=		@@IDENTITY
	--EXECUTE [CBaseCRM_Fresh].[dbo]._log '@_NEW_ID_COMPANY', @_NEW_ID_COMPANY
	/*********************************************/
	
	--Включение триггера CRM
	/*********************************************/
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[COMPANY]
	ENABLE TRIGGER ALL
	/*********************************************/
	EXECUTE [CBaseCRM_Fresh].[dbo]._log '@_DV_ID_COMPANY', @_DV_ID_COMPANY
	EXECUTE [CBaseCRM_Fresh].[dbo]._log '@_NEW_ID_COMPANY', @_NEW_ID_COMPANY
	
	--Запишем ключ контакта crm в dv
	/*********************************************/
	UPDATE 
	TOP (1)	[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
	SET		Telex						=		@_NEW_ID_COMPANY		
	WHERE	RowID						=		@_DV_ID_COMPANY	
	/*********************************************/


	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S
END