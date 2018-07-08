/**
 *
 * The MIT License (MIT)
 *
 * Copyright (c) 2017 - 2018 Daniel Popiniuc
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
USE `mysql_monitoring_schema`;
GRANT ALTER, UPDATE ON *.* TO 'mysql_monitoring_user'@'127.0.0.1';
DROP TABLE IF EXISTS `auto_increment_gap_elimination_content`;
CREATE TABLE `auto_increment_gap_elimination_content` (
  `table_schema` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `table_name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `column_name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `content_tinyint_signed` tinyint(4) NULL,
  `content_tinyint_unsigned` tinyint(3) UNSIGNED NULL,
  `content_smallint_signed` smallint(6) NULL,
  `content_smallint_unsigned` smallint(5) UNSIGNED NULL,
  `content_mediumint_signed` mediumint(9) NULL,
  `content_mediumint_unsigned` mediumint(8) UNSIGNED NULL,
  `content_int_signed` int(11) NULL,
  `content_int_unsigned` int(10) UNSIGNED NULL,
  `content_bigint_signed` int(21) NULL,
  `content_bigint_unsigned` int(20) UNSIGNED NULL,
  KEY `K_aigec_SchemaTableColumn` (`table_schema`,`table_name`,`column_name`),
  KEY `K_aigec_ContentTinyintSigned` (`content_tinyint_signed`),
  KEY `K_aigec_ContentTinyintUnsigned` (`content_tinyint_unsigned`),
  KEY `K_aigec_ContentSmallintSigned` (`content_smallint_signed`),
  KEY `K_aigec_ContentSmallintUnsigned` (`content_smallint_unsigned`),
  KEY `K_aigec_ContentMediumintSigned` (`content_mediumint_signed`),
  KEY `K_aigec_ContentMediumintUnsigned` (`content_mediumint_unsigned`),
  KEY `K_aigec_ContentIntSigned` (`content_int_signed`),
  KEY `K_aigec_ContentIntUnsigned` (`content_int_unsigned`),
  KEY `K_aigec_ContentBigintSigned` (`content_bigint_signed`),
  KEY `K_aigec_ContentBigintUnsigned` (`content_bigint_unsigned`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=COMPACT;
DROP TABLE IF EXISTS `auto_increment_gap_elimination_log`;
CREATE TABLE `auto_increment_gap_elimination_log` (
  `table_schema` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `table_name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `column_name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `gap_elimination_timestamp_added` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `parameters_before` JSON NOT NULL,
  `parameters_after` JSON NULL,
  `gap_elimination_timestamp_completed` datetime(6) DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(6),
  KEY `K_aigel_SchemaTableColumn` (`table_schema`,`table_name`,`column_name`, `gap_elimination_timestamp_added`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=COMPACT;
/* Support for Duration in-place calculate (requires MySQL 5.6.7+ or MariaDB 5.2.3+) */
ALTER TABLE `auto_increment_gap_elimination_log` ADD COLUMN `gap_eliminiation_duration` TIME(6) GENERATED ALWAYS AS (CASE WHEN `gap_elimination_timestamp_completed` IS NULL THEN NULL ELSE  TIMEDIFF(`gap_elimination_timestamp_completed`, `gap_elimination_timestamp_added`) END) STORED AFTER `gap_elimination_timestamp_completed`;
DELIMITER //
DROP PROCEDURE IF EXISTS `pr_Eliminate_Auto_Increment_Gap_4_Tinyint_Signed`//
CREATE DEFINER=`mysql_monitoring_user`@`127.0.0.1` PROCEDURE `pr_Eliminate_Auto_Increment_Gap_4_Tinyint_Signed`(IN p_InScope_Database VARCHAR(200), IN p_InScope_Table VARCHAR(64), IN p_InScope_Column VARCHAR(64))
    MODIFIES SQL DATA
    COMMENT 'Eliminates the gaps for AC fields of type Tinyint Signed'
BEGIN
	DECLARE v_ContentTinyintSigned_Previous tinyint(4) DEFAULT 0;
	DECLARE v_ContentTinyintSigned_Current tinyint(4);
	DECLARE v_done INT DEFAULT 0;
	DECLARE info_cursor CURSOR FOR SELECT `content_tinyint_signed` FROM `auto_increment_gap_elimination_content` WHERE ( `table_schema` LIKE p_InScope_Database) AND (`table_name` LIKE p_InScope_Table) AND (`column_name` LIKE p_InScope_Column) ORDER BY `content_tinyint_signed`;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
    SET @dynamic_sql = CONCAT("UPDATE `", p_InScope_Database, "`.`", p_InScope_Table, "` SET `", p_InScope_Column, "` = ? WHERE `", p_InScope_Column, "` = ?;");
    PREPARE complete_sql FROM @dynamic_sql;
    OPEN info_cursor;
    REPEAT
        FETCH info_cursor INTO v_ContentTinyintSigned_Current;
        IF NOT v_done THEN
            SET @ContentTinyintSignedOld = v_ContentTinyintSigned_Current;
            SET @ContentTinyintSignedNew = (v_ContentTinyintSigned_Previous + 1);
            IF (@ContentTinyintSignedOld = @ContentTinyintSignedNew) THEN
                SET v_ContentTinyintSigned_Previous = v_ContentTinyintSigned_Current;
            ELSE
                EXECUTE complete_sql USING @ContentTinyintSignedNew, @ContentTinyintSignedOld;
                SET v_ContentTinyintSigned_Previous = @ContentTinyintSignedNew;
            END IF;
        END IF;
    UNTIL v_done END REPEAT;
    CLOSE info_cursor;
    DEALLOCATE PREPARE complete_sql;
