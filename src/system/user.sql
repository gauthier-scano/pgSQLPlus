CREATE FUNCTION @extschema@.create_user(_id BIGINT, _name TEXT, _index SMALLINT, _delete BOOLEAN, _mask BOOLEAN, _history BOOLEAN, _right BOOLEAN)
  RETURNS VOID AS
$$
	INSERT INTO @extschema@.user(id, name, index, delete, mask, history, "right") VALUES (_id, _name, _index, _delete, _mask, _history, _right);
$$
LANGUAGE sql;


CREATE FUNCTION @extschema@.delete_user(_id BIGINT)
  RETURNS VOID AS
$$
	DELETE FROM @extschema@.user WHERE id = _id;
$$
LANGUAGE sql;


CREATE FUNCTION @extschema@.set_user_right(_id BIGINT, _delete BOOLEAN, _mask BOOLEAN, _history BOOLEAN, _right BOOLEAN)
  RETURNS VOID AS
$$
	UPDATE @extschema@.user SET (delete, mask, history, "right") = (_delete, _mask, _history, _right) WHERE id = _id;
$$
LANGUAGE sql;


CREATE FUNCTION @extschema@.set_user_table_right(_id_user BIGINT, _schema TEXT, _table TEXT, _read BOOLEAN, _insert BOOLEAN, _delete BOOLEAN, _update BOOLEAN)
  RETURNS VOID AS
$$
	UPDATE @extschema@."table_user_right" SET (
		"read",
		"insert",
		"delete",
		"update"
	) = (
		_read,
		_insert,
		_delete,
		_update
	) WHERE
		"id_user" 	= _id_user
	AND	"id_table" 	= (SELECT t1.id FROM @extschema@."table" AS t1 WHERE t1."schema" = _schema AND t1."table" = _table);
$$
LANGUAGE sql;
