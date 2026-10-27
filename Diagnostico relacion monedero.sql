SELECT
    m.idnota,
    m.idnotadescripcion,
    m.concepto,
    m.monto,

    np.idnotapago,
    np.folio AS folio_notapago,
    np.fecha AS fecha_notapago,
    np.estatus AS estatus_notapago,

    nd.idnotapago AS idnota_decripcion_encontrada,
    nd.idnotapago_descripcion,
    nd.idpago,
    nd.monto AS monto_notapago,

    CASE
        WHEN np.idnotapago IS NULL THEN 'NO EXISTE EN NOTAPAGO'
        WHEN nd.idnotapago_descripcion IS NULL THEN 'NO EXISTE EN NOTAPAGO_DESCRIPCION'
        ELSE 'RELACION ENCONTRADA'
    END AS estado_relacion

FROM monedero m

LEFT JOIN notapago np
    ON np.idnotapago = m.idnota

LEFT JOIN notapago_descripcion nd
    ON nd.idnotapago_descripcion = m.idnotadescripcion

ORDER BY
    m.idnota,
    m.idnotadescripcion;
