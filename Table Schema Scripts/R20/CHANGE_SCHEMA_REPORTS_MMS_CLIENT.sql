DROP TABLE IF EXISTS CBDB_REPORTS.MMS.CLIENT

/****** Object:  Table [MMS].[CLIENT]    Script Date: 18/12/2019 10:28:32 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE CBDB_REPORTS.MMS.CLIENT(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[HEADER_ID] [bigint] NULL,
	[MEMBER_NO] [varchar](20) NULL,
	[OLD_CIF_NO] [varchar](20) NULL,
	[APPL_REF_NO] [varchar](20) NULL,
	[APPLICATION_DATE] [date] NULL,
	[APPL_USER_ID] [varchar](20) NULL,
	[FULL_NAME] [nvarchar](100) NULL,
	[FIRST_NAME] [nvarchar](100) NULL,
	[MIDDLE_NAME] [nvarchar](100) NULL,
	[LAST_NAME] [nvarchar](100) NULL,
	[EXTN_NAME] [nvarchar](50) NULL,
	[MEMBER_TYPE] [varchar](50) NULL,
	[CUSTOMER_TYPE] [varchar](50) NULL,
	[MEMBER_CLASS] [varchar](50) NULL,
	[MEMBERSHIP_DATE] [date] NULL,
	[MAN_NO] [varchar](20) NULL,
	[STATUS] [varchar](20) NULL,
	[CORP_CODE] [varchar](20) NULL,
	[CORP_NAME] [nvarchar](250) NULL,
	[PREV_CORP_CODE] [varchar](20) NULL,
	[BILLING_GROUP] [nvarchar](200) NULL,
	[DIVISION] [nvarchar](60) NULL,
	[GENDER] [varchar](10) NULL,
	[BIRTHDATE] [date] NULL,
	[CIVIL_STATUS] [varchar](20) NULL,
	[SPS_BIRTHDATE] [date] NULL,
	[SPS_DBP] [bit] NULL,
	[SPS_FNAME] [nvarchar](100) NULL,
	[SPS_MNAME] [nvarchar](100) NULL,
	[SPS_LNAME] [nvarchar](100) NULL,
	[PREF_ADDRESS] [nvarchar](1000) NULL,
	[PREF_EMAIL_ADD] [varchar](50) NULL,
	[PREF_LANDLINE] [varchar](20) NULL,
	[PREF_MOBILE] [varchar](20) NULL,
	[WITH_DBP] [bit] NULL,
	[DBP_ENROLL_DATE] [date] NULL,
	[DBP_END_DATE] [date] NULL,
	[WITH_DOLE_OUT] [bit] NULL,
	[DOLE_OUT_ENROLL_DATE] [date] NULL,
	[DOLE_OUT_END_DATE] [date] NULL,
	[HOLD_DATE] [date] NULL,
	[HOLD_REASON_CODE] [varchar](10) NULL,
	[HOLD_REASON_DESC] [nvarchar](60) NULL,
	[HOLD_USER_ID] [varchar](20) NULL,
	[LAST_STAT_CHANGE_DATE] [date] NULL,
	[REASON_STAT_CHANGE] [nvarchar](250) NULL,
	[TERMINATION_DATE] [date] NULL,
	[LAST_UPDATED_DATE] [date] NULL,
	[PEP] [bit] NULL,
	[RTS] [bit] NULL,
	[BOT_RESO_NO] [nvarchar](50) NULL,
	[BOT_CONF_DATE] [date] NULL,
	[WITH_ADDRESS] [bit] NULL,
	[WITH_MOBILE] [bit] NULL,
	[WITH_LANDLINE] [bit] NULL,
	[WITH_EMAIL] [bit] NULL,
	[WITH_SOCIAL_MEDIA] [bit] NULL,
	[RISK_CLASS] [varchar](10) NULL,
	[GARNISH] [bit] NULL,
	[GARNISH_START_DATE] [date] NULL,
	[GARNISH_END_DATE] [date] NULL,
	[COSIGNEE_NAME] [nvarchar](200) NULL,
	[GARNISH_COVERAGE] [varchar](5) NULL,
	[GARNISH_COVERAGE_VALUE] [nvarchar](50) NULL,
	[SPA] [bit] NULL,
	[SPA_START_DATE] [date] NULL,
	[SPA_END_DATE] [date] NULL,
	[SPA_COVERAGE] [varchar](5) NULL,
	[SPA_COVERAGE_VALUE] [nvarchar](50) NULL,
	[SPA_ATTORNEY] [varchar](100) NULL,
	[TORI_TAG] [bit] NULL,
	[TORI_TAG_LAST_UPDATED_DATE] [date] NULL,
	[PREV_CORP_NAME] [varchar](255) NULL,
	[IS_TERMINATED] [bit] NULL,
	[DBP_REMARKS] [varchar](10) NULL,
	[DBP_SPS_REMARKS] [varchar](10) NULL,
	[BILLING_GROUP_CODE] [nvarchar](8) NULL,
	[CLIENT_STATUS_CODE] [varchar](10) NULL,
	[MEMBER_TYPE_CODE] [varchar](10) NULL,
	[GROUP_CODE] [varchar](20) NULL,
	[GROUP_CODE_DESC] [varchar](250) NULL,
	[GARNISH_COVERAGE_DESC] [varchar](200) NULL,
	[SPA_COVERAGE_DESC] [varchar](200) NULL,
	[SPS_DBP_ENROLL_DATE] [date] NULL,
	[SPS_DBP_END_DATE] [date] NULL,
	[DIVISION_CODE] [varchar](15) NULL,
	[CORP_TRANSFER_REASON] [varchar](100) NULL
) ON [PRIMARY]
GO


