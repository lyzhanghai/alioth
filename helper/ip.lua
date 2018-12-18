--[[
 *************************************************************
 * Get client IP address.
 *************************************************************
]]

local utils = require("helper.utils")
local str_find = string.find
local str_sub = string.sub
local ngx_req = ngx.req
local ngx_var = ngx.var
local m_ip = {}

function m_ip.get_client_ip()
    local ip = "127.0.0.1"
    if ngx_req.get_headers()['x_forwarded_for'] then
        local ip_str = ngx_req.get_headers()['x_forwarded_for']
        local ip_tab = utils.explode(",", ip_str)
        if type(ip_tab) == "table" and #ip_tab >= 1 then
            ip = ip_tab[#ip_tab]
        end
    elseif ngx_var.http_clientip then
        ip = ngx_var.http_clientip
    elseif ngx_var.remote_addr then
        ip = ngx_var.remote_addr
    end

    local pos = str_find(ip, ",", 1, true)
    if pos then
        ip = str_sub(ip, 1, pos - 1)
    end

    return utils.trim(ip)
end

return m_ip
