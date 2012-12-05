USE [CBaseCRM_Fresh]
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Иван Берлинец
-- Create date: 14.11.2012
-- Description:	Скрипит создает триггер на добавления email в DV из CRM.
-- Необходимо заминить имя Copy_DV на имя базы DV. 
-- =============================================

--Удаляем триггер если он существует.
/*********************************************/
IF object_id(N'CRM_DV_LIST_EMAIL_CLIENT') IS NOT NULL
DROP TRIGGER CRM_DV_LIST_EMAIL_CLIENT
GO
/*********************************************/

--Добавляем триггер. добовления  контактов в DV при добовление в CRM.
/*********************************************/
CREATE TRIGGER CRM_DV_LIST_EMAIL_CLIENT
   ON LIST_EMAIL_CLIENT
   AFTER INSERT, UPDATE
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
	--DELETE [dbo].[Log]
	/*********************************************/
	
	--Объявляем пременные
	/*********************************************/
	DECLARE     @_ID_COMPANY				int
	DECLARE		@_ID_CONTACT_MAN_INS		int
	DECLARE		@_EMAIL_INS					varchar(50) 
	DECLARE		@_EMAIL_MIN					varchar(50) 
	DECLARE		@_EMAIL						varchar(50) -- DV type varchar(64) привод типа и длинны не нужен	
	/*********************************************/
	
	--Заполняем переменные значениями
	/*********************************************/
	SELECT 
	TOP 1		@_ID_COMPANY					=		INS.ID_COMPANY,
				@_ID_CONTACT_MAN_INS			=		INS.ID_CONTACT_MAN,
				@_EMAIL_INS						=		INS.email
	FROM		INSERTED as INS;
	/*********************************************/
			
	--Заполняем переменную самым коротким email
	/*********************************************/
	SELECT		
	TOP 1		@_EMAIL_MIN						=		 MIN(dbo.LIST_EMAIL_CLIENT.email)
	FROM		LIST_CONTACT_MAN 
	INNER JOIN	LIST_EMAIL_CLIENT 
	ON			LIST_CONTACT_MAN.ID_CONTACT_MAN =		LIST_EMAIL_CLIENT.ID_CONTACT_MAN
	WHERE		(LIST_CONTACT_MAN.ID_CONTACT_MAN=		@_ID_CONTACT_MAN_INS)
	
	IF(DATALENGTH(@_EMAIL_INS) <=  DATALENGTH(@_EMAIL_MIN)) 
	SET			@_EMAIL							=		@_EMAIL_INS
	ELSE
	SET			@_EMAIL							=		@_EMAIL_INS
	--execute _log '@_EMAIL', @_EMAIL
	execute _log '@_ID_CONTACT_MAN_INS', @_ID_CONTACT_MAN_INS
	/*********************************************/
	
	
	--Обновляем сотв. запись в DV
	/*********************************************/
	
	IF(@_ID_CONTACT_MAN_INS != 0 AND @_ID_CONTACT_MAN_INS IS NOT NULL)
	BEGIN
		--Отключаем Триггер в DV
		/*********************************************/
		ALTER TABLE [Copy_DV].[dbo].[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}]
		DISABLE TRIGGER DV_CRM_Upd_Email
		/*********************************************/	

		UPDATE
		TOP (1)		Copy_DV.[dbo].[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}]
		SET			[Email]							=		@_EMAIL
		WHERE		CRM_ID							=		@_ID_CONTACT_MAN_INS
		AND			CRM_ID							IS		NOT NULL

		--Включаем Триггер в DV
		/*********************************************/
		ALTER TABLE [Copy_DV].[dbo].[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}]
		ENABLE TRIGGER DV_CRM_Upd_Email
		/*********************************************/	
	END
	ELSE
	BEGIN
		--Отключаем Триггер в DV
		/*********************************************/
		ALTER TABLE [Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
		DISABLE TRIGGER DV_CRM_Upd_Req_email
		/*********************************************/		
		UPDATE
		TOP (1)		Copy_DV.[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
		SET			[Email]							=		@_EMAIL_INS
		WHERE		Telex							=		@_ID_COMPANY
		--Включаем Триггер в DV
		/*********************************************/
		ALTER TABLE [Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
		ENABLE TRIGGER DV_CRM_Upd_Req_email
		/*********************************************/	
	END
	/*********************************************/
		
	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S
END
GO
