--------------------------------------------------------------------------------
-- Задание 3.1. Функция, возвращающая таблицу TransferredPoints в более человекочитаемом виде
--------------------------------------------------------------------------------
CREATE 
OR REPLACE FUNCTION fnc_transferred_points() RETURNS TABLE (
  "Peer1" VARCHAR, "Peer2" VARCHAR, "PointsAmount" BIGINT
) AS $TP_function$ WITH cte1 AS (
  SELECT 
    DISTINCT CASE WHEN t1."CheckingPeer" < t1."CheckedPeer" THEN t1."CheckingPeer" ELSE t1."CheckedPeer" END AS "Peer1", 
    CASE WHEN t1."CheckingPeer" > t1."CheckedPeer" THEN t1."CheckingPeer" ELSE t1."CheckedPeer" END AS "Peer2" 
  FROM 
    transferredpoints t1 
    LEFT JOIN transferredpoints t2 ON t1."CheckingPeer" = t2."CheckedPeer" 
    AND t1."CheckedPeer" = t2."CheckingPeer" 
  GROUP BY 
    CASE WHEN t1."CheckingPeer" < t1."CheckedPeer" THEN t1."CheckingPeer" ELSE t1."CheckedPeer" END, 
    CASE WHEN t1."CheckingPeer" > t1."CheckedPeer" THEN t1."CheckingPeer" ELSE t1."CheckedPeer" END 
  ORDER BY 
    "Peer1", 
    "Peer2"
) 
select 
  "Peer1", 
  "Peer2", 
  COALESCE(
    (
      SELECT 
        "PointsAmount" 
      FROM 
        transferredpoints 
      where 
        "CheckedPeer" = cte1."Peer1" 
        AND "CheckingPeer" = cte1."Peer2"
    ), 
    0
  ) - COALESCE(
    (
      SELECT 
        "PointsAmount" 
      FROM 
        transferredpoints 
      WHERE 
        "CheckingPeer" = cte1."Peer1" 
        AND "CheckedPeer" = cte1."Peer2"
    ), 
    0
  ) AS "PointsAmount" 
FROM 
  cte1;
$TP_function$ LANGUAGE sql;
--------------------------------------------------------------------------------
-- Проверяем вывод функции
--------------------------------------------------------------------------------
select 
  * 
from 
  fnc_transferred_points();
--------------------------------------------------------------------------------
-- Задание 3.2. Функция, которая возвращает таблицу вида: ник пользователя, название проверенного задания, 
-- кол-во полученного XP
--------------------------------------------------------------------------------
CREATE 
OR REPLACE FUNCTION fnc_xp_amount() RETURNS TABLE (
  "Peer" VARCHAR, "Task" VARCHAR, "XP" INTEGER
) AS $xp_amount$ 
select 
  "Peer", 
  "Task", 
  "XPAmount" AS "XP" 
From 
  checks 
  RIGHT JOIN xp ON checks."ID" = xp."Check" $xp_amount$ LANGUAGE sql --------------------------------------------------------------------------------
  -- Проверяем вывод функции
  --------------------------------------------------------------------------------
select 
  * 
from 
  fnc_xp_amount();
--------------------------------------------------------------------------------
-- Задание 3.3. Функция, определяющая пиров, которые не выходили из кампуса в течение всего дня
--------------------------------------------------------------------------------
CREATE 
OR REPLACE FUNCTION fnc_peer_leaved(dates DATE) RETURNS TABLE("Peer" VARCHAR) AS $$ BEGIN RETURN QUERY 
SELECT 
  timetracking."Peer" as p 
FROM 
  timetracking 
WHERE 
  "Date" = dates 
  AND "State" = 1 
GROUP BY 
  p 
HAVING 
  COUNT("State")= 1;
END;
$$ LANGUAGE plpgsql;
--------------------------------------------------------------------------------
-- Проверяем вывод функции
--------------------------------------------------------------------------------
SELECT 
  * 
FROM 
  fnc_peer_leaved('2023-03-03');
--------------------------------------------------------------------------------
-- Задание 3.4. Изменение в количестве пир поинтов каждого пира по таблице TransferredPoints
--------------------------------------------------------------------------------
CREATE 
OR REPLACE PROCEDURE prc_transferred_points_change(ref REFCURSOR) AS $$ BEGIN OPEN ref FOR 
SELECT 
  p."Nickname" AS Peer, 
  p.total - m.total AS PointsChange 
