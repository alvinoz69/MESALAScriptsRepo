EXEC DMS_FINALIZER
EXEC LMS_FINALIZER
EXEC CMN_FINALIZER
EXEC MMS_FINALIZER
use cbdb_reports
--EXEC dbo.cmn_staging
--EXEC dbo.mms_staging_V2
--EXEC dbo.dms_staging
--EXEC dbo.lms_staging
--EXEC dbo.ctl_staging
--EXEC dbo.brc_staging

SELECT * FROM CBDB_REPORTS.CMN.DATA_COPY_HEADER
SELECT * FROM CBDB_REPORTS.CMN.DATA_COPY_DETAIL
SELECT * FROM CBDB_REPORTS.LMS.APPRAISAL
SELECT * FROM CBDB_REPORTS.DMS.ACCT_ANNUAL_BALANCE
SELECT * FROM CBDB_REPORTS.RPT.ERROR_DETAILS ORDER BY ID DESC                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         C
SELECT * FROM CBDB_REPORTS.CMN.BANK_SUNDRY
SELECT * FROM CBDB_STAGE.CMN.DATA_COPY_HEADER
SELECT * FROM CBDB_STAGE.CMN.DATA_COPY_DETAIL
SELECT * FROM CBDB_STAGE.CMN.BULK_ITEMS
SELECT * FROM CBDB_STAGE.CMN.BILLING
SELECT * FROM CBDB_REPORTS.MMS.CO_TRANSFER_HISTORY
SELECT * FROM CBDB_STAGE.CMN.BIZ_JOURNAL WHERE TRAN_CODE = 4313
SELECT * FROM CBDB_REPORTS.MMS.RELATIONSHIP
SELECT * FROM CBDB_STAGE.LMS.ACCOUNT_PDC
SELECT * FROM CBDB_REPORTS.LMS.ACCOUNT_PDC
SELECT * FROM CBDB_REPORTS.LMS.INSURANCE
SELECT * FROM CBDB_STAGE.LMS.ACCOUNT_INSURANCE
SELECT * FROM CBDB_REPORTS.LMS.ACCOUNT_CO_MAKER
SELECT * FROM CBDB_STAGE.CTL.CFG_PROPERTY_TYPE
SELECT * FROM CBDB_STAGE.CTL.PROPERTY
SELECT * FROM CBDB_REPORTS.LMS.ACCOUNT_MASTER
SELECT COUNT(1) FROM CBDB_STAGE.LMS.ACCOUNT_INFO
SELECT * FROM CBDB_REPORTS.RPT.SP_LOG ORDER BY ID DESC


UPDATE CBDB_REPORTS.RPT.SP_LOG SET STATUS = 3 WHERE ID = 23


SELECT INACTIV_ANNIV_DATE, ACCOUNT_TYPE,* FROM CBDB_REPORTS.DMS.ACCOUNT_MASTER
SELECT NET_PROCEEDS,* FROM CBDB_REPORTS.LMS.ACCOUNT_MASTER
SELECT INSTALLMENT_NO,* FROM CBDB_REPORTS.LMS.ACCOUNT_PDC
SELECT * FROM CBDB_REPORTS.RPT.ERROR_DETAILS ORDER BY ID DESC


UPDATE  CBDB_REPORTS.CMN.DATA_COPY_DETAIL
SET STATUS = 3
WHERE ID = 13379

UPDATE  CBDB_REPORTS.CMN.DATA_COPY_HEADER
SET STATUS = 3
WHERE ID = 17

--UPDATE CBDB_STAGE.CMN.DATA_COPY_DETAIL
--SET IS_FAILED = 0
--WHERE ID = 1

--DELETE FROM CBDB_REPORTS.CMN.DATA_COPY_DETAIL WHERE HEADER_ID = 71
--DELETE FROM CBDB_REPORTS.CMN.DATA_COPY_HEADER WHERE ID = 9
--DELETE FROM CBDB_REPORTS.CMN.DATA_COPY_DETAIL WHERE HEADER_ID = 9

