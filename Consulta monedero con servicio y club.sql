SET @codserv = 174;
SET @fecha_inicio = '2026-08-01';
SET @fecha_fin    = '2026-10-31';

SELECT
    p.idservicio AS codigo_servicio,
    empresa.codserv AS codigo_club,
    empresa.nombre AS nombre_club,

    uc.idusuarios AS idusuario,
    CONCAT_WS(' ', uc.nombre, uc.paterno, uc.materno) AS nombre_usuario,

    m.idnota,
    m.idnotadescripcion,
    m.concepto,
    m.monto,
    m.fecha AS fecha_monedero,

    np.idnotapago,
    np.folio AS folio_notapago,
    np.fecha AS fecha_notapago,
    np.estatus AS estatus_notapago,

    nd.idnotapago AS idnota_descripcion_encontrada,
    nd.idnotapago_descripcion,
    nd.idpago,
    nd.monto AS monto_notapago

FROM monedero m

LEFT JOIN notapago np
    ON np.idnotapago = m.idnota

LEFT JOIN notapago_descripcion nd
    ON nd.idnotapago_descripcion = m.idnotadescripcion
   AND nd.idnotapago = m.idnota

LEFT JOIN pagos p
    ON p.idpago = nd.idpago

LEFT JOIN usuarios u
    ON u.idusuarios = p.idusuarios

LEFT JOIN bdcentralwon.usuarios_central uc
    ON uc.idusuarios = u.idusuarios

LEFT JOIN bdcentralwon.empresa empresa
    ON empresa.codserv = @codserv

WHERE COALESCE(m.fecha, np.fecha) >= CONCAT(@fecha_inicio, ' 00:00:00')
  AND COALESCE(m.fecha, np.fecha) < DATE_ADD(@fecha_fin, INTERVAL 1 DAY)

ORDER BY
    m.idnota,
    m.idnotadescripcion;
