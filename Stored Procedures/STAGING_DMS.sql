DROP PROCEDURE IF EXISTS [dbo].[dms_staging]
/****** Object:  StoredProcedure [dbo].[dms_staging]    Script Date: 27/02/2020 6:29:22 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[dms_staging]
as
begin

declare @ctr bigint;set @ctr = 0;
declare @isfailed as nvarchar(50); set @isfailed = 0;
declare @savepoint as nvarchar(50);
declare @starttimeDMS datetime;
declare @starttime datetime;
declare @endtime datetime;
declare @isrollback bit; set @isrollback = 0;

declare @trandate datetime;
declare @status nvarchar(50);
declare @headerstatus nvarchar(50);
declare @isfaulty bit; set @isfaulty = 0;
declare @totalfaultyrecord bigint; set @totalfaultyrecord = 0;
declare @total_dump_record bigint; set @total_dump_record = 0;
declare @total_delta_record bigint; set @total_delta_record = 0;
declare @headerid bigint;
declare @errormessage nvarchar(3000);
declare @isdump bit;
declare @OneTimeRun bit; set @OneTimeRun = 0;
declare @ReRun bit;  SET @ReRun = 0;
declare @tablename nvarchar(100);
declare @schemaname nvarchar(100); set @schemaname = 'DMS';
declare @failedSP bit; set @failedSP = 0;
set xact_abort off;
set nocount on;  

select @trandate = PREVIOUS_BUSINESS_DATE from cbdb_stage.cmn.bank_sundry;
--status codes 
-- 1 -- start
-- 2 -- in progress
-- 3 -- failed
-- 4 -- finish

BEGIN /*Validation of Data Copy Header***********start**************/
print 'Validation of Data Copy Header***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);
SELECT @HEADERID = ID, @status = status  FROM CBDB_STAGE.CMN.DATA_COPY_HEADER (NOLOCK) 
WHERE ID = (SELECT MAX(ID) FROM CBDB_STAGE.CMN.DATA_COPY_HEADER (NOLOCK) WHERE MODULE_CODE = 'DEP') and BUSINESS_DATE = @trandate;

	IF (@status = 4 OR @status = 1)
	BEGIN
		set @OneTimeRun = 1; -- SP will not be executed again
		print 'One Time Run';
	END;
	else if (@headerid is null)
	begin
		set @OneTimeRun = 0; -- First RUN of SP
	end
	else if (@status = 0)
	begin
		set @OneTimeRun = 0; -- First RUN of SP
	end
	ELSE -- retrieve all tables that status is failed or in progress(means the table was not processed successfully is status is still 2)
	BEGIN
		
		DECLARE @failedtables TABLE (HEADER_ID bigint ,SCHEMA_NAME nvarchar(500),TABLE_NAME nvarchar(500), RECORD_COUNT bigint,START_TIME datetime,END_TIME datetime,IS_FAILED bit,FAIL_EXCEPTION nvarchar(3000),IS_FAULTY bit,IS_DUMP bit);

		INSERT INTO @failedtables (HEADER_ID,SCHEMA_NAME, TABLE_NAME, RECORD_COUNT,START_TIME,END_TIME,IS_FAILED,FAIL_EXCEPTION,IS_FAULTY,IS_DUMP)
		SELECT HEADER_ID, SCHEMA_NAME, TABLE_NAME,RECORD_COUNT,START_TIME,END_TIME,IS_FAILED,FAIL_EXCEPTION,IS_FAULTY,IS_DUMP 
		FROM CBDB_STAGE.CMN.DATA_COPY_DETAIL nolock
		WHERE HEADER_ID = @headerid and is_failed = 1 or is_faulty = 1;

		set @OneTimeRun = 1; -- only tables that is failed or faulty wil be exeuted again
		set @ReRun = 1; --only tables that is failed or faulty wil be exeuted again
		--select * from @failedtables;
		print 'For Re-RUN';
	END;
print 'Validation of Data Copy Header***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);
 /******************************Validation of Data Copy Header***********end***************/
END;

print 'One Time Run Value BELOW';
print @OneTimeRun;
print 'Re-Run Value BELOW';
print @ReRun;

		-- initialize header id for todays business date
		select @headerid = id, @headerstatus = status from cbdb_stage.cmn.DATA_COPY_HEADER nolock where MODULE_CODE = 'DEP' and BUSINESS_DATE = @trandate order by id desc
		print 'Header ID Value BELOW';
		print @headerid;

if (@ReRun = 1 and @headerstatus != 0)
begin
	if not exists (select * from @failedtables)
	begin
		goto EXIT_PROCEDURE;
	end;
end;

if @OneTimeRun = 0 or @ReRun = 1
begin

-- 68 DEPOSIT TABLES AS OF 10/22/2019

PRINT '******************************STAGING PROCESS STARTED******************************';

BEGIN /******************************insert into Data Copy Header***********start***************/
		set @starttimeDMS = sysdatetime();
		set @status = 1; -- status start

		update cbdb_stage.CMN.DATA_COPY_HEADER set START_TIME = SYSDATETIME(), STATUS = @status where MODULE_CODE = 'DEP' and STATUS = 0 and START_TIME is null;

		-- initialize header id for todays business date
		select @headerid = id, @headerstatus = status from cbdb_stage.cmn.DATA_COPY_HEADER nolock where MODULE_CODE = 'DEP' and BUSINESS_DATE = @trandate order by id desc
		print 'Header ID Value BELOW';
		print @headerid;
		--******************************insert into Data Copy Header***********end***************
END;

BEGIN /************populates CBDB_STAGE.ACCOUNT_ADDRESS_CONTACT **********start*************** DUMP*/
		print 'populates CBDB_STAGE.ACCOUNT_ADDRESS_CONTACT***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'ACCOUNT_ADDRESS_CONTACT';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.ACCOUNT_ADDRESS_CONTACT;

		begin try
			insert into CBDB_STAGE.DMS.ACCOUNT_ADDRESS_CONTACT (ACCOUNT_NO,
															EMAIL_ADDRESS,
															MOBILE_CTY_CODE,
															MOBILE_PREFIX,
															MOBILE_NUMBER,
															PREFERRED_ADDRESS,
															ADDRESS_TYPE,
															ADDRESS1,
															ADDRESS2,
															ADDRESS3,
															ADDRESS4,
															CITY,
															ZIP_CODE,
															STATE,
															COUNTRY,
															LENGTH_OF_STAY,
															LANDLINE_CTY_CODE,
															LANDLINE_PREFIX,
															LANDLINE_NUMBER,
															LANDLINE_EXT,
															FAX_CTY_CODE,
															FAX_PREFIX,
															FAX_NUMBER,
															DISTRICT,
															TOWN
															) 
			select 
			ACCOUNT_NO,
			EMAIL_ADDRESS,
			MOBILE_CTY_CODE,
			MOBILE_PREFIX,
			MOBILE_NUMBER,
			PREFERRED_ADDRESS,
			ADDRESS_TYPE,
			ADDRESS1,
			ADDRESS2,
			ADDRESS3,
			ADDRESS4,
			CITY,
			ZIP_CODE,
			STATE,
			COUNTRY,
			LENGTH_OF_STAY,
			LANDLINE_CTY_CODE,
			LANDLINE_PREFIX,
			LANDLINE_NUMBER,
			LANDLINE_EXT,
			FAX_CTY_CODE,
			FAX_PREFIX,
			FAX_NUMBER,
			DISTRICT,
			TOWN 
			from cbdb_deposit.cbdb_deposit_admin.ACCOUNT_ADDRESS_CONTACT nolock

			--******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************


		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.ACCOUNT_ADDRESS_CONTACT nolock;
		set @total_dump_record = @total_dump_record + @ctr;

		end try
		begin catch
			 print '*************error detail (account_address_contact table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;

			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.ACCOUNT_ADDRESS_CONTACT **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';
		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.ACCOUNT_ADDRESS_CONTACT***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);
		--******************************insert in Data Copy Detail***********end***************
END;

BEGIN /************populates CBDB_STAGE.ACCOUNT_ANNUAL_BALANCE **********start*************** DUMP*/
		print 'populates CBDB_STAGE.ACCOUNT_ANNUAL_BALANCE***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'ACCOUNT_ANNUAL_BALANCE';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.ACCOUNT_ANNUAL_BALANCE;

		begin try
			insert into CBDB_STAGE.DMS.ACCOUNT_ANNUAL_BALANCE (
																HEADER_ID,
																ACCOUNT_NO,
																BUSINESS_YEAR,
																BEGINNING_BALANCE,
																INTEREST_MONTH1,
																INTEREST_MONTH2,
																INTEREST_MONTH3,
																INTEREST_MONTH4,
																INTEREST_MONTH5,
																INTEREST_MONTH6,
																INTEREST_MONTH7,
																INTEREST_MONTH8,
																INTEREST_MONTH9,
																INTEREST_MONTH10,
																INTEREST_MONTH11,
																INTEREST_MONTH12,
																INTEREST_PAID1,
																INTEREST_PAID2,
																INTEREST_PAID3,
																INTEREST_PAID4,
																INTEREST_PAID5,
																INTEREST_PAID6,
																INTEREST_PAID7,
																INTEREST_PAID8,
																INTEREST_PAID9,
																INTEREST_PAID10,
																INTEREST_PAID11,
																INTEREST_PAID12,
																CLEARED_MONTH1,
																CLEARED_MONTH2,
																CLEARED_MONTH3,
																CLEARED_MONTH4,
																CLEARED_MONTH5,
																CLEARED_MONTH6,
																CLEARED_MONTH7,
																CLEARED_MONTH8,
																CLEARED_MONTH9,
																CLEARED_MONTH10,
																CLEARED_MONTH11,
																CLEARED_MONTH12,
																AVAILABLE_MONTH1,
																AVAILABLE_MONTH2,
																AVAILABLE_MONTH3,
																AVAILABLE_MONTH4,
																AVAILABLE_MONTH5,
																AVAILABLE_MONTH6,
																AVAILABLE_MONTH7,
																AVAILABLE_MONTH8,
																AVAILABLE_MONTH9,
																AVAILABLE_MONTH10,
																AVAILABLE_MONTH11,
																AVAILABLE_MONTH12,
																LEDGER_MONTH1,
																LEDGER_MONTH2,
																LEDGER_MONTH3,
																LEDGER_MONTH4,
																LEDGER_MONTH5,
																LEDGER_MONTH6,
																LEDGER_MONTH7,
																LEDGER_MONTH8,
																LEDGER_MONTH9,
																LEDGER_MONTH10,
																LEDGER_MONTH11,
																LEDGER_MONTH12,
																TAX_MONTH1,
																TAX_MONTH2,
																TAX_MONTH3,
																TAX_MONTH4,
																TAX_MONTH5,
																TAX_MONTH6,
																TAX_MONTH7,
																TAX_MONTH8,
																TAX_MONTH9,
																TAX_MONTH10,
																TAX_MONTH11,
																TAX_MONTH12,
																ADB_MONTH1,
																ADB_MONTH2,
																ADB_MONTH3,
																ADB_MONTH4,
																ADB_MONTH5,
																ADB_MONTH6,
																ADB_MONTH7,
																ADB_MONTH8,
																ADB_MONTH9,
																ADB_MONTH10,
																ADB_MONTH11,
																ADB_MONTH12,
																LQB_QUARTER1,
																LQB_QUARTER2,
																LQB_QUARTER3,
																LQB_QUARTER4,
																POST_EDA_METHOD,
																EDA_QUARTER1,
																EDA_QUARTER2,
																EDA_QUARTER3,
																EDA_QUARTER4,
																ADJUSTED_LQB_QUARTER1,
																ADJUSTED_LQB_QUARTER2,
																ADJUSTED_LQB_QUARTER3,
																ADJUSTED_LQB_QUARTER4,
																DIVIDEND_CREDITED1,
																DIVIDEND_CREDITED2,
																DIVIDEND_CREDITED3,
																DIVIDEND_CREDITED4,
																EXCESS_TRANSFER_AMOUNT1,
																EXCESS_TRANSFER_AMOUNT2,
																EXCESS_TRANSFER_AMOUNT3,
																EXCESS_TRANSFER_AMOUNT4,
																ANNUAL_DIVIDEND,
																Q1_EDA_NON_POSTING_REASON,
																Q2_EDA_NON_POSTING_REASON,
																Q3_EDA_NON_POSTING_REASON,
																Q4_EDA_NON_POSTING_REASON,
																ANNUAL_DIV_NON_POSTING_REASON,
																EXCESS_ANNUAL_DIV_TRANSFER_AMOUNT
																) 
			select 
			@headerid,
			ACCOUNT_NO,
			BUSINESS_YEAR,
			BEGINNING_BALANCE,
			INTEREST_MONTH1,
			INTEREST_MONTH2,
			INTEREST_MONTH3,
			INTEREST_MONTH4,
			INTEREST_MONTH5,
			INTEREST_MONTH6,
			INTEREST_MONTH7,
			INTEREST_MONTH8,
			INTEREST_MONTH9,
			INTEREST_MONTH10,
			INTEREST_MONTH11,
			INTEREST_MONTH12,
			INTEREST_PAID1,
			INTEREST_PAID2,
			INTEREST_PAID3,
			INTEREST_PAID4,
			INTEREST_PAID5,
			INTEREST_PAID6,
			INTEREST_PAID7,
			INTEREST_PAID8,
			INTEREST_PAID9,
			INTEREST_PAID10,
			INTEREST_PAID11,
			INTEREST_PAID12,
			CLEARED_MONTH1,
			CLEARED_MONTH2,
			CLEARED_MONTH3,
			CLEARED_MONTH4,
			CLEARED_MONTH5,
			CLEARED_MONTH6,
			CLEARED_MONTH7,
			CLEARED_MONTH8,
			CLEARED_MONTH9,
			CLEARED_MONTH10,
			CLEARED_MONTH11,
			CLEARED_MONTH12,
			AVAILABLE_MONTH1,
			AVAILABLE_MONTH2,
			AVAILABLE_MONTH3,
			AVAILABLE_MONTH4,
			AVAILABLE_MONTH5,
			AVAILABLE_MONTH6,
			AVAILABLE_MONTH7,
			AVAILABLE_MONTH8,
			AVAILABLE_MONTH9,
			AVAILABLE_MONTH10,
			AVAILABLE_MONTH11,
			AVAILABLE_MONTH12,
			LEDGER_MONTH1,
			LEDGER_MONTH2,
			LEDGER_MONTH3,
			LEDGER_MONTH4,
			LEDGER_MONTH5,
			LEDGER_MONTH6,
			LEDGER_MONTH7,
			LEDGER_MONTH8,
			LEDGER_MONTH9,
			LEDGER_MONTH10,
			LEDGER_MONTH11,
			LEDGER_MONTH12,
			TAX_MONTH1,
			TAX_MONTH2,
			TAX_MONTH3,
			TAX_MONTH4,
			TAX_MONTH5,
			TAX_MONTH6,
			TAX_MONTH7,
			TAX_MONTH8,
			TAX_MONTH9,
			TAX_MONTH10,
			TAX_MONTH11,
			TAX_MONTH12,
			ADB_MONTH1,
			ADB_MONTH2,
			ADB_MONTH3,
			ADB_MONTH4,
			ADB_MONTH5,
			ADB_MONTH6,
			ADB_MONTH7,
			ADB_MONTH8,
			ADB_MONTH9,
			ADB_MONTH10,
			ADB_MONTH11,
			ADB_MONTH12,
			LQB_QUARTER1,
			LQB_QUARTER2,
			LQB_QUARTER3,
			LQB_QUARTER4,
			POST_EDA_METHOD,
			EDA_QUARTER1,
			EDA_QUARTER2,
			EDA_QUARTER3,
			EDA_QUARTER4,
			ADJUSTED_LQB_QUARTER1,
			ADJUSTED_LQB_QUARTER2,
			ADJUSTED_LQB_QUARTER3,
			ADJUSTED_LQB_QUARTER4,
			DIVIDEND_CREDITED1,
			DIVIDEND_CREDITED2,
			DIVIDEND_CREDITED3,
			DIVIDEND_CREDITED4,
			EXCESS_TRANSFER_AMOUNT1,
			EXCESS_TRANSFER_AMOUNT2,
			EXCESS_TRANSFER_AMOUNT3,
			EXCESS_TRANSFER_AMOUNT4,
			ANNUAL_DIVIDEND,
			Q1_EDA_NON_POSTING_REASON,
			Q2_EDA_NON_POSTING_REASON,
			Q3_EDA_NON_POSTING_REASON,
			Q4_EDA_NON_POSTING_REASON,
			ANNUAL_DIV_NON_POSTING_REASON,
			EXCESS_ANNUAL_DIV_TRANSFER_AMOUNT
			from cbdb_deposit.cbdb_deposit_admin.ACCOUNT_ANNUAL_BALANCE nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.ACCOUNT_ANNUAL_BALANCE nolock;
		set @total_dump_record = @total_dump_record + @ctr;

		--******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
		--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail (ACCOUNT_ANNUAL_BALANCE table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;

			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.ACCOUNT_ANNUAL_BALANCE **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';
		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 
		print 'populates CBDB_STAGE.ACCOUNT_ANNUAL_BALANCE***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;

BEGIN /************populates CBDB_STAGE.ACCOUNT_ATA **********start*************** DUMP*/
		print 'populates CBDB_STAGE.ACCOUNT_ATA***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'ACCOUNT_ATA';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.ACCOUNT_ATA;

		begin try
			insert into CBDB_STAGE.DMS.ACCOUNT_ATA (
													HEADER_ID,
													ACCOUNT_NO,
													ATA_ACCOUNT_NO
													) 
			select 
			@headerid,
			ACCOUNT_NO,
			ATA_ACCOUNT_NO
			from cbdb_deposit.cbdb_deposit_admin.ACCOUNT_ATA nolock

			--******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************


		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.ACCOUNT_ATA nolock;
		set @total_dump_record = @total_dump_record + @ctr;

		end try
		begin catch
			 print '*************error detail (ACCOUNT_ATA table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;

			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.ACCOUNT_ATA **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.ACCOUNT_ATA***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);
		--******************************insert in Data Copy Detail***********end***************
END;

