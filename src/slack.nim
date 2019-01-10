import db_postgres, json, strformat, strutils

import jester

import db


const lang {.strdefine.}: string = "en"

when lang == "ru":
  import localizations/ru
else:
  import localizations/en


router slack:
  post "/fyi":
    var success: bool

    withDbConn dbConn:
      let
        body = parseJson(request.body)
        text = body["text"].getStr()
        userId = body["user_id"].getStr()

      success = dbConn.addEntry(text, userId)

    if success:
      resp %*{
        "response_type": "in_channel",
        "text": "✔"
      }

    else:
      resp "❌"

  post "/how":
    var matches: seq[Row]

    withDbConn dbConn:
      let query = parseJson(request.body)["text"].getStr()
      matches = dbConn.findMatches(query)

    if len(matches) == 0:
      resp %*{
        "response_type": "in_channel",
        "text": nothingFound()
      }

    else:
      var attachments = newJArray()

      for match in matches:
        attachments.add %*{
          "actions": [
            {
              "name": "rate",
              "text": "👍",
              "type": "button",
              "value": &"{match[0]} 1"
            },
            {
              "name": "rate",
              "text": "👎",
              "type": "button",
              "value": &"{match[0]} -1"
            }
          ],
          "color": if parseInt(match[4]) < 0: "#bababa" else: "#22ab00",
          "text": match[1],
          "author_name": &"<@{match[2]}>",
          "callback_id": "rate"
        }

      resp %*{
        "response_type": "in_channel",
        "attachments": attachments
      }

  post "/actions":
    let
      payload = parseJson(request.body)["payload"]
      action = payload["actions"][0]["value"].getStr().split()
      (entryId, diff) = (parseInt action[0], parseInt action[1])

    withDbConn dbConn:
      discard dbConn.rate(entryId, diff)

    resp %*{
      "text": "🙏",
      "replace_original": false
    }
