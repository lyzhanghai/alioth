--[[
 *************************************************************
 * Load Start Up File
 *************************************************************
]]


local dispatcher = require("kernel.base.dispatcher")
local router = require("router.api")
local config = require("helper.config")
local alog = require("logger.alog")
local ngx = ngx
local app = {}

function app.start()
    config:initial()
    alog:init_alog()
    dispatcher:initial(router)
    return dispatcher:execute(ngx.var.request_uri)
end

return app
