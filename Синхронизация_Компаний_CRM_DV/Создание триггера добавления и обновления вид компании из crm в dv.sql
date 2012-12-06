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
IF object_id('CRM_DV_VID_COMPANY', 'TR') IS NOT NULL
DROP TRIGGER CRM_DV_VID_COMPANY
GO
/*********************************************/

--��������� �������. ����������  ��������� � DV ��� ���������� � CRM.
/*********************************************/
CREATE TRIGGER CRM_DV_VID_COMPANY
   ON [dbo].[COMPANY]
   AFTER INSERT, UPDATE
/*********************************************/
AS
IF(UPDATE(ID_VID_COMPANY))
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
	DECLARE     @_ID_VID_COMPANY			int
	/*********************************************/
	

	--��������� ���������� ����������
	/*********************************************/
	SELECT		@_ID_COMPANY		=		INS.ID_COMPANY,				
				@_ID_VID_COMPANY	=		INS.ID_VID_COMPANY
	FROM		INSERTED AS INS
	/*********************************************/
	
	execute [CBaseCRM_Fresh].[dbo]._log '@_ID_VID_COMPANY', @_ID_VID_COMPANY		
	--��������� ������� � CRM
	/*********************************************/
	ALTER TABLE [Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
	DISABLE TRIGGER ALL
	/*********************************************/
	IF(@_ID_VID_COMPANY = 15)
	BEGIN
		UPDATE
		TOP (1)		[Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
		SET			[IsVendor]						=		1,
					[IsClient]						=		0
		WHERE		[Telex]							=		@_ID_COMPANY
	END
	ELSE IF(@_ID_VID_COMPANY = 15)
	BEGIN
		UPDATE
		TOP (1)		[Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
		SET			[IsVendor]						=		0,
					[IsClient]						=		0
		WHERE		[Telex]							=		@_ID_COMPANY
	END
	ELSE
	BEGIN
		UPDATE
		TOP (1)		[Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
		SET			[IsClient]						=		1,
					[IsVendor]						=		0
		WHERE		[Telex]							=		@_ID_COMPANY	
	END

	--�������� ������� � CRM
	/*********************************************/		
	ALTER TABLE [Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
	ENABLE TRIGGER ALL
	/*********************************************/	
	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S
END