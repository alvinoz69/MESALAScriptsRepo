DROP TABLE IF EXISTS [LMS].[ACCOUNT_PDC]
/****** Object:  Table [LMS].[ACCOUNT_PDC]    Script Date: 27/11/2019 2:25:46 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [LMS].[ACCOUNT_PDC](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[HEADER_ID] [bigint] NOT NULL,
	[AMORTIZATION_INFO_ID] [nchar](24) NULL,
	[ACCOUNT_NO] [varchar](20)  NULL,
	[INSTALLMENT_NO] [int] NULL,
	[INSTALLMENT_DUE_DATE] [date]  NULL,
	[CHECK_NO] [nvarchar](20)  NULL,
	[FLOAT_DAYS] [smallint]  NULL,
	[ISSUE_DATE] [date] NULL,
	[CHECK_AMOUNT] [decimal](18, 2) NULL,
	[DRAWER_ACCOUNT_NO] [nvarchar](20) NULL,
	[DRAWER_BANK_CODE] [nvarchar](3) NULL,
	[DRAWER_NAME] [nvarchar](200) NULL,
	[DRAWER_BRANCH_NAME] [nvarchar](50) NULL,
	[CHECK_STATUS] [smallint]  NULL,
	[BRANCH_CODE] [nvarchar](20)  NULL,
	[BRSTN] [nvarchar](10)  NULL,
	[FLOAT_ROLL_DOWN] [smallint] NULL,
	[POSTED_DATE] [datetime2](3) NULL,
 CONSTRAINT [PK_PDC] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


