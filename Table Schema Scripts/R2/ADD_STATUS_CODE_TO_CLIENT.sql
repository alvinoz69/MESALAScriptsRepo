IF COL_LENGTH('CBDB_REPORTS.MMS.CLIENT', 'CLIENT_STATUS_CODE') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.MMS.CLIENT
	ADD CLIENT_STATUS_CODE VARCHAR(10)
END


IF COL_LENGTH('CBDB_REPORTS.MMS.CLIENT', 'MEMBER_TYPE_CODE') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.MMS.CLIENT
	ADD MEMBER_TYPE_CODE VARCHAR(10)
END
