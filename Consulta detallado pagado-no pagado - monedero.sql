SET @fecha_inicio = '2026-10-01';
SET @fecha_fin    = '2026-10-31';

SELECT
    codigo_servicio,
    codigo_club,
    e.nombre AS nombre_club,
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
    monto_neto,
    tipo_pago,
    m.concepto AS concepto_monedero,
    m.monto AS monto_monedero
FROM (

    /* =========================
       PAGADOS - COMANDA
       ========================= */
    SELECT
        NULL AS codigo_servicio,
        174 AS codigo_club,

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
        SUM(CAST(nd.monto AS DECIMAL(12,2))) AS monto_bruto,
        COALESCE(SUM(nda.monto_descontado), 0) AS descuento_aplicado,
        SUM(CAST(nd.monto AS DECIMAL(12,2)))
            - COALESCE(SUM(nda.monto_descontado), 0) AS monto_neto,

        MAX(
            CASE
                WHEN EXISTS (
                    SELECT 1
                    FROM monedero m
                    WHERE m.idnota = np.idnotapago
                      AND m.idnotadescripcion = nd.idnotapago_descripcion
                ) THEN 'MONEDERO'
                ELSE NULL
            END
        ) AS tipo_pago,

        c.id_comanda AS orden_comanda,
        0 AS nivel_fila,
        np.idnotapago AS idnota_monedero,
        nd.idnotapago_descripcion AS idnotadescripcion_monedero

    FROM comandas c
    LEFT JOIN pagos p
        ON p.idpago = c.id_pago
    LEFT JOIN notapago_descripcion nd
        ON nd.idpago = p.idpago
    LEFT JOIN notapago np
        ON np.idnotapago = nd.idnotapago
    LEFT JOIN notapago_descuento_aplicado nda
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

    GROUP BY
        c.id_comanda,
        c.folio,
        np.folio,
        DATE(COALESCE(np.fecha, c.creado_en)),
        c.id_invitado,
        i.id,
        i.nombre,
        uc.idusuarios,
        uc.nombre,
        uc.paterno,
        uc.materno,
        np.idnotapago,
        nd.idnotapago_descripcion

    UNION ALL

    /* =========================
       PAGADOS - ITEMS DE COMANDA
       ========================= */
    SELECT
        NULL AS codigo_servicio,
        174 AS codigo_club,

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

        MAX(
            CASE
                WHEN EXISTS (
                    SELECT 1
                    FROM monedero m
                    WHERE m.idnota = np.idnotapago
                      AND m.idnotadescripcion = nd.idnotapago_descripcion
                ) THEN 'MONEDERO'
                ELSE NULL
            END
        ) AS tipo_pago,

        c.id_comanda AS orden_comanda,
        1 AS nivel_fila,
        np.idnotapago AS idnota_monedero,
        nd.idnotapago_descripcion AS idnotadescripcion_monedero

    FROM comandas c
    LEFT JOIN pagos p
        ON p.idpago = c.id_pago
    LEFT JOIN notapago_descripcion nd
        ON nd.idpago = p.idpago
    LEFT JOIN notapago np
        ON np.idnotapago = nd.idnotapago
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

    GROUP BY
        c.id_comanda,
        c.folio,
        np.folio,
        DATE(COALESCE(np.fecha, c.creado_en)),
        c.id_invitado,
        i.id,
        i.nombre,
        uc.idusuarios,
        uc.nombre,
        uc.paterno,
        uc.materno,
        ci.id,
        ci.nombrepaquete,
        ci.cantidad,
        ci.costototal,
        cat.nombre,
        csn.nombre,
        cun.nombre,
        csu.nombre,
        np.idnotapago,
        nd.idnotapago_descripcion

    UNION ALL

    /* =========================
       PAGADOS - RESERVAS
       ========================= */
    SELECT
        NULL AS codigo_servicio,
        174 AS codigo_club,

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
        SUM(CAST(nd.monto AS DECIMAL(12,2))) AS monto_bruto,
        COALESCE(SUM(nda.monto_descontado), 0) AS descuento_aplicado,
        SUM(CAST(nd.monto AS DECIMAL(12,2)))
            - COALESCE(SUM(nda.monto_descontado), 0) AS monto_neto,

        MAX(
            CASE
                WHEN EXISTS (
                    SELECT 1
                    FROM monedero m
                    WHERE m.idnota = np.idnotapago
                      AND m.idnotadescripcion = nd.idnotapago_descripcion
                ) THEN 'MONEDERO'
                ELSE NULL
            END
        ) AS tipo_pago,

        NULL AS orden_comanda,
        NULL AS nivel_fila,
        np.idnotapago AS idnota_monedero,
        nd.idnotapago_descripcion AS idnotadescripcion_monedero

    FROM pagos p
    INNER JOIN reservaciones r
        ON r.id = p.id_reservacion
    INNER JOIN notapago_descripcion nd
        ON nd.idpago = p.idpago
    INNER JOIN notapago np
        ON np.idnotapago = nd.idnotapago
    LEFT JOIN notapago_descuento_aplicado nda
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
            (p.tipo = 4
             AND np.fecha >= CONCAT(@fecha_inicio, ' 00:00:00')
             AND np.fecha < DATE_ADD(@fecha_fin, INTERVAL 1 DAY))
            OR
            (p.tipo = 5
             AND r.fecha >= @fecha_inicio
             AND r.fecha <= @fecha_fin)
      )

    GROUP BY
        r.id,
        r.codigo_reserva,
        p.tipo,
        np.folio,
        p.id_invitado,
        np.id_invitado,
        i.nombre,
        uc.idusuarios,
        uc.nombre,
        uc.paterno,
        uc.materno,
        cat.nombre,
        csn.nombre,
        cun.nombre,
        csu.nombre,
        CASE
            WHEN p.tipo = 5 THEN DATE(r.fecha)
            ELSE DATE(np.fecha)
        END,
        np.idnotapago,
        nd.idnotapago_descripcion

    UNION ALL

    /* =========================
       PAGADOS - SERVICIOS
       ========================= */
    SELECT
        s.idservicio AS codigo_servicio,
        174 AS codigo_club,

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
        SUM(CAST(nd.monto AS DECIMAL(12,2))) AS monto_bruto,
        COALESCE(SUM(nda.monto_descontado), 0) AS descuento_aplicado,
        SUM(CAST(nd.monto AS DECIMAL(12,2)))
            - COALESCE(SUM(nda.monto_descontado), 0) AS monto_neto,

        MAX(
            CASE
                WHEN EXISTS (
                    SELECT 1
                    FROM monedero m
                    WHERE m.idnota = np.idnotapago
                      AND m.idnotadescripcion = nd.idnotapago_descripcion
                ) THEN 'MONEDERO'
                ELSE NULL
            END
        ) AS tipo_pago,

        NULL AS orden_comanda,
        NULL AS nivel_fila,
        np.idnotapago AS idnota_monedero,
        nd.idnotapago_descripcion AS idnotadescripcion_monedero

    FROM pagos p
    INNER JOIN servicios s
        ON s.idservicio = p.idservicio
    INNER JOIN notapago_descripcion nd
        ON nd.idpago = p.idpago
    INNER JOIN notapago np
        ON np.idnotapago = nd.idnotapago
    LEFT JOIN notapago_descuento_aplicado nda
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

    GROUP BY
        s.idservicio,
        s.idservicio,
        s.titulo,
        np.folio,
        DATE(np.fecha),
        p.id_invitado,
        np.id_invitado,
        i.nombre,
        uc.idusuarios,
        uc.nombre,
        uc.paterno,
        uc.materno,
        cat.nombre,
        csn.nombre,
        cun.nombre,
        csu.nombre,
        np.idnotapago,
        nd.idnotapago_descripcion

    UNION ALL

    /* =========================
       PENDIENTES - COMANDA
       ========================= */
    SELECT
        NULL AS codigo_servicio,
        174 AS codigo_club,
        CASE
            WHEN c.id_invitado IS NOT NULL THEN CONCAT('INV-', i.id)
            ELSE CAST(uc.idusuarios AS CHAR)
        END AS idcliente,
        CASE
            WHEN c.id_invitado IS NOT NULL THEN CONCAT(i.nombre, ' (invitado)')
            ELSE CONCAT_WS(' ', uc.nombre, uc.paterno, uc.materno)
        END AS nombre_completo,
        NULL AS folio_notapago,
        CONCAT('COMANDA #', c.folio) AS producto,
        NULL AS categoria_negocio,
        NULL AS subcategoria_negocio,
        NULL AS unidad_negocio,
        NULL AS subunidad_negocio,
        DATE(c.creado_en) AS fecha_adeudo,
        NULL AS fecha_pago,
        SUM(ci.costototal) AS monto_bruto,
        NULL AS descuento_aplicado,
        NULL AS monto_neto,
        NULL AS tipo_pago,
        c.id_comanda AS orden_comanda,
        0 AS nivel_fila,
        NULL AS idnota_monedero,
        NULL AS idnotadescripcion_monedero
    FROM comandas c
    INNER JOIN comanda_item ci
        ON ci.id_comanda = c.id_comanda
       AND ci.estatus = 1
    LEFT JOIN usuarios u
        ON u.idusuarios = c.id_usuario
    LEFT JOIN bdcentralwon.usuarios_central uc
        ON uc.idusuarios = u.idusuarios
    LEFT JOIN invitados i
        ON i.id = c.id_invitado
    WHERE c.estado_pago IN ('pendiente', 'cobrando')
      AND c.creado_en >= CONCAT(@fecha_inicio, ' 00:00:00')
      AND c.creado_en < DATE_ADD(@fecha_fin, INTERVAL 1 DAY)
    GROUP BY
        c.id_comanda,
        c.folio,
        DATE(c.creado_en),
        c.id_invitado,
        i.id,
        i.nombre,
        uc.idusuarios,
        uc.nombre,
        uc.paterno,
        uc.materno

    UNION ALL

    /* =========================
       PENDIENTES - ITEMS
       ========================= */
    SELECT
        NULL AS codigo_servicio,
        174 AS codigo_club,
        CASE
            WHEN c.id_invitado IS NOT NULL THEN CONCAT('INV-', i.id)
            ELSE CAST(uc.idusuarios AS CHAR)
        END AS idcliente,
        CASE
            WHEN c.id_invitado IS NOT NULL THEN CONCAT(i.nombre, ' (invitado)')
            ELSE CONCAT_WS(' ', uc.nombre, uc.paterno, uc.materno)
        END AS nombre_completo,
        NULL AS folio_notapago,
        CONCAT('  └─ ', ci.nombrepaquete, ' x', ci.cantidad) AS producto,
        cat.nombre AS categoria_negocio,
        csn.nombre AS subcategoria_negocio,
        cun.nombre AS unidad_negocio,
        csu.nombre AS subunidad_negocio,
        DATE(c.creado_en) AS fecha_adeudo,
        NULL AS fecha_pago,
        ci.costototal AS monto_bruto,
        NULL AS descuento_aplicado,
        NULL AS monto_neto,
        NULL AS tipo_pago,
        c.id_comanda AS orden_comanda,
        1 AS nivel_fila,
        NULL AS idnota_monedero,
        NULL AS idnotadescripcion_monedero
    FROM comandas c
    INNER JOIN comanda_item ci
        ON ci.id_comanda = c.id_comanda
       AND ci.estatus = 1
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
    WHERE c.estado_pago IN ('pendiente', 'cobrando')
      AND c.creado_en >= CONCAT(@fecha_inicio, ' 00:00:00')
      AND c.creado_en < DATE_ADD(@fecha_fin, INTERVAL 1 DAY)

    UNION ALL

    /* =========================
       PENDIENTES - RESERVAS
       ========================= */
    SELECT
        NULL AS codigo_servicio,
        174 AS codigo_club,
        CASE
            WHEN p.id_invitado IS NOT NULL THEN CONCAT('INV-', p.id_invitado)
            ELSE CAST(uc.idusuarios AS CHAR)
        END AS idcliente,
        CASE
            WHEN p.id_invitado IS NOT NULL THEN CONCAT(i.nombre, ' (invitado)')
            ELSE CONCAT_WS(' ', uc.nombre, uc.paterno, uc.materno)
        END AS nombre_completo,
        NULL AS folio_notapago,
        CASE
            WHEN p.tipo = 5 THEN CONCAT('Reserva Autoplaza ', r.codigo_reserva)
            ELSE CONCAT('Reserva ', r.codigo_reserva)
        END AS producto,
        cat.nombre AS categoria_negocio,
        csn.nombre AS subcategoria_negocio,
        cun.nombre AS unidad_negocio,
        csu.nombre AS subunidad_negocio,
        CASE
            WHEN p.tipo = 5 THEN DATE(r.fecha)
            ELSE DATE(p.fechacreacion)
        END AS fecha_adeudo,
        NULL AS fecha_pago,
        p.monto AS monto_bruto,
        NULL AS descuento_aplicado,
        NULL AS monto_neto,
        NULL AS tipo_pago,
        NULL AS orden_comanda,
        NULL AS nivel_fila,
        NULL AS idnota_monedero,
        NULL AS idnotadescripcion_monedero
    FROM pagos p
    INNER JOIN reservaciones r
        ON r.id = p.id_reservacion
    LEFT JOIN usuarios u
        ON u.idusuarios = p.idusuarios
    LEFT JOIN bdcentralwon.usuarios_central uc
        ON uc.idusuarios = u.idusuarios
    LEFT JOIN invitados i
        ON i.id = p.id_invitado
    LEFT JOIN cps_subunidad_negocio csu
        ON csu.id = r.id_subunidad_negocio
    LEFT JOIN cps_unidad_negocio cun
        ON cun.id = csu.id_unidad_negocio
    LEFT JOIN cps_subcategoria_negocio csn
        ON csn.id = cun.id_subcategoria_negocio
    LEFT JOIN cps_categoria_negocio cat
        ON cat.id = csn.id_categoria_negocio
    WHERE p.pagado = 0
      AND p.estatus IN (0, 1)
      AND p.tipo IN (4, 5)
      AND (
            (p.tipo = 4
             AND p.fechacreacion >= CONCAT(@fecha_inicio, ' 00:00:00')
             AND p.fechacreacion < DATE_ADD(@fecha_fin, INTERVAL 1 DAY))
            OR
            (p.tipo = 5
             AND r.fecha >= @fecha_inicio
             AND r.fecha <= @fecha_fin)
      )

    UNION ALL

    /* =========================
       PENDIENTES - SERVICIOS
       ========================= */
    SELECT
        s.idservicio AS codigo_servicio,
        174 AS codigo_club,
        CASE
            WHEN p.id_invitado IS NOT NULL THEN CONCAT('INV-', p.id_invitado)
            ELSE CAST(uc.idusuarios AS CHAR)
        END AS idcliente,
        CASE
            WHEN p.id_invitado IS NOT NULL THEN CONCAT(i.nombre, ' (invitado)')
            ELSE CONCAT_WS(' ', uc.nombre, uc.paterno, uc.materno)
        END AS nombre_completo,
        NULL AS folio_notapago,
        s.titulo AS producto,
        cat.nombre AS categoria_negocio,
        csn.nombre AS subcategoria_negocio,
        cun.nombre AS unidad_negocio,
        csu.nombre AS subunidad_negocio,
        DATE(p.fechacreacion) AS fecha_adeudo,
        NULL AS fecha_pago,
        p.monto AS monto_bruto,
        NULL AS descuento_aplicado,
        NULL AS monto_neto,
        NULL AS tipo_pago,
        NULL AS orden_comanda,
        NULL AS nivel_fila,
        NULL AS idnota_monedero,
        NULL AS idnotadescripcion_monedero
    FROM pagos p
    INNER JOIN servicios s
        ON s.idservicio = p.idservicio
    LEFT JOIN usuarios u
        ON u.idusuarios = p.idusuarios
    LEFT JOIN bdcentralwon.usuarios_central uc
        ON uc.idusuarios = u.idusuarios
    LEFT JOIN invitados i
        ON i.id = p.id_invitado
    LEFT JOIN cps_subunidad_negocio csu
        ON csu.id = s.id_subunidad_negocio
    LEFT JOIN cps_unidad_negocio cun
        ON cun.id = csu.id_unidad_negocio
    LEFT JOIN cps_subcategoria_negocio csn
        ON csn.id = cun.id_subcategoria_negocio
    LEFT JOIN cps_categoria_negocio cat
        ON cat.id = csn.id_categoria_negocio
    WHERE p.pagado = 0
      AND p.estatus IN (0, 1)
      AND p.tipo = 1
      AND p.fechacreacion >= CONCAT(@fecha_inicio, ' 00:00:00')
      AND p.fechacreacion < DATE_ADD(@fecha_fin, INTERVAL 1 DAY)

) AS reporte_movimientos

INNER JOIN bdcentralwon.empresa e
    ON e.codserv = reporte_movimientos.codigo_club

INNER JOIN monedero m
    ON m.idnota = reporte_movimientos.idnota_monedero
   AND m.idnotadescripcion = reporte_movimientos.idnotadescripcion_monedero

WHERE monto_bruto > 0
   OR monto_neto > 0

ORDER BY
    CASE WHEN orden_comanda IS NULL THEN 1 ELSE 0 END,
    orden_comanda,
    nivel_fila,
    fecha_pago,
    fecha_adeudo;
