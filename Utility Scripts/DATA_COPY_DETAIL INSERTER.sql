USE [CBDB_STAGE]
GO

INSERT INTO [CMN].[DATA_COPY_DETAIL]
           ([HEADER_ID]
           ,[DATA_TABLE_NAME]
           ,[RECORD_COUNT]
           ,[START_TIME]
           ,[END_TIME]
           ,[IS_FAILED]
           ,[FAIL_EXCEPTION]
           ,[PER_EOD]
           ,[IS_FAULTY]
           ,[IS_DUMP])
     VALUES
           (44
           ,'MMS.CLIENT'
           ,1
           ,GETDATE()
           ,GETDATE()
           ,0
           ,NULL
           ,0
           ,0
           ,0)
GO


