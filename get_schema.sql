-- 获取所有表的结构信息
SELECT 
  table_name,
  (
    SELECT json_agg(
      json_build_object(
        'column_name', column_name,
        'data_type', data_type,
        'is_nullable', is_nullable,
        'column_default', column_default
      )
    )
    FROM information_schema.columns
    WHERE table_name = t.table_name AND table_schema = 'public'
  ) AS columns
FROM information_schema.tables t
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'; 