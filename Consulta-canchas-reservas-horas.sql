SELECT
    z.idzona AS cancha_id,
    z.nombre AS cancha,
    STR_TO_DATE(r.fecha, '%Y-%m-%d') AS fecha_reserva,
    r.hora_inicial AS hora_inicio,
    r.hora_final AS hora_fin,

    ROUND(
        TIMESTAMPDIFF(
            MINUTE,
            STR_TO_DATE(CONCAT(r.fecha, ' ', r.hora_inicial), '%Y-%m-%d %H:%i'),
            STR_TO_DATE(CONCAT(r.fecha, ' ', r.hora_final), '%Y-%m-%d %H:%i')
        ) / 60,
        2
    ) AS horas_reservadas,

    r.id AS reserva_id,
    r.codigo_reserva,
    r.costo

FROM reservaciones r
INNER JOIN zonas z
    ON z.idzona = r.idzona

WHERE STR_TO_DATE(r.fecha, '%Y-%m-%d') >= '2026-01-01'
  AND STR_TO_DATE(r.fecha, '%Y-%m-%d') <  '2026-09-01'
  AND r.estatus <> 3 -- excluir reservas canceladas

ORDER BY
    z.nombre,
    fecha_reserva,
    r.hora_inicial;