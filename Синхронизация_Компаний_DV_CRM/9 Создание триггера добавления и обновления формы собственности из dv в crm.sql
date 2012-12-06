USE Copy_DV
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
IF object_id('DV_CRM_FORM_S_COMPANY', 'TR') IS NOT NULL
DROP TRIGGER DV_CRM_FORM_S_COMPANY
GO
/*********************************************/

--��������� �������. ����������  ��������� � DV ��� ���������� � CRM.
/*********************************************/
CREATE TRIGGER DV_CRM_FORM_S_COMPANY
   ON [dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
AFTER UPDATE
/*********************************************/
AS
IF(UPDATE(OrgType))
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE		@_BEF_OrgType						nvarchar(128)
	DECLARE		@_AFT_OrgType						nvarchar(128)

	-- ������� �������� �� ���������
	/*********************************************/		
	SELECT	@_BEF_OrgType					=		UPD.OrgType
	FROM	DELETED AS UPD
	/*********************************************/	
	  	
	--��������� ���������� ����� ����������� ��������.	
	/*********************************************/
	SELECT 
	TOP 1		@_AFT_OrgType				=		UPD.OrgType
	FROM		INSERTED as UPD;
	/*********************************************/

	IF(	@_BEF_OrgType	=	@_AFT_OrgType 
	OR  @_AFT_OrgType	IS	NULL 
		) RETURN

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

	--execute [CBaseCRM_Fresh].[dbo]._log '', '������ �������� ���������� ���.'
	-- ������� ���
	/*********************************************/
	--DELETE		[CBaseCRM_Fresh].[dbo].[Log]
	/*********************************************/
	
	--���������� ������������ �������� ���������
	/*********************************************/
	DECLARE		@_DV_ID_OrgType					uniqueidentifier
	DECLARE		@_ID_COMPANY					int	
	DECLARE		@_Name							nvarchar(128)
	DECLARE		@_COUNT							int
	/*********************************************/
	
	--��������� ���������� ����������� ����������.
	/*********************************************/
	SELECT
	TOP 1		@_DV_ID_OrgType			=		INS.OrgType,
				@_ID_COMPANY			=		INS.Telex				
	FROM		INSERTED as INS

	SELECT
	TOP 1		@_Name					=		Name				
	FROM		[dbo].[dvtable_{4b25da25-ace2-4205-bd28-69f80d1cf57f}]
	WHERE		RowID					=		@_DV_ID_OrgType
	/*********************************************/
	--execute [CBaseCRM_Fresh].[dbo]._log '@_Name', @_Name
	--execute [CBaseCRM_Fresh].[dbo]._log '@_Name', @_Name
	
	--��������� ������� � DV
	/*********************************************/
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[COMPANY]
	DISABLE TRIGGER ALL
	/*********************************************/
	
	--���� ��� ���������� ��������� �� ��������� ��������� ��.
	/*********************************************/
	
	--��������� ������������ �������� ������
	/*********************************************/	
	UPDATE
	TOP (1)		[CBaseCRM_Fresh].[dbo].[COMPANY]
	SET			FORM_SOBST_COMPANY		=		@_Name
	WHERE		ID_COMPANY 				=		@_ID_COMPANY			
	/*********************************************/
	
	--�������� ������� � CRM
	/*********************************************/		
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
	ENABLE TRIGGER ALL
	/*********************************************/
	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S
END