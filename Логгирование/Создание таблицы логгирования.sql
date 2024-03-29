USE [CBaseCRM_Fresh]
-- =============================================
-- Author:		Иван Берлинец
-- Create date: 14.11.2012
-- Description:	Скрипит создает таблицу логгирования.
-- =============================================
GO

/****** Object:  Table [dbo].[Log]    Script Date: 14.11.2012 12:12:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Log](
	[TIME] datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
	[NAME] [nchar](500) NULL,
	[VALUE] [nchar](500) NULL	
) ON [PRIMARY]

GO
