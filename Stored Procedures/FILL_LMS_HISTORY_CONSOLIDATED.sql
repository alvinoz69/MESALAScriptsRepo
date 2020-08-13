
USE CBDB_STAGE
GO

DROP PROCEDURE IF EXISTS dbo.FILL_LMS_HISTORY_CONSOLIDATED

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.FILL_LMS_HISTORY_CONSOLIDATED
	@HEADER_ID BIGINT,
	@BUSINESS_DATE DATE,
	@IS_COMPLETED INT = 0,
	@SP_NAME NVARCHAR(50) = 'LMS_HISTORY_CONSOLIDATED',
	@TABLE_NAME NVARCHAR(100) = 'RPT.LMS_HISTORY_CONSOLIDATED',
	@SOURCE_TABLE NVARCHAR(100) = 'LMS.ACCT_BAL_HISTORY',
	@INSERTED_RECORDS BIGINT = 0,
	@ERR_MSG NVARCHAR(500) = '',
	@DURATION BIGINT = 0,
	@ID_CONTROL BIGINT = 0,
	@IS_DUMP BIT = 0,
	@BATCH_SIZE INT = 50000,
	@RESULTS BIGINT = 0
AS

BEGIN
	--START OF SET TO INSERT
	
	SELECT @ID_CONTROL = ISNULL((SELECT MIN(A.ID) FROM CBDB_REPORTS.LMS.ACCT_BAL_HISTORY A WITH(NOLOCK) INNER JOIN CBDB_STAGE.CMN.TRAN_ITEM B WITH(NOLOCK) ON A.TRAN_CODE = B.TRAN_CODE WHERE B.PRIMARY_TRAN = 1 AND A.HEADER_ID = (SELECT TOP 1 HEADER_ID FROM CBDB_REPORTS.CMN.DATA_COPY_DETAIL WITH(NOLOCK) WHERE HEADER_ID = @HEADER_ID AND TABLE_NAME = @SOURCE_TABLE ORDER BY ID DESC)), 0)
	
	--CHECK STATUS IF COMPLETED
	SET @IS_COMPLETED = ISNULL((SELECT TOP 1 [STATUS] FROM CBDB_REPORTS.RPT.SP_LOG WITH(NOLOCK) WHERE BUSINESS_DATE = @BUSINESS_DATE AND HEADER_ID = @HEADER_ID AND NAME = @SP_NAME ORDER BY ID DESC),0)
	
	--LOGGED IF PROCESS ALREADY COMPLETED
	IF (@IS_COMPLETED = 4) BEGIN  PRINT @SP_NAME + ' IS ALREADY COMPLETED.' END
	IF @IS_COMPLETED <> 4
	BEGIN	
		SET @IS_DUMP = ISNULL((SELECT TOP 1 IS_DUMP FROM CBDB_REPORTS.CMN.DATA_COPY_DETAIL WITH(NOLOCK) WHERE TABLE_NAME = @SOURCE_TABLE AND HEADER_ID = @HEADER_ID ORDER BY ID DESC),0)
			
		--IF TABLE HAS ERROR PREVIOUSLY, DELETE ALL RECORDS FROM TABLE WITH CURRENT HEADER_ID	
		IF @IS_COMPLETED = 3
		BEGIN
			EXEC ('DELETE FROM CBDB_REPORTS.' + @TABLE_NAME + ' WHERE BUSINESS_DATE=' + ''''+ @BUSINESS_DATE + ''''+'')
		END

		--IF DUMP, TRUNCATE THE TABLE BEFORE INSERTING
		IF @IS_DUMP = 1 AND @TABLE_NAME IS NOT NULL
		BEGIN
			EXEC ('TRUNCATE TABLE CBDB_REPORTS.' + @TABLE_NAME)
		END

		--LOG START

		BEGIN
			IF NOT EXISTS (SELECT 1 FROM CBDB_REPORTS.RPT.SP_LOG WITH(NOLOCK) WHERE BUSINESS_DATE = @BUSINESS_DATE AND [NAME] = @SP_NAME AND STATUS IN (3,1))
			BEGIN
				INSERT INTO CBDB_REPORTS.RPT.SP_LOG (HEADER_ID  ,NAME	  ,BUSINESS_DATE  ,TIME_STARTED ,STATUS)
										VALUES		(@HEADER_ID ,@SP_NAME ,@BUSINESS_DATE ,GETDATE()    ,1)
				PRINT '---------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
				PRINT 'STATUS : STARTED   | PROCEDURE NAME : ' + @SP_NAME + ' | HEADER_ID : ' + CAST(@HEADER_ID AS VARCHAR(MAX)) + ' | TIME STARTED : ' + CAST(GETDATE() AS VARCHAR(MAX)) + ' | BUSINESS DATE : ' + CAST(@BUSINESS_DATE AS VARCHAR(MAX))			
			END
		END

		--BATCH INSERT OF 100000
		BEGIN TRY
			SELECT @INSERTED_RECORDS = 0,			
				   @RESULTS = 1; --STORES THE ROW COUNT AFTER EACH SUCCESSFUL BATCH
			WHILE (@RESULTS > 0)
			BEGIN
			--PRINT 'ID CONTROL ' + CAST(@ID_CONTROL AS NVARCHAR(50))
			--PRINT 'RESULTS  ' + CAST(@RESULTS AS NVARCHAR(150))
			--->INSERT INTO SELECT STATEMENT
				INSERT INTO CBDB_REPORTS.RPT.LMS_HISTORY_CONSOLIDATED WITH(TABLOCK)
						(ACCOUNT_NO     ,TRAN_CODE     ,SEQUENCENO				   ,BRANCH_CODE		,BUSINESS_DATE	   ,USER_NAME	  ,MNEMONIC     ,MEMBER_NO     ,PRODUCT_CODE     ,ACCOUNT_STATUS_CODE     ,IS_REVERSAL     ,AR_NO     ,OR_NO     ,OR_AR_DATE     ,TRAN_CODE_DESCRIPTION					  ,TRAN_TYPE     ,PRINCIPAL_BALANCE     ,INTEREST_BALANCE     ,OUTSTANDING_BALANCE           ,AIR_BALANCE     ,DEPOSIT_ACCOUNT_NO     ,HOST_ID    ,IS_PAYMENT   	,AIR ,PRINCIPAL ,INTEREST ,PENALTY ,AP ,AR ,COLLECTION_AGENT_FEE ,CCA ,SD ,PREV_LOAN,TRAN_TOTAL)                                                                                                                                              
				SELECT   ABH.ACCOUNT_NO ,ABH.TRAN_CODE ,ABH.SEQ_NO AS 'SEQUENCENO' ,ABH.BRANCH_CODE ,ABH.BUSINESS_DATE ,ABH.USER_NAME ,ABH.MNEMONIC ,ACM.MEMBER_NO ,ACM.PRODUCT_CODE ,ACM.ACCOUNT_STATUS_CODE ,ABH.IS_REVERSAL ,ABH.AR_NO ,ABH.OR_NO ,ABH.OR_AR_DATE ,TR.TRAN_NAME AS 'TRAN_CODE_DESCRIPTION' ,ABH.TRAN_TYPE ,ABH.PRINCIPAL_BALANCE ,ABH.INTEREST_BALANCE ,NULL AS 'OUTSTANDING_BALANCE' ,ABH.AIR_BALANCE ,ABH.DEPOSIT_ACCOUNT_NO ,ABH.HOST_ID,LTC.IS_PAYMENT
				,ISNULL(AIR.AMOUNT,0)  AS 'AIR' 
				,IIF(LTC.TRAN_NATURE IS NULL OR LTC.TRAN_NATURE = 0,ISNULL(DUP_PRIN.AMOUNT,0),0) AS 'PRINCIPAL' 
				,ISNULL(ITR.AMOUNT,0) AS 'INTEREST' 
				,ISNULL(PEN.AMOUNT,0) AS 'PENALTY' 
				,0 AS 'AP'    --WAITING FOR TRAN CODE
				,0 AS 'AR'	--WAITING FOR TRAN CODE
				,0 AS 'COLLECTION_AGENT_FEE' --WAITING FOR TRAN CODE
				,ISNULL(CCA.AMOUNT,0) AS 'CCA' 
				,ISNULL(SD.AMOUNT,0) AS 'SD' 
				,0 AS 'PREV_LOAN' 
				,IIF(LTC.TRAN_NATURE IS NULL OR LTC.TRAN_NATURE = 0,ISNULL(DUP_PRIN.AMOUNT,0),0) + ISNULL(AIR.AMOUNT,0) + ISNULL(ITR.AMOUNT,0) + ISNULL(PEN.AMOUNT,0)+ISNULL(SD.AMOUNT,0)+ISNULL(CCA.AMOUNT,0) AS 'TRAN_TOTAL'
				FROM CBDB_REPORTS.LMS.ACCT_BAL_HISTORY  ABH WITH(NOLOCK)
				INNER JOIN (
					SELECT MAX(ID) ID, ACCOUNT_NO, TRAN_CODE, BUSINESS_DATE, SEQ_NO, USER_NAME, BRANCH_CODE FROM CBDB_REPORTS.LMS.ACCT_BAL_HISTORY WITH(NOLOCK)
					GROUP BY ACCOUNT_NO, TRAN_CODE, BUSINESS_DATE, SEQ_NO, USER_NAME, BRANCH_CODE
				) MAX_ABH 	ON ABH.ID = MAX_ABH.ID AND ABH.ACCOUNT_NO = MAX_ABH.ACCOUNT_NO AND ABH.TRAN_CODE = MAX_ABH.TRAN_CODE AND ABH.SEQ_NO = MAX_ABH.SEQ_NO AND ABH.BUSINESS_DATE = MAX_ABH.BUSINESS_DATE
				LEFT JOIN CBDB_REPORTS.LMS.ACCOUNT_MASTER ACM WITH(NOLOCK)
					ON	ABH.ACCOUNT_NO  = ACM.ACCOUNT_NO
				LEFT JOIN CBDB_STAGE.CMN.TRAN_ITEM TR WITH(NOLOCK)
					ON ABH.TRAN_CODE = TR.TRAN_CODE
				LEFT JOIN CBDB_REPORTS.CMN.LHC_TRAN_CONFIG LTC WITH (NOLOCK)
					ON ABH.TRAN_CODE = LTC.TRAN_CODE
				LEFT JOIN 
					(SELECT ACCOUNT_NO, SUM(ISNULL(AMOUNT,0)) AS AMOUNT, SEQ_NO, BUSINESS_DATE, USER_NAME, A.TRAN_CODE FROM CBDB_REPORTS.LMS.ACCT_BAL_HISTORY A WITH(NOLOCK) 
					INNER JOIN CBDB_STAGE.CMN.TRAN_ITEM B WITH(NOLOCK) ON A.TRAN_CODE = B.TRAN_CODE AND B.PRIMARY_TRAN  = 1 GROUP BY ACCOUNT_NO, SEQ_NO, BUSINESS_DATE, USER_NAME,A.TRAN_CODE) DUP_PRIN
					ON ABH.ACCOUNT_NO = DUP_PRIN.ACCOUNT_NO AND ABH.SEQ_NO = DUP_PRIN.SEQ_NO
					AND ABH.BUSINESS_DATE = DUP_PRIN.BUSINESS_DATE
					AND ABH.USER_NAME = DUP_PRIN.USER_NAME
					AND ABH.TRAN_CODE = DUP_PRIN.TRAN_CODE
				LEFT JOIN 
					(SELECT ACCOUNT_NO, SUM(ISNULL(AMOUNT,0)) AS AMOUNT, SEQ_NO, BUSINESS_DATE, USER_NAME FROM CBDB_REPORTS.LMS.ACCT_BAL_HISTORY A WITH(NOLOCK) 
					INNER JOIN CBDB_REPORTS.CMN.LHC_TRAN_CONFIG B WITH(NOLOCK) ON A.TRAN_CODE = B.TRAN_CODE AND (B.TRAN_NATURE = 1 OR (B.TRAN_NATURE = 10 AND A.ACCOUNT_STATUS_CODE <> '01')) GROUP BY ACCOUNT_NO, SEQ_NO, BUSINESS_DATE, USER_NAME) ITR
					ON ABH.ACCOUNT_NO = ITR.ACCOUNT_NO AND ABH.SEQ_NO = ITR.SEQ_NO
					AND ABH.BUSINESS_DATE = ITR.BUSINESS_DATE
					AND ABH.USER_NAME = ITR.USER_NAME
					AND TR.PROCESS_UNIQUE_KEY <> 'LoansStatusReclassificationDoProcess'
				LEFT JOIN 
					(SELECT ACCOUNT_NO, SUM(ISNULL(AMOUNT,0)) AS AMOUNT, SEQ_NO, BUSINESS_DATE, USER_NAME FROM CBDB_REPORTS.LMS.ACCT_BAL_HISTORY A WITH(NOLOCK) 
					INNER JOIN CBDB_REPORTS.CMN.LHC_TRAN_CONFIG B WITH(NOLOCK) ON A.TRAN_CODE = B.TRAN_CODE AND (B.TRAN_NATURE = 2 OR (B.TRAN_NATURE = 10 AND A.ACCOUNT_STATUS_CODE = '01')) GROUP BY ACCOUNT_NO, SEQ_NO, BUSINESS_DATE, USER_NAME) AIR
					ON ABH.ACCOUNT_NO = AIR.ACCOUNT_NO AND ABH.SEQ_NO = AIR.SEQ_NO
					AND ABH.BUSINESS_DATE = AIR.BUSINESS_DATE
					AND ABH.USER_NAME = AIR.USER_NAME
					AND TR.PROCESS_UNIQUE_KEY <> 'LoansStatusReclassificationDoProcess'
				LEFT JOIN 
					(SELECT ACCOUNT_NO, SUM(ISNULL(AMOUNT,0)) AS AMOUNT, SEQ_NO, BUSINESS_DATE, USER_NAME FROM CBDB_REPORTS.LMS.ACCT_BAL_HISTORY A WITH(NOLOCK)
					INNER JOIN CBDB_REPORTS.CMN.LHC_TRAN_CONFIG B WITH(NOLOCK) ON A.TRAN_CODE = B.TRAN_CODE AND B.TRAN_NATURE = 3 GROUP BY ACCOUNT_NO, SEQ_NO, BUSINESS_DATE, USER_NAME) PEN
					ON ABH.ACCOUNT_NO = PEN.ACCOUNT_NO AND ABH.SEQ_NO = PEN.SEQ_NO
					AND ABH.BUSINESS_DATE = PEN.BUSINESS_DATE
					AND ABH.USER_NAME = PEN.USER_NAME
					AND TR.PROCESS_UNIQUE_KEY <> 'LoansStatusReclassificationDoProcess'
				LEFT JOIN 
					(SELECT ACCOUNT_NO, SUM(ISNULL(AMOUNT,0)) AS AMOUNT, SEQ_NO, BUSINESS_DATE, USER_NAME FROM CBDB_REPORTS.LMS.ACCT_BAL_HISTORY A WITH(NOLOCK)
					INNER JOIN CBDB_REPORTS.CMN.LHC_TRAN_CONFIG B WITH(NOLOCK) ON A.TRAN_CODE = B.TRAN_CODE AND B.TRAN_NATURE = 4 GROUP BY ACCOUNT_NO, SEQ_NO, BUSINESS_DATE, USER_NAME) SD
					ON ABH.ACCOUNT_NO = SD.ACCOUNT_NO AND ABH.SEQ_NO = SD.SEQ_NO
					AND ABH.BUSINESS_DATE = SD.BUSINESS_DATE
					AND ABH.USER_NAME = SD.USER_NAME
					AND TR.PROCESS_UNIQUE_KEY <> 'LoansStatusReclassificationDoProcess'
				LEFT JOIN 
					(SELECT ACCOUNT_NO, SUM(ISNULL(AMOUNT,0)) AS AMOUNT, SEQ_NO, BUSINESS_DATE, USER_NAME FROM CBDB_REPORTS.LMS.ACCT_BAL_HISTORY A WITH(NOLOCK)
					INNER JOIN CBDB_REPORTS.CMN.LHC_TRAN_CONFIG B WITH(NOLOCK) ON A.TRAN_CODE = B.TRAN_CODE AND B.TRAN_NATURE = 5 GROUP BY ACCOUNT_NO, SEQ_NO, BUSINESS_DATE, USER_NAME) CCA
					ON ABH.ACCOUNT_NO = CCA.ACCOUNT_NO AND ABH.SEQ_NO = CCA.SEQ_NO
					AND ABH.BUSINESS_DATE = CCA.BUSINESS_DATE
					AND ABH.USER_NAME = CCA.USER_NAME
					AND TR.PROCESS_UNIQUE_KEY <> 'LoansStatusReclassificationDoProcess'


				/* NOT IN USE
				LEFT JOIN 
					(SELECT ACCOUNT_NO, SUM(ISNULL(AMOUNT,0)) AS AMOUNT, SEQ_NO, BUSINESS_DATE, USER_NAME FROM CBDB_REPORTS.LMS.ACCT_BAL_HISTORY A WITH(NOLOCK) 
					WHERE TRAN_CODE IN (2803,2830,2831,2833,2836,2837,2845,2847,2841,2842,2843,2844,2848) GROUP BY ACCOUNT_NO, SEQ_NO, BUSINESS_DATE, USER_NAME) CRI
					ON ABH.ACCOUNT_NO = CRI.ACCOUNT_NO AND ABH.SEQ_NO = CRI.SEQ_NO
					AND ABH.BUSINESS_DATE = CRI.BUSINESS_DATE
					AND ABH.USER_NAME = CRI.USER_NAME */

				/* NOT IN USE
				LEFT JOIN 
					(SELECT ACCOUNT_NO, SUM(ISNULL(AMOUNT,0)) AS AMOUNT, SEQ_NO, BUSINESS_DATE, USER_NAME FROM CBDB_REPORTS.LMS.ACCT_BAL_HISTORY WITH(NOLOCK) WHERE TRAN_CODE IN (2804) GROUP BY ACCOUNT_NO, SEQ_NO, BUSINESS_DATE, USER_NAME) DST
					ON ABH.ACCOUNT_NO = DST.ACCOUNT_NO AND ABH.SEQ_NO = DST.SEQ_NO
					AND ABH.BUSINESS_DATE = DST.BUSINESS_DATE
					AND ABH.USER_NAME = DST.USER_NAME */

			--->END OF INSERT INTO SELECT STATEMENT		
				WHERE TR.PRIMARY_TRAN = 1 AND ABH.ID >= @ID_CONTROL AND ABH.ID < @ID_CONTROL + @BATCH_SIZE	--BATCH CONTROL OF THE CURRENT BATCH	
				SET @RESULTS = @@ROWCOUNT --OBTAINING LATEST ROWCOUNT
				SET @INSERTED_RECORDS = @RESULTS + @INSERTED_RECORDS
				SET @ID_CONTROL = @ID_CONTROL + @BATCH_SIZE --NEXT BATCH
			END
		END TRY
		BEGIN CATCH
			SET @ERR_MSG = ERROR_MESSAGE()
			INSERT INTO CBDB_REPORTS.RPT.ERROR_DETAILS ([ERROR_NUMBER],[ERROR_SEVERITY],[ERROR_STATE],[ERROR_LINE],[ERROR_MESSAGE],[ERROR_TABLE],[TRANCOUNT],[REMARKS],[DATE_OCCURED])
			VALUES (ERROR_NUMBER(), ERROR_SEVERITY(), ERROR_STATE(),ERROR_LINE(),ERROR_MESSAGE(),@TABLE_NAME, CONVERT(varchar, @@TRANCOUNT),'',GETDATE());
			--LOG AFTER ERROR
			UPDATE CBDB_REPORTS.RPT.SP_LOG
				SET STATUS = 3
			WHERE HEADER_ID = @HEADER_ID AND BUSINESS_DATE = @BUSINESS_DATE
			PRINT '---------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
			PRINT 'STATUS : FAILED     | PROCEDURE NAME : ' + @SP_NAME + ' | HEADER_ID : ' + CAST(@HEADER_ID AS VARCHAR(MAX)) + ' | BUSINESS DATE : ' + CAST(@BUSINESS_DATE AS VARCHAR(MAX)) + ' | ERROR MESSAGE : ' + @ERR_MSG
			PRINT '---------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
		END CATCH

		--LOG FINISH IF THE TABLE HAS NO ERROR 
		IF @ERR_MSG IS NULL OR @ERR_MSG = ''
		BEGIN
			SET @DURATION = DATEDIFF(SECOND, (SELECT TOP 1 TIME_STARTED FROM CBDB_REPORTS.RPT.SP_LOG WHERE HEADER_ID = @HEADER_ID AND BUSINESS_DATE = @BUSINESS_DATE ORDER BY ID DESC), GETDATE())		
			UPDATE CBDB_REPORTS.RPT.SP_LOG
				SET STATUS	   = 4,
					TIME_ENDED = GETDATE(),
					DURATION   = @DURATION,
					INSERTED_RECORDS = @INSERTED_RECORDS
			WHERE HEADER_ID = @HEADER_ID AND BUSINESS_DATE = @BUSINESS_DATE AND NAME = @SP_NAME
			PRINT 'STATUS : COMPLETED | PROCEDURE NAME : ' + @SP_NAME + ' | HEADER_ID : ' + CAST(@HEADER_ID AS VARCHAR(MAX)) + ' | RECORD COUNT : ' + CAST(@INSERTED_RECORDS AS VARCHAR(MAX)) + ' | TIME ENDED : ' + CAST(GETDATE() AS VARCHAR(MAX)) + ' | DURATION : ' + CONVERT(VARCHAR(50),@DURATION)			       
			PRINT '---------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
		END
	END
END
