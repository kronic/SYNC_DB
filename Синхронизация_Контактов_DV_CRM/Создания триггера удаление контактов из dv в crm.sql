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
IF object_id(N'DV_CRM_Del_Contact') IS NOT NULL
DROP TRIGGER DV_CRM_Del_Contact
GO
/*********************************************/

--Добавляем триггер. добовления  контактов в DV при добовление в CRM.
/*********************************************/
CREATE TRIGGER DV_CRM_Del_Contact
   ON [dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}]
   AFTER DELETE
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
	
	DECLARE		@_ID_CONTACT_MAN				int

	--Заполняем переменные значениями добавленным значение.
	/*********************************************/
	SELECT 
	TOP 1		@_ID_CONTACT_MAN		=		DEL.CRM_ID				
	FROM		DELETED as DEL;
	/*********************************************/
	IF(@_ID_CONTACT_MAN IS NULL) RETURN
	
	--Отключаем Триггер в CRM
	/*********************************************/
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[LIST_CONTACT_MAN]
	DISABLE TRIGGER ALL
	/*********************************************/	 	
									  
	DELETE	
	TOP (1)
	FROM	[CBaseCRM_Fresh].[dbo].[LIST_CONTACT_MAN]
	WHERE	ID_CONTACT_MAN				=		@_ID_CONTACT_MAN
			
	--Включение триггера CRM
	/*********************************************/
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[LIST_CONTACT_MAN]
	ENABLE TRIGGER ALL
	/*********************************************/

	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S

END
GO