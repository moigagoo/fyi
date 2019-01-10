import sugar, strformat

include karax/prelude

import karax/kajax

proc cb(httpStatus: int, response: cstring) =
  echo response

proc render(): VNode =
  buildHtml(tdiv):
    input(
      id="search",
      onkeyup = (event: Event, node: VNode) => (
        ajaxGet(&"/api/search?q={node.value}", @[], cb)
      )
    )


setRenderer render
