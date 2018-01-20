# shiori_charset_convert

The SHIORI Message charset convert utility for Nim lang

## Install

```
nimble install shiori_charset_convert
```

## Basic Usage

```nim
import shiori_charset_convert

let utf8Request = "GET SHIORI/3.0\nCharset: Shift_JIS\nValue: ソ連を表示\n\n"
let sjisRequest = convert(utf8Request, "shift-jis", "utf-8")

echo shioriMessageToUtf8(sjisRequest) == utf8Request
echo shioriMessageFromUtf8(utf8Request) == sjisRequest
```

## With SHIORI making

```nim
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
```

## License

This is released under [MIT License](https://narazaka.net/license/MIT?2018).
