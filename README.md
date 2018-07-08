# auto-increment-health-mysql
Auto Increment Health Evaluation for MySQL databases

Auto Increment Health Evaluation for MySQL databases - provides a set of metric to help you evaluate the following:
- filling level and if is little to no reserve left which will be an indicator that you will have to take appropriate actions before serious problems dictated by data not being able to be added;
- start gap level and if that is medium or high is an indicator the interval is deviated and you are affected by wasted values with potential bigger problems on filling level and its implications (see above);
- continuous level and if that is medium or high is an indicator of you have a gap generating process in the source that populates your data with potential bigger problems on filling level and its implications (see above);
- end gap level and if that is medium or high is an indicator of you have a gap generating process in the source that populates your data that is affecting the end with potential bigger problems on filling level and its implications (see above);

Current script has been tested on following MySQL flavours:
- Oracle MySQL 5.0.96 (on 19.09.2016, different script created due to big DDL differences, see "MySQL_50x" folder)
- Oracle MySQL 5.1.72 (on 19.09.2016, different script created due to big DDL differences, see "MySQL_51x-55x" folder)
- Oracle MySQL 5.5.52 (on 19.09.2016, different script created due to big DDL differences, see "MySQL_51x-55x" folder)
- Oracle MySQL 5.6.33 (on 16.09.2016)
- Oracle MySQL 5.7.15 (on 14.09.2016)
- Oracle MySQL 5.7.16 (on 07.11.2016)
- Oracle MySQL 8.0.0-dmr (on 15.09.2016)
- Oracle MySQL 8.0.11 (on 08.07.2018)
- MariaDB.org 5.5.52 (on 19.09.2016, different script created due to big DDL differences, see "MySQL_51x-55x" folder)
- MariaDB.org 10.0.27 (on 19.09.2016)
- MariaDB.org 10.1.17 (on 19.09.2016)
- MariaDB.org 10.2.1-alpha (on 19.09.2016)
