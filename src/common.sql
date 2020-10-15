CREATE FUNCTION @extschema@.execute(_sql TEXT)
  RETURNS VOID AS
$$
BEGIN
	EXECUTE 'DO LANGUAGE plpgsql $temp$ BEGIN ' || _sql || ' END $temp$;';
END;
$$
LANGUAGE plpgsql;

CREATE FUNCTION @extschema@.get_function_return_type(_schema TEXT, _name TEXT)
 RETURNS TEXT AS
$$
BEGIN 
	RETURN (
		SELECT type.typname
			FROM pg_proc AS proc
			JOIN pg_type AS type ON type.oid = proc.prorettype
			LEFT OUTER JOIN pg_namespace AS nasp ON nasp.oid = proc.pronamespace
		WHERE
			NOT proc.proisagg
			AND nasp.nspname = _schema
			AND proname = _name
	);
END;
$$
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.get_foreign_key_target(_schema TEXT, _table TEXT, _column TEXT)
RETURNS /*TABLE(
  	"constraint_name" 	TEXT,
	"schema"			TEXT,
	"table"				TEXT,
	"column"			TEXT[],
	"foreign_schema"	TEXT,
	"foreign_table"		TEXT,
	"foreign_column"	TEXT[]
)*/ TEXT AS
$$
--	RETURN QUERY
	SELECT
/*		c.conname::TEXT,
		sch.nspname::TEXT,
		tbl.relname::TEXT,
		ARRAY_AGG(DISTINCT col.attname::TEXT) AS "f_column",
		usg.table_schema::TEXT,
		usg.table_name::TEXT,
		ARRAY_AGG(DISTINCT usg.column_name::TEXT)*/
		usg.column_name::TEXT
	FROM pg_constraint AS "c"
	   JOIN LATERAL unnest(c.conkey) WITH ORDINALITY AS u(attnum, attposition) ON TRUE
	   JOIN pg_class 		AS "tbl" ON tbl.oid = c.conrelid
	   JOIN pg_namespace 	AS "sch" ON sch.oid = tbl.relnamespace
	   JOIN pg_attribute 	AS "col" ON (col.attrelid = tbl.oid AND col.attnum = u.attnum)
	   JOIN information_schema.constraint_column_usage AS "usg" ON (usg.constraint_name = c.conname)
	WHERE
		c.contype 	= 'f' AND
		sch.nspname = _schema AND
		tbl.relname = _table AND
		col.attname = _column
	GROUP BY c.conname, sch.nspname, tbl.relname, usg.table_schema, usg.table_name,  usg.column_name
	LIMIT 1;
$$
LANGUAGE sql;

/*
Récupère la liste des noms des contraintes dans une base
SELECT con.conname
FROM pg_catalog.pg_constraint con
	INNER JOIN pg_catalog.pg_class rel
			   ON rel.oid = con.conrelid
	INNER JOIN pg_catalog.pg_namespace nsp
			   ON nsp.oid = connamespace
*/
