/**
 *
 * The MIT License (MIT)
 *
 * Copyright (c) 2016 Daniel Popiniuc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 */
/* ----------------------------------------------------------------------------
Auto Increment Health Evaluation for MySQL databases - provides a set of metric to help you evaluate the following:
- filling level and if is little to no reserve left which will be an indicator 
that you will have to take appropriate actions before serious problems dictated by data not being able to be added;
- start gap level and if that is medium or high is an indicator the interval is deviated and you are affected 
by wasted values with potential bigger problems on filling level and its implications (see above);
- continuous level and if that is medium or high is an indicator of you have a gap generating process 
in the source that populates your data with potential bigger problems on filling level 
and its implications (see above);
- end gap level and if that is medium or high is an indicator of you have a gap generating process 
in the source that populates your data that is affecting the end with potential bigger problems on filling level 
and its implications (see above);

Current script has been tested on following MySQL flavours:
- Oracle MySQL 5.5.52 (on 19.09.2016, different script created due to big DDL differences, see "MySQL55" folder)
- Oracle MySQL 5.6.33 (on 16.09.2016)
- Oracle MySQL 5.7.15 (on 14.09.2016)
- Oracle MySQL 8.0.0-dmr (on 15.09.2016)
- MariaDB.org 10.0.27 (on 19.09.2016)
- MariaDB.org 10.1.17 (on 19.09.2016)
- MariaDB.org 10.2.1-alpha (on 19.09.2016)
---------------------------------------------------------------------------- */
CREATE DATABASE /*!32312 IF NOT EXISTS */ `mysql_monitoring_schema` /*!40100 DEFAULT CHARACTER SET utf8 */;
USE `mysql_monitoring_schema`;
/* Creates the MySQL user that will be responsable to run entire logic of Auto Increment Health Evaluation */
DROP USER /*!50708 IF EXISTS */ 'mysql_monitoring'@'127.0.0.1';
FLUSH PRIVILEGES;
CREATE USER 'mysql_monitoring'@'127.0.0.1' /*!50500 IDENTIFIED WITH 'mysql_native_password' AS '*3D0D9CFA148374A19EE4ECE3C15D2C447D70CD55' */ /*!50706 REQUIRE NONE PASSWORD EXPIRE DEFAULT ACCOUNT UNLOCK */;
SET PASSWORD FOR 'mysql_monitoring'@'127.0.0.1' = PASSWORD('ReplaceMeWithStrongerCombination');
GRANT SELECT, EXECUTE ON *.* TO 'mysql_monitoring'@'127.0.0.1';
GRANT INSERT, UPDATE, DELETE ON `mysql_monitoring_schema`.* TO 'mysql_monitoring'@'127.0.0.1';
FLUSH PRIVILEGES;
/* Removes existing structure to ensure latest definition of evaluation structure to be created */
DROP TABLE IF EXISTS `auto_increment_health_evaluation`;
/* Creates latest definition of evaluation structure */
CREATE TABLE IF NOT EXISTS `auto_increment_health_evaluation` (
  `table_schema` varchar(64) NOT NULL,
  `table_name` varchar(64) NOT NULL,
  `column_name` varchar(64) NOT NULL,
  `data_type` varchar(64) NOT NULL,
  `column_type` longtext NOT NULL,
  `auto_increment_next_value` bigint(20) UNSIGNED NOT NULL,
  `min_possible` bigint(21) /*!50706 GENERATED ALWAYS AS ((case when (locate('unsigned',`column_type`) != 0) then 0 else (case when (`data_type` = 'tinyint') then -(128) when (`data_type` = 'smallint') then -(32768) when (`data_type` = 'mediumint') then -(8388608) when (`data_type` = 'int') then -(2147483648) when (`data_type` = 'bigint') then -(9223372036854775808) else NULL end) end)) STORED */ /*M!100201 GENERATED ALWAYS AS ((case when (locate('unsigned',`column_type`) != 0) then 0 else (case when (`data_type` = 'tinyint') then -(128) when (`data_type` = 'smallint') then -(32768) when (`data_type` = 'mediumint') then -(8388608) when (`data_type` = 'int') then -(2147483648) when (`data_type` = 'bigint') then -(9223372036854775808) else NULL end) end)) STORED */, 
  `max_possible` bigint(20) UNSIGNED /*!50706 GENERATED ALWAYS AS ((case when ((`data_type` = 'tinyint') and (locate('unsigned',`column_type`) = 0)) then 127 when ((`data_type` = 'tinyint') and (locate('unsigned',`column_type`) <> 0)) then 255 when ((`data_type` = 'smallint') and (locate('unsigned',`column_type`) = 0)) then 32767 when ((`data_type` = 'smallint') and (locate('unsigned',`column_type`) <> 0)) then 65535 when ((`data_type` = 'mediumint') and (locate('unsigned',`column_type`) = 0)) then 8388607 when ((`data_type` = 'mediumint') and (locate('unsigned',`column_type`) <> 0)) then 16777215 when ((`data_type` = 'int') and (locate('unsigned',`column_type`) = 0)) then 2147483647 when ((`data_type` = 'int') and (locate('unsigned',`column_type`) <> 0)) then 4294967295 when ((`data_type` = 'bigint') and (locate('unsigned',`column_type`) = 0)) then 9223372036854775807 when ((`data_type` = 'bigint') and (locate('unsigned',`column_type`) <> 0)) then 18446744073709551615 else 1 end)) STORED */  /*M!100201 GENERATED ALWAYS AS ((case when ((`data_type` = 'tinyint') and (locate('unsigned',`column_type`) = 0)) then 127 when ((`data_type` = 'tinyint') and (locate('unsigned',`column_type`) <> 0)) then 255 when ((`data_type` = 'smallint') and (locate('unsigned',`column_type`) = 0)) then 32767 when ((`data_type` = 'smallint') and (locate('unsigned',`column_type`) <> 0)) then 65535 when ((`data_type` = 'mediumint') and (locate('unsigned',`column_type`) = 0)) then 8388607 when ((`data_type` = 'mediumint') and (locate('unsigned',`column_type`) <> 0)) then 16777215 when ((`data_type` = 'int') and (locate('unsigned',`column_type`) = 0)) then 2147483647 when ((`data_type` = 'int') and (locate('unsigned',`column_type`) <> 0)) then 4294967295 when ((`data_type` = 'bigint') and (locate('unsigned',`column_type`) = 0)) then 9223372036854775807 when ((`data_type` = 'bigint') and (locate('unsigned',`column_type`) <> 0)) then 18446744073709551615 else 1 end)) STORED */,
  `evaluation_timestamp_added` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `min_evaluated` bigint(21) DEFAULT NULL,
  `max_evaluated` bigint(20) UNSIGNED DEFAULT NULL,
  `record_count_evaluated` bigint(20) UNSIGNED DEFAULT NULL,
  `calculated_filling_value` bigint(20) UNSIGNED /*!50706 GENERATED ALWAYS AS (case when (`record_count_evaluated` is null) then null when (`record_count_evaluated` = 0) then 0 else (`auto_increment_next_value` - ifnull(nullif((`max_evaluated` - `min_evaluated`),0),1)) end) STORED */ /*M!100201 GENERATED ALWAYS AS (case when (`record_count_evaluated` is null) then null when (`record_count_evaluated` = 0) then 0 else (`auto_increment_next_value` - ifnull(nullif((`max_evaluated` - `min_evaluated`),0),1)) end) STORED */,
  `calculated_filling_percentage` decimal(12,9) /*!50706 GENERATED ALWAYS AS (case when (`record_count_evaluated` is null) then null when (`record_count_evaluated` = 0) then 0 else round(((`auto_increment_next_value` * 100) / `max_possible`),9) end) STORED */ /*M!100201 GENERATED ALWAYS AS (case when (`record_count_evaluated` is null) then null when (`record_count_evaluated` = 0) then 0 else (`auto_increment_next_value` - ifnull(nullif((`max_evaluated` - `min_evaluated`),0),1)) end) STORED */,
  `calculated_filling_quality_level` enum('empty','tiny','low','acceptable','medium','high','dangerous','full') /*!50706 GENERATED ALWAYS AS (case when (`calculated_filling_percentage` is not null) then (case when (`record_count_evaluated` = 0) then 'empty' when (`calculated_filling_percentage` between 0 and 9.999999999) then 'tiny' when (`calculated_filling_percentage` between 10 and 39.999999999) then 'low' when (`calculated_filling_percentage` between 40 and 59.999999999) then 'acceptable' when (`calculated_filling_percentage` between 60 and 79.999999999) then 'medium' when (`calculated_filling_percentage` between 80 and 89.999999999) then 'high' when (`calculated_filling_percentage` between 90 and 99.999999999) then 'dangerous' else 'full' end) else null end) STORED */ /*M!100201 GENERATED ALWAYS AS (case when (`calculated_filling_percentage` is not null) then (case when (`record_count_evaluated` = 0) then 'empty' when (`calculated_filling_percentage` between 0 and 9.999999999) then 'tiny' when (`calculated_filling_percentage` between 10 and 39.999999999) then 'low' when (`calculated_filling_percentage` between 40 and 59.999999999) then 'acceptable' when (`calculated_filling_percentage` between 60 and 79.999999999) then 'medium' when (`calculated_filling_percentage` between 80 and 89.999999999) then 'high' when (`calculated_filling_percentage` between 90 and 99.999999999) then 'dangerous' else 'full' end) else null end) STORED */,
  `calculated_start_gap_value` bigint(21) /*!50706 GENERATED ALWAYS AS (case when (`record_count_evaluated` is null) then null when (`record_count_evaluated` = 0) then 0 else ((`min_evaluated` - (case when `min_evaluated` = 0 then 0 else 1 end)) - `min_possible`) end) STORED */ /*M!100201 GENERATED ALWAYS AS (case when (`record_count_evaluated` is null) then null when (`record_count_evaluated` = 0) then 0 else ((`min_evaluated` - (case when `min_evaluated` = 0 then 0 else 1 end)) - `min_possible`) end) STORED */,
  `calculated_start_gap_percentage` decimal(12,9) /*!50706 GENERATED ALWAYS AS ((case when (`record_count_evaluated` is null) then null when (`record_count_evaluated` = 0) then 100 else round(((1 - (`calculated_start_gap_value` / ifnull(nullif((`max_possible` - `min_possible`),0),1)  )) * 100),9) end)) STORED */ /*M!100201 GENERATED ALWAYS AS ((case when (`record_count_evaluated` is null) then null when (`record_count_evaluated` = 0) then 100 else round(((1 - (`calculated_start_gap_value` / ifnull(nullif((`max_possible` - `min_possible`),0),1)  )) * 100),9) end)) STORED */,
  `calculated_start_quality_level` enum('perfect','almost','good','concerning','bad','awful','disaster') /*!50706 GENERATED ALWAYS AS (case when (`calculated_start_gap_percentage` is not null) then (case when (`calculated_start_gap_percentage` = 100.000000000) then 'perfect' when (`calculated_start_gap_percentage` between 90 and 99.999999999) then 'almost' when (`calculated_start_gap_percentage` between 80 and 89.999999999) then 'good'  when (`calculated_start_gap_percentage` between 60 and 79.999999999) then 'concerning' when (`calculated_start_gap_percentage` between 40 and 59.999999999) then 'bad' when (`calculated_start_gap_percentage` between 20 and 39.999999999) then 'awful' else 'disaster' end) else null end) STORED */ /*M!100201 GENERATED ALWAYS AS (case when (`calculated_start_gap_percentage` is not null) then (case when (`calculated_start_gap_percentage` = 100.000000000) then 'perfect' when (`calculated_start_gap_percentage` between 90 and 99.999999999) then 'almost' when (`calculated_start_gap_percentage` between 80 and 89.999999999) then 'good'  when (`calculated_start_gap_percentage` between 60 and 79.999999999) then 'concerning' when (`calculated_start_gap_percentage` between 40 and 59.999999999) then 'bad' when (`calculated_start_gap_percentage` between 20 and 39.999999999) then 'awful' else 'disaster' end) else null end) STORED */,
  `calculated_continuity_gap_value` bigint(20) UNSIGNED /*!50706 GENERATED ALWAYS AS (case when (`record_count_evaluated` is null) then null when (`record_count_evaluated` = 0) then 0 else (((`max_evaluated` - `min_evaluated`) + 1) - `record_count_evaluated`) end) STORED */ /*M!100201 GENERATED ALWAYS AS (case when (`record_count_evaluated` is null) then null when (`record_count_evaluated` = 0) then 0 else (((`max_evaluated` - `min_evaluated`) + 1) - `record_count_evaluated`) end) STORED */,
  `calculated_continuity_gap_percentage` decimal(12,9) /*!50706 GENERATED ALWAYS AS ((case when (`record_count_evaluated` is null) then null when (`record_count_evaluated` = 0) then 100 when ((`max_evaluated` = 0) and (`min_evaluated` = 0)) then 0 else round(((1 - (`calculated_continuity_gap_value` / ifnull(nullif((`max_evaluated` - `min_evaluated`),0),1)  )) * 100),9) end)) STORED */ /*M!100201 GENERATED ALWAYS AS ((case when (`record_count_evaluated` is null) then null when (`record_count_evaluated` = 0) then 100 when ((`max_evaluated` = 0) and (`min_evaluated` = 0)) then 0 else round(((1 - (`calculated_continuity_gap_value` / ifnull(nullif((`max_evaluated` - `min_evaluated`),0),1)  )) * 100),9) end)) STORED */,
  `calculated_continuity_quality_level` enum('perfect','almost','good','concerning','bad','awful','disaster') /*!50706 GENERATED ALWAYS AS (case when (`calculated_continuity_gap_percentage` is not null) then (case when (`calculated_continuity_gap_percentage` = 100.000000000) then 'perfect' when (`calculated_continuity_gap_percentage` between 90 and 99.999999999) then 'almost' when (`calculated_continuity_gap_percentage` between 80 and 89.999999999) then 'good'  when (`calculated_continuity_gap_percentage` between 60 and 79.999999999) then 'concerning' when (`calculated_continuity_gap_percentage` between 40 and 59.999999999) then 'bad' when (`calculated_continuity_gap_percentage` between 20 and 39.999999999) then 'awful' else 'disaster' end) else null end) STORED */ /*M!100201 GENERATED ALWAYS AS (case when (`calculated_continuity_gap_percentage` is not null) then (case when (`calculated_continuity_gap_percentage` = 100.000000000) then 'perfect' when (`calculated_continuity_gap_percentage` between 90 and 99.999999999) then 'almost' when (`calculated_continuity_gap_percentage` between 80 and 89.999999999) then 'good'  when (`calculated_continuity_gap_percentage` between 60 and 79.999999999) then 'concerning' when (`calculated_continuity_gap_percentage` between 40 and 59.999999999) then 'bad' when (`calculated_continuity_gap_percentage` between 20 and 39.999999999) then 'awful' else 'disaster' end) else null end) STORED */,
  `calculated_end_gap_value` bigint(20) UNSIGNED /*!50706 GENERATED ALWAYS AS (case when (`record_count_evaluated` is null) then null when (`record_count_evaluated` = 0) then 0 else ((`auto_increment_next_value` - (case when (`auto_increment_next_value` = `max_evaluated`) then 0 else 1 end)) - `max_evaluated`) end) STORED */ /*M!100201 GENERATED ALWAYS AS (case when (`record_count_evaluated` is null) then null when (`record_count_evaluated` = 0) then 0 else ((`auto_increment_next_value` - (case when (`auto_increment_next_value` = `max_evaluated`) then 0 else 1 end)) - `max_evaluated`) end) STORED */,
  `calculated_end_gap_percentage` decimal(12,9) /*!50706 GENERATED ALWAYS AS ((case when (`record_count_evaluated` is null) then null when (`record_count_evaluated` = 0) then 100 else round(((1 - (`calculated_end_gap_value` / ifnull(nullif((`max_possible` - `min_possible`),0),1)  )) * 100),9) end)) STORED */ /*M!100201 GENERATED ALWAYS AS ((case when (`record_count_evaluated` is null) then null when (`record_count_evaluated` = 0) then 100 else round(((1 - (`calculated_end_gap_value` / ifnull(nullif((`max_possible` - `min_possible`),0),1)  )) * 100),9) end)) STORED */,
  `calculated_end_quality_level` enum('perfect','almost','good','concerning','bad','awful','disaster') /*!50706 GENERATED ALWAYS AS (case when (`calculated_end_gap_percentage` is not null) then (case when (`calculated_end_gap_percentage` = 100.000000000) then 'perfect' when (`calculated_end_gap_percentage` between 90 and 99.999999999) then 'almost' when (`calculated_end_gap_percentage` between 80 and 89.999999999) then 'good'  when (`calculated_end_gap_percentage` between 60 and 79.999999999) then 'concerning' when (`calculated_end_gap_percentage` between 40 and 59.999999999) then 'bad' when (`calculated_end_gap_percentage` between 20 and 39.999999999) then 'awful' else 'disaster' end) else null end) STORED */ /*M!100201 GENERATED ALWAYS AS (case when (`calculated_end_gap_percentage` is not null) then (case when (`calculated_end_gap_percentage` = 100.000000000) then 'perfect' when (`calculated_end_gap_percentage` between 90 and 99.999999999) then 'almost' when (`calculated_end_gap_percentage` between 80 and 89.999999999) then 'good'  when (`calculated_end_gap_percentage` between 60 and 79.999999999) then 'concerning' when (`calculated_end_gap_percentage` between 40 and 59.999999999) then 'bad' when (`calculated_end_gap_percentage` between 20 and 39.999999999) then 'awful' else 'disaster' end) else null end) STORED */,
  `evaluation_timestamp_completed` datetime(6) DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`table_schema`,`table_name`,`column_name`),
  KEY `calculated_filling_percentage` (`calculated_filling_percentage`),
  KEY `calculated_filling_quality_level` (`calculated_filling_quality_level`),
  KEY `calculated_start_gap_percentage` (`calculated_start_gap_percentage`),
  KEY `calculated_start_quality_level` (`calculated_start_quality_level`),
  KEY `calculated_continuity_gap_percentage` (`calculated_continuity_gap_percentage`),
  KEY `calculated_continuity_quality_level` (`calculated_continuity_quality_level`),
  KEY `calculated_end_gap_percentage` (`calculated_end_gap_percentage`),
  KEY `calculated_end_quality_level` (`calculated_end_quality_level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;
/* Entire logic of Auto Increment Health Evaluation */
DELIMITER //
DROP PROCEDURE IF EXISTS `pr_Auto_Increment_Evaluation_Min`//
CREATE DEFINER=`mysql_monitoring`@`127.0.0.1` PROCEDURE `pr_Auto_Increment_Evaluation_Min`(IN `p_TableSchema` VARCHAR(64), IN `p_TableName` VARCHAR(64), IN `p_ColumnName` VARCHAR(64), OUT `p_MinAutoIncrement` BIGINT(21))
    NOT DETERMINISTIC 
    READS SQL DATA 
    SQL SECURITY DEFINER 
    COMMENT 'AI evaluation for minimum value'
BEGIN
    SET @dynamic_sql_min = CONCAT("SET @v_Min_Auto_Increment = (SELECT MIN(`", p_ColumnName, "`) FROM `", p_TableSchema, "`.`", p_TableName, "`);");
    PREPARE complete_min_sql FROM @dynamic_sql_min;
    EXECUTE complete_min_sql;
    SELECT IFNULL(@v_Min_Auto_Increment, 0) INTO p_MinAutoIncrement;
    DEALLOCATE PREPARE complete_min_sql;
END//
DROP PROCEDURE IF EXISTS `pr_Auto_Increment_Evaluation_Max`//
CREATE DEFINER=`mysql_monitoring`@`127.0.0.1` PROCEDURE `pr_Auto_Increment_Evaluation_Max`(IN `p_TableSchema` VARCHAR(64), IN `p_TableName` VARCHAR(64), IN `p_ColumnName` VARCHAR(64), OUT `p_MaxAutoIncrement` BIGINT(20) UNSIGNED)
    NOT DETERMINISTIC 
    READS SQL DATA 
    SQL SECURITY DEFINER 
    COMMENT 'AI evaluation for maximum value' 
BEGIN
    SET @dynamic_sql = CONCAT("SET @v_Max_Auto_Increment = (SELECT MAX(`", p_ColumnName, "`) FROM `", p_TableSchema, "`.`", p_TableName, "`);");
    PREPARE complete_max_sql FROM @dynamic_sql;
    EXECUTE complete_max_sql;
    SELECT IFNULL(@v_Max_Auto_Increment, 0) INTO p_MaxAutoIncrement;
    DEALLOCATE PREPARE complete_max_sql;
END//
DROP PROCEDURE IF EXISTS `pr_Auto_Increment_Evaluation_Records`//
CREATE DEFINER=`mysql_monitoring`@`127.0.0.1` PROCEDURE `pr_Auto_Increment_Evaluation_Records`(IN `p_TableSchema` VARCHAR(64), IN `p_TableName` VARCHAR(64), IN `p_ColumnName` VARCHAR(64), OUT `p_Record_Count` BIGINT(20) UNSIGNED)
    NOT DETERMINISTIC 
    READS SQL DATA 
    SQL SECURITY DEFINER 
    COMMENT 'Record count evaluation of tables with AI column' 
BEGIN
    SET @dynamic_sql_records = CONCAT("SET @v_Record_Count = (SELECT COUNT(*) FROM `", p_TableSchema, "`.`", p_TableName, "`);");
    PREPARE complete_records_sql FROM @dynamic_sql_records;
    EXECUTE complete_records_sql;
    SELECT IFNULL(@v_Record_Count, 0) INTO p_Record_Count;
    DEALLOCATE PREPARE complete_records_sql;
END//
DROP FUNCTION IF EXISTS `fn_MySQLversionNumeric`//
CREATE DEFINER=`mysql_monitoring`@`127.0.0.1` FUNCTION `fn_MySQLversionNumeric`() RETURNS MEDIUMINT(8) UNSIGNED
    DETERMINISTIC 
    CONTAINS SQL 
    SQL SECURITY DEFINER 
    COMMENT 'Returns current MySQL version as a number w/ 5 digits'
BEGIN
    DECLARE v_setMySQLversion VARCHAR(8);
    DECLARE v_MySQLversion MEDIUMINT(8) UNSIGNED;
    SELECT SUBSTRING_INDEX(VERSION(), '-', 1) INTO v_setMySQLversion;
    SELECT SUBSTRING_INDEX(v_setMySQLversion, '.', 1) into @v_MySQLversionMajor;
    SELECT CAST(REPLACE(SUBSTRING_INDEX(v_setMySQLversion, '.', 2), CONCAT(@v_MySQLversionMajor, '.'), '') AS UNSIGNED) into @v_MySQLversionMinor;
    SELECT CAST(SUBSTRING_INDEX(v_setMySQLversion, '.', -1) AS UNSIGNED) into @v_MySQLversionThird;
    SELECT CAST(CONCAT(@v_MySQLversionMajor, (CASE WHEN (@v_MySQLversionMinor < 10) THEN "0" ELSE "" END), @v_MySQLversionMinor, (CASE WHEN (@v_MySQLversionThird < 10) THEN "0" ELSE "" END), @v_MySQLversionThird) AS UNSIGNED) INTO v_MySQLversion;
    RETURN v_MySQLversion;
END//
DROP FUNCTION IF EXISTS `fn_MySQLforkDistribution`//
CREATE DEFINER=`mysql_monitoring`@`127.0.0.1` FUNCTION `fn_MySQLforkDistribution`() RETURNS VARCHAR(15)
    DETERMINISTIC 
    CONTAINS SQL 
    SQL SECURITY DEFINER 
    COMMENT 'Returns MySQL or mariadb.org'
BEGIN
    DECLARE v_MySQLforkDistribution VARCHAR(15);
    SELECT SUBSTRING_INDEX(@@global.version_comment, ' ', 1) INTO v_MySQLforkDistribution;
    RETURN v_MySQLforkDistribution;
END//
DROP PROCEDURE IF EXISTS `pr_Auto_Increment_Evaluation_1_Capture`//
CREATE DEFINER=`mysql_monitoring`@`127.0.0.1` PROCEDURE `pr_Auto_Increment_Evaluation_1_Capture`()
    NOT DETERMINISTIC 
    MODIFIES SQL DATA 
    SQL SECURITY DEFINER 
    COMMENT 'Adds AI columns from all schemas' 
BEGIN
    /* Ensure we're starting in an empty space */
    DELETE FROM `auto_increment_health_evaluation`;
    /* Capture all AI column from all databases on current MySQL server */
    INSERT INTO `auto_increment_health_evaluation` (`table_schema`, `table_name`, `column_name`, `data_type`, `column_type`, `auto_increment_next_value`)
        SELECT 
            `C`.`TABLE_SCHEMA`, 
            `C`.`TABLE_NAME`, 
            `C`.`COLUMN_NAME`, 
            `C`.`DATA_TYPE`, 
            `C`.`COLUMN_TYPE`,
            `T`.`AUTO_INCREMENT`
        FROM `information_schema`.`COLUMNS` `C`
        INNER JOIN `information_schema`.`TABLES` `T` ON ((`C`.`TABLE_SCHEMA` = `T`.`TABLE_SCHEMA`) AND (`C`.`TABLE_NAME` = `T`.`TABLE_NAME`))
        WHERE (`C`.`EXTRA` LIKE 'auto_increment')
        GROUP BY `C`.`TABLE_SCHEMA`, `C`.`TABLE_NAME`, `C`.`COLUMN_NAME`
        ORDER BY `C`.`TABLE_SCHEMA`, `C`.`TABLE_NAME`, `C`.`COLUMN_NAME`;
    /* Calculates few columns for MySQL older than 5.7.6 which does not support generated columns */
    IF ((`fn_MySQLforkDistribution`() = 'MySQL') AND (`fn_MySQLversionNumeric`() < 50706)) OR ((`fn_MySQLforkDistribution`() = 'mariadb.org') AND (`fn_MySQLversionNumeric`() < 100201)) THEN
        UPDATE `auto_increment_health_evaluation` SET
            `min_possible` = (
                CASE
                    WHEN (LOCATE('unsigned', `column_type`) != 0) THEN 0
                    WHEN (LOCATE('unsigned', `column_type`) = 0) THEN (CASE
                        WHEN (`data_type` = 'tinyint') THEN -(128) 
                        WHEN (`data_type` = 'smallint') THEN -(32768) 
                        WHEN (`data_type` = 'mediumint') THEN -(8388608) 
                        WHEN (`data_type` = 'int') THEN -(2147483648) 
                        WHEN (`data_type` = 'bigint') THEN -(9223372036854775808) 
                        ELSE NULL
                    END)
            END), 
            `max_possible` = (
                CASE 
                    WHEN ((`data_type` = 'tinyint') AND (LOCATE('unsigned', `column_type`) = 0)) THEN 127
                    WHEN ((`data_type` = 'tinyint') AND (LOCATE('unsigned', `column_type`) != 0)) THEN 255
                    WHEN ((`data_type` = 'smallint') AND (LOCATE('unsigned', `column_type`) = 0)) THEN 32767
                    WHEN ((`data_type` = 'smallint') AND (LOCATE('unsigned', `column_type`) != 0)) THEN 65535
                    WHEN ((`data_type` = 'mediumint') AND (LOCATE('unsigned', `column_type`) = 0)) THEN 8388607
                    WHEN ((`data_type` = 'mediumint') AND (LOCATE('unsigned', `column_type`) != 0)) THEN 16777215
                    WHEN ((`data_type` = 'int') AND (LOCATE('unsigned', `column_type`) = 0)) THEN 2147483647
                    WHEN ((`data_type` = 'int') AND (LOCATE('unsigned', `column_type`) != 0)) THEN 4294967295
                    WHEN ((`data_type` = 'bigint') AND (LOCATE('unsigned', `column_type`) = 0)) THEN 9223372036854775807
                    WHEN ((`data_type` = 'bigint') AND (LOCATE('unsigned', `column_type`) != 0)) THEN 18446744073709551615
                    ELSE 1
            END);
    END IF;
END//
DROP PROCEDURE IF EXISTS `pr_Auto_Increment_Evaluation_2_Health`//
CREATE DEFINER=`mysql_monitoring`@`127.0.0.1` PROCEDURE `pr_Auto_Increment_Evaluation_2_Health`()
    NOT DETERMINISTIC 
    MODIFIES SQL DATA 
    SQL SECURITY DEFINER 
    COMMENT 'AI evaluation'
BEGIN
    DECLARE v_done INT DEFAULT 0;
    DECLARE v_table_schema VARCHAR(64);
    DECLARE v_table_name VARCHAR(64);
    DECLARE v_column_name VARCHAR(64);
    DECLARE v_Min_Evaluated BIGINT(21);
    DECLARE v_Max_Evaluated BIGINT(20) UNSIGNED;
    DECLARE v_Record_Count_Evaluated BIGINT(20) UNSIGNED;
    /* Reads existing AI columns to later evaluate 1 by 1 */
    DECLARE info_cursor CURSOR FOR SELECT `table_schema`, `table_name`, `column_name` FROM `auto_increment_health_evaluation`;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
    /* Evaluate current situation for every single relevant column and table */
    SET @dynamic_sql = "UPDATE `auto_increment_health_evaluation` SET `min_evaluated` = ?, `max_evaluated` = ?, `record_count_evaluated` = ? WHERE (`table_schema` = ?) AND (`table_name` = ?) AND (`column_name` = ?);";
    PREPARE complete_sql FROM @dynamic_sql;
    OPEN info_cursor;
    REPEAT
        FETCH info_cursor INTO v_table_schema, v_table_name, v_column_name;
        IF NOT v_done THEN
            SET @table_schema = v_table_schema;
            SET @table_name = v_table_name;
            SET @column_name = v_column_name;
            CALL `pr_Auto_Increment_Evaluation_Min`(v_table_schema, v_table_name, v_column_name, v_Min_Evaluated);
            SET @Min_Evaluated = v_Min_Evaluated;
            CALL `pr_Auto_Increment_Evaluation_Max`(v_table_schema, v_table_name, v_column_name, v_Max_Evaluated);
            SET @Max_Evaluated = v_Max_Evaluated;
            CALL `pr_Auto_Increment_Evaluation_Records`(v_table_schema, v_table_name, v_column_name, v_Record_Count_Evaluated);
            SET @Record_Count_Evaluated = v_Record_Count_Evaluated;
            EXECUTE complete_sql USING @Min_Evaluated, @Max_Evaluated, @Record_Count_Evaluated, @table_schema, @table_name, @column_name;
        END IF;
    UNTIL v_done END REPEAT;
    CLOSE info_cursor;
    DEALLOCATE PREPARE complete_sql;
END//
DROP PROCEDURE IF EXISTS `pr_Auto_Increment_Evaluation_3_Calculate`//
CREATE DEFINER=`mysql_monitoring`@`127.0.0.1` PROCEDURE `pr_Auto_Increment_Evaluation_3_Calculate`()
    NOT DETERMINISTIC 
    MODIFIES SQL DATA 
    SQL SECURITY DEFINER 
    COMMENT 'Calculates few columns for MySQL older than 5.7.6' 
BEGIN
    IF ((`fn_MySQLforkDistribution`() = 'MySQL') AND (`fn_MySQLversionNumeric`() < 50706)) OR ((`fn_MySQLforkDistribution`() = 'mariadb.org') AND (`fn_MySQLversionNumeric`() < 100201)) THEN
        UPDATE `auto_increment_health_evaluation` SET 
            `calculated_filling_value` = (
                CASE 
                    WHEN (`record_count_evaluated` IS NULL) THEN NULL 
                    WHEN (`record_count_evaluated` = 0) THEN 0 
                    ELSE (`auto_increment_next_value` - IFNULL(NULLIF((`max_evaluated` - `min_evaluated`),0),1))
            END),
            `calculated_start_gap_value` = (
                CASE 
                    WHEN (`record_count_evaluated` IS NULL) THEN NULL 
                    WHEN (`record_count_evaluated` = 0) THEN 0 
                    ELSE ((`min_evaluated` - (CASE WHEN `min_evaluated` = 0 THEN 0 ELSE 1 END)) - `min_possible`) 
            END),
            `calculated_continuity_gap_value` = (
                CASE 
                    WHEN (`record_count_evaluated` is null) THEN null 
                    WHEN (`record_count_evaluated` = 0) THEN 0 
                    ELSE (((`max_evaluated` - `min_evaluated`) + 1) - `record_count_evaluated`)
            END),
            `calculated_end_gap_value` = (
                CASE 
                    WHEN (`record_count_evaluated` is null) THEN null 
                    WHEN (`record_count_evaluated` = 0) THEN 0 
                    ELSE ((`auto_increment_next_value` - (CASE WHEN (`auto_increment_next_value` = `max_evaluated`) THEN 0 ELSE 1 END)) - `max_evaluated`)
            END);
        UPDATE `auto_increment_health_evaluation` SET 
            `calculated_filling_percentage` = (
                CASE 
                    WHEN (`record_count_evaluated` IS NULL) THEN NULL 
                    WHEN (`record_count_evaluated` = 0) THEN 0 
                    ELSE ROUND(((`auto_increment_next_value` * 100) / `max_possible`),9)
            END),
            `calculated_start_gap_percentage` = (
                CASE 
                    WHEN (`record_count_evaluated` IS NULL) THEN null 
                    WHEN (`record_count_evaluated` = 0) THEN 100 
                    ELSE ROUND(((1 - (`calculated_start_gap_value` / IFNULL(NULLIF((`max_possible` - `min_possible`),0),1)  )) * 100),9)
            END),
            `calculated_continuity_gap_percentage` = (
                CASE 
                    WHEN (`record_count_evaluated` IS NULL) THEN null 
                    WHEN (`record_count_evaluated` = 0) THEN 100 
                    WHEN ((`max_evaluated` = 0) and (`min_evaluated` = 0)) THEN 0 
                    ELSE ROUND(((1 - (`calculated_continuity_gap_value` / IFNULL(NULLIF((`max_evaluated` - `min_evaluated`),0),1)  )) * 100),9)
            END),
            `calculated_end_gap_percentage` = (
                CASE 
                    WHEN (`record_count_evaluated` IS NULL) THEN null 
                    WHEN (`record_count_evaluated` = 0) THEN 100 
                    ELSE ROUND(((1 - (`calculated_end_gap_value` / IFNULL(NULLIF((`max_possible` - `min_possible`),0),1)  )) * 100),9)
            END);
        UPDATE `auto_increment_health_evaluation` SET 
            `calculated_filling_quality_level` = (
                CASE 
                    WHEN (`calculated_filling_percentage` IS NOT NULL) THEN (
                        CASE 
                            WHEN (`record_count_evaluated` = 0) THEN 'empty' 
                            WHEN (`calculated_filling_percentage` BETWEEN 0 AND 9.999999999) THEN 'tiny' 
                            WHEN (`calculated_filling_percentage` BETWEEN 10 AND 39.999999999) THEN 'low' 
                            WHEN (`calculated_filling_percentage` BETWEEN 40 AND 59.999999999) THEN 'acceptable' 
                            WHEN (`calculated_filling_percentage` BETWEEN 60 AND 79.999999999) THEN 'medium' 
                            WHEN (`calculated_filling_percentage` BETWEEN 80 AND 89.999999999) THEN 'high' 
                            WHEN (`calculated_filling_percentage` BETWEEN 90 AND 99.999999999) THEN 'dangerous' 
                            ELSE 'full' 
                        END) 
                    ELSE NULL
            END),
            `calculated_start_quality_level` = (
                CASE 
                    WHEN (`calculated_start_gap_percentage` IS NOT NULL) THEN (
                        CASE 
                            WHEN (`calculated_start_gap_percentage` = 100.000000000) THEN 'perfect' 
                            WHEN (`calculated_start_gap_percentage` BETWEEN 90 AND 99.999999999) THEN 'almost' 
                            WHEN (`calculated_start_gap_percentage` BETWEEN 80 AND 89.999999999) THEN 'good'  
                            WHEN (`calculated_start_gap_percentage` BETWEEN 60 AND 79.999999999) THEN 'concerning' 
                            WHEN (`calculated_start_gap_percentage` BETWEEN 40 AND 59.999999999) THEN 'bad' 
                            WHEN (`calculated_start_gap_percentage` BETWEEN 20 AND 39.999999999) THEN 'awful' 
                            ELSE 'disaster' 
                        END) 
                    ELSE NULL
            END),
            `calculated_continuity_quality_level` = (
                CASE 
                    WHEN (`calculated_continuity_gap_percentage` IS NOT NULL) THEN (
                        CASE 
                            WHEN (`calculated_continuity_gap_percentage` = 100.000000000) THEN 'perfect' 
                            WHEN (`calculated_continuity_gap_percentage` BETWEEN 90 AND 99.999999999) THEN 'almost' 
                            WHEN (`calculated_continuity_gap_percentage` BETWEEN 80 AND 89.999999999) THEN 'good'  
                            WHEN (`calculated_continuity_gap_percentage` BETWEEN 60 AND 79.999999999) THEN 'concerning' 
                            WHEN (`calculated_continuity_gap_percentage` BETWEEN 40 AND 59.999999999) THEN 'bad' 
                            WHEN (`calculated_continuity_gap_percentage` BETWEEN 20 AND 39.999999999) THEN 'awful' 
                            ELSE 'disaster' 
                        END) 
                    ELSE NULL
            END),
            `calculated_end_quality_level` = (
                CASE 
                    WHEN (`calculated_end_gap_percentage` IS NOT NULL) THEN (
                        CASE 
                            WHEN (`calculated_end_gap_percentage` = 100.000000000) THEN 'perfect' 
                            WHEN (`calculated_end_gap_percentage` BETWEEN 90 AND 99.999999999) THEN 'almost' 
                            WHEN (`calculated_end_gap_percentage` BETWEEN 80 AND 89.999999999) THEN 'good'  
                            WHEN (`calculated_end_gap_percentage` BETWEEN 60 AND 79.999999999) THEN 'concerning' 
                            WHEN (`calculated_end_gap_percentage` BETWEEN 40 AND 59.999999999) THEN 'bad' 
                            WHEN (`calculated_end_gap_percentage` BETWEEN 20 AND 39.999999999) THEN 'awful' 
                            ELSE 'disaster' 
                        END) 
                    ELSE NULL
            END);
    END IF;
END//
/*!50100 DROP EVENT IF EXISTS `event_AutoIncrementHealthEvaluation`// */
/*!50100 CREATE DEFINER=`mysql_monitoring`@`127.0.0.1` EVENT `event_AutoIncrementHealthEvaluation` 
ON SCHEDULE EVERY 1 DAY 
STARTS '2016-09-15 00:10:00' 
ON COMPLETION PRESERVE 
ENABLE DO 
BEGIN
    CALL `pr_Auto_Increment_Evaluation_1_Capture`();
    CALL `pr_Auto_Increment_Evaluation_2_Health`();
    CALL `pr_Auto_Increment_Evaluation_3_Calculate`();
END// */
DELIMITER ;
/* Query to help you assess how much time running the Auto Increment Health Evaluation takes */
/*
SELECT
    TIMEDIFF(MAX(`evaluation_timestamp_added`), MIN(`evaluation_timestamp_added`)) AS Added_Duration,
    TIMEDIFF(MIN(`evaluation_timestamp_completed`), MAX(`evaluation_timestamp_added`)) AS GapBetweenAddAndCompleted_Duration,
    TIMEDIFF(MAX(`evaluation_timestamp_completed`), MIN(`evaluation_timestamp_completed`)) AS Completed_Duration,
    TIMEDIFF(MAX(`evaluation_timestamp_completed`), MIN(`evaluation_timestamp_added`)) AS Entire_Duration
FROM
    `auto_increment_health_evaluation`;
*/
/* Query to resent the AI value */
/* 
    ALTER TABLE `table_name_targeted_for_AI_reset` AUTO_INCREMENT = 1; 
*/
