SET @codserv = 146;
SET @anio = 2026;

SET @fecha_inicio = CONCAT(@anio, '-07-01');
SET @fecha_fin    = CONCAT(@anio, '-11-01');

SELECT
    e.codserv AS codigo_servicio,
    e.nombre AS nombre_club,

    r.cancha,

    r.fecha_reserva AS fecha,

    CASE WEEKDAY(r.fecha_reserva)
        WHEN 0 THEN 'Lunes'
        WHEN 1 THEN 'Martes'
        WHEN 2 THEN 'Miércoles'
        WHEN 3 THEN 'Jueves'
        WHEN 4 THEN 'Viernes'
        WHEN 5 THEN 'Sábado'
        WHEN 6 THEN 'Domingo'
    END AS dia,

    ROUND(SUM(r.horas_vendidas), 2) AS horas_cancha_vendidas

FROM bdcentralwon.empresa e

CROSS JOIN (
    SELECT
        res.idzona AS cancha_id,
        COALESCE(
            z.nombre,
            CONCAT('Cancha ', res.idzona)
        ) AS cancha,

        STR_TO_DATE(res.fecha, '%Y-%m-%d') AS fecha_reserva,

        (
            TIMESTAMPDIFF(
                MINUTE,
                STR_TO_DATE(res.hora_inicial, '%H:%i'),
                STR_TO_DATE(res.hora_final, '%H:%i')
            )
            +
            CASE
                WHEN res.hora_final <= res.hora_inicial
                    THEN 1440
                ELSE 0
            END
        ) / 60 AS horas_vendidas

    FROM reservaciones res

    LEFT JOIN zonas z
        ON z.idzona = res.idzona

    INNER JOIN cps_subunidad_negocio subunidad
        ON subunidad.id = res.id_subunidad_negocio

    INNER JOIN cps_unidad_negocio unidad
        ON unidad.id = subunidad.id_unidad_negocio

    INNER JOIN cps_subcategoria_negocio subcategoria
        ON subcategoria.id = unidad.id_subcategoria_negocio
       AND subcategoria.id = 1
       -- 1 = Renta de canchas

    WHERE STR_TO_DATE(res.fecha, '%Y-%m-%d') >= @fecha_inicio
      AND STR_TO_DATE(res.fecha, '%Y-%m-%d') < @fecha_fin

      -- Excluye reservas canceladas
      AND res.estatus IN (1, 2)

      -- Pagadas totalmente o parcialmente
      AND res.pago_completado IN (1, 2)
) AS r

WHERE e.codserv = @codserv
  AND e.estatus = 1

GROUP BY
    e.codserv,
    e.nombre,
    r.cancha_id,
    r.cancha,
    r.fecha_reserva,
    WEEKDAY(r.fecha_reserva)

ORDER BY
    e.codserv,
    r.fecha_reserva,
    r.cancha;