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
IF object_id(N'DV_CRM_Upd_Req_Full_Name') IS NOT NULL
DROP TRIGGER DV_CRM_Upd_Req_Full_Name
GO
/*********************************************/

--��������� �������. ����������  ��������� � DV ��� ���������� � CRM.
/*********************************************/
CREATE TRIGGER DV_CRM_Upd_Req_Full_Name
   ON [dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
AFTER UPDATE
/*********************************************/
AS
IF(UPDATE(FullName))
BEGIN
	DECLARE		@_BEF_FullName						nvarchar(128)
	DECLARE		@_AFT_FullName						nvarchar(128)

	-- ������� �������� �� ���������
	/*********************************************/		
	SELECT	@_BEF_FullName					=		UPD.FullName
	FROM	DELETED AS UPD
	/*********************************************/	
	  	
	--��������� ���������� ����� ����������� ��������.	
	/*********************************************/
	SELECT 
	TOP 1		@_AFT_FullName				=		UPD.FullName
	FROM		INSERTED as UPD;
	/*********************************************/

	IF(	@_BEF_FullName	=	@_AFT_FullName 
	OR  @_AFT_FullName	IS	NULL 
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

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON		
	
	-- ������� ���
	/*********************************************/
	--DELETE	[CBaseCRM_Fresh].[dbo].[Log]
	/*********************************************/
		
	--�������� ����������
	/*********************************************/
	DECLARE		@_ID_COMPANY					int
	DECLARE		@_COUNT							int
	/*********************************************/
	
	--��������� ����������
	/*********************************************/
	SELECT
	TOP 1		@_ID_COMPANY			=		INS.Telex
	FROM		INSERTED AS INS
	/*********************************************/
		
	--������� ����������� ���������� � �������� �� ���������
	
	/*********************************************/
	SELECT		@_COUNT					=		COUNT(ID_COMPANY)
	FROM [CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
	WHERE		ID_COMPANY				=		@_ID_COMPANY				
	/*********************************************/
	--��������� ������� � DV
	/*********************************************/
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
	DISABLE TRIGGER ALL
	/*********************************************/	

	--���� ��� ���������� ��������� �� ��������� ��������� ��.
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
	--��������� ������������ ���������
		/*********************************************/	
		UPDATE
		TOP (1)		[CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
		SET			FULL_NAME				=		UPD.FullName			
		FROM		INSERTED AS UPD
		WHERE		ID_COMPANY				=		UPD.Telex			
		/*********************************************/
	END
	ELSE
	BEGIN
		--��������� ������������ ���������
		/*********************************************/	
		UPDATE
		TOP (1)		[CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
		SET			FULL_NAME				=		UPD.FullName			
		FROM		INSERTED AS UPD
		WHERE		ID_COMPANY				=		UPD.Telex
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