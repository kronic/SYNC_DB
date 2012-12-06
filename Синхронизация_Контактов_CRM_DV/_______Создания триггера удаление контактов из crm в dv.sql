								USE [CBaseCRM_Fresh]
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		���� ��������
-- Create date: 14.11.2012
-- Description:	������� ������� ������� �� ���������� �����, ������, ��������, ��������� � DV �� CRM.
-- ���������� �������� ��� Copy_DV �� ��� ���� DV. 
-- =============================================

--������� ������� ���� �� ����������.
/*********************************************/
IF object_id(N'DEL_CRM_DV_LIST_CONTACT_MAN') IS NOT NULL
DROP TRIGGER DEL_CRM_DV_LIST_CONTACT_MAN
GO
/*********************************************/

--��������� �������. ����������  ��������� � DV ��� ���������� � CRM.
/*********************************************/
CREATE TRIGGER DEL_CRM_DV_LIST_CONTACT_MAN
   ON LIST_CONTACT_MAN
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
	--DELETE [dbo].[Log]
	/*********************************************/
	DECLARE		@DEL_ID		uniqueidentifier

	SELECT
	TOP 1 		@DEL_ID	= DV_ID	
	FROM		DELETED as DEL;



	--��������� ������� � DV
	/*********************************************/
	ALTER TABLE Copy_DV.[dbo].[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}] 
	DISABLE TRIGGER ALL
	/*********************************************/									  
	DELETE	
	TOP (1)
	FROM	Copy_DV.[dbo].[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}]
	WHERE	RowID		=	 @DEL_ID
	--�������� ������� � DV
	/*********************************************/
	ALTER TABLE [Copy_DV].[dbo].[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}]
	ENABLE TRIGGER ALL
	/*********************************************/			
	execute [CBaseCRM_Fresh].[dbo]._log 'Stop', @S

END
GO