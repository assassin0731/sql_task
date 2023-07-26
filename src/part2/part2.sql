--------------------------------------------------------------------------------
-- Задание 2.1. Процедура добавленя P2P проверки
--------------------------------------------------------------------------------
-- Входные параметры: проверяющий пир, проверяемый пир, статус проверки, время проверки
--------------------------------------------------------------------------------
-- 1) Первым селектом находим самую последнюю подходящую проверку проверяющий пир-проверяемый пир-задание.
-- 2) Если такой проверки нет, но поданный в процедуру статус не 'Start', то ошибка
-- 3) Если такая проверка есть, но её статус совпадает с поданным в процедуру, то ошибка
-- 4) Если время завершения проверки раньше, чем время старта, то ошибка
-- 5) Если нет ошибки, заносим данные в таблицу/таблицы
--------------------------------------------------------------------------------
CREATE 
OR REPLACE PROCEDURE pr_add_p2p_check(
  checking_peer VARCHAR, checked_peer VARCHAR, 
  task VARCHAR, state check_status, 
  this_time TIME WITHOUT TIME ZONE
) LANGUAGE plpgsql AS $$ DECLARE check_state check_status;
prev_time TIME WITHOUT TIME ZONE;
find_error BOOL = false;
new_id BIGINT;
current_id BIGINT;
BEGIN IF checking_peer = checked_peer THEN RAISE EXCEPTION 'Peer cant check himself';
END IF;
SELECT 
  status, 
  time, 
  check_id INTO check_state, 
  prev_time, 
  current_id 
FROM 
  (
    SELECT 
      "CheckingPeer", 
      "Peer", 
      "State" AS status, 
      "Task", 
      "Date", 
      "Time" AS time, 
      checks."ID" AS check_id 
    FROM 
      p2p 
      JOIN checks ON p2p."Check" = checks."ID" 
    WHERE 
      "CheckingPeer" = checking_peer 
      AND "Peer" = checked_peer 
      AND "Task" = task 
    ORDER BY 
      "Date" DESC, 
      "Time" DESC 
    LIMIT 
      1
  ) AS one_line;
IF check_state IS NULL THEN IF state != 'Start' THEN RAISE NOTICE 'Cant finish check that hasnt started';
find_error = true;
END IF;
ELSEIF check_state = state THEN IF state = 'Start' THEN RAISE NOTICE 'Check is already started';
ELSE RAISE NOTICE 'Cant finish check that hasnt started';
END IF;
find_error = true;
ELSEIF (
  check_state = 'Start' 
  AND state != 'Start' 
  AND prev_time >= this_time
) THEN RAISE NOTICE 'Time of end cant be less or equal to time of start';
find_error = true;
END IF;
IF (
  find_error = false 
  AND state = 'Start'
) THEN INSERT INTO checks("Peer", "Task", "Date") 
VALUES 
  (checked_peer, task, NOW()) RETURNING "ID" INTO new_id;
INSERT INTO P2P(
  "Check", "CheckingPeer", "State", 
  "Time"
) 
VALUES 
  (
    new_id, checking_peer, state, this_time
  );
ELSEIF (find_error = false) THEN INSERT INTO P2P(
  "Check", "CheckingPeer", "State", 
  "Time"
) 
VALUES 
  (
    current_id, checking_peer, state, 
    this_time
  );
END IF;
END;
$$;

--------------------------------------------------------------------------------
-- Проверка
--------------------------------------------------------------------------------
-- Добавляем новую проверку и проверяем, что она добавилась
CALL pr_add_p2p_check(
  'ivanov', 'sokolov', 'C2_s21_stringplus', 
  'Start', '10:00'
);
SELECT 
  * 
FROM 
  P2P;
-- Пытаемся добавить такую же проверку и получаем ошибку, что проверка уже началась
CALL pr_add_p2p_check(
  'ivanov', 'sokolov', 'C2_s21_stringplus', 
  'Start', '10:00'
);
-- Пытаемся завершить раньше начала, получаем ошибку
CALL pr_add_p2p_check(
  'ivanov', 'sokolov', 'C2_s21_stringplus', 
  'Start', '10:00'
);
-- Завершаем проверку и проверяем, что завершение добавилось
CALL pr_add_p2p_check(
  'ivanov', 'sokolov', 'C2_s21_stringplus', 
  'Success', '10:30'
);
SELECT 
  * 
FROM 
  P2P;
