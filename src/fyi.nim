import db_postgres, json, strformat, strutils

import jester

import db


router slack:
  post "/fyi":
    var success: bool

    withDbConn dbConn:
      success = dbConn.addEntry(@"text", @"user_id", @"channel_id")

    resp %*{
      "response_type": "in_channel",
      "text": if success: "✔" else: "❌"
    }

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
          "text": [
              &"{match[1]}",
              &"_Добавлено {match[2]} в канале {match[3]} {match[4]}_"
            ].join("\n\n"),
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
          "callback_id": "rate"
        }

      resp %*{
        "response_type": "in_channel",
        "text": "Вот что нашлось по вашему запросу:",
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


routes:
  extend slack, "/slack"
