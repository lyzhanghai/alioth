--[[
 *************************************************************
 * Config your personalise route
 *************************************************************
]]


local config = {
    hash_mapping   = {
        ['/v1/test'] = {'app.controller.testAction'}
    },
    prefix_mapping = {},
    regex_mapping  = {},
}

return config