CREATE DATABASE "TEST_INFO21" create table "TableName_person" (
  id bigint primary key, name varchar not null, 
  age integer not null default 10, gender varchar default 'female' not null, 
  address varchar
);
alter table 
  "TableName_person" 
add 
  constraint ch_gender check (
    gender in ('female', 'male')
  );
insert into "TableName_person" 
values 
  (1, 'Anna', 16, 'female', 'Moscow');
insert into "TableName_person" 
values 
  (2, 'Andrey', 21, 'male', 'Moscow');
insert into "TableName_person" 
values 
  (3, 'Kate', 33, 'female', 'Kazan');
insert into "TableName_person" 
values 
  (4, 'Denis', 13, 'male', 'Kazan');
insert into "TableName_person" 
values 
  (5, 'Elvira', 45, 'female', 'Kazan');
insert into "TableName_person" 
values 
  (
    6, 'Irina', 21, 'female', 'Saint-Petersburg'
  );
insert into "TableName_person" 
values 
  (
    7, 'Peter', 24, 'male', 'Saint-Petersburg'
  );
insert into "TableName_person" 
values 
  (
    8, 'Nataly', 30, 'female', 'Novosibirsk'
  );
insert into "TableName_person" 
values 
  (9, 'Dmitriy', 18, 'male', 'Samara');
create table "TableName_pizzeria" (
  id bigint primary key, name varchar not null, 
  rating numeric not null default 0
);
alter table 
  "TableName_pizzeria" 
add 
  constraint ch_rating check (
    rating between 0 
    and 5
  );
insert into "TableName_pizzeria" 
values 
  (1, 'Pizza Hut', 4.6);
insert into "TableName_pizzeria" 
values 
  (2, 'Dominos', 4.3);
insert into "TableName_pizzeria" 
values 
  (3, 'DoDo Pizza', 3.2);
insert into "TableName_pizzeria" 
values 
  (4, 'Papa Johns', 4.9);
insert into "TableName_pizzeria" 
values 
  (5, 'Best Pizza', 2.3);
insert into "TableName_pizzeria" 
values 
  (6, 'DinoPizza', 4.2);
create table "TableName_person_visits" (
  id bigint primary key, 
  person_id bigint not null, 
  pizzeria_id bigint not null, 
  visit_date date not null default current_date, 
  constraint uk_TableName_person_visits unique (
    person_id, pizzeria_id, visit_date
  ), 
  constraint fk_TableName_person_visits_person_id foreign key (person_id) references "TableName_person"(id), 
  constraint fk_TableName_person_visits_pizzeria_id foreign key (pizzeria_id) references "TableName_pizzeria"(id)
);
insert into "TableName_person_visits" 
values 
  (1, 1, 1, '2022-01-01');
insert into "TableName_person_visits" 
values 
  (2, 2, 2, '2022-01-01');
insert into "TableName_person_visits" 
values 
  (3, 2, 1, '2022-01-02');
insert into "TableName_person_visits" 
values 
  (4, 3, 5, '2022-01-03');
insert into "TableName_person_visits" 
values 
  (5, 3, 6, '2022-01-04');
insert into "TableName_person_visits" 
values 
  (6, 4, 5, '2022-01-07');
insert into "TableName_person_visits" 
values 
  (7, 4, 6, '2022-01-08');
insert into "TableName_person_visits" 
values 
  (8, 5, 2, '2022-01-08');
insert into "TableName_person_visits" 
values 
  (9, 5, 6, '2022-01-09');
insert into "TableName_person_visits" 
values 
  (10, 6, 2, '2022-01-09');
insert into "TableName_person_visits" 
values 
  (11, 6, 4, '2022-01-01');
insert into "TableName_person_visits" 
values 
  (12, 7, 1, '2022-01-03');
insert into "TableName_person_visits" 
values 
  (13, 7, 2, '2022-01-05');
insert into "TableName_person_visits" 
values 
  (14, 8, 1, '2022-01-05');
insert into "TableName_person_visits" 
values 
  (15, 8, 2, '2022-01-06');
insert into "TableName_person_visits" 
values 
  (16, 8, 4, '2022-01-07');
insert into "TableName_person_visits" 
values 
  (17, 9, 4, '2022-01-08');
insert into "TableName_person_visits" 
values 
  (18, 9, 5, '2022-01-09');
