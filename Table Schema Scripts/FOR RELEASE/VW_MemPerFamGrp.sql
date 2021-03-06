DROP VIEW IF EXISTS [dbo].[VW_MemPerFamGrp]

/****** Object:  View [dbo].[VW_MemPerFamGrp]    Script Date: 18/02/2020 2:09:04 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[VW_MemPerFamGrp] AS
SELECT 
B.CORP_NAME,
A.PRIMARY_MEMBER_NO,
A.PRIMARY_MEMBER_STATUS,
A.PRIMARY_MEMBERSHIP_DATE,
A.PRIMARY_MEMBER_NAME,
A.SEC_MEMBER_NO,
A.SEC_MEMBERSHIP_DATE,
A.SEC_MEMBER_NAME,
A.SEC_MEMBER_STATUS,
A.RELATIONSHIP_TO_PRIMARY
FROM MMS.FAMILY_GROUP A WITH(NOLOCK)
LEFT JOIN MMS.CLIENT B WITH(NOLOCK) ON A.PRIMARY_MEMBER_NO = B.MEMBER_NO
GO