FROM 
  (
    (
      SELECT 
        Peers."Nickname", 
        SUM(
          COALESCE(tp."PointsAmount", 0)
        ) AS total 
      FROM 
        Peers 
        LEFT JOIN transferredpoints AS tp ON tp."CheckingPeer" = Peers."Nickname" 
      GROUP BY 
        Peers."Nickname"
    ) AS p 
    JOIN (
      SELECT 
        Peers."Nickname", 
        SUM(
          COALESCE(tp."PointsAmount", 0)
        ) AS total 
      FROM 
        Peers 
        LEFT JOIN TransferredPoints AS tp ON tp."CheckedPeer" = Peers."Nickname" 
      GROUP BY 
        Peers."Nickname"
    ) AS m ON p."Nickname" = m."Nickname"
  ) 
ORDER BY 
  2 DESC;
END;
$$ LANGUAGE plpgsql;
--------------------------------------------------------------------------------
-- Проверяем вывод процедуры
--------------------------------------------------------------------------------
CALL prc_transferred_points_change('task3_4');
FETCH ALL IN task3_4;
--------------------------------------------------------------------------------
-- Задание 3.5. Изменение в количестве пир поинтов каждого пира по таблице, возвращаемой функцией 3.1
--------------------------------------------------------------------------------
CREATE 
OR REPLACE PROCEDURE pcd_func_points_change(ref REFCURSOR) LANGUAGE plpgsql AS $$ BEGIN OPEN ref FOR 
SELECT 
  "Nickname" AS "Peer", 
  (
    SELECT 
      COALESCE(
        SUM("PointsAmount"), 
        0
      ) 
    FROM 
      fnc_transferred_points() 
    WHERE 
      "Peer2" = peers."Nickname"
  ) -(
    SELECT 
      COALESCE(
        SUM("PointsAmount"), 
        0
      ) 
    FROM 
      fnc_transferred_points() 
    WHERE 
      "Peer1" = peers."Nickname"
  ) AS "PointsChange" 
FROM 
  peers 
ORDER BY 
  2 DESC;
END $$;
--------------------------------------------------------------------------------
-- Проверяем вывод процедуры
--------------------------------------------------------------------------------
CALL pcd_func_points_change('task3_5');
FETCH ALL IN task3_5;
--------------------------------------------------------------------------------
-- Задание 3.6. Cамое часто проверяемое задание за каждый день
--------------------------------------------------------------------------------
CREATE 
OR REPLACE PROCEDURE prc_often_task(ref REFCURSOR) AS $$ BEGIN OPEN ref FOR WITH cte_1 AS (
  SELECT 
    checks."Date" AS dat, 
    checks."Task" AS task, 
    COUNT(*) AS cou 
  FROM 
    checks 
  GROUP BY 
    checks."Date", 
    checks."Task"
), 
cte_2 AS (
  SELECT 
    temp.dat AS dat2, 
    MAX(cou) AS max 
  FROM 
    cte_1 AS temp 
  GROUP BY 
    dat
) 
SELECT 
  TO_CHAR(dat, 'DD.MM.YYYY') AS "Day", 
  task AS "Task" 
FROM 
  cte_1 
  LEFT JOIN cte_2 ON dat2 = dat 
WHERE 
  max = cou 
ORDER BY 
  1;
END;
$$ LANGUAGE plpgsql;
--------------------------------------------------------------------------------
-- Проверяем вывод процедуры
--------------------------------------------------------------------------------
CALL prc_often_task('task3_6');
FETCH ALL IN task3_6;
--------------------------------------------------------------------------------
-- Задание 3.7. Все пиры, выполнившие весь заданный блок задач и дата завершения последнего задания
--------------------------------------------------------------------------------
CREATE 
OR REPLACE PROCEDURE prc_block_graduated(ref REFCURSOR, blocks VARCHAR) AS $$ BEGIN OPEN ref FOR WITH cpe_1 AS (
  SELECT 
    "Peer" peer, 
    "Task", 
    "Date" dat 
  FROM 
    checks 
    RIGHT JOIN xp ON "Check" = checks."ID" 
  WHERE 
    checks."Task" ~ ('^' || blocks || '[0-9]') 
  ORDER BY 
    1, 
    2
) 
SELECT 
  peer AS "Peer", 
  to_char(
    MAX(dat), 
    'DD.MM.YYYY'
  ) "Day" 
