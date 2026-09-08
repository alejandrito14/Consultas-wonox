SELECT
    p.idproductoinv AS producto_id,
    p.nombreinv AS producto,
    p.sku,
    p.stock_minimo,
    p.costo,
    p.unit_id AS unidad_id,
    p.stock AS inventario_actual


FROM productosinv p
WHERE p.para_inventario = 1
  AND p.estatus = 1
ORDER BY
    p.nombreinv;