END//
DROP PROCEDURE IF EXISTS `pr_Eliminate_Auto_Increment_Gap_4_Tinyint_Unsigned`//
CREATE DEFINER=`mysql_monitoring_user`@`127.0.0.1` PROCEDURE `pr_Eliminate_Auto_Increment_Gap_4_Tinyint_Unsigned`(IN p_InScope_Database VARCHAR(200), IN p_InScope_Table VARCHAR(64), IN p_InScope_Column VARCHAR(64))
    MODIFIES SQL DATA
    COMMENT 'Eliminates the gaps for AC fields of type Tinyint Signed'
BEGIN
	DECLARE v_ContentTinyintUnsigned_Previous tinyint(3) UNSIGNED DEFAULT 0;
	DECLARE v_ContentTinyintUnsigned_Current tinyint(3) UNSIGNED;
	DECLARE v_done INT DEFAULT 0;
	DECLARE info_cursor CURSOR FOR SELECT `content_tinyint_unsigned` FROM `auto_increment_gap_elimination_content` WHERE (`table_schema` LIKE p_InScope_Database) AND (`table_name` LIKE p_InScope_Table) AND (`column_name` LIKE p_InScope_Column) ORDER BY `content_tinyint_unsigned`;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
    SET @dynamic_sql = CONCAT("UPDATE `", p_InScope_Database, "`.`", p_InScope_Table, "` SET `", p_InScope_Column, "` = ? WHERE `", p_InScope_Column, "` = ?;");
    PREPARE complete_sql FROM @dynamic_sql;
    OPEN info_cursor;
    REPEAT
        FETCH info_cursor INTO v_ContentTinyintUnsigned_Current;
        IF NOT v_done THEN
            SET @ContentTinyintUnsignedOld = v_ContentTinyintUnsigned_Current;
            SET @ContentTinyintUnsignedNew = (v_ContentTinyintUnsigned_Previous + 1);
            IF (@ContentTinyintUnsignedOld = @ContentTinyintUnsignedNew) THEN
                SET v_ContentTinyintUnsigned_Previous = v_ContentTinyintUnsigned_Current;
            ELSE
                EXECUTE complete_sql USING @ContentTinyintUnsignedNew, @ContentTinyintUnsignedOld;
                SET v_ContentTinyintUnsigned_Previous = @ContentTinyintUnsignedNew;
            END IF;
        END IF;
    UNTIL v_done END REPEAT;
    CLOSE info_cursor;
    DEALLOCATE PREPARE complete_sql;
END//
DROP PROCEDURE IF EXISTS `pr_Eliminate_Auto_Increment_Gap_4_Smallint_Signed`//
CREATE DEFINER=`mysql_monitoring_user`@`127.0.0.1` PROCEDURE `pr_Eliminate_Auto_Increment_Gap_4_Smallint_Signed`(IN p_InScope_Database VARCHAR(200), IN p_InScope_Table VARCHAR(64), IN p_InScope_Column VARCHAR(64))
    MODIFIES SQL DATA
    COMMENT 'Eliminates the gaps for AC fields of type Smallint Signed'
BEGIN
	DECLARE v_ContentSmallintSigned_Previous smallint(6) DEFAULT 0;
	DECLARE v_ContentSmallintSigned_Current smallint(6);
	DECLARE v_done INT DEFAULT 0;
	DECLARE info_cursor CURSOR FOR SELECT `content_smallint_signed` FROM `auto_increment_gap_elimination_content` WHERE ( `table_schema` LIKE p_InScope_Database) AND (`table_name` LIKE p_InScope_Table) AND (`column_name` LIKE p_InScope_Column) ORDER BY `content_smallint_signed`;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
    SET @dynamic_sql = CONCAT("UPDATE `", p_InScope_Database, "`.`", p_InScope_Table, "` SET `", p_InScope_Column, "` = ? WHERE `", p_InScope_Column, "` = ?;");
    PREPARE complete_sql FROM @dynamic_sql;
    OPEN info_cursor;
    REPEAT
        FETCH info_cursor INTO v_ContentSmallintSigned_Current;
        IF NOT v_done THEN
            SET @ContentSmallintSignedOld = v_ContentSmallintSigned_Current;
            SET @ContentSmallintSignedNew = (v_ContentSmallintSigned_Previous + 1);
            IF (@ContentSmallintSignedOld = @ContentSmallintSignedNew) THEN
                SET v_ContentSmallintSigned_Previous = v_ContentSmallintSigned_Current;
            ELSE
                EXECUTE complete_sql USING @ContentSmallintSignedNew, @ContentSmallintSignedOld;
                SET v_ContentSmallintSigned_Previous = @ContentSmallintSignedNew;
            END IF;
        END IF;
    UNTIL v_done END REPEAT;
    CLOSE info_cursor;
    DEALLOCATE PREPARE complete_sql;
