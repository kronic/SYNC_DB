USE [CBaseCRM_Fresh]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		���� ��������
-- Create date: 14.11.2012
-- Description:	������� ������� ������� �� ���������� ��������� � DV �� CRM.
-- ���������� �������� ��� Copy_DV �� ��� ���� DV. 
-- =============================================

--������� ������� ���� �� ����������.
/*********************************************/
IF object_id(N'CRM_DV_LIST_TELEPHONES') IS NOT NULL
DROP TRIGGER CRM_DV_LIST_TELEPHONES
GO
/*********************************************/

--��������� �������. ����������  ��������� � DV ��� ���������� � CRM.
/*********************************************/
CREATE TRIGGER CRM_DV_LIST_TELEPHONES
   ON CBaseCRM_FRESH.dbo.LIST_TELEPHONES
   AFTER INSERT, UPDATE
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
	--DELETE [dbo].[Log]
	/*********************************************/
	
	--��������� ���������
	/*********************************************/
	DECLARE     @_ID_COMPANY				int
	DECLARE		@_ID_CONTACT_MAN_INS		int
	DECLARE		@_TELEPHONE_INS				varchar(50) 
	DECLARE		@_TELEPHONE_MIN				varchar(50) 
	DECLARE		@_TELEPHONE					varchar(50) -- DV type varchar(64) ������ ���� � ������ �� �����
	/*********************************************/
	
	--��������� ���������� ����������
	/*********************************************/
	SELECT 
	TOP 1		@_ID_COMPANY					=		INS.ID_COMPANY,
				@_ID_CONTACT_MAN_INS			=		INS.ID_CONTACT_MAN,
				@_TELEPHONE_INS					=		INS.TELEPHONE
	FROM		INSERTED as INS;
	/*********************************************/
	--execute _log '@_TELEPHONE_INS', @_TELEPHONE_INS

	--��������� ��������� ����� �������� ���������
	/*********************************************/
	SELECT 
	TOP 1		@_TELEPHONE_MIN = MIN(dbo.LIST_TELEPHONES.TELEPHONE)
	FROM		LIST_CONTACT_MAN 
	INNER JOIN	LIST_TELEPHONES 
	ON			LIST_CONTACT_MAN.ID_CONTACT_MAN	=		LIST_TELEPHONES.ID_CONTACT_MAN
	WHERE		(LIST_CONTACT_MAN.ID_CONTACT_MAN=		@_ID_CONTACT_MAN_INS)
	
	--execute _log '@_TELEPHONE_MIN', @_TELEPHONE_MIN

	IF(DATALENGTH(@_TELEPHONE_INS) <=  DATALENGTH(@_TELEPHONE_MIN)) 
	SET			@_TELEPHONE						=		@_TELEPHONE_INS
	ELSE
	SET			@_TELEPHONE						=		@_TELEPHONE_MIN
	
	--execute _log '@_TELEPHONE', @_TELEPHONE
	--execute _log '@_ID_CONTACT_MAN_INS', @_ID_CONTACT_MAN_INS
	/*********************************************/
	
	IF(@_ID_CONTACT_MAN_INS != 0 AND @_ID_CONTACT_MAN_INS IS NOT NULL)
	BEGIN
		--��������� �������� � DV
		/*********************************************/
		ALTER TABLE Copy_DV.[dbo].[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}]
		DISABLE TRIGGER	ALL
		/*********************************************/
	
		--��������� ����. ������ � DV
		/*********************************************/
		UPDATE
		TOP (1)		Copy_DV.[dbo].[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}]
		SET			[Phone]							=		@_TELEPHONE
		WHERE		CRM_ID							=		@_ID_CONTACT_MAN_INS
		/*********************************************/

		--�������� �������� � DV
		/*********************************************/
		ALTER TABLE Copy_DV.[dbo].[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}]
		ENABLE TRIGGER ALL
		/*********************************************/
	
	END
	ELSE
	BEGIN
		--��������� ������� � DV
		/*********************************************/
		ALTER TABLE [Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
		DISABLE TRIGGER ALL
		/*********************************************/		
		--execute _log '@_ID_CONTACT_MAN_INS', @_ID_COMPANY
		
		UPDATE
		TOP (1)		Copy_DV.[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
		SET			[Phone]							=		@_TELEPHONE_INS
		WHERE		Telex							=		@_ID_COMPANY
		
		--�������� ������� � DV
		/*********************************************/
		ALTER TABLE [Copy_DV].[dbo].[dvtable_{c78abded-db1c-4217-ae0d-51a400546923}]
		ENABLE TRIGGER ALL
		/*********************************************/	
	END
	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S
END
GO