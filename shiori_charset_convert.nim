##[
The SHIORI Message charset convert utility

- `Repository <https://github.com/Narazaka/shiori_charset_convert-nim>`_

Basic Usage
=============

.. code-block:: Nim
  import shiori_charset_convert

  let utf8Request = "GET SHIORI/3.0\nCharset: Shift_JIS\nValue: ソ連を表示\n\n"
  let sjisRequest = convert(utf8Request, "shift-jis", "utf-8")

  echo shioriMessageToUtf8(sjisRequest) == utf8Request
  echo shioriMessageFromUtf8(utf8Request) == sjisRequest

With SHIORI making
=============

.. code-block:: Nim
  import shioridll
  import shiori_charset_convert
  import shiori
  import tables

  shioriLoadCallback = proc(dirpathStr: string): bool =
    true

  # Request messages can always be treated as utf-8 in callback.
  # Response messages from callback are encoded with Charset header value.
  shioriRequestCallback = autoConvertShioriMessageCharset(proc(requestStr: string): string =
    let request = parseRequest(requestStr)
    var response = newResponse(headers = {"Charset": "Shift_JIS"}.newOrderedTable)
    if request.version != "3.0":
      response.statusCode = 400
      return $response

    case request.id:
      of "version":
        response.value = "0.0.1"
      of "OnBoot":
        response.value = r"\0\s[0]aaaaaa\e"
      else:
        response.status = Status.No_Content

    $response
  )

  shioriUnloadCallback = proc(): bool =
    true

License
=============

This is released under `MIT License <https://narazaka.net/license/MIT?2018>`_.

]##

import tables
import encodings
import nre

var toUtf8 = newTable[string, EncodingConverter]()
var fromUtf8 = newTable[string, EncodingConverter]()
let charsetRe = re"(*CRLF)(?i)Charset: (.+)"

proc shioriMessageToUtf8*(str: string): string =
  let charsetMatch = str.find(charsetRe)
  if charsetMatch.isSome():
    let charset = charsetMatch.get().captures()[0]
    var conv: EncodingConverter
    if toUtf8.hasKey(charset):
      conv = toUtf8[charset]
    else:
      conv = open("utf-8", charset)
      toUtf8[charset] = conv
    conv.convert(str)
  else:
    str

proc shioriMessageFromUtf8*(str: string): string =
  let charsetMatch = str.find(charsetRe)
  if charsetMatch.isSome():
    let charset = charsetMatch.get().captures()[0]
    var conv: EncodingConverter
    if fromUtf8.hasKey(charset):
      conv = fromUtf8[charset]
    else:
      conv = open(charset, "utf-8")
      fromUtf8[charset] = conv
    conv.convert(str)
  else:
    str

proc autoConvertShioriMessageCharset*(callback: proc(str: string): string): proc(str: string): string =
  return proc(requestStr: string): string =
    shioriMessageFromUtf8(callback(shioriMessageToUtf8(requestStr)))

when isMainModule:
  import unittest

  let sj_u8req = "GET SHIORI/3.0\nCharset: Shift_JIS\nValue: ソ連を表示\n\n"
  let sj_sjreq = convert(sj_u8req, "shift-jis", "utf-8")
  let u8_u8req = "GET SHIORI/3.0\nCharset: UTF-8\nValue: ソ連を表示\n\n"

  suite "Charset: Shift_JIS":
    test "sjis to utf8":
      check(shioriMessageToUtf8(sj_sjreq) == sj_u8req)
    test "sjis from utf8":
      check(shioriMessageFromUtf8(sj_u8req) == sj_sjreq)

  suite "Charset: UTF-8":
    test "utf8 to utf8":
      check(shioriMessageToUtf8(u8_u8req) == u8_u8req)
    test "utf8 from utf8":
      check(shioriMessageFromUtf8(u8_u8req) == u8_u8req)
