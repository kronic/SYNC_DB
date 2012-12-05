USE [Copy_DV]
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET CONCAT_NULL_YIELDS_NULL ON;
GO
-- =============================================
-- Author:		���� ��������
-- Create date: 14.11.2012
-- Description:	������� ������� ������� �� ���������� ���������� ������ �� DV � CRM.
-- ���������� �������� ��� Copy_DV �� ��� ���� DV.
-- =============================================

--������� ������� ���� �� ����������.
/*********************************************/
IF OBJECT_ID(N'DV_CRM_Upd_Req_GL_BUH', 'TR') IS NOT NULL
DROP TRIGGER DV_CRM_Upd_Req_GL_BUH
GO
/*********************************************/

--��������� �������. ����������  �������� � DV ��� ���������� � CRM.
/*********************************************/
CREATE TRIGGER	DV_CRM_Upd_Req_GL_BUH
ON				[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
AFTER UPDATE
/*********************************************/
AS
IF UPDATE(ChiefAccountant)
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
	SET NOCOUNT ON
	--execute [CBaseCRM_Fresh].[dbo]._log '', '������ �������� ���������� ���.'
	-- ������� ���
	/*********************************************/
	--DELETE		[CBaseCRM_Fresh].[dbo].[Log]
	/*********************************************/
	
	--���������� ������������ �������� ���������
	/*********************************************/
	DECLARE		@_DV_ID_CHIEFACCOUNTANT			uniqueidentifier
	DECLARE		@_ID_COMPANY					int	
	DECLARE		@_FirstName						nvarchar(32)
	DECLARE		@_LastName						nvarchar(32)
	DECLARE		@_MiddleName					nvarchar(32)
	DECLARE		@_COUNT							int
	/*********************************************/
	
	--��������� ���������� ����������� ����������.
	/*********************************************/
	SELECT
	TOP 1		@_DV_ID_CHIEFACCOUNTANT	=		INS.ChiefAccountant,
				@_ID_COMPANY			=		INS.Telex				
	FROM		INSERTED as INS;

	SELECT
	TOP 1		@_FirstName				=		ISNULL(FirstName, ''),
				@_LastName				=		ISNULL(LastName , ''),
				@_MiddleName			=		ISNULL(MiddleName,'')
	FROM		[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}]
	WHERE		RowID					=		@_DV_ID_CHIEFACCOUNTANT
	/*********************************************/
	
	--execute [CBaseCRM_Fresh].[dbo]._log '@_DV_ID_COMPANY', @_DV_ID_COMPANY
	--execute [CBaseCRM_Fresh].[dbo]._log '@_ID_COMPANY', @_ID_COMPANY
	
	/*********************************************/
	SELECT		@_COUNT					=		COUNT(ID_COMPANY)
	FROM		[CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
	WHERE		ID_COMPANY				=		@_ID_COMPANY					
	/*********************************************/
	
	--execute [CBaseCRM_Fresh].[dbo]._log '@_COUNT', @_COUNT
	
	--���� ��� ���������� ��������� �� ��������� ��������� ��.
	/*********************************************/
	
	--��������� ������� � DV
	/*********************************************/
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
	DISABLE TRIGGER ALL
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
		
		--��������� ������������ �������� ������
		/*********************************************/	
		UPDATE		[CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
		SET			GL_BUH					=		@_LastName + ' ' + @_FirstName + ' ' + @_MiddleName
		WHERE		ID_COMPANY 				=		@_ID_COMPANY			
		/*********************************************/					
	END
	ELSE
	BEGIN
		
		--��������� ������������ �������� ������
		/*********************************************/	
		UPDATE		[CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
		SET			GL_BUH					=		@_LastName + ' ' + @_FirstName + ' ' + @_MiddleName
		WHERE		ID_COMPANY 				=		@_ID_COMPANY
		AND			USE_DEFAULT				=		'True'		
		/*********************************************/	 
	END

	--�������� ������� � CRM
	/*********************************************/		
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
	ENABLE TRIGGER ALL
	/*********************************************/	

	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S	
END