insert into "TableName_person_visits" 
values 
  (19, 9, 6, '2022-01-10');
create table "TableName_menu" (
  id bigint primary key, 
  pizzeria_id bigint not null, 
  pizza_name varchar not null, 
  price numeric not null default 1, 
  constraint fk_menu_pizzeria_id foreign key (pizzeria_id) references "TableName_pizzeria"(id)
);
insert into "TableName_menu" 
values 
  (1, 1, 'cheese pizza', 900);
insert into "TableName_menu" 
values 
  (2, 1, 'pepperoni pizza', 1200);
insert into "TableName_menu" 
values 
  (3, 1, 'sausage pizza', 1200);
insert into "TableName_menu" 
values 
  (4, 1, 'supreme pizza', 1200);
insert into "TableName_menu" 
values 
  (5, 6, 'cheese pizza', 950);
insert into "TableName_menu" 
values 
  (6, 6, 'pepperoni pizza', 800);
insert into "TableName_menu" 
values 
  (7, 6, 'sausage pizza', 1000);
insert into "TableName_menu" 
values 
  (8, 2, 'cheese pizza', 800);
insert into "TableName_menu" 
values 
  (9, 2, 'mushroom pizza', 1100);
insert into "TableName_menu" 
values 
  (10, 3, 'cheese pizza', 780);
insert into "TableName_menu" 
values 
  (11, 3, 'supreme pizza', 850);
insert into "TableName_menu" 
values 
  (12, 4, 'cheese pizza', 700);
insert into "TableName_menu" 
values 
  (13, 4, 'mushroom pizza', 950);
insert into "TableName_menu" 
values 
  (14, 4, 'pepperoni pizza', 1000);
insert into "TableName_menu" 
values 
  (15, 4, 'sausage pizza', 950);
insert into "TableName_menu" 
values 
  (16, 5, 'cheese pizza', 700);
insert into "TableName_menu" 
values 
  (17, 5, 'pepperoni pizza', 800);
insert into "TableName_menu" 
values 
  (18, 5, 'supreme pizza', 850);
create table "TableName_person_order" (
  id bigint primary key, 
  person_id bigint not null, 
  menu_id bigint not null, 
  order_date date not null default current_date, 
  constraint fk_order_person_id foreign key (person_id) references "TableName_person"(id), 
  constraint fk_order_menu_id foreign key (menu_id) references "TableName_menu"(id)
);
insert into "TableName_person_order" 
values 
  (1, 1, 1, '2022-01-01');
insert into "TableName_person_order" 
values 
  (2, 1, 2, '2022-01-01');
insert into "TableName_person_order" 
values 
  (3, 2, 8, '2022-01-01');
insert into "TableName_person_order" 
values 
  (4, 2, 9, '2022-01-01');
insert into "TableName_person_order" 
values 
  (5, 3, 16, '2022-01-04');
insert into "TableName_person_order" 
values 
  (6, 4, 16, '2022-01-07');
insert into "TableName_person_order" 
values 
  (7, 4, 17, '2022-01-07');
insert into "TableName_person_order" 
values 
  (8, 4, 18, '2022-01-07');
insert into "TableName_person_order" 
values 
  (9, 4, 6, '2022-01-08');
insert into "TableName_person_order" 
values 
  (10, 4, 7, '2022-01-08');
insert into "TableName_person_order" 
values 
  (11, 5, 6, '2022-01-09');
insert into "TableName_person_order" 
values 
  (12, 5, 7, '2022-01-09');
insert into "TableName_person_order" 
values 
  (13, 6, 13, '2022-01-01');
insert into "TableName_person_order" 
values 
  (14, 7, 3, '2022-01-03');
insert into "TableName_person_order" 
values 
  (15, 7, 9, '2022-01-05');
insert into "TableName_person_order" 
values 
  (16, 7, 4, '2022-01-05');
insert into "TableName_person_order" 
values 
  (17, 8, 8, '2022-01-06');
insert into "TableName_person_order" 
values 
  (18, 8, 14, '2022-01-07');
insert into "TableName_person_order" 
values 
  (19, 9, 18, '2022-01-09');
insert into "TableName_person_order" 
values 
  (20, 9, 6, '2022-01-10');
CREATE 
OR REPLACE FUNCTION fnc_test_1() RETURNS int AS $$ 
SELECT 
  1;
