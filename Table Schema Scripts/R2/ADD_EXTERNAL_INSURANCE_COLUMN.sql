IF COL_LENGTH('CBDB_REPORTS.LMS.INSURANCE', 'EXTERNAL_INSURANCE') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.LMS.INSURANCE
	ADD EXTERNAL_INSURANCE SMALLINT DEFAULT 0 NOT NULL
END
GO