END//
DROP PROCEDURE IF EXISTS `pr_Eliminate_Auto_Increment_Gap_4_Smallint_Unsigned`//
CREATE DEFINER=`mysql_monitoring_user`@`127.0.0.1` PROCEDURE `pr_Eliminate_Auto_Increment_Gap_4_Smallint_Unsigned`(IN p_InScope_Database VARCHAR(200), IN p_InScope_Table VARCHAR(64), IN p_InScope_Column VARCHAR(64))
    MODIFIES SQL DATA
    COMMENT 'Eliminates the gaps for AC fields of type Smallint Signed'
BEGIN
	DECLARE v_ContentSmallintUnsigned_Previous smallint(5) UNSIGNED DEFAULT 0;
	DECLARE v_ContentSmallintUnsigned_Current smallint(5) UNSIGNED;
	DECLARE v_done INT DEFAULT 0;
	DECLARE info_cursor CURSOR FOR SELECT `content_smallint_unsigned` FROM `auto_increment_gap_elimination_content` WHERE (`table_schema` LIKE p_InScope_Database) AND (`table_name` LIKE p_InScope_Table) AND (`column_name` LIKE p_InScope_Column) ORDER BY `content_smallint_unsigned`;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
    SET @dynamic_sql = CONCAT("UPDATE `", p_InScope_Database, "`.`", p_InScope_Table, "` SET `", p_InScope_Column, "` = ? WHERE `", p_InScope_Column, "` = ?;");
    PREPARE complete_sql FROM @dynamic_sql;
    OPEN info_cursor;
    REPEAT
        FETCH info_cursor INTO v_ContentSmallintUnsigned_Current;
        IF NOT v_done THEN
            SET @ContentSmallintUnsignedOld = v_ContentSmallintUnsigned_Current;
            SET @ContentSmallintUnsignedNew = (v_ContentSmallintUnsigned_Previous + 1);
            IF (@ContentSmallintUnsignedOld = @ContentSmallintUnsignedNew) THEN
                SET v_ContentSmallintUnsigned_Previous = v_ContentSmallintUnsigned_Current;
            ELSE
                EXECUTE complete_sql USING @ContentSmallintUnsignedNew, @ContentSmallintUnsignedOld;
                SET v_ContentSmallintUnsigned_Previous = @ContentSmallintUnsignedNew;
            END IF;
        END IF;
    UNTIL v_done END REPEAT;
    CLOSE info_cursor;
    DEALLOCATE PREPARE complete_sql;
END//
DROP PROCEDURE IF EXISTS `pr_Eliminate_Auto_Increment_Gap_4_Mediumint_Signed`//
CREATE DEFINER=`mysql_monitoring_user`@`127.0.0.1` PROCEDURE `pr_Eliminate_Auto_Increment_Gap_4_Mediumint_Signed`(IN p_InScope_Database VARCHAR(200), IN p_InScope_Table VARCHAR(64), IN p_InScope_Column VARCHAR(64))
    MODIFIES SQL DATA
    COMMENT 'Eliminates the gaps for AC fields of type Mediumint Signed'
BEGIN
	DECLARE v_ContentMediumintSigned_Previous mediumint(9) DEFAULT 0;
	DECLARE v_ContentMediumintSigned_Current mediumint(9);
	DECLARE v_done INT DEFAULT 0;
	DECLARE info_cursor CURSOR FOR SELECT `content_mediumint_signed` FROM `auto_increment_gap_elimination_content` WHERE ( `table_schema` LIKE p_InScope_Database) AND (`table_name` LIKE p_InScope_Table) AND (`column_name` LIKE p_InScope_Column) ORDER BY `content_mediumint_signed`;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
    SET @dynamic_sql = CONCAT("UPDATE `", p_InScope_Database, "`.`", p_InScope_Table, "` SET `", p_InScope_Column, "` = ? WHERE `", p_InScope_Column, "` = ?;");
    PREPARE complete_sql FROM @dynamic_sql;
    OPEN info_cursor;
    REPEAT
        FETCH info_cursor INTO v_ContentMediumintSigned_Current;
        IF NOT v_done THEN
            SET @ContentMediumintSignedOld = v_ContentMediumintSigned_Current;
            SET @ContentMediumintSignedNew = (v_ContentMediumintSigned_Previous + 1);
            IF (@ContentMediumintSignedOld = @ContentMediumintSignedNew) THEN
                SET v_ContentMediumintSigned_Previous = v_ContentMediumintSigned_Current;
            ELSE
                EXECUTE complete_sql USING @ContentMediumintSignedNew, @ContentMediumintSignedOld;
                SET v_ContentMediumintSigned_Previous = @ContentMediumintSignedNew;
            END IF;
        END IF;
    UNTIL v_done END REPEAT;
    CLOSE info_cursor;
    DEALLOCATE PREPARE complete_sql;
END//
DROP PROCEDURE IF EXISTS `pr_Eliminate_Auto_Increment_Gap_4_Mediumint_Unsigned`//
CREATE DEFINER=`mysql_monitoring_user`@`127.0.0.1` PROCEDURE `pr_Eliminate_Auto_Increment_Gap_4_Mediumint_Unsigned`(IN p_InScope_Database VARCHAR(200), IN p_InScope_Table VARCHAR(64), IN p_InScope_Column VARCHAR(64))
    MODIFIES SQL DATA
    COMMENT 'Eliminates the gaps for AC fields of type Mediumint Signed'
