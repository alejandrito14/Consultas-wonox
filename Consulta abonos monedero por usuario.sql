SET @codserv = 174;
SET @fecha_inicio = '2026-08-01';
SET @fecha_fin    = '2026-10-31';

SELECT
    NULL AS codigo_servicio,
    empresa.codserv AS codigo_club,
    empresa.nombre AS nombre_club,

    m.idusuario,
    CONCAT_WS(' ', uc.nombre, uc.paterno, uc.materno) AS nombre_usuario,

    m.idnota,
    m.idnotadescripcion,
    m.concepto,
    m.monto,
    m.tipo AS tipo_monedero_codigo,
    'ABONO' AS tipo_monedero,
    m.fecha AS fecha_monedero

FROM monedero m

LEFT JOIN bdcentralwon.usuarios_central uc
    ON uc.idusuarios = m.idusuario

LEFT JOIN bdcentralwon.empresa empresa
    ON empresa.codserv = @codserv

WHERE m.tipo = 0
  AND m.fecha >= CONCAT(@fecha_inicio, ' 00:00:00')
  AND m.fecha < DATE_ADD(@fecha_fin, INTERVAL 1 DAY)

ORDER BY
    nombre_usuario,
    m.fecha,
    m.idusuario;
