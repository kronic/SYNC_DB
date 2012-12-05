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
IF object_id('CRM_DV_FORM_SOBST_COMPANY', 'TR') IS NOT NULL
DROP TRIGGER CRM_DV_FORM_SOBST_COMPANY
GO
/*********************************************/

--Добавляем триггер. добовления  контактов в DV при добовление в CRM.
/*********************************************/
CREATE TRIGGER CRM_DV_FORM_SOBST_COMPANY
   ON [dbo].[COMPANY]
   AFTER INSERT, UPDATE
/*********************************************/
AS
IF(UPDATE(FORM_SOBST_COMPANY))
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
	DECLARE		@_FORM_SOBST_COMPANY		varchar(100) -- DV type nvarchar(128) привод типа и длинны не нужен
	/*********************************************/
	

	--Заполняем переменные значениями
	/*********************************************/
	SELECT		@_ID_COMPANY		=		INS.ID_COMPANY,				
				@_FORM_SOBST_COMPANY=		INS.FORM_SOBST_COMPANY
	FROM		INSERTED AS INS
	/*********************************************/
	
	--Ищем тип юр. лица, если не находим - добавляем
	/*********************************************/
	IF(@_FORM_SOBST_COMPANY IS NOT NULL AND @_FORM_SOBST_COMPANY != '')
	BEGIN
		DECLARE @_DV_OrgType				uniqueidentifier
		DECLARE	@_RowID						uniqueidentifier
		
		SELECT	
		TOP 1	@_RowID				=		[RowID] 
		FROM	Copy_DV.[dbo].[dvtable_{4b25da25-ace2-4205-bd28-69f80d1cf57f}] 
		WHERE	Name				=		@_FORM_SOBST_COMPANY
		--Если нет
		IF(@_RowID IS NULL)
		BEGIN
			
			--Константы
			/*********************************************/
			DECLARE		@CONST_SDID					uniqueidentifier
			DECLARE		@CONST_InstanceID			uniqueidentifier
			DECLARE		@CONST_ParentRowID			uniqueidentifier
			DECLARE		@CONST_ParentTreeRowID		uniqueidentifier
			SET			@CONST_SDID				=	'{8F51A892-10C4-4723-9EEA-B93DA63414C1}'
			SET			@CONST_InstanceID		=	'{65FF9382-17DC-4E9F-8E93-84D6D3D8FE8C}'
			SET			@CONST_ParentRowID		=	'{00000000-0000-0000-0000-000000000000}'
			SET			@CONST_ParentTreeRowID	=	'{00000000-0000-0000-0000-000000000000}'
			/*********************************************/

			--Новый Ключ
			/*********************************************/
			DECLARE		@NEW_RowID					uniqueidentifier
			SET			@NEW_RowID				=	NEWID()
			/*********************************************/

			INSERT INTO DV_Sartogosm.[dbo].[dvtable_{4b25da25-ace2-4205-bd28-69f80d1cf57f}]  
						(
						[RowID],
						[SDID],
						[InstanceID],
						[ParentRowID],
						[ParentTreeRowID],
						[Name]
						)
			VALUES
						(
						@NEW_RowID,				--RowID
						@CONST_SDID,			--SDID
						@CONST_InstanceID,		--InstanceID
						@CONST_ParentRowID,
						@CONST_ParentTreeRowID,
						@_FORM_SOBST_COMPANY	--Name				
						)
			SET			@_DV_OrgType			=	@NEW_RowID
		END
		ELSE
		BEGIN
			SET			@_DV_OrgType			=	@_RowID
		END	

		UPDATE		[Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
		SET			[OrgType]						=		@_DV_OrgType					
		WHERE		[Telex]							=		@_ID_COMPANY

	END
	/*********************************************/
	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S
END