--[[
 *************************************************************
 * Load Application Config.
 *************************************************************
]]
local ngx = ngx
local m_config = {}

function m_config.initial(self)
    local run_env = ngx.ctx.app.run_env
    local prefix = "config.config"
    local suffix = ""
    if "dev" == run_env then
        suffix = "Dev"
    elseif "test" == run_env then
        suffix = "Test"
    elseif "prod" == run_env then
        suffix = "Prod"
    end
    ngx.ctx.app.env_config = require(prefix .. suffix)
    if not ngx.ctx.app.env_config then
        error("application run env error")
    end
end

function m_config.get_config(self, key)
    if nil == key then
        return ngx.ctx.app.env_config
    else
        return ngx.ctx.app.env_config[key]
    end
    return nil
end

return m_config
