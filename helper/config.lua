--[[
 *************************************************************
 * Load Application Config.
 *************************************************************
]]
local ngx = ngx
local m_config = {
    app_config = nil
}

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
    self.app_config = require(prefix .. suffix)
    if not self.app_config then
        error("application run env error")
    end
end

function m_config.get_config(self, key)
    if nil == key then
        return self.app_config
    else
        return self.app_config[key]
    end
    return {}
end

return m_config
