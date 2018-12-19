--[[
 *************************************************************
 * Log Recorder
 *************************************************************
]]

local f_os_date = os.date
local f_io_open = io.open
local f_str_format = string.format
local v_ngx_var = ngx.var

local require = require
local m_ip = require("helper.ip")

local math    = math
local tostring = tostring
local ngx = ngx
local error = error

local alog = {
}

local LOG_LEVEL_FATAL = 0x01
local LOG_LEVEL_WARNING = 0x02
local LOG_LEVEL_NOTICE = 0x04
local LOG_LEVEL_TRACE = 0x06
local LOG_LEVEL_DEBUG = 0x08
local LOG_LEVEL_ALL = 0x10

local LOG_LEVEL_NAMES = {
	[LOG_LEVEL_FATAL] = "FATAL",
	[LOG_LEVEL_WARNING] = "WARNING",
	[LOG_LEVEL_NOTICE] = "NOTICE",
	[LOG_LEVEL_TRACE] = "TRACE",
	[LOG_LEVEL_DEBUG] = "DEBUG",
	[LOG_LEVEL_ALL] = "ALL"
}

function alog.get_log_id(self)
    if ngx.ctx.app.env_config.log.log_id then
        return ngx.ctx.app.env_config.log.log_id
    end
    local now_time = ngx.req.start_time() * 1000
    local work_id = ngx.worker.pid()
    math.randomseed(tostring(now_time):reverse():sub(1,6))
    local random = math.random(1000, 9999)
    local log_id = now_time .. work_id .. random
    ngx.ctx.app.env_config.log.log_id = log_id
    return log_id
end

local function log_level_check(log_level)
    for k, v in pairs(LOG_LEVEL_NAMES) do
        if v == log_level then
            ngx.ctx.app.env_config.log.log_level = k
            return true
        end
    end
    error("log level " .. log_level .. "error")
end

function alog.init_alog(self)
    ngx.ctx.app.env_config.log.log_id = self:get_log_id()
    log_level_check(ngx.ctx.app.env_config.log.log_level)
end

local function write_log(log_level, message, err_no)
    if ngx.ctx.app.env_config.log.log_level < log_level then
        return true
    end
    local log_file = ngx.ctx.app.env_config.log.log_path
    local file_suffix = ""
    if log_level <= LOG_LEVEL_WARNING then
        file_suffix = file_suffix .. ".wf"
    end
    local cutting = ""
    if ngx.ctx.app.env_config.log.log_cutting == 'h' then
        cutting = f_os_date("%Y%m%d%H")
    else
        cutting = f_os_date("%Y%m%d")
    end
    if file_suffix == "" then
        log_file = log_file .. "." .. cutting
    else
        log_file = log_file .. "." .. cutting .. "." .. file_suffix
    end

    local content = f_str_format("%s: %s err_no[%d] ip[%s] log_id[%s] uri[%s] %s\n",
        LOG_LEVEL_NAMES[log_level] or "NONE", ngx.utctime(), err_no, m_ip.get_client_ip(),
            ngx.ctx.app.env_config.log.log_id, v_ngx_var.request_uri, message
    )

    local fh, err = f_io_open(log_file, "a")
    if not fh then
        error("can not open file " .. log_file)
    end
    local r, err = fh:write(content)
    if not r then
        fh:close()
        error("write file " .. log_file .. "fail")
    end
    fh:close()
    return true

end

function alog.notice(str, err_no)
    err_no = err_no or 0
	return write_log(LOG_LEVEL_NOTICE, str, err_no)
end

function alog.warning(str, err_no)
    err_no = err_no or 0
	return write_log(LOG_LEVEL_WARNING, str, err_no)
end

function alog.trace(str, err_no)
    err_no = err_no or 0
    return write_log(LOG_LEVEL_TRACE, str, err_no)
end

function alog.fatal(str, err_no)
    err_no = err_no or 0
    return write_log(LOG_LEVEL_FATAL, str, err_no)
end

function alog.debug(str, err_no)
    err_no = err_no or 0
    return write_log(LOG_LEVEL_DEBUG , str, err_no)
end

return alog

