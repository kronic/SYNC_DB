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
IF object_id(N'DV_CRM_Upd_Req_Tel') IS NOT NULL
DROP TRIGGER DV_CRM_Upd_Req_Tel
GO
/*********************************************/

--��������� �������. ����������  ��������� � DV ��� ���������� � CRM.
/*********************************************/
CREATE TRIGGER DV_CRM_Upd_Req_Tel
   ON [dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
AFTER UPDATE
/*********************************************/
AS
IF(UPDATE(Phone))
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
		UPDATE		[CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
		SET			KONT_TEL				=		UPD.Phone			
		FROM		INSERTED AS UPD
		WHERE		ID_COMPANY				=		UPD.Telex			
		/*********************************************/
	END
	ELSE
		BEGIN
		--��������� ������������ ���������
		/*********************************************/	
		UPDATE		[CBaseCRM_Fresh].[dbo].[LIST_REQUIS_COMPANY]
		SET			KONT_TEL				=		UPD.Phone			
		FROM		INSERTED AS UPD
		WHERE		ID_COMPANY				=		UPD.Telex
		AND			USE_DEFAULT				=		'True'
		/*********************************************/
	END
	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S
END		
