--[[
 *************************************************************
 * Route Dispatcher
 *************************************************************
]]

local string = string
local pairs = pairs
local require = require
local pcall = pcall
local ngx = ngx
local utils = require("helper.utils")
local alog = require("logger.alog")

local dispatcher = {
    hash_mapping = {},
    prefix_mapping = {},
    regex_mapping = {},
}

function dispatcher.initial(self, config)
	self.hash_mapping   = config.hash_mapping or {}
	self.prefix_mapping = config.prefix_mapping or {}
	self.regex_mapping  = config.regex_mapping or {}
	return true
end

local function parse_uri(uri)
    local length = string.find(uri, "?")
    if length then
        uri = string.sub(uri, 1, length - 1)
    end
    return string.lower(uri)
end

local function get_dispatched_action(self, request_uri)
    local raw_uri = request_uri or ""
    local parsed_uri = parse_uri(raw_uri)
    local action_config = {}
    local action_params = {}
    local action_module = ""

    if (self.hash_mapping[parsed_uri]) then
        action_config = self.hash_mapping[parsed_uri]
        action_module = action_config[1]
        action_params = action_config[2] or {}
        return action_module, action_params
    end

    for pattern, action_config in pairs(self.prefix_mapping) do
        if (utils.prefix_match(parsed_uri, pattern)) then
            action_module = action_config[1]
            action_params = action_config[2] or {}
            return action_module, action_params
        end
    end

    for pattern, action_config in pairs(self.regex_mapping) do
        if (string.find(parsed_uri, pattern)) then
            action_module = action_config[1]
            action_params = action_config[2] or {}
            return action_module, action_params
        end
    end

    local err_msg = 'No action could be dispatched for uri: ' .. uri
    return action_module, action_params, err_msg
end

local function require_module(action_module)
    local err_msg = ""
    if not action_module then
        err_msg = "action module is empty"
        return nil, err_msg
    end
    local match = string.find(action_module, "^[%a_][%w_.]*$")
    if not match then
        err_msg = 'action class name invalid: actionClassName[' .. action_module .. ']'
        return nil, err_msg
    end

    return require(action_module)
end

function dispatcher.execute(self, request_uri)
    local action_module, action_params, err_msg = get_dispatched_action(self, request_uri)
    if err_msg then
        alog.fatal("framework error :" .. err_msg)
        ngx.exit(ngx.HTTP_NOT_FOUND)
    end

    if action_module then
        local action_object, err_msg = require_module(action_module)
        if err_msg then
            alog.fatal("framework error :" .. err_msg)
            ngx.exit(ngx.HTTP_BAD_REQUEST)
        end

        local status, err_msg = pcall(action_object.execute, self, action_params)
        if not status then
            alog.warning("framework error :" .. err_msg)
            ngx.exit(ngx.HTTP_BAD_REQUEST)
        end
    end
	return true
end

return dispatcher
