IF COL_LENGTH('CBDB_STAGE.MMS.BIZ_JOURNAL', 'OVERRIDE_ID') IS NULL
BEGIN
	ALTER TABLE CBDB_STAGE.MMS.BIZ_JOURNAL
	ADD OVERRIDE_ID [nvarchar](50)
END


