WITH RECURSIVE
parametros AS (
    SELECT
        CAST('2026-09-01' AS DATE) AS fecha_inicio,
        CURRENT_DATE() AS fecha_fin
),

horas AS (
    SELECT 6 AS hora

    UNION ALL

    SELECT hora + 1
    FROM horas
    WHERE hora < 23
),

eventos AS (

    /* Reservaciones completamente pagadas */
    SELECT
        r.idzona,
        'Reserva' AS tipo_evento,

        STR_TO_DATE(
            CONCAT(LEFT(r.fecha, 10), ' ', r.hora_inicial),
            '%Y-%m-%d %H:%i'
        ) AS inicio_evento,

        STR_TO_DATE(
            CONCAT(LEFT(r.fecha, 10), ' ', r.hora_final),
            '%Y-%m-%d %H:%i'
        ) AS fin_evento

    FROM reservaciones AS r

    CROSS JOIN parametros AS p

    WHERE STR_TO_DATE(LEFT(r.fecha, 10), '%Y-%m-%d')
          BETWEEN p.fecha_inicio AND p.fecha_fin

      AND COALESCE(r.estatus, 0) <> 3
      AND COALESCE(r.pago_completado, 0) = 1

    UNION ALL

    /* Servicios completamente pagados */
    SELECT
        hs.idzona,

        CASE
            WHEN LOWER(sc.nombre) LIKE '%clase%'
                THEN 'Clase'
            WHEN LOWER(sc.nombre) LIKE '%academ%'
                THEN 'Academia'
            ELSE 'Otro'
        END AS tipo_evento,

        STR_TO_DATE(
            CONCAT(LEFT(hs.fecha, 10), ' ', hs.horainicial),
            '%Y-%m-%d %H:%i'
        ) AS inicio_evento,

        STR_TO_DATE(
            CONCAT(LEFT(hs.fecha, 10), ' ', hs.horafinal),
            '%Y-%m-%d %H:%i'
        ) AS fin_evento

    FROM horariosservicio AS hs

    INNER JOIN servicios AS s
        ON s.idservicio = hs.idservicio

    INNER JOIN cps_subunidad_negocio AS su
        ON su.id = s.id_subunidad_negocio

    INNER JOIN cps_unidad_negocio AS u
        ON u.id = su.id_unidad_negocio

    INNER JOIN cps_subcategoria_negocio AS sc
        ON sc.id = u.id_subcategoria_negocio

    CROSS JOIN parametros AS p

    WHERE STR_TO_DATE(LEFT(hs.fecha, 10), '%Y-%m-%d')
          BETWEEN p.fecha_inicio AND p.fecha_fin

      AND hs.idservicio IS NOT NULL
      AND COALESCE(s.estatus, 0) = 1
      AND COALESCE(s.canceladoservicio, 0) = 0
      AND COALESCE(s.pago_completado, 0) = 1

    UNION ALL

    /* Bloqueos */
    SELECT
        b.id_zona AS idzona,
        'Bloqueo' AS tipo_evento,

        CAST(b.hora_inicial AS DATETIME) AS inicio_evento,
        CAST(b.hora_final AS DATETIME) AS fin_evento

    FROM bloqueos AS b

    CROSS JOIN parametros AS p

    WHERE DATE(b.fecha)
          BETWEEN p.fecha_inicio AND p.fecha_fin
),

segmentos AS (
    SELECT
        z.idzona,
        z.nombre AS cancha,
        h.hora,
        e.tipo_evento,

        TIMESTAMPDIFF(
            SECOND,

            GREATEST(
                e.inicio_evento,
                DATE_ADD(
                    DATE(e.inicio_evento),
                    INTERVAL h.hora HOUR
                )
            ),

            LEAST(
                e.fin_evento,
                DATE_ADD(
                    DATE(e.inicio_evento),
                    INTERVAL (h.hora + 1) HOUR
                )
            )
        ) / 3600 AS horas_segmento

    FROM eventos AS e

    INNER JOIN zonas AS z
        ON z.idzona = e.idzona

    INNER JOIN horas AS h
        ON e.inicio_evento < DATE_ADD(
               DATE(e.inicio_evento),
               INTERVAL (h.hora + 1) HOUR
           )
       AND e.fin_evento > DATE_ADD(
               DATE(e.inicio_evento),
               INTERVAL h.hora HOUR
           )

    WHERE z.cancha_activa = 1
      AND e.fin_evento > e.inicio_evento
)

SELECT
    cancha,

    CASE
        WHEN hora BETWEEN 6 AND 11
            THEN 'Mañana'
        WHEN hora BETWEEN 12 AND 17
            THEN 'Mediodía'
        WHEN hora BETWEEN 18 AND 23
            THEN 'Tarde-noche'
    END AS franja,

    CONCAT(
        LPAD(hora, 2, '0'),
        ':00 - ',
        LPAD(hora + 1, 2, '0'),
        ':00'
    ) AS horario,

    ROUND(
        SUM(
            CASE
                WHEN tipo_evento <> 'Bloqueo'
                    THEN horas_segmento
                ELSE 0
            END
        ),
        2
    ) AS horas_ocupadas,

    ROUND(
        SUM(
            CASE
                WHEN tipo_evento = 'Bloqueo'
                    THEN horas_segmento
                ELSE 0
            END
        ),
        2
    ) AS horas_bloqueadas,

    ROUND(
        SUM(horas_segmento),
        2
    ) AS horas_total,

    SUM(tipo_evento = 'Reserva') AS reservas,
    SUM(tipo_evento = 'Clase') AS clases,
    SUM(tipo_evento = 'Academia') AS academias,
    SUM(tipo_evento = 'Otro') AS otros,
    SUM(tipo_evento = 'Bloqueo') AS bloqueos

FROM segmentos

GROUP BY
    idzona,
    cancha,
    hora

ORDER BY
    cancha,

    CASE
        WHEN hora BETWEEN 6 AND 11 THEN 1
        WHEN hora BETWEEN 12 AND 17 THEN 2
        WHEN hora BETWEEN 18 AND 23 THEN 3
    END,

    horas_ocupadas DESC,
    hora;