--[[
 *************************************************************
 * Http help function.
 *************************************************************
]]
local zlib = require("zlib")
local alog = require("logger.alog")
local m_http = {}
local request = { __index = m_http}
local ngx_req = ngx.req

function m_http.new(self)
    return setmetatable(request)
end

function m_http.get_headers(self)
    local headers, err = ngx_req.get_headers()
    if err == 'truncated' then
        -- one can choose to ignore or reject the current request here
        ngx.exit(ngx.HTTP_BAD_REQUEST)
    end
    if not headers then
        return {}
    end
    return headers
end

function m_http.get_uri_data(self)
    local data, err = ngx_req.get_uri_data()
    if err == 'truncated' then
        -- one can choose to ignore or reject the current request here
        ngx.exit(ngx.HTTP_BAD_REQUEST)
    end
    return data
end

function m_http.get_form_post_data(self)
    ngx_req.read_body()
    local data, err = ngx_req.get_post_args()
    if err == 'truncated' then
        -- one can choose to ignore or reject the current request here
        ngx.exit(ngx.HTTP_BAD_REQUEST)
    end
    if not data then
        alog.warning("failed to get post data")
        ngx.exit(ngx.HTTP_BAD_REQUEST)
    end
    return data
end

local function inflate_data()
    local headers = ngx_req.get_headers()
    if headers and headers["Content-Encoding"] and headers["Content-Encoding"] == "gzip" then
        local body = ngx_req.get_body_data()
        if body then
            local status, data = pcall(zlib.inflate(), body)
            if not status then
                alog.warning("[zlip inflate error]" .. data)
                data = ""
            end
            ngx_req.set_body_data(data)
            ngx_req.set_header("Content-Encoding", "gziped")
        end
    end

end

function m_http.get_raw_post_data(self)
    inflate_data()
    local req_method = ngx_req.get_method()
    if "POST" == req_method then
        ngx_req.read_body()
        local data = ngx_req.get_body_data()
        return data
    end
    return nil
end

return m_http

