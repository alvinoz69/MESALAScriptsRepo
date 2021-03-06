DROP VIEW IF EXISTS [dbo].[VW_PDCForPostng]

/****** Object:  View [dbo].[VW_PDCForPostng]    Script Date: 11/12/2019 1:33:02 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[VW_PDCForPostng] AS
SELECT
C.MEMBER_NO 'ACCOUNT NO',
C.FULL_NAME 'NAME',
A.DRAWER_BANK_CODE 'ISSUING BANK',
A.CHECK_NO,
A.CHECK_AMOUNT
FROM LMS.ACCOUNT_PDC 			A WITH(NOLOCK)
LEFT JOIN LMS.ACCOUNT_MASTER 	B WITH(NOLOCK) ON A.ACCOUNT_NO = B.ACCOUNT_NO 																				
LEFT JOIN MMS.CLIENT			C WITH(NOLOCK) ON B.MEMBER_NO = C.MEMBER_NO

WHERE 
DATEDIFF(DAY,(SELECT NEXT_BUSINESS_DATE FROM CMN.BANK_SUNDRY),A.POSTED_DATE) = 0 --NEXT BIZ DATE SHOULD BE EQUAL TO POSTED DATE

GO


