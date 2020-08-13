DROP TABLE IF EXISTS CBDB_REPORTS.MMS.CLIENT_STATUS_HISTORY

/****** Object:  Table [MMS].[CLIENT_STATUS_HISTORY]    Script Date: 26/10/2019 3:03:32 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE CBDB_REPORTS.MMS.CLIENT_STATUS_HISTORY(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[HEADER_ID] [bigint] NOT NULL,
	[MEMBER_NO] [varchar](20) NOT NULL,
	[STATUS_FROM] [varchar](20) NULL,
	[STATUS_FROM_DESC] [varchar](50) NULL,
	[STATUS_TO] [varchar](20) NULL,
	[STATUS_TO_DESC] [varchar](50) NULL,
	[MAINT_DATE] [date] NULL,
	[MAINT_BY] [varchar](20) NULL,
	[MAINT_REASON] [nvarchar](60) NULL
) ON [PRIMARY]
GO


