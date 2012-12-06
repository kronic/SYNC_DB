USE [CBaseCRM_Fresh]
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET CONCAT_NULL_YIELDS_NULL ON;
GO
-- =============================================
-- Author:		���� ��������
-- Create date: 14.11.2012
-- Description:	������� ������� ������� �� ���������� email � DV �� CRM.
-- ���������� �������� ��� Copy_DV �� ��� ���� DV. 
-- =============================================

--������� ������� ���� �� ����������.
/*********************************************/
IF object_id('CRM_DV_FORM_ADRES', 'TR') IS NOT NULL
DROP TRIGGER CRM_DV_FORM_ADRES
GO
/*********************************************/

--��������� �������. ����������  ��������� � DV ��� ���������� � CRM.
/*********************************************/
CREATE TRIGGER CRM_DV_FORM_ADRES
   ON [dbo].[COMPANY]
   AFTER UPDATE, INSERT
/*********************************************/
AS
IF(UPDATE(ADRES))
BEGIN
	--�������� ��� ����������� ��������
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
	
	--����������
	/*********************************************/
	DECLARE		@_ID_COMPANY				int
	DECLARE		@_ADRES						varchar(200) -- DV type nvarchar(1024) ������ ���� � ������ �� �����
	DECLARE		@_DV_ID_COMPANY				uniqueidentifier
	/*********************************************/
	
	--��������� ���������� ����������
	/*********************************************/
	SELECT		@_ID_COMPANY		=		INS.ID_COMPANY,				
				@_ADRES				=		INS.ADRES
	FROM		INSERTED AS INS
	
	SELECT		
	TOP 1		@_DV_ID_COMPANY		=		RowID
	FROM		[Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
	WHERE		Telex = @_ID_COMPANY
	/*********************************************/
	
	--��������� �������� �����
	/*********************************************/
	IF(@_ADRES IS NOT NULL AND @_ADRES != '' AND @_DV_ID_COMPANY IS NOT NULL)
	BEGIN
		
		--�������� ������� �����
		DECLARE			@_DV_ID_ADRES				uniqueidentifier
		
		SELECT			@_DV_ID_ADRES			=	[RowID]
		FROM			[Copy_DV].[dbo].[dvtable_{1de3032f-1956-4c37-ae14-a29f8b47e0ac}]
		WHERE			[ParentRowID]			=	@_DV_ID_COMPANY
		AND				[AddressType]			=	0

		IF(@_DV_ID_ADRES IS NULL)
		BEGIN
			--���������
			/*********************************************/
			DECLARE		@CONST_SDID					uniqueidentifier
			DECLARE		@CONST_InstanceID			uniqueidentifier
			DECLARE		@CONST_ParentTreeRowID		uniqueidentifier
			SET			@CONST_SDID				=	'{8F51A892-10C4-4723-9EEA-B93DA63414C1}'
			SET			@CONST_InstanceID		=	'{65FF9382-17DC-4E9F-8E93-84D6D3D8FE8C}'
			SET			@CONST_ParentTreeRowID	=	'{00000000-0000-0000-0000-000000000000}'
			/*********************************************/

			--����� ����
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
						0,
						@_ADRES
						)
		END
		ELSE
		BEGIN
			--��������� ������� � CRM
			/*********************************************/
			ALTER TABLE [Copy_DV].[dbo].[dvtable_{1de3032f-1956-4c37-ae14-a29f8b47e0ac}]
			DISABLE TRIGGER ALL
			/*********************************************/	

			UPDATE
			TOP (1)		[Copy_DV].[dbo].[dvtable_{1de3032f-1956-4c37-ae14-a29f8b47e0ac}]
			SET			[Address]				=	@_ADRES
			WHERE		[ParentRowID]			=	@_DV_ID_COMPANY
			AND			[AddressType]			=	0

			--�������� ������� � CRM
			/*********************************************/		
			ALTER TABLE [Copy_DV].[dbo].[dvtable_{1de3032f-1956-4c37-ae14-a29f8b47e0ac}]
			ENABLE TRIGGER ALL
			/*********************************************/	
		END
	END		
	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S
END