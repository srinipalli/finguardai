-- =====================================================================
-- fg_rules_bulk_v2.sql
-- Comprehensive rules set (~120) covering velocity, time-of-day, channels,
-- geo/geo-velocity, MCC risk, blacklist/reputation, KYC/lifecycle,
-- beneficiary novelty, behavioral patterns, chargebacks, wallet/forex/card,
-- OTP/PIN anomalies, graph/fraud-ring hints, scam signals.
-- Idempotent via MERGE; safe to rerun.
-- =====================================================================
SET DEFINE OFF
PROMPT Loading fg_rules_bulk_v2 ...

MERGE INTO fg_rules r
USING (SELECT 'FG_VELOCITY_01' AS rule_code, q'[ {"category":"VELOCITY","scope":"ACCOUNT","window_minutes":15,"txn_count_gt":3,"total_amount_gte":10000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Velocity breach (ACCOUNT 3 in 15m)', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_VELOCITY_01',''Velocity breach (ACCOUNT 3 in 15m)'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_VELOCITY_02' AS rule_code, q'[ {"category":"VELOCITY","scope":"DEVICE","window_minutes":30,"txn_count_gt":5,"total_amount_gte":20000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Velocity breach (DEVICE 5 in 30m)', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_VELOCITY_02',''Velocity breach (DEVICE 5 in 30m)'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_VELOCITY_03' AS rule_code, q'[ {"category":"VELOCITY","scope":"IP","window_minutes":60,"txn_count_gt":7,"total_amount_gte":30000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Velocity breach (IP 7 in 60m)', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_VELOCITY_03',''Velocity breach (IP 7 in 60m)'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_VELOCITY_04' AS rule_code, q'[ {"category":"VELOCITY","scope":"MERCHANT","window_minutes":120,"txn_count_gt":10,"total_amount_gte":50000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Velocity breach (MERCHANT 10 in 120m)', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_VELOCITY_04',''Velocity breach (MERCHANT 10 in 120m)'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_VELOCITY_05' AS rule_code, q'[ {"category":"VELOCITY","scope":"CUSTOMER","window_minutes":1440,"txn_count_gt":20,"total_amount_gte":100000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Velocity breach (CUSTOMER 20 in 1440m)', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_VELOCITY_05',''Velocity breach (CUSTOMER 20 in 1440m)'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_VELOCITY_06' AS rule_code, q'[ {"category":"VELOCITY","scope":"CARD","window_minutes":4320,"txn_count_gt":40,"total_amount_gte":150000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Velocity breach (CARD 40 in 4320m)', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_VELOCITY_06',''Velocity breach (CARD 40 in 4320m)'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_TIME_01' AS rule_code, q'[ {"category":"TIME_OF_DAY","hour_from":0,"hour_to":4,"days":"ANY","amount_gte":20000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Time-of-day anomaly 0-4h', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_TIME_01',''Time-of-day anomaly 0-4h'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_TIME_02' AS rule_code, q'[ {"category":"TIME_OF_DAY","hour_from":1,"hour_to":5,"days":"WEEKEND","amount_gte":25000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Time-of-day anomaly 1-5h', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_TIME_02',''Time-of-day anomaly 1-5h'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_TIME_03' AS rule_code, q'[ {"category":"TIME_OF_DAY","hour_from":22,"hour_to":23,"days":"WEEKDAY","amount_gte":30000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Time-of-day anomaly 22-23h', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_TIME_03',''Time-of-day anomaly 22-23h'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_TIME_04' AS rule_code, q'[ {"category":"TIME_OF_DAY","hour_from":0,"hour_to":6,"days":"ANY","amount_gte":15000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Time-of-day anomaly 0-6h', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_TIME_04',''Time-of-day anomaly 0-6h'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_TIME_05' AS rule_code, q'[ {"category":"TIME_OF_DAY","hour_from":23,"hour_to":2,"days":"ANY","amount_gte":18000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Time-of-day anomaly 23-2h', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_TIME_05',''Time-of-day anomaly 23-2h'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_TIME_06' AS rule_code, q'[ {"category":"TIME_OF_DAY","hour_from":12,"hour_to":14,"days":"WEEKDAY","amount_gte":500000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Time-of-day anomaly 12-14h', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_TIME_06',''Time-of-day anomaly 12-14h'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_CARD_01' AS rule_code, q'[ {"category":"CHANNEL","channel":"CARD","subtype":"CNP","amount_gte":10000,"present":false} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='CARD anomaly - CNP', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_CARD_01',''CARD anomaly - CNP'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_CARD_02' AS rule_code, q'[ {"category":"CHANNEL","channel":"CARD","subtype":"CONTACTLESS","amount_gte":20000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='CARD anomaly - CONTACTLESS', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_CARD_02',''CARD anomaly - CONTACTLESS'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_CARD_03' AS rule_code, q'[ {"category":"CHANNEL","channel":"CARD","subtype":"MOTO","amount_gte":30000,"present":false} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='CARD anomaly - MOTO', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_CARD_03',''CARD anomaly - MOTO'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_CARD_04' AS rule_code, q'[ {"category":"CHANNEL","channel":"CARD","subtype":"INTERNATIONAL","amount_gte":40000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='CARD anomaly - INTERNATIONAL', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_CARD_04',''CARD anomaly - INTERNATIONAL'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_CARD_05' AS rule_code, q'[ {"category":"CHANNEL","channel":"CARD","subtype":"ECOM","amount_gte":50000,"present":false} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='CARD anomaly - ECOM', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_CARD_05',''CARD anomaly - ECOM'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_CARD_06' AS rule_code, q'[ {"category":"CHANNEL","channel":"CARD","subtype":"CARD_PRESENT","amount_gte":60000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='CARD anomaly - CARD_PRESENT', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_CARD_06',''CARD anomaly - CARD_PRESENT'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_UPI_01' AS rule_code, q'[ {"category":"CHANNEL","channel":"UPI","subtype":"P2P","amount_gte":10000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='UPI anomaly - P2P', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_UPI_01',''UPI anomaly - P2P'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_UPI_02' AS rule_code, q'[ {"category":"CHANNEL","channel":"UPI","subtype":"P2M","amount_gte":20000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='UPI anomaly - P2M', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_UPI_02',''UPI anomaly - P2M'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_UPI_03' AS rule_code, q'[ {"category":"CHANNEL","channel":"UPI","subtype":"AUTOPAY","amount_gte":30000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='UPI anomaly - AUTOPAY', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_UPI_03',''UPI anomaly - AUTOPAY'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_UPI_04' AS rule_code, q'[ {"category":"CHANNEL","channel":"UPI","subtype":"MANDATE","amount_gte":40000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='UPI anomaly - MANDATE', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_UPI_04',''UPI anomaly - MANDATE'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_UPI_05' AS rule_code, q'[ {"category":"CHANNEL","channel":"UPI","subtype":"QR_STATIC","amount_gte":50000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='UPI anomaly - QR_STATIC', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_UPI_05',''UPI anomaly - QR_STATIC'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_UPI_06' AS rule_code, q'[ {"category":"CHANNEL","channel":"UPI","subtype":"QR_DYNAMIC","amount_gte":60000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='UPI anomaly - QR_DYNAMIC', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_UPI_06',''UPI anomaly - QR_DYNAMIC'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_IMPS_01' AS rule_code, q'[ {"category":"CHANNEL","channel":"IMPS","subtype":"P2A","amount_gte":10000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='IMPS anomaly - P2A', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_IMPS_01',''IMPS anomaly - P2A'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_IMPS_02' AS rule_code, q'[ {"category":"CHANNEL","channel":"IMPS","subtype":"P2P","amount_gte":20000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='IMPS anomaly - P2P', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_IMPS_02',''IMPS anomaly - P2P'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_IMPS_03' AS rule_code, q'[ {"category":"CHANNEL","channel":"IMPS","subtype":"MERCHANT","amount_gte":30000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='IMPS anomaly - MERCHANT', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_IMPS_03',''IMPS anomaly - MERCHANT'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_IMPS_04' AS rule_code, q'[ {"category":"CHANNEL","channel":"IMPS","subtype":"NIGHT","amount_gte":40000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='IMPS anomaly - NIGHT', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_IMPS_04',''IMPS anomaly - NIGHT'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_IMPS_05' AS rule_code, q'[ {"category":"CHANNEL","channel":"IMPS","subtype":"HIGH_VALUE","amount_gte":50000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='IMPS anomaly - HIGH_VALUE', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_IMPS_05',''IMPS anomaly - HIGH_VALUE'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_IMPS_06' AS rule_code, q'[ {"category":"CHANNEL","channel":"IMPS","subtype":"NEW_BENEFICIARY","amount_gte":60000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='IMPS anomaly - NEW_BENEFICIARY', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_IMPS_06',''IMPS anomaly - NEW_BENEFICIARY'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_NEFT_01' AS rule_code, q'[ {"category":"CHANNEL","channel":"NEFT","subtype":"BATCH","amount_gte":10000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='NEFT anomaly - BATCH', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_NEFT_01',''NEFT anomaly - BATCH'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_NEFT_02' AS rule_code, q'[ {"category":"CHANNEL","channel":"NEFT","subtype":"ODD_HOURS","amount_gte":20000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='NEFT anomaly - ODD_HOURS', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_NEFT_02',''NEFT anomaly - ODD_HOURS'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_NEFT_03' AS rule_code, q'[ {"category":"CHANNEL","channel":"NEFT","subtype":"NEW_PAYEE","amount_gte":30000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='NEFT anomaly - NEW_PAYEE', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_NEFT_03',''NEFT anomaly - NEW_PAYEE'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_NEFT_04' AS rule_code, q'[ {"category":"CHANNEL","channel":"NEFT","subtype":"HIGH_VALUE","amount_gte":40000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='NEFT anomaly - HIGH_VALUE', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_NEFT_04',''NEFT anomaly - HIGH_VALUE'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_NEFT_05' AS rule_code, q'[ {"category":"CHANNEL","channel":"NEFT","subtype":"CORP_BULK","amount_gte":50000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='NEFT anomaly - CORP_BULK', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_NEFT_05',''NEFT anomaly - CORP_BULK'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_NEFT_06' AS rule_code, q'[ {"category":"CHANNEL","channel":"NEFT","subtype":"FIRST_TIME_IFSC","amount_gte":60000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='NEFT anomaly - FIRST_TIME_IFSC', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_NEFT_06',''NEFT anomaly - FIRST_TIME_IFSC'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_NETBANK_01' AS rule_code, q'[ {"category":"CHANNEL","channel":"NETBANKING","subtype":"LOGIN_NEW_DEVICE","amount_gte":10000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='NETBANKING anomaly - LOGIN_NEW_DEVICE', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_NETBANK_01',''NETBANKING anomaly - LOGIN_NEW_DEVICE'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_NETBANK_02' AS rule_code, q'[ {"category":"CHANNEL","channel":"NETBANKING","subtype":"PAYEE_FIRST","amount_gte":20000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='NETBANKING anomaly - PAYEE_FIRST', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_NETBANK_02',''NETBANKING anomaly - PAYEE_FIRST'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_NETBANK_03' AS rule_code, q'[ {"category":"CHANNEL","channel":"NETBANKING","subtype":"BILLPAY","amount_gte":30000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='NETBANKING anomaly - BILLPAY', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_NETBANK_03',''NETBANKING anomaly - BILLPAY'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_NETBANK_04' AS rule_code, q'[ {"category":"CHANNEL","channel":"NETBANKING","subtype":"HIGH_VALUE","amount_gte":40000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='NETBANKING anomaly - HIGH_VALUE', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_NETBANK_04',''NETBANKING anomaly - HIGH_VALUE'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_NETBANK_05' AS rule_code, q'[ {"category":"CHANNEL","channel":"NETBANKING","subtype":"MULTI_IP","amount_gte":50000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='NETBANKING anomaly - MULTI_IP', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_NETBANK_05',''NETBANKING anomaly - MULTI_IP'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_NETBANK_06' AS rule_code, q'[ {"category":"CHANNEL","channel":"NETBANKING","subtype":"NEW_BROWSER","amount_gte":60000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='NETBANKING anomaly - NEW_BROWSER', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_NETBANK_06',''NETBANKING anomaly - NEW_BROWSER'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_ATM_01' AS rule_code, q'[ {"category":"CHANNEL","channel":"ATM","subtype":"WITHDRAWAL","amount_gte":10000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='ATM anomaly - WITHDRAWAL', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_ATM_01',''ATM anomaly - WITHDRAWAL'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_ATM_02' AS rule_code, q'[ {"category":"CHANNEL","channel":"ATM","subtype":"BALANCE_ENQ","amount_gte":20000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='ATM anomaly - BALANCE_ENQ', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_ATM_02',''ATM anomaly - BALANCE_ENQ'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_ATM_03' AS rule_code, q'[ {"category":"CHANNEL","channel":"ATM","subtype":"MULTI_WITHDRAW","amount_gte":30000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='ATM anomaly - MULTI_WITHDRAW', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_ATM_03',''ATM anomaly - MULTI_WITHDRAW'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_ATM_04' AS rule_code, q'[ {"category":"CHANNEL","channel":"ATM","subtype":"NIGHT","amount_gte":40000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='ATM anomaly - NIGHT', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_ATM_04',''ATM anomaly - NIGHT'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_ATM_05' AS rule_code, q'[ {"category":"CHANNEL","channel":"ATM","subtype":"REMOTE_CITY","amount_gte":50000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='ATM anomaly - REMOTE_CITY', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_ATM_05',''ATM anomaly - REMOTE_CITY'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_ATM_06' AS rule_code, q'[ {"category":"CHANNEL","channel":"ATM","subtype":"FAILED_PIN","amount_gte":60000,"present":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='ATM anomaly - FAILED_PIN', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_ATM_06',''ATM anomaly - FAILED_PIN'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_GEO_01' AS rule_code, q'[ {"category":"GEO","geo_country_mismatch":true,"home_country":"IN","ip_country":"XX","amount_gte":20000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Geo anomaly 1', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_GEO_01',''Geo anomaly 1'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_GEO_02' AS rule_code, q'[ {"category":"GEO","geo_distance_km_gt":500,"window_minutes":60,"amount_gte":30000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Geo anomaly 2', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_GEO_02',''Geo anomaly 2'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_GEO_03' AS rule_code, q'[ {"category":"GEO","geo_new_city":true,"city_risk_score_gte":70,"amount_gte":15000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Geo anomaly 3', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_GEO_03',''Geo anomaly 3'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_GEO_04' AS rule_code, q'[ {"category":"GEO","ip_proxy_vpn":true,"reputation_score_lte":30,"amount_gte":12000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Geo anomaly 4', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_GEO_04',''Geo anomaly 4'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_GEO_05' AS rule_code, q'[ {"category":"GEO","ip_tor":true,"amount_gte":8000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Geo anomaly 5', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_GEO_05',''Geo anomaly 5'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_GEO_06' AS rule_code, q'[ {"category":"GEO","gps_missing_but_required":true,"channel":"UPI","amount_gte":10000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Geo anomaly 6', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_GEO_06',''Geo anomaly 6'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_GEOVEL_01' AS rule_code, q'[ {"category":"GEO_VELOCITY","geo_points_required":2,"distance_km_gt":1000,"window_minutes":30} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Geo-velocity hop 1', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_GEOVEL_01',''Geo-velocity hop 1'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_GEOVEL_02' AS rule_code, q'[ {"category":"GEO_VELOCITY","geo_points_required":2,"distance_km_gt":800,"window_minutes":20} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Geo-velocity hop 2', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_GEOVEL_02',''Geo-velocity hop 2'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_GEOVEL_03' AS rule_code, q'[ {"category":"GEO_VELOCITY","geo_points_required":2,"distance_km_gt":300,"window_minutes":10} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Geo-velocity hop 3', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_GEOVEL_03',''Geo-velocity hop 3'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_GEOVEL_04' AS rule_code, q'[ {"category":"GEO_VELOCITY","geo_points_required":2,"distance_km_gt":150,"window_minutes":5} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Geo-velocity hop 4', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_GEOVEL_04',''Geo-velocity hop 4'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_GEOVEL_05' AS rule_code, q'[ {"category":"GEO_VELOCITY","geo_points_required":2,"country_hop":true,"window_minutes":60} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Geo-velocity hop 5', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_GEOVEL_05',''Geo-velocity hop 5'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_GEOVEL_06' AS rule_code, q'[ {"category":"GEO_VELOCITY","geo_points_required":2,"cell_tower_hop":true,"window_minutes":15} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Geo-velocity hop 6', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_GEOVEL_06',''Geo-velocity hop 6'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_MCC_01' AS rule_code, q'[ {"category":"MCC_RISK","mcc_in":["4829","6011","6012"],"merchant_risk_score_gte":70,"chargeback_rate_gte":0.04} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='High-risk MCC cluster 1', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_MCC_01',''High-risk MCC cluster 1'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_MCC_02' AS rule_code, q'[ {"category":"MCC_RISK","mcc_in":["7995","7801","7832"],"merchant_risk_score_gte":70,"chargeback_rate_gte":0.04} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='High-risk MCC cluster 2', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_MCC_02',''High-risk MCC cluster 2'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_MCC_03' AS rule_code, q'[ {"category":"MCC_RISK","mcc_in":["5122","5912","5977"],"merchant_risk_score_gte":70,"chargeback_rate_gte":0.04} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='High-risk MCC cluster 3', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_MCC_03',''High-risk MCC cluster 3'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_MCC_04' AS rule_code, q'[ {"category":"MCC_RISK","mcc_in":["4111","4131","4789"],"merchant_risk_score_gte":70,"chargeback_rate_gte":0.04} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='High-risk MCC cluster 4', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_MCC_04',''High-risk MCC cluster 4'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_MCC_05' AS rule_code, q'[ {"category":"MCC_RISK","mcc_in":["4814","4899","4900"],"merchant_risk_score_gte":70,"chargeback_rate_gte":0.04} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='High-risk MCC cluster 5', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_MCC_05',''High-risk MCC cluster 5'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_MCC_06' AS rule_code, q'[ {"category":"MCC_RISK","mcc_in":["5399","5999","5994"],"merchant_risk_score_gte":70,"chargeback_rate_gte":0.04} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='High-risk MCC cluster 6', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_MCC_06',''High-risk MCC cluster 6'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_REPUTE_01' AS rule_code, q'[ {"category":"BLACKLIST_REPUTATION","ip_blacklisted":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Blacklist/Reputation hit 1', r.severity='CRITICAL', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_REPUTE_01',''Blacklist/Reputation hit 1'','CRITICAL','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_REPUTE_02' AS rule_code, q'[ {"category":"BLACKLIST_REPUTATION","device_blacklisted":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Blacklist/Reputation hit 2', r.severity='CRITICAL', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_REPUTE_02',''Blacklist/Reputation hit 2'','CRITICAL','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_REPUTE_03' AS rule_code, q'[ {"category":"BLACKLIST_REPUTATION","merchant_blacklisted":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Blacklist/Reputation hit 3', r.severity='CRITICAL', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_REPUTE_03',''Blacklist/Reputation hit 3'','CRITICAL','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_REPUTE_04' AS rule_code, q'[ {"category":"BLACKLIST_REPUTATION","phone_blacklisted":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Blacklist/Reputation hit 4', r.severity='CRITICAL', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_REPUTE_04',''Blacklist/Reputation hit 4'','CRITICAL','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_REPUTE_05' AS rule_code, q'[ {"category":"BLACKLIST_REPUTATION","card_blacklisted":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Blacklist/Reputation hit 5', r.severity='CRITICAL', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_REPUTE_05',''Blacklist/Reputation hit 5'','CRITICAL','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_REPUTE_06' AS rule_code, q'[ {"category":"BLACKLIST_REPUTATION","reputation_score_lte":25} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Blacklist/Reputation hit 6', r.severity='CRITICAL', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_REPUTE_06',''Blacklist/Reputation hit 6'','CRITICAL','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_KYC_01' AS rule_code, q'[ {"category":"KYC_LIFECYCLE","kyc_level":"KYC_MIN","account_age_days_lt":7} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='KYC/Lifecycle anomaly 1', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_KYC_01',''KYC/Lifecycle anomaly 1'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_KYC_02' AS rule_code, q'[ {"category":"KYC_LIFECYCLE","kyc_level":"KYC_VIDEO","account_age_days_lt":3} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='KYC/Lifecycle anomaly 2', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_KYC_02',''KYC/Lifecycle anomaly 2'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_KYC_03' AS rule_code, q'[ {"category":"KYC_LIFECYCLE","address_change_days_lt":7,"amount_gte":20000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='KYC/Lifecycle anomaly 3', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_KYC_03',''KYC/Lifecycle anomaly 3'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_KYC_04' AS rule_code, q'[ {"category":"KYC_LIFECYCLE","phone_change_days_lt":3,"amount_gte":10000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='KYC/Lifecycle anomaly 4', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_KYC_04',''KYC/Lifecycle anomaly 4'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_KYC_05' AS rule_code, q'[ {"category":"KYC_LIFECYCLE","email_change_days_lt":3,"amount_gte":10000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='KYC/Lifecycle anomaly 5', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_KYC_05',''KYC/Lifecycle anomaly 5'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_KYC_06' AS rule_code, q'[ {"category":"KYC_LIFECYCLE","kyc_expiring_days_lte":5,"amount_gte":15000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='KYC/Lifecycle anomaly 6', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_KYC_06',''KYC/Lifecycle anomaly 6'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_BENEF_01' AS rule_code, q'[ {"category":"BENEFICIARY_NOVELTY","beneficiary_age_days_lt":1,"amount_gte":15000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Beneficiary novelty 1', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_BENEF_01',''Beneficiary novelty 1'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_BENEF_02' AS rule_code, q'[ {"category":"BENEFICIARY_NOVELTY","beneficiary_age_days_lt":7,"first_time_beneficiary":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Beneficiary novelty 2', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_BENEF_02',''Beneficiary novelty 2'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_BENEF_03' AS rule_code, q'[ {"category":"BENEFICIARY_NOVELTY","beneficiary_txn_count_window":3,"window_minutes":60} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Beneficiary novelty 3', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_BENEF_03',''Beneficiary novelty 3'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_BENEF_04' AS rule_code, q'[ {"category":"BENEFICIARY_NOVELTY","beneficiary_bank_change":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Beneficiary novelty 4', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_BENEF_04',''Beneficiary novelty 4'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_BENEF_05' AS rule_code, q'[ {"category":"BENEFICIARY_NOVELTY","beneficiary_ifsc_mismatch_history":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Beneficiary novelty 5', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_BENEF_05',''Beneficiary novelty 5'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_BENEF_06' AS rule_code, q'[ {"category":"BENEFICIARY_NOVELTY","beneficiary_name_similarity_score_lte":0.4} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Beneficiary novelty 6', r.severity='MEDIUM', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_BENEF_06',''Beneficiary novelty 6'','MEDIUM','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_BEHAV_01' AS rule_code, q'[ {"category":"BEHAVIORAL","amount_zscore_gt":3.0} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Behavioral deviation 1', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_BEHAV_01',''Behavioral deviation 1'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_BEHAV_02' AS rule_code, q'[ {"category":"BEHAVIORAL","hour_zscore_gt":2.5} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Behavioral deviation 2', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_BEHAV_02',''Behavioral deviation 2'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_BEHAV_03' AS rule_code, q'[ {"category":"BEHAVIORAL","channel_mix_change_zscore_gt":2.0} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Behavioral deviation 3', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_BEHAV_03',''Behavioral deviation 3'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_BEHAV_04' AS rule_code, q'[ {"category":"BEHAVIORAL","new_device":true,"amount_gte":20000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Behavioral deviation 4', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_BEHAV_04',''Behavioral deviation 4'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_BEHAV_05' AS rule_code, q'[ {"category":"BEHAVIORAL","new_ip_subnet":true,"amount_gte":10000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Behavioral deviation 5', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_BEHAV_05',''Behavioral deviation 5'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_BEHAV_06' AS rule_code, q'[ {"category":"BEHAVIORAL","login_failed_then_transfer":true,"window_minutes":15} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Behavioral deviation 6', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_BEHAV_06',''Behavioral deviation 6'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_CHBACK_01' AS rule_code, q'[ {"category":"CHARGEBACK","prior_chargeback_count_gt":0,"lookback_days":30} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Chargeback/dispute signal 1', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_CHBACK_01',''Chargeback/dispute signal 1'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_CHBACK_02' AS rule_code, q'[ {"category":"CHARGEBACK","prior_chargeback_count_gt":1,"lookback_days":90} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Chargeback/dispute signal 2', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_CHBACK_02',''Chargeback/dispute signal 2'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_CHBACK_03' AS rule_code, q'[ {"category":"CHARGEBACK","merchant_chargeback_rate_gte":0.05,"lookback_days":90} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Chargeback/dispute signal 3', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_CHBACK_03',''Chargeback/dispute signal 3'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_CHBACK_04' AS rule_code, q'[ {"category":"CHARGEBACK","customer_dispute_ratio_gte":0.03,"lookback_days":180} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Chargeback/dispute signal 4', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_CHBACK_04',''Chargeback/dispute signal 4'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_CHBACK_05' AS rule_code, q'[ {"category":"CHARGEBACK","issuer_dispute_flag":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Chargeback/dispute signal 5', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_CHBACK_05',''Chargeback/dispute signal 5'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_CHBACK_06' AS rule_code, q'[ {"category":"CHARGEBACK","retrieval_request_recent":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Chargeback/dispute signal 6', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_CHBACK_06',''Chargeback/dispute signal 6'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_WALLETFX_01' AS rule_code, q'[ {"category":"WALLET_FOREX_CARD","wallet_topup":true,"amount_gte":50000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Wallet/Forex/Card specific 1', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_WALLETFX_01',''Wallet/Forex/Card specific 1'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_WALLETFX_02' AS rule_code, q'[ {"category":"WALLET_FOREX_CARD","wallet_p2p_chain":true,"hops_gt":3,"window_minutes":120} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Wallet/Forex/Card specific 2', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_WALLETFX_02',''Wallet/Forex/Card specific 2'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_WALLETFX_03' AS rule_code, q'[ {"category":"WALLET_FOREX_CARD","forex_currency_not_in":["INR"],"amount_gte":20000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Wallet/Forex/Card specific 3', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_WALLETFX_03',''Wallet/Forex/Card specific 3'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_WALLETFX_04' AS rule_code, q'[ {"category":"WALLET_FOREX_CARD","card_international":true,"amount_gte":15000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Wallet/Forex/Card specific 4', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_WALLETFX_04',''Wallet/Forex/Card specific 4'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_WALLETFX_05' AS rule_code, q'[ {"category":"WALLET_FOREX_CARD","card_contactless_tap_count_gt":5,"window_minutes":30} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Wallet/Forex/Card specific 5', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_WALLETFX_05',''Wallet/Forex/Card specific 5'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_WALLETFX_06' AS rule_code, q'[ {"category":"WALLET_FOREX_CARD","mcc_forex_remittance":true,"amount_gte":25000} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Wallet/Forex/Card specific 6', r.severity='HIGH', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_WALLETFX_06',''Wallet/Forex/Card specific 6'','HIGH','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_OTPPIN_01' AS rule_code, q'[ {"category":"OTP_PIN","otp_fail_count_gt":3,"window_minutes":15} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='OTP/PIN anomaly 1', r.severity='CRITICAL', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_OTPPIN_01',''OTP/PIN anomaly 1'','CRITICAL','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_OTPPIN_02' AS rule_code, q'[ {"category":"OTP_PIN","pin_retry_count_gt":3,"window_minutes":15} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='OTP/PIN anomaly 2', r.severity='CRITICAL', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_OTPPIN_02',''OTP/PIN anomaly 2'','CRITICAL','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_OTPPIN_03' AS rule_code, q'[ {"category":"OTP_PIN","otp_bypass_detected":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='OTP/PIN anomaly 3', r.severity='CRITICAL', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_OTPPIN_03',''OTP/PIN anomaly 3'','CRITICAL','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_OTPPIN_04' AS rule_code, q'[ {"category":"OTP_PIN","sim_swap_recent_days_lte":3} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='OTP/PIN anomaly 4', r.severity='CRITICAL', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_OTPPIN_04',''OTP/PIN anomaly 4'','CRITICAL','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_OTPPIN_05' AS rule_code, q'[ {"category":"OTP_PIN","device_biometric_disabled":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='OTP/PIN anomaly 5', r.severity='CRITICAL', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_OTPPIN_05',''OTP/PIN anomaly 5'','CRITICAL','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_OTPPIN_06' AS rule_code, q'[ {"category":"OTP_PIN","otp_delivery_to_alt_channel":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='OTP/PIN anomaly 6', r.severity='CRITICAL', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_OTPPIN_06',''OTP/PIN anomaly 6'','CRITICAL','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_GRAPH_01' AS rule_code, q'[ {"category":"GRAPH_RING","shared_device_count_gt":3} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Graph/ring suspicion 1', r.severity='CRITICAL', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_GRAPH_01',''Graph/ring suspicion 1'','CRITICAL','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_GRAPH_02' AS rule_code, q'[ {"category":"GRAPH_RING","shared_ip_count_gt":5} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Graph/ring suspicion 2', r.severity='CRITICAL', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_GRAPH_02',''Graph/ring suspicion 2'','CRITICAL','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_GRAPH_03' AS rule_code, q'[ {"category":"GRAPH_RING","cycle_triads_detected":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Graph/ring suspicion 3', r.severity='CRITICAL', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_GRAPH_03',''Graph/ring suspicion 3'','CRITICAL','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_GRAPH_04' AS rule_code, q'[ {"category":"GRAPH_RING","component_size_gt":20} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Graph/ring suspicion 4', r.severity='CRITICAL', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_GRAPH_04',''Graph/ring suspicion 4'','CRITICAL','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_GRAPH_05' AS rule_code, q'[ {"category":"GRAPH_RING","distance_to_known_fraud_lte":2} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Graph/ring suspicion 5', r.severity='CRITICAL', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_GRAPH_05',''Graph/ring suspicion 5'','CRITICAL','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_GRAPH_06' AS rule_code, q'[ {"category":"GRAPH_RING","merchant_cluster_bridge":true} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Graph/ring suspicion 6', r.severity='CRITICAL', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_GRAPH_06',''Graph/ring suspicion 6'','CRITICAL','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_SCAM_01' AS rule_code, q'[ {"category":"SCAM_SIGNAL","social_engineering":true,"narration_keywords":["refund","OTP","verify"],"scam_pattern":"refund_scam"} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Scam signal 1', r.severity='CRITICAL', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_SCAM_01',''Scam signal 1'','CRITICAL','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_SCAM_02' AS rule_code, q'[ {"category":"SCAM_SIGNAL","social_engineering":true,"narration_keywords":["KYC","suspend","update"],"scam_pattern":"kyc_scam"} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Scam signal 2', r.severity='CRITICAL', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_SCAM_02',''Scam signal 2'','CRITICAL','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_SCAM_03' AS rule_code, q'[ {"category":"SCAM_SIGNAL","social_engineering":true,"narration_keywords":["electricity","bill","disconnect"],"scam_pattern":"utility_scam"} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Scam signal 3', r.severity='CRITICAL', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_SCAM_03',''Scam signal 3'','CRITICAL','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_SCAM_04' AS rule_code, q'[ {"category":"SCAM_SIGNAL","social_engineering":true,"narration_keywords":["customs","parcel","hold"],"scam_pattern":"parcel_scam"} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Scam signal 4', r.severity='CRITICAL', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_SCAM_04',''Scam signal 4'','CRITICAL','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_SCAM_05' AS rule_code, q'[ {"category":"SCAM_SIGNAL","social_engineering":true,"narration_keywords":["job","task","earn"],"scam_pattern":"task_scam"} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Scam signal 5', r.severity='CRITICAL', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_SCAM_05',''Scam signal 5'','CRITICAL','Y',s.def_json);

MERGE INTO fg_rules r
USING (SELECT 'FG_SCAM_06' AS rule_code, q'[ {"category":"SCAM_SIGNAL","social_engineering":true,"narration_keywords":["loan","pre-approve","fee"],"scam_pattern":"loan_fee_scam"} ]' AS def_json FROM dual) s
ON (r.rule_code=s.rule_code)
WHEN MATCHED THEN UPDATE SET r.name='Scam signal 6', r.severity='CRITICAL', r.is_active='Y', r.definition_json=s.def_json
WHEN NOT MATCHED THEN INSERT(rule_code,name,severity,is_active,definition_json)
VALUES('FG_SCAM_06',''Scam signal 6'','CRITICAL','Y',s.def_json);

PROMPT fg_rules_bulk_v2 loaded successfully.
