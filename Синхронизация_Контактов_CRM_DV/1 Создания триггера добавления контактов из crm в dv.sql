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
IF object_id(N'CRM_DV_LIST_CONTACT_MAN') IS NOT NULL
DROP TRIGGER CRM_DV_LIST_CONTACT_MAN
GO
/*********************************************/

--��������� �������. ����������  ��������� � DV ��� ���������� � CRM.
/*********************************************/
CREATE TRIGGER CRM_DV_LIST_CONTACT_MAN
   ON LIST_CONTACT_MAN
   AFTER INSERT
/*********************************************/
AS
BEGIN
		-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
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
	
	-- ������� ���
	/*********************************************/
	--DELETE [dbo].[Log]
	/*********************************************/

	--����� ����
	/*********************************************/
	DECLARE		@NEW_RowID							uniqueidentifier
	/*********************************************/
	
	--���������
	/*********************************************/
	DECLARE		@CONST_SDID							uniqueidentifier
	DECLARE		@CONST_InstanceID					uniqueidentifier	
	DECLARE		@CONST_ParentTreeRowID				uniqueidentifier
	/*********************************************/
	
	--��������� ��������� ����������
	/*********************************************/
	SET			@NEW_RowID					=		NEWID()
	SET			@CONST_SDID					=		'8F51A892-10C4-4723-9EEA-B93DA63414C1'
	SET			@CONST_InstanceID			=		'65FF9382-17DC-4E9F-8E93-84D6D3D8FE8C'
	SET			@CONST_ParentTreeRowID		=		'00000000-0000-0000-0000-000000000000'
	/*********************************************/

	--���������� ������������ ��������
	/*********************************************/
	DECLARE     @_ID_COMPANY						int
	DECLARE		@_ID_CONTACT_MAN_INS				int
	DECLARE		@_ParentRowID						uniqueidentifier	
	/*********************************************/

	--��������� ���������� ����������
	/*********************************************/
	SELECT 
	TOP 1		@_ID_COMPANY				=		INS.ID_COMPANY,
				@_ID_CONTACT_MAN_INS		=		INS.ID_CONTACT_MAN
	FROM		INSERTED as INS;
	/*********************************************/

	--��� ������ �������� ��������� ����� ���� � DV � ���������� ��� � CRM
	/*********************************************/
	SELECT		@_ParentRowID				=		DV_ID   
	FROM        COMPANY
	WHERE		ID_COMPANY	 				=		@_ID_COMPANY
	/*********************************************/
		
	--��������� ������� � DV
	/*********************************************/
	ALTER TABLE Copy_DV.[dbo].[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}] 
	DISABLE TRIGGER ALL
	/*********************************************/	
	
	INSERT INTO  Copy_DV.[dbo].[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}]
				(
				RowID,
				SDID,					--CONST 
				InstanceID,				--CONST
				ParentRowID,			--ID_DV
				ParentTreeRowID,		--CONST
				CRM_ID				
				) 
	VALUES
				(
				@NEW_RowID,				--RowID
				@CONST_SDID,			--SDID
				@CONST_InstanceID,		--InstanceID
				@_ParentRowID,			--ParentRowID
				@CONST_ParentTreeRowID, --ParentTreeRowID
				@_ID_CONTACT_MAN_INS	--CRM_ID					
				)		
	
	--�������� ������� � DV
	/*********************************************/
	ALTER TABLE [Copy_DV].[dbo].[dvtable_{1a46bf0f-2d02-4ac9-8866-5adf245921e8}]
	ENABLE TRIGGER ALL
	/*********************************************/			
	UPDATE
	TOP (1)	LIST_CONTACT_MAN
	SET		[DV_ID]				=		@NEW_RowID
	WHERE	[ID_CONTACT_MAN]	=	@_ID_CONTACT_MAN_INS

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
--GO
--���������� �������� ������
--exec sp_settriggerorder 'dbo.CRM_DV_LIST_CONTACT_MAN', 'first', 'insert'
--GO