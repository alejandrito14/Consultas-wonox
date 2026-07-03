SELECT
  um.idusuarios,
  CONCAT_WS(' ', ANY_VALUE(uc.nombre), ANY_VALUE(uc.paterno), ANY_VALUE(uc.materno)) AS nombre_completo,
	uc.celular,
  m.idmembresia,
  ANY_VALUE(m.titulo) AS membresia,

  um.fechaexpiracion
FROM usuarios_membresia um
JOIN membresia m ON m.idmembresia = um.idmembresia
LEFT JOIN membresia_cps_config mc ON mc.id_membresia = m.idmembresia
LEFT JOIN cps_categoria_negocio   cat   ON mc.cps_id = cat.id   AND m.nivel_cps = 1
LEFT JOIN cps_subcategoria_negocio sub   ON mc.cps_id = sub.id   AND m.nivel_cps = 2
LEFT JOIN cps_unidad_negocio      uni   ON mc.cps_id = uni.id   AND m.nivel_cps = 3
LEFT JOIN cps_subunidad_negocio   subuni ON mc.cps_id = subuni.id AND m.nivel_cps = 4
LEFT JOIN bdcentralwon.usuarios_central uc ON uc.idusuarios = um.idusuarios
-- Opcional: solo usuarios activos en el central
WHERE uc.estatus = 1
-- Opcional: si quieres solo membresías vigentes, descomenta la siguiente línea
AND (um.fechaexpiracion IS NULL OR um.fechaexpiracion >= CURDATE())
GROUP BY
  um.idusuarios,
  m.idmembresia,
  um.fechaexpiracion
ORDER BY nombre_completo, m.titulo;