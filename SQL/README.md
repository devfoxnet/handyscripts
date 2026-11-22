# Useful MySQL/MariaDB Commands

#### SQL tuner
Nice CLI tool for doing basic tuning on SQL boxes: 
```bash
wget -O mysqltuner.pl mysqltuner.pl
perl mysqltuner.pl
```

#### Get users list:
`SELECT host, user, password FROM mysql.user;` 

#### Get storage engines used by tables in database
`SELECT TABLE_NAME, ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'database';`

#### Check replication on slave: 
`mysql -e "SHOW SLAVE STATUS\G" | grep Master`

#### Save processlist to file: 
`echo "SHOW FULL PROCESSLIST\G" | mysql > mysql_processes_$(date +%F).log`

#### Get DB sizes
```
SELECT table_schema "Database Name", sum( data_length + index_length ) / 1024 / 1024 "Database Size in MB" 
FROM information_schema.TABLES GROUP BY table_schema;
```

#### Create Wordpress admin account
Useful when access is needed to WP admin panels but you only have access to 

```SQL
INSERT INTO `<WPDBNAMEHERE>`.`wp_users` (`ID`, `user_login`, `user_pass`, `user_nicename`, `user_email`, `user_status`, `display_name`)
VALUES ('IDHERE', 'UserName', MD5('MakeASecurePassword'), 'NiceNameHere', 'support.team@mydomain.com', '0', 'NiceNameHere');

INSERT INTO `wp_usermeta` (`umeta_id`, `user_id`, `meta_key`, `meta_value`) VALUES (NULL, 'IDHERE', 'wp_capabilities', 'a:1:{s:13:"administrator";b:1;}');

INSERT INTO `wp_usermeta` (`umeta_id`, `user_id`, `meta_key`, `meta_value`) VALUES (NULL, 'IDHERE', 'wp_user_level', '10');
```
