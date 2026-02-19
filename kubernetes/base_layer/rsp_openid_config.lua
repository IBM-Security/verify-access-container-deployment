-- We're going to inject "code_challenge_methods_supported": [ "plain" ]
-- into the response payload

local cjson = require "cjson"
local payload = cjson.decode(HTTPResponse.getBody())

local pkceMethods = { "plain" }
setmetatable(pkceMethods, cjson.array_mt)
payload["code_challenge_methods_supported"] = pkceMethods
HTTPResponse.setBody(cjson.encode(payload))
