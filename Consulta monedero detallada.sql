SET @fecha_inicio = '2026-10-01';
SET @fecha_fin    = '2026-10-31';
SET @codserv      = 174;

SELECT
    reporte.codigo_servicio,
    empresa.codserv AS codigo_club,
    empresa.nombre AS nombre_club,
    reporte.idcliente,
    reporte.nombre_completo,
    reporte.folio_notapago,
    reporte.producto,
    reporte.categoria_negocio,
    reporte.subcategoria_negocio,
    reporte.unidad_negocio,
    reporte.subunidad_negocio,
    reporte.fecha_adeudo,
    reporte.fecha_pago,
    reporte.monto_bruto,
    reporte.descuento_aplicado,
    reporte.monto_neto,
    reporte.tipo_pago,
    reporte.idnota,
    reporte.idnotadescripcion,
    reporte.concepto_monedero,
    reporte.monto_monedero
FROM (

    /* =========================
       MONEDERO - COMANDA
       ========================= */
    SELECT
        NULL AS codigo_servicio,

        CASE
            WHEN c.id_invitado IS NOT NULL THEN CONCAT('INV-', i.id)
            ELSE CAST(uc.idusuarios AS CHAR)
        END AS idcliente,

        CASE
            WHEN c.id_invitado IS NOT NULL THEN CONCAT(i.nombre, ' (invitado)')
            ELSE CONCAT_WS(' ', uc.nombre, uc.paterno, uc.materno)
        END AS nombre_completo,

        np.folio AS folio_notapago,
        CONCAT('COMANDA #', c.folio) AS producto,
        NULL AS categoria_negocio,
        NULL AS subcategoria_negocio,
        NULL AS unidad_negocio,
        NULL AS subunidad_negocio,
        NULL AS fecha_adeudo,
        DATE(COALESCE(np.fecha, c.creado_en)) AS fecha_pago,
        CAST(nd.monto AS DECIMAL(12,2)) AS monto_bruto,
        COALESCE(nda.monto_descontado, 0) AS descuento_aplicado,
        CAST(nd.monto AS DECIMAL(12,2))
            - COALESCE(nda.monto_descontado, 0) AS monto_neto,
        'MONEDERO' AS tipo_pago,
        m.idnota,
        m.idnotadescripcion,
        m.concepto AS concepto_monedero,
        m.monto AS monto_monedero,
        c.id_comanda AS orden_comanda,
        0 AS nivel_fila

    FROM monedero m
    INNER JOIN notapago np
        ON np.idnotapago = m.idnota
    INNER JOIN notapago_descripcion nd
        ON nd.idnotapago_descripcion = m.idnotadescripcion
       AND nd.idnotapago = m.idnota
    INNER JOIN pagos p
        ON p.idpago = nd.idpago
    INNER JOIN comandas c
        ON c.id_pago = p.idpago
    LEFT JOIN (
        SELECT
            idnotapago_descripcion,
            SUM(monto_descontado) AS monto_descontado
        FROM notapago_descuento_aplicado
        GROUP BY idnotapago_descripcion
    ) nda
        ON nda.idnotapago_descripcion = nd.idnotapago_descripcion
    LEFT JOIN usuarios u
        ON u.idusuarios = c.id_usuario
    LEFT JOIN bdcentralwon.usuarios_central uc
        ON uc.idusuarios = u.idusuarios
    LEFT JOIN invitados i
        ON i.id = c.id_invitado

    WHERE c.estado_pago = 'pagada'
      AND COALESCE(np.fecha, c.creado_en) >= CONCAT(@fecha_inicio, ' 00:00:00')
      AND COALESCE(np.fecha, c.creado_en) < DATE_ADD(@fecha_fin, INTERVAL 1 DAY)

    UNION ALL

    /* =========================
       MONEDERO - ITEMS DE COMANDA
       ========================= */
    SELECT
        NULL AS codigo_servicio,

        CASE
            WHEN c.id_invitado IS NOT NULL THEN CONCAT('INV-', i.id)
            ELSE CAST(uc.idusuarios AS CHAR)
        END AS idcliente,

        CASE
            WHEN c.id_invitado IS NOT NULL THEN CONCAT(i.nombre, ' (invitado)')
            ELSE CONCAT_WS(' ', uc.nombre, uc.paterno, uc.materno)
        END AS nombre_completo,

        np.folio AS folio_notapago,
        CONCAT('  └─ ', ci.nombrepaquete, ' x', ci.cantidad) AS producto,
        cat.nombre AS categoria_negocio,
        csn.nombre AS subcategoria_negocio,
        cun.nombre AS unidad_negocio,
        csu.nombre AS subunidad_negocio,
        NULL AS fecha_adeudo,
        DATE(COALESCE(np.fecha, c.creado_en)) AS fecha_pago,
        ci.costototal AS monto_bruto,
        NULL AS descuento_aplicado,
        NULL AS monto_neto,
        'MONEDERO' AS tipo_pago,
        m.idnota,
        m.idnotadescripcion,
        m.concepto AS concepto_monedero,
        m.monto AS monto_monedero,
        c.id_comanda AS orden_comanda,
        1 AS nivel_fila

    FROM monedero m
    INNER JOIN notapago np
        ON np.idnotapago = m.idnota
    INNER JOIN notapago_descripcion nd
        ON nd.idnotapago_descripcion = m.idnotadescripcion
       AND nd.idnotapago = m.idnota
    INNER JOIN pagos p
        ON p.idpago = nd.idpago
    INNER JOIN comandas c
        ON c.id_pago = p.idpago
    INNER JOIN comanda_item ci
        ON ci.id_comanda = c.id_comanda
    LEFT JOIN usuarios u
        ON u.idusuarios = c.id_usuario
    LEFT JOIN bdcentralwon.usuarios_central uc
        ON uc.idusuarios = u.idusuarios
    LEFT JOIN invitados i
        ON i.id = c.id_invitado
    LEFT JOIN paquetes paq
        ON paq.idpaquete = ci.idpaquete
    LEFT JOIN categoriapaquete cp
        ON cp.idcategoriapaquete = paq.idcategoriapaquete
    LEFT JOIN cps_subunidad_negocio csu
        ON csu.id = cp.id_subunidad_negocio
    LEFT JOIN cps_unidad_negocio cun
        ON cun.id = csu.id_unidad_negocio
    LEFT JOIN cps_subcategoria_negocio csn
        ON csn.id = cun.id_subcategoria_negocio
    LEFT JOIN cps_categoria_negocio cat
        ON cat.id = csn.id_categoria_negocio

    WHERE c.estado_pago = 'pagada'
      AND COALESCE(np.fecha, c.creado_en) >= CONCAT(@fecha_inicio, ' 00:00:00')
      AND COALESCE(np.fecha, c.creado_en) < DATE_ADD(@fecha_fin, INTERVAL 1 DAY)

    UNION ALL

    /* =========================
       MONEDERO - RESERVAS
       ========================= */
    SELECT
        NULL AS codigo_servicio,

        CASE
            WHEN COALESCE(p.id_invitado, np.id_invitado) IS NOT NULL
                THEN CONCAT('INV-', COALESCE(p.id_invitado, np.id_invitado))
            ELSE CAST(uc.idusuarios AS CHAR)
        END AS idcliente,

        CASE
            WHEN COALESCE(p.id_invitado, np.id_invitado) IS NOT NULL
                THEN CONCAT(i.nombre, ' (invitado)')
            ELSE CONCAT_WS(' ', uc.nombre, uc.paterno, uc.materno)
        END AS nombre_completo,

        np.folio AS folio_notapago,
        CASE
            WHEN p.tipo = 5 THEN CONCAT('Reserva Autoplaza ', r.codigo_reserva)
            ELSE CONCAT('Reserva ', r.codigo_reserva)
        END AS producto,
        cat.nombre AS categoria_negocio,
        csn.nombre AS subcategoria_negocio,
        cun.nombre AS unidad_negocio,
        csu.nombre AS subunidad_negocio,
        NULL AS fecha_adeudo,
        CASE
            WHEN p.tipo = 5 THEN DATE(r.fecha)
            ELSE DATE(np.fecha)
        END AS fecha_pago,
        CAST(nd.monto AS DECIMAL(12,2)) AS monto_bruto,
        COALESCE(nda.monto_descontado, 0) AS descuento_aplicado,
        CAST(nd.monto AS DECIMAL(12,2))
            - COALESCE(nda.monto_descontado, 0) AS monto_neto,
        'MONEDERO' AS tipo_pago,
        m.idnota,
        m.idnotadescripcion,
        m.concepto AS concepto_monedero,
        m.monto AS monto_monedero,
        NULL AS orden_comanda,
        NULL AS nivel_fila

    FROM monedero m
    INNER JOIN notapago np
        ON np.idnotapago = m.idnota
    INNER JOIN notapago_descripcion nd
        ON nd.idnotapago_descripcion = m.idnotadescripcion
       AND nd.idnotapago = m.idnota
    INNER JOIN pagos p
        ON p.idpago = nd.idpago
    INNER JOIN reservaciones r
        ON r.id = p.id_reservacion
    LEFT JOIN (
        SELECT
            idnotapago_descripcion,
            SUM(monto_descontado) AS monto_descontado
        FROM notapago_descuento_aplicado
        GROUP BY idnotapago_descripcion
    ) nda
        ON nda.idnotapago_descripcion = nd.idnotapago_descripcion
    LEFT JOIN usuarios u
        ON u.idusuarios = p.idusuarios
    LEFT JOIN bdcentralwon.usuarios_central uc
        ON uc.idusuarios = u.idusuarios
    LEFT JOIN invitados i
        ON i.id = COALESCE(p.id_invitado, np.id_invitado)
    LEFT JOIN cps_subunidad_negocio csu
        ON csu.id = r.id_subunidad_negocio
    LEFT JOIN cps_unidad_negocio cun
        ON cun.id = csu.id_unidad_negocio
    LEFT JOIN cps_subcategoria_negocio csn
        ON csn.id = cun.id_subcategoria_negocio
    LEFT JOIN cps_categoria_negocio cat
        ON cat.id = csn.id_categoria_negocio

    WHERE p.pagado = 1
      AND p.estatus = 2
      AND p.tipo IN (4, 5)
      AND np.estatus = 1
      AND (
            (
                p.tipo = 4
                AND np.fecha >= CONCAT(@fecha_inicio, ' 00:00:00')
                AND np.fecha < DATE_ADD(@fecha_fin, INTERVAL 1 DAY)
            )
            OR
            (
                p.tipo = 5
                AND r.fecha >= @fecha_inicio
                AND r.fecha <= @fecha_fin
            )
      )

    UNION ALL

    /* =========================
       MONEDERO - SERVICIOS
       ========================= */
    SELECT
        s.idservicio AS codigo_servicio,

        CASE
            WHEN COALESCE(p.id_invitado, np.id_invitado) IS NOT NULL
                THEN CONCAT('INV-', COALESCE(p.id_invitado, np.id_invitado))
            ELSE CAST(uc.idusuarios AS CHAR)
        END AS idcliente,

        CASE
            WHEN COALESCE(p.id_invitado, np.id_invitado) IS NOT NULL
                THEN CONCAT(i.nombre, ' (invitado)')
            ELSE CONCAT_WS(' ', uc.nombre, uc.paterno, uc.materno)
        END AS nombre_completo,

        np.folio AS folio_notapago,
        s.titulo AS producto,
        cat.nombre AS categoria_negocio,
        csn.nombre AS subcategoria_negocio,
        cun.nombre AS unidad_negocio,
        csu.nombre AS subunidad_negocio,
        NULL AS fecha_adeudo,
        DATE(np.fecha) AS fecha_pago,
        CAST(nd.monto AS DECIMAL(12,2)) AS monto_bruto,
        COALESCE(nda.monto_descontado, 0) AS descuento_aplicado,
        CAST(nd.monto AS DECIMAL(12,2))
            - COALESCE(nda.monto_descontado, 0) AS monto_neto,
        'MONEDERO' AS tipo_pago,
        m.idnota,
        m.idnotadescripcion,
        m.concepto AS concepto_monedero,
        m.monto AS monto_monedero,
        NULL AS orden_comanda,
        NULL AS nivel_fila

    FROM monedero m
    INNER JOIN notapago np
        ON np.idnotapago = m.idnota
    INNER JOIN notapago_descripcion nd
        ON nd.idnotapago_descripcion = m.idnotadescripcion
       AND nd.idnotapago = m.idnota
    INNER JOIN pagos p
        ON p.idpago = nd.idpago
    INNER JOIN servicios s
        ON s.idservicio = p.idservicio
    LEFT JOIN (
        SELECT
            idnotapago_descripcion,
            SUM(monto_descontado) AS monto_descontado
        FROM notapago_descuento_aplicado
        GROUP BY idnotapago_descripcion
    ) nda
        ON nda.idnotapago_descripcion = nd.idnotapago_descripcion
    LEFT JOIN usuarios u
        ON u.idusuarios = p.idusuarios
    LEFT JOIN bdcentralwon.usuarios_central uc
        ON uc.idusuarios = u.idusuarios
    LEFT JOIN invitados i
        ON i.id = COALESCE(p.id_invitado, np.id_invitado)
    LEFT JOIN cps_subunidad_negocio csu
        ON csu.id = s.id_subunidad_negocio
    LEFT JOIN cps_unidad_negocio cun
        ON cun.id = csu.id_unidad_negocio
    LEFT JOIN cps_subcategoria_negocio csn
        ON csn.id = cun.id_subcategoria_negocio
    LEFT JOIN cps_categoria_negocio cat
        ON cat.id = csn.id_categoria_negocio

    WHERE p.pagado = 1
      AND p.estatus = 2
      AND p.tipo = 1
      AND np.estatus = 1
      AND np.fecha >= CONCAT(@fecha_inicio, ' 00:00:00')
      AND np.fecha < DATE_ADD(@fecha_fin, INTERVAL 1 DAY)

) AS reporte

INNER JOIN bdcentralwon.empresa empresa
    ON empresa.codserv = @codserv

WHERE reporte.monto_bruto > 0
   OR reporte.monto_neto > 0

ORDER BY
    CASE WHEN reporte.orden_comanda IS NULL THEN 1 ELSE 0 END,
    reporte.orden_comanda,
    reporte.nivel_fila,
    reporte.fecha_pago,
    reporte.fecha_adeudo;
