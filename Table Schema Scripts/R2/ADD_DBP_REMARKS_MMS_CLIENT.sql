IF COL_LENGTH('CBDB_REPORTS.MMS.CLIENT', 'DBP_REMARKS') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.MMS.CLIENT
	ADD DBP_REMARKS VARCHAR(10) NULL
END

IF COL_LENGTH('CBDB_REPORTS.MMS.CLIENT', 'DBP_SPS_REMARKS') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.MMS.CLIENT
	ADD DBP_SPS_REMARKS VARCHAR(10) NULL
END