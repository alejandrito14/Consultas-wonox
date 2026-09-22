SET @fecha_inicio = '2026-09-01';
SET @fecha_fin    = '2026-09-22';

SELECT GROUP_CONCAT(
    DISTINCT CONCAT(
        'COUNT(DISTINCT CASE WHEN cancha = ',
        QUOTE(COALESCE(z.nombre, CONCAT('Cancha ', z.idzona))),
        ' THEN clase_id END) AS `',
        REPLACE(
            COALESCE(z.nombre, CONCAT('Cancha ', z.idzona)),
            '`',
            '``'
        ),
        '`'
    )
    ORDER BY COALESCE(z.nombre, CONCAT('Cancha ', z.idzona))
    SEPARATOR ', '
)
INTO @columnas_canchas
FROM zonas z;

SET @sql = CONCAT(
'WITH clases_coach AS (
    SELECT
        uc.idusuarios AS coach_id,

        CONCAT_WS(
            '' '',
            uc.nombre,
            uc.paterno,
            uc.materno
        ) AS coach,

        hs.idhorarioservicio AS clase_id,

        COALESCE(
            z.nombre,
            CONCAT(''Cancha '', hs.idzona)
        ) AS cancha

    FROM usuarios_servicios us

    INNER JOIN usuarioscoachs uco
        ON uco.idusuarios_servicios = us.idusuarios_servicios

    INNER JOIN servicios s
        ON s.idservicio = us.idservicio

    INNER JOIN horariosservicio hs
        ON hs.idservicio = s.idservicio

    INNER JOIN zonas z
        ON z.idzona = hs.idzona

    INNER JOIN cps_subunidad_negocio su
        ON su.id = s.id_subunidad_negocio

    INNER JOIN cps_unidad_negocio un
        ON un.id = su.id_unidad_negocio

    INNER JOIN cps_subcategoria_negocio sc
        ON sc.id = un.id_subcategoria_negocio

    INNER JOIN bdcentralwon.usuarios_central uc
        ON uc.idusuarios = us.idusuarios

    WHERE hs.fecha BETWEEN @fecha_inicio AND @fecha_fin
      AND LOWER(TRIM(sc.nombre)) = ''clases''
      AND COALESCE(us.cancelacion, 0) = 0
      AND COALESCE(s.canceladoservicio, 0) = 0
      AND COALESCE(uc.estatus, 1) = 1
)

SELECT
    coach_id AS `Coach ID`,
    coach AS `Coach`,
    ',
    @columnas_canchas,
    ',
    COUNT(DISTINCT clase_id) AS `Total clases`

FROM clases_coach
GROUP BY coach_id, coach
ORDER BY `Total clases` DESC, coach'
);

PREPARE consulta FROM @sql;
EXECUTE consulta;
DEALLOCATE PREPARE consulta;