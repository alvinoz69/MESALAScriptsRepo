IF COL_LENGTH('CBDB_STAGE.LMS.ACCOUNT_INFO', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.ACCOUNT_INFO SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.ACCOUNT_INFO', 'CASA_ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.ACCOUNT_INFO SET CASA_ACCOUNT_NO = RTRIM(CASA_ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.ACCOUNT_INFO', 'MIGRATED_ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.ACCOUNT_INFO SET MIGRATED_ACCOUNT_NO = RTRIM(MIGRATED_ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.DMS.ACCOUNT_CEILING_HISTORY', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.ACCOUNT_CEILING_HISTORY SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.DMS.ACCOUNT_CHANNEL_FREQUENCY', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.ACCOUNT_CHANNEL_FREQUENCY SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.DAILY_ACCOUNT_INFO', 'AMORTIZATION_INFO_ID') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.DAILY_ACCOUNT_INFO SET AMORTIZATION_INFO_ID = RTRIM(AMORTIZATION_INFO_ID) END
IF COL_LENGTH('CBDB_STAGE.DMS.ACCOUNT_CHARGE', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.ACCOUNT_CHARGE SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.DMS.ACCOUNT_HOLD', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.ACCOUNT_HOLD SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.DRE_CHECK', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.DRE_CHECK SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.EOD_PROCESS_DONE', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.EOD_PROCESS_DONE SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.EOD_PROCESS_FAILED', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.EOD_PROCESS_FAILED SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.DMS.ACCOUNT_JOINT', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.ACCOUNT_JOINT SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.ACCOUNT_QUANTITATIVE', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.ACCOUNT_QUANTITATIVE SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.DMS.ACCOUNT_OTHER_SERVICES', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.ACCOUNT_OTHER_SERVICES SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.ACCOUNT_RECURRING_COST', 'AMORTIZATION_INFO_ID') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.ACCOUNT_RECURRING_COST SET AMORTIZATION_INFO_ID = RTRIM(AMORTIZATION_INFO_ID) END
IF COL_LENGTH('CBDB_STAGE.DMS.ACCOUNT_PASSBOOK', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.ACCOUNT_PASSBOOK SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.ACCOUNT_PDC', 'AMORTIZATION_INFO_ID') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.ACCOUNT_PDC SET AMORTIZATION_INFO_ID = RTRIM(AMORTIZATION_INFO_ID) END
IF COL_LENGTH('CBDB_STAGE.LMS.PRE_EMI_INFO', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.PRE_EMI_INFO SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.DMS.ACCOUNT_PLACEMENT', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.ACCOUNT_PLACEMENT SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.DMS.ACCOUNT_PLACEMENT', 'CREDIT_ACCOUNT') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.ACCOUNT_PLACEMENT SET CREDIT_ACCOUNT = RTRIM(CREDIT_ACCOUNT) END
IF COL_LENGTH('CBDB_STAGE.LMS.ACCOUNT_RELEASE_CHECK_ISSUED', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.ACCOUNT_RELEASE_CHECK_ISSUED SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.DMS.ACCOUNT_PLACEMENT_C_F_T', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.ACCOUNT_PLACEMENT_C_F_T SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.BRC.BIZ_JOURNAL', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.BRC.BIZ_JOURNAL SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.ACCOUNT_REPRICING_RATE', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.ACCOUNT_REPRICING_RATE SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.ACCOUNT_RESTRUCTURE_RENEWAL', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.ACCOUNT_RESTRUCTURE_RENEWAL SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.ACCOUNT_RESTRUCTURE_RENEWAL', 'RESTRUCT_RENEW_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.ACCOUNT_RESTRUCTURE_RENEWAL SET RESTRUCT_RENEW_NO = RTRIM(RESTRUCT_RENEW_NO) END
IF COL_LENGTH('CBDB_STAGE.DMS.ACCOUNT_PLACEMENT_ITEM', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.ACCOUNT_PLACEMENT_ITEM SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.ACCOUNT_STATUS', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.ACCOUNT_STATUS SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.COL.EOD_PROCESS_DONE', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.COL.EOD_PROCESS_DONE SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.ACCOUNT_UNPOSTED_PAYMENT', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.ACCOUNT_UNPOSTED_PAYMENT SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.ACCOUNT_UNPOSTED_PAYMENT', 'DEP_ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.ACCOUNT_UNPOSTED_PAYMENT SET DEP_ACCOUNT_NO = RTRIM(DEP_ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.DMS.ACCOUNT_STATUS_HISTORY', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.ACCOUNT_STATUS_HISTORY SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.COL.EOD_PROCESS_FAILED', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.COL.EOD_PROCESS_FAILED SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.ACCOUNT_UPFRONT_COST', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.ACCOUNT_UPFRONT_COST SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.DMS.ACCOUNT_SVS', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.ACCOUNT_SVS SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.DMS.BIZ_JOURNAL', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.BIZ_JOURNAL SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.ACCOUNT_UPFRONT_RECEIVABLE', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.ACCOUNT_UPFRONT_RECEIVABLE SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.AMORTIZATION_INFO', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.AMORTIZATION_INFO SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.AMORTIZATION_INFO', 'AMORTIZATION_INFO_ID') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.AMORTIZATION_INFO SET AMORTIZATION_INFO_ID = RTRIM(AMORTIZATION_INFO_ID) END
IF COL_LENGTH('CBDB_STAGE.LMS.AMORTIZATION_ITEM', 'AMORTIZATION_INFO_ID') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.AMORTIZATION_ITEM SET AMORTIZATION_INFO_ID = RTRIM(AMORTIZATION_INFO_ID) END
IF COL_LENGTH('CBDB_STAGE.DMS.CFG_CCA_TRANSFER_CORPORATION', 'CATEGORY') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.CFG_CCA_TRANSFER_CORPORATION SET CATEGORY = RTRIM(CATEGORY) END
IF COL_LENGTH('CBDB_STAGE.BRC.EOD_PROCESS_DONE', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.BRC.EOD_PROCESS_DONE SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.DMS.CFG_CCA_TRANSFER_IN_SERVICE', 'CORP_CATEGORY') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.CFG_CCA_TRANSFER_IN_SERVICE SET CORP_CATEGORY = RTRIM(CORP_CATEGORY) END
IF COL_LENGTH('CBDB_STAGE.BRC.EOD_PROCESS_FAILED', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.BRC.EOD_PROCESS_FAILED SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.BIZ_JOURNAL', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.BIZ_JOURNAL SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.BIZ_JOURNAL', 'COLLATERAL_ID') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.BIZ_JOURNAL SET COLLATERAL_ID = RTRIM(COLLATERAL_ID) END
IF COL_LENGTH('CBDB_STAGE.DMS.VOUCHER', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.VOUCHER SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.DMS.VOUCHER', 'TO_ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.VOUCHER SET TO_ACCOUNT_NO = RTRIM(TO_ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.DMS.ACCOUNT_INFO', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.ACCOUNT_INFO SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.DMS.ACCOUNT_SERVICES', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.ACCOUNT_SERVICES SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.DMS.ACCOUNT_ANNUAL_BALANCE', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.ACCOUNT_ANNUAL_BALANCE SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.DMS.ACCOUNT_ADDRESS_CONTACT', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.ACCOUNT_ADDRESS_CONTACT SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.DMS.CHECK_STATUS', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.CHECK_STATUS SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.CTL.COLLATERAL', 'COLLATERAL_ID') IS NOT NULL BEGIN UPDATE CBDB_STAGE.CTL.COLLATERAL SET COLLATERAL_ID = RTRIM(COLLATERAL_ID) END
IF COL_LENGTH('CBDB_STAGE.CTL.COLLATERAL_DOCUMENT', 'COLLATERAL_ID') IS NOT NULL BEGIN UPDATE CBDB_STAGE.CTL.COLLATERAL_DOCUMENT SET COLLATERAL_ID = RTRIM(COLLATERAL_ID) END
IF COL_LENGTH('CBDB_STAGE.CMN.BIZ_JOURNAL', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.CMN.BIZ_JOURNAL SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.CTL.COLLATERAL_OWNER', 'COLLATERAL_ID') IS NOT NULL BEGIN UPDATE CBDB_STAGE.CTL.COLLATERAL_OWNER SET COLLATERAL_ID = RTRIM(COLLATERAL_ID) END
IF COL_LENGTH('CBDB_STAGE.CTL.COLLATERAL_OWNER', 'CIF_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.CTL.COLLATERAL_OWNER SET CIF_NO = RTRIM(CIF_NO) END
IF COL_LENGTH('CBDB_STAGE.CTL.DEPOSIT', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.CTL.DEPOSIT SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.DMS.ACCOUNT_BALANCE_EXT', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.ACCOUNT_BALANCE_EXT SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.VOUCHER', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.VOUCHER SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.VOUCHER', 'TO_ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.VOUCHER SET TO_ACCOUNT_NO = RTRIM(TO_ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.VOUCHER', 'COLLATERAL_ID') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.VOUCHER SET COLLATERAL_ID = RTRIM(COLLATERAL_ID) END
IF COL_LENGTH('CBDB_STAGE.DMS.CHECK_PLACEMENT', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.CHECK_PLACEMENT SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.DMS.CHECK_PLACEMENT', 'CREDIT_ACCOUNT') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.CHECK_PLACEMENT SET CREDIT_ACCOUNT = RTRIM(CREDIT_ACCOUNT) END
IF COL_LENGTH('CBDB_STAGE.CTL.OWNER', 'CIF_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.CTL.OWNER SET CIF_NO = RTRIM(CIF_NO) END
IF COL_LENGTH('CBDB_STAGE.CMN.BANK_SUNDRY', 'DATE_FORMAT') IS NOT NULL BEGIN UPDATE CBDB_STAGE.CMN.BANK_SUNDRY SET DATE_FORMAT = RTRIM(DATE_FORMAT) END
IF COL_LENGTH('CBDB_STAGE.DMS.CHECK_STATUS_EXT', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.CHECK_STATUS_EXT SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.CMN.BULK_CONTROL', 'REFERENCE_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.CMN.BULK_CONTROL SET REFERENCE_NO = RTRIM(REFERENCE_NO) END
IF COL_LENGTH('CBDB_STAGE.CTL.TAX_INSURANCE', 'COLLATERAL_ID') IS NOT NULL BEGIN UPDATE CBDB_STAGE.CTL.TAX_INSURANCE SET COLLATERAL_ID = RTRIM(COLLATERAL_ID) END
IF COL_LENGTH('CBDB_STAGE.CMN.BULK_ITEMS', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.CMN.BULK_ITEMS SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.ACCOUNT_AUTODEBIT', 'AMORTIZATION_INFO_ID') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.ACCOUNT_AUTODEBIT SET AMORTIZATION_INFO_ID = RTRIM(AMORTIZATION_INFO_ID) END
IF COL_LENGTH('CBDB_STAGE.CTL.APPRAISAL', 'COLLATERAL_ID') IS NOT NULL BEGIN UPDATE CBDB_STAGE.CTL.APPRAISAL SET COLLATERAL_ID = RTRIM(COLLATERAL_ID) END
IF COL_LENGTH('CBDB_STAGE.LMS.ACCOUNT_BALANCE_HISTORY', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.ACCOUNT_BALANCE_HISTORY SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.ACCOUNT_BALANCE_HISTORY', 'AMORTIZATION_INFO_ID') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.ACCOUNT_BALANCE_HISTORY SET AMORTIZATION_INFO_ID = RTRIM(AMORTIZATION_INFO_ID) END
IF COL_LENGTH('CBDB_STAGE.DMS.ACCOUNT_ATA', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.ACCOUNT_ATA SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.ACCOUNT_CHARGE', 'AMORTIZATION_INFO_ID') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.ACCOUNT_CHARGE SET AMORTIZATION_INFO_ID = RTRIM(AMORTIZATION_INFO_ID) END
IF COL_LENGTH('CBDB_STAGE.DMS.EOD_PROCESS_DONE', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.EOD_PROCESS_DONE SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.DMS.ACCOUNT_BALANCE', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.ACCOUNT_BALANCE SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.DMS.EOD_PROCESS_FAILED', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.EOD_PROCESS_FAILED SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.DMS.ACCOUNT_BALANCE_HISTORY', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.ACCOUNT_BALANCE_HISTORY SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.ACCOUNT_CO_MAKER', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.ACCOUNT_CO_MAKER SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.ACCOUNT_ADDRESS_CONTACT', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.ACCOUNT_ADDRESS_CONTACT SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.ACCOUNT_COLLATERAL', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.ACCOUNT_COLLATERAL SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END
IF COL_LENGTH('CBDB_STAGE.LMS.ACCOUNT_COLLATERAL', 'COLLATERAL_REF_ID') IS NOT NULL BEGIN UPDATE CBDB_STAGE.LMS.ACCOUNT_COLLATERAL SET COLLATERAL_REF_ID = RTRIM(COLLATERAL_REF_ID) END
IF COL_LENGTH('CBDB_STAGE.DMS.PASSBOOK_INVENTORY', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_STAGE.DMS.PASSBOOK_INVENTORY SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END

IF COL_LENGTH('CBDB_REPORTS.LMS.ACCOUNT_PDC', 'AMORTIZATION_INFO_ID') IS NOT NULL BEGIN UPDATE CBDB_REPORTS.LMS.ACCOUNT_PDC SET AMORTIZATION_INFO_ID = RTRIM(AMORTIZATION_INFO_ID) END
IF COL_LENGTH('CBDB_REPORTS.LMS.COLLATERAL', 'PLATE_NO') IS NOT NULL BEGIN UPDATE CBDB_REPORTS.LMS.COLLATERAL SET PLATE_NO = RTRIM(PLATE_NO) END
IF COL_LENGTH('CBDB_REPORTS.LMS.APPRAISAL', 'COLLATERAL_ID') IS NOT NULL BEGIN UPDATE CBDB_REPORTS.LMS.APPRAISAL SET COLLATERAL_ID = RTRIM(COLLATERAL_ID) END
IF COL_LENGTH('CBDB_REPORTS.LMS.ACCOUNT_CO_MAKER', 'ACCOUNT_NO') IS NOT NULL BEGIN UPDATE CBDB_REPORTS.LMS.ACCOUNT_CO_MAKER SET ACCOUNT_NO = RTRIM(ACCOUNT_NO) END