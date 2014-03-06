# MARK FOR DELETION

# We don't use Database as a database at all. We just use it as a store of key value pairs exactly as 
# localstorage works. We store JSON objects as strings associated with keys. The only reason we use Database at all is that 
# localStorage is limited to 5M of memory and database can be set to have an unlimited size. 
 
class window.DB
  @key: "test_key"
  @value: "a"
  
  @db: null
  
  @ensure_db: =>
    @db = window.openDatabase("Database", "1.0", "App DB", 200000) unless @db?
    
  @ensure_key_value_table: =>
    @ensure_db()
    @db.transaction(DB.ensure_key_value_table_sql, DB.error_cb, DB.success_cb)
  
  @ensure_key_value_table_sql: (tx) =>
    tx.executeSql('DROP TABLE IF EXISTS key_value');
    tx.executeSql('CREATE TABLE IF NOT EXISTS key_value (key,     value)');
    sql = "INSERT INTO key_value (key, value) VALUES ('key1', '" + DB.value + "' )"
    console.log sql
    tx.executeSql(sql)
  
  @success_cb: => console.log "db tx success"  
  @error_cb: (e) => 
    console.log "error_cb:"  
    console.log e 
    return false
  
  
  @query_result_cb: (tx, results) =>
    console.log("Returned rows = " + results.rows.length);
    console.log("Rows:")
    console.log(results.rows);
    console.log("Item0:")
    console.log(results.rows.item(0));
    console.log results.rows.item(0).value.length
    console.log("resultSet")
    console.log(resultSet)
    return false
    
  
  @query_error_cb: (e) =>
    console.log "query_error_cb:"  
    console.log e 
  
  # Test db max size:
  @mk_str: (size) => 
    str = ""
    str += "a" for n in [0..size]
    DB.value = str
    DB.value.length
  
  @dbl_str: =>
    DB.value += DB.value
    DB.value.length
    
  @set: (key, val) =>
    @ensure_key_value_table()
    # @db.transaction(DB.set_sql, DB.success_cb, DB.error_cb)
    
  @set_sql: (tx) =>
    # tx.executeSql('DELETE FROM key_value WHERE key = "key1"')
    # tx.executeSql("DELETE FROM key_value WHERE key = #{@key}")
    tx.executeSql('INSERT INTO key_value (key, value) VALUES (1, "test")')

  @get: (key) =>
    # @ensure_key_value_table()
    @db.transaction(DB.get_sql, DB.error_cb);
  
  @get_sql: (tx) => 
    tx.executeSql('SELECT * FROM key_value WHERE key = "key1"', [], DB.query_result_cb, DB.query_error_cb)
    
  @clear: (key) ->
  
  @clear_all: ->
    
    

