USE [CBaseCRM_Fresh]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		���� ��������
-- Create date: 14.11.2012
-- Description:	��������� ������������
-- =============================================

CREATE PROCEDURE  [dbo].[_log]
				@VAR nvarchar(500), 
				@LOG nvarchar(500)

AS
BEGIN
	INSERT INTO [dbo].[LOG] (
							[NAME], 
							[VALUE]
							)
	VALUES					(
							@VAR,
							@LOG
							)
END