BEGIN
	DECLARE v_ContentMediumintUnsigned_Previous mediumint(8) UNSIGNED DEFAULT 0;
	DECLARE v_ContentMediumintUnsigned_Current mediumint(8) UNSIGNED;
	DECLARE v_done INT DEFAULT 0;
	DECLARE info_cursor CURSOR FOR SELECT `content_mediumint_unsigned` FROM `auto_increment_gap_elimination_content` WHERE (`table_schema` LIKE p_InScope_Database) AND (`table_name` LIKE p_InScope_Table) AND (`column_name` LIKE p_InScope_Column) ORDER BY `content_mediumint_unsigned`;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
    SET @dynamic_sql = CONCAT("UPDATE `", p_InScope_Database, "`.`", p_InScope_Table, "` SET `", p_InScope_Column, "` = ? WHERE `", p_InScope_Column, "` = ?;");
    PREPARE complete_sql FROM @dynamic_sql;
    OPEN info_cursor;
    REPEAT
        FETCH info_cursor INTO v_ContentMediumintUnsigned_Current;
        IF NOT v_done THEN
            SET @ContentMediumintUnsignedOld = v_ContentMediumintUnsigned_Current;
            SET @ContentMediumintUnsignedNew = (v_ContentMediumintUnsigned_Previous + 1);
            IF (@ContentMediumintUnsignedOld = @ContentMediumintUnsignedNew) THEN
                SET v_ContentMediumintUnsigned_Previous = v_ContentMediumintUnsigned_Current;
            ELSE
                EXECUTE complete_sql USING @ContentMediumintUnsignedNew, @ContentMediumintUnsignedOld;
                SET v_ContentMediumintUnsigned_Previous = @ContentMediumintUnsignedNew;
            END IF;
        END IF;
    UNTIL v_done END REPEAT;
    CLOSE info_cursor;
    DEALLOCATE PREPARE complete_sql;
END//
DROP PROCEDURE IF EXISTS `pr_Eliminate_Auto_Increment_Gap_4_Int_Signed`//
CREATE DEFINER=`mysql_monitoring_user`@`127.0.0.1` PROCEDURE `pr_Eliminate_Auto_Increment_Gap_4_Int_Signed`(IN p_InScope_Database VARCHAR(200), IN p_InScope_Table VARCHAR(64), IN p_InScope_Column VARCHAR(64))
    MODIFIES SQL DATA
    COMMENT 'Eliminates the gaps for AC fields of type Int Signed'
BEGIN
	DECLARE v_ContentIntSigned_Previous int(11) DEFAULT 0;
	DECLARE v_ContentIntSigned_Current int(11);
	DECLARE v_done INT DEFAULT 0;
	DECLARE info_cursor CURSOR FOR SELECT `content_int_signed` FROM `auto_increment_gap_elimination_content` WHERE ( `table_schema` LIKE p_InScope_Database) AND (`table_name` LIKE p_InScope_Table) AND (`column_name` LIKE p_InScope_Column) ORDER BY `content_int_signed`;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
    SET @dynamic_sql = CONCAT("UPDATE `", p_InScope_Database, "`.`", p_InScope_Table, "` SET `", p_InScope_Column, "` = ? WHERE `", p_InScope_Column, "` = ?;");
    PREPARE complete_sql FROM @dynamic_sql;
    OPEN info_cursor;
    REPEAT
        FETCH info_cursor INTO v_ContentIntSigned_Current;
        IF NOT v_done THEN
            SET @ContentIntSignedOld = v_ContentIntSigned_Current;
            SET @ContentIntSignedNew = (v_ContentIntSigned_Previous + 1);
            IF (@ContentIntSignedOld = @ContentIntSignedNew) THEN
                SET v_ContentIntSigned_Previous = v_ContentIntSigned_Current;
            ELSE
                EXECUTE complete_sql USING @ContentIntSignedNew, @ContentIntSignedOld;
                SET v_ContentIntSigned_Previous = @ContentIntSignedNew;
            END IF;
        END IF;
    UNTIL v_done END REPEAT;
    CLOSE info_cursor;
    DEALLOCATE PREPARE complete_sql;
END//
DROP PROCEDURE IF EXISTS `pr_Eliminate_Auto_Increment_Gap_4_Int_Unsigned`//
CREATE DEFINER=`mysql_monitoring_user`@`127.0.0.1` PROCEDURE `pr_Eliminate_Auto_Increment_Gap_4_Int_Unsigned`(IN p_InScope_Database VARCHAR(200), IN p_InScope_Table VARCHAR(64), IN p_InScope_Column VARCHAR(64))
    MODIFIES SQL DATA
    COMMENT 'Eliminates the gaps for AC fields of type Int Signed'