$$ LANGUAGE sql;
CREATE 
OR REPLACE FUNCTION fnc_test_2(var1 int, var2 int) RETURNS int AS $$ 
SELECT 
  1;
$$ LANGUAGE sql;
CREATE 
OR REPLACE FUNCTION fnc_test_3() RETURNS int AS $$ 
SELECT 
  1;
$$ LANGUAGE sql;
CREATE 
OR REPLACE FUNCTION fnc_test_4(var1 int, var2 int, var3 int) RETURNS int AS $$ 
SELECT 
  1;
$$ LANGUAGE sql;
CREATE TABLE test_table(
  "Nickname" VARCHAR UNIQUE PRIMARY KEY, 
  "Birthday" DATE NOT NULL DEFAULT CURRENT_DATE
);
CREATE TABLE test_table_2(
  "Nickname" VARCHAR UNIQUE PRIMARY KEY, 
  "Birthday" DATE NOT NULL DEFAULT CURRENT_DATE
);
CREATE 
OR REPLACE FUNCTION fnc_empty() RETURNS trigger AS $$ BEGIN RETURN 1;
END;
$$ LANGUAGE plpgsql;
CREATE 
OR REPLACE TRIGGER trg_first 
AFTER 
  INSERT 
  OR 
UPDATE 
  OR DELETE ON test_table FOR EACH ROW EXECUTE FUNCTION fnc_empty();
CREATE 
OR REPLACE TRIGGER trg_first 
AFTER 
  INSERT 
  OR 
UPDATE 
  OR DELETE ON test_table_2 FOR EACH ROW EXECUTE FUNCTION fnc_empty();
CREATE 
OR REPLACE TRIGGER trg_second BEFORE INSERT 
OR 
UPDATE 
  OR DELETE ON test_table FOR EACH ROW EXECUTE FUNCTION fnc_empty();
CREATE 
OR REPLACE TRIGGER trg_third 
AFTER 
  INSERT ON test_table FOR EACH ROW EXECUTE FUNCTION fnc_empty();
CREATE 
OR REPLACE TRIGGER trg_forth 
AFTER 
  INSERT 
  OR 
UPDATE 
  OR DELETE ON test_table_2 FOR EACH ROW EXECUTE FUNCTION fnc_empty();
CREATE 
OR REPLACE TRIGGER trg_fifth BEFORE INSERT ON test_table_2 FOR EACH ROW EXECUTE FUNCTION fnc_empty();
--------------------------------------------------------------------------------
-- Задание 4.1. Создать хранимую процедуру, которая, не уничтожая базу данных, 
-- уничтожает все те таблицы текущей базы данных, имена которых начинаются с фразы 'TableName'.
--------------------------------------------------------------------------------
CREATE 
OR REPLACE PROCEDURE drop_tables_with_prefix() LANGUAGE plpgsql AS $$ DECLARE table_name text;
BEGIN FOR table_name IN 
SELECT 
  tablename 
FROM 
  pg_tables 
WHERE 
  schemaname = 'public' 
  AND tablename LIKE 'TableName' || '%' LOOP EXECUTE 'DROP TABLE IF EXISTS "' || table_name || '" CASCADE;';
END LOOP;
END;
$$;
--------------------------------------------------------------------------------
-- Проверяем работу процедуры
--------------------------------------------------------------------------------
CALL drop_tables_with_prefix();
--------------------------------------------------------------------------------
-- Задание 4.2. Создать хранимую процедуру с выходным параметром, которая выводит список имен и параметров
-- всех скалярных SQL функций пользователя в текущей базе данных. Имена функций без параметров не выводить. 
-- Имена и список параметров должны выводиться в одну строку. Выходной параметр возвращает количество найденных функций.
--------------------------------------------------------------------------------
CREATE 
OR REPLACE PROCEDURE pcd_count_functions(
  ref REFCURSOR, OUT count_func INTEGER
) LANGUAGE plpgsql AS $$ BEGIN count_func := 0;
DROP 
  TABLE IF EXISTS task_4_2;
CREATE TEMP TABLE task_4_2 AS (
  SELECT 
    routines.routine_name AS name, 
    parameters.parameter_name AS type 
  FROM 
    information_schema.routines 
    LEFT JOIN information_schema.parameters ON routines.specific_name = parameters.specific_name 
  WHERE 
    routines.specific_schema = 'public' 
    AND routine_type = 'FUNCTION' 
  GROUP BY 
    routines.routine_name, 
    parameters.parameter_name
);
SELECT 
  count(*) INTO count_func 
