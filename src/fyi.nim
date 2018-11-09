import db_postgres, json, strformat
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
        let text = &"{match[0]},\n\n_добавлено {match[1]} в канале {match[2]} {match[3]}_"

        attachments.add %*{"text": text}

      resp %*{
        "response_type": "in_channel",
        "text": "Вот что нашлось по вашему запросу:",
        "attachments": attachments
      }


routes:
  extend slack, "/slack"
