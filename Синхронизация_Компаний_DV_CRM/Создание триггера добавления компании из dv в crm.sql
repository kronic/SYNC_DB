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
IF object_id(N'DV_CRM_Ins_Add_Company') IS NOT NULL
DROP TRIGGER DV_CRM_Ins_Add_Company
GO
/*********************************************/

--��������� �������. ����������  ��������� � DV ��� ���������� � CRM.
/*********************************************/
CREATE TRIGGER DV_CRM_Ins_Add_Company
   ON [dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
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
	DECLARE		@_NEW_ID_COMPANY					int			
	/*********************************************/	

	--���������� ������������ �������� ���������
	/*********************************************/
	DECLARE		@_DV_ID_COMPANY					uniqueidentifier
	DECLARE		@_ID_COMPANY					int
	/*********************************************/
		
	--��������� ���������� ���������� ����������� ��������.
	/*********************************************/
	SELECT 
	TOP 1		@_DV_ID_COMPANY			=		INS.RowID				
	FROM		INSERTED as INS
	/*********************************************/
	
	--��������� ������� � CRM
	/*********************************************/
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[COMPANY]
	DISABLE TRIGGER ALL
	/*********************************************/
	--EXECUTE [CBaseCRM_Fresh].[dbo]._log '@_DV_ID_COMPANY', @_DV_ID_COMPANY	
	--��������� ������ � crm.
	/*********************************************/
	INSERT INTO	[CBaseCRM_Fresh].[dbo].[COMPANY]
			(
				DV_ID
			) 
	VALUES	(
				@_DV_ID_COMPANY
			)
	/*********************************************/


	--���������� � ���������� �������� ������ ����� ������������ � CRM
	/*********************************************/
	SET			@_NEW_ID_COMPANY		=		@@IDENTITY
	--EXECUTE [CBaseCRM_Fresh].[dbo]._log '@_NEW_ID_COMPANY', @_NEW_ID_COMPANY
	/*********************************************/
	
	--��������� �������� CRM
	/*********************************************/
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[COMPANY]
	ENABLE TRIGGER ALL
	/*********************************************/
	EXECUTE [CBaseCRM_Fresh].[dbo]._log '@_DV_ID_COMPANY', @_DV_ID_COMPANY
	EXECUTE [CBaseCRM_Fresh].[dbo]._log '@_NEW_ID_COMPANY', @_NEW_ID_COMPANY
	
	--������� ���� �������� crm � dv
	/*********************************************/
	UPDATE 
	TOP (1)	[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
	SET		Telex						=		@_NEW_ID_COMPANY		
	WHERE	RowID						=		@_DV_ID_COMPANY	
	/*********************************************/


	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S
END