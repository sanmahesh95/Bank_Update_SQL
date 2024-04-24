DELIMITER //
DROP PROCEDURE if EXISTS da790_project.sp_bank_update;
CREATE PROCEDURE da790_project.sp_bank_update()
 BEGIN
  

START TRANSACTION;

CREATE TABLE if not exists account
(
account_id int NOT NULL
,avail_balance int NOT NULL
,last_activity_date DATETIME
,PRIMARY KEY(account_id)
);

-- Below insert statements need to executed only once
#INSERT INTO account VALUES(123,500,'2019-07-10 20:53:27');
#INSERT INTO account VALUES(789,75,'2019-06-22 15:18:35');

SAVEPOINT data_inserted_account;

drop table if exists temp;
CREATE TABLE temp AS (SELECT * FROM account);


CREATE TABLE if not exists temp_account
(
account_id int NOT NULL
,previous_balance int NOT NULL
,avail_balance int NOT NULL
,txn_type_cd VARCHAR(10) NOT null
,last_activity_date DATETIME
,txn_date DATETIME
,PRIMARY KEY(account_id)
);

DELETE FROM temp_account;
INSERT INTO temp_account (account_id,previous_balance,avail_balance,txn_type_cd,last_activity_date,txn_date)
SELECT account_id
, avail_balance AS previous_balance
,avail_balance
,'Credited' AS txn_type_cd
,last_activity_date
,NOW() AS txn_date
FROM account;

SAVEPOINT data_inserted_temp_account;

UPDATE account
SET avail_balance =
	CASE WHEN account_id = 123 AND avail_balance >0 then avail_balance - 50
		WHEN account_id = 789 then avail_balance + 50
	END 
WHERE account_id IN (123,789);

SAVEPOINT data_updated_account;

UPDATE temp_account ta
INNER JOIN temp temp ON temp.account_id = ta.account_id
INNER JOIN account ON temp.account_id = account.account_id
SET 
    ta.account_id = temp.account_id,
    ta.previous_balance = temp.avail_balance,
    ta.avail_balance = account.avail_balance,
    ta.txn_type_cd = CASE WHEN account.avail_balance < temp.avail_balance THEN 'Debited' ELSE 'Credited' END,
    ta.last_activity_date = temp.last_activity_date,
    ta.txn_date = NOW()
WHERE ta.account_id IN (123, 789);

SAVEPOINT data_updated_temp_account;


-- can place rollback to test the data;
# ROLLBACK to SAVEPOINT data_updated_account;
COMMIT;

SELECT * FROM temp_account;
SELECT * FROM account;

 END;
//

DELIMITER ;

CALL sp_bank_update();

