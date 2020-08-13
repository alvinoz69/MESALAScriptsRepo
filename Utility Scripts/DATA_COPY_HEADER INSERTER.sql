USE [CBDB_STAGE]
GO

INSERT INTO [CMN].[DATA_COPY_HEADER]
           ([HEADER_ID]
           ,[MODULE_CODE]
           ,[BUSINESS_DATE]
           ,[TOTAL_DUMP_RECORD]
           ,[TOTAL_DELTA_RECORD]
           ,[START_TIME]
           ,[END_TIME]
           ,[IS_FAILED]
           ,[STATUS]
           ,[IS_FAULTY]
           ,[TOTAL_FAULTY_RECORD])
     VALUES
           (NULL
           ,'CIF'
           ,'2019-10-17'
           ,0
           ,0
           ,GETDATE()
           ,GETDATE()
           ,0
           ,4
           ,0
           ,0)
GO


