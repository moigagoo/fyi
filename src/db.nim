import os, times, db_postgres

export db_postgres


proc initDb*(dbConn: DbConn) =
  dbConn.exec sql"DROP TABLE IF EXISTS entries"
  dbConn.exec sql"""
    CREATE TABLE entries
    (
      id SERIAL PRIMARY KEY,
      body text NOT NULL CHECK (body <> ''),
      author_id varchar(20) NOT NULL CHECK (author_id <> ''),
      created_at timestamp DEFAULT CURRENT_TIMESTAMP,
      rating INT DEFAULT 0
    )
    """

proc addEntry*(dbConn: DbConn, body, authorId: string): bool =
  try:
    discard dbConn.insertID(
      sql"INSERT INTO entries (body, author_id) VALUES (?, ?)",
      body, authorId
    )
    result = true

  except DbError:
    discard

proc rate*(dbConn: DbConn, entryId, diff: int): bool =
  try:
    dbConn.exec sql"UPDATE entries SET rating = rating + ? WHERE id = ?", diff, entryId
    result = true

  except DbError:
    discard

proc findMatches*(dbConn: DbConn, query: string, limit = 3, tsConfig = "russian"): seq[Row] =
  dbConn.getAllRows(
    sql"""
      SELECT *
      FROM entries
      WHERE tsvector_to_array(to_tsvector(?, body))
        && tsvector_to_array(to_tsvector(?, ?))
      ORDER BY rating DESC, created_at DESC
      LIMIT ?
      """,
      tsConfig, tsConfig, query, limit
  )

proc getEntries*(dbConn: DbConn): seq[Row] = dbConn.getAllRows(sql"SELECT * FROM entries")

proc getEntry*(dbConn: DbConn, id: int): Row =
  result = dbConn.getRow(sql"SELECT * FROM entries WHERE id=?", id)

proc deleteEntry*(dbConn: DbConn, id: int) =
  dbConn.exec(sql"DELETE FROM entries WHERE id=?", id)

proc createEntry*(dbConn: DbConn, body, authorId: string): int =
  try:
    result = dbConn.insertID(
      sql"INSERT INTO entries (body, author_id) VALUES (?, ?)",
      body, authorId
    ).int

  except DbError:
    discard

proc updateEntry*(dbConn: DbConn, id: int, text: string): bool =
  try:
    dbConn.exec sql"UPDATE entries SET body = ? WHERE id = ?", text, id
    result = true

  except DbError:
    discard

template withDbConn*(varName, body: untyped): untyped =
  let
    host = getEnv("PG_HOST")
    user = getEnv("PG_USER")
    password = getEnv("PG_PASSWORD")
    db = getEnv("PG_DB")

  if len(host) == 0 or len(user) == 0 or len(password) == 0 or len(db) == 0:
    quit "PG_HOST, PG_USER, PG_PASSWORD, and PG_DB env vars cannot be empty"

  let `varName` {.inject.} = open(host, user, password, db)

  try:
    body

  finally:
    `varName`.close()


when isMainModule:
  withDbConn dbConn:
    dbConn.initDb()
