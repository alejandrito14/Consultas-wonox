SET @codserv = 174;
SET @fecha_inicio = '2026-08-01';
SET @fecha_fin    = '2026-10-31';

SELECT
    empresa.codserv AS codigo_club,
    empresa.nombre AS nombre_club,

    COALESCE(p.idusuarios, c.id_usuario) AS idusuario,

    CASE
        WHEN COALESCE(p.id_invitado, c.id_invitado) IS NOT NULL
            THEN CONCAT(i.nombre, ' (invitado)')
        ELSE CONCAT_WS(' ', uc.nombre, uc.paterno, uc.materno)
    END AS nombre_usuario,


    m.concepto,
    m.monto AS monto_monedero,

    m.tipo AS tipo_monedero_codigo,

    CASE
        WHEN m.tipo = 0 THEN 'ABONO'
        WHEN m.tipo = 1 THEN 'CARGO'
        ELSE 'OTRO'
    END AS tipo_monedero,

    CASE
        WHEN m.tipo = 0 THEN m.monto
        ELSE 0
    END AS monto_abono,

    CASE
        WHEN m.tipo = 1 THEN m.monto
        ELSE 0
    END AS monto_cargo,

    CASE
        WHEN m.tipo = 0 THEN m.monto
        WHEN m.tipo = 1 THEN -m.monto
        ELSE 0
    END AS movimiento_saldo,

    m.fecha AS fecha_monedero,

    r.codigo_reserva,
    c.folio AS codigo_comanda,

    COALESCE(np_id.idnotapago, np_res.idnotapago) AS idnotapago,
    COALESCE(np_id.folio, np_res.folio) AS folio_notapago,
    COALESCE(np_id.fecha, np_res.fecha) AS fecha_notapago,
    COALESCE(np_id.estatus, np_res.estatus) AS estatus_notapago,

    COALESCE(
        nd_id.idnotapago_descripcion,
        nd_res.idnotapago_descripcion
    ) AS idnotapago_descripcion,

    p.idpago
FROM monedero m

LEFT JOIN notapago np_id
    ON np_id.idnotapago = m.idnota
   AND m.idnota <> -1

LEFT JOIN notapago_descripcion nd_id
    ON nd_id.idnotapago_descripcion = m.idnotadescripcion
   AND nd_id.idnotapago = m.idnota
   AND m.idnota <> -1

LEFT JOIN reservaciones r
    ON r.codigo_reserva = SUBSTRING_INDEX(
        SUBSTRING_INDEX(m.concepto, 'Pago de reserva ', -1),
        ' en cancha',
        1
    )
   AND m.idnota = -1

LEFT JOIN comandas c
    ON c.folio = SUBSTRING_INDEX(
        SUBSTRING_INDEX(m.concepto, 'Comanda ', -1),
        ' ',
        1
    )
   AND m.idnota = -1

LEFT JOIN pagos p
    ON p.idpago = nd_id.idpago
    OR (
        m.idnota = -1
        AND p.id_reservacion = r.id
    )
    OR (
        m.idnota = -1
        AND p.idpago = c.id_pago
    )

LEFT JOIN notapago_descripcion nd_res
    ON nd_res.idpago = p.idpago
   AND m.idnota = -1

LEFT JOIN notapago np_res
    ON np_res.idnotapago = nd_res.idnotapago

LEFT JOIN usuarios u
    ON u.idusuarios = COALESCE(p.idusuarios, c.id_usuario)

LEFT JOIN bdcentralwon.usuarios_central uc
    ON uc.idusuarios = u.idusuarios

LEFT JOIN invitados i
    ON i.id = COALESCE(p.id_invitado, c.id_invitado)

LEFT JOIN bdcentralwon.empresa empresa
    ON empresa.codserv = @codserv

WHERE COALESCE(m.fecha, np_id.fecha, np_res.fecha)
          >= CONCAT(@fecha_inicio, ' 00:00:00')
  AND COALESCE(m.fecha, np_id.fecha, np_res.fecha)
          < DATE_ADD(@fecha_fin, INTERVAL 1 DAY)

  AND m.tipo = 1

  AND COALESCE(
          np_id.idnotapago,
          np_res.idnotapago
      ) IS NOT NULL

  AND COALESCE(
          np_id.estatus,
          np_res.estatus
      ) = 1

  AND (
        (
            c.id_comanda IS NOT NULL
            AND c.estado_pago = 'pagada'
        )
        OR
        (
            c.id_comanda IS NULL
            AND p.pagado = 1
            AND p.estatus = 2
        )
      )

ORDER BY

    COALESCE(m.fecha, np_id.fecha, np_res.fecha)