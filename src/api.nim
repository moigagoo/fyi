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

        if entry[0] == "": resp Http404
        else:
          resp %*{
            "id": entry[0],
            "body": entry[1],
            "authorId": entry[2],
            "createdAt": entry[3],
            "rating": entry[4]
          }

  delete "/entries/@id":
    let id = parseInt(@"id")

    withDbConn dbConn:
      dbConn.deleteEntry(id)
      resp Http200

  post "/entries/?":
    withDbConn dbConn:
      let
        body = parseJson(request.body)
        text = body["text"].getStr()
        userId = body{"user_id"}.getStr("fyi")

      resp %*{
        "id": dbConn.createEntry(text, userId)
      }

  put "/entries/@id":
    let
      id = parseInt(@"id")
      body = parseJson(request.body)
      text = body["text"].getStr()

    var success: bool

    withDbConn dbConn:
      success = dbConn.updateEntry(id , text)

    if success: resp Http200
    else: resp Http500
