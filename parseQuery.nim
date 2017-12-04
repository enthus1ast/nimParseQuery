import uri, tables, sequtils

proc parseQuery*(query: string): OrderedTableRef[string, string] = 
  ## parses the query part of an uri.
  var start = 0
  var key, val = ""
  var queryBlock = ""
  if query == "":
    return
  result = newOrderedTable[string, string]()
  for i in 0..query.len:
    if query[i] == '&' or i == query.len:
      start = i
      var inval = false
      for each in queryBlock:
        if not inval and each == '=': 
          inval = true
          continue
        if inval:
          val.add each
        else:
          key.add each
      result.add(key.decodeUrl, val.decodeUrl)
      setLen(key, 0)
      setLen(val, 0)
      setLen(queryBlock, 0)
    else:
      queryBlock.add(query[i])

proc parseQuery*(uri: Uri): OrderedTableRef[string, string] =
  return parseQuery(uri.query)
  
proc newQuery(query: OrderedTableRef[string, string]): string =
  ## generates a query string
  ## eg: "faa=faa%3Dfaa"
  result = ""
  var first = true
  for key, val in query.pairs: 
    if first: first = false
    else: result.add("&")
    result.add(key.encodeUrl() & "=" & val.encodeUrl())

when isMainModule:
  block: # parseQuery & newQuery tests
    assert "foo=baa&baz=bahhz&baz=bahhz2".parseQuery() == 
        { "foo": "baa", "baz": "bahhz", "baz": "bahhz2"}.newOrderedTable()
    assert "foo=baa&baz=bahhz&baz=bahhz2".parseQuery() == 
      {"foo": "baa", "baz": "bahhz", "baz": "bahhz2"}.newOrderedTable()

    assert "http://example.com/res.some?foo=baa&baz=bahhz&baz=bahhz2"
      .parseUri().query.parseQuery() == 
        {"foo": "baa", "baz": "bahhz", "baz": "bahhz2"}.newOrderedTable()
    
    assert "faa".parseQuery() == {"faa": ""}.newOrderedTable()
    assert "faa&faa".parseQuery() == {"faa": "", "faa": ""}.newOrderedTable()
    assert "faa=faa=faa".parseQuery() == {"faa": "faa=faa"}.newOrderedTable()
    assert "faa=faa%3Dfaa".parseQuery() == {"faa": "faa=faa"}.newOrderedTable()
    
  block:
    var ur = parseUri("http://www.example.com/")
    var tt = {"user": "Günter Jürgen", "mail": "günter-jürgen@example.com"}.newOrderedTable()
    ur.query = newQuery(tt)
    assert ur.query.parseQuery == tt

  block:
    var ur = parseUri("http://www.example.com/")
    var tt = {"user": "李王", "mail": "李王@example.com"}.newOrderedTable()
    ur.query = newQuery(tt)
    assert ur.query.parseQuery == tt  

  block: # queries in query
    var ur = parseUri("http://www.example.com/")
    var t1 = {"user": "李王", "mail": "李王@example.com"}.newOrderedTable().newQuery()
    var t2 = {"user": "Günter Jürgen", "mail": "günter-jürgen@example.com"}.newOrderedTable().newQuery()
    var tt = {"users": t1, "users": t2}.newOrderedTable()
    ur.query = tt.newQuery()
    assert ur.query.parseQuery() == tt

  block: # test parseQuery with uri as param
    var ur = parseUri("http://www.example.com/?id=4221")
    assert ur.parseQuery()["id"] == "4221"

  block:
    var ur = parseUri("http://www.example.com/?id=4221&id=1338")
    var qu = parseQuery(ur)
    assert toSeq(qu.values) == @["4221", "1338"]
    assert toSeq(qu.keys) == @["id","id"]
    assert toSeq(qu.pairs) ==  @[("id", "4221"), ("id", "1338")]
