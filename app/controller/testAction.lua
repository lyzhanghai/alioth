local alog = require("logger.alog")
local test = {}

function test.execute(action_param)
    ngx.say("hello world")
    alog.notice("success", 111)
end

return test
