IF COL_LENGTH('CBDB_REPORTS.CMN.BILLING', 'BILL_AMOUNT') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.CMN.BILLING
	ADD BILL_AMOUNT DECIMAL(18,2) DEFAULT 0
END