FROM 
  cpe_1 
GROUP BY 
  peer 
HAVING 
  COUNT("Task")=(
    SELECT 
      COUNT("Title") 
    FROM 
      tasks 
    WHERE 
      tasks."Title" ~ ('^' || blocks || '[0-9]')
  ) 
ORDER BY 
  2;
END;
$$ LANGUAGE plpgsql;
--------------------------------------------------------------------------------
-- Проверяем вывод процедуры
--------------------------------------------------------------------------------
CALL prc_block_graduated('task3_7', 'C');
FETCH ALL IN task3_7;
--------------------------------------------------------------------------------
-- Задание 3.8. К какому пиру стоит идти на проверку каждому обучающемуся
--------------------------------------------------------------------------------
-- 1) В all_friends получаем таблицу со всеми друзьями каждого пира
-- 2) Джойним таблицу с рекоммендациями, добавляем каждому пиру тех, кого рекомендуют друзья пира. Группируем для подсчёта количества рекоммендаций каждого пира
-- 3) Сортируем кол-во по убыванию и для каждого пира оставляем одну строку с самым максимальным кол-вом рекоммендаций
--------------------------------------------------------------------------------
CREATE PROCEDURE pr_peer_friend_reccomends(ref REFCURSOR) LANGUAGE plpgsql AS $$ BEGIN OPEN ref FOR 
SELECT 
  "Nickname" AS "Peer", 
  "RecommendedPeer" 
FROM 
  (
    WITH table1 AS (
      SELECT 
        "Peer1", 
        "RecommendedPeer", 
        count(*) 
      FROM 
        (
          SELECT 
            DISTINCT "Peer1", 
            peers."Nickname" 
          FROM 
            friends 
            JOIN peers ON peers."Nickname" = friends."Peer2" 
          UNION 
          SELECT 
            DISTINCT "Peer2", 
            peers."Nickname" 
          FROM 
            friends 
            JOIN peers ON peers."Nickname" = friends."Peer1"
        ) AS all_friends 
        JOIN (
          SELECT 
            DISTINCT * 
          FROM 
            recommendations
        ) AS recommend ON "Nickname" = "Peer" 
      WHERE 
        "Peer1" != "RecommendedPeer" 
      GROUP BY 
        "Peer1", 
        "RecommendedPeer" 
      ORDER BY 
        "Peer1", 
        count DESC, 
        "RecommendedPeer"
    ) 
    SELECT 
      DISTINCT a1."Peer1", 
      (
        SELECT 
          "RecommendedPeer" 
        FROM 
          table1 
        WHERE 
          a1."Peer1" = table1."Peer1" 
        LIMIT 
          1
      ) 
    FROM 
      table1 a1
  ) AS table2 
  RIGHT JOIN peers ON "Nickname" = "Peer1" 
ORDER BY 
  "Peer";
END $$;
--------------------------------------------------------------------------------
-- Проверяем вывод процедуры
--------------------------------------------------------------------------------
CALL pr_peer_friend_reccomends('task8');
FETCH ALL 
FROM 
  task8;
