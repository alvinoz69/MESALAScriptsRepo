IF COL_LENGTH('CBDB_REPORTS.MMS.RELATIONSHIP', 'RELATIONSHIP_TYPE_CODE') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.MMS.RELATIONSHIP
	ADD RELATIONSHIP_TYPE_CODE VARCHAR(100)
END