import db_postgres, json, strformat, strutils

import jester

import db


router slack:
  post "/fyi":
    var success: bool

    withDbConn dbConn:
      success = dbConn.addEntry(@"text", @"user_id")

    resp if success: "✔" else: "❌"

  post "/how":
    var matches: seq[Row]

    withDbConn dbConn:
      matches = dbConn.findMatches @"text"

    if len(matches) == 0:
      resp "Ничего не нашлось 😿"

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
      payload = parseJson @"payload"
      action = payload["actions"][0]["value"].getStr().split()
      (entryId, diff) = (parseInt action[0], parseInt action[1])

    withDbConn dbConn:
      discard dbConn.rate(entryId, diff)

    resp %*{
      "text": "🙏",
      "replace_original": false
    }
