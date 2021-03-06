
----ACCOUNT MASTER
INSERT INTO CBDB_REPORTS.DMS.ACCOUNT_MASTER WITH(TABLOCK)
      (HEADER_ID          ,ACCOUNT_NO   ,ACCOUNT_NAME   ,ACCOUNT_OPEN_DATE                  ,PRODUCT_MNE                            ,PRODUCT_CODE     ,PRODUCT_DESC                       ,ACCOUNT_TYPE                              ,MEMBER_NO               ,ACCOUNT_STATUS                                   ,CAPCON_CEILING    ,LEDGER_BAL       ,AVAILABLE_BAL       ,PASSBOOK_BAL       ,FLOAT_BAL       ,FNWCAP_BAL                       ,LAST_FIN_TXN_DATE     ,INACTIV_ANNIV_DATE             ,IS_CLOSE   ,CLOSE_DATE   ,CLOSE_REASON                                  ,OLD_ACCT_NO   ,PLACEMENT_AMT        ,PLACEMENT_DATE    ,MATURITY_DATE,ROLLOVER_CTR    ,RENEWAL_CTR                         ,REFERENCE_NO           ,CCC_LIMIT           ,INITIAL_DEP_DATE)
SELECT 123 AS 'HEADER_ID' ,AI.ACCOUNT_NO,AI.ACCOUNT_NAME,AI.OPEN_DATE AS 'ACCOUNT_OPEN_DATE', PROD.PRODUCT_MNEMONIC AS 'PRODUCT_MNE',PROD.PRODUCT_CODE,PROD.PRODUCT_NAME AS 'PRODUCT_DESC',NULL AS 'ACCOUNT_TYPE' /*FOR FURTHER USE*/,AI.CIF_NO AS 'MEMBER_NO', AI.ACCOUNT_STATUS_CODE /*SHOULD BE DESCRIPTIVE*/, AI.CAPCON_CEILING,AB.LEDGER_BALANCE,AB.AVAILABLE_BALANCE,AB.PASSBOOK_BALANCE,AB.FLOAT_BALANCE,SVC.FNWCAP_AMOUNT AS 'FNWCAP_BAL', AI.LAST_FINANCIAL_TXN,  NULL AS 'INACTIVE_ANNIV_DATE',AI.IS_CLOSE,AI.CLOSE_DATE,AI.CLOSE_REASON_CODE /*SHOULD BE DESCRIPTIVE*/, AI.OLD_ACCT_NO, AI.PLACEMENT_AMOUNT, AI.PLACEMENT_DATE,MATURITY_DATE,AI.ROLLOVER_TYPE,AI.RENEWAL_TERM /*FOR CLARIFICATION*/,NULL AS 'REFERENCE_NO', NULL AS 'CCC_LIMIT', AI.INITIAL_DEPOSIT_DATE 
FROM CBDB_STAGE.DMS.ACCOUNT_INFO AI WITH(NOLOCK)
LEFT JOIN CBDB_STAGE.DMS.ACCOUNT_BALANCE AB WITH(NOLOCK)
	ON AI.ACCOUNT_NO = AB.ACCOUNT_NO
LEFT JOIN CBDB_STAGE.DMS.PRODUCT PROD WITH(NOLOCK)
	ON AI.DEPOSIT_PRODUCT_CODE = PROD.DEPOSIT_PRODUCT_CODE
LEFT JOIN CBDB_STAGE.DMS.ACCOUNT_SERVICES SVC WITH(NOLOCK)
	ON AI.ACCOUNT_NO = SVC.ACCOUNT_NO

-----DMS.ACCOUNT_BALANCE_HISTORY
INSERT INTO CBDB_REPORTS.DMS.ACCOUNT_BAL_HISTORY WITH(TABLOCK)
	(HEADER_ID          ,ABH.ACCOUNT_NO,CHANNEL_TYPE    ,AMOUNT     ,TRAN_CODE    ,TRAN_DESC                     ,MNEMONIC      ,TRAN_TYPE     ,TRAN_DATE     ,BRANCH_CODE    ,USER_NAME    ,SEQUENCENO     ,IS_REVERSAL     ,REVERSAL_ID)
SELECT NULL AS HEADER_ID,ABH.ACCOUNT_NO,ABH.CHANNEL_TYPE, ABH.AMOUNT,ABH.TRAN_CODE, ITEM.TRAN_NAME AS 'TRAN_DESC', ITEM.MNEMONIC, ABH.TRAN_TYPE, ABH.TRAN_DATE,ABH.BRANCH_CODE,ABH.USER_NAME, ABH.SEQUENCENO, ABH.IS_REVERSAL, ABH.REVERSAL_ID
FROM CBDB_STAGE.DMS.ACCOUNT_BALANCE_HISTORY ABH WITH(NOLOCK)
LEFT JOIN CBDB_STAGE.CMN.TRAN_ITEM ITEM WITH(NOLOCK)
	ON ABH.TRAN_CODE = ITEM.TRAN_CODE



---- DMS.TD_ACCOUNT_INFO
INSERT INTO CBDB_REPORTS.DMS.TD_ACCOUNT_INFO WITH(TABLOCK)
	(HEADER_ID,ACCOUNT_NO   ,PLACEMENT_NO     ,ROLLOVER_COUNTER     ,INTEREST_RATE     ,TERM_VALUE           ,TERM_UNIT           ,PRETERM_DATE              ,AUTO_ROLLOVER    ,PLACEMENT_STATUS     ,CREDIT_ACCOUNT     ,PLACEMENT_AMOUNT   ,PLACEMENT_DATE   ,MATURITY_DATE    ,TERMINATION_DATE          ,LAST_CREDIT_DATE    ,LAST_UPDATED_DATE     ,LAST_UPDATED_BY    ,LAST_APPROVED_BY     ,LAST_UPDATED_BRANCH ,TERMINATION_REASON)
SELECT 123    ,AI.ACCOUNT_NO, APL.PLACEMENT_NO, APL.ROLLOVER_COUNTER, APL.INTEREST_RATE, TERM_FREQUENCY_VALUE, TERM_FREQUENCY_UNIT, APL.PRE_TERMINATION_DATE ,APL.AUTO_ROLLOVER, APL.PLACEMENT_STATUS, APL.CREDIT_ACCOUNT,AI.PLACEMENT_AMOUNT,AI.PLACEMENT_DATE, AI.MATURITY_DATE, APL.PRE_TERMINATION_DATE ,APL.LAST_CREDIT_DATE, APL.LAST_UPDATED_DATE,APL.LAST_UPDATED_BY, APL.LAST_APPROVED_BY, LAST_UPDATED_BRANCH, APL.TERMINATION_REASON_CODE /*SHOULD BE DESCRIPTIVE*/
FROM CBDB_STAGE.DMS.ACCOUNT_INFO AI WITH(NOLOCK)
INNER JOIN CBDB_STAGE.DMS.ACCOUNT_PLACEMENT APL WITH(NOLOCK) ON AI.ACCOUNT_NO = APL.ACCOUNT_NO
LEFT JOIN CBDB_STAGE.DMS.PRODUCT PROD WITH(NOLOCK) ON AI.DEPOSIT_PRODUCT_CODE = PROD.DEPOSIT_PRODUCT_CODE
WHERE PROD.PRODUCT_MNEMONIC = 'TD'