--------------------------------------------------------------------------------
-- Задание 3.9. Процент пиров которые: приступили только к блоку 1, приступили только к блоку 2, приступили к обоим, не приступили ни к одному
--------------------------------------------------------------------------------
-- Входные данные: блок 1, блок 2
--------------------------------------------------------------------------------
-- 1) Считаем общее количество пиров
-- 2) Создаем 4 таблицы с пирами, которые приступили только к блоку 1, приступили только к блоку 2, приступили к обоим, не приступили ни к одному
-- 3) С помощью созданных таблиц и общего кол-ва пиров, подсчитываем процентное кол-во пиров для каждой таблицы
--------------------------------------------------------------------------------
CREATE 
OR REPLACE PROCEDURE pr_peer_percent_blocks(
  ref REFCURSOR, block1 VARCHAR, block2 VARCHAR
) LANGUAGE plpgsql AS $$ DECLARE peer_amount int = (
  SELECT 
    count(*) 
  FROM 
    peers
);
BEGIN OPEN ref FOR WITH table_block1 AS (
  SELECT 
    DISTINCT "Peer" 
  FROM 
    checks 
  WHERE 
    "Task" LIKE block1 || '%'
), 
table_block2 AS (
  SELECT 
    DISTINCT "Peer" 
  FROM 
    checks 
  WHERE 
    "Task" LIKE block2 || '%'
), 
table_both AS (
  SELECT 
    * 
  FROM 
    table_block1 
  INTERSECT 
  SELECT 
    * 
  FROM 
    table_block2
), 
table_nothing AS (
  SELECT 
    "Nickname" 
  FROM 
    peers 
  EXCEPT 
    (
      SELECT 
        * 
      FROM 
        table_block1 
      UNION 
      SELECT 
        * 
      FROM 
        table_block2
    )
) 
SELECT 
  ROUND(
    (
      (
        SELECT 
          count(*) 
        FROM 
          table_block1
      ) / peer_amount :: REAL
    )* 100
  ) AS "StartedBlock1", 
  ROUND(
    (
      (
        SELECT 
          count(*) 
        FROM 
          table_block2
      ) / peer_amount :: REAL
    )* 100
  ) AS "StartedBlock2", 
  ROUND(
    (
      (
        SELECT 
          count(*) 
        FROM 
          table_both
      ) / peer_amount :: REAL
    )* 100
  ) AS "StartedBothBlocks", 
  ROUND(
    (
      (
        SELECT 
          count(*) 
        FROM 
          table_nothing
      ) / peer_amount :: REAL
    )* 100
  ) AS "DidntStartAnyBlock";
END $$;
--------------------------------------------------------------------------------
-- Проверяем вывод процедуры
--------------------------------------------------------------------------------
CALL pr_peer_percent_blocks('task9', 'D', 'C');
FETCH ALL 
FROM 
  task9;
CALL pr_peer_percent_blocks('task9', 'SQL', 'D');
FETCH ALL 
FROM 
  task9;
CALL pr_peer_percent_blocks('task9', 'SQL', 'C');
FETCH ALL 
FROM 
  task9;
--------------------------------------------------------------------------------
-- Задание 3.10. Процент пиров, которые когда-либо успешно проходили проверку в свой день рождения
--------------------------------------------------------------------------------
CREATE 
OR REPLACE PROCEDURE pcd_birthday_checks_percent(ref REFCURSOR) LANGUAGE plpgsql AS $$ BEGIN OPEN ref FOR 
select 
  COALESCE(
    ROUND(
      (
        COUNT(
          CASE WHEN p2p."State" = 'Success' 
          AND (
            verter."State" = 'Success' 
            OR verter."State" IS NULL
          ) THEN p2p."State" END
        ):: numeric / NULLIF(
          COUNT(
            CASE WHEN (
              (
                p2p."State" = 'Success' 
                OR p2p."State" = 'Failure'
              ) 
              AND (
                verter."State" = 'Success' 
                OR verter."State" = 'Failure' 
                OR verter."State" IS NULL
              )
            ) THEN p2p."State" END
          ), 
          0
        ):: numeric
      )* 100, 
      0
    ), 
    0
  ) AS "SuccessfulChecks", 
  COALESCE(
    ROUND(
      (
        1 - COUNT(
          CASE WHEN p2p."State" = 'Success' 
          AND (
            verter."State" = 'Success' 
            OR verter."State" IS NULL
          ) THEN p2p."State" END
        ):: numeric / NULLIF(
          COUNT(
            CASE WHEN (
              (
                p2p."State" = 'Success' 
                OR p2p."State" = 'Failure'
              ) 
              AND (
                verter."State" = 'Success' 
                OR verter."State" = 'Failure' 
                OR verter."State" IS NULL
              )
            ) THEN p2p."State" END
          ), 
          0
        ):: numeric
      )* 100, 
      0
    ), 
    0
  ) AS "UnsuccessfulChecks" 
