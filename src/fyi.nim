import db_postgres, json, strformat, strutils

import jester

import db
import api
import slack

const lang {.strdefine.}: string = "en"

when lang == "ru":
  import localizations/ru
else:
  import localizations/en


routes:
  extend slack, "/slack"