--TRUNCATE TABLE CBDB_REPORTS.CMN.DATA_COPY_HEADER
--TRUNCATE TABLE CBDB_REPORTS.CMN.BANK_SUNDRY
--TRUNCATE TABLE CBDB_REPORTS.CMN.BILLING
--DELETE FROM CBDB_REPORTS.MMS.ADDRESS
--DELETE FROM CBDB_REPORTS.MMS.CFG_CORP_CONTACT_PERSON
--DELETE FROM CBDB_REPORTS.MMS.CLIENT
--DELETE FROM CBDB_REPORTS.MMS.CLIENT_STATUS_HISTORY
--DELETE FROM CBDB_REPORTS.MMS.FAMILY_GROUP
--DELETE FROM CBDB_REPORTS.MMS.PEP_INFO
--DELETE FROM CBDB_REPORTS.MMS.PRIM_SEC_XREF
--DELETE FROM CBDB_REPORTS.MMS.RELATIONSHIP
--DELETE FROM CBDB_REPORTS.MMS.CLIENT_OTHER_INFO
--DELETE FROM CBDB_REPORTS.CMN.BILLING
--DELETE FROM CBDB_REPORTS.CMN.BANK_SUNDRY
--DELETE FROM CBDB_REPORTS.LMS.ACCOUNT_CO_MAKER
--DELETE FROM CBDB_REPORTS.LMS.ACCOUNT_MASTER
--DELETE FROM CBDB_REPORTS.LMS.ACCOUNT_PDC
--DELETE FROM CBDB_REPORTS.LMS.ACCT_BAL_HISTORY
--DELETE FROM CBDB_REPORTS.LMS.APPRAISAL
--DELETE FROM CBDB_REPORTS.LMS.AUTODEBIT_HISTORY
--DELETE FROM CBDB_REPORTS.LMS.COLLATERAL
--DELETE FROM CBDB_REPORTS.LMS.INSURANCE
--DELETE FROM CBDB_REPORTS.LMS.REMITTANCE
--DELETE FROM CBDB_REPORTS.[DMS].[ACCOUNT_BAL_HISTORY]
--DELETE FROM CBDB_REPORTS.[DMS].[ACCOUNT_MASTER]
--DELETE FROM CBDB_REPORTS.DMS.ACCT_ANNUAL_BALANCE
--DELETE FROM CBDB_REPORTS.[DMS].TD_ACCOUNT_INFO
--DELETE FROM CBDB_REPORTS.CMN.DATA_COPY_DETAIL




SELECT * FROM CBDB_STAGE.MMS.ADDRESS
SELECT * FROM CBDB_STAGE.MMS.CONTACT

SELECT * FROM CBDB_REPORTS.MMS.CLIENT WHERE MEMBER_NO = '2019640001014'
SELECT * FROM CBDB_STAGE.MMS.CLIENT WHERE CIF_NO = '2019640000000'
SELECT * FROM CBDB_STAGE.MMS.CONTACT

SELECT * FROM CBDB_STAGE.MMS.MEMBER_DBP WHERE CIF_NO = '2019640001014'
SELECT * FROM CBDB_STAGE.CMN.NA_PICKLIST WHERE CATEGORY LIKE '%HOLD%'
SELECT * FROM CBDB_STAGE.MMS.CLIENT_RELATION WHERE RELATIONSHIP_CODE = '001'
SELECT DATE_OPEN,* FROM CBDB_STAGE.MMS.CLIENT
SELECT * FROM CBDB_STAGE.MMS.MEMBER_DBP
SELECT * FROM CBDB_REPORTS.MMS.RELATIONSHIP
SELECT * FROM CBDB_REPORTS.MMS.CLIENT_STATUS_HISTORY
SELECT * FROM CBDB_STAGE.MMS.CLIENT_STATUS_HISTORY
SELECT * FROM CBDB_REPORTS.MMS.ADDRESS
SELECT * FROM CBDB_STAGE.MMS.ADDRESS
SELECT * FROM CBDB_REPORTS.MMS.PEP_INFO
SELECT * FROM CBDB_REPORTS.MMS.PRIM_SEC_XREF 
SELECT * FROM CBDB_STAGE.CMN.CS_COUNTRY
SELECT * FROM CBDB_REPORTS.MMS.CFG_CORP_CONTACT_PERSON
SELECT * FROM CBDB_REPORTS.DMS.ACCOUNT_MASTER
SELECT * FROM CBDB_REPORTS.LMS.ACCOUNT_MASTER
SELECT * FROM CBDB_REPORTS.RPT.ERROR_DETAILS
SELECT * FROM CBDB_REPORTS.CMN.CFG_INSURANCE_TYPE
SELECT * FROM CBDB_STAGE.CTL.TAX_INSURANCE
SELECT INITIAL_DEPOSIT_DATE, INACTIVITY_DAYS_COUNTER,* FROM CBDB_STAGE.DMS.ACCOUNT_INFO

