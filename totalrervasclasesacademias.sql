SET @fecha_inicio = '2026-09-01';
SET @fecha_fin    = '2026-09-22';

WITH actividades AS (

    /* Rentas de cancha */
    SELECT
        COALESCE(z.nombre, CONCAT('Cancha ', r.idzona)) AS cancha,
        'renta' AS tipo,
        TIMESTAMPDIFF(
            MINUTE,
            STR_TO_DATE(
                CONCAT(r.fecha, ' ', r.hora_inicial),
                '%Y-%m-%d %H:%i'
            ),
            CASE
                WHEN r.hora_final >= r.hora_inicial THEN
                    STR_TO_DATE(
                        CONCAT(r.fecha, ' ', r.hora_final),
                        '%Y-%m-%d %H:%i'
                    )
                ELSE
                    DATE_ADD(
                        STR_TO_DATE(
                            CONCAT(r.fecha, ' ', r.hora_final),
                            '%Y-%m-%d %H:%i'
                        ),
                        INTERVAL 1 DAY
                    )
            END
        ) AS minutos
    FROM reservaciones r
    INNER JOIN zonas z
        ON z.idzona = r.idzona
    WHERE r.fecha BETWEEN @fecha_inicio AND @fecha_fin
      AND COALESCE(r.estatus, 0) <> 3

    UNION ALL

    /* Clases y academias */
    SELECT
        COALESCE(z.nombre, CONCAT('Cancha ', hs.idzona)) AS cancha,
        CASE
            WHEN LOWER(TRIM(sc.nombre)) = 'clases'
                THEN 'clase'
            WHEN LOWER(TRIM(sc.nombre)) = 'academias'
                THEN 'academia'
        END AS tipo,
        TIMESTAMPDIFF(
            MINUTE,
            STR_TO_DATE(
                CONCAT(hs.fecha, ' ', hs.horainicial),
                '%Y-%m-%d %H:%i'
            ),
            CASE
                WHEN hs.horafinal >= hs.horainicial THEN
                    STR_TO_DATE(
                        CONCAT(hs.fecha, ' ', hs.horafinal),
                        '%Y-%m-%d %H:%i'
                    )
                ELSE
                    DATE_ADD(
                        STR_TO_DATE(
                            CONCAT(hs.fecha, ' ', hs.horafinal),
                            '%Y-%m-%d %H:%i'
                        ),
                        INTERVAL 1 DAY
                    )
            END
        ) AS minutos
    FROM horariosservicio hs
    INNER JOIN servicios s
        ON s.idservicio = hs.idservicio
    INNER JOIN zonas z
        ON z.idzona = hs.idzona
    INNER JOIN cps_subunidad_negocio su
        ON su.id = s.id_subunidad_negocio
    INNER JOIN cps_unidad_negocio un
        ON un.id = su.id_unidad_negocio
    INNER JOIN cps_subcategoria_negocio sc
        ON sc.id = un.id_subcategoria_negocio
    WHERE hs.fecha BETWEEN @fecha_inicio AND @fecha_fin
      AND COALESCE(s.canceladoservicio, 0) <> 1
      AND LOWER(TRIM(sc.nombre)) IN ('clases', 'academias')
)

SELECT
    cancha AS `Cancha`,

    SUM(tipo = 'renta') AS `Reservas`,
    ROUND(SUM(CASE WHEN tipo = 'renta'
                   THEN minutos ELSE 0 END) / 60, 2) AS `Hrs reservas`,

    SUM(tipo = 'clase') AS `Clases`,
    ROUND(SUM(CASE WHEN tipo = 'clase'
                   THEN minutos ELSE 0 END) / 60, 2) AS `Hrs clase`,

    SUM(tipo = 'academia') AS `Academias`,
    ROUND(SUM(CASE WHEN tipo = 'academia'
                   THEN minutos ELSE 0 END) / 60, 2) AS `Hrs academia`,
	    (
        SUM(tipo = 'renta') +
        SUM(tipo = 'clase') +
        SUM(tipo = 'academia')
    ) AS `Cantidad`,


    ROUND(SUM(minutos) / 60, 2) AS `Hrs totales`

FROM actividades
GROUP BY cancha
ORDER BY cantidad desc;