BEGIN
	DECLARE v_ContentIntUnsigned_Previous int(10) UNSIGNED DEFAULT 0;
	DECLARE v_ContentIntUnsigned_Current int(10) UNSIGNED;
	DECLARE v_done INT DEFAULT 0;
	DECLARE info_cursor CURSOR FOR SELECT `content_int_unsigned` FROM `auto_increment_gap_elimination_content` WHERE (`table_schema` LIKE p_InScope_Database) AND (`table_name` LIKE p_InScope_Table) AND (`column_name` LIKE p_InScope_Column) ORDER BY `content_int_unsigned`;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
    SET @dynamic_sql = CONCAT("UPDATE `", p_InScope_Database, "`.`", p_InScope_Table, "` SET `", p_InScope_Column, "` = ? WHERE `", p_InScope_Column, "` = ?;");
    PREPARE complete_sql FROM @dynamic_sql;
    OPEN info_cursor;
    REPEAT
        FETCH info_cursor INTO v_ContentIntUnsigned_Current;
        IF NOT v_done THEN
            SET @ContentIntUnsignedOld = v_ContentIntUnsigned_Current;
            SET @ContentIntUnsignedNew = (v_ContentIntUnsigned_Previous + 1);
            IF (@ContentIntUnsignedOld = @ContentIntUnsignedNew) THEN
                SET v_ContentIntUnsigned_Previous = v_ContentIntUnsigned_Current;
            ELSE
                EXECUTE complete_sql USING @ContentIntUnsignedNew, @ContentIntUnsignedOld;
                SET v_ContentIntUnsigned_Previous = @ContentIntUnsignedNew;
            END IF;
        END IF;
    UNTIL v_done END REPEAT;
    CLOSE info_cursor;
    DEALLOCATE PREPARE complete_sql;
END//
DROP PROCEDURE IF EXISTS `pr_Eliminate_Auto_Increment_Gap_4_Bigint_Signed`//
CREATE DEFINER=`mysql_monitoring_user`@`127.0.0.1` PROCEDURE `pr_Eliminate_Auto_Increment_Gap_4_Bigint_Signed`(IN p_InScope_Database VARCHAR(200), IN p_InScope_Table VARCHAR(64), IN p_InScope_Column VARCHAR(64))
    MODIFIES SQL DATA
    COMMENT 'Eliminates the gaps for AC fields of type Bigint Signed'
BEGIN
	DECLARE v_ContentBigintSigned_Previous bigint(21) DEFAULT 0;
	DECLARE v_ContentBigintSigned_Current bigint(21);
	DECLARE v_done INT DEFAULT 0;
	DECLARE info_cursor CURSOR FOR SELECT `content_bigint_signed` FROM `auto_increment_gap_elimination_content` WHERE ( `table_schema` LIKE p_InScope_Database) AND (`table_name` LIKE p_InScope_Table) AND (`column_name` LIKE p_InScope_Column) ORDER BY `content_bigint_signed`;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
    SET @dynamic_sql = CONCAT("UPDATE `", p_InScope_Database, "`.`", p_InScope_Table, "` SET `", p_InScope_Column, "` = ? WHERE `", p_InScope_Column, "` = ?;");
    PREPARE complete_sql FROM @dynamic_sql;
    OPEN info_cursor;
    REPEAT
        FETCH info_cursor INTO v_ContentBigintSigned_Current;
        IF NOT v_done THEN
            SET @ContentBigintSignedOld = v_ContentBigintSigned_Current;
            SET @ContentBigintSignedNew = (v_ContentBigintSigned_Previous + 1);
            IF (@ContentBigintSignedOld = @ContentBigintSignedNew) THEN
                SET v_ContentBigintSigned_Previous = v_ContentBigintSigned_Current;
            ELSE
                EXECUTE complete_sql USING @ContentBigintSignedNew, @ContentBigintSignedOld;
                SET v_ContentBigintSigned_Previous = @ContentBigintSignedNew;
            END IF;
        END IF;
    UNTIL v_done END REPEAT;
    CLOSE info_cursor;
    DEALLOCATE PREPARE complete_sql;
END//
DROP PROCEDURE IF EXISTS `pr_Eliminate_Auto_Increment_Gap_4_Bigint_Unsigned`//
CREATE DEFINER=`mysql_monitoring_user`@`127.0.0.1` PROCEDURE `pr_Eliminate_Auto_Increment_Gap_4_Bigint_Unsigned`(IN p_InScope_Database VARCHAR(200), IN p_InScope_Table VARCHAR(64), IN p_InScope_Column VARCHAR(64))
    MODIFIES SQL DATA
    COMMENT 'Eliminates the gaps for AC fields of type Bigint Signed'
BEGIN
	DECLARE v_ContentBigintUnsigned_Previous bigint(20) UNSIGNED DEFAULT 0;
	DECLARE v_ContentBigintUnsigned_Current bigint(20) UNSIGNED;
	DECLARE v_done INT DEFAULT 0;
	DECLARE info_cursor CURSOR FOR SELECT `content_bigint_unsigned` FROM `auto_increment_gap_elimination_content` WHERE (`table_schema` LIKE p_InScope_Database) AND (`table_name` LIKE p_InScope_Table) AND (`column_name` LIKE p_InScope_Column) ORDER BY `content_bigint_unsigned`;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
    SET @dynamic_sql = CONCAT("UPDATE `", p_InScope_Database, "`.`", p_InScope_Table, "` SET `", p_InScope_Column, "` = ? WHERE `", p_InScope_Column, "` = ?;");
    PREPARE complete_sql FROM @dynamic_sql;
    OPEN info_cursor;
    REPEAT
        FETCH info_cursor INTO v_ContentBigintUnsigned_Current;
        IF NOT v_done THEN
            SET @ContentBigintUnsignedOld = v_ContentBigintUnsigned_Current;
            SET @ContentBigintUnsignedNew = (v_ContentBigintUnsigned_Previous + 1);
            IF (@ContentBigintUnsignedOld = @ContentBigintUnsignedNew) THEN
                SET v_ContentBigintUnsigned_Previous = v_ContentBigintUnsigned_Current;
            ELSE
                EXECUTE complete_sql USING @ContentBigintUnsignedNew, @ContentBigintUnsignedOld;
                SET v_ContentBigintUnsigned_Previous = @ContentBigintUnsignedNew;
            END IF;
        END IF;
    UNTIL v_done END REPEAT;
    CLOSE info_cursor;
    DEALLOCATE PREPARE complete_sql;