from 
  checks 
  INNER JOIN peers ON date_part('month', peers."Birthday")= date_part('month', checks."Date") 
  AND date_part('day', peers."Birthday")= date_part('day', checks."Date") 
  AND peers."Nickname" = checks."Peer" 
  LEFT JOIN verter ON checks."ID" = verter."Check" 
  LEFT JOIN p2p ON checks."ID" = p2p."Check" 
  AND (
    p2p."State" = 'Success' 
    OR p2p."State" = 'Failure'
  );
END $$;
--------------------------------------------------------------------------------
-- Проверяем вывод процедуры
--------------------------------------------------------------------------------
call pcd_birthday_checks_percent('task3_10');
fetch all in task3_10;
--------------------------------------------------------------------------------
-- Задание 3.11. Все пиры, которые сдали заданные задания 1 и 2, но не сдали задание 3
--------------------------------------------------------------------------------
CREATE 
OR REPLACE PROCEDURE prc_tasks_check(
  ref REFCURSOR, task1 text, task2 text, 
  task3 text
) LANGUAGE plpgsql AS $$ BEGIN OPEN ref FOR 
Select 
  ARRAY_AGG ("Peer") as peer 
FROM 
  (
    SELECT 
      checks."Peer" 
    FROM 
      checks 
      RIGHT JOIN xp ON checks."ID" = xp."Check" 
    WHERE 
      checks."Task" = task1 
    INTERSECT 
    SELECT 
      checks."Peer" 
    FROM 
      checks 
      RIGHT JOIN xp ON checks."ID" = xp."Check" 
    WHERE 
      checks."Task" = task2 
    EXCEPT 
    SELECT 
      checks."Peer" 
    FROM 
      checks 
      RIGHT JOIN xp ON checks."ID" = xp."Check" 
    WHERE 
      checks."Task" = task3
  ) AS temptable;
END;
$$;
--------------------------------------------------------------------------------
-- Проверяем вывод процедуры
--------------------------------------------------------------------------------
CALL prc_tasks_check(
  'task3_11', 'FirstTask', 'SecondTask', 
  'ThirdTask'
);
FETCH ALL IN task3_11;
--------------------------------------------------------------------------------
-- Задание 3.12. Для каждой задачи кол-во предшествующих ей задач
--------------------------------------------------------------------------------
-- 1) Рекурсивно для каждого задания берем само задание и родительское задание (если оно не NULL)
-- 2) Получаем в 1м столбце название одного задания несколько раз, в зависимости от того, сколько у него предшествующих
-- 3) Группируем полученную таблицу по названию заданий и получаем количество предшествующих для каждого задания
-- 4) Джойним полученную таблицу к таблице с названиями заданий. Если в полученной отсуствует название задания, то у задания нет предшествующих, указываем 0
--------------------------------------------------------------------------------
CREATE 
OR REPLACE PROCEDURE pr_need_task_count(ref REFCURSOR) LANGUAGE plpgsql AS $$ BEGIN OPEN ref FOR WITH RECURSIVE table1 AS (
  SELECT 
    "Title" AS title, 
    "Title", 
    "ParentTask" 
  FROM 
    tasks 
  WHERE 
    "ParentTask" IS NOT NULL 
  UNION 
  SELECT 
    table1.title AS title, 
    tasks."Title", 
    tasks."ParentTask" 
  FROM 
    tasks 
    JOIN table1 on table1."ParentTask" = tasks."Title" 
  WHERE 
    tasks."ParentTask" IS NOT NULL
) 
SELECT 
  "Title" AS "Task", 
  coalesce(count, 0) AS "PrevCount" 
FROM 
  (
    SELECT 
      title, 
      count(*) 
    FROM 
      table1 
    GROUP BY 
      title
  ) AS table2 
  RIGHT JOIN tasks ON title = "Title" 
ORDER BY 
  "Task", 
  "PrevCount";
END $$;
--------------------------------------------------------------------------------
-- Проверяем вывод процедуры
--------------------------------------------------------------------------------
CALL pr_need_task_count('task12');
FETCH ALL 
FROM 
  task12;
