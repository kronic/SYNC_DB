USE [Copy_DV]
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		���� ��������
-- Create date: 14.11.2012
-- Description:	������� ������� ������� �� ���������� ���������� ������ �� DV � CRM.
-- ���������� �������� ��� Copy_DV �� ��� ���� DV. 
-- =============================================

--������� ������� ���� �� ����������.
/*********************************************/
IF object_id(N'DV_CRM_Ins_Contact') IS NOT NULL
DROP TRIGGER DV_CRM_Ins_Contact
GO
/*********************************************/

--��������� �������. ����������  ��������� � DV ��� ���������� � CRM.
/*********************************************/
CREATE TRIGGER DV_CRM_Ins_Contact
   ON [dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}]
   AFTER INSERT
/*********************************************/
AS 
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
	
	-- ������� ���
	/*********************************************/
	--DELETE [CBaseCRM_Fresh].[dbo].[Log]
	/*********************************************/

	--����� ����
	/*********************************************/
	DECLARE		@NEW_ID_CONTACT_MAN				int	
	/*********************************************/
	
	--���������� ������������ �������� ���������
	/*********************************************/
	DECLARE		@_DV_ID_CONTACT					uniqueidentifier
	DECLARE		@_DV_ID_COMPANY					uniqueidentifier
	DECLARE		@_ID_COMPANY					int
	/*********************************************/
		
	--��������� ���������� ���������� ����������� ��������.
	/*********************************************/
	SELECT 
	TOP 1		@_DV_ID_CONTACT			=		INS.RowID,
				@_DV_ID_COMPANY			=		INS.ParentRowID		
	FROM		INSERTED as INS;
	/*********************************************/

	--��� ������ �������� ��������� ����� ���� � DV � ���������� ��� � CRM
	/*********************************************/
	SELECT		@_ID_COMPANY			=		Telex   
	FROM        [dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
	WHERE		RowID					=		@_DV_ID_COMPANY
	/*********************************************/

	--��������� ������� � CRM
	/*********************************************/
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[LIST_CONTACT_MAN]
	DISABLE TRIGGER ALL
	/*********************************************/

	INSERT INTO  [CBaseCRM_Fresh].[dbo].[LIST_CONTACT_MAN]
			(
				ID_COMPANY,
				DV_ID
			) 
	VALUES	(
				@_ID_COMPANY,
				@_DV_ID_CONTACT
			)
	--���������� � ���������� �������� ������ ����� ������������ � CRM
	/*********************************************/
	SET			@NEW_ID_CONTACT_MAN		=		@@IDENTITY
	--EXECUTE [CBaseCRM_Fresh].[dbo]._log '@NEW_ID_CONTACT_MAN', @NEW_ID_CONTACT_MAN
	/*********************************************/

	--������� ���� �������� crm � dv
	/*********************************************/
	UPDATE
	TOP	(1)	[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}]
	SET		CRM_ID						=		@NEW_ID_CONTACT_MAN		
	WHERE	RowID						=		@_DV_ID_CONTACT
	/*********************************************/
	--��������� �������� CRM
	/*********************************************/
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[LIST_CONTACT_MAN]
	ENABLE TRIGGER ALL
	/*********************************************/
	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S

END
GO