--[[
 *************************************************************
 * Load Start Up File
 *************************************************************
]]


local dispatcher = require("kernel.base.dispatcher")
local router = require("router.api")
local config = require("helper.config")
local ngx = ngx
local app = {}

function app.start()
    config:initial()
    dispatcher:initial(router)
    return dispatcher:execute(ngx.var.request_uri)
end

return app
