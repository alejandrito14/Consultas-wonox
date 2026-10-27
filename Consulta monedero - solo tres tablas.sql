SET @fecha_inicio = '2026-10-01';
SET @fecha_fin    = '2026-10-31';

SELECT
    m.*,

    np.folio AS folio_notapago,
    np.fecha AS fecha_notapago,
    np.estatus AS estatus_notapago,

    nd.idpago,
    nd.idnotapago AS idnotapago_descripcion,
    nd.monto AS monto_notapago

FROM monedero m

INNER JOIN notapago np
    ON np.idnotapago = m.idnota

INNER JOIN notapago_descripcion nd
    ON nd.idnotapago_descripcion = m.idnotadescripcion
   AND nd.idnotapago = m.idnota

WHERE np.fecha >= CONCAT(@fecha_inicio, ' 00:00:00')
  AND np.fecha < DATE_ADD(@fecha_fin, INTERVAL 1 DAY)
  AND np.estatus = 1

ORDER BY
    np.fecha,
    m.idnota,
    m.idnotadescripcion;
