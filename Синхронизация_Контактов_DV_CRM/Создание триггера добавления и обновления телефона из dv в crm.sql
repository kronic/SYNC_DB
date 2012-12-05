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
IF OBJECT_ID(N'DV_CRM_Upd_Phone', 'TR') IS NOT NULL
DROP TRIGGER DV_CRM_Upd_Phone
GO
/*********************************************/

--��������� �������. ���������� �������� � DV ��� ���������� � CRM.
/*********************************************/
CREATE TRIGGER	DV_CRM_Upd_Phone
ON				[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}]
AFTER UPDATE   
/*********************************************/
AS
IF(UPDATE(Phone))
BEGIN
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
	DECLARE		@_DV_ID_COMPANY					uniqueidentifier
	DECLARE		@_ID_COMPANY					int
	DECLARE		@_ID_CONTACT_MAN				int
	DECLARE		@_BEF_TELEPHONE					varchar(64)
	DECLARE		@_AFT_TELEPHONE					varchar(64)
	DECLARE		@_TELEPHONE_OLD					varchar(64)
	/*********************************************/

	-- ������� �������� �� ���������
	/*********************************************/		
	SELECT	@_BEF_TELEPHONE				=		UPD.Phone
	FROM	DELETED AS UPD
	/*********************************************/	
	
	
	--��������� ���������� ����� ����������� ��������.
	/*********************************************/
	SELECT 
	TOP 1		@_DV_ID_COMPANY			=		UPD.ParentRowID,
				@_ID_CONTACT_MAN		=		UPD.CRM_ID,
				@_AFT_TELEPHONE			=		UPD.Phone
	FROM		INSERTED as UPD;
	/*********************************************/

	IF(@_BEF_TELEPHONE =	@_AFT_TELEPHONE 
	OR @_AFT_TELEPHONE IS	NULL 
	OR @_AFT_TELEPHONE =	'')	RETURN
	

	--�������� ��� ���������� ��������
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

	--��������� ������� �������� � CRM
	/*********************************************/
	SELECT		
	TOP 1		@_TELEPHONE_OLD			=		TELEPHONE	
	FROM		[CBaseCRM_Fresh].[dbo].[LIST_TELEPHONES]
	WHERE		ID_CONTACT_MAN			=		@_ID_CONTACT_MAN
	/*********************************************/
	--execute [CBaseCRM_Fresh].[dbo]._log '@_TELEPHONE', @_TELEPHONE
	--execute [CBaseCRM_Fresh].[dbo]._log '@_TELEPHONE_OLD', @_TELEPHONE_OLD

	--��������� ������� � CRM
	/*********************************************/
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[LIST_TELEPHONES]
	DISABLE TRIGGER ALL
	/*********************************************/	

	--���� ��� �������� ������� ���
	IF(@_TELEPHONE_OLD IS NULL)
	BEGIN
		--��������� ���.
		/*********************************************/
		INSERT INTO  [CBaseCRM_Fresh].[dbo].[LIST_TELEPHONES]
				(
				ID_COMPANY,
				ID_CONTACT_MAN,
				TELEPHONE
				) 
		VALUES	(
				@_ID_COMPANY,
				@_ID_CONTACT_MAN,
				@_AFT_TELEPHONE
				)
		/*********************************************/
	END
	--���� ���� ��� ������� ���
	ELSE
	BEGIN
		IF(@_AFT_TELEPHONE = @_TELEPHONE_OLD)
		BEGIN
			execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S
			RETURN
		END
		--execute [CBaseCRM_Fresh].[dbo]._log '', '��������� ���'
		--execute [CBaseCRM_Fresh].[dbo]._log '@_TELEPHONE', @_TELEPHONE
		--execute [CBaseCRM_Fresh].[dbo]._log '@_TELEPHONE_OLD', @_TELEPHONE_OLD
		--��������� ���
		/*********************************************/
		UPDATE
		TOP (1)	[CBaseCRM_Fresh].[dbo].[LIST_TELEPHONES]
		SET		TELEPHONE					=		@_AFT_TELEPHONE
		WHERE	ID_CONTACT_MAN				=		@_ID_CONTACT_MAN
		/*********************************************/
	END
	
	--�������� ������� � CRM
	/*********************************************/
	ALTER TABLE [CBaseCRM_Fresh].[dbo].[LIST_TELEPHONES]
	ENABLE TRIGGER ALL
	/*********************************************/	
	
	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S
END