-- Пытаемся завершить не начатую проверку, получаем ошибку
CALL pr_add_p2p_check(
  'ivanov', 'sokolov', 'C2_s21_stringplus', 
  'Success', '11:30'
);
--------------------------------------------------------------------------------
-- Задание 2.2. Процедура добавленя проверки Verter'ом
--------------------------------------------------------------------------------
-- Входные параметры: проверяемый пир, название задания, статус проверки, время
--------------------------------------------------------------------------------
-- 1) Сначала проверяем, существует ли такая P2P проверка
-- 2) Если проверки не существует, то ошибка
-- 3) Если проверка существует и в таблице проверки вертером уже есть 2 записи (то есть вертер уже начал и закончил свою проверку), то ошибка
-- 4) Если в таблице вертера одна запись и поданный статус 'Start' то ошибка, т.к. вертер уже начал проверку
-- 5) Если в таблице вертера нет записей и поданный статус не 'Start' то ошибка, т.к. вертер ещё не начал проверку
-- 6) Если время старта проверки вертером меньше, чем время завершения P2P проверки, то ошибка
-- 7) Если время завершения проверки вертером меньше, чем время старта проверки вертером, то ошибка
-- 8) Если ошибки нет, заносим данные в таблицу
--------------------------------------------------------------------------------
CREATE 
OR REPLACE PROCEDURE pr_add_verter_check(
  checked_peer VARCHAR, task VARCHAR, 
  state check_status, this_time TIME WITHOUT TIME ZONE
) LANGUAGE plpgsql AS $$ DECLARE find_error BOOL = false;
check_id BIGINT;
check_time TIME WITHOUT TIME ZONE;
verter_counter INT;
BEGIN 
SELECT 
  checks."ID", 
  "Time" INTO check_id, 
  check_time 
FROM 
  p2p 
  JOIN checks ON p2p."Check" = checks."ID" 
WHERE 
  "Peer" = checked_peer 
  AND "Task" = task 
  AND "State" = 'Success' 
ORDER BY 
  "Date" DESC, 
  "Time" DESC 
LIMIT 
  1;
IF check_id IS NOT NULL THEN 
SELECT 
  count(*) INTO verter_counter 
FROM 
  verter 
WHERE 
  verter."Check" = check_id;
IF verter_counter = 2 THEN RAISE NOTICE 'Verter had already checked this';
find_error = true;
ELSEIF (
  verter_counter = 1 
  AND state = 'Start'
) THEN RAISE NOTICE 'Verter had already started cheking';
find_error = true;
ELSEIF (
  verter_counter = 0 
  AND state != 'Start'
) THEN RAISE NOTICE 'Verter hasnt started this check yet';
find_error = true;
ELSEIF (
  state = 'Start' 
  AND check_time >= this_time
) THEN RAISE NOTICE 'P2P check time is less then verter time';
find_error = true;
ELSEIF (
  state != 'Start' 
  AND this_time <= (
    SELECT 
      "Time" 
    FROM 
      verter 
    WHERE 
      verter."Check" = check_id
  )
) THEN RAISE NOTICE 'Verter start checking time is less then end cheking time';
find_error = true;
END IF;
ELSE RAISE NOTICE 'No such P2P check';
find_error = true;
END IF;
IF (find_error = false) THEN INSERT INTO verter("Check", "State", "Time") 
VALUES 
  (check_id, state, this_time);
END IF;
END;
$$;
--------------------------------------------------------------------------------
-- Проверка
--------------------------------------------------------------------------------
-- Ошибка при попытке добавления не начавшейся проверки вертером
CALL pr_add_verter_check(
  'sokolov', 'C2_s21_stringplus', 'Success', 
  '11:30'
);
-- Ошибка при попытке добавления начала проверки вертером со временем меньше, чем завершение P2P проверки
CALL pr_add_verter_check(
  'sokolov', 'C2_s21_stringplus', 'Start', 
  '09:30'
);
-- Добавляем начало проверки вертером и проверяем
CALL pr_add_verter_check(
  'sokolov', 'C2_s21_stringplus', 'Start', 
  '11:30'
);
SELECT 
  * 
FROM 
  verter;
-- Ошибка при попытке завершения раньше, чем было начало
CALL pr_add_verter_check(
  'sokolov', 'C2_s21_stringplus', 'Success', 
  '11:00'
);
-- Добавляем завершение проверки вертером и проверяем
CALL pr_add_verter_check(
  'sokolov', 'C2_s21_stringplus', 'Success', 
  '11:35'
);
SELECT 
  * 
FROM 
  verter;
-- Ошибка при попытке добавления несуществующей P2P проверки
CALL pr_add_verter_check(
  'avtobus', 'C2_s21_stringplus', 'Start', 
  '11:35'
);
--------------------------------------------------------------------------------
-- Задание 2.3. Триггер изменения записи в таблице TransferredPoints просле добавления P2P проверки
--------------------------------------------------------------------------------
-- 1) Проверяем, что добавляемая запись в P2P это начало проверки
-- 2) Если это начало проверки, смотрим, есть ли уже в таблице с поинтами связка проверяющий пир-проверяемый пир
-- 3) Если запись есть, то обновляем её, увеличивая кол-во поинтов на 1
-- 4) Если записи нет, создаём новую, указывая 1 как кол-во поинтов
--------------------------------------------------------------------------------
CREATE 
OR REPLACE FUNCTION fnc_trg_insert_p2p_check() RETURNS trigger AS $$ DECLARE checking_peer VARCHAR;
checked_peer VARCHAR;
BEGIN 
SELECT 
  "CheckingPeer", 
  "Peer" INTO checking_peer, 
  checked_peer 
