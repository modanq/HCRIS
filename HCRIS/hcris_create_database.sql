-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- Schema HCRIS
-- -----------------------------------------------------
DROP SCHEMA IF EXISTS `HCRIS` ;

-- -----------------------------------------------------
-- Schema HCRIS
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `HCRIS` DEFAULT CHARACTER SET ascii ;
USE `HCRIS` ;

-- -----------------------------------------------------
-- Table `HCRIS`.`control_type`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `HCRIS`.`control_type` ;

CREATE TABLE IF NOT EXISTS `HCRIS`.`control_type` (
  `control_type_id` TINYINT UNSIGNED NOT NULL,
  `control_type` VARCHAR(19) CHARACTER SET 'ascii' NOT NULL,
  `control_subtype` VARCHAR(17) CHARACTER SET 'ascii' NOT NULL,
  PRIMARY KEY (`control_type_id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `HCRIS`.`report`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `HCRIS`.`report` ;

CREATE TABLE IF NOT EXISTS `HCRIS`.`report` (
  `report_id` MEDIUMINT UNSIGNED NOT NULL,
  `form` ENUM('2552-96', '2552-10') NOT NULL,
  `report_year` YEAR NOT NULL,
  `control_type_id` TINYINT UNSIGNED NULL,
  `provider_id` MEDIUMINT UNSIGNED NOT NULL,
  `npi` INT UNSIGNED NULL,
  `report_status` ENUM('Amended', 'As Submitted', 'Reopened', 'Settled', 'Settled w/Audit') NOT NULL,
  `fiscal_year_start` DATE NULL,
  `fiscal_year_end` DATE NULL,
  `process_date` DATE NULL,
  `medicare_utilization` ENUM('Low', 'None', 'Full') NOT NULL,
  PRIMARY KEY (`report_id`, `form`),
  INDEX `fk_report_control_type_idx` (`control_type_id` ASC),
  CONSTRAINT `fk_report_control_type`
    FOREIGN KEY (`control_type_id`)
    REFERENCES `HCRIS`.`control_type` (`control_type_id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `HCRIS`.`alpha`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `HCRIS`.`alpha` ;

CREATE TABLE IF NOT EXISTS `HCRIS`.`alpha` (
  `report_id` MEDIUMINT UNSIGNED NOT NULL,
  `form` ENUM('2552-96', '2552-10') NOT NULL,
  `variable_name` VARCHAR(41) NOT NULL,
  `item_text` VARCHAR(41) NOT NULL,
  INDEX `index_report` (`report_id` ASC),
  INDEX `fk_alpha_report_idx` (`report_id` ASC, `form` ASC),
  CONSTRAINT `fk_alpha_report`
    FOREIGN KEY (`report_id` , `form`)
    REFERENCES `HCRIS`.`report` (`report_id` , `form`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `HCRIS`.`alpha_temp`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `HCRIS`.`alpha_temp` ;

CREATE TABLE IF NOT EXISTS `HCRIS`.`alpha_temp` (
  `report_id` MEDIUMINT UNSIGNED NOT NULL,
  `form` ENUM('2552-96', '2552-10') NOT NULL,
  `worksheet_code` CHAR(7) NOT NULL,
  `line_number` CHAR(5) NOT NULL,
  `column_number` CHAR(5) NOT NULL,
  `item_text` VARCHAR(41) NOT NULL,
  INDEX `index2` (`worksheet_code` ASC),
  INDEX `index_WKSHT_CD` (`worksheet_code` ASC))
ENGINE = MEMORY;


-- -----------------------------------------------------
-- Table `HCRIS`.`provider_type`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `HCRIS`.`provider_type` ;

CREATE TABLE IF NOT EXISTS `HCRIS`.`provider_type` (
  `provider_type_id` TINYINT UNSIGNED NOT NULL,
  `provider_type` VARCHAR(45) CHARACTER SET 'ascii' NOT NULL,
  PRIMARY KEY (`provider_type_id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `HCRIS`.`provider`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `HCRIS`.`provider` ;

CREATE TABLE IF NOT EXISTS `HCRIS`.`provider` (
  `provider_id` MEDIUMINT UNSIGNED NOT NULL,
  `hospital_name` VARCHAR(36) NOT NULL,
  `street_address` VARCHAR(36) NULL,
  `po_box` VARCHAR(20) NULL,
  `city` VARCHAR(28) NOT NULL,
  `state` CHAR(2) NOT NULL,
  `zip_code` CHAR(10) NOT NULL,
  `county` VARCHAR(31) NULL,
  PRIMARY KEY (`provider_id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `HCRIS`.`features`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `HCRIS`.`features` ;

CREATE TABLE IF NOT EXISTS `HCRIS`.`features` (
  `variable_name` VARCHAR(41) NOT NULL,
  `form` ENUM('2552-96', '2552-10') NOT NULL,
  `variable_type` ENUM('Alpha', 'Numeric') NOT NULL,
  `worksheet_code` CHAR(7) NOT NULL,
  `line_number` CHAR(5) NOT NULL,
  `column_number` CHAR(5) NOT NULL,
  PRIMARY KEY (`variable_name`, `form`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `HCRIS`.`numeric_temp`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `HCRIS`.`numeric_temp` ;

CREATE TABLE IF NOT EXISTS `HCRIS`.`numeric_temp` (
  `report_id` MEDIUMINT UNSIGNED NOT NULL,
  `form` ENUM('2552-96', '2552-10') NOT NULL,
  `worksheet_code` CHAR(7) NOT NULL,
  `line_number` CHAR(5) NOT NULL,
  `column_number` CHAR(5) NOT NULL,
  `item_value` FLOAT NOT NULL,
  INDEX `index2` (`worksheet_code` ASC),
  INDEX `index_WKSHT_CD` (`worksheet_code` ASC))
ENGINE = MEMORY;


-- -----------------------------------------------------
-- Table `HCRIS`.`numeric`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `HCRIS`.`numeric` ;

CREATE TABLE IF NOT EXISTS `HCRIS`.`numeric` (
  `report_id` MEDIUMINT UNSIGNED NOT NULL,
  `form` ENUM('2552-96', '2552-10') NOT NULL,
  `variable_name` VARCHAR(41) NOT NULL,
  `item_value` FLOAT NOT NULL,
  INDEX `index_report` (`report_id` ASC),
  INDEX `fk_numeric_report_idx` (`report_id` ASC, `form` ASC),
  CONSTRAINT `fk_numeric_report`
    FOREIGN KEY (`report_id` , `form`)
    REFERENCES `HCRIS`.`report` (`report_id` , `form`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;

USE `HCRIS` ;

-- -----------------------------------------------------
-- Placeholder table for view `HCRIS`.`aggregate`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `HCRIS`.`aggregate` (`provider_id` INT, `hospital_name` INT, `report_year` INT, `fiscal_year_start` INT, `fiscal_year_end` INT, `city` INT, `state` INT, `zip_code` INT, `medicare_utilization` INT, `control_type` INT, `control_subtype` INT, `provider_type` INT, `qualify_for_dsh_payments` INT, `qualify_for_dsh_capital_payments` INT, `geographic_classification` INT, `sole_community_hospital` INT, `medicare_dependent_hospital` INT, `teaching_hospital` INT, `critical_access_hospital` INT, `referral_center` INT, `meaningful_use` INT, `medicare_termination` INT, `number_of_beds` INT, `total_bed_days` INT, `total_inpatient_days` INT, `total_discharges` INT, `icu_beds` INT, `icu_bed_days` INT, `icu_inpatient_days` INT, `icu_total_costs` INT, `emergency_room_total_costs` INT, `medicaid_total_days` INT, `medicaid_hmo_days` INT, `medicaid_labor_and_delivery_days` INT, `medicaid_swing_bed_snf_days` INT, `medicaid_swing_bed_nf_days` INT, `total_patient_days` INT, `total_labor_and_delivery_days` INT, `employee_discount_days` INT, `total_swing_bed_snf_days` INT, `total_swing_bed_nf_days` INT, `total_adjusted_salaries` INT, `total_paid_hours` INT, `total_operating_expense` INT, `cost_to_charge_ratio` INT, `medicaid_revenue` INT, `medicaid_cost` INT, `total_unreimbursed_and_uncompensated_care` INT, `ssi_to_medicare_days` INT, `medicaid_to_total_days` INT, `calculated_dsh_percentage` INT, `adjusted_dsh_percentage` INT);

-- -----------------------------------------------------
-- View `HCRIS`.`aggregate`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `HCRIS`.`aggregate`;
DROP VIEW IF EXISTS `HCRIS`.`aggregate` ;
USE `HCRIS`;
CREATE  OR REPLACE VIEW `aggregate` AS
SELECT provider_id, hospital_name, report_year, fiscal_year_start, fiscal_year_end, city, state, zip_code, medicare_utilization, control_type, control_subtype
	 , (SELECT provider_type FROM `numeric` JOIN provider_type ON provider_type.provider_type_id = item_value WHERE report_id = report.report_id AND form = report.form AND variable_name = 'provider_type') AS `provider_type`
     , (SELECT item_text FROM alpha WHERE report_id = report.report_id AND form = report.form AND variable_name = 'qualify_for_dsh_payments') AS `qualify_for_dsh_payments`
     , (SELECT item_text FROM alpha WHERE report_id = report.report_id AND form = report.form AND variable_name = 'qualify_for_dsh_capital_payments') AS `qualify_for_dsh_capital_payments`
     , (SELECT CASE WHEN item_value = 1 THEN "Urban" WHEN item_value = 2 THEN "Rural" ELSE NULL END FROM `numeric` WHERE variable_name = 'geographic_classification' AND report_id = report.report_id AND form = report.form UNION SELECT CASE WHEN item_text = 1 THEN "Urban" WHEN item_text = 2 THEN "Rural" ELSE NULL END FROM alpha WHERE variable_name = 'geographic_classification' AND report_id = report.report_id AND form = report.form) AS `geographic_classification`
     , EXISTS (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'sole_community_hospital') AS `sole_community_hospital`
     , EXISTS (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'medicare_dependent_hospital') AS `medicare_dependent_hospital`
     , (SELECT item_text FROM alpha WHERE report_id = report.report_id AND form = report.form AND variable_name = 'teaching_hospital') AS `teaching_hospital`
     , (SELECT item_text FROM alpha WHERE report_id = report.report_id AND form = report.form AND variable_name = 'critical_access_hospital') AS `critical_access_hospital`
     , (SELECT item_text FROM alpha WHERE report_id = report.report_id AND form = report.form AND variable_name = 'referral_center') AS `referral_center`
     , (SELECT item_text FROM alpha WHERE report_id = report.report_id AND form = report.form AND variable_name = 'meaningful_use') AS `meaningful_use`
     , (SELECT item_text FROM alpha WHERE report_id = report.report_id AND form = report.form AND variable_name = 'medicare_termination') AS `medicare_termination`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'number_of_beds') AS `number_of_beds`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'total_bed_days') AS `total_bed_days`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'total_inpatient_days') AS `total_inpatient_days`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'total_discharges') AS `total_discharges`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'icu_beds') AS `icu_beds`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'icu_bed_days') AS `icu_bed_days`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'icu_inpatient_days') AS `icu_inpatient_days`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'icu_total_costs') AS `icu_total_costs`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'emergency_room_total_costs') AS `emergency_room_total_costs`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'medicaid_total_days') AS `medicaid_total_days`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'medicaid_hmo_days') AS `medicaid_hmo_days`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'medicaid_labor_and_delivery_days') AS `medicaid_labor_and_delivery_days` # only available >= 2010
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'medicaid_swing_bed_snf_days') AS `medicaid_swing_bed_snf_days`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'medicaid_swing_bed_nf_days') AS `medicaid_swing_bed_nf_days`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'total_patient_days') AS `total_patient_days`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'total_labor_and_delivery_days') AS `total_labor_and_delivery_days` # only available >= 2010
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'employee_discount_days') AS `employee_discount_days`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'total_swing_bed_snf_days') AS `total_swing_bed_snf_days`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'total_swing_bed_nf_days') AS `total_swing_bed_nf_days`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'total_adjusted_salaries') AS `total_adjusted_salaries`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'total_paid_hours') AS `total_paid_hours`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'total_operating_expense') AS `total_operating_expense`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'cost_to_charge_ratio') AS `cost_to_charge_ratio`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'medicaid_revenue') AS `medicaid_revenue`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'medicaid_cost') AS `medicaid_cost`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'total_unreimbursed_and_uncompensated_care') AS `total_unreimbursed_and_uncompensated_care`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'ssi_to_medicare_days') AS `ssi_to_medicare_days`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'medicaid_to_total_days') AS `medicaid_to_total_days`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'calculated_dsh_percentage') AS `calculated_dsh_percentage`
     , (SELECT item_value FROM `numeric` WHERE report_id = report.report_id AND form = report.form AND variable_name = 'adjusted_dsh_percentage') AS `adjusted_dsh_percentage`