FROM 
  (
    SELECT 
      name 
    FROM 
      task_4_2 
    GROUP BY 
      name
  ) AS func_names;
OPEN ref FOR 
SELECT 
  array_to_string(
    ARRAY(
      SELECT 
        name || ', ' || array_to_string(
          ARRAY(
            SELECT 
              a.type 
            FROM 
              task_4_2 a 
            WHERE 
              a.name = b.name
          ), 
          ', '
        ) 
      FROM 
        task_4_2 b 
      WHERE 
        type IS NOT NULL 
      GROUP BY 
        name
    ), 
    ' | '
  ) AS func_param;
END;
$$;
--------------------------------------------------------------------------------
-- Проверяем вывод процедуры
--------------------------------------------------------------------------------
DO $$ DECLARE task42 REFCURSOR = 'task42';
count_func INTEGER;
string TEXT;
BEGIN CALL pcd_count_functions(task42, count_func);
FETCH NEXT 
FROM 
  task42 INTO string;
RAISE NOTICE 'Number of functions: %', 
count_func;
RAISE NOTICE 'Functions and variables: %', 
string;
END;
$$;
--------------------------------------------------------------------------------
-- Задание 4.3. Создать хранимую процедуру с выходным параметром, которая уничтожает 
-- все SQL DML триггеры в текущей базе данных. Выходной параметр возвращает количество уничтоженных триггеров.
--------------------------------------------------------------------------------
CREATE 
OR REPLACE PROCEDURE pcd_drop_triggers(OUT trigger_count INTEGER) LANGUAGE plpgsql AS $$ DECLARE arow record;
BEGIN trigger_count := 0;
FOR arow IN 
SELECT 
  trigger_name, 
  event_object_table 
FROM 
  information_schema.triggers 
GROUP BY 
  trigger_name, 
  event_object_table LOOP EXECUTE 'DROP TRIGGER ' || arow.trigger_name || ' ON ' || arow.event_object_table || ';';
trigger_count = trigger_count + 1;
END LOOP;
END;
$$;
--------------------------------------------------------------------------------
-- Проверяем работу процедуры
--------------------------------------------------------------------------------
SELECT 
  event_object_table, 
  trigger_name 
FROM 
  information_schema.triggers 
GROUP BY 
  trigger_name, 
  event_object_table;
DO $$ DECLARE trigger_count INTEGER;
BEGIN CALL pcd_drop_triggers(trigger_count);
RAISE NOTICE 'Triggers deleted: %', 
trigger_count;
END;
$$;
SELECT 
  event_object_table, 
  trigger_name 
FROM 
  information_schema.triggers 
GROUP BY 
  trigger_name, 
  event_object_table;
--------------------------------------------------------------------------------
-- Задание 4.4. Создать хранимую процедуру с входным параметром, которая выводит имена и описания типа объектов 
-- (только хранимых процедур и скалярных функций), в тексте которых на языке SQL встречается строка, задаваемая 
-- параметром процедуры.
--------------------------------------------------------------------------------
CREATE 
OR REPLACE PROCEDURE prc_obj_names_info(search_string TEXT) LANGUAGE plpgsql AS $$ DECLARE obj_name TEXT;
obj_type TEXT;
BEGIN FOR obj_name, 
obj_type IN 
SELECT 
  routine_name AS obj_name, 
  routine_type AS obj_type 
FROM 
  information_schema.routines 
WHERE 
  routine_definition ILIKE '%' || search_string || '%' -- If the function is an SQL function, then SQL, else EXTERNAL.
  AND routine_body = 'SQL' 
  AND (
    routine_type = 'FUNCTION' 
    OR routine_type = 'PROCEDURE'
  ) LOOP RAISE NOTICE 'Object name: %, Object type: %', 
  obj_name, 
  obj_type;
END LOOP;
END;
$$;
--------------------------------------------------------------------------------
-- Проверяем вывод процедуры
--------------------------------------------------------------------------------
DO $$ BEGIN 
SET 
  client_min_messages = 'INFO';
CALL prc_obj_names_info('select');
END;
$$;
