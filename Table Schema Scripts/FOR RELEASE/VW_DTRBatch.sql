DROP VIEW IF EXISTS [dbo].[VW_DTRBatch]

/****** Object:  View [dbo].[VW_DTRBatch]    Script Date: 02/03/2020 9:50:39 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[VW_DTRBatch] AS

SELECT
  A.TRAN_CODE
 ,A.OR_NO 'REFERENCE'
 ,B.ACCT_NAME 'MEMBERS_NAME'
 ,B.ACCOUNT_NO
 ,B.EMPLOYEE_NO
 ,C.CORP_CODE 'COMPANY'
 ,B.LOAN_AMOUNT
 ,B.PRINCIPAL_AMOUNT
 ,B.INTEREST_AMOUNT
 ,A.AIR
 ,A.PENALTY
 ,A.COLLECTION_AGENT_FEE
 ,A.CCA
 ,A.SD
 ,A.AP
 ,A.AR
 ,A.USER_NAME 'USER_ID'
FROM RPT.LMS_HISTORY_CONSOLIDATED A WITH(NOLOCK)
LEFT JOIN LMS.ACCOUNT_MASTER      B WITH(NOLOCK) ON A.ACCOUNT_NO = B.ACCOUNT_NO
LEFT JOIN MMS.CLIENT              C WITH(NOLOCK) ON B.MEMBER_NO = C.MEMBER_NO
WHERE DATEDIFF(DAY, A.BUSINESS_DATE, (SELECT CURRENT_BUSINESS_DATE FROM CMN.BANK_SUNDRY)) = 0
  AND A.IS_REVERSAL <> 1
  AND A.USER_NAME IN ('SYS') --BATCH
GO