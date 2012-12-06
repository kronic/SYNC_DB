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
IF object_id('CRM_DV_INN', 'TR') IS NOT NULL
DROP TRIGGER CRM_DV_INN
GO
/*********************************************/

--��������� �������. ����������  ��������� � DV ��� ���������� � CRM.
/*********************************************/
CREATE TRIGGER CRM_DV_INN
   ON [dbo].[LIST_REQUIS_COMPANY]
   AFTER INSERT, UPDATE
/*********************************************/
AS
IF(UPDATE(INN))
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
	DECLARE		@_INN						varchar(20) -- DV type nvarchar(128) ������ ���� � ������ �� �����
	DECLARE		@_COUNT_REQ					int
	DECLARE		@_USE_DEFAULT				varchar(10)
	/*********************************************/
	
	--��������� ���������� ����������
	/*********************************************/
	SELECT		@_ID_COMPANY		=		INS.ID_COMPANY,				
				@_INN				=		INS.INN,
				@_USE_DEFAULT		=		INS.USE_DEFAULT
	FROM		INSERTED AS INS	
	
	SELECT		@_COUNT_REQ = COUNT(ID_COMPANY)
	FROM		[LIST_REQUIS_COMPANY]
	WHERE		ID_COMPANY			=		@_ID_COMPANY	
	/*********************************************/
	
	IF(@_USE_DEFAULT != 'True' AND @_COUNT_REQ > 1 )
	BEGIN
		execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S
		RETURN
	END
	--execute [CBaseCRM_Fresh].[dbo]._log '@_FAX', @_FAX
	--��������� ������� � DV
	/*********************************************/
	ALTER TABLE [Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
	DISABLE TRIGGER ALL
	/*********************************************/	

	UPDATE
	TOP (1)		[Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
	SET			[INN]			=	@_INN
	WHERE		[Telex]			=	@_ID_COMPANY	
	

	--�������� ������� � CRM
	/*********************************************/		
	ALTER TABLE [Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
	ENABLE TRIGGER ALL
	/*********************************************/	
		
	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S
END