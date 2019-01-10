import db_postgres, json

import jester

import db


router api:
  get "/search":
    var matches = newJArray()

    withDbConn dbConn:
      for match in dbConn.findMatches @"q":
        matches.add %*{
          "body": match[1],
          "authorId": match[2],
          "createdAt": match[3],
          "rating": match[4]
        }

    resp matches