FROM report
	LEFT JOIN provider USING(provider_id)
    LEFT JOIN control_type USING(control_type_id)
ORDER BY provider_id, report_year
LIMIT 150000
;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

-- -----------------------------------------------------
-- Data for table `HCRIS`.`control_type`
-- -----------------------------------------------------
START TRANSACTION;
USE `HCRIS`;
INSERT INTO `HCRIS`.`control_type` (`control_type_id`, `control_type`, `control_subtype`) VALUES (1, 'Voluntary Nonprofit', 'Church');
INSERT INTO `HCRIS`.`control_type` (`control_type_id`, `control_type`, `control_subtype`) VALUES (2, 'Voluntary Nonprofit', 'Other');
INSERT INTO `HCRIS`.`control_type` (`control_type_id`, `control_type`, `control_subtype`) VALUES (3, 'Proprietary', 'Individual');
INSERT INTO `HCRIS`.`control_type` (`control_type_id`, `control_type`, `control_subtype`) VALUES (4, 'Proprietary', 'Corporation');
INSERT INTO `HCRIS`.`control_type` (`control_type_id`, `control_type`, `control_subtype`) VALUES (5, 'Proprietary', 'Partnership');
INSERT INTO `HCRIS`.`control_type` (`control_type_id`, `control_type`, `control_subtype`) VALUES (6, 'Proprietary', 'Other');
INSERT INTO `HCRIS`.`control_type` (`control_type_id`, `control_type`, `control_subtype`) VALUES (7, 'Governmental', 'Federal');
INSERT INTO `HCRIS`.`control_type` (`control_type_id`, `control_type`, `control_subtype`) VALUES (8, 'Governmental', 'City-County');
INSERT INTO `HCRIS`.`control_type` (`control_type_id`, `control_type`, `control_subtype`) VALUES (9, 'Governmental', 'County');
INSERT INTO `HCRIS`.`control_type` (`control_type_id`, `control_type`, `control_subtype`) VALUES (10, 'Governmental', 'State');
INSERT INTO `HCRIS`.`control_type` (`control_type_id`, `control_type`, `control_subtype`) VALUES (11, 'Governmental', 'Hospital District');
INSERT INTO `HCRIS`.`control_type` (`control_type_id`, `control_type`, `control_subtype`) VALUES (12, 'Governmental', 'City');
INSERT INTO `HCRIS`.`control_type` (`control_type_id`, `control_type`, `control_subtype`) VALUES (13, 'Governmental', 'Other');

