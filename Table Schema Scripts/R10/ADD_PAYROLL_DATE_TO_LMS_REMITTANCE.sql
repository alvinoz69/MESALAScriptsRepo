IF COL_LENGTH('CBDB_REPORTS.LMS.REMITTANCE', 'PAYROLL_DATE') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.LMS.REMITTANCE
	ADD PAYROLL_DATE DATE
END