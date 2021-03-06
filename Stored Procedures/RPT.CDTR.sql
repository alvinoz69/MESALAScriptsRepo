USE [CBDB_STAGE]
DROP PROCEDURE IF EXISTS [dbo].[RPT_CDTR]
/****** Object:  StoredProcedure [dbo].[RPT_CDTR]    Script Date: 11/11/2019 3:06:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[RPT_CDTR] AS
begin
SET NOCOUNT ON;
declare @SET_ID bigint;
declare @PREV_SET_ID bigint; 
declare @TRAN_DATE date;
declare @PREV_ENDING_BALANCE decimal(18,2); set @PREV_ENDING_BALANCE = 0.00;
declare @BEG_BALANCE decimal(18,2); set @BEG_BALANCE = 0.00;
select @TRAN_DATE = CURRENT_BUSINESS_DATE from CBDB_REPORTS.CMN.BANK_SUNDRY;
select @SET_ID = MAX(ID) from CBDB_REPORTS.RPT.CDTR_REFERENCE;

DECLARE @ACCOUNT_TYPE NVARCHAR(50);
DECLARE @ACCOUNT_DESC NVARCHAR(100);
DECLARE @ACCOUNT_MNEMONIC NVARCHAR(50);
DECLARE @DEBIT_AMOUNT decimal(18,2); 
DECLARE @CREDIT_AMOUNT decimal(18,2); 
DECLARE @ENDING_BALANCE decimal(18,2); set @ENDING_BALANCE = 0.00;
DECLARE @HEADER_ID BIGINT = (SELECT MAX(ID) FROM CBDB_REPORTS.CMN.DATA_COPY_DETAIL WHERE TABLE_NAME = 'DMS.ACCOUNT_BAL_HISTORY')


IF @HEADER_ID IS NULL BEGIN PRINT 'RPT_CDTR: Something went wrong retrieving HEADER ID' RETURN END

print @TRAN_DATE;
if @TRAN_DATE != (select TRANSACTION_DATE from CBDB_REPORTS.RPT.CDTR_REFERENCE where id = @SET_ID) OR (select TRANSACTION_DATE  from CBDB_REPORTS.RPT.CDTR_REFERENCE where id = @SET_ID) IS NULL
begin

	if @SET_ID IS NULL
		begin
			--set_id default value is 1
			 set @SET_ID = 1;
			insert into CBDB_REPORTS.RPT.CDTR_REFERENCE (SET_ID, HEADER_ID, TRANSACTION_DATE) values (@SET_ID,@HEADER_ID, @TRAN_DATE);
			-- beginning balance is zero for first run
			--insert into CBDB_REPORTS.RPT.CDTR_REF_DETAILS (SET_ID, BEGINNING_BALANCE, TRANSACTION_DATE) values (@SET_ID, 0.00, @TRAN_DATE);
	
			-- GET THE BEGINNING BALANCE FROM THE LEDGER BALANCE 12/08/2018
			DECLARE @beg_bal TABLE (ID	bigint,SET_ID bigint,MNEMONIC_CODE	nvarchar(50),BEGINNING_BALANCE	decimal(18, 2),DESCRIPTION	nvarchar(500),NO_OF_RECORDS	bigint,DEBIT_AMOUNT	decimal(18, 2),CREDIT_AMOUNT	decimal(18, 2),ACCOUNT_TYPE nvarchar(50),ACCOUNT_TYPE_DESC nvarchar(90),ACCOUNT_TYPE_MNEMONIC nvarchar(50),TRANSACTION_DATE	datetime,ENDING_BALANCE	decimal(18, 2));

			INSERT INTO @beg_bal (BEGINNING_BALANCE,ACCOUNT_TYPE, ACCOUNT_TYPE_DESC, ACCOUNT_TYPE_MNEMONIC)
			select sum(ledger_bal), product_code, PRODUCT_DESC, PRODUCT_MNE from CBDB_REPORTS.DMS.ACCOUNT_MASTER group by product_code, PRODUCT_DESC, PRODUCT_MNE;

			DECLARE @BEGINNING_BALANCE DECIMAL(18,2);
			DECLARE @ACNT_TYPE NVARCHAR(50);
			DECLARE @ACNT_DESC NVARCHAR(50);
			DECLARE @ACNT_MNEMONIC NVARCHAR(50);

			DECLARE beg_balance CURSOR FOR
			SELECT BEGINNING_BALANCE,ACCOUNT_TYPE, ACCOUNT_TYPE_DESC,ACCOUNT_TYPE_MNEMONIC FROM @beg_bal
		
			OPEN beg_balance 
				FETCH NEXT FROM beg_balance into @BEGINNING_BALANCE, @ACNT_TYPE, @ACNT_DESC, @ACNT_MNEMONIC

			WHILE @@FETCH_STATUS = 0
			BEGIN
				insert into CBDB_REPORTS.RPT.CDTR_REF_DETAILS (SET_ID,HEADER_ID, BEGINNING_BALANCE,ACCOUNT_TYPE, PRODUCT_NAME, PRODUCT_MNEMONIC, TRANSACTION_DATE) values (@SET_ID,@HEADER_ID,@BEGINNING_BALANCE ,@ACNT_TYPE,@ACNT_DESC,@ACNT_MNEMONIC, @TRAN_DATE);
				
			FETCH NEXT FROM beg_balance INTO @BEGINNING_BALANCE, @ACNT_TYPE ,@ACNT_DESC, @ACNT_MNEMONIC
			END             
			CLOSE beg_balance
			DEALLOCATE beg_balance 
		end
	else
		begin
			set @PREV_SET_ID = @SET_ID;
			set @SET_ID = @SET_ID + 1;

			insert into CBDB_REPORTS.RPT.CDTR_REFERENCE (SET_ID,HEADER_ID, TRANSACTION_DATE) values (@SET_ID,@HEADER_ID, @TRAN_DATE);

			-- GET BEGINNING BALANCE PER ACCOUNT TYPE
			DECLARE BEGIN_BAL_CUR CURSOR  FOR
				SELECT DISTINCT ACCOUNT_TYPE, PRODUCT_NAME, PRODUCT_MNEMONIC FROM [CBDB_REPORTS].[RPT].[CDTR_REF_DETAILS] WHERE SET_ID = @PREV_SET_ID and ACCOUNT_TYPE IS NOT NULL
			
				OPEN BEGIN_BAL_CUR 
					FETCH NEXT FROM BEGIN_BAL_CUR into @ACCOUNT_TYPE, @ACCOUNT_DESC, @ACCOUNT_MNEMONIC

				WHILE @@FETCH_STATUS = 0
				BEGIN

				IF @ACCOUNT_TYPE IS NOT NULL
				BEGIN
					
					select @PREV_ENDING_BALANCE = isnull(ENDING_BALANCE,0.00) from CBDB_REPORTS.RPT.CDTR_REF_DETAILS where SET_ID = @PREV_SET_ID AND ACCOUNT_TYPE = @ACCOUNT_TYPE;
					set @BEG_BALANCE = @PREV_ENDING_BALANCE;
					insert into CBDB_REPORTS.RPT.CDTR_REF_DETAILS (SET_ID,HEADER_ID, BEGINNING_BALANCE, TRANSACTION_DATE, ACCOUNT_TYPE, PRODUCT_NAME, PRODUCT_MNEMONIC) values (@SET_ID,@HEADER_ID, @PREV_ENDING_BALANCE, @TRAN_DATE, @ACCOUNT_TYPE, @ACCOUNT_DESC, @ACCOUNT_MNEMONIC);

				END;
				ELSE
					BREAK;
	
				FETCH NEXT FROM BEGIN_BAL_CUR INTO @ACCOUNT_TYPE, @ACCOUNT_DESC, @ACCOUNT_MNEMONIC
				END;
				CLOSE BEGIN_BAL_CUR;
				DEALLOCATE BEGIN_BAL_CUR;

		end		


	DECLARE @CDTR_TEMP TABLE (ID	bigint,SET_ID bigint,MNEMONIC_CODE	nvarchar(50),BEGINNING_BALANCE	decimal(18, 2),DESCRIPTION	nvarchar(500),NO_OF_RECORDS	bigint,DEBIT_AMOUNT	decimal(18, 2),CREDIT_AMOUNT	decimal(18, 2),ACCOUNT_TYPE nvarchar(50),TRANSACTION_DATE	datetime,ENDING_BALANCE	decimal(18, 2), PRODUCT_NAME VARCHAR(100), PRODUCT_MNEMONIC VARCHAR(50));

	INSERT INTO @CDTR_TEMP (SET_ID,MNEMONIC_CODE,DESCRIPTION,NO_OF_RECORDS,DEBIT_AMOUNT,CREDIT_AMOUNT,ACCOUNT_TYPE,TRANSACTION_DATE, PRODUCT_NAME, PRODUCT_MNEMONIC)
	SELECT
	@SET_ID,
	 A.MNEMONIC, 
	 B.TRAN_NAME,
	COUNT(B.TRAN_NAME) AS 'NO_OF_RECORDS',
	SUM(CASE WHEN A.TRAN_TYPE = '1' THEN isnull(A.AMOUNT,0.00) ELSE 0 END) AS 'DEBIT_AMOUNT',
	SUM(CASE WHEN A.TRAN_TYPE = '2' THEN isnull(A.AMOUNT,0.00) ELSE 0 END) AS 'CREDIT_AMOUNT',
	C.PRODUCT_CODE AS ACCOUNT_TYPE,
	A.TRAN_DATE,
	C.PRODUCT_DESC,
	C.PRODUCT_MNE

	FROM CBDB_REPORTS.DMS.ACCOUNT_BAL_HISTORY A WITH(NOLOCK) 
	INNER JOIN CBDB_STAGE.CMN.TRAN_ITEM   B WITH(NOLOCK) ON A.MNEMONIC   = B.MNEMONIC AND A.TRAN_CODE = B.TRAN_CODE AND B.TRAN_CATEGORY = 1 AND B.SOA_APPLICABLE = 1 --ADDED 11/27/2018--B.TRAN_CODE != 'DCC' -- ONLY MONETARY TRANS SHOULD BE LOGGED -- NO DCC SHOULD BE DISPLAYED 11/21/2018
	INNER JOIN CBDB_REPORTS.DMS.ACCOUNT_MASTER	   C WITH(NOLOCK) ON A.ACCOUNT_NO = C.ACCOUNT_NO
	WHERE A.TRAN_DATE = @TRAN_DATE
	--DATEDIFF(DD, A.BUSINESS_DATE, CBDB_STAGE.CMN.BANK_SUNDRY_DETAILS) = 0
	GROUP BY 
	A.MNEMONIC, 
	 B.TRAN_NAME, 
	A.TRAN_TYPE,
	C.PRODUCT_CODE,
	A.TRAN_DATE,
	C.PRODUCT_DESC,
	C.PRODUCT_MNE;

	if exists (select * from @CDTR_TEMP)
	begin
		begin transaction
		insert into CBDB_REPORTS.RPT.CDTR_REF_DETAILS (SET_ID,HEADER_ID, MNEMONIC_CODE, DESCRIPTION, NO_OF_RECORDS, DEBIT_AMOUNT, CREDIT_AMOUNT, ACCOUNT_TYPE, TRANSACTION_DATE, PRODUCT_NAME, PRODUCT_MNEMONIC) 
		select SET_ID,@HEADER_ID,MNEMONIC_CODE,DESCRIPTION,NO_OF_RECORDS,DEBIT_AMOUNT,CREDIT_AMOUNT,ACCOUNT_TYPE,TRANSACTION_DATE, PRODUCT_NAME, PRODUCT_MNEMONIC from @CDTR_TEMP;
		commit transaction
	end;

IF (SELECT CURSOR_STATUS('global','CDTR_CUR')) >= -1
 BEGIN
  IF (SELECT CURSOR_STATUS('global','CDTR_CUR')) > -1
   BEGIN
    CLOSE CDTR_CUR
   END
 DEALLOCATE CDTR_CUR
END

	DECLARE CDTR_CUR CURSOR  FOR
	SELECT DISTINCT ACCOUNT_TYPE, PRODUCT_NAME, PRODUCT_MNEMONIC  FROM [CBDB_REPORTS].[RPT].[CDTR_REF_DETAILS] WHERE SET_ID = @SET_ID and ACCOUNT_TYPE IS NOT NULL
		
	OPEN CDTR_CUR 
		FETCH NEXT FROM CDTR_CUR into @ACCOUNT_TYPE, @ACCOUNT_DESC, @ACCOUNT_MNEMONIC

	WHILE @@FETCH_STATUS = 0
	BEGIN

	IF @ACCOUNT_TYPE IS NOT NULL
	BEGIN
	
			selecT @BEG_BALANCE = ISNULL(A.BEGINNING_BALANCE,0.00) from CBDB_REPORTS.RPT.CDTR_REF_DETAILS A
			where A.SET_ID = @SET_ID AND A.ACCOUNT_TYPE = @ACCOUNT_TYPE 
			AND ID = (SELECT MIN(X.ID) FROM CBDB_REPORTS.RPT.CDTR_REF_DETAILS X WHERE X.SET_ID = @SET_ID AND X.ACCOUNT_TYPE = @ACCOUNT_TYPE);

			select @DEBIT_AMOUNT = ISNULL(SUM(DEBIT_AMOUNT),0.00), @CREDIT_AMOUNT = ISNULL(SUM(CREDIT_AMOUNT),0.00) from @CDTR_TEMP 
			where SET_ID = @SET_ID AND ACCOUNT_TYPE = @ACCOUNT_TYPE;
			set @ENDING_BALANCE = ISNULL(@CREDIT_AMOUNT,0.00) - ISNULL(@DEBIT_AMOUNT,0.00);
			set @ENDING_BALANCE = ISNULL(@BEG_BALANCE,0.00) + ISNULL(@ENDING_BALANCE,0.00);

		begin transaction
			insert into CBDB_REPORTS.RPT.CDTR_REF_DETAILS (SET_ID,HEADER_ID, BEGINNING_BALANCE,ENDING_BALANCE, CREDIT_AMOUNT, DEBIT_AMOUNT, TRANSACTION_DATE, ACCOUNT_TYPE, PRODUCT_NAME, PRODUCT_MNEMONIC) 
			values (@SET_ID,@HEADER_ID, @BEG_BALANCE,@ENDING_BALANCE, @CREDIT_AMOUNT, @DEBIT_AMOUNT, @TRAN_DATE, @ACCOUNT_TYPE,@ACCOUNT_DESC, @ACCOUNT_MNEMONIC);
		commit transaction

	END;
	ELSE
		BREAK;
	
	FETCH NEXT FROM CDTR_CUR INTO @ACCOUNT_TYPE, @ACCOUNT_DESC, @ACCOUNT_MNEMONIC 
    END;
	CLOSE CDTR_CUR;
	DEALLOCATE CDTR_CUR;
		
	END;
	PRINT '---------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
	PRINT 'EXTENDED PROCEDURE: RPT_CDTR HAS EXECUTED SUCCESSFULLY'
	PRINT '---------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
END;