END//
DROP PROCEDURE IF EXISTS `pr_Eliminate_Auto_Increment_Gaps_Only`//
CREATE DEFINER=`mysql_monitoring_user`@`127.0.0.1` PROCEDURE `pr_Eliminate_Auto_Increment_Gaps_Only`(IN p_InScope_Database VARCHAR(200), IN p_InScope_Table VARCHAR(64))
    MODIFIES SQL DATA
    COMMENT "Eliminates gaps from AC cols. (require AI Health Evaluation 1st)"
BEGIN
	DECLARE v_InScope_Database VARCHAR(200);
	DECLARE v_InScope_Table VARCHAR(64);
	DECLARE v_InScope_Column VARCHAR(64);
	DECLARE v_Type_Data VARCHAR(200);
	DECLARE v_Type_Column VARCHAR(200);
	DECLARE v_NonCascadedFKs SMALLINT(5) UNSIGNED DEFAULT NULL;
	DECLARE v_done INT DEFAULT 0;
	DECLARE info_cursor CURSOR FOR SELECT `table_schema`, `table_name`, `column_name`, `data_type`, `column_type` FROM `auto_increment_health_evaluation` WHERE (`table_schema` LIKE p_InScope_Database) AND (`table_name` LIKE p_InScope_Table) AND ((`calculated_start_quality_level` NOT LIKE "perfect") OR (`calculated_continuity_quality_level` NOT LIKE "perfect"));
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
    OPEN info_cursor;
    REPEAT
        FETCH info_cursor INTO v_InScope_Database, v_InScope_Table, v_InScope_Column, v_Type_Data, v_Type_Column;
        IF NOT v_done THEN
            /* before proceed we have to verify if we have FK relationship with anything else but CASCADE to ensure data integrity */
            SELECT COUNT(*) INTO v_NonCascadedFKs FROM `information_schema`.`KEY_COLUMN_USAGE` `KCU` INNER JOIN `information_schema`.`REFERENTIAL_CONSTRAINTS` `RC` ON ((`KCU`.`CONSTRAINT_SCHEMA` = `RC`.`CONSTRAINT_SCHEMA`) AND (`KCU`.`CONSTRAINT_NAME` = `RC`.`CONSTRAINT_NAME`)) WHERE (`KCU`.`TABLE_SCHEMA` = v_InScope_Database) AND (`KCU`.`TABLE_NAME` = v_InScope_Table) AND (`KCU`.`COLUMN_NAME` = v_InScope_Column) AND (`KCU`.`REFERENCED_TABLE_NAME` IS NOT NULL) AND (`RC`.`UPDATE_RULE` != "CASCADE");
            IF v_NonCascadedFKs = 0 THEN
                SET @dynamic_sql_delete = CONCAT("DELETE FROM `auto_increment_gap_elimination_content` WHERE ( `table_schema` LIKE '", v_InScope_Database, "') AND (`table_name` LIKE '", v_InScope_Table, "') AND (`column_name` LIKE '", v_InScope_Column, "');");
                PREPARE complete_sql_delete FROM @dynamic_sql_delete;
                EXECUTE complete_sql_delete;
                CASE 
                    WHEN ((v_Type_Data = "tinyint") AND (LOCATE("unsigned", v_Type_Column) = 0)) THEN
                        SET @dynamic_sql_insert = CONCAT("INSERT INTO `auto_increment_gap_elimination_content` (`table_schema`, `table_name`, `column_name`, `content_tinyint_signed`) SELECT '", v_InScope_Database, "', '", v_InScope_Table, "', '", v_InScope_Column, "', `", v_InScope_Column, "` FROM `", v_InScope_Database, "`.`", v_InScope_Table, "`;");
                    WHEN ((v_Type_Data = "tinyint") AND (LOCATE("unsigned", v_Type_Column) != 0)) THEN
                        SET @dynamic_sql_insert = CONCAT("INSERT INTO `auto_increment_gap_elimination_content` (`table_schema`, `table_name`, `column_name`, `content_tinyint_unsigned`) SELECT '", v_InScope_Database, "', '", v_InScope_Table, "', '", v_InScope_Column, "', `", v_InScope_Column, "` FROM `", v_InScope_Database, "`.`", v_InScope_Table, "`;");
                    WHEN ((v_Type_Data = "smallint") AND (LOCATE("unsigned", v_Type_Column) = 0)) THEN
                        SET @dynamic_sql_insert = CONCAT("INSERT INTO `auto_increment_gap_elimination_content` (`table_schema`, `table_name`, `column_name`, `content_smallint_signed`) SELECT '", v_InScope_Database, "', '", v_InScope_Table, "', '", v_InScope_Column, "', `", v_InScope_Column, "` FROM `", v_InScope_Database, "`.`", v_InScope_Table, "`;");
                    WHEN ((v_Type_Data = "smallint") AND (LOCATE("unsigned", v_Type_Column) != 0)) THEN
                        SET @dynamic_sql_insert = CONCAT("INSERT INTO `auto_increment_gap_elimination_content` (`table_schema`, `table_name`, `column_name`, `content_smallint_unsigned`) SELECT '", v_InScope_Database, "', '", v_InScope_Table, "', '", v_InScope_Column, "', `", v_InScope_Column, "` FROM `", v_InScope_Database, "`.`", v_InScope_Table, "`;");
                    WHEN ((v_Type_Data = "mediumint") AND (LOCATE("unsigned", v_Type_Column) = 0)) THEN
                        SET @dynamic_sql_insert = CONCAT("INSERT INTO `auto_increment_gap_elimination_content` (`table_schema`, `table_name`, `column_name`, `content_mediumint_signed`) SELECT '", v_InScope_Database, "', '", v_InScope_Table, "', '", v_InScope_Column, "', `", v_InScope_Column, "` FROM `", v_InScope_Database, "`.`", v_InScope_Table, "`;");
                    WHEN ((v_Type_Data = "mediumint") AND (LOCATE("unsigned", v_Type_Column) != 0)) THEN
                        SET @dynamic_sql_insert = CONCAT("INSERT INTO `auto_increment_gap_elimination_content` (`table_schema`, `table_name`, `column_name`, `content_mediumint_unsigned`) SELECT '", v_InScope_Database, "', '", v_InScope_Table, "', '", v_InScope_Column, "', `", v_InScope_Column, "` FROM `", v_InScope_Database, "`.`", v_InScope_Table, "`;");
                    WHEN ((v_Type_Data = "int") AND (LOCATE("unsigned", v_Type_Column) = 0)) THEN
                        SET @dynamic_sql_insert = CONCAT("INSERT INTO `auto_increment_gap_elimination_content` (`table_schema`, `table_name`, `column_name`, `content_int_signed`) SELECT '", v_InScope_Database, "', '", v_InScope_Table, "', '", v_InScope_Column, "', `", v_InScope_Column, "` FROM `", v_InScope_Database, "`.`", v_InScope_Table, "`;");
                    WHEN ((v_Type_Data = "int") AND (LOCATE("unsigned", v_Type_Column) != 0)) THEN
                        SET @dynamic_sql_insert = CONCAT("INSERT INTO `auto_increment_gap_elimination_content` (`table_schema`, `table_name`, `column_name`, `content_int_unsigned`) SELECT '", v_InScope_Database, "', '", v_InScope_Table, "', '", v_InScope_Column, "', `", v_InScope_Column, "` FROM `", v_InScope_Database, "`.`", v_InScope_Table, "`;");
                    WHEN ((v_Type_Data = "bigint") AND (LOCATE("unsigned", v_Type_Column) = 0)) THEN
                        SET @dynamic_sql_insert = CONCAT("INSERT INTO `auto_increment_gap_elimination_content` (`table_schema`, `table_name`, `column_name`, `content_bigint_signed`) SELECT '", v_InScope_Database, "', '", v_InScope_Table, "', '", v_InScope_Column, "', `", v_InScope_Column, "` FROM `", v_InScope_Database, "`.`", v_InScope_Table, "`;");
                    WHEN ((v_Type_Data = "bigint") AND (LOCATE("unsigned", v_Type_Column) != 0)) THEN
                        SET @dynamic_sql_insert = CONCAT("INSERT INTO `auto_increment_gap_elimination_content` (`table_schema`, `table_name`, `column_name`, `content_bigint_unsigned`) SELECT '", v_InScope_Database, "', '", v_InScope_Table, "', '", v_InScope_Column, "', `", v_InScope_Column, "` FROM `", v_InScope_Database, "`.`", v_InScope_Table, "`;");
                END CASE;
                PREPARE complete_sql_insert FROM @dynamic_sql_insert;
                EXECUTE complete_sql_insert;
                DEALLOCATE PREPARE complete_sql_insert;
                CASE 
                    WHEN ((v_Type_Data = "tinyint") AND (LOCATE("unsigned", v_Type_Column) = 0)) THEN
                        CALL `pr_Eliminate_Auto_Increment_Gap_4_Tinyint_Signed`(v_InScope_Database, v_InScope_Table, v_InScope_Column);
                    WHEN ((v_Type_Data = "tinyint") AND (LOCATE("unsigned", v_Type_Column) != 0)) THEN
                        CALL `pr_Eliminate_Auto_Increment_Gap_4_Tinyint_Unsigned`(v_InScope_Database, v_InScope_Table, v_InScope_Column);
                    WHEN ((v_Type_Data = "smallint") AND (LOCATE("unsigned", v_Type_Column) = 0)) THEN
                        CALL `pr_Eliminate_Auto_Increment_Gap_4_Smallint_Signed`(v_InScope_Database, v_InScope_Table, v_InScope_Column);
                    WHEN ((v_Type_Data = "smallint") AND (LOCATE("unsigned", v_Type_Column) != 0)) THEN
                        CALL `pr_Eliminate_Auto_Increment_Gap_4_Smallint_Unsigned`(v_InScope_Database, v_InScope_Table, v_InScope_Column);
                    WHEN ((v_Type_Data = "mediumint") AND (LOCATE("unsigned", v_Type_Column) = 0)) THEN
                        CALL `pr_Eliminate_Auto_Increment_Gap_4_Mediumint_Signed`(v_InScope_Database, v_InScope_Table, v_InScope_Column);
                    WHEN ((v_Type_Data = "mediumint") AND (LOCATE("unsigned", v_Type_Column) != 0)) THEN
                        CALL `pr_Eliminate_Auto_Increment_Gap_4_Mediumint_Unsigned`(v_InScope_Database, v_InScope_Table, v_InScope_Column);
                    WHEN ((v_Type_Data = "int") AND (LOCATE("unsigned", v_Type_Column) = 0)) THEN
                        CALL `pr_Eliminate_Auto_Increment_Gap_4_Int_Signed`(v_InScope_Database, v_InScope_Table, v_InScope_Column);
                    WHEN ((v_Type_Data = "int") AND (LOCATE("unsigned", v_Type_Column) != 0)) THEN
                        CALL `pr_Eliminate_Auto_Increment_Gap_4_Int_Unsigned`(v_InScope_Database, v_InScope_Table, v_InScope_Column);
                    WHEN ((v_Type_Data = "bigint") AND (LOCATE("unsigned", v_Type_Column) = 0)) THEN
                        CALL `pr_Eliminate_Auto_Increment_Gap_4_Bigint_Signed`(v_InScope_Database, v_InScope_Table, v_InScope_Column);
                    WHEN ((v_Type_Data = "bigint") AND (LOCATE("unsigned", v_Type_Column) != 0)) THEN
                        CALL `pr_Eliminate_Auto_Increment_Gap_4_Bigint_Unsigned`(v_InScope_Database, v_InScope_Table, v_InScope_Column);
                END CASE;
                SET @dynamic_sql_alter = CONCAT("ALTER TABLE `", v_InScope_Database, "`.`", v_InScope_Table, "` AUTO_INCREMENT = 1;");
                PREPARE complete_sql_alter FROM @dynamic_sql_alter;
                EXECUTE complete_sql_alter;
                DEALLOCATE PREPARE complete_sql_alter;
                EXECUTE complete_sql_delete;
                DEALLOCATE PREPARE complete_sql_delete;
            END IF;
        END IF;
    UNTIL v_done END REPEAT;
    CLOSE info_cursor;