BEGIN /************populates CBDB_STAGE.ACCOUNT_BALANCE **********start*************** DUMP*/
		print 'populates CBDB_STAGE.ACCOUNT_BALANCE***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'ACCOUNT_BALANCE';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.ACCOUNT_BALANCE;

		begin try
			insert into CBDB_STAGE.DMS.ACCOUNT_BALANCE (
														HEADER_ID,
														ACCOUNT_NO,
														AVAILABLE_BALANCE,
														FLOAT_BALANCE,
														CLEARED_BALANCE,
														HOLD_BALANCE,
														PASSBOOK_BALANCE,
														LEDGER_BALANCE,
														PREV_PASSBOOK_BALANCE

													) 
			select  
			@headerid,
			ACCOUNT_NO,
			AVAILABLE_BALANCE,
			FLOAT_BALANCE,
			CLEARED_BALANCE,
			HOLD_BALANCE,
			PASSBOOK_BALANCE,
			LEDGER_BALANCE,
			PREV_PASSBOOK_BALANCE
			from cbdb_deposit.cbdb_deposit_admin.ACCOUNT_BALANCE nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.ACCOUNT_BALANCE nolock;
		set @total_dump_record = @total_dump_record + @ctr;

			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail (ACCOUNT_BALANCE table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.ACCOUNT_BALANCE **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.ACCOUNT_BALANCE***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;

BEGIN /************populates CBDB_STAGE.ACCOUNT_BALANCE_HISTORY **********start*************** DELTA */
		if exists (select top 1 * from @failedtables where TABLE_NAME = 'ACCOUNT_BALANCE_HISTORY' AND SCHEMA_NAME = 'DMS')
		begin 
		print 'RERUN TRIGGERED';
			set @ReRun = 1;

			begin transaction
			DELETE FROM CBDB_STAGE.DMS.ACCOUNT_BALANCE_HISTORY WHERE TRAN_DATE = @trandate;
			DELETE FROM CBDB_STAGE.DMS.ACCOUNT_BALANCE_HISTORY WHERE HEADER_ID = @headerid;
			commit transaction

		end;
		
		if (@ReRun = 1 or @OneTimeRun = 0)
		begin
		print 'populates CBDB_STAGE.ACCOUNT_BALANCE_HISTORY***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @status = 2; -- status in progress
		set @tablename = 'ACCOUNT_BALANCE_HISTORY';

		begin try

		if exists (select top 1 * from CBDB_STAGE.DMS.ACCOUNT_BALANCE_HISTORY)
			begin	
					insert into CBDB_STAGE.DMS.ACCOUNT_BALANCE_HISTORY (
															HEADER_ID,
															ACCOUNT_NO,
															CHANNEL_TYPE,
															AVAILABLE_BALANCE,
															FLOAT_BALANCE,
															LEDGER_BALANCE,
															TRAN_CODE,
															TRAN_TYPE,
															TRAN_DATE,
															MNEMONIC,
															AMOUNT,
															BRANCH_CODE,
															USER_NAME,
															SEQUENCENO,
															IS_REVERSAL,
															REVERSAL_ID,
															CLEARED_BALANCE,
															HOLD_BALANCE,
															PASSBOOK_BALANCE,
															PREV_PASSBOOK_BALANCE,
															VALUE_DATE,
															HOST_ID
															) 
					select  
					@headerid,
					ACCOUNT_NO,
					CHANNEL_TYPE,
					AVAILABLE_BALANCE,
					FLOAT_BALANCE,
					LEDGER_BALANCE,
					TRAN_CODE,
					TRAN_TYPE,
					TRAN_DATE,
					MNEMONIC,
					AMOUNT,
					BRANCH_CODE,
					USER_NAME,
					SEQUENCENO,
					IS_REVERSAL,
					REVERSAL_ID,
					CLEARED_BALANCE,
					HOLD_BALANCE,
					PASSBOOK_BALANCE,
					PREV_PASSBOOK_BALANCE,
					VALUE_DATE,
					ID
					from cbdb_deposit.cbdb_deposit_admin.ACCOUNT_BALANCE_HISTORY nolock WHERE TRAN_DATE = @trandate;

					-- count records for delta
					select @ctr = count(*) from CBDB_STAGE.DMS.ACCOUNT_BALANCE_HISTORY nolock where HEADER_ID = @headerid;
					set @total_delta_record = @total_delta_record + @ctr;
					set @isdump = 0;
				end;
			else 
				begin
					insert into CBDB_STAGE.DMS.ACCOUNT_BALANCE_HISTORY (
															HEADER_ID,
															ACCOUNT_NO,
															CHANNEL_TYPE,
															AVAILABLE_BALANCE,
															FLOAT_BALANCE,
															LEDGER_BALANCE,
															TRAN_CODE,
															TRAN_TYPE,
															TRAN_DATE,
															MNEMONIC,
															AMOUNT,
															BRANCH_CODE,
															USER_NAME,
															SEQUENCENO,
															IS_REVERSAL,
															REVERSAL_ID,
															CLEARED_BALANCE,
															HOLD_BALANCE,
															PASSBOOK_BALANCE,
															PREV_PASSBOOK_BALANCE,
															VALUE_DATE
															) 
					select  
					@headerid,
					ACCOUNT_NO,
					CHANNEL_TYPE,
					AVAILABLE_BALANCE,
					FLOAT_BALANCE,
					LEDGER_BALANCE,
					TRAN_CODE,
					TRAN_TYPE,
					TRAN_DATE,
					MNEMONIC,
					AMOUNT,
					BRANCH_CODE,
					USER_NAME,
					SEQUENCENO,
					IS_REVERSAL,
					REVERSAL_ID,
					CLEARED_BALANCE,
					HOLD_BALANCE,
					PASSBOOK_BALANCE,
					PREV_PASSBOOK_BALANCE,
					VALUE_DATE
					from cbdb_deposit.cbdb_deposit_admin.ACCOUNT_BALANCE_HISTORY nolock;


					-- count records for dumping
					select @ctr = count(*) from CBDB_STAGE.DMS.ACCOUNT_BALANCE_HISTORY nolock where HEADER_ID = @headerid;
					set @total_dump_record = @total_dump_record + @ctr;
					set @isdump = 1;

				end;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail (ACCOUNT_BALANCE_HISTORY table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.ACCOUNT_BALANCE_HISTORY **********end*************** DELTA

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 
		print 'populates CBDB_STAGE.ACCOUNT_BALANCE_HISTORY***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
		END;
END;

BEGIN /************populates CBDB_STAGE.ACCOUNT_CEILING_HISTORY **********start*************** DELTA */
		if exists (select top 1 * from @failedtables where TABLE_NAME = 'ACCOUNT_CEILING_HISTORY' AND SCHEMA_NAME = 'DMS' )
		begin 
		print 'RERUN TRIGGERED';
			set @ReRun = 1;
			begin transaction
			DELETE FROM CBDB_STAGE.DMS.ACCOUNT_CEILING_HISTORY WHERE LAST_UPDATED_DATE = @trandate;
			DELETE FROM CBDB_STAGE.DMS.ACCOUNT_CEILING_HISTORY WHERE HEADER_ID = @headerid;
			commit transaction
		end;
		

		if (@ReRun = 1 or @OneTimeRun = 0)
		begin

		print 'populates CBDB_STAGE.ACCOUNT_CEILING_HISTORY***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @status = 2; -- status in progress
		set @tablename = 'ACCOUNT_CEILING_HISTORY';

		begin try
			if exists (select top 1 * from CBDB_STAGE.DMS.ACCOUNT_CEILING_HISTORY)
				begin
					insert into CBDB_STAGE.DMS.ACCOUNT_CEILING_HISTORY (
																		HEADER_ID,
																		ACCOUNT_NO,
																		CEILING_AMOUNT,
																		FNWCAP_AMOUNT,
																		LAST_UPDATED_DATE,
																		LAST_UPDATED_BY,
																		LAST_UPDATED_BRANCH,
																		LAST_APPROVED_BY
																		) 
					select  
					@headerid,
					ACCOUNT_NO,
					CEILING_AMOUNT,
					FNWCAP_AMOUNT,
					LAST_UPDATED_DATE,
					LAST_UPDATED_BY,
					LAST_UPDATED_BRANCH,
					LAST_APPROVED_BY
					from cbdb_deposit.cbdb_deposit_admin.ACCOUNT_CEILING_HISTORY nolock where LAST_UPDATED_DATE = @trandate;

					-- count records for delta
					select @ctr = count(*) from CBDB_STAGE.DMS.ACCOUNT_CEILING_HISTORY nolock  where HEADER_ID = @headerid;
					set @total_delta_record = @total_delta_record + @ctr;
					set @isdump = 0;
				end;
			else
				begin
					insert into CBDB_STAGE.DMS.ACCOUNT_CEILING_HISTORY (
																		HEADER_ID,
																		ACCOUNT_NO,
																		CEILING_AMOUNT,
																		FNWCAP_AMOUNT,
																		LAST_UPDATED_DATE,
																		LAST_UPDATED_BY,
																		LAST_UPDATED_BRANCH,
																		LAST_APPROVED_BY
																		) 
					select  
					@headerid,
					ACCOUNT_NO,
					CEILING_AMOUNT,
					FNWCAP_AMOUNT,
					LAST_UPDATED_DATE,
					LAST_UPDATED_BY,
					LAST_UPDATED_BRANCH,
					LAST_APPROVED_BY
					from cbdb_deposit.cbdb_deposit_admin.ACCOUNT_CEILING_HISTORY nolock;

					-- count records for dumping
					select @ctr = count(*) from CBDB_STAGE.DMS.ACCOUNT_CEILING_HISTORY nolock  where HEADER_ID = @headerid;
					set @total_dump_record = @total_dump_record + @ctr;
					set @isdump = 1;
				end;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail (ACCOUNT_CEILING_HISTORY table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.ACCOUNT_CEILING_HISTORY **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.ACCOUNT_CEILING_HISTORY***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
		end
END;

BEGIN /************populates CBDB_STAGE.ACCOUNT_CHANNEL_FREQUENCY **********start*************** DUMP */
		print 'populates CBDB_STAGE.ACCOUNT_CHANNEL_FREQUENCY***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'ACCOUNT_CHANNEL_FREQUENCY';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.ACCOUNT_CHANNEL_FREQUENCY;

		begin try
			insert into CBDB_STAGE.DMS.ACCOUNT_CHANNEL_FREQUENCY (
																HEADER_ID,
																ACCOUNT_NO,
																BUSINESS_YEAR,
																CHANNEL_TYPE,
																DAY_DEPOSIT_CNT,
																DAY_DEPOSIT_AMT,
																DAY_WITHDRAWAL_CNT,
																DAY_WITHDRAWAL_AMT,
																WEEK_DEPOSIT_CNT,
																WEEK_DEPOSIT_AMT,
																WEEK_WITHDRAWAL_CNT,
																WEEK_WITHDRAWAL_AMT,
																MONTH_DEPOSIT_CNT,
																MONTH_DEPOSIT_AMT,
																MONTH_WITHDRAWAL_CNT,
																MONTH_WITHDRAWAL_AMT,
																QUARTER_DEPOSIT_CNT,
																QUARTER_DEPOSIT_AMT,
																QUARTER_WITHDRAWAL_CNT,
																QUARTER_WITHDRAWAL_AMT,
																YEAR_DEPOSIT_CNT,
																YEAR_DEPOSIT_AMT,
																YEAR_WITHDRAWAL_CNT,
																YEAR_WITHDRAWAL_AMT
																) 
			select
			@headerid,
			ACCOUNT_NO,
			BUSINESS_YEAR,
			CHANNEL_TYPE,
			DAY_DEPOSIT_CNT,
			DAY_DEPOSIT_AMT,
			DAY_WITHDRAWAL_CNT,
			DAY_WITHDRAWAL_AMT,
			WEEK_DEPOSIT_CNT,
			WEEK_DEPOSIT_AMT,
			WEEK_WITHDRAWAL_CNT,
			WEEK_WITHDRAWAL_AMT,
			MONTH_DEPOSIT_CNT,
			MONTH_DEPOSIT_AMT,
			MONTH_WITHDRAWAL_CNT,
			MONTH_WITHDRAWAL_AMT,
			QUARTER_DEPOSIT_CNT,
			QUARTER_DEPOSIT_AMT,
			QUARTER_WITHDRAWAL_CNT,
			QUARTER_WITHDRAWAL_AMT,
			YEAR_DEPOSIT_CNT,
			YEAR_DEPOSIT_AMT,
			YEAR_WITHDRAWAL_CNT,
			YEAR_WITHDRAWAL_AMT
			from cbdb_deposit.cbdb_deposit_admin.ACCOUNT_CHANNEL_FREQUENCY nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.ACCOUNT_CHANNEL_FREQUENCY nolock;
		set @total_dump_record = @total_dump_record + @ctr;

			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************

		end try
		begin catch
			 print '*************error detail (ACCOUNT_CHANNEL_FREQUENCY table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.ACCOUNT_CHANNEL_FREQUENCY **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';
		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.ACCOUNT_CHANNEL_FREQUENCY***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;

BEGIN /************populates CBDB_STAGE.ACCOUNT_CHARGE **********start*************** DUMP */
		print 'populates CBDB_STAGE.ACCOUNT_CHARGE***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'ACCOUNT_CHARGE';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.ACCOUNT_CHARGE;

		begin try
			insert into CBDB_STAGE.DMS.ACCOUNT_CHARGE (
													   HEADER_ID,
													   ACCOUNT_NO,
													   CHARGE_CODE,
													   CHARGE_AMOUNT,
													   PAID_AMOUNT,
													   PAID_DATE,
													   POSTED_DATE,
													   WAIVED
													  ) 
			select
			@headerid,
			ACCOUNT_NO,
			CHARGE_CODE,
			CHARGE_AMOUNT,
			PAID_AMOUNT,
			PAID_DATE,
			POSTED_DATE,
			WAIVED
			from cbdb_deposit.cbdb_deposit_admin.ACCOUNT_CHARGE nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.ACCOUNT_CHARGE nolock;
		set @total_dump_record = @total_dump_record + @ctr;

			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************

		end try
		begin catch
			 print '*************error detail (ACCOUNT_CHARGE table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.ACCOUNT_CHARGE **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';
		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.ACCOUNT_CHARGE***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;

BEGIN /************populates CBDB_STAGE.ACCOUNT_HOLD **********start*************** DUMP */
		print 'populates CBDB_STAGE.ACCOUNT_HOLD***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'ACCOUNT_HOLD';

		-- need for dumping
		truncate table CBDB_STAGE.DMS.ACCOUNT_HOLD;

		begin try
			insert into CBDB_STAGE.DMS.ACCOUNT_HOLD (
													HEADER_ID,
													ACCOUNT_NO,
													HOLD_CODE,
													HOLD_GARNISH,
													HOLD_ALL,
													HOLD_AMOUNT,
													OTHER_REASON,
													EXPIRATION,
													HOLD_STATUS,
													REFERENCE_NO,
													TELLER_NAME,
													SET_DATE,
													MODULE_CODE,
													REMARKS
													)
			select
			@headerid,
			ACCOUNT_NO,
			HOLD_CODE,
			HOLD_GARNISH,
			HOLD_ALL,
			HOLD_AMOUNT,
			OTHER_REASON,
			EXPIRATION,
			HOLD_STATUS,
			REFERENCE_NO,
			TELLER_NAME,
			SET_DATE,
			MODULE_CODE,
			REMARKS
			from cbdb_deposit.cbdb_deposit_admin.ACCOUNT_HOLD nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.ACCOUNT_HOLD nolock;
		set @total_dump_record = @total_dump_record + @ctr;

			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************

		end try
		begin catch
			 print '*************error detail (ACCOUNT_HOLD table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.ACCOUNT_HOLD **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.ACCOUNT_HOLD***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;

BEGIN /************populates CBDB_STAGE.ACCOUNT_INFO **********start*************** DUMP */
		print 'populates CBDB_STAGE.ACCOUNT_INFO***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'ACCOUNT_INFO';

		-- need for dumping
		truncate table CBDB_STAGE.DMS.ACCOUNT_INFO;

		begin try
			insert into CBDB_STAGE.DMS.ACCOUNT_INFO (
														HEADER_ID,
														ACCOUNT_NO,
														CIF_NO,
														ACCOUNT_NAME,
														BRANCH_CODE,
														DEPOSIT_PRODUCT_CODE,
														INITIAL_DEPOSIT_DATE,
														PREV_DAY_BALANCE,
														CUMULATIVE_BALANCE,
														OPEN_DATE,
														IS_CLOSE,
														CLOSE_DATE,
														CLOSE_AMT,
														CLOSE_REASON_CODE,
														CURRENCY_CODE,
														ACCT_GROUP,
														CB_CODE,
														INDUSTRY_CODE,
														LAST_MAINTENANCE_DATE,
														LAST_STATUS_CHANGE,
														LAST_MAINTENANCE_TXN,
														LAST_FINANCIAL_TXN,
														LAST_INQUIRY_TXN,
														LAST_INACTIVITY_CHARGED,
														LAST_MBR_CHARGED,
														ACCOUNT_STATUS_CODE,
														LATE_CHECK_AMOUNT,
														ACCT_RECEIVABLES_AMT,
														TOTAL_NUMBER_CREDITS,
														TOTAL_NUMBER_DEBITS,
														TOTAL_AMOUNT_CREDITS,
														TOTAL_AMOUNT_DEBITS,
														TOTAL_NUMBER_ATA_CREDITS,
														TOTAL_NUMBER_ATA_DEBITS,
														TOTAL_ATA_AMOUNT_CREDITS,
														TOTAL_ATA_AMOUNT_DEBITS,
														TOTAL_NUMBER_ATM_WDRAWAL,
														TOTAL_NUMBER_NOBOOK,
														TOTAL_NUMBER_ATA,
														OLD_CIF_NO,
														CAUTION_ITEMS,
														SPO_FLAG,
														CONFIDENTIAL_ACCT,
														BLOCKED_ACCT,
														SPL_INSTRUCTION,
														PLACEMENT_DATE,
														PLACEMENT_AMOUNT,
														ROLLOVER_TYPE,
														ACCT_PLACEMENT_STATUS,
														ACCT_PLACEMENT_STATUS_OLD,
														MATURITY_DATE,
														TERM,
														TERM_INT_RATE,
														PAYOUT_ACCT,
														TERMROLLOVRTYP,
														AUTO_ROLLOVER,
														RENEWAL_TERM,
														BP_AMT,
														BP_AVAILED,
														BP_CRDT_LMT,
														BP_SETUPDATE,
														BP_EXPDATE,
														LAST_BP_AVAIL,
														START_DAY_BAL,
														START_CURR_BAL,
														SIGN_INST,
														SIGN_REQ,
														MARKETING_TYPE,
														REFER_DIV,
														REFER_OFFICER_ID,
														TOD_AMT,
														DOC_STAMP_PAID,
														TOTAL_NUMBER_DAUD_CHQ,
														TOTAL_NUMBER_DAIF_CHQ,
														TOTAL_NUMBER_RET_CHQ,
														WITH_RETURN_CHQ,
														WITH_CLEARING_CHQ,
														TOTAL_ATF_AMOUNT,
														P_MAX_CREDIT_AMT,
														P_MAX_DEBIT_AMT,
														VALUE_DATE,
														P_MINBAL_FLAG,
														NETCHG_AMT,
														WITH_ATA,
														WITH_JOINT_ACCT,
														WITH_SURVIVORSHIP,
														SOA_DELIVERY,
														ENTERPRISE,
														SOURCE_OF_FUND_CODE,
														TYPE_BUS_OCC,
														ITF_RELATIVE,
														SPECIAL_INTEREST_RATE,
														SPECIAL_MBR,
														SPECIAL_TAX_RATE,
														AFFILIATE_CODE,
														INTRODUCED_BY,
														WITH_SOA,
														LAST_ZERO_BAL_DATE,
														PURPOSE_ACCT,
														COUNTRY_FUNDS,
														SIGNATURE_CARD_EXPIRY,
														REMARK,
														DEPT_CODE,
														PURPOSE_ACCT_OTHERS,
														OLD_ACCT_NO,
														SR_BALANCE,
														REACTIVATION_DATE,
														CAPCON_CEILING,
														WITH_ALMS,
														WITH_APEX,
														WITH_SALARY_DEDUCTION,
														WITH_PROPERTY_FORSALE,
														INACTIVITY_DAYS_COUNTER,
														MBR_CHARGE_APPLIED,
														ACCOUNT_CLASSIFICATION,
														CLIENT_TYPE,
														SURVIVORSHIP_LAST_UPDATED_DATE,
														SURVIVORSHIP_LAST_UPDATED_BY,
														SURVIVORSHIP_LAST_UPDATED_BRANCH,
														SURVIVORSHIP_LAST_APPROVED_BY,
														FIRST_FINANCIAL_TXN,
														LAST_BELOW_MIN_BALANCE,
														LASTZERO_BAL_DATE
														)
			select
			@headerid,
			ACCOUNT_NO,
			CIF_NO,
			ACCOUNT_NAME,
			BRANCH_CODE,
			DEPOSIT_PRODUCT_CODE,
			INITIAL_DEPOSIT_DATE,
			PREV_DAY_BALANCE,
			CUMULATIVE_BALANCE,
			OPEN_DATE,
			IS_CLOSE,
			CLOSE_DATE,
			CLOSE_AMT,
			CLOSE_REASON_CODE,
			CURRENCY_CODE,
			ACCT_GROUP,
			CB_CODE,
			INDUSTRY_CODE,
			LAST_MAINTENANCE_DATE,
			LAST_STATUS_CHANGE,
			LAST_MAINTENANCE_TXN,
			LAST_FINANCIAL_TXN,
			LAST_INQUIRY_TXN,
			LAST_INACTIVITY_CHARGED,
			LAST_MBR_CHARGED,
			ACCOUNT_STATUS_CODE,
			LATE_CHECK_AMOUNT,
			ACCT_RECEIVABLES_AMT,
			TOTAL_NUMBER_CREDITS,
			TOTAL_NUMBER_DEBITS,
			TOTAL_AMOUNT_CREDITS,
			TOTAL_AMOUNT_DEBITS,
			TOTAL_NUMBER_ATA_CREDITS,
			TOTAL_NUMBER_ATA_DEBITS,
			TOTAL_ATA_AMOUNT_CREDITS,
			TOTAL_ATA_AMOUNT_DEBITS,
			TOTAL_NUMBER_ATM_WDRAWAL,
			TOTAL_NUMBER_NOBOOK,
			TOTAL_NUMBER_ATA,
			OLD_CIF_NO,
			CAUTION_ITEMS,
			SPO_FLAG,
			CONFIDENTIAL_ACCT,
			BLOCKED_ACCT,
			SPL_INSTRUCTION,
			PLACEMENT_DATE,
			PLACEMENT_AMOUNT,
			ROLLOVER_TYPE,
			ACCT_PLACEMENT_STATUS,
			ACCT_PLACEMENT_STATUS_OLD,
			MATURITY_DATE,
			TERM,
			TERM_INT_RATE,
			PAYOUT_ACCT,
			TERMROLLOVRTYP,
			AUTO_ROLLOVER,
			RENEWAL_TERM,
			BP_AMT,
			BP_AVAILED,
			BP_CRDT_LMT,
			BP_SETUPDATE,
			BP_EXPDATE,
			LAST_BP_AVAIL,
			START_DAY_BAL,
			START_CURR_BAL,
			SIGN_INST,
			SIGN_REQ,
			MARKETING_TYPE,
			REFER_DIV,
			REFER_OFFICER_ID,
			TOD_AMT,
			DOC_STAMP_PAID,
			TOTAL_NUMBER_DAUD_CHQ,
			TOTAL_NUMBER_DAIF_CHQ,
			TOTAL_NUMBER_RET_CHQ,
			WITH_RETURN_CHQ,
			WITH_CLEARING_CHQ,
			TOTAL_ATF_AMOUNT,
			P_MAX_CREDIT_AMT,
			P_MAX_DEBIT_AMT,
			VALUE_DATE,
			P_MINBAL_FLAG,
			NETCHG_AMT,
			WITH_ATA,
			WITH_JOINT_ACCT,
			WITH_SURVIVORSHIP,
			SOA_DELIVERY,
			ENTERPRISE,
			SOURCE_OF_FUND_CODE,
			TYPE_BUS_OCC,
			ITF_RELATIVE,
			SPECIAL_INTEREST_RATE,
			SPECIAL_MBR,
			SPECIAL_TAX_RATE,
			AFFILIATE_CODE,
			INTRODUCED_BY,
			WITH_SOA,
			LAST_ZERO_BAL_DATE,
			PURPOSE_ACCT,
			COUNTRY_FUNDS,
			SIGNATURE_CARD_EXPIRY,
			REMARK,
			DEPT_CODE,
			PURPOSE_ACCT_OTHERS,
			OLD_ACCT_NO,
			SR_BALANCE,
			REACTIVATION_DATE,
			CAPCON_CEILING,
			WITH_ALMS,
			WITH_APEX,
			WITH_SALARY_DEDUCTION,
			WITH_PROPERTY_FORSALE,
			INACTIVITY_DAYS_COUNTER,
			MBR_CHARGE_APPLIED,
			ACCOUNT_CLASSIFICATION,
			CLIENT_TYPE,
			SURVIVORSHIP_LAST_UPDATED_DATE,
			SURVIVORSHIP_LAST_UPDATED_BY,
			SURVIVORSHIP_LAST_UPDATED_BRANCH,
			SURVIVORSHIP_LAST_APPROVED_BY,
			FIRST_FINANCIAL_TXN,
			LAST_BELOW_MIN_BALANCE,
			LASTZERO_BAL_DATE
			from cbdb_deposit.cbdb_deposit_admin.ACCOUNT_INFO nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.ACCOUNT_INFO nolock;
		set @total_dump_record = @total_dump_record + @ctr;

			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************

		end try
		begin catch
			 print '*************error detail (ACCOUNT_INFO table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.ACCOUNT_INFO **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';
		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.ACCOUNT_INFO***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;

BEGIN /************populates CBDB_STAGE.ACCOUNT_JOINT **********start*************** DUMP */
		print 'populates CBDB_STAGE.ACCOUNT_JOINT***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'ACCOUNT_JOINT';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.ACCOUNT_JOINT;

		begin try
			insert into CBDB_STAGE.DMS.ACCOUNT_JOINT (
														HEADER_ID,
														ACCOUNT_NO,
														CIF_NO,
														RELATION_TYPE
														)
			select
			@headerid,
			ACCOUNT_NO,
			CIF_NO,
			RELATION_TYPE
			from cbdb_deposit.cbdb_deposit_admin.ACCOUNT_JOINT nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.ACCOUNT_JOINT nolock;
		set @total_dump_record = @total_dump_record + @ctr;

			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************

		end try
		begin catch
			 print '*************error detail (ACCOUNT_JOINT table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************

		end catch
		--************populates CBDB_STAGE.ACCOUNT_JOINT **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';
		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 
		
		print 'populates CBDB_STAGE.ACCOUNT_JOINT***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;

BEGIN /************populates CBDB_STAGE.ACCOUNT_OTHER_SERVICES **********start*************** DUMP */
		print 'populates CBDB_STAGE.ACCOUNT_OTHER_SERVICES***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'ACCOUNT_OTHER_SERVICES';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.ACCOUNT_OTHER_SERVICES;

		begin try
			insert into CBDB_STAGE.DMS.ACCOUNT_OTHER_SERVICES (
														HEADER_ID,
														ACCOUNT_NO,
														ALLOW_TRANSFER,
														ACCOUNT_NUMBER,
														ACCOUNT_NAME,
														BANK_CODE,
														START_DATE,
														EXPIRATION_DATE,
														PAYJUR_CODE,
														SERIAL_NO,
														LAST_UPDATED_DATE,
														LAST_UPDATED_BY,
														LAST_UPDATED_BRANCH,
														LAST_APPROVED_BY,
														WITH_ATM

														)
			select
			@headerid,
			ACCOUNT_NO,
			ALLOW_TRANSFER,
			ACCOUNT_NUMBER,
			ACCOUNT_NAME,
			BANK_CODE,
			START_DATE,
			EXPIRATION_DATE,
			PAYJUR_CODE,
			SERIAL_NO,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_UPDATED_BRANCH,
			LAST_APPROVED_BY,
			WITH_ATM
			from cbdb_deposit.cbdb_deposit_admin.ACCOUNT_OTHER_SERVICES nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.ACCOUNT_OTHER_SERVICES nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail (ACCOUNT_OTHER_SERVICES table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.ACCOUNT_OTHER_SERVICES **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.ACCOUNT_OTHER_SERVICES***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;

BEGIN /************populates CBDB_STAGE.ACCOUNT_PASSBOOK **********start*************** DUMP */
		print 'populates CBDB_STAGE.ACCOUNT_PASSBOOK***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'ACCOUNT_PASSBOOK';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.ACCOUNT_PASSBOOK;

		begin try
			insert into CBDB_STAGE.DMS.ACCOUNT_PASSBOOK (														
														HEADER_ID,
														ACCOUNT_NO,
														BALANCE,
														TRAN_CODE,
														TRAN_TYPE,
														TRAN_DATE,
														MNEMONIC,
														AMOUNT,
														BRANCH_CODE,
														USER_NAME,
														SEQUENCENO,
														IS_REVERSAL,
														REVERSAL_ID,
														IS_PRINTED
														)
			select
			@headerid,
			ACCOUNT_NO,
			BALANCE,
			TRAN_CODE,
			TRAN_TYPE,
			TRAN_DATE,
			MNEMONIC,
			AMOUNT,
			BRANCH_CODE,
			USER_NAME,
			SEQUENCENO,
			IS_REVERSAL,
			REVERSAL_ID,
			IS_PRINTED
			from cbdb_deposit.cbdb_deposit_admin.ACCOUNT_PASSBOOK nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.ACCOUNT_PASSBOOK nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail (ACCOUNT_PASSBOOK table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.ACCOUNT_PASSBOOK **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';
		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.ACCOUNT_PASSBOOK***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************

END;

BEGIN /************populates CBDB_STAGE.ACCOUNT_PLACEMENT **********start*************** DUMP */
		print 'populates CBDB_STAGE.ACCOUNT_PLACEMENT***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'ACCOUNT_PLACEMENT';
		begin try
		-- need for dumping
		truncate table CBDB_STAGE.DMS.ACCOUNT_PLACEMENT;

			insert into CBDB_STAGE.DMS.ACCOUNT_PLACEMENT (														
															HEADER_ID,
															ACCOUNT_NO,
															PLACEMENT_NO,
															ROLLOVER_COUNTER,
															INTEREST_RATE,
															TERM_FREQUENCY_VALUE,
															TERM_FREQUENCY_UNIT,
															CREDIT_FREQUENCY,
															PRE_TERMINATION_DATE,
															AUTO_ROLLOVER,
															PLACEMENT_STATUS,
															CREDIT_ACCOUNT,
															LAST_CREDIT_DATE,
															LAST_UPDATED_DATE,
															LAST_UPDATED_BY,
															LAST_APPROVED_BY,
															LAST_UPDATED_BRANCH,
															TERMINATION_TYPE,
															TERMINATION_REASON_CODE,
															CLOSE_AMT,
															PRE_TERMINATION_INTEREST_RATE,
															PRE_TERMINATION_INTEREST_AMOUNT
														)
			select
			@headerid,
			ACCOUNT_NO,
			PLACEMENT_NO,
			ROLLOVER_COUNTER,
			INTEREST_RATE,
			TERM_FREQUENCY_VALUE,
			TERM_FREQUENCY_UNIT,
			CREDIT_FREQUENCY,
			PRE_TERMINATION_DATE,
			AUTO_ROLLOVER,
			PLACEMENT_STATUS,
			CREDIT_ACCOUNT,
			LAST_CREDIT_DATE,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY,
			LAST_UPDATED_BRANCH,
			TERMINATION_TYPE,
			TERMINATION_REASON_CODE,
			CLOSE_AMOUNT, -- MODIFIED 12/26/2019
			PRE_TERMINATION_INTEREST_RATE,
			PRE_TERMINATION_INTEREST_AMOUNT
			from cbdb_deposit.cbdb_deposit_admin.ACCOUNT_PLACEMENT nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.ACCOUNT_PLACEMENT nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail (ACCOUNT_PLACEMENT table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.ACCOUNT_PLACEMENT **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';
		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.ACCOUNT_PLACEMENT***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************

END;

BEGIN /************populates CBDB_STAGE.ACCOUNT_PLACEMENT_C_F_T **********start*************** DUMP */
		print 'populates CBDB_STAGE.ACCOUNT_PLACEMENT_C_F_T***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'ACCOUNT_PLACEMENT_C_F_T';
		
		begin try
		-- need for dumping
		truncate table CBDB_STAGE.DMS.ACCOUNT_PLACEMENT_C_F_T;

	
			insert into CBDB_STAGE.DMS.ACCOUNT_PLACEMENT_C_F_T (														
																HEADER_ID,
																ACCOUNT_NO,
																PLACEMENT_NO,
																CHARGE_CODE,
																AMOUNT
																)
			select
			@headerid,
			ACCOUNT_NO,
			PLACEMENT_NO,
			CHARGE_CODE,
			AMOUNT
			from cbdb_deposit.cbdb_deposit_admin.ACCOUNT_PLACEMENT_C_F_T nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.ACCOUNT_PLACEMENT_C_F_T nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail (ACCOUNT_PLACEMENT_C_F_T table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.ACCOUNT_PLACEMENT_C_F_T **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.ACCOUNT_PLACEMENT_C_F_T***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;

BEGIN /************populates CBDB_STAGE.ACCOUNT_PLACEMENT_ITEM **********start*************** DUMP */
		print 'populates CBDB_STAGE.ACCOUNT_PLACEMENT_ITEM***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'ACCOUNT_PLACEMENT_ITEM';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.ACCOUNT_PLACEMENT_ITEM;

		begin try
			insert into CBDB_STAGE.DMS.ACCOUNT_PLACEMENT_ITEM (														
																HEADER_ID,
																ACCOUNT_NO,
																PLACEMENT_NO,
																IS_CLOSE,
																PLACEMENT_AMOUNT,
																OPEN_DATE,
																MATURITY_DATE,
																INTEREST_AMOUNT,
																TOTAL_INTEREST_AMOUNT,
																TOTAL_INTEREST_PAID,
																AUTO_ROLLOVER_TYPE
																)
			select
			@headerid,
			ACCOUNT_NO,
			PLACEMENT_NO,
			IS_CLOSE,
			PLACEMENT_AMOUNT,
			OPEN_DATE,
			MATURITY_DATE,
			INTEREST_AMOUNT,
			TOTAL_INTEREST_AMOUNT,
			TOTAL_INTEREST_PAID,
			AUTO_ROLLOVER_TYPE
			from cbdb_deposit.cbdb_deposit_admin.ACCOUNT_PLACEMENT_ITEM nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.ACCOUNT_PLACEMENT_ITEM nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail (ACCOUNT_PLACEMENT_ITEM table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.ACCOUNT_PLACEMENT_ITEM **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.ACCOUNT_PLACEMENT_ITEM***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;

BEGIN /************populates CBDB_STAGE.ACCOUNT_SERVICES **********start*************** DUMP */
		print 'populates CBDB_STAGE.ACCOUNT_SERVICES***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'ACCOUNT_SERVICES';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.ACCOUNT_SERVICES;

		begin try
			insert into CBDB_STAGE.DMS.ACCOUNT_SERVICES (														
														HEADER_ID,
														ACCOUNT_NO,
														REQUEST_TYPE,
														PAYSLIP_TYPE,
														MEMBER_PAYSLIP_ID,
														PREV_DAY_CEILING_AMOUNT,
														PREV_DAY_FNWCAP_BAL,
														CEILING_AMOUNT,
														WITH_AUTO_DEDUCT,
														CONTRIBUTION_AMOUNT,
														CC_LAST_UPDATED_DATE,
														CC_LAST_UPDATED_BY,
														CC_LAST_UPDATED_BRANCH,
														CC_LAST_APPROVED_BY,
														WITH_EDA,
														DIVIDEND_ACCOUNT_NO,
														EDA_LAST_UPDATED_DATE,
														EDA_LAST_UPDATED_BY,
														EDA_LAST_UPDATED_BRANCH,
														EDA_LAST_APPROVED_BY,
														SAVING_ACCOUNT_NO,
														TRANSFER_OPTION,
														OTHER_ACCOUNT_NO,
														OTHER_BANK_NAME,
														OTHER_ACCOUNT_NAME,
														PAYJUR_CODE,
														SERIAL_NO,
														TO_LAST_UPDATED_DATE,
														TO_LAST_UPDATED_BY,
														TO_LAST_UPDATED_BRANCH,
														TO_LAST_APPROVED_BY,
														EDA_ENROLLMENT_STATUS,
														EDA_ENROLLMENT_REMARK,
														REQUEST_DATE,
														FNWCAP_AMOUNT
														)
			select
			@headerid,
			ACCOUNT_NO,
			REQUEST_TYPE,
			PAYSLIP_TYPE,
			MEMBER_PAYSLIP_ID,
			PREV_DAY_CEILING_AMOUNT,
			PREV_DAY_FNWCAP_BAL,
			CEILING_AMOUNT,
			WITH_AUTO_DEDUCT,
			CONTRIBUTION_AMOUNT,
			CC_LAST_UPDATED_DATE,
			CC_LAST_UPDATED_BY,
			CC_LAST_UPDATED_BRANCH,
			CC_LAST_APPROVED_BY,
			WITH_EDA,
			DIVIDEND_ACCOUNT_NO,
			EDA_LAST_UPDATED_DATE,
			EDA_LAST_UPDATED_BY,
			EDA_LAST_UPDATED_BRANCH,
			EDA_LAST_APPROVED_BY,
			SAVING_ACCOUNT_NO,
			TRANSFER_OPTION,
			OTHER_ACCOUNT_NO,
			OTHER_BANK_NAME,
			OTHER_ACCOUNT_NAME,
			PAYJUR_CODE,
			SERIAL_NO,
			TO_LAST_UPDATED_DATE,
			TO_LAST_UPDATED_BY,
			TO_LAST_UPDATED_BRANCH,
			TO_LAST_APPROVED_BY,
			EDA_ENROLLMENT_STATUS,
			EDA_ENROLLMENT_REMARK,
			REQUEST_DATE,
			FNWCAP_AMOUNT
			from cbdb_deposit.cbdb_deposit_admin.ACCOUNT_SERVICES nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.ACCOUNT_SERVICES nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail (ACCOUNT_SERVICES table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.ACCOUNT_SERVICES **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';
		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.ACCOUNT_SERVICES***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************

END;

BEGIN /************populates CBDB_STAGE.ACCOUNT_STATUS_HISTORY **********start*************** DELTA */
		
		if exists (select top 1 * from @failedtables where TABLE_NAME = 'ACCOUNT_STATUS_HISTORY' AND SCHEMA_NAME = 'DMS')
		begin 
		print 'RERUN TRIGGERED';
			set @ReRun = 1;
			begin transaction
			DELETE FROM CBDB_STAGE.DMS.ACCOUNT_STATUS_HISTORY WHERE TRAN_DATE = @trandate;
			DELETE FROM CBDB_STAGE.DMS.ACCOUNT_STATUS_HISTORY WHERE HEADER_ID = @headerid;
			commit transaction
		end;

		if (@ReRun = 1 or @OneTimeRun = 0)
		begin
		print 'populates CBDB_STAGE.ACCOUNT_STATUS_HISTORY***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @status = 2; -- status in progress
		set @tablename = 'ACCOUNT_STATUS_HISTORY';

		begin try

			if exists (select top 1 * from CBDB_STAGE.DMS.ACCOUNT_STATUS_HISTORY)
				begin
					insert into CBDB_STAGE.DMS.ACCOUNT_STATUS_HISTORY (
																		HEADER_ID,
																		ACCOUNT_NO,
																		STATUS_FROM,
																		STATUS_TO,
																		REASON_CODE,
																		SEQUENCENO,
																		REVERSAL_ID,
																		TRAN_DATE,
																		LAST_UPDATED_DATE,
																		LAST_UPDATED_BY,
																		LAST_UPDATED_BRANCH,
																		LAST_APPROVED_BY
																		) 
						select  
						@headerid,
						ACCOUNT_NO,
						STATUS_FROM,
						STATUS_TO,
						REASON_CODE,
						SEQUENCENO,
						REVERSAL_ID,
						TRAN_DATE,
						LAST_UPDATED_DATE,
						LAST_UPDATED_BY,
						LAST_UPDATED_BRANCH,
						LAST_APPROVED_BY

						from cbdb_deposit.cbdb_deposit_admin.ACCOUNT_STATUS_HISTORY nolock WHERE TRAN_DATE = @trandate;

					-- count records for delta
					select @ctr = count(*) from CBDB_STAGE.DMS.ACCOUNT_STATUS_HISTORY nolock  where HEADER_ID = @headerid;
					set @total_delta_record = @total_delta_record + @ctr;
					set @isdump = 0;
				end;
			else
				begin
					insert into CBDB_STAGE.DMS.ACCOUNT_STATUS_HISTORY (
																		HEADER_ID,
																		ACCOUNT_NO,
																		STATUS_FROM,
																		STATUS_TO,
																		REASON_CODE,
																		SEQUENCENO,
																		REVERSAL_ID,
																		TRAN_DATE,
																		LAST_UPDATED_DATE,
																		LAST_UPDATED_BY,
																		LAST_UPDATED_BRANCH,
																		LAST_APPROVED_BY
																		) 
						select  
						@headerid,
						ACCOUNT_NO,
						STATUS_FROM,
						STATUS_TO,
						REASON_CODE,
						SEQUENCENO,
						REVERSAL_ID,
						TRAN_DATE,
						LAST_UPDATED_DATE,
						LAST_UPDATED_BY,
						LAST_UPDATED_BRANCH,
						LAST_APPROVED_BY

						from cbdb_deposit.cbdb_deposit_admin.ACCOUNT_STATUS_HISTORY nolock;

					-- count records for dump
					select @ctr = count(*) from CBDB_STAGE.DMS.ACCOUNT_STATUS_HISTORY nolock  where HEADER_ID = @headerid;
					set @total_dump_record = @total_dump_record + @ctr;
					set @isdump = 1;
				end;

			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail (ACCOUNT_STATUS_HISTORY table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.ACCOUNT_STATUS_HISTORY **********end*************** DELTA

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.ACCOUNT_STATUS_HISTORY***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
		end;
END;

BEGIN /************populates CBDB_STAGE.ACCOUNT_SVS **********start*************** DUMP */
		print 'populates CBDB_STAGE.ACCOUNT_SVS***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'ACCOUNT_SVS';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.ACCOUNT_SVS;

		begin try
			insert into CBDB_STAGE.DMS.ACCOUNT_SVS (														
													HEADER_ID,
													CIF_NO,
													ACCOUNT_NO,
													IMAGE_TYPE
													)
			select
			@headerid,
			CIF_NO,
			ACCOUNT_NO,
			IMAGE_TYPE
			from cbdb_deposit.cbdb_deposit_admin.ACCOUNT_SVS nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.ACCOUNT_SVS nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail ACCOUNT_SVS table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.ACCOUNT_SVS **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.ACCOUNT_SVS***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;
		
BEGIN /************populates CBDB_STAGE.BATCH_HOLD_DATA **********start*************** DUMP */
		print 'populates CBDB_STAGE.BATCH_HOLD_DATA***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'BATCH_HOLD_DATA';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.BATCH_HOLD_DATA;

		begin try
			insert into CBDB_STAGE.DMS.BATCH_HOLD_DATA (														
														HEADER_ID,
														MASTER_FILE_UID,
														UPLOAD_TYPE,
														ACCOUNT_NO,
														AMOUNT,
														EXPIRATION,
														HOLD_CODE,
														REMARKS,
														ACCOUNT_HOLD_ID,
														POSTED_STATUS,
														UNPOSTED_REASON
													)
			select
			@headerid,
			MASTER_FILE_UID,
			UPLOAD_TYPE,
			ACCOUNT_NO,
			AMOUNT,
			EXPIRATION,
			HOLD_CODE,
			REMARKS,
			ACCOUNT_HOLD_ID,
			POSTED_STATUS,
			UNPOSTED_REASON
			from cbdb_deposit.cbdb_deposit_admin.BATCH_HOLD_DATA nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.BATCH_HOLD_DATA nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail BATCH_HOLD_DATA table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.BATCH_HOLD_DATA **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.BATCH_HOLD_DATA***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;

BEGIN /************populates CBDB_STAGE.BIZ_JOURNAL **********start*************** DELTA */
		if exists (select top 1 * from @failedtables  where TABLE_NAME = 'BIZ_JOURNAL' AND SCHEMA_NAME = 'DMS' )
		begin 
		print 'RERUN TRIGGERED';
			set @ReRun = 1;
			begin transaction
			DELETE FROM CBDB_STAGE.DMS.BIZ_JOURNAL WHERE TRAN_DATE = @trandate;
			DELETE FROM CBDB_STAGE.DMS.BIZ_JOURNAL WHERE HEADER_ID = @headerid;
			commit transaction
		end;

		if (@ReRun = 1 or @OneTimeRun = 0)
		begin
		print 'populates CBDB_STAGE.BIZ_JOURNAL***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @status = 2; -- status in progress
		set @tablename = 'BIZ_JOURNAL';

		begin try

			if exists (select top 1 * from CBDB_STAGE.DMS.BIZ_JOURNAL)
				begin
						insert into CBDB_STAGE.DMS.BIZ_JOURNAL (
																HEADER_ID,
																ACCOUNT_NO,
																TRAN_CODE,
																TRAN_TYPE,
																BRANCH_CODE,
																TRAN_DATE,
																AMOUNT,
																CURRENCY_CODE,
																CHANNEL,
																USER_NAME,
																IS_REVERSAL,
																REVERSAL_ORIGINAL_ID,
																REVERSAL_REASON,
																SOURCE_OF_FUND,
																TRAN_REMARK,
																TRAN_PURPOSE,
																SEQUENCE_NO,
																REFERENCE_NO,
																JOURNAL_DATETIME,
																OFFICIAL_RECEIPT,
																ACKNOWLEDGE_RECEIPT,
																INTER_BRANCH,
																TRAN_VALUE_DATE,
																OVERRIDE_ID
																			) 
						select  
						@headerid,
						ACCOUNT_NO,
						TRAN_CODE,
						TRAN_TYPE,
						BRANCH_CODE,
						TRAN_DATE,
						AMOUNT,
						CURRENCY_CODE,
						CHANNEL,
						USER_NAME,
						IS_REVERSAL,
						REVERSAL_ORIGINAL_ID,
						REVERSAL_REASON,
						SOURCE_OF_FUND,
						TRAN_REMARK,
						TRAN_PURPOSE,
						SEQUENCE_NO,
						REFERENCE_NO,
						JOURNAL_DATETIME,
						OFFICIAL_RECEIPT,
						ACKNOWLEDGE_RECEIPT,
						INTER_BRANCH,
						TRAN_VALUE_DATE,
						OVERRIDE_ID

						from cbdb_deposit.cbdb_deposit_admin.BIZ_JOURNAL nolock WHERE TRAN_DATE = @trandate;

					-- count records for delta
					select @ctr = count(*) from CBDB_STAGE.DMS.BIZ_JOURNAL nolock  where HEADER_ID = @headerid;
					set @total_delta_record = @total_delta_record + @ctr;
					set @isdump = 0;
				end;
			else
				begin
						insert into CBDB_STAGE.DMS.BIZ_JOURNAL (
											HEADER_ID,
											ACCOUNT_NO,
											TRAN_CODE,
											TRAN_TYPE,
											BRANCH_CODE,
											TRAN_DATE,
											AMOUNT,
											CURRENCY_CODE,
											CHANNEL,
											USER_NAME,
											IS_REVERSAL,
											REVERSAL_ORIGINAL_ID,
											REVERSAL_REASON,
											SOURCE_OF_FUND,
											TRAN_REMARK,
											TRAN_PURPOSE,
											SEQUENCE_NO,
											REFERENCE_NO,
											JOURNAL_DATETIME,
											OFFICIAL_RECEIPT,
											ACKNOWLEDGE_RECEIPT,
											INTER_BRANCH,
											TRAN_VALUE_DATE,
											OVERRIDE_ID
														) 
						select  
						@headerid,
						ACCOUNT_NO,
						TRAN_CODE,
						TRAN_TYPE,
						BRANCH_CODE,
						TRAN_DATE,
						AMOUNT,
						CURRENCY_CODE,
						CHANNEL,
						USER_NAME,
						IS_REVERSAL,
						REVERSAL_ORIGINAL_ID,
						REVERSAL_REASON,
						SOURCE_OF_FUND,
						TRAN_REMARK,
						TRAN_PURPOSE,
						SEQUENCE_NO,
						REFERENCE_NO,
						JOURNAL_DATETIME,
						OFFICIAL_RECEIPT,
						ACKNOWLEDGE_RECEIPT,
						INTER_BRANCH,
						TRAN_VALUE_DATE,
						OVERRIDE_ID

						from cbdb_deposit.cbdb_deposit_admin.BIZ_JOURNAL nolock;

					-- count records for dump
					select @ctr = count(*) from CBDB_STAGE.DMS.BIZ_JOURNAL nolock  where HEADER_ID = @headerid;
					set @total_dump_record = @total_dump_record + @ctr;
					set @isdump = 1;

				end;

			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail (BIZ_JOURNAL table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.BIZ_JOURNAL **********end*************** DELTA
		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.BIZ_JOURNAL***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
		end;
END;

BEGIN /************populates CBDB_STAGE.CFG_ACCOUNT_STATUS_TYPE **********start*************** DUMP */
		print 'populates CBDB_STAGE.CFG_ACCOUNT_STATUS_TYPE***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'CFG_ACCOUNT_STATUS_TYPE';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.CFG_ACCOUNT_STATUS_TYPE;

		begin try
			insert into CBDB_STAGE.DMS.CFG_ACCOUNT_STATUS_TYPE (														
																HEADER_ID,
																ACCOUNT_STATUS_CODE,
																ACCOUNT_STATUS_NAME,
																STATUS_LEVEL,
																USED,
																LAST_UPDATED_DATE,
																LAST_UPDATED_BY,
																LAST_APPROVED_BY
																)
			select
			@headerid,
			ACCOUNT_STATUS_CODE,
			ACCOUNT_STATUS_NAME,
			STATUS_LEVEL,
			USED,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY

			from cbdb_deposit.cbdb_deposit_admin.CFG_ACCOUNT_STATUS_TYPE nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.CFG_ACCOUNT_STATUS_TYPE nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail CFG_ACCOUNT_STATUS_TYPE table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.CFG_ACCOUNT_STATUS_TYPE **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.CFG_ACCOUNT_STATUS_TYPE***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************

END;
		
BEGIN /************populates CBDB_STAGE.CFG_CCA_TRANSFER **********start*************** DUMP */
		print 'populates CBDB_STAGE.CFG_CCA_TRANSFER***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'CFG_CCA_TRANSFER';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.CFG_CCA_TRANSFER;

		begin try
			insert into CBDB_STAGE.DMS.CFG_CCA_TRANSFER (														
														HEADER_ID,
														CODE,
														TRANSFER_NAME,
														TRANSFER_TYPE,
														EFFECTIVE_DATE,
														STATUS,
														--MAXIMUM_AMOUNT,
														--DAYS_RETAIN,
														FREQUENCY,
														LAST_UPDATED_DATE,
														LAST_UPDATED_BY,
														LAST_APPROVED_BY,
														TRANSFER_CONDITION
																)
			select
			@headerid,	
			CODE,
			TRANSFER_NAME,
			TRANSFER_TYPE,
			EFFECTIVE_DATE,
			STATUS,
			--MAXIMUM_AMOUNT,
			--DAYS_RETAIN,
			FREQUENCY,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY,
			TRANSFER_CONDITION

			from cbdb_deposit.cbdb_deposit_admin.CFG_CCA_TRANSFER nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.CFG_CCA_TRANSFER nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail CFG_CCA_TRANSFER table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.CFG_CCA_TRANSFER **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.CFG_CCA_TRANSFER***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;
		
BEGIN /************populates CBDB_STAGE.CFG_CCA_TRANSFER_AGE **********start*************** DUMP */
		print 'populates CBDB_STAGE.CFG_CCA_TRANSFER_AGE***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'CFG_CCA_TRANSFER_AGE';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.CFG_CCA_TRANSFER_AGE;

		begin try
			insert into CBDB_STAGE.DMS.CFG_CCA_TRANSFER_AGE (														
															HEADER_ID,
															MINIMUM,
															MAXIMUM,
															--AMOUNT,
															EFFECTIVE_DATE,
															MAXIMUM_TRANSFER_AMOUNT,
															LAST_UPDATED_DATE,
															LAST_UPDATED_BY,
															LAST_APPROVED_BY
															)
			select
			@headerid,	
			MINIMUM,
			MAXIMUM,
			--AMOUNT,
			EFFECTIVE_DATE,
			MAXIMUM_TRANSFER_AMOUNT,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY

			from cbdb_deposit.cbdb_deposit_admin.CFG_CCA_TRANSFER_AGE nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.CFG_CCA_TRANSFER_AGE nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail CFG_CCA_TRANSFER_AGE table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.CFG_CCA_TRANSFER_AGE **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.CFG_CCA_TRANSFER_AGE***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;
		
BEGIN /************populates CBDB_STAGE.CFG_CCA_TRANSFER_CORPORATION **********start*************** DUMP */
		print 'populates CBDB_STAGE.CFG_CCA_TRANSFER_CORPORATION***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'CFG_CCA_TRANSFER_CORPORATION';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.CFG_CCA_TRANSFER_CORPORATION;

		begin try
			insert into CBDB_STAGE.DMS.CFG_CCA_TRANSFER_CORPORATION (														
																	HEADER_ID,
																	CATEGORY,
																	CORP_CODE,
																	EFFECTIVE_DATE,
																	LAST_UPDATED_DATE,
																	LAST_UPDATED_BY,
																	LAST_APPROVED_BY
																	)
			select
			@headerid,	
			CATEGORY,
			CORP_CODE,
			EFFECTIVE_DATE,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY

			from cbdb_deposit.cbdb_deposit_admin.CFG_CCA_TRANSFER_CORPORATION nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.CFG_CCA_TRANSFER_CORPORATION nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail CFG_CCA_TRANSFER_CORPORATION table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.CFG_CCA_TRANSFER_CORPORATION **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';
		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.CFG_CCA_TRANSFER_CORPORATION***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;

BEGIN /************populates CBDB_STAGE.CFG_CCA_TRANSFER_IN_SERVICE **********start*************** DUMP */
		print 'populates CBDB_STAGE.CFG_CCA_TRANSFER_IN_SERVICE***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'CFG_CCA_TRANSFER_IN_SERVICE';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.CFG_CCA_TRANSFER_IN_SERVICE;

		begin try
			insert into CBDB_STAGE.DMS.CFG_CCA_TRANSFER_IN_SERVICE (														
																	HEADER_ID,
																	MINIMUM,
																	MAXIMUM,
																	--AMOUNT,
																	EFFECTIVE_DATE,
																	CORP_CATEGORY,
																	MAXIMUM_TRANSFER_AMOUNT,
																	LAST_UPDATED_DATE,
																	LAST_UPDATED_BY,
																	LAST_APPROVED_BY
																	)
			select
			@headerid,	
			MINIMUM,
			MAXIMUM,
			--AMOUNT,
			EFFECTIVE_DATE,
			CORP_CATEGORY,
			MAXIMUM_TRANSFER_AMOUNT,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY

			from cbdb_deposit.cbdb_deposit_admin.CFG_CCA_TRANSFER_IN_SERVICE nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.CFG_CCA_TRANSFER_IN_SERVICE nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail CFG_CCA_TRANSFER_IN_SERVICE table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.CFG_CCA_TRANSFER_IN_SERVICE **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.CFG_CCA_TRANSFER_IN_SERVICE***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;		

BEGIN /************populates CBDB_STAGE.CFG_CCA_TRANSFER_LOAN **********start*************** DUMP */
		print 'populates CBDB_STAGE.CFG_CCA_TRANSFER_LOAN***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'CFG_CCA_TRANSFER_LOAN';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.CFG_CCA_TRANSFER_LOAN;

		begin try
			insert into CBDB_STAGE.DMS.CFG_CCA_TRANSFER_LOAN (														
																HEADER_ID,
																MINIMUM_AMOUNT,
																PRODUCT_CODE,
																EFFECTIVE_DATE,
																LAST_UPDATED_DATE,
																LAST_UPDATED_BY,
																LAST_APPROVED_BY
															)
			select
			@headerid,	
			MINIMUM_AMOUNT,
			PRODUCT_CODE,
			EFFECTIVE_DATE,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY

			from cbdb_deposit.cbdb_deposit_admin.CFG_CCA_TRANSFER_LOAN nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.CFG_CCA_TRANSFER_LOAN nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail CFG_CCA_TRANSFER_LOAN table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.CFG_CCA_TRANSFER_LOAN **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';
		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.CFG_CCA_TRANSFER_LOAN***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;

BEGIN /************populates CBDB_STAGE.CFG_CCA_TRANSFER_MEMBERSHIP **********start*************** DUMP */
		print 'populates CBDB_STAGE.CFG_CCA_TRANSFER_MEMBERSHIP***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'CFG_CCA_TRANSFER_MEMBERSHIP';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.CFG_CCA_TRANSFER_MEMBERSHIP;

		begin try
			insert into CBDB_STAGE.DMS.CFG_CCA_TRANSFER_MEMBERSHIP (														
																	HEADER_ID,
																	--CODE,
																	MINIMUM_YEARS,
																	MAXIMUM_YEARS,
																	--AMOUNT,
																	MAXIMUM_TRANSFER_AMOUNT,
																	EFFECTIVE_DATE,
																	LAST_UPDATED_DATE,
																	LAST_UPDATED_BY,
																	LAST_APPROVED_BY
																	)
			select
			@headerid,	
			--CODE,
			MINIMUM_YEARS,
			MAXIMUM_YEARS,
			--AMOUNT
			MAXIMUM_TRANSFER_AMOUNT,
			EFFECTIVE_DATE,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY

			from cbdb_deposit.cbdb_deposit_admin.CFG_CCA_TRANSFER_MEMBERSHIP nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.CFG_CCA_TRANSFER_MEMBERSHIP nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail CFG_CCA_TRANSFER_MEMBERSHIP table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.CFG_CCA_TRANSFER_MEMBERSHIP **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.CFG_CCA_TRANSFER_MEMBERSHIP***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;
--COMMENTED 2/19/2020		
--BEGIN /************populates CBDB_STAGE.CFG_CCA_TRANSFER_RANK **********start*************** DUMP */
--		print 'populates CBDB_STAGE.CFG_CCA_TRANSFER_RANK***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
--		set @starttime = sysdatetime();
--		set @isdump = 1;
--		set @status = 2; -- status in progress
--		set @tablename = 'CFG_CCA_TRANSFER_RANK';
--		-- need for dumping
--		truncate table CBDB_STAGE.DMS.CFG_CCA_TRANSFER_RANK;

--		begin try
--			insert into CBDB_STAGE.DMS.CFG_CCA_TRANSFER_RANK (														
--															  HEADER_ID,
--															  --CODE,
--															  RANK_CODE,
--															  --AMOUNT,
--															  MAXIMUM_TRANSFER_AMOUNT,
--															  EFFECTIVE_DATE,
--															  LAST_UPDATED_DATE,
--															  LAST_UPDATED_BY,
--															  LAST_APPROVED_BY
--															  )
--			select
--			@headerid,	
--			--CODE,
--			RANK_CODE,
--			--AMOUNT
--			MAXIMUM_TRANSFER_AMOUNT,
--			EFFECTIVE_DATE,
--			LAST_UPDATED_DATE,
--			LAST_UPDATED_BY,
--			LAST_APPROVED_BY

--			from cbdb_deposit.cbdb_deposit_admin.CFG_CCA_TRANSFER_RANK nolock

--		-- count records for dumping
--		select @ctr = count(*) from CBDB_STAGE.DMS.CFG_CCA_TRANSFER_RANK nolock;
--		set @total_dump_record = @total_dump_record + @ctr;


--			 --******************************UPDATE Data Copy Header Status***********start***************
--			begin transaction
--			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
--			commit transaction
--			--******************************UPDATE Data Copy Header Status***********end***************
--		end try
--		begin catch
--			 print '*************error detail CFG_CCA_TRANSFER_RANK table)****************';
--			 print 'error number  :' + cast(error_number() as varchar);
--			 print 'error severity:' + cast(error_severity() as varchar);
--			 print 'error state   :' + cast(error_state() as varchar);
--			 print 'error line    :' + cast(error_line() as varchar);
--			 print 'error message :' + error_message();
--			 set @errormessage = ERROR_MESSAGE();
--			 set @isfailed = 1;
--			 set @status = 3; -- status failed
--			 set @failedSP = 1;
--			 --******************************UPDATE Data Copy Header Status***********start***************
--			begin transaction
--			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
--			commit transaction
--			--******************************UPDATE Data Copy Header Status***********end***************
--		end catch
--		--************populates CBDB_STAGE.CFG_CCA_TRANSFER_RANK **********end*************** DUMP

--		--******************************insert in Data Copy Detail***********start***************
--		set @endtime = sysdatetime();
--		if (@ReRun = 1)
--		begin
--		print 'rerun starts';
--			if @isfailed = 1 -- rerun is still failed
--				begin print 'rerun is still failed';
--				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
--					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
--					print 'rerun is still failed';
--					end
--				end
--			else -- rerun is successful
--			begin print 'rerun is successful';
--				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
--					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
--					print 'rerun status is still successful';
--					end
--				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
--					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
--					print 'rerun is successful - changed status failed to success';
--					end
--				else 
--					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
--					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
--					print 'rerun insert record not yet existing';
--					end
--			end
--		end;
--		else
--		begin
--			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
--			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
--			print 'insert record not yet existing';
--		end
--		print 'resert values';
--		--reset values
--		set @ctr = 0;
--		set @isrollback = 0;
--		set @isfailed = 0;
--		set @errormessage = null;
--		set @isfaulty = 0;
--		set @isdump = null;
		 

--		print 'populates CBDB_STAGE.CFG_CCA_TRANSFER_RANK***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
--		--******************************insert in Data Copy Detail***********end***************
--END;
--COMMENTED 2/19/2020
		
BEGIN /************populates CBDB_STAGE.CFG_CCA_TRANSFER_RANK **********start*************** DUMP */
		print 'populates CBDB_STAGE.CFG_CCA_TRANSFER_TD***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'CFG_CCA_TRANSFER_TD';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.CFG_CCA_TRANSFER_TD;

		begin try
			insert into CBDB_STAGE.DMS.CFG_CCA_TRANSFER_TD (														
															HEADER_ID,
															MINIMUM_AMOUNT,
															MAXIMUM_AMOUNT,
															MAXIMUM_TRANSFER_AMOUNT,
															EFFECTIVE_DATE,
															LAST_UPDATED_BY,
															LAST_APPROVED_BY
															)
			select
			@headerid,	
			MINIMUM_AMOUNT,
			MAXIMUM_AMOUNT,
			MAXIMUM_TRANSFER_AMOUNT,
			EFFECTIVE_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY

			from cbdb_deposit.cbdb_deposit_admin.CFG_CCA_TRANSFER_TD nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.CFG_CCA_TRANSFER_TD nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail CFG_CCA_TRANSFER_TD table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.CFG_CCA_TRANSFER_TD **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.CFG_CCA_TRANSFER_TD***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;

BEGIN /************populates CBDB_STAGE.CFG_CHARGE_FORMULA_CON **********start*************** DUMP */
		print 'populates CBDB_STAGE.CFG_CHARGE_FORMULA_CON***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'CFG_CHARGE_FORMULA_CON';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.CFG_CHARGE_FORMULA_CON;

		begin try
			insert into CBDB_STAGE.DMS.CFG_CHARGE_FORMULA_CON (														
																HEADER_ID,
																CHARGE_CODE,
																AMOUNT_FORMULA,
																CONDITION_FORMULA,
																SEQ_NO,
																LAST_UPDATED_DATE,
																LAST_UPDATED_BY,
																LAST_APPROVED_BY
															)
			select
			@headerid,	
			CHARGE_CODE,
			AMOUNT_FORMULA,
			CONDITION_FORMULA,
			SEQ_NO,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY
			from cbdb_deposit.cbdb_deposit_admin.CFG_CHARGE_FORMULA_CON nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.CFG_CHARGE_FORMULA_CON nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail CFG_CHARGE_FORMULA_CON table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.CFG_CHARGE_FORMULA_CON **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.CFG_CHARGE_FORMULA_CON***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;
		
BEGIN /************populates CBDB_STAGE.CFG_CHARGE_TYPE **********start*************** DUMP */
		print 'populates CBDB_STAGE.CFG_CHARGE_TYPE***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'CFG_CHARGE_TYPE';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.CFG_CHARGE_TYPE;

		begin try
			insert into CBDB_STAGE.DMS.CFG_CHARGE_TYPE (														
														HEADER_ID,
														CHARGE_CODE,
														CHARGE_NAME,
														CHARGE_TYPE,
														USED,
														LAST_UPDATED_DATE,
														LAST_UPDATED_BY,
														LAST_APPROVED_BY,
														CHARGE_COST_TYPE
														)
			select
			@headerid,	
			CHARGE_CODE,
			CHARGE_NAME,
			CHARGE_TYPE,
			USED,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY,
			CHARGE_COST_TYPE
			from cbdb_deposit.cbdb_deposit_admin.CFG_CHARGE_TYPE nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.CFG_CHARGE_TYPE nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail CFG_CHARGE_TYPE table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.CFG_CHARGE_TYPE **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.CFG_CHARGE_TYPE***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;
		
BEGIN /************populates CBDB_STAGE.CFG_EDA **********start*************** DUMP */
		print 'populates CBDB_STAGE.CFG_EDA***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'CFG_EDA';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.CFG_EDA;

		begin try
			insert into CBDB_STAGE.DMS.CFG_EDA (														
												HEADER_ID,
												BUSINESS_YEAR,
												ANNUAL_DIV_RATE,
												ANNUAL_DIV_DATE,
												ADVANCE_ESTIMATED_DIV,
												AED_PERIOD_FROM,
												AED_PERIOD_TO,
												LAST_UPDATED_DATE,
												LAST_UPDATED_BY,
												LAST_APPROVED_BY,
												AED_PERCENTAGE
												)
			select
			@headerid,	
			BUSINESS_YEAR,
			ANNUAL_DIV_RATE,
			ANNUAL_DIV_DATE,
			ADVANCE_ESTIMATED_DIV,
			AED_PERIOD_FROM,
			AED_PERIOD_TO,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY,
			AED_PERCENTAGE
			from cbdb_deposit.cbdb_deposit_admin.CFG_EDA nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.CFG_EDA nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail CFG_EDA table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.CFG_EDA **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.CFG_EDA***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;

BEGIN /************populates CBDB_STAGE.CFG_HOLD_TYPE **********start*************** DUMP */
		print 'populates CBDB_STAGE.CFG_HOLD_TYPE***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'CFG_HOLD_TYPE';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.CFG_HOLD_TYPE;

		begin try
			insert into CBDB_STAGE.DMS.CFG_HOLD_TYPE (														
														HEADER_ID,
														HOLD_CODE,
														HOLD_NAME,
														LAST_UPDATED_DATE,
														LAST_UPDATED_BY,
														LAST_APPROVED_BY
													 )
			select
			@headerid,	
			HOLD_CODE,
			HOLD_NAME,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY
			from cbdb_deposit.cbdb_deposit_admin.CFG_HOLD_TYPE nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.CFG_HOLD_TYPE nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail CFG_HOLD_TYPE table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.CFG_HOLD_TYPE **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.CFG_HOLD_TYPE***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;

BEGIN /************populates CBDB_STAGE.CFG_MISCELLANEOUS_CHARGE_TYPE **********start*************** DUMP */
		print 'populates CBDB_STAGE.CFG_MISCELLANEOUS_CHARGE_TYPE***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'CFG_MISCELLANEOUS_CHARGE_TYPE';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.CFG_MISCELLANEOUS_CHARGE_TYPE;

		begin try
			insert into CBDB_STAGE.DMS.CFG_MISCELLANEOUS_CHARGE_TYPE (														
																		HEADER_ID,
																		MISCELLANEOUS_CHARGE_CODE,
																		MISCELLANEOUS_CHARGE_NAME,
																		MISCELLANEOUS_CHARGE_TYPE,
																		MISCELLANEOUS_COST_TYPE,
																		EFFECTIVE_DATE,
																		USED,
																		LAST_UPDATED_DATE,
																		LAST_UPDATED_BY,
																		LAST_APPROVED_BY
																	)
			select
			@headerid,	
			MISCELLANEOUS_CHARGE_CODE,
			MISCELLANEOUS_CHARGE_NAME,
			MISCELLANEOUS_CHARGE_TYPE,
			MISCELLANEOUS_COST_TYPE,
			EFFECTIVE_DATE,
			USED,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY
			from cbdb_deposit.cbdb_deposit_admin.CFG_MISCELLANEOUS_CHARGE_TYPE nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.CFG_MISCELLANEOUS_CHARGE_TYPE nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail CFG_MISCELLANEOUS_CHARGE_TYPE table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.CFG_MISCELLANEOUS_CHARGE_TYPE **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.CFG_MISCELLANEOUS_CHARGE_TYPE***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;
		

BEGIN /************populates CBDB_STAGE.CFG_MISCELLANEOUS_FORMULA_CON **********start*************** DUMP */
		print 'populates CBDB_STAGE.CFG_MISCELLANEOUS_FORMULA_CON***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'CFG_MISCELLANEOUS_FORMULA_CON';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.CFG_MISCELLANEOUS_FORMULA_CON;

		begin try
			insert into CBDB_STAGE.DMS.CFG_MISCELLANEOUS_FORMULA_CON (														
																	HEADER_ID,
																	MISCELLANEOUS_CHARGE_CODE,
																	AMOUNT_FORMULA,
																	CONDITION_FORMULA,
																	SEQ_NO,
																	LAST_UPDATED_DATE,
																	LAST_UPDATED_BY,
																	LAST_APPROVED_BY,
																	EFFECTIVE_DATE
																	)
			select
			@headerid,	
			MISCELLANEOUS_CHARGE_CODE,
			AMOUNT_FORMULA,
			CONDITION_FORMULA,
			SEQ_NO,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY,
			EFFECTIVE_DATE

			from cbdb_deposit.cbdb_deposit_admin.CFG_MISCELLANEOUS_FORMULA_CON nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.CFG_MISCELLANEOUS_FORMULA_CON nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail CFG_MISCELLANEOUS_FORMULA_CON table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.CFG_MISCELLANEOUS_FORMULA_CON **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.CFG_MISCELLANEOUS_FORMULA_CON***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;
		
BEGIN /************populates CBDB_STAGE.CFG_UTILITY_TYPE **********start*************** DUMP */
		print 'populates CBDB_STAGE.CFG_UTILITY_TYPE***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'CFG_UTILITY_TYPE';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.CFG_UTILITY_TYPE;

		begin try
			insert into CBDB_STAGE.DMS.CFG_UTILITY_TYPE (														
														HEADER_ID,
														CODE,
														NAME,
														BRANCH_CODE,
														SUBSCRIBER_CODE,
														BILL_DOCUMENT_REFERENCE,
														TELEPHONE_PAGE,
														CASH_MODE,
														CHECK_MODE,
														DEBIT_TO_ACCOUNT_MODE,
														LAST_UPDATED_DATE,
														LAST_UPDATED_BY,
														LAST_APPROVED_BY
														)
			select
			@headerid,	
			CODE,
			NAME,
			BRANCH_CODE,
			SUBSCRIBER_CODE,
			BILL_DOCUMENT_REFERENCE,
			TELEPHONE_PAGE,
			CASH_MODE,
			CHECK_MODE,
			DEBIT_TO_ACCOUNT_MODE,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY
			from cbdb_deposit.cbdb_deposit_admin.CFG_UTILITY_TYPE nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.CFG_UTILITY_TYPE nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail CFG_UTILITY_TYPE table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.CFG_UTILITY_TYPE **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.CFG_UTILITY_TYPE***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;
		
BEGIN /************populates CBDB_STAGE.CHECK_ISSUED **********start*************** DUMP */
		print 'populates CBDB_STAGE.CHECK_ISSUED***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'CHECK_ISSUED';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.CHECK_ISSUED;

		begin try
			insert into CBDB_STAGE.DMS.CHECK_ISSUED (														
														HEADER_ID,
														REFERENCE_NO,
														CHQ_ISSUE_DATE,
														CHQ_NUMBER,
														CHQ_BRSTN,
														CHQ_ACCT_NO,
														CHQ_AMOUNT,
														CHQ_PURPOSE,
														PAYEE_NAME,
														BANK_NAME,
														IS_REVERSED,
														CHQ_GUID,
														TRAN_DATE,
														SEQUENCENO,
														TRAN_CODE,
														USER_NAME,
														BRANCH_CODE
														)
			select
			@headerid,	
			REFERENCE_NO,
			CHQ_ISSUE_DATE,
			CHQ_NUMBER,
			CHQ_BRSTN,
			CHQ_ACCT_NO,
			CHQ_AMOUNT,
			CHQ_PURPOSE,
			PAYEE_NAME,
			BANK_NAME,
			IS_REVERSED,
			CHQ_GUID,
			TRAN_DATE,
			SEQUENCENO,
			TRAN_CODE,
			USER_NAME,
			BRANCH_CODE
			from cbdb_deposit.cbdb_deposit_admin.CHECK_ISSUED nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.CHECK_ISSUED nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail CHECK_ISSUED table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.CHECK_ISSUED **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.CHECK_ISSUED***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;
		
BEGIN /************populates CBDB_STAGE.CHECK_ISSUED_SAP **********start*************** DUMP */
		print 'populates CBDB_STAGE.CHECK_ISSUED_SAP***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'CHECK_ISSUED_SAP';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.CHECK_ISSUED_SAP;

		begin try
			insert into CBDB_STAGE.DMS.CHECK_ISSUED_SAP (														
														HEADER_ID,
														FILE_PROCESS_UID,
														REFERENCE_NO,
														CHQ_ISSUE_DATE,
														CHQ_NUMBER,
														CHQ_AMOUNT,
														PAYEE_NAME,
														BANK_NAME,
														PROCESS_STATUS,
														PROCESS_REMARK,
														MODULE_CODE
														)
			select
			@headerid,	
			FILE_PROCESS_UID,
			REFERENCE_NO,
			CHQ_ISSUE_DATE,
			CHQ_NUMBER,
			CHQ_AMOUNT,
			PAYEE_NAME,
			BANK_NAME,
			PROCESS_STATUS,
			PROCESS_REMARK,
			MODULE_CODE
			from cbdb_deposit.cbdb_deposit_admin.CHECK_ISSUED_SAP nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.CHECK_ISSUED_SAP nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail CHECK_ISSUED_SAP table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.CHECK_ISSUED_SAP **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';
		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.CHECK_ISSUED_SAP***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;
		
BEGIN /************populates CBDB_STAGE.CHECK_PLACEMENT **********start*************** DUMP */
		print 'populates CBDB_STAGE.CHECK_PLACEMENT***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'CHECK_PLACEMENT';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.CHECK_PLACEMENT;

		begin try
			insert into CBDB_STAGE.DMS.CHECK_PLACEMENT (														
													HEADER_ID,
													ACCOUNT_NO,
													INTEREST_RATE,
													TERM_FREQUENCY_VALUE,
													TERM_FREQUENCY_UNIT,
													CREDIT_FREQUENCY,
													AUTO_ROLLOVER,
													CREDIT_ACCOUNT,
													OPEN_DATE,
													AUTO_ROLLOVER_TYPE,
													CHQ_GUID,
													LAST_UPDATED_DATE,
													LAST_UPDATED_BY,
													LAST_APPROVED_BY,
													LAST_UPDATED_BRANCH
													)
			select
			@headerid,	
			ACCOUNT_NO,
			INTEREST_RATE,
			TERM_FREQUENCY_VALUE,
			TERM_FREQUENCY_UNIT,
			CREDIT_FREQUENCY,
			AUTO_ROLLOVER,
			CREDIT_ACCOUNT,
			OPEN_DATE,
			AUTO_ROLLOVER_TYPE,
			CHQ_GUID,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY,
			LAST_UPDATED_BRANCH
			from cbdb_deposit.cbdb_deposit_admin.CHECK_PLACEMENT nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.CHECK_PLACEMENT nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail CHECK_PLACEMENT table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.CHECK_PLACEMENT **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.CHECK_PLACEMENT***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;
	
BEGIN /************populates CBDB_STAGE.CHECK_STATUS **********start*************** DUMP */
		print 'populates CBDB_STAGE.CHECK_STATUS***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'CHECK_STATUS';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.CHECK_STATUS;

		begin try
			insert into CBDB_STAGE.DMS.CHECK_STATUS (														
													HEADER_ID,
													ACCOUNT_NO,
													DEPOSIT_DATE,
													BRANCH_REGCODE,
													LATE_CHECK,
													CHQ_TYPE,
													CHQ_ISSUE_DATE,
													CHQ_BRSTN,
													CHQ_BANK_CODE,
													CHQ_BRANCH_CODE,
													CHQ_REGION_CODE,
													CHQ_NUMBER,
													CHQ_SEQNO,
													CHQ_ACCT_NO,
													CHQ_AMOUNT,
													CHQ_FLOAT_DAYS,
													CHQ_STATUS,
													ROLLDOWN,
													REMAIN_DAYFLOAT,
													REMAIN_AMOUNT_BP,
													PROCESS_FLAG,
													CERTIFICATE_NO,
													DBP_STATUS,
													LAST_UPDATED_BY,
													IS_REVERSED,
													CHQ_PURPOSE,
													IS_CLEARED,
													SAP_REFERENCE_NO,
													TRAN_DATE,
													SEQUENCENO,
													TRAN_CODE,
													USER_NAME,
													BRANCH_CODE,
													CHQ_GUID
													)
			select
			@headerid,	
			ACCOUNT_NO,
			DEPOSIT_DATE,
			BRANCH_REGCODE,
			LATE_CHECK,
			CHQ_TYPE,
			CHQ_ISSUE_DATE,
			CHQ_BRSTN,
			CHQ_BANK_CODE,
			CHQ_BRANCH_CODE,
			CHQ_REGION_CODE,
			CHQ_NUMBER,
			CHQ_SEQNO,
			CHQ_ACCT_NO,
			CHQ_AMOUNT,
			CHQ_FLOAT_DAYS,
			CHQ_STATUS,
			ROLLDOWN,
			REMAIN_DAYFLOAT,
			REMAIN_AMOUNT_BP,
			PROCESS_FLAG,
			CERTIFICATE_NO,
			DBP_STATUS,
			LAST_UPDATED_BY,
			IS_REVERSED,
			CHQ_PURPOSE,
			IS_CLEARED,
			SAP_REFERENCE_NO,
			TRAN_DATE,
			SEQUENCENO,
			TRAN_CODE,
			USER_NAME,
			BRANCH_CODE,
			CHQ_GUID
			from cbdb_deposit.cbdb_deposit_admin.CHECK_STATUS nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.CHECK_STATUS nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail CHECK_STATUS table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.CHECK_STATUS **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.CHECK_STATUS***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;

BEGIN /************populates CBDB_STAGE.CHECK_STATUS_EXT **********start*************** DUMP */
		print 'populates CBDB_STAGE.CHECK_STATUS_EXT***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'CHECK_STATUS_EXT';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.CHECK_STATUS_EXT;

		begin try
			insert into CBDB_STAGE.DMS.CHECK_STATUS_EXT (														
														HEADER_ID,
														CHECK_STATUS_ID,
														ACCOUNT_NO,
														AMOUNT,
														TRAN_CODE
														)
			select
			@headerid,			
			CHECK_STATUS_ID,
			ACCOUNT_NO,
			AMOUNT,
			TRAN_CODE
			from cbdb_deposit.cbdb_deposit_admin.CHECK_STATUS_EXT nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.CHECK_STATUS_EXT nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail CHECK_STATUS_EXT table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.CHECK_STATUS_EXT **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.CHECK_STATUS_EXT***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;
		--DID NOT INCLUDE DB_VERSION

BEGIN /************populates CBDB_STAGE.DEP_FILE_MAPPING **********start*************** DUMP */
		print 'populates CBDB_STAGE.DEP_FILE_MAPPING***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'DEP_FILE_MAPPING';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.DEP_FILE_MAPPING;

		begin try
			insert into CBDB_STAGE.DMS.DEP_FILE_MAPPING (														
														HEADER_ID,
														PROCESS_CODE,
														FILE_CODE,
														COLUMN_INDEX,
														COLUMN_TYPE,
														COLUMN_NUM_DECIMAL,
														COLUMN_DATE_FORMAT,
														TARGET_COLUMN_NAME,
														MAX_COL_LENGTH,
														COLUMN_POSITION
														)
			select
			@headerid,			
			PROCESS_CODE,
			FILE_CODE,
			COLUMN_INDEX,
			COLUMN_TYPE,
			COLUMN_NUM_DECIMAL,
			COLUMN_DATE_FORMAT,
			TARGET_COLUMN_NAME,
			MAX_COL_LENGTH,
			COLUMN_POSITION
			from cbdb_deposit.cbdb_deposit_admin.DEP_FILE_MAPPING nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.DEP_FILE_MAPPING nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail DEP_FILE_MAPPING table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.DEP_FILE_MAPPING **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';
		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.DEP_FILE_MAPPING***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;
		
BEGIN /************populates CBDB_STAGE.DEP_FILE_MAPPING_HEADER **********start*************** DUMP */

		print 'populates CBDB_STAGE.DEP_FILE_MAPPING_HEADER***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'DEP_FILE_MAPPING_HEADER';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.DEP_FILE_MAPPING_HEADER;

		begin try
			insert into CBDB_STAGE.DMS.DEP_FILE_MAPPING_HEADER (														
																HEADER_ID,
																SOURCE_FILE_COL_CNT,
																COL_DELIMITER,
																HEADER_TO_SKIP,
																PROCESS_CODE,
																FILE_CODE
																)
			select
			@headerid,			
			SOURCE_FILE_COL_CNT,
			COL_DELIMITER,
			HEADER_TO_SKIP,
			PROCESS_CODE,
			FILE_CODE
			from cbdb_deposit.cbdb_deposit_admin.DEP_FILE_MAPPING_HEADER nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.DEP_FILE_MAPPING_HEADER nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail DEP_FILE_MAPPING_HEADER table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.DEP_FILE_MAPPING_HEADER **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';
		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.DEP_FILE_MAPPING_HEADER***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;
		
BEGIN /************populates CBDB_STAGE.DEPOSIT_PICKLIST **********start*************** DUMP */
		print 'populates CBDB_STAGE.DEPOSIT_PICKLIST***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'DEPOSIT_PICKLIST';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.DEPOSIT_PICKLIST;

		begin try
			insert into CBDB_STAGE.DMS.DEPOSIT_PICKLIST (														
															HEADER_ID,
															CATEGORY,
															CODE,
															DESCRIPTION,
															TAG1,
															TAG2,
															TAG3
														)
			select
			@headerid,			
			CATEGORY,
			CODE,
			DESCRIPTION,
			TAG1,
			TAG2,
			TAG3
			from cbdb_deposit.cbdb_deposit_admin.DEPOSIT_PICKLIST nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.DEPOSIT_PICKLIST nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail DEPOSIT_PICKLIST table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.DEPOSIT_PICKLIST **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.DEPOSIT_PICKLIST***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;
	
BEGIN /************populates CBDB_STAGE.DEPOSIT_TYPE **********start*************** DUMP */
		print 'populates CBDB_STAGE.DEPOSIT_TYPE***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'DEPOSIT_TYPE';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.DEPOSIT_TYPE;

		begin try
			insert into CBDB_STAGE.DMS.DEPOSIT_TYPE (														
													HEADER_ID,
													DEPOSIT_CODE,
													DEPOSIT_NAME,
													APPL_TYPE,
													TIME_DEPOSIT_INTEREST,
													FEE,
													DAYS_IN_MONTH_TYPE,
													DAYS_IN_YEAR_TYPE,
													MINIMUM_BALANCE_REQUIRED,
													MAXIMUM_BALANCE_REQUIRED,
													MINIMUM_NUMBER_DEPOSIT,
													MAXIMUM_NUMBER_DEPOSIT,
													MINIMUM_NUMBER_WITHDRAWAL,
													MAXIMUM_NUMBER_WITHDRAWAL,
													INITIAL_DEPOSIT_REQUIRED,
													AUTO_TRANSFER_ACCOUNT,
													TD_FEE_CHARGE_TAX,
													INSURANCE_COVERAGE,
													CLOSE_ON_ZERO_BALANCE,
													TIERRED_INTEREST,
													ALLOW_CEILING_AMOUNT_MULTIPLIER,
													APPLICANT_AGE_REQUIREMENT,
													LAST_UPDATED_DATE,
													LAST_UPDATED_BY,
													LAST_APPROVED_BY

														)
			select
			@headerid,			
			DEPOSIT_CODE,
			DEPOSIT_NAME,
			APPL_TYPE,
			TIME_DEPOSIT_INTEREST,
			FEE,
			DAYS_IN_MONTH_TYPE,
			DAYS_IN_YEAR_TYPE,
			MINIMUM_BALANCE_REQUIRED,
			MAXIMUM_BALANCE_REQUIRED,
			MINIMUM_NUMBER_DEPOSIT,
			MAXIMUM_NUMBER_DEPOSIT,
			MINIMUM_NUMBER_WITHDRAWAL,
			MAXIMUM_NUMBER_WITHDRAWAL,
			INITIAL_DEPOSIT_REQUIRED,
			AUTO_TRANSFER_ACCOUNT,
			TD_FEE_CHARGE_TAX,
			INSURANCE_COVERAGE,
			CLOSE_ON_ZERO_BALANCE,
			TIERRED_INTEREST,
			ALLOW_CEILING_AMOUNT_MULTIPLIER,
			APPLICANT_AGE_REQUIREMENT,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY
			from cbdb_deposit.cbdb_deposit_admin.DEPOSIT_TYPE nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.DEPOSIT_TYPE nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail DEPOSIT_TYPE table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.DEPOSIT_TYPE **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.DEPOSIT_TYPE***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;

BEGIN /************populates CBDB_STAGE.EDA_ENROLLMENT_STATUS **********start*************** DUMP */
		print 'populates CBDB_STAGE.EDA_ENROLLMENT_STATUS***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'EDA_ENROLLMENT_STATUS';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.EDA_ENROLLMENT_STATUS;

		begin try
			insert into CBDB_STAGE.DMS.EDA_ENROLLMENT_STATUS (														
															HEADER_ID,
															FILE_PROCESS_ID,
															ACCOUNT_NUMBER,
															ACCOUNT_NAME,
															SUBSCRIBER_NUMBER,
															REMARKS,
															STATUS,
															PROCESS_STATUS,
															PROCESS_REMARK
															)
			select
			@headerid,			
			FILE_PROCESS_ID,
			ACCOUNT_NUMBER,
			ACCOUNT_NAME,
			SUBSCRIBER_NUMBER,
			REMARKS,
			STATUS,
			PROCESS_STATUS,
			PROCESS_REMARK
			from cbdb_deposit.cbdb_deposit_admin.EDA_ENROLLMENT_STATUS nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.EDA_ENROLLMENT_STATUS nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail EDA_ENROLLMENT_STATUS table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.EDA_ENROLLMENT_STATUS **********end*************** DUMP


		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';
		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.EDA_ENROLLMENT_STATUS***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************

END; 

BEGIN /************populates CBDB_STAGE.EOD_PROCESS_DONE **********start*************** DUMP */
		print 'populates CBDB_STAGE.EOD_PROCESS_DONE***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'EOD_PROCESS_DONE';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.EOD_PROCESS_DONE;

		begin try
			insert into CBDB_STAGE.DMS.EOD_PROCESS_DONE (														
															HEADER_ID,
															ACCOUNT_NO,
															PROCESS_KEY,
															META,
															TRAN_DATE,
															IS_SUCCESSFUL
															)
			select
			@headerid,			
			ACCOUNT_NO,
			PROCESS_KEY,
			META,
			TRAN_DATE,
			IS_SUCCESSFUL
			from cbdb_deposit.cbdb_deposit_admin.EOD_PROCESS_DONE nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.EOD_PROCESS_DONE nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail EOD_PROCESS_DONE table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.EOD_PROCESS_DONE **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.EOD_PROCESS_DONE***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;

BEGIN /************populates CBDB_STAGE.EOD_PROCESS_FAILED **********start*************** DUMP */
		print 'populates CBDB_STAGE.EOD_PROCESS_FAILED***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'EOD_PROCESS_FAILED';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.EOD_PROCESS_FAILED;

		begin try
			insert into CBDB_STAGE.DMS.EOD_PROCESS_FAILED (														
															HEADER_ID,
															ACCOUNT_NO,
															PROCESS_KEY,
															META,
															TRAN_DATE,
															ERROR
															)
			select
			@headerid,			
			ACCOUNT_NO,
			PROCESS_KEY,
			META,
			TRAN_DATE,
			ERROR
			from cbdb_deposit.cbdb_deposit_admin.EOD_PROCESS_FAILED nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.EOD_PROCESS_FAILED nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail EOD_PROCESS_FAILED table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.EOD_PROCESS_FAILED **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.EOD_PROCESS_FAILED***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;

BEGIN /************populates CBDB_STAGE.FILE_PROCESS_HISTORY **********start*************** DELTA */
		if exists (select top 1 * from @failedtables  where TABLE_NAME = 'FILE_PROCESS_HISTORY' AND SCHEMA_NAME = 'DMS')
		begin 
		print 'RERUN TRIGGERED';
			set @ReRun = 1;
			begin transaction
			DELETE FROM CBDB_STAGE.DMS.FILE_PROCESS_HISTORY WHERE PROCESS_DATE = @trandate;
			DELETE FROM CBDB_STAGE.DMS.FILE_PROCESS_HISTORY WHERE HEADER_ID = @headerid;
			commit transaction
		end;
		
		if (@ReRun = 1 or @OneTimeRun = 0)
		begin
		print 'populates CBDB_STAGE.FILE_PROCESS_HISTORY***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @status = 2; -- status in progress
		set @tablename = 'FILE_PROCESS_HISTORY';

		begin try
			if exists (select top 1 * from CBDB_STAGE.DMS.FILE_PROCESS_HISTORY)
				begin

						insert into CBDB_STAGE.DMS.FILE_PROCESS_HISTORY (
																		HEADER_ID,
																		FILE_NAME,
																		PROCESS_DATE,
																		PROCESS_CODE,
																		PROCESS_STATUS,
																		STATUS_DESC,
																		TOTAL_REC,
																		VALID_REC_CNT,
																		EXC_REC_CNT,
																		REC_WITH_DUP_CNT
																		) 
						select  
						@headerid,
						FILE_NAME,
						PROCESS_DATE,
						PROCESS_CODE,
						PROCESS_STATUS,
						STATUS_DESC,
						TOTAL_REC,
						VALID_REC_CNT,
						EXC_REC_CNT,
						REC_WITH_DUP_CNT
						from cbdb_deposit.cbdb_deposit_admin.FILE_PROCESS_HISTORY nolock WHERE PROCESS_DATE = @trandate;

					-- count records for dumping
					select @ctr = count(*) from CBDB_STAGE.DMS.FILE_PROCESS_HISTORY nolock  where HEADER_ID = @headerid;
					set @total_delta_record = @total_delta_record + @ctr;
					set @isdump = 0;
				end;
			else
				begin
					insert into CBDB_STAGE.DMS.FILE_PROCESS_HISTORY (
																	HEADER_ID,
																	FILE_NAME,
																	PROCESS_DATE,
																	PROCESS_CODE,
																	PROCESS_STATUS,
																	STATUS_DESC,
																	TOTAL_REC,
																	VALID_REC_CNT,
																	EXC_REC_CNT,
																	REC_WITH_DUP_CNT
																	) 
					select  
					@headerid,
					FILE_NAME,
					PROCESS_DATE,
					PROCESS_CODE,
					PROCESS_STATUS,
					STATUS_DESC,
					TOTAL_REC,
					VALID_REC_CNT,
					EXC_REC_CNT,
					REC_WITH_DUP_CNT
					from cbdb_deposit.cbdb_deposit_admin.FILE_PROCESS_HISTORY nolock;

					-- count records for dumping
					select @ctr = count(*) from CBDB_STAGE.DMS.FILE_PROCESS_HISTORY nolock  where HEADER_ID = @headerid;
					set @total_dump_record = @total_dump_record + @ctr;
					set @isdump = 1;
				end;

			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail (FILE_PROCESS_HISTORY table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.FILE_PROCESS_HISTORY **********end*************** DELTA

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 
		print 'populates CBDB_STAGE.FILE_PROCESS_HISTORY***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
		end;
END;

BEGIN /************populates CBDB_STAGE.PASSBOOK_INVENTORY **********start*************** DUMP */
		print 'populates CBDB_STAGE.PASSBOOK_INVENTORY***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'PASSBOOK_INVENTORY';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.PASSBOOK_INVENTORY;

		begin try
			insert into CBDB_STAGE.DMS.PASSBOOK_INVENTORY (														
															HEADER_ID,
															ACCOUNT_NO,
															PASSBOOK_SERIAL_NO,
															ISSUANCE_TYPE,
															REASON,
															ISSUED_DATE,
															ISSUED_BY,
															ISSUED_BRANCH,
															LAST_UPDATED_DATE,
															LAST_UPDATED_BY,
															LAST_APPROVED_BY,
															STATUS
															)
			select
			@headerid,			
			ACCOUNT_NO,
			PASSBOOK_SERIAL_NO,
			ISSUANCE_TYPE,
			REASON,
			ISSUED_DATE,
			ISSUED_BY,
			ISSUED_BRANCH,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY,
			STATUS
			from cbdb_deposit.cbdb_deposit_admin.PASSBOOK_INVENTORY nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.PASSBOOK_INVENTORY nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail PASSBOOK_INVENTORY table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.PASSBOOK_INVENTORY **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.PASSBOOK_INVENTORY***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************

END;

BEGIN /************populates CBDB_STAGE.PRODUCT **********start*************** DUMP */
		print 'populates CBDB_STAGE.PRODUCT***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'PRODUCT';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.PRODUCT;

		begin try
			insert into CBDB_STAGE.DMS.PRODUCT (														
												HEADER_ID,
												DEPOSIT_CODE,
												PRODUCT_CODE,
												PRODUCT_NAME,
												DEPOSIT_PRODUCT_CODE,
												PRODUCT_MNEMONIC,
												CURRENCY_CODE,
												PRIMARY_MEDIA_TYPE,
												SECONDARY_MEDIA_TYPE,
												TERM_TYPE,
												TERM,
												PRETERMINATION,
												INT_RATE_FIRST_HALF_OF_TERM,
												INT_RATE_SECOND_HALF_OF_TERM,
												WTHLDNG_TAX_FIRST_HALF_OF_TERM,
												WTHLDNG_TAX_SECND_HALF_OF_TERM,
												HOLDING_PERIOD,
												CLEARING_PERIOD,
												NOTIFICATION_BEFORE_MATURITY,
												MATURED_UNWITHDRAWAL_INTR_RATE,
												GL_CODE,
												GL_INTEREST_EXPENSES,
												GL_ACCRUED_INT_PAYABLE,
												GL_CLEARING,
												APPROVAL_STATUS_TYPE,
												MINIMUM_AGE,
												MAXIMUM_AGE,
												INTR_COMPUTATION_BALANCE_TYPE,
												BOOKING_INTEREST,
												CREDITING_FREQUENCY,
												EXPIRE_DATE,
												EFFECTIVE_DATE,
												LAST_UPDATED_DATE,
												LAST_UPDATED_BY,
												LAST_APPROVED_BY
												)
			select
			@headerid,			
			DEPOSIT_CODE,
			PRODUCT_CODE,
			PRODUCT_NAME,
			DEPOSIT_PRODUCT_CODE,
			PRODUCT_MNEMONIC,
			CURRENCY_CODE,
			PRIMARY_MEDIA_TYPE,
			SECONDARY_MEDIA_TYPE,
			TERM_TYPE,
			TERM,
			PRETERMINATION,
			INT_RATE_FIRST_HALF_OF_TERM,
			INT_RATE_SECOND_HALF_OF_TERM,
			WTHLDNG_TAX_FIRST_HALF_OF_TERM,
			WTHLDNG_TAX_SECND_HALF_OF_TERM,
			HOLDING_PERIOD,
			CLEARING_PERIOD,
			NOTIFICATION_BEFORE_MATURITY,
			MATURED_UNWITHDRAWAL_INTR_RATE,
			GL_CODE,
			GL_INTEREST_EXPENSES,
			GL_ACCRUED_INT_PAYABLE,
			GL_CLEARING,
			APPROVAL_STATUS_TYPE,
			MINIMUM_AGE,
			MAXIMUM_AGE,
			INTR_COMPUTATION_BALANCE_TYPE,
			BOOKING_INTEREST,
			CREDITING_FREQUENCY,
			EXPIRE_DATE,
			EFFECTIVE_DATE,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY
			from cbdb_deposit.cbdb_deposit_admin.PRODUCT nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.PRODUCT nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail PRODUCT table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.PRODUCT **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.PRODUCT***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************

END;

BEGIN /************populates CBDB_STAGE.PRODUCT_BALANCE **********start*************** DUMP */
		print 'populates CBDB_STAGE.PRODUCT_BALANCE***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'PRODUCT_BALANCE';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.PRODUCT_BALANCE;

		begin try
			insert into CBDB_STAGE.DMS.PRODUCT_BALANCE (														
														HEADER_ID,
														ORG_DEPOSIT_PRODUCT_CODE,
														INITIAL_DEPOSIT,
														BALANCE_TYPE,
														MINIMUM_BALANCE,
														MAXIMUM_BALANCE,
														ATA_MINIMUM_BALANCE,
														ATA_MAXIMUM_BALANCE,
														MINIMUM_BALANCE_FOR_INTEREST,
														INTEREST_BALANCE_TYPE,
														ATA_AVERAGE_DAILY_BALANCE,
														ATA_AVERAGE_DAILY_BALANCE_TYPE,
														NON_WITHDRAWABLE_BAL,
														EFFECTIVE_DATE,
														LAST_UPDATED_DATE,
														LAST_UPDATED_BY,
														LAST_APPROVED_BY
														)
			select
			@headerid,			
			ORG_DEPOSIT_PRODUCT_CODE,
			INITIAL_DEPOSIT,
			BALANCE_TYPE,
			MINIMUM_BALANCE,
			MAXIMUM_BALANCE,
			ATA_MINIMUM_BALANCE,
			ATA_MAXIMUM_BALANCE,
			MINIMUM_BALANCE_FOR_INTEREST,
			INTEREST_BALANCE_TYPE,
			ATA_AVERAGE_DAILY_BALANCE,
			ATA_AVERAGE_DAILY_BALANCE_TYPE,
			NON_WITHDRAWABLE_BAL,
			EFFECTIVE_DATE,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY
			from cbdb_deposit.cbdb_deposit_admin.PRODUCT_BALANCE nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.PRODUCT_BALANCE nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail PRODUCT_BALANCE table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.PRODUCT_BALANCE **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.PRODUCT_BALANCE***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************

END;
		
BEGIN /************populates CBDB_STAGE.PRODUCT_CHANNEL_LIMIT **********start*************** DUMP */
		print 'populates CBDB_STAGE.PRODUCT_CHANNEL_LIMIT***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'PRODUCT_CHANNEL_LIMIT';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.PRODUCT_CHANNEL_LIMIT;

		begin try
			insert into CBDB_STAGE.DMS.PRODUCT_CHANNEL_LIMIT (														
															HEADER_ID,
															ORG_DEPOSIT_PRODUCT_CODE,
															CHANNEL_TYPE,
															CLIENT_TYPE,
															FREQUENCY,
															MINIMUM_NUMBER_OF_DEPOSIT,
															MAXIMUM_NUMBER_OF_DEPOSIT,
															MINIMUM_NUMBER_OF_WITHDRAWAL,
															MAXIMUM_NUMBER_OF_WITHDRAWAL,
															MINIMUM_AMOUNT_OF_DEPOSIT,
															MAXIMUM_AMOUNT_OF_DEPOSIT,
															MINIMUM_AMOUNT_OF_WITHDRAWAL,
															MAXIMUM_AMOUNT_OF_WITHDRAWAL,
															EFFECTIVE_DATE,
															LAST_UPDATED_DATE,
															LAST_UPDATED_BY,
															LAST_APPROVED_BY
															)
			select
			@headerid,			
			ORG_DEPOSIT_PRODUCT_CODE,
			CHANNEL_TYPE,
			CLIENT_TYPE,
			FREQUENCY,
			MINIMUM_NUMBER_OF_DEPOSIT,
			MAXIMUM_NUMBER_OF_DEPOSIT,
			MINIMUM_NUMBER_OF_WITHDRAWAL,
			MAXIMUM_NUMBER_OF_WITHDRAWAL,
			MINIMUM_AMOUNT_OF_DEPOSIT,
			MAXIMUM_AMOUNT_OF_DEPOSIT,
			MINIMUM_AMOUNT_OF_WITHDRAWAL,
			MAXIMUM_AMOUNT_OF_WITHDRAWAL,
			EFFECTIVE_DATE,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY
			from cbdb_deposit.cbdb_deposit_admin.PRODUCT_CHANNEL_LIMIT nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.PRODUCT_CHANNEL_LIMIT nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail PRODUCT_CHANNEL_LIMIT table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.PRODUCT_CHANNEL_LIMIT **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.PRODUCT_CHANNEL_LIMIT***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************

END;
		
BEGIN /************populates CBDB_STAGE.PRODUCT_INACTIVE_CHARGE **********start*************** DUMP */
		print 'populates CBDB_STAGE.PRODUCT_INACTIVE_CHARGE***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'PRODUCT_INACTIVE_CHARGE';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.PRODUCT_INACTIVE_CHARGE;

		begin try
			insert into CBDB_STAGE.DMS.PRODUCT_INACTIVE_CHARGE (														
																HEADER_ID,
																ORG_DEPOSIT_PRODUCT_CODE,
																CHARGE_CODE,
																CHARGE_PERIOD_VALUE,
																CHARGE_PERIOD_UNIT,
																CHARGE_GENERATE_LETTER_VALUE,
																CHARGE_GENERATE_LETTER_UNIT,
																INACTIVITY_PERIOD_VALUE,
																INACTIVITY_PERIOD_UNIT,
																TRANSACTION_CODE,
																EFFECTIVE_DATE,
																LAST_UPDATED_DATE,
																LAST_UPDATED_BY,
																LAST_APPROVED_BY
															)
			select
			@headerid,			
			ORG_DEPOSIT_PRODUCT_CODE,
			CHARGE_CODE,
			CHARGE_PERIOD_VALUE,
			CHARGE_PERIOD_UNIT,
			CHARGE_GENERATE_LETTER_VALUE,
			CHARGE_GENERATE_LETTER_UNIT,
			INACTIVITY_PERIOD_VALUE,
			INACTIVITY_PERIOD_UNIT,
			TRANSACTION_CODE,
			EFFECTIVE_DATE,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY
			from cbdb_deposit.cbdb_deposit_admin.PRODUCT_INACTIVE_CHARGE nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.PRODUCT_INACTIVE_CHARGE nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail PRODUCT_INACTIVE_CHARGE table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.PRODUCT_INACTIVE_CHARGE **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.PRODUCT_INACTIVE_CHARGE***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************

END;
				
BEGIN /************populates CBDB_STAGE.PRODUCT_INTEREST_TIERED **********start*************** DUMP */
		print 'populates CBDB_STAGE.PRODUCT_INTEREST_TIERED***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'PRODUCT_INTEREST_TIERED';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.PRODUCT_INTEREST_TIERED;

		begin try
			insert into CBDB_STAGE.DMS.PRODUCT_INTEREST_TIERED (														
																HEADER_ID,
																ORG_DEPOSIT_PRODUCT_CODE,
																LOWER_BALANCE,
																UPPER_BALANCE,
																INTEREST_RATE,
																EFFECTIVE_DATE,
																LAST_UPDATED_DATE,
																LAST_UPDATED_BY,
																LAST_APPROVED_BY
																)
			select
			@headerid,			
			ORG_DEPOSIT_PRODUCT_CODE,
			LOWER_BALANCE,
			UPPER_BALANCE,
			INTEREST_RATE,
			EFFECTIVE_DATE,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY
			from cbdb_deposit.cbdb_deposit_admin.PRODUCT_INTEREST_TIERED nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.PRODUCT_INTEREST_TIERED nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail PRODUCT_INTEREST_TIERED table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.PRODUCT_INTEREST_TIERED **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.PRODUCT_INTEREST_TIERED***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************

END;		
				
BEGIN /************populates CBDB_STAGE.PRODUCT_MBR_CHARGE **********start*************** DUMP */
		print 'populates CBDB_STAGE.PRODUCT_MBR_CHARGE***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'PRODUCT_MBR_CHARGE';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.PRODUCT_MBR_CHARGE;

		begin try
			insert into CBDB_STAGE.DMS.PRODUCT_MBR_CHARGE (														
													HEADER_ID,
													ORG_DEPOSIT_PRODUCT_CODE,
													FEE_CHARGE_CODE,
													EFFECTIVE_DATE,
													TRANSACTION_CODE,
													CHARGE_PERIOD_VALUE,
													CHARGE_PERIOD_UNIT,
													CHARGE_GENERATE_LETTER_VALUE,
													CHARGE_GENERATE_LETTER_UNIT,
													MBR_PERIOD_VALUE,
													MBR_PERIOD_UNIT,
													LAST_UPDATED_DATE,
													LAST_UPDATED_BY,
													LAST_APPROVED_BY
													)
			select
			@headerid,			
			ORG_DEPOSIT_PRODUCT_CODE,
			FEE_CHARGE_CODE,
			EFFECTIVE_DATE,
			TRANSACTION_CODE,
			CHARGE_PERIOD_VALUE,
			CHARGE_PERIOD_UNIT,
			CHARGE_GENERATE_LETTER_VALUE,
			CHARGE_GENERATE_LETTER_UNIT,
			MBR_PERIOD_VALUE,
			MBR_PERIOD_UNIT,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY
			from cbdb_deposit.cbdb_deposit_admin.PRODUCT_MBR_CHARGE nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.PRODUCT_MBR_CHARGE nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail PRODUCT_MBR_CHARGE table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.PRODUCT_MBR_CHARGE **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.PRODUCT_MBR_CHARGE***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;
				
BEGIN /************populates CBDB_STAGE.PRODUCT_ORGANIZATION **********start*************** DUMP */
		print 'populates CBDB_STAGE.PRODUCT_ORGANIZATION***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'PRODUCT_ORGANIZATION';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.PRODUCT_ORGANIZATION;

		begin try
			insert into CBDB_STAGE.DMS.PRODUCT_ORGANIZATION (														
															HEADER_ID,
															ORG_DEPOSIT_PRODUCT_CODE,
															ORG_NODE_CODE,
															DEPOSIT_PRODUCT_CODE,
															USED,
															LAST_UPDATED_DATE,
															LAST_UPDATED_BY,
															LAST_APPROVED_BY
															)
			select
			@headerid,			
			ORG_DEPOSIT_PRODUCT_CODE,
			ORG_NODE_CODE,
			DEPOSIT_PRODUCT_CODE,
			USED,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY
			from cbdb_deposit.cbdb_deposit_admin.PRODUCT_ORGANIZATION nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.PRODUCT_ORGANIZATION nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail PRODUCT_ORGANIZATION table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.PRODUCT_ORGANIZATION **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.PRODUCT_ORGANIZATION***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************

END;
			
BEGIN /************populates CBDB_STAGE.PRODUCT_OTHER_CONFIG **********start*************** DUMP */
		print 'populates CBDB_STAGE.PRODUCT_OTHER_CONFIG***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'PRODUCT_OTHER_CONFIG';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.PRODUCT_OTHER_CONFIG;

		begin try
			insert into CBDB_STAGE.DMS.PRODUCT_OTHER_CONFIG (														
															HEADER_ID,
															ORG_DEPOSIT_PRODUCT_CODE,
															CEILING_AMOUNT_MULTIPLIER,
															CEILING_AMOUNT_BALANCE_TYPE,
															NON_WITHDRAWABLE_PERCENT,
															MAX_ASSOCIATE_MEMBER_BALANCE,
															CATEGORY,
															GRACE_PERIOD_NO,
															GRACE_TERM,
															TOTAL_FREQUNCY_LIMIT,
															FREQUNCY_TYPE,
															MAX_SECONDARY_MEMBER_BALANCE,
															COLLATERAL,
															HOLDING_PERIOD_ALLOWED,
															HOLDING_PERIOD_VALUE,
															HOLDING_PERIOD_TERM,
															CCA_FALLBACK_RATE,
															MIN_BALANCE_CORPORATE,
															EFFECTIVE_DATE,
															LAST_UPDATED_DATE,
															LAST_UPDATED_BY,
															LAST_APPROVED_BY
															)
			select
			@headerid,			
			ORG_DEPOSIT_PRODUCT_CODE,
			CEILING_AMOUNT_MULTIPLIER,
			CEILING_AMOUNT_BALANCE_TYPE,
			NON_WITHDRAWABLE_PERCENT,
			MAX_ASSOCIATE_MEMBER_BALANCE,
			CATEGORY,
			GRACE_PERIOD_NO,
			GRACE_TERM,
			TOTAL_FREQUNCY_LIMIT,
			FREQUNCY_TYPE,
			MAX_SECONDARY_MEMBER_BALANCE,
			COLLATERAL,
			HOLDING_PERIOD_ALLOWED,
			HOLDING_PERIOD_VALUE,
			HOLDING_PERIOD_TERM,
			CCA_FALLBACK_RATE,
			MIN_BALANCE_CORPORATE,
			EFFECTIVE_DATE,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY
			from cbdb_deposit.cbdb_deposit_admin.PRODUCT_OTHER_CONFIG nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.PRODUCT_OTHER_CONFIG nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail PRODUCT_OTHER_CONFIG table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.PRODUCT_OTHER_CONFIG **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.PRODUCT_OTHER_CONFIG***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
END;

BEGIN /************populates CBDB_STAGE.PRODUCT_OVERALL_FERQUENCY_LIMIT **********start*************** DUMP */
		print 'populates CBDB_STAGE.PRODUCT_OVERALL_FERQUENCY_LIMIT***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'PRODUCT_OVERALL_FERQUENCY_LIMIT';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.PRODUCT_OVERALL_FERQUENCY_LIMIT;

		begin try
			insert into CBDB_STAGE.DMS.PRODUCT_OVERALL_FERQUENCY_LIMIT (														
																		HEADER_ID,
																		ORG_DEPOSIT_PRODUCT_CODE,
																		CLIENT_TYPE,
																		FREQUENCY,
																		OVERALL_DEPOSIT_AMOUNT,
																		OVERALL_WITHDRAWAL_AMOUNT,
																		OVERALL_DEPOSIT_NUMBER,
																		OVERALL_WITHDRAWAL_NUMBER,
																		EFFECTIVE_DATE,
																		LAST_UPDATED_DATE,
																		LAST_UPDATED_BY,
																		LAST_APPROVED_BY
																		)
			select
			@headerid,			
			ORG_DEPOSIT_PRODUCT_CODE,
			CLIENT_TYPE,
			FREQUENCY,
			OVERALL_DEPOSIT_AMOUNT,
			OVERALL_WITHDRAWAL_AMOUNT,
			OVERALL_DEPOSIT_NUMBER,
			OVERALL_WITHDRAWAL_NUMBER,
			EFFECTIVE_DATE,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY

			from cbdb_deposit.cbdb_deposit_admin.PRODUCT_OVERALL_FERQUENCY_LIMIT nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.PRODUCT_OVERALL_FERQUENCY_LIMIT nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail PRODUCT_OVERALL_FERQUENCY_LIMIT table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.PRODUCT_OVERALL_FERQUENCY_LIMIT **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.PRODUCT_OVERALL_FERQUENCY_LIMIT***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************

END;

BEGIN /************populates CBDB_STAGE.PRODUCT_STATUS **********start*************** DUMP */
		print 'populates CBDB_STAGE.PRODUCT_STATUS***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'PRODUCT_STATUS';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.PRODUCT_STATUS;

		begin try
			insert into CBDB_STAGE.DMS.PRODUCT_STATUS (														
														HEADER_ID,
														ORG_DEPOSIT_PRODUCT_CODE,
														ACCOUNT_STATUS_TYPE_CODE,
														ACCOUNT_STATUS_TYPE_NAME,
														NUMBER_OF_FREQUENCY_VALUE,
														NUMBER_OF_FREQUENCY_UNIT,
														GENERATE_LETTER_VALUE,
														GENERATE_LETTER_UNIT,
														UPWARD_TRANSACTION_FLAG,
														DEPOSIT_PR_AC_STTS_TYPE_ED_COD
														)
			select
			@headerid,			
			ORG_DEPOSIT_PRODUCT_CODE,
			ACCOUNT_STATUS_TYPE_CODE,
			ACCOUNT_STATUS_TYPE_NAME,
			NUMBER_OF_FREQUENCY_VALUE,
			NUMBER_OF_FREQUENCY_UNIT,
			GENERATE_LETTER_VALUE,
			GENERATE_LETTER_UNIT,
			UPWARD_TRANSACTION_FLAG,
			DEPOSIT_PR_AC_STTS_TYPE_ED_COD

			from cbdb_deposit.cbdb_deposit_admin.PRODUCT_STATUS nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.PRODUCT_STATUS nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail PRODUCT_STATUS table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.PRODUCT_STATUS **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.PRODUCT_STATUS***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************

END;

BEGIN /************populates CBDB_STAGE.PRODUCT_STATUS_TRAN_RESTRICT **********start*************** DUMP */
		print 'populates CBDB_STAGE.PRODUCT_STATUS_TRAN_RESTRICT***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'PRODUCT_STATUS_TRAN_RESTRICT';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.PRODUCT_STATUS_TRAN_RESTRICT;

		begin try
			insert into CBDB_STAGE.DMS.PRODUCT_STATUS_TRAN_RESTRICT (														
																	HEADER_ID,
																	TRAN_ITEM_TRAN_CODE,
																	DEP_PROD_ACC_STTS_TYPE_ED_COD,
																	EFFECTIVE_DATE,
																	LAST_UPDATED_DATE,
																	LAST_UPDATED_BY,
																	LAST_APPROVED_BY
																	)
			select
			@headerid,			
			TRAN_ITEM_TRAN_CODE,
			DEP_PROD_ACC_STTS_TYPE_ED_COD,
			EFFECTIVE_DATE,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY
			from cbdb_deposit.cbdb_deposit_admin.PRODUCT_STATUS_TRAN_RESTRICT nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.PRODUCT_STATUS_TRAN_RESTRICT nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail PRODUCT_STATUS_TRAN_RESTRICT table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.PRODUCT_STATUS_TRAN_RESTRICT **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.PRODUCT_STATUS_TRAN_RESTRICT***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************

END;		

BEGIN /************populates CBDB_STAGE.PRODUCT_STATUS_TRAN_TRIGGER **********start*************** DUMP */
		print 'populates CBDB_STAGE.PRODUCT_STATUS_TRAN_TRIGGER***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'PRODUCT_STATUS_TRAN_TRIGGER';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.PRODUCT_STATUS_TRAN_TRIGGER;

		begin try
			insert into CBDB_STAGE.DMS.PRODUCT_STATUS_TRAN_TRIGGER (														
																	HEADER_ID,
																	TRAN_ITEM_TRAN_CODE,
																	DEP_PROD_ACC_STTS_TYPE_ED_COD,
																	EFFECTIVE_DATE,
																	LAST_UPDATED_DATE,
																	LAST_UPDATED_BY,
																	LAST_APPROVED_BY
																	)
			select
			@headerid,			
			TRAN_ITEM_TRAN_CODE,
			DEP_PROD_ACC_STTS_TYPE_ED_COD,
			EFFECTIVE_DATE,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY
			from cbdb_deposit.cbdb_deposit_admin.PRODUCT_STATUS_TRAN_TRIGGER nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.PRODUCT_STATUS_TRAN_TRIGGER nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail PRODUCT_STATUS_TRAN_TRIGGER table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.PRODUCT_STATUS_TRAN_TRIGGER **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.PRODUCT_STATUS_TRAN_TRIGGER***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************

END;

BEGIN /************populates CBDB_STAGE.PRODUCT_TD_FEE_CHARGE_TAX **********start*************** DUMP */
		print 'populates CBDB_STAGE.PRODUCT_TD_FEE_CHARGE_TAX***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'PRODUCT_TD_FEE_CHARGE_TAX';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.PRODUCT_TD_FEE_CHARGE_TAX;

		begin try
			insert into CBDB_STAGE.DMS.PRODUCT_TD_FEE_CHARGE_TAX (														
																	HEADER_ID,
																	ORG_DEPOSIT_PRODUCT_CODE,
																	ACTION_TYPE,
																	TRANSACTION_CODE,
																	CHARGE_CODE,
																	EFFECTIVE_DATE,
																	LAST_UPDATED_DATE,
																	LAST_UPDATED_BY,
																	LAST_APPROVED_BY
																	)
			select
			@headerid,			
			ORG_DEPOSIT_PRODUCT_CODE,
			ACTION_TYPE,
			TRANSACTION_CODE,
			CHARGE_CODE,
			EFFECTIVE_DATE,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY
			from cbdb_deposit.cbdb_deposit_admin.PRODUCT_TD_FEE_CHARGE_TAX nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.PRODUCT_TD_FEE_CHARGE_TAX nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail PRODUCT_TD_FEE_CHARGE_TAX table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.PRODUCT_TD_FEE_CHARGE_TAX **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.PRODUCT_TD_FEE_CHARGE_TAX***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************

END;

BEGIN /************populates CBDB_STAGE.PRODUCT_TD_PARAM **********start*************** DUMP */
		print 'populates CBDB_STAGE.PRODUCT_TD_PARAM***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'PRODUCT_TD_PARAM';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.PRODUCT_TD_PARAM;

		begin try
			insert into CBDB_STAGE.DMS.PRODUCT_TD_PARAM (														
														HEADER_ID,
														ORG_DEPOSIT_PRODUCT_CODE,
														PLACEMENT_MIN_AMOUNT,
														PLACEMENT_MAX_AMOUNT,
														HOLDING_PERIOD_DAY,
														HOLDING_PERIOD_CLEARING,
														GENERATE_LETTER_BEFORE_MATURE,
														UNWITHDRAWN_INTEREST_RATE,
														EFFECTIVE_DATE,
														PRE_TERMINATION_RATE,
														MAX_TD_AMOUNT,
														MAX_TD_AMOUNT_PER_MEMBER,
														AUTO_ROLLOVER_LIMIT,
														TERM_UNIT,
														LAST_UPDATED_DATE,
														LAST_UPDATED_BY,
														LAST_APPROVED_BY
																	)
			select
			@headerid,			
			ORG_DEPOSIT_PRODUCT_CODE,
			PLACEMENT_MIN_AMOUNT,
			PLACEMENT_MAX_AMOUNT,
			HOLDING_PERIOD_DAY,
			HOLDING_PERIOD_CLEARING,
			GENERATE_LETTER_BEFORE_MATURE,
			UNWITHDRAWN_INTEREST_RATE,
			EFFECTIVE_DATE,
			PRE_TERMINATION_RATE,
			MAX_TD_AMOUNT,
			MAX_TD_AMOUNT_PER_MEMBER,
			AUTO_ROLLOVER_LIMIT,
			TERM_UNIT,
			LAST_UPDATED_DATE,
			LAST_UPDATED_BY,
			LAST_APPROVED_BY
			from cbdb_deposit.cbdb_deposit_admin.PRODUCT_TD_PARAM nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.PRODUCT_TD_PARAM nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail PRODUCT_TD_PARAM table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.PRODUCT_TD_PARAM **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.PRODUCT_TD_PARAM***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************

END;
		
BEGIN /************populates CBDB_STAGE.VOUCHER **********start*************** DELTA */

		if exists (select top 1 * from @failedtables  where TABLE_NAME = 'VOUCHER' AND SCHEMA_NAME = 'DMS')
		begin 
		print 'RERUN TRIGGERED';
			set @ReRun = 1;
			begin transaction
			DELETE FROM CBDB_STAGE.DMS.VOUCHER WHERE TRAN_DATE = @trandate;
			DELETE FROM CBDB_STAGE.DMS.VOUCHER WHERE HEADER_ID = @headerid;
			commit transaction
		end;

		if (@ReRun = 1 or @OneTimeRun = 0)
		begin
		print 'populates CBDB_STAGE.VOUCHER***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @status = 2; -- status in progress
		set @tablename = 'VOUCHER';

		begin try
			if exists (select top 1 * from CBDB_STAGE.DMS.VOUCHER)
				begin

						insert into CBDB_STAGE.DMS.VOUCHER (
															HEADER_ID,
															ACCOUNT_NO,
															USER_NAME,
															TRAN_CODE,
															TRAN_DATE,
															BRANCH_CODE,
															SEQUENCE_NO,
															IS_REVERSED,
															AMOUNT,
															TO_ACCOUNT_NO,
															CHARGED_BRANCH_CODE,
															GL_CODE,
															TRAN_TYPE,
															OR_NO,
															SRC_OR_TRAN,
															NAME,
															STREET,
															CITY,
															POSTAL_CODE,
															TO_NAME,
															PRIMARY_TRAN

																) 
						select  
						@headerid,
						ACCOUNT_NO,
						USER_NAME,
						TRAN_CODE,
						TRAN_DATE,
						BRANCH_CODE,
						SEQUENCE_NO,
						IS_REVERSED,
						AMOUNT,
						TO_ACCOUNT_NO,
						CHARGED_BRANCH_CODE,
						GL_CODE,
						TRAN_TYPE,
						OR_NO,
						SRC_OR_TRAN,
						NAME,
						STREET,
						CITY,
						POSTAL_CODE,
						TO_NAME,
						PRIMARY_TRAN
						from cbdb_deposit.cbdb_deposit_admin.VOUCHER nolock WHERE TRAN_DATE = @trandate;

					-- count records for dumping
					select @ctr = count(*) from CBDB_STAGE.DMS.VOUCHER nolock  where HEADER_ID = @headerid;
					set @total_delta_record = @total_delta_record + @ctr;
					set @isdump = 0;
				end;
			else
				begin
						insert into CBDB_STAGE.DMS.VOUCHER (
															HEADER_ID,
															ACCOUNT_NO,
															USER_NAME,
															TRAN_CODE,
															TRAN_DATE,
															BRANCH_CODE,
															SEQUENCE_NO,
															IS_REVERSED,
															AMOUNT,
															TO_ACCOUNT_NO,
															CHARGED_BRANCH_CODE,
															GL_CODE,
															TRAN_TYPE,
															OR_NO,
															SRC_OR_TRAN,
															NAME,
															STREET,
															CITY,
															POSTAL_CODE,
															TO_NAME,
															PRIMARY_TRAN

																) 
						select  
						@headerid,
						ACCOUNT_NO,
						USER_NAME,
						TRAN_CODE,
						TRAN_DATE,
						BRANCH_CODE,
						SEQUENCE_NO,
						IS_REVERSED,
						AMOUNT,
						TO_ACCOUNT_NO,
						CHARGED_BRANCH_CODE,
						GL_CODE,
						TRAN_TYPE,
						OR_NO,
						SRC_OR_TRAN,
						NAME,
						STREET,
						CITY,
						POSTAL_CODE,
						TO_NAME,
						PRIMARY_TRAN
						from cbdb_deposit.cbdb_deposit_admin.VOUCHER nolock;

					-- count records for dumping
					select @ctr = count(*) from CBDB_STAGE.DMS.VOUCHER nolock  where HEADER_ID = @headerid;
					set @total_dump_record = @total_dump_record + @ctr;
					set @isdump = 1;
				end;

			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail (VOUCHER table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.VOUCHER **********end*************** DELTA

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.VOUCHER***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************
		end;
END;

BEGIN /************populates CBDB_STAGE.ACCOUNT_BALANCE_EXT **********start*************** DUMP */
		print 'populates CBDB_STAGE.ACCOUNT_BALANCE_EXT***********start' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		set @starttime = sysdatetime();
		set @isdump = 1;
		set @status = 2; -- status in progress
		set @tablename = 'ACCOUNT_BALANCE_EXT';
		-- need for dumping
		truncate table CBDB_STAGE.DMS.ACCOUNT_BALANCE_EXT;

		begin try
			insert into CBDB_STAGE.DMS.ACCOUNT_BALANCE_EXT (														
															HEADER_ID,
															ACCOUNT_NO,
															FIXED_BALANCE,
															BUFFER_BALANCE

																	)
			select
			@headerid,			
			ACCOUNT_NO,
			FIXED_BALANCE,
			BUFFER_BALANCE
			from cbdb_deposit.cbdb_deposit_admin.ACCOUNT_BALANCE_EXT nolock

		-- count records for dumping
		select @ctr = count(*) from CBDB_STAGE.DMS.ACCOUNT_BALANCE_EXT nolock;
		set @total_dump_record = @total_dump_record + @ctr;


			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end try
		begin catch
			 print '*************error detail ACCOUNT_BALANCE_EXT table)****************';
			 print 'error number  :' + cast(error_number() as varchar);
			 print 'error severity:' + cast(error_severity() as varchar);
			 print 'error state   :' + cast(error_state() as varchar);
			 print 'error line    :' + cast(error_line() as varchar);
			 print 'error message :' + error_message();
			 set @errormessage = ERROR_MESSAGE();
			 set @isfailed = 1;
			 set @status = 3; -- status failed
			 set @failedSP = 1;
			 --******************************UPDATE Data Copy Header Status***********start***************
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction
			--******************************UPDATE Data Copy Header Status***********end***************
		end catch
		--************populates CBDB_STAGE.PRODUCT_TD_PARAM **********end*************** DUMP

		--******************************insert in Data Copy Detail***********start***************
		set @endtime = sysdatetime();
		if (@ReRun = 1)
		begin
		print 'rerun starts';
			if @isfailed = 1 -- rerun is still failed
				begin print 'rerun is still failed';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 1, FAIL_EXCEPTION = @errormessage, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is still failed';
					end
				end
			else -- rerun is successful
			begin print 'rerun is successful';
				if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 0 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set is_dump = @isdump, record_count = @ctr, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun status is still successful';
					end
				else if exists ( select top 1 id from cbdb_stage.cmn.DATA_COPY_DETAIL where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname)
					begin update cbdb_stage.cmn.DATA_COPY_DETAIL set IS_FAILED = 0, FAIL_EXCEPTION = null, start_time = @starttime, end_time = @endtime where HEADER_ID = @headerid and TABLE_NAME = @tablename and IS_FAILED = 1 AND SCHEMA_NAME = @schemaname;
					print 'rerun is successful - changed status failed to success';
					end
				else 
					begin exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
					@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
					print 'rerun insert record not yet existing';
					end
			end
		end;
		else
		begin
			exec cbdb_stage.[dbo].[INSERT_DATA_COPY_DETAIL] @headerid = @headerid, @schemaname = @schemaname, @tablename = @tablename ,@ctr=@ctr,@starttime=@starttime, @endtime = @endtime,
			@isfailed=@isfailed, @errormessage=@errormessage,@isfaulty=@isfaulty, @isdump=@isdump;
			print 'insert record not yet existing';
		end
		print 'resert values';

		--reset values
		set @ctr = 0;
		set @isrollback = 0;
		set @isfailed = 0;
		set @errormessage = null;
		set @isfaulty = 0;
		set @isdump = null;
		 

		print 'populates CBDB_STAGE.ACCOUNT_BALANCE_EXT***********end' + ' >>>>' + CONVERT(varchar, SYSDATETIME(), 121);	
		--******************************insert in Data Copy Detail***********end***************

END;

	   --******************************Update Data Copy Header***********start***************
		
		if  (@failedSP != 1)-- not exists (select * from CBDB_STAGE.CMN.DATA_COPY_HEADER where STATUS = 3 and id = @headerid)
		begin
		
			set @status = 4; -- status finished
		
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = 4, TOTAL_DELTA_RECORD = @total_delta_record, TOTAL_DUMP_RECORD = @total_dump_record, END_TIME = SYSDATETIME() where ID = @headerid;
			commit transaction

			PRINT '******************************STAGING PROCESS FINISHED******************************';
		END;
		ELSE
		begin
		
			set @status = 3; -- status failed
		
			begin transaction
			update cbdb_stage.cmn.data_copy_header set status = @status where ID = @headerid;
			commit transaction

			PRINT '******************************STAGING PROCESS FINISHED******************************';
		END;
		--******************************Update Data Copy Header***********end***************


end;
else
	PRINT '******************************STAGING PROCESS BUSINESS DATE IS ALREADY EXISTING******************************';

	--update data table name 
	update cbdb_stage.cmn.data_copy_detail set data_table_name = schema_name +'.'+ table_name where header_id = @headerid;

	EXIT_PROCEDURE:
set nocount off;  
end;



