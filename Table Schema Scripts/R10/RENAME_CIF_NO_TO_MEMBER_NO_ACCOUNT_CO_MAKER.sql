DROP TABLE IF EXISTS CBDB_REPORTS.LMS.ACCOUNT_CO_MAKER

/****** Object:  Table [LMS].[ACCOUNT_CO_MAKER]    Script Date: 15/11/2019 10:21:34 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE CBDB_REPORTS.LMS.ACCOUNT_CO_MAKER(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[HEADER_ID] [bigint] NOT NULL,
	[ACCOUNT_NO] [nchar](18) NOT NULL,
	[MEMBER_NO] [nvarchar](30) NOT NULL,
	[BILL_ALLOWED] [smallint] NULL,
	[STATUS] [varchar](255) NULL,
	[BILL_TRANSFER_DATE] [date] NULL,
	[FULL_NAME] [varchar](250) NULL,
	[LAST_NAME] [varchar](100) NULL,
	[FIRST_NAME] [varchar](100) NULL,
	[MIDDLE_NAME] [varchar](100) NULL,
	[EXTN_NAME] [varchar](50) NULL,
	[CORP_CODE] [varchar](50) NULL,
	[CORP_NAME] [varchar](255) NULL
)
GO
