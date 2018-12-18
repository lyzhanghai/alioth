--[[
 *************************************************************
 * Create The Application.
 *************************************************************
]]
local app = require ("kernel.base.application")
ngx.header["Content-Type"] = "text/html"

--[[
 *************************************************************
 *  Decide The Run Env.
 *************************************************************
]]
local ngx = ngx
-- run_env can be dev, test, prod.
ngx.ctx.app = {}
ngx.ctx.app.run_env = ngx.var.run_env or "test"

--[[
 *************************************************************
 *  Run The Application.
 *************************************************************
]]
app.start()

