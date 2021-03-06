DROP TABLE IF EXISTS CBDB_REPORTS.LMS.NA_APPLICATION_COMPUTATION

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE CBDB_REPORTS.LMS.NA_APPLICATION_COMPUTATION(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[HEADER_ID] BIGINT NULL,
	[REFNO] [nvarchar](50) NULL,
	[LOAN_PRODUCT_CODE] [nvarchar](50) NULL,
	[LOAN_AMOUNT] [decimal](18, 2) NULL,
	[LOAN_TERM] [int] NULL,
	[LOAN_MA] [decimal](18, 2) NULL,
	[LOAN_CTP] [decimal](18, 2) NULL,
	[LOAN_SBL] [decimal](18, 2) NULL,
	[LOAN_AVAILABLE_SBL] [decimal](18, 2) NULL,
	[LOAN_LOANABLE_AMOUNT] [decimal](18, 2) NULL,
	[LOAN_NET_PROCEED] [decimal](18, 2) NULL,
	[START_TIME] [datetime] NULL,
	[END_TIME] [datetime] NULL,
	[LOAN_STATUS] [smallint] NULL,
	[LAST_UPDATED_BY] [nvarchar](40) NULL,
	[LAST_UPDATED_DATE] [datetime] NULL,
	--[COMPUTATION_DETAILS] [nvarchar](max) NULL,
	--[PROCESS_START_TIME] [datetime] NULL,
	--[PROCESS_END_TIME] [datetime] NULL,
	[RELEASE_BY] [nvarchar](150) NULL,
	--[PROCESSING_DETAILS] [varchar](max) NULL,
	[LIT_NO] [nvarchar](50) NULL,
	[CREATE_BY] [nvarchar](80) NULL,
	OVERALL_MONTHLY_INC [decimal](18, 2),
	TOTAL_DEDUCTION [decimal](18, 2),
	NET_TAKE_HOME_PAY [decimal](18, 2)
	)
