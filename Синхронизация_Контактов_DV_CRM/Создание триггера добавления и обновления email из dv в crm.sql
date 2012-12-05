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
IF OBJECT_ID(N'DV_CRM_Upd_Email', 'TR') IS NOT NULL
DROP TRIGGER DV_CRM_Upd_Email
GO
/*********************************************/

--��������� �������. ����������  �������� � DV ��� ���������� � CRM.
/*********************************************/
CREATE TRIGGER	DV_CRM_Upd_Email
ON				[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}]
AFTER UPDATE   
/*********************************************/
AS
IF(UPDATE(Email))
BEGIN
	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON	

	-- ������� ���
	/*********************************************/
	--DELETE		[CBaseCRM_Fresh].[dbo].[Log]
	/*********************************************/

	--���������� ������������ �������� ���������
	/*********************************************/
	DECLARE		@_DV_ID_COMPANY					uniqueidentifier
	DECLARE		@_ID_COMPANY					int
	DECLARE		@_ID_CONTACT_MAN				int
	DECLARE		@_BEF_EMAIL						varchar(64)
	DECLARE		@_AFT_EMAIL						varchar(64)
	DECLARE		@_EMAIL_OLD						varchar(64)
	/*********************************************/
	
	-- ������� �������� �� ���������
	/*********************************************/		
	SELECT	@_BEF_EMAIL					=		UPD.Email
	FROM	DELETED AS UPD
	/*********************************************/	
	  	
	--��������� ���������� ����� ����������� ��������.	
	/*********************************************/
	SELECT 
	TOP 1		@_DV_ID_COMPANY			=		UPD.ParentRowID,
				@_ID_CONTACT_MAN		=		UPD.CRM_ID,
				@_AFT_EMAIL				=		UPD.Email
	FROM		INSERTED as UPD;
	/*********************************************/
	
	IF(	@_BEF_EMAIL	=	@_AFT_EMAIL 
	OR  @_AFT_EMAIL IS	NULL 
	OR	@_AFT_EMAIL =	'') RETURN

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

	--��� ������ �������� ��������� ����� ���� � DV � ���������� ��� � CRM
	/*********************************************/
	SELECT		@_ID_COMPANY			=		Telex   
	FROM        [dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
	WHERE		RowID					=		@_DV_ID_COMPANY
	/*********************************************/
	
	--��������� ������� email � CRM
	/*********************************************/
	SELECT		
	TOP 1		@_EMAIL_OLD				=		email	
	FROM		[CBaseCRM_Fresh].[dbo].[LIST_EMAIL_CLIENT]
	WHERE		ID_CONTACT_MAN			=		@_ID_CONTACT_MAN
	/*********************************************/
	
	--execute [CBaseCRM_Fresh].[dbo]._log '@_EMAIL_OLD', @_EMAIL_OLD
	--��������� ������� � CRM
	/*********************************************/
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[LIST_EMAIL_CLIENT]
	DISABLE TRIGGER ALL
	/*********************************************/	

	--���� ��� email ������� ���
	IF(@_EMAIL_OLD IS NULL)
	BEGIN
		--execute [CBaseCRM_Fresh].[dbo]._log '@_ID_CONTACT_MAN', '��������� EMAIL'		
		--��������� EMAIL
		/*********************************************/	
		INSERT INTO	[CBaseCRM_Fresh].[dbo].[LIST_EMAIL_CLIENT]
				(
				ID_COMPANY,
				ID_CONTACT_MAN,
				email
				) 
		VALUES	(
				@_ID_COMPANY,
				@_ID_CONTACT_MAN,
				@_AFT_EMAIL
				)
		/*********************************************/
		
	END
	--���� ���� email ������� ���
	ELSE
	BEGIN
		IF(@_AFT_EMAIL = @_EMAIL_OLD) 
		BEGIN
			execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S
			RETURN
		END
		--execute [CBaseCRM_Fresh].[dbo]._log '@_ID_CONTACT_MAN', '��������� EMAIL'
		--execute [CBaseCRM_Fresh].[dbo]._log '@_EMAIL', @_EMAIL
		--execute [CBaseCRM_Fresh].[dbo]._log '@_EMAIL_OLD', @_EMAIL_OLD
		--��������� EMAIL
		/*********************************************/
		UPDATE
		TOP	(1)	[CBaseCRM_Fresh].[dbo].[LIST_EMAIL_CLIENT]
		SET		email						=		@_AFT_EMAIL
		WHERE	ID_CONTACT_MAN				=		@_ID_CONTACT_MAN
		/*********************************************/
	END
	--�������� ������� � CRM
	/*********************************************/
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[LIST_EMAIL_CLIENT]
	ENABLE TRIGGER CRM_DV_LIST_EMAIL_CLIENT
	/*********************************************/	
	
	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S
END
GO