SELECT * FROM CBDB_STAGE.CMN.NA_PICKLIST WHERE CATEGORY LIKE '%MembershipStatus%'

SELECT * FROM CBDB_STAGE.CMN.NA_PICKLIST WHERE DESCRIPTION LIKE '%Beneficiary%'

SELECT * FROM MVDB_CB_BDS.DBO.CS_COUNTRY WHERE CATEGORY LIKE '%Civil%'

SELECT * FROM CBDB_STAGE.MMS.MEMBER_SPA_GAR

SELECT * FROM CBDB_STAGE.CTL.TAX_INSURANCE

SELECT * FROM CBDB_STAGE.MMS.CLIENT_STATUS_HISTORY

SELECT 
	(CASE 
		WHEN DATEDIFF(mm, (SELECT CURRENT_BUSINESS_DATE FROM CBDB_STAGE.CMN.BANK_SUNDRY), DBP.DBP_ENROLLMENT_DATE) = 0 AND DATEDIFF(mm, (SELECT CURRENT_BUSINESS_DATE FROM CBDB_STAGE.CMN.BANK_SUNDRY), DBP.DBP_END_DATE) > 0
		THEN 'CREATE'
		WHEN DATEDIFF(mm, (SELECT CURRENT_BUSINESS_DATE FROM CBDB_STAGE.CMN.BANK_SUNDRY), DBP.DBP_END_DATE) = 0
		THEN 'DELETE'
	END
	) 
	 AS 'DBP_REMARKS',
	(CASE 
		WHEN DATEDIFF(mm, (SELECT CURRENT_BUSINESS_DATE FROM CBDB_STAGE.CMN.BANK_SUNDRY), SPS_DBP.DBP_ENROLLMENT_DATE) = 0 AND DATEDIFF(mm, (SELECT CURRENT_BUSINESS_DATE FROM CBDB_STAGE.CMN.BANK_SUNDRY), SPS_DBP.DBP_END_DATE) > 0
		THEN 'CREATE'
		WHEN DATEDIFF(mm, (SELECT CURRENT_BUSINESS_DATE FROM CBDB_STAGE.CMN.BANK_SUNDRY), SPS_DBP.DBP_END_DATE) = 0
		THEN 'DELETE'
	END
	) 
	 AS 'DBP_SPS_REMARKS'
	--,C.* 
FROM CBDB_STAGE.MMS.CLIENT C WITH(NOLOCK)
LEFT JOIN CBDB_STAGE.MMS.MEMBER_DBP DBP WITH(NOLOCK)
ON C.CIF_NO = DBP.CIF_NO AND DBP.ID = (SELECT MAX(ID) FROM CBDB_STAGE.MMS.MEMBER_DBP WHERE CIF_NO = C.CIF_NO)
LEFT JOIN CBDB_STAGE.MMS.CLIENT_RELATION SPS WITH(NOLOCK)
ON C.CIF_NO = SPS.CIF_NO AND SPS.RELATIONSHIP_CODE = '001' -- SPOUSE
LEFT JOIN CBDB_STAGE.MMS.MEMBER_DBP SPS_DBP WITH(NOLOCK)
ON SPS.RELATED_CIF_NO = SPS_DBP.CIF_NO

SELECT * FROM CBDB_STAGE.LMS.PRODUCT_OTHER_CONFIG
SELECT * FROM CBDB_STAGE.LMS.ACCOUNT_INFO

SELECT * FROM DMS.ACCT_ANNUAL_BALANCE
SELECT COVERAGE FROM CBDB_REPORTS.MMS.CLIENT
SELECT * FROM CBDB_STAGE.CMN.NA_PICKLIST WHERE CATEGORY = 'BDS_GAR_COVERAGE'
SELECT * FROM CBDB_STAGE.CMN.NA_PICKLIST WHERE CATEGORY = 'BDS_SPA_COVERAGE'

