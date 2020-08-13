DROP VIEW IF EXISTS [dbo].[VW_CCMasterlist]
/****** Object:  View [dbo].[VW_CCMasterlist]    Script Date: 10/01/2020 10:56:59 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[VW_CCMasterlist] AS
SELECT 
A.ACCOUNT_NO, 
A.ACCOUNT_STATUS,
A.MEMBER_NO,
CASE WHEN B.MEMBER_TYPE_CODE = 'C'
	 THEN B.FULL_NAME
	 ELSE B.LAST_NAME
END AS LAST_NAME,
B.FIRST_NAME, 
B.MIDDLE_NAME, 
B.CORP_CODE,
B.MEMBER_TYPE,
B.MEMBER_CLASS,
B.STATUS,
A.LEDGER_BAL,
A.PRODUCT_CODE,
A.PRODUCT_DESC
FROM DMS.ACCOUNT_MASTER				A WITH (NOLOCK)
LEFT JOIN MMS.CLIENT				B WITH (NOLOCK) ON B.MEMBER_NO = A.MEMBER_NO
-- PRODUCT CODE 001 = CCA
-- PRODUCT CODE 002 = RSD
-- PRODUCT CODE 003 = SSD
-- PRODUCT CODE 004 = TDA
-- PRODUCT CODE 005 = TDB
-- PRODUCT CODE 006 = TDC
-- PRODUCT CODE 007 = STD
WHERE A.IS_CLOSE=0 
AND A.PRODUCT_CODE='001'
GO