END//
DROP PROCEDURE IF EXISTS `pr_Eliminate_Auto_Increment_Gaps`//
CREATE DEFINER=`mysql_monitoring_user`@`127.0.0.1` PROCEDURE `pr_Eliminate_Auto_Increment_Gaps`(IN p_InScope_Database VARCHAR(64), IN p_InScope_Table VARCHAR(64))
    MODIFIES SQL DATA
BEGIN
    CALL `pr_Auto_Increment_Evaluation_ALL`(p_InScope_Database, p_InScope_Table);
    INSERT `auto_increment_gap_elimination_log` 
        (`table_schema`, `table_name`, `column_name`, `parameters_before`)
        SELECT 
            `table_schema`,
            `table_name`,
            `column_name`,
            CONCAT('{ "data_type": "', `data_type`, '", "column_type": "', `column_type`, '", "auto_increment_next_value": "', `auto_increment_next_value`, '", "min_evaluated": "', `min_evaluated`, '", "max_evaluated": "', `max_evaluated`, '", "record_count_evaluated": "', `record_count_evaluated`, '" }')
        FROM
            `auto_increment_health_evaluation`
        WHERE
            (`table_schema` LIKE p_InScope_Database)
            AND (`table_name` LIKE p_InScope_Table)
            AND (
                (`calculated_start_quality_level` NOT LIKE "perfect") 
                OR (`calculated_continuity_quality_level` NOT LIKE "perfect")
            );
    CALL `pr_Eliminate_Auto_Increment_Gaps_Only`(p_InScope_Database, p_InScope_Table);
    CALL `pr_Auto_Increment_Evaluation_ALL`(p_InScope_Database, p_InScope_Table);
    UPDATE
        `auto_increment_gap_elimination_log` `aigel`
    SET
        `aigel`.`parameters_after` = (
            SELECT
                CONCAT('{ "auto_increment_next_value": "', `aihe`.`auto_increment_next_value`, '", "min_evaluated": "', `aihe`.`min_evaluated`, '", "max_evaluated": "', `aihe`.`max_evaluated`, '", "record_count_evaluated": "', `aihe`.`record_count_evaluated`, '" }')
            FROM
                `auto_increment_health_evaluation` `aihe`
            WHERE
                (`aihe`.`table_schema` LIKE `aigel`.`table_schema`)
                AND (`aihe`.`table_name` LIKE `aigel`.`table_name`)
                AND (`aihe`.`column_name` LIKE `aigel`.`column_name`)
        )
    WHERE
        (`aigel`.`table_schema` LIKE p_InScope_Database)
        AND (`table_name` LIKE p_InScope_Table)
        AND (`aigel`.`gap_elimination_timestamp_completed` IS NULL);
END//
DELIMITER ;