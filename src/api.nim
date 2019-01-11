import db_postgres, json

import jester

import db


router api:
  get "/entries":
    var matches = newJArray()

    withDbConn dbConn:
      for match in dbConn.getEntries():
        matches.add %*{
          "id": match[0],
          "body": match[1],
          "authorId": match[2],
          "createdAt": match[3],
          "rating": match[4]
        }

    resp matches
