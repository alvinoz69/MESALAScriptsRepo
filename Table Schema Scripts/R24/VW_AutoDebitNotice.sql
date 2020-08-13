DROP VIEW IF EXISTS [dbo].[VW_AutoDebitNotice]

/****** Object:  View [dbo].[VW_AutoDebitNotice]    Script Date: 15/01/2020 11:26:36 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[VW_AutoDebitNotice] AS

SELECT
B.FULL_NAME,
B.LAST_NAME,
B.PREF_ADDRESS,
A.ACCOUNT_NO,
ISNULL(A.PRINCIPAL_AMOUNT,0) 'PRINCIPAL_AMOUNT',
ISNULL(A.INTEREST_AMOUNT,0) 'INTEREST_AMOUNT',
ISNULL(NULL,0) 'HANDLING_FEE',
ISNULL(A.PENALTY,0) 'PENALTY',
NULL 'SIGNATORY'
FROM      LMS.ACCOUNT_MASTER A WITH(NOLOCK)
RIGHT JOIN MMS.CLIENT         B WITH(NOLOCK) ON A.MEMBER_NO = B.MEMBER_NO
--WHERE A.IS_CLOSE = 0

GO