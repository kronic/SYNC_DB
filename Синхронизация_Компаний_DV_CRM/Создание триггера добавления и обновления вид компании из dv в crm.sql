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
IF object_id(N'DV_CRM_Upd_Vid_Company') IS NOT NULL
DROP TRIGGER DV_CRM_Upd_Vid_Company
GO
/*********************************************/

--Добавляем триггер. добовления  контактов в DV при добовление в CRM.
/*********************************************/
CREATE TRIGGER DV_CRM_Upd_Vid_Company
   ON [dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
AFTER UPDATE
/*********************************************/
AS
IF(UPDATE(IsClient))
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON	
	
	DECLARE		@_BEF_IsClient					bit
	DECLARE		@_AFT_IsClient					bit

	-- Получим значение до обноления
	/*********************************************/		
	SELECT	@_BEF_IsClient				=		UPD.IsClient
	FROM	DELETED AS UPD
	/*********************************************/	
	  	
	--Заполняем переменные после добавленния значения.	
	/*********************************************/
	SELECT 
	TOP 1		@_AFT_IsClient			=		UPD.IsClient
	FROM		INSERTED as UPD;
	/*********************************************/
	
	IF(	@_BEF_IsClient	=	@_AFT_IsClient 
	OR  @_AFT_IsClient	IS	NULL 
		) RETURN

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
	
	--Отключаем Триггер в CRM
	/*********************************************/
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[COMPANY]
	DISABLE TRIGGER ALL
	/*********************************************/

	IF(@_AFT_IsClient = 1)
		BEGIN
		UPDATE
		TOP (1)	[CBaseCRM_Fresh].[dbo].[COMPANY]
		SET		ID_VID_COMPANY			=			8
		FROM	INSERTED AS UPD
		WHERE	DV_ID						=			UPD.RowID
	END
	ELSE
	BEGIN
		UPDATE	
		TOP (1)	[CBaseCRM_Fresh].[dbo].[COMPANY]
		SET		ID_VID_COMPANY				=			15
		FROM	INSERTED AS UPD
		WHERE	DV_ID						=			UPD.RowID
	END

	--Включение триггера CRM
	/*********************************************/
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[COMPANY]
	ENABLE TRIGGER ALL
	/*********************************************/

	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S	
END