--------------------------------------------------------------------------------
-- Задание 3.13. "Удачные" для проверок дни. День считается "удачным", если в нем есть хотя бы N идущих подряд успешных проверки
--------------------------------------------------------------------------------
-- Входной параметр: кол-во идущих подряд удачных проверок
--------------------------------------------------------------------------------
-- 1) Если входной параметр 0, то просто возвращаем все даты
-- 2) В p2p_start создаем таблицу со стартами проверок
-- 3) Накладываем условия удачной проверки, опыт больше 80% от максимального
-- 4) Джойним к полученной таблице несколько других таблиц и сортируем по дате, времени и статусу проверки. Имеем столбец с 0, если не удачная проверка и 1 если удачная
-- 5) Дальше по столбцу даты столбец с удачной/неудачной проверкой суммируется и получаем кол-во удачных проверок подряд
-- 6) Сравниваем полученное число со входным в процедуру и возвращаем дату, если подходит под условие
--------------------------------------------------------------------------------

CREATE 
OR REPLACE PROCEDURE pr_successful_days(ref REFCURSOR, num_days INTEGER) LANGUAGE plpgsql AS $$ BEGIN IF num_days = 0 THEN OPEN ref FOR 
SELECT 
  DISTINCT "Date" 
FROM 
  checks 
ORDER BY 
  "Date";
ELSE OPEN ref FOR 
SELECT 
  DISTINCT "Date" 
FROM 
  (
    SELECT 
      "Date", 
      GroupCount, 
      count(*) 
    FROM 
      (
        SELECT 
          *, 
          SUM(NewGroup) OVER (
            ORDER BY 
              "Date", 
              "Time", 
              "State"
          ) AS GroupCount 
        FROM 
          (
            SELECT 
              "Task", 
              "Date", 
              "Time", 
              "Check", 
              "State", 
              "check1", 
              CASE WHEN LAG("Date") over (
                ORDER BY 
                  "Date", 
                  "Time", 
                  "State"
              ) = "Date" 
              AND LAG("State") over (
                ORDER BY 
                  "Date", 
                  "Time", 
                  "State"
              ) = "State" THEN 0 ELSE 1 END AS NewGroup 
            FROM 
              (
                WITH p2p_start AS (
                  SELECT 
                    "Task", 
                    "Date", 
                    "Check", 
                    "State", 
                    "Time" 
                  FROM 
                    checks 
                    JOIN p2p ON p2p."Check" = checks."ID" 
                  WHERE 
                    "State" = 'Start'
                ) 
                SELECT 
                  p2p_start."Task", 
                  p2p_start."Date", 
                  p2p_start."Time", 
                  p2p_start."Check", 
                  p2p_start."State" AS state, 
                  p2p."State", 
                  CASE WHEN "MaxXP" :: REAL * 0.8 <= "XPAmount" THEN true ELSE false END AS "check1" 
                FROM 
                  p2p_start 
                  JOIN p2p ON p2p."Check" = p2p_start."Check" 
                  JOIN tasks ON p2p_start."Task" = tasks."Title" 
                  LEFT JOIN xp ON xp."Check" = p2p_start."Check" 
                WHERE 
                  p2p."State" != 'Start' 
                ORDER BY 
                  "Date", 
                  "Time", 
                  p2p."State"
              ) AS table2
          ) AS table3 
        WHERE 
          "check1" = 'true'
      ) AS table1 
    GROUP BY 
      "Date", 
      GroupCount
  ) AS table4 
WHERE 
  count >= num_days;
END IF;
END $$;


--------------------------------------------------------------------------------
-- Проверяем вывод процедуры
--------------------------------------------------------------------------------
CALL pr_successful_days('task13', 0);
FETCH ALL 
FROM 
  task13;
CALL pr_successful_days('task13', 1);
FETCH ALL 
FROM 
  task13;
CALL pr_successful_days('task13', 2);
FETCH ALL 
FROM 
  task13;
--------------------------------------------------------------------------------
-- Задание 3.14. Пир с наибольшим количеством XP
--------------------------------------------------------------------------------
CREATE 
OR REPLACE PROCEDURE prc_peer_max_xp(ref REFCURSOR) AS $$ BEGIN OPEN ref FOR 
SELECT 
  "Peer", 
  SUM("XPAmount") AS "XP" 
FROM 
  checks 
  JOIN xp ON xp."ID" = checks."ID" 
