DROP VIEW IF EXISTS [dbo].[VW_LstCollateral]
/****** Object:  View [dbo].[VW_LstCollateral]    Script Date: 04/12/2019 4:26:13 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[VW_LstCollateral] AS
SELECT 
CL.FULL_NAME
,AM.ACCOUNT_NO
,AM.PRODUCT_NAME AS LOAN_TYPE
,AM.LOAN_AMOUNT
,AM.RELEASED_DATE
,AM.MATURITY_DATE
,AM.TERM
,AM.MONTHLY_AMORT
,AM.LOAN_BALANCE AS OUTSTANDING_BALANCE
,APP.APPRAISAL_DATE AS LATEST_APPRAISAL_DATE
,COLL.APPRAISAL_VALUE
,APP.COLLATERAL_ID
,COLL.COLLATERAL_TYPE_DESC
FROM LMS.ACCOUNT_MASTER AM WITH(NOLOCK)
INNER JOIN LMS.COLLATERAL  COLL WITH(NOLOCK)
	ON AM.ACCOUNT_NO = COLL.ACCOUNT_NO
LEFT JOIN MMS.CLIENT CL WITH(NOLOCK)
	ON AM.MEMBER_NO = CL.MEMBER_NO
LEFT JOIN LMS.APPRAISAL APP WITH(NOLOCK)
	ON AM.ACCOUNT_NO = APP.ACCOUNT_NO AND APP.ID =(SELECT MAX(ID) FROM LMS.APPRAISAL WHERE ACCOUNT_NO  = AM.ACCOUNT_NO)
WHERE AM.IS_CLOSE = 0

GO


