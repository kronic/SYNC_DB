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
IF object_id('CRM_DV_ADRES_YUR', 'TR') IS NOT NULL
DROP TRIGGER CRM_DV_ADRES_YUR
GO
/*********************************************/

--Добавляем триггер. добовления  контактов в DV при добовление в CRM.
/*********************************************/
CREATE TRIGGER CRM_DV_ADRES_YUR
   ON [dbo].[LIST_REQUIS_COMPANY]
   AFTER INSERT, UPDATE
/*********************************************/
AS
IF(UPDATE(ADRES_YUR))
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
	SET NOCOUNT ON;
	
	--Переменные
	/*********************************************/
	DECLARE		@_ID_COMPANY				int
	DECLARE		@_ADRES_YUR					varchar(200) -- DV type nvarchar(1024) привод типа и длинны не нужен
	DECLARE		@_DV_ID_COMPANY				uniqueidentifier
	DECLARE		@_COUNT_REQ					int
	DECLARE		@_USE_DEFAULT				varchar(10)
	/*********************************************/
	
	--Заполняем переменные значениями
	/*********************************************/
	SELECT		@_ID_COMPANY		=		INS.ID_COMPANY,				
				@_ADRES_YUR			=		INS.ADRES_YUR,
				@_USE_DEFAULT		=		INS.USE_DEFAULT
	FROM		INSERTED AS INS
	
	SELECT		@_COUNT_REQ = COUNT(ID_COMPANY)
	FROM		[LIST_REQUIS_COMPANY]
	WHERE		ID_COMPANY			=		@_ID_COMPANY	
	
	
	IF(@_USE_DEFAULT != 'True' AND @_COUNT_REQ > 1 )
	BEGIN
		execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S
		RETURN
	END

	SELECT		
	TOP 1		@_DV_ID_COMPANY		=		RowID
	FROM		[Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
	WHERE		Telex = @_ID_COMPANY
	/*********************************************/
	
	--Добовляем почтовый адрес
	/*********************************************/
	IF(@_ADRES_YUR IS NOT NULL AND @_ADRES_YUR != '' AND @_DV_ID_COMPANY IS NOT NULL)
	BEGIN
		
		--Проверем наличие адеса
		DECLARE			@_DV_ID_ADRES				uniqueidentifier
		
		SELECT			@_DV_ID_ADRES			=	[RowID]
		FROM			[Copy_DV].[dbo].[dvtable_{1de3032f-1956-4c37-ae14-a29f8b47e0ac}]
		WHERE			[ParentRowID]			=	@_DV_ID_COMPANY
		AND				[AddressType]			=	2

		IF(@_DV_ID_ADRES IS NULL)
		BEGIN
			--Константы
			/*********************************************/
			DECLARE		@CONST_SDID					uniqueidentifier
			DECLARE		@CONST_InstanceID			uniqueidentifier
			DECLARE		@CONST_ParentTreeRowID		uniqueidentifier
			SET			@CONST_SDID				=	'{8F51A892-10C4-4723-9EEA-B93DA63414C1}'
			SET			@CONST_InstanceID		=	'{65FF9382-17DC-4E9F-8E93-84D6D3D8FE8C}'
			SET			@CONST_ParentTreeRowID	=	'{00000000-0000-0000-0000-000000000000}'
			/*********************************************/

			--Новый Ключ
			/*********************************************/
			DECLARE		@NEW_RowID					uniqueidentifier
			SET			@NEW_RowID				=	NEWID()
			/*********************************************/

			INSERT INTO [Copy_DV].[dbo].[dvtable_{1de3032f-1956-4c37-ae14-a29f8b47e0ac}]
						(
						[RowID],
						[SDID],
						[InstanceID],
						[ParentRowID],
						[ParentTreeRowID],
						[AddressType],
						[Address]
						)
			VALUES
						(
						@NEW_RowID,				--RowID
						@CONST_SDID,			--SDID
						@CONST_InstanceID,		--InstanceID
						@_DV_ID_COMPANY,
						@CONST_ParentTreeRowID,
						2,
						@_ADRES_YUR
						)
		END
		ELSE
		BEGIN
			--Отключаем Триггер в CRM
			/*********************************************/
			ALTER TABLE [Copy_DV].[dbo].[dvtable_{1de3032f-1956-4c37-ae14-a29f8b47e0ac}]
			DISABLE TRIGGER [DV_CRM_Upd_Address]
			/*********************************************/	

			UPDATE		[Copy_DV].[dbo].[dvtable_{1de3032f-1956-4c37-ae14-a29f8b47e0ac}]
			SET			[Address]				=	@_ADRES_YUR
			WHERE		[ParentRowID]			=	@_DV_ID_COMPANY
			AND			[AddressType]			=	2

			--Включаем Триггер в CRM
			/*********************************************/		
			ALTER TABLE [Copy_DV].[dbo].[dvtable_{1de3032f-1956-4c37-ae14-a29f8b47e0ac}]
			ENABLE TRIGGER [DV_CRM_Upd_Address]
			/*********************************************/	
		END
	END		
	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S
END