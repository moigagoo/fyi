import db_postgres, json, strutils

import jester

import db


router api:
  get "/entries/?@id?":
    if @"id" == "":
      var entries = newJArray()

      withDbConn dbConn:
        for entry in dbConn.getEntries():
          entries.add %*{
            "id": entry[0],
            "body": entry[1],
            "authorId": entry[2],
            "createdAt": entry[3],
            "rating": entry[4]
          }

      resp entries

    else:
      let id = parseInt(@"id")

      withDbConn dbConn:
        let entry = dbConn.getEntry(id)

        resp %*{
          "id": entry[0],
          "body": entry[1],
          "authorId": entry[2],
          "createdAt": entry[3],
          "rating": entry[4]
        }
