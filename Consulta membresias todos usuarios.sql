SELECT
  um.idusuarios AS id_usuario,
  uc.celular AS telefono,
  CONCAT_WS(' ', uc.nombre, uc.paterno, uc.materno) AS nombre_completo,
  um.idmembresia,
  m.titulo AS nombre_membresia,
  um.fechaexpiracion
FROM usuarios_membresia um
JOIN bdcentralwon.usuarios_central uc ON uc.idusuarios = um.idusuarios
JOIN membresia m ON m.idmembresia = um.idmembresia
WHERE uc.estatus = 1
  AND um.estatus = 1 and um.fechacancelacion is null and um.fechadeshabilitacion is null and um.usuariocancelacion=0
 
ORDER BY  um.idmembresia,nombre_completo