COMMIT;


-- -----------------------------------------------------
-- Data for table `HCRIS`.`provider_type`
-- -----------------------------------------------------
START TRANSACTION;
USE `HCRIS`;
INSERT INTO `HCRIS`.`provider_type` (`provider_type_id`, `provider_type`) VALUES (1, 'General Short Term');
INSERT INTO `HCRIS`.`provider_type` (`provider_type_id`, `provider_type`) VALUES (2, 'General Long Term');
INSERT INTO `HCRIS`.`provider_type` (`provider_type_id`, `provider_type`) VALUES (3, 'Cancer');
INSERT INTO `HCRIS`.`provider_type` (`provider_type_id`, `provider_type`) VALUES (4, 'Psychiatric');
INSERT INTO `HCRIS`.`provider_type` (`provider_type_id`, `provider_type`) VALUES (5, 'Rehabilitation');
INSERT INTO `HCRIS`.`provider_type` (`provider_type_id`, `provider_type`) VALUES (6, 'Religious Non-Medical Health Care Institution');
INSERT INTO `HCRIS`.`provider_type` (`provider_type_id`, `provider_type`) VALUES (7, 'Children');
INSERT INTO `HCRIS`.`provider_type` (`provider_type_id`, `provider_type`) VALUES (8, 'Alcohol and Drug');
INSERT INTO `HCRIS`.`provider_type` (`provider_type_id`, `provider_type`) VALUES (9, 'Other');

COMMIT;

