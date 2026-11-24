SELECT
    :anio AS anio_reporte,
    uc.idusuarios AS id_cliente,
    CONCAT_WS(' ', uc.nombre, uc.paterno, uc.materno) AS nombrealumno,
    uc.codigopais,
    uc.celular,
    COALESCE(MAX(n.nivel), 'Amateur') AS nivel,
    uc.fechanacimiento,
    TIMESTAMPDIFF(
        YEAR,
        STR_TO_DATE(uc.fechanacimiento, '%Y-%m-%d'),
        CURDATE()
    ) AS edad,
    uc.sexo,

    COUNT(DISTINCT CASE
        WHEN p.id_reservacion IS NOT NULL THEN r.id
    END) AS total_reservaciones,

    COUNT(DISTINCT CASE
        WHEN MONTH(r.fecha) = 1 AND p.id_reservacion IS NOT NULL THEN r.id
    END) AS reservas_enero,

    COUNT(DISTINCT CASE
        WHEN MONTH(r.fecha) = 2 AND p.id_reservacion IS NOT NULL THEN r.id
    END) AS reservas_febrero,

    COUNT(DISTINCT CASE
        WHEN MONTH(r.fecha) = 3 AND p.id_reservacion IS NOT NULL THEN r.id
    END) AS reservas_marzo,

    COUNT(DISTINCT CASE
        WHEN MONTH(r.fecha) = 4 AND p.id_reservacion IS NOT NULL THEN r.id
    END) AS reservas_abril,

    COUNT(DISTINCT CASE
        WHEN MONTH(r.fecha) = 5 AND p.id_reservacion IS NOT NULL THEN r.id
    END) AS reservas_mayo,

    COUNT(DISTINCT CASE
        WHEN MONTH(r.fecha) = 6 AND p.id_reservacion IS NOT NULL THEN r.id
    END) AS reservas_junio,

    COUNT(DISTINCT CASE
        WHEN MONTH(r.fecha) = 7 AND p.id_reservacion IS NOT NULL THEN r.id
    END) AS reservas_julio,

    COUNT(DISTINCT CASE
        WHEN MONTH(r.fecha) = 8 AND p.id_reservacion IS NOT NULL THEN r.id
    END) AS reservas_agosto,

    COUNT(DISTINCT CASE
        WHEN MONTH(r.fecha) = 9 AND p.id_reservacion IS NOT NULL THEN r.id
    END) AS reservas_septiembre,

    COUNT(DISTINCT CASE
        WHEN MONTH(r.fecha) = 10 AND p.id_reservacion IS NOT NULL THEN r.id
    END) AS reservas_octubre,

    COUNT(DISTINCT CASE
        WHEN MONTH(r.fecha) = 11 AND p.id_reservacion IS NOT NULL THEN r.id
    END) AS reservas_noviembre,

    COUNT(DISTINCT CASE
        WHEN MONTH(r.fecha) = 12 AND p.id_reservacion IS NOT NULL THEN r.id
    END) AS reservas_diciembre

FROM bdcentralwon.usuarios_central AS uc
INNER JOIN usuarios AS u
    ON u.idusuarios = uc.idusuarios
LEFT JOIN reservaciones AS r
    ON r.idusuario = uc.idusuarios
   AND r.estatus <> 3
   AND YEAR(r.fecha) = :anio
LEFT JOIN pagos AS p
    ON p.id_reservacion = r.id
   AND p.pagado = 1
LEFT JOIN bdcentralwon.deportenivelusuario AS dnu
    ON dnu.idusuario = uc.idusuarios
LEFT JOIN bdcentralwon.nivel AS n
    ON n.idnivel = dnu.idnivel
WHERE uc.estatus = 1
  AND TRIM(CONCAT_WS(' ', uc.nombre, uc.paterno, uc.materno)) <> ''
GROUP BY
    uc.idusuarios,
    uc.nombre,
    uc.paterno,
    uc.materno,
    uc.codigopais,
    uc.celular,
    uc.fechanacimiento,
    uc.sexo
ORDER BY
    nombrealumno