SELECT * FROM CBDB_STAGE.MMS.CFG_RISK_CATEGORY
SELECT RISK_CLASS_CODE,* FROM CBDB_STAGE.MMS.CLIENT

SELECT DISTINCT MEMBER_CLASS FROM CBDB_REPORTS.MMS.CLIENT

SELECT CL.CIF_NO
	  --,SPS_DBP.DBP_ENROLLMENT_DATE
	  --,SPS_DBP.DBP_END_DATE
	  ,SPS.*
FROM CBDB_STAGE.MMS.CLIENT CL
LEFT JOIN CBDB_STAGE.MMS.CLIENT_RELATION SPS WITH(NOLOCK)
	ON CL.CIF_NO = SPS.CIF_NO AND SPS.RELATIONSHIP_CODE = '001' -- SPOUSE
--LEFT JOIN CBDB_STAGE.MMS.MEMBER_DBP SPS_DBP WITH(NOLOCK)
--	ON SPS.RELATED_CIF_NO = SPS_DBP.CIF_NO
WHERE CL.CIF_NO = '2019640001014'

SELECT * FROM CBDB_STAGE.MMS.MEMBER_DBP WHERE CIF_NO = '2019640001014'

SELECT * FROM CBDB_STAGE.DMS.ACCOUNT_INFO
SELECT * FROM CBDB_REPORTS.DMS.ACCOUNT_MASTER

SELECT * FROM CBDB_STAGE.LMS.ACCOUNT_INFO
SELECT * FROM CBDB_REPORTS.LMS.ACCOUNT_MASTER

SELECT * FROM CBDB_STAGE.LMS.ACCOUNT_BALANCE_HISTORY
SELECT * FROM CBDB_STAGE.DMS.ACCOUNT_BALANCE_HISTORY

SELECT * FROM CBDB_REPORTS.MMS.CLIENT  
SELECT BILLING_GROUP_CODE,* FROM CBDB_STAGE.MMS.CLIENT WHERE CIF_NO = '100035575'
SELECT * FROM CBDB_REPORTS.DMS.ACCOUNT_MASTER
SELECT * FROM CBDB_REPORTS.LMS.ACCOUNT_MASTER WHERE MEMBER_NO = '100035575'

SElECT MEMBER_NO, PREF_EMAIL_ADD FROM CBDB_REPORTS.MMS.CLIENT
SELECT C.CIF_NO, C.FIRST_NAME, C.LAST_NAME, C.TERMINATION_DATE FROM CBDB_STAGE.MMS.CLIENT C

SELECT * FROM CBDB_STAGE.MMS.CFG_RISK_CATEGORY

SELECT * FROM CBDB_STAGE.CMN.NA_PICKLIST WHERE CATEGORY LIKE '%PAYMENT%'
SELECT * FROM CBDB_REPORTS.MMS.CLIENT WHERE MEMBER_TYPE_CODE = 'C'

SELECT CIF_NO, TYPE FROM  CBDB_STAGE.MMS.MEMBER_SPA_GAR

SELECT * FROM CBDB_REPORTS.MMS.CLIENT
SELECT * FROM CBDB_STAGE.MMS.CLIENT

SELECT * FROM CBDB_REPORTS.LMS.ACCOUNT_MASTER
SELECT * FROM CBDB_REPORTS.DMS.ACCOUNT_MASTER WHERE ACCOUNT_NO = '61000400000107'

SELECT * FROM CBDB_STAGE.DMS.ACCOUNT_PLACEMENT
SELECT * FROM CBDB_STAGE.DMS.PRODUCT

SELECT * FROM CBDB_REPORTS.LMS.COLLATERAL

SELECT * FROM CBDB_REPORTS.RPT.REPORT_GENERATOR WHERE FILE_NAME LIKE '%SumLoanRel%'

SELECT * FROM CBDB_REPORTS.MMS.CLIENT
SELECT * FROM CBDB_REPORTS.LMS.

SELECT * FROM CBDB_REPORTS.CMN.BANK_SUNDRY

SELECT * FROM CBDB_STAGE.MMS.CFG_RISK_CATEGORY

SELECT RISK_CLASS_CODE,* FROM CBDB_STAGE.MMS.CLIENT

SELECT * FROM