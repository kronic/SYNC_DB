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
IF object_id('CRM_DV_COMPANY_URL', 'TR') IS NOT NULL
DROP TRIGGER CRM_DV_COMPANY_URL
GO
/*********************************************/

--��������� �������. ����������  ��������� � DV ��� ���������� � CRM.
/*********************************************/
CREATE TRIGGER CRM_DV_COMPANY_URL
   ON [dbo].[COMPANY]
   AFTER UPDATE, INSERT
/*********************************************/
AS
IF(UPDATE(URL_COMPANY))
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	--����������
	/*********************************************/
	DECLARE		@_ID_COMPANY				int
	DECLARE     @_URL_COMPANY				varchar(150) --DV nvarchar(256)
	/*********************************************/
	
	--��������� ���������� ����������
	/*********************************************/
	SELECT		@_ID_COMPANY		=		INS.ID_COMPANY,				
				@_URL_COMPANY		=		INS.URL_COMPANY
	FROM		INSERTED AS INS
	/*********************************************/
	IF(@_URL_COMPANY IS NULL) RETURN
	SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
	
	BEGIN TRAN tr1 
	
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
	
	
	--execute [CBaseCRM_Fresh].[dbo]._log '', '���������'		
	--��������� ������� � CRM
	/*********************************************/
	ALTER TABLE [Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
	DISABLE TRIGGER ALL
	/*********************************************/	
	UPDATE
	TOP (1)		[Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
	SET			[URL]							=		@_URL_COMPANY					
	WHERE		[Telex]							=		@_ID_COMPANY
	
	--�������� ������� � CRM
	/*********************************************/		
	ALTER TABLE [Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
	ENABLE TRIGGER ALL
	/*********************************************/
	
	--��������� ����� � dv ��� ��������� �������
	/*********************************************/		
	UPDATE [Copy_DV].[dbo].[dvsys_instances_date]
	SET  [ChangeDateTime] = CURRENT_TIMESTAMP
	WHERE [InstanceID] = N'65FF9382-17DC-4E9F-8E93-84D6D3D8FE8C'				
	/*********************************************/	
	--���� ������ ����� ����������
	/*********************************************/	
	IF @@ERROR != 0
	BEGIN		
		execute [CBaseCRM_Fresh].[dbo]._log 'ERROR TRAN = ', @S
		ROLLBACK TRANSACTION
		RETURN
	END
	/*********************************************/	
	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S	
	--������� ����������
	/*********************************************/	
	COMMIT TRAN tr1
	/*********************************************/	
END