FROM 
  p2p 
  JOIN checks ON p2p."Check" = checks."ID" 
WHERE 
  p2p."ID" = NEW."ID" 
  AND "State" = 'Start';
IF checking_peer IS NOT NULL THEN IF EXISTS(
  SELECT 
    "CheckingPeer", 
    "CheckedPeer" 
  FROM 
    transferredpoints 
  WHERE 
    "CheckingPeer" = checking_peer 
    AND "CheckedPeer" = checked_peer
) THEN 
UPDATE 
  transferredpoints 
SET 
  "PointsAmount" = "PointsAmount" + 1 
WHERE 
  "CheckingPeer" = checking_peer 
  AND "CheckedPeer" = checked_peer;
ELSE INSERT INTO transferredpoints(
  "CheckingPeer", "CheckedPeer", "PointsAmount"
) 
VALUES 
  (checking_peer, checked_peer, 1);
END IF;
END IF;
RETURN NULL;
END;
$$ LANGUAGE plpgsql;
CREATE 
OR REPLACE TRIGGER trg_insert_p2p_check 
AFTER 
  INSERT ON p2p FOR EACH ROW EXECUTE PROCEDURE fnc_trg_insert_p2p_check();
--------------------------------------------------------------------------------
-- Проверка
--------------------------------------------------------------------------------
-- Смотрим таблицу с поинтами
SELECT 
  * 
FROM 
  TransferredPoints 
ORDER BY 
  1 DESC;
-- Добавляем две новые проверки
CALL pr_add_p2p_check(
  'ivanov', 'sokolov', 'C3_SimpleBashUtils', 
  'Start', '11:30'
);
CALL pr_add_p2p_check(
  'sokolov', 'ivanov', 'C3_SimpleBashUtils', 
  'Start', '12:30'
);
-- Проверяем, что к существуюей проверке добавилась 1, а так же добавилась новая запись
SELECT 
  * 
FROM 
  TransferredPoints 
ORDER BY 
  1 DESC;
-- Добавляем завершение проверки и смотрим, что в таблице с поинтами измененией не произошло
CALL pr_add_p2p_check(
  'sokolov', 'ivanov', 'C3_SimpleBashUtils', 
  'Success', '12:40'
);
SELECT 
  * 
FROM 
  TransferredPoints 
ORDER BY 
  1 DESC;
--------------------------------------------------------------------------------
-- Задание 2.4. Триггер проверки корректности данных перед добавлением записи в таблицу XP
--------------------------------------------------------------------------------
CREATE 
OR REPLACE FUNCTION fnc_trg_xp_corrections() RETURNS TRIGGER AS $xp_audit$ DECLARE max_xp INTEGER;
check_test VARCHAR;
BEGIN 
SELECT 
  "MaxXP" INTO max_xp 
FROM 
  tasks 
  JOIN checks ON checks."Task" = tasks."Title" 
WHERE 
  checks."ID" = NEW."Check";
SELECT 
  * INTO check_test 
FROM 
  checks 
  JOIN p2p ON p2p."Check" = checks."ID" 
  JOIN verter ON verter."Check" = checks."ID" 
WHERE 
  checks."ID" = NEW."Check" 
  AND p2p."State" = 'Success' 
  AND verter."State" = 'Success' 
LIMIT 
  1;
IF NEW."XPAmount" > max_xp THEN RAISE EXCEPTION 'The amount of XP exceeds the maximum allowed for this task';
ELSIF check_test IS NULL THEN RAISE EXCEPTION 'The Check field must reference a successful check';
END IF;
RETURN NEW;
END;
$xp_audit$ LANGUAGE plpgsql;
CREATE TRIGGER trg_xp_corrections BEFORE INSERT ON xp FOR EACH ROW EXECUTE FUNCTION fnc_trg_xp_corrections();
--------------------------------------------------------------------------------
-- Проверка
--------------------------------------------------------------------------------
--Данный INSERT должен сработать
INSERT INTO xp 
VALUES 
  (
    (
      SELECT 
        MAX("ID")+ 1 
      FROM 
        xp
    ), 
    8, 
    150
  );
--Данный INSERT должен вызвать ошибку переполнения по XP
INSERT INTO xp 
VALUES 
  (
    (
      SELECT 
        MAX("ID")+ 1 
      FROM 
        xp
    ), 
    8, 
    330
  );
