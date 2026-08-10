SET @fecha_inicio = '2026-07-01';
SET @fecha_fin    = '2026-07-31';

SELECT
    idcliente,
    nombre_completo,
    folio_notapago,
    producto,
    categoria_negocio,
    subcategoria_negocio,
    unidad_negocio,
    subunidad_negocio,
    fecha_adeudo,
    fecha_pago,
    monto_bruto,
    descuento_aplicado,
    monto_neto
FROM (
    /* PAGADOS - COMANDA */
    SELECT
        CASE WHEN c.id_invitado IS NOT NULL THEN CONCAT('INV-', i.id)
             ELSE CAST(uc.idusuarios AS CHAR) END AS idcliente,
        CASE WHEN c.id_invitado IS NOT NULL THEN CONCAT(i.nombre, ' (invitado)')
             ELSE CONCAT_WS(' ', uc.nombre, uc.paterno, uc.materno) END AS nombre_completo,
        np.folio AS folio_notapago,
        CONCAT('COMANDA #', c.folio) AS producto,
        NULL AS categoria_negocio, NULL AS subcategoria_negocio,
        'TPV' AS unidad_negocio, 'COMANDAS' AS subunidad_negocio,
        NULL AS fecha_adeudo,
        DATE(COALESCE(np.fecha, c.creado_en)) AS fecha_pago,
        SUM(CAST(nd.monto AS DECIMAL(12,2))) AS monto_bruto,
        COALESCE(SUM(nda.monto_descontado), 0) AS descuento_aplicado,
        SUM(CAST(nd.monto AS DECIMAL(12,2))) - COALESCE(SUM(nda.monto_descontado), 0) AS monto_neto,
        c.id_comanda AS orden_comanda, 0 AS nivel_fila
    FROM comandas c
    LEFT JOIN pagos p ON p.idpago = c.id_pago
    LEFT JOIN notapago_descripcion nd ON nd.idpago = p.idpago
    LEFT JOIN notapago np ON np.idnotapago = nd.idnotapago
    LEFT JOIN notapago_descuento_aplicado nda ON nda.idnotapago_descripcion = nd.idnotapago_descripcion
    LEFT JOIN usuarios u ON u.idusuarios = c.id_usuario
    LEFT JOIN bdcentralwon.usuarios_central uc ON uc.idusuarios = u.idusuarios
    LEFT JOIN invitados i ON i.id = c.id_invitado
    WHERE c.estado_pago = 'pagada'
      AND COALESCE(np.fecha, c.creado_en) >= CONCAT(@fecha_inicio, ' 00:00:00')
      AND COALESCE(np.fecha, c.creado_en) < DATE_ADD(@fecha_fin, INTERVAL 1 DAY)
    GROUP BY c.id_comanda, c.folio, np.folio, DATE(COALESCE(np.fecha, c.creado_en)),
             c.id_invitado, i.id, i.nombre, uc.idusuarios, uc.nombre, uc.paterno, uc.materno

    UNION ALL

    /* PAGADOS - ITEMS DE COMANDA */
    SELECT
        CASE WHEN c.id_invitado IS NOT NULL THEN CONCAT('INV-', i.id)
             ELSE CAST(uc.idusuarios AS CHAR) END,
        CASE WHEN c.id_invitado IS NOT NULL THEN CONCAT(i.nombre, ' (invitado)')
             ELSE CONCAT_WS(' ', uc.nombre, uc.paterno, uc.materno) END,
        np.folio,
        CONCAT('  └─ ', ci.nombrepaquete, ' x', ci.cantidad),
        cat.nombre, csn.nombre, 'TPV', csu.nombre,
        NULL, DATE(COALESCE(np.fecha, c.creado_en)), ci.costototal, NULL, NULL,
        c.id_comanda, 1
    FROM comandas c
    LEFT JOIN pagos p ON p.idpago = c.id_pago
    LEFT JOIN notapago_descripcion nd ON nd.idpago = p.idpago
    LEFT JOIN notapago np ON np.idnotapago = nd.idnotapago
    INNER JOIN comanda_item ci ON ci.id_comanda = c.id_comanda
    LEFT JOIN usuarios u ON u.idusuarios = c.id_usuario
    LEFT JOIN bdcentralwon.usuarios_central uc ON uc.idusuarios = u.idusuarios
    LEFT JOIN invitados i ON i.id = c.id_invitado
    LEFT JOIN paquetes paq ON paq.idpaquete = ci.idpaquete
    LEFT JOIN categoriapaquete cp ON cp.idcategoriapaquete = paq.idcategoriapaquete
    LEFT JOIN cps_subunidad_negocio csu ON csu.id = cp.id_subunidad_negocio
    LEFT JOIN cps_unidad_negocio cun ON cun.id = csu.id_unidad_negocio
    LEFT JOIN cps_subcategoria_negocio csn ON csn.id = cun.id_subcategoria_negocio
    LEFT JOIN cps_categoria_negocio cat ON cat.id = csn.id_categoria_negocio
    WHERE c.estado_pago = 'pagada'
      AND COALESCE(np.fecha, c.creado_en) >= CONCAT(@fecha_inicio, ' 00:00:00')
      AND COALESCE(np.fecha, c.creado_en) < DATE_ADD(@fecha_fin, INTERVAL 1 DAY)
    GROUP BY c.id_comanda, c.folio, np.folio, DATE(COALESCE(np.fecha, c.creado_en)),
             c.id_invitado, i.id, i.nombre, uc.idusuarios, uc.nombre, uc.paterno,
             uc.materno, ci.id, ci.nombrepaquete, ci.cantidad, ci.costototal,
             cat.nombre, csn.nombre, cun.nombre, csu.nombre

    UNION ALL

    /* PENDIENTES - COMANDA */
    SELECT
        CASE WHEN c.id_invitado IS NOT NULL THEN CONCAT('INV-', i.id)
             ELSE CAST(uc.idusuarios AS CHAR) END,
        CASE WHEN c.id_invitado IS NOT NULL THEN CONCAT(i.nombre, ' (invitado)')
             ELSE CONCAT_WS(' ', uc.nombre, uc.paterno, uc.materno) END,
        NULL, CONCAT('COMANDA #', c.folio), NULL, NULL, 'TPV', 'COMANDAS',
        DATE(c.creado_en), NULL, SUM(ci.costototal), NULL, NULL,
        c.id_comanda, 0
    FROM comandas c
    INNER JOIN comanda_item ci ON ci.id_comanda = c.id_comanda AND ci.estatus = 1
    LEFT JOIN usuarios u ON u.idusuarios = c.id_usuario
    LEFT JOIN bdcentralwon.usuarios_central uc ON uc.idusuarios = u.idusuarios
    LEFT JOIN invitados i ON i.id = c.id_invitado
    WHERE c.estado_pago IN ('pendiente', 'cobrando')
      AND c.creado_en >= CONCAT(@fecha_inicio, ' 00:00:00')
      AND c.creado_en < DATE_ADD(@fecha_fin, INTERVAL 1 DAY)
    GROUP BY c.id_comanda, c.folio, DATE(c.creado_en), c.id_invitado, i.id, i.nombre,
             uc.idusuarios, uc.nombre, uc.paterno, uc.materno

    UNION ALL

    /* PENDIENTES - ITEMS DE COMANDA */
    SELECT
        CASE WHEN c.id_invitado IS NOT NULL THEN CONCAT('INV-', i.id)
             ELSE CAST(uc.idusuarios AS CHAR) END,
        CASE WHEN c.id_invitado IS NOT NULL THEN CONCAT(i.nombre, ' (invitado)')
             ELSE CONCAT_WS(' ', uc.nombre, uc.paterno, uc.materno) END,
        NULL, CONCAT('  └─ ', ci.nombrepaquete, ' x', ci.cantidad),
        cat.nombre, csn.nombre, 'TPV', csu.nombre,
        DATE(c.creado_en), NULL, ci.costototal, NULL, NULL,
        c.id_comanda, 1
    FROM comandas c
    INNER JOIN comanda_item ci ON ci.id_comanda = c.id_comanda AND ci.estatus = 1
    LEFT JOIN usuarios u ON u.idusuarios = c.id_usuario
    LEFT JOIN bdcentralwon.usuarios_central uc ON uc.idusuarios = u.idusuarios
    LEFT JOIN invitados i ON i.id = c.id_invitado
    LEFT JOIN paquetes paq ON paq.idpaquete = ci.idpaquete
    LEFT JOIN categoriapaquete cp ON cp.idcategoriapaquete = paq.idcategoriapaquete
    LEFT JOIN cps_subunidad_negocio csu ON csu.id = cp.id_subunidad_negocio
    LEFT JOIN cps_unidad_negocio cun ON cun.id = csu.id_unidad_negocio
    LEFT JOIN cps_subcategoria_negocio csn ON csn.id = cun.id_subcategoria_negocio
    LEFT JOIN cps_categoria_negocio cat ON cat.id = csn.id_categoria_negocio
    WHERE c.estado_pago IN ('pendiente', 'cobrando')
      AND c.creado_en >= CONCAT(@fecha_inicio, ' 00:00:00')
      AND c.creado_en < DATE_ADD(@fecha_fin, INTERVAL 1 DAY)
) AS tpv
ORDER BY orden_comanda, nivel_fila, fecha_pago, fecha_adeudo;
