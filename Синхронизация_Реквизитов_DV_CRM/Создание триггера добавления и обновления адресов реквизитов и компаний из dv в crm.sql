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
IF OBJECT_ID(N'DV_CRM_Upd_Address', 'TR') IS NOT NULL
DROP TRIGGER DV_CRM_Upd_Address
GO
/*********************************************/

--Добавляем триггер. Обновления  телефона в DV при добовление в CRM.
/*********************************************/
CREATE TRIGGER	DV_CRM_Upd_Address
ON				[dvtable_{1de3032f-1956-4c37-ae14-a29f8b47e0ac}]
AFTER UPDATE
/*********************************************/
AS
IF (UPDATE([Address]) OR UPDATE(ZipCode) OR UPDATE(City))
BEGIN
	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON
	
	DECLARE		@_BEF_Address					nvarchar(1024)
	DECLARE		@_BEF_ZipCode					nvarchar(32)
	DECLARE		@_BEF_City						nvarchar(128)
	DECLARE		@_AFT_Address					nvarchar(1024)
	DECLARE		@_AFT_ZipCode					nvarchar(32)
	DECLARE		@_AFT_City						nvarchar(128)
	
	-- Получим значение до обноления
	/*********************************************/		
	SELECT	@_BEF_Address				=		UPD.[Address],
			@_BEF_ZipCode				=		UPD.ZipCode,
			@_BEF_City					=		UPD.City					
	FROM	DELETED AS UPD
	/*********************************************/	
	  	
	--Заполняем переменные после добавленния значения.	
	/*********************************************/
	SELECT	@_AFT_Address				=		UPD.[Address],
			@_AFT_ZipCode				=		UPD.ZipCode,
			@_AFT_City					=		UPD.City					
	FROM	INSERTED AS UPD
	/*********************************************/

	IF	(	ISNULL(@_BEF_Address, '')	=	ISNULL(@_AFT_Address, '')
	AND		ISNULL(@_BEF_ZipCode, '')	=	ISNULL(@_AFT_ZipCode, '')
	AND		ISNULL(@_AFT_City, '')		=	ISNULL(@_AFT_City, '')
		) RETURN

	--execute [CBaseCRM_Fresh].[dbo]._log '@_BEF_Address', @_BEF_Address
	--execute [CBaseCRM_Fresh].[dbo]._log '@_BEF_ZipCode', @_BEF_ZipCode
	--execute [CBaseCRM_Fresh].[dbo]._log '@_BEF_City', @_BEF_City
	--execute [CBaseCRM_Fresh].[dbo]._log '@_AFT_Address', @_AFT_Address
	--execute [CBaseCRM_Fresh].[dbo]._log '@_AFT_ZipCode', @_AFT_ZipCode
	--execute [CBaseCRM_Fresh].[dbo]._log '@_AFT_City', @_AFT_City

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
	--execute [CBaseCRM_Fresh].[dbo]._log '', 'Запуск триггера обновление тел.'
	-- Очистим лог
	/*********************************************/
	--DELETE		[CBaseCRM_Fresh].[dbo].[Log]
	/*********************************************/
	
	--Переменные добавленного значения должность
	/*********************************************/
	DECLARE		@_DV_ID_COMPANY					uniqueidentifier
	DECLARE		@_ID_COMPANY					int	
	DECLARE		@_ADDRESS_TYPE					int
	DECLARE		@_COUNT							int
	/*********************************************/
	
	--Заполняем переменные добавленным значениями.
	/*********************************************/
	SELECT 
	TOP 1		@_DV_ID_COMPANY			=		INS.ParentRowID,
				@_ADDRESS_TYPE			=		INS.AddressType
	FROM		INSERTED as INS;
	
	SELECT
	TOP 1		@_ID_COMPANY			=		[Telex]
	FROM		[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
	WHERE		RowID					=		@_DV_ID_COMPANY
	/*********************************************/
	
	--execute [CBaseCRM_Fresh].[dbo]._log '@_DV_ID_COMPANY', @_DV_ID_COMPANY
	--execute [CBaseCRM_Fresh].[dbo]._log '@_ID_COMPANY', @_ID_COMPANY
	
	/*********************************************/
	SELECT		@_COUNT					=		COUNT(ID_COMPANY)
	FROM		[CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
	WHERE		ID_COMPANY				=		@_ID_COMPANY				
	/*********************************************/
	
	--execute [CBaseCRM_Fresh].[dbo]._log '@_COUNT', @_COUNT
	
	 --Отключаем Триггер в DV
	/*********************************************/
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
	DISABLE TRIGGER ALL

	ALTER TABLE [CBaseCRM_Fresh].[dbo].[COMPANY]
	DISABLE TRIGGER ALL
	/*********************************************/	
	
	--Если нет реквизитов добавляем по умолчанию добовляем их.
	/*********************************************/
	IF(@_COUNT = 0)
	BEGIN
		INSERT INTO	[CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
				(
				ID_COMPANY,
				USE_DEFAULT
				) 
		VALUES	(
				@_ID_COMPANY,
				1
				) 	
	END
	/*********************************************/		
	IF(@_COUNT = 1)
	BEGIN
		IF(@_ADDRESS_TYPE = 1)
		BEGIN
			--Обновляем существующие почтовый адресс
			/*********************************************/	
			UPDATE
			TOP (1)		[CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
			SET			POCHT_ADR				=		UPD.[Address]
			FROM		INSERTED AS UPD
			WHERE		ID_COMPANY 				=		@_ID_COMPANY			
			/*********************************************/
		END
		IF(@_ADDRESS_TYPE = 2)
		BEGIN
			--Обновляем существующие почтовый адресс
			/*********************************************/	
			UPDATE
			TOP (1)		[CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
			SET			ADRES_YUR				=		UPD.[Address]
			FROM		INSERTED AS UPD
			WHERE		ID_COMPANY 				=		@_ID_COMPANY			
			/*********************************************/
		END
		IF(@_ADDRESS_TYPE = 0)
		BEGIN
			--Обновляем существующие почтовый адресс
			/*********************************************/	
			UPDATE
			TOP (1)		[CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
			SET			ADRES_FACT				=		UPD.[Address]
			FROM		INSERTED AS UPD
			WHERE		ID_COMPANY 				=		@_ID_COMPANY
			/*********************************************/			
		END
	END
	ELSE
	BEGIN
		IF(@_ADDRESS_TYPE = 1)
		BEGIN
			--Обновляем существующие почтовый адресс
			/*********************************************/	
			UPDATE
			TOP (1)		[CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
			SET			POCHT_ADR				=		UPD.[Address]
			FROM		INSERTED AS UPD
			WHERE		ID_COMPANY 				=		@_ID_COMPANY
			AND			USE_DEFAULT				=		'True'		
			/*********************************************/
		END
		IF(@_ADDRESS_TYPE = 2)
		BEGIN
			--Обновляем существующие почтовый адресс
			/*********************************************/	
			UPDATE
			TOP (1)		[CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
			SET			ADRES_YUR				=		UPD.[Address]
			FROM		INSERTED AS UPD
			WHERE		ID_COMPANY 				=		@_ID_COMPANY
			AND			USE_DEFAULT				=		'True'
			/*********************************************/
		END
		IF(@_ADDRESS_TYPE = 0)
		BEGIN
			--Обновляем существующие почтовый адресс
			/*********************************************/	
			UPDATE
			TOP (1)		[CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
			SET			ADRES_FACT				=		UPD.[Address]
			FROM		INSERTED AS UPD
			WHERE		ID_COMPANY 				=		@_ID_COMPANY
			AND			USE_DEFAULT				=		'True'
			/*********************************************/
		END
	END
	IF(@_ADDRESS_TYPE = 0)
	BEGIN
		--Обновляем адрес компании
		/*********************************************/	
		UPDATE
		TOP (1)		[CBaseCRM_Fresh].[dbo].[COMPANY]
		SET			ADRES				=		ISNULL(UPD.ZipCode, '') + ' ' + ISNULL(UPD.City, '') + ' ' + ISNULL(UPD.[Address], '')
		FROM		INSERTED AS UPD
		WHERE		ID_COMPANY 				=		@_ID_COMPANY
		/*********************************************/
	END
	--Включаем Триггер в CRM
	/*********************************************/		
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
	ENABLE TRIGGER ALL
	
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[COMPANY]
	ENABLE TRIGGER ALL
	/*********************************************/

	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S
END