GROUP BY 
  "Peer" 
ORDER BY 
  2 DESC 
LIMIT 
  1;
END;
$$ LANGUAGE plpgsql;
--------------------------------------------------------------------------------
-- Проверяем вывод процедуры
--------------------------------------------------------------------------------
CALL prc_peer_max_xp('task3_14');
FETCH ALL IN task3_14;
--------------------------------------------------------------------------------
-- Задание 3.15. Пиры, приходившие раньше заданного времени не менее N раз за всё время
--------------------------------------------------------------------------------
CREATE 
OR REPLACE PROCEDURE prc_peer_early_entry(
  ref REFCURSOR, time_in TIME, N INTEGER
) AS $$ BEGIN OPEN ref FOR 
SELECT 
  "Peer" 
FROM 
  timetracking 
WHERE 
  "Time" < time_in 
  AND "State" = 1 
GROUP BY 
  "Peer" 
HAVING 
  COUNT("State")>= N;
END;
$$ LANGUAGE plpgsql;
--------------------------------------------------------------------------------
-- Проверяем вывод процедуры
--------------------------------------------------------------------------------
CALL prc_peer_early_entry('task3_15', '13:37', 2);
FETCH ALL IN task3_15;
--------------------------------------------------------------------------------
-- Задание 3.16. Пиры, выходившие за последние N дней из кампуса больше M раз
--------------------------------------------------------------------------------
CREATE 
OR REPLACE PROCEDURE prc_peer_often_leave(ref REFCURSOR, N INTEGER, M INTEGER) AS $$ BEGIN OPEN ref FOR 
SELECT 
  "Peer" 
FROM 
  timetracking 
WHERE 
  "State" = 2 
  AND "Date" >(
    CURRENT_DATE - N * INTERVAL '1 days'
  ) 
GROUP BY 
  "Peer" 
HAVING 
  COUNT("State")> M;
END;
$$ LANGUAGE plpgsql;
--------------------------------------------------------------------------------
-- Проверяем вывод процедуры
--------------------------------------------------------------------------------
CALL prc_peer_often_leave('task3_16', 5, 1);
FETCH ALL IN task3_16;
--------------------------------------------------------------------------------
-- Задание 3.17. Для каждого месяца процент ранних входов
--------------------------------------------------------------------------------
CREATE 
OR REPLACE PROCEDURE pcd_birthday_entries_percent(ref REFCURSOR) LANGUAGE plpgsql AS $$ BEGIN OPEN ref FOR WITH entries AS (
  SELECT 
    date_trunc('month', "Date") AS month, 
    COUNT(DISTINCT "Peer") AS total_entries 
  FROM 
    timetracking 
    LEFT JOIN peers ON timetracking."Peer" = peers."Nickname" 
  WHERE 
    "State" = 1 
    AND date_part('month', peers."Birthday")= date_part('month', timetracking."Date") 
  GROUP BY 
    month
), 
early_entries AS (
  SELECT 
    date_trunc('month', "Date") AS month, 
    COUNT(DISTINCT "Peer") AS early_entries 
  FROM 
    timetracking 
    LEFT JOIN peers ON timetracking."Peer" = peers."Nickname" 
  WHERE 
    "State" = 1 
    AND "Time" < '12:00:00' 
    AND date_part('month', peers."Birthday")= date_part('month', timetracking."Date") 
  GROUP BY 
    month
) 
SELECT 
  to_char(dates.month, 'Month') AS month, 
  COALESCE(
    ROUND(
      early_entries.early_entries :: numeric / entries.total_entries :: numeric * 100, 
      0
    ), 
    0
  ) AS early_entries 
FROM 
  (
    SELECT 
      generate_series(
        '2023-01-01' :: date, '2023-12-01' :: date, 
        '1 month'
      ):: date AS month
  ) AS dates 
  LEFT JOIN entries ON dates.month = entries.month 
  LEFT JOIN early_entries ON dates.month = early_entries.month 
ORDER BY 
  dates.month;
END $$;
--------------------------------------------------------------------------------
-- Проверяем вывод процедуры
--------------------------------------------------------------------------------
CALL pcd_birthday_entries_percent('task3_17');
FETCH ALL IN task3_17;
