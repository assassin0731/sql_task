-- Создание таблиц БД
CREATE TYPE check_status AS ENUM ('Start', 'Success', 'Failure');
CREATE TABLE Peers(
  "Nickname" VARCHAR UNIQUE PRIMARY KEY, 
  "Birthday" DATE NOT NULL DEFAULT CURRENT_DATE
);
CREATE TABLE Tasks(
  "Title" VARCHAR PRIMARY KEY, 
  "ParentTask" VARCHAR, 
  "MaxXP" BIGINT NOT NULL, 
  CONSTRAINT fk_tasks_parent_task FOREIGN KEY ("ParentTask") REFERENCES Tasks("Title")
);
CREATE TABLE Checks(
  "ID" SERIAL PRIMARY KEY, 
  "Peer" VARCHAR NOT NULL, 
  "Task" VARCHAR NOT NULL, 
  "Date" DATE NOT NULL DEFAULT CURRENT_DATE, 
  CONSTRAINT fk_checks_peer FOREIGN KEY ("Peer") REFERENCES Peers("Nickname"), 
  CONSTRAINT fk_checks_task FOREIGN KEY ("Task") REFERENCES Tasks("Title")
);
CREATE TABLE P2P(
  "ID" SERIAL PRIMARY KEY, 
  "Check" BIGINT NOT NULL, 
  "CheckingPeer" VARCHAR NOT NULL, 
  "State" check_status NOT NULL, 
  "Time" TIME WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIME, 
  CONSTRAINT fk_p2p_check FOREIGN KEY ("Check") REFERENCES Checks("ID"), 
  CONSTRAINT fk_p2p_checking_peer FOREIGN KEY ("CheckingPeer") REFERENCES Peers("Nickname")
);
CREATE TABLE Verter(
  "ID" SERIAL PRIMARY KEY, 
  "Check" BIGINT NOT NULL, 
  "State" check_status NOT NULL, 
  "Time" TIME WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIME, 
  CONSTRAINT fk_verter_check FOREIGN KEY ("Check") REFERENCES Checks("ID")
);
CREATE TABLE TransferredPoints(
  "ID" SERIAL PRIMARY KEY, 
  "CheckingPeer" VARCHAR NOT NULL, 
  "CheckedPeer" VARCHAR NOT NULL, 
  "PointsAmount" INT NOT NULL, 
  CONSTRAINT fk_transferred_points_checking_peer FOREIGN KEY ("CheckingPeer") REFERENCES Peers("Nickname"), 
  CONSTRAINT fk_transferred_points_checked_peer FOREIGN KEY ("CheckedPeer") REFERENCES Peers("Nickname")
);
CREATE TABLE Friends(
  "ID" SERIAL PRIMARY KEY, 
  "Peer1" VARCHAR NOT NULL, 
  "Peer2" VARCHAR NOT NULL, 
  CONSTRAINT fk_friends_peer1 FOREIGN KEY ("Peer1") REFERENCES Peers("Nickname"), 
  CONSTRAINT fk_friends_peer2 FOREIGN KEY ("Peer2") REFERENCES Peers("Nickname")
);
CREATE TABLE Recommendations(
  "ID" SERIAL PRIMARY KEY, 
  "Peer" VARCHAR NOT NULL, 
  "RecommendedPeer" VARCHAR NOT NULL, 
  CONSTRAINT fk_recommendations_peer FOREIGN KEY ("Peer") REFERENCES Peers("Nickname"), 
  CONSTRAINT fk_recommendations_recommended_peer FOREIGN KEY ("RecommendedPeer") REFERENCES Peers("Nickname")
);
CREATE TABLE XP(
  "ID" SERIAL PRIMARY KEY, 
  "Check" BIGINT NOT NULL, 
  "XPAmount" INT NOT NULL, 
  CONSTRAINT fk_xp_check FOREIGN KEY ("Check") REFERENCES Checks("ID")
);
CREATE TABLE TimeTracking(
  "ID" SERIAL PRIMARY KEY, 
  "Peer" VARCHAR NOT NULL, 
  "Date" DATE NOT NULL DEFAULT CURRENT_DATE, 
  "Time" TIME WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIME, 
  "State" INT NOT NULL, 
  CONSTRAINT ch_time_tracking_state CHECK (
    "State" IN (1, 2)
  ), 
  CONSTRAINT fk_time_tracking_peer FOREIGN KEY ("Peer") REFERENCES Peers("Nickname")
);
-- Процедура импорта данных из файла
CREATE 
OR REPLACE PROCEDURE pr_import(
  table_ VARCHAR, 
  path VARCHAR, 
  delim VARCHAR(1)
) LANGUAGE plpgsql AS $$ DECLARE schema TEXT = (
  SELECT 
    "current_schema"()
);
BEGIN EXECUTE 'COPY ' || table_ || ' FROM ''' || path || ''' DELIMITER ''' || delim || ''' CSV HEADER';
IF EXISTS(
  SELECT 
    column_name 
  FROM 
    information_schema.columns 
  WHERE 
    table_schema = schema 
    AND table_name = table_ 
    AND column_name = 'ID'
) THEN EXECUTE 'SELECT setval(''"' || table_ || '_ID_seq"'', (SELECT max("ID")+1 FROM ' || table_ || '), false)';
END IF;
END $$;
-- Процедура экспорта данных в файл
CREATE 
OR REPLACE PROCEDURE pr_export(
  table_name VARCHAR, 
  path VARCHAR, 
  delim VARCHAR(1)
) LANGUAGE plpgsql AS $$ BEGIN EXECUTE 'COPY ' || table_name || ' TO ''' || path || ''' DELIMITER ''' || delim || ''' CSV HEADER';
END $$;
-- Задание путей до файлов с экспортом/импорторм, нужно указать свой путь
-- Так же может потребоваться дать права на чтение запись 'chmod a+rwX' для всех папок по пути от '/home/username/' до '/export(import)'
SET 
  import_path.var TO '/Users/ps/Projects/SQL2_Info21_v1.0-1/src/import/';
-- Вызов процедур импорта
CALL pr_import(
  'peers', 
  current_setting('import_path.var') || 'peers.csv', 
  ','
);
CALL pr_import(
  'friends', 
  current_setting('import_path.var') || 'friends.csv', 
  ','
);
CALL pr_import(
  'recommendations', 
  current_setting('import_path.var') || 'recommendations.csv', 
  ','
);
CALL pr_import(
  'TimeTracking', 
  current_setting('import_path.var') || 'time_tracking.csv', 
  ','
);
CALL pr_import(
  'transferredpoints', 
  current_setting('import_path.var') || 'transferred_points.csv', 
  ','
);
CALL pr_import(
  'tasks', 
  current_setting('import_path.var') || 'tasks.csv', 
  ','
);
CALL pr_import(
  'checks', 
  current_setting('import_path.var') || 'checks.csv', 
  ','
);
CALL pr_import(
  'p2p', 
  current_setting('import_path.var') || 'p2p.csv', 
  ','
);
CALL pr_import(
  'verter', 
  current_setting('import_path.var') || 'verter.csv', 
  ','
);
CALL pr_import(
  'xp', 
  current_setting('import_path.var') || 'xp.csv', 
  ','
);
-- Задание путей до файлов с экспортом, нужно указать свой путь
SET 
  export_path.var TO '/home/kerenhor/SQL2_Info21_v1.0-1/src/export/';
-- Вызов процедур экспорта
CALL pr_export(
  'peers', 
  current_setting('export_path.var') || 'peers.csv', 
  ','
);
CALL pr_export(
  'friends', 
  current_setting('export_path.var') || 'friends.csv', 
  ','
);
CALL pr_export(
  'recommendations', 
  current_setting('export_path.var') || 'recommendations.csv', 
  ','
);
CALL pr_export(
  'TimeTracking', 
  current_setting('export_path.var') || 'time_tracking.csv', 
  ','
);
CALL pr_export(
  'transferredpoints', 
  current_setting('export_path.var') || 'transferred_points.csv', 
  ','
);
CALL pr_export(
  'tasks', 
  current_setting('export_path.var') || 'tasks.csv', 
  ','
);
CALL pr_export(
  'checks', 
  current_setting('export_path.var') || 'checks.csv', 
  ','
);
CALL pr_export(
  'P2P', 
  current_setting('export_path.var') || 'P2P.csv', 
  ','
);
CALL pr_export(
  'verter', 
  current_setting('export_path.var') || 'verter.csv', 
  ','
);
CALL pr_export(
  'XP', 
  current_setting('export_path.var') || 'XP.csv', 
  ','
);
