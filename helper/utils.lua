--[[
 *************************************************************
 * Some Help function.
 *************************************************************
]]

local pairs  = pairs
local ipairs = ipairs
local table  = table
local type   = type
local next   = next
local assert = assert
local substr = string.sub
local string = string
local tonumber = tonumber
local tostring = tostring

--lua extension
local bd_bit32 = require("bit")
-- local bd_int64 = require('int64')
--ngx func
local md5 = ngx.md5

local utils = {}

--[[
/**
 * Generate a signature.  Should be copied into the client
 * library and also used on the server to validate signatures.
 *
 * @param table	  params	params to be signatured
 * @param string  secret	secret key used in signature
 * @param string  namespace	prefix of the param name, all params whose name are equal
 * with namespace will not be put in the signature.
 * @return string md5 signature
 **/
 ]]
function utils.generate_sig(params, secret, namespace)
	local str = {}
	local kparams = utils.ksort(params)
	local v = ''
	for i, k in ipairs(kparams) do
		if (k ~= namespace) then
			v = params[k]
			table.insert(str, tostring(k) .. '=' .. tostring(v))
		end
	end
	table.insert(str, secret)
	str = table.concat(str, '')
	return md5(str)
end

function utils.ksort(params)
	local new_arr = {}
	for k in pairs(params) do
		table.insert(new_arr, k)
	end
	table.sort(new_arr)
	return new_arr
end

function utils.trim(s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

function utils.rtrim(s)
    return (string.gsub(s, "(.-)%s*$", "%1"))
end

function utils.ltrim(s)
    return (string.gsub(s, "^%s*(.-)", "%1"))
end

-- function utils.hack_int64(num)
--   if num == nil then
--     return bd_int64.new(0) -- hack num is nil
--   end
--   if tonumber(num) ~= nil then
--     return bd_int64.new(num)
--   else
--     return bd_int64.new(0)
--   end
-- end

function utils.in_array(needle_str, source_arr)
	if type(source_arr) ~= "table" or (not next(source_arr)) then
		return false
	end
	table.sort(source_arr)
	for k, v in pairs(source_arr) do
		if v > needle_str then
			return false
		end
		if v == needle_str then
			return k
		end
	end
end

function utils.file_exists(file)
	local fh, _, errno = f_io_open(file, "r")
	if fh then
		fh:close()
		return true
	elseif errno == 2 then
		return false
	else
		assert(nil, "Error occured during file existence testing")
	end
end

--[[
dump a variable into a string
n.b. nesting depth or recursiveness times
@param mixed var
@return LUA_TSTRING
]]
function utils.simple_var_dump(var)
	local ret
	local var_type = type(var)

	if var_type == "table" then
		local dumped = {}
		local i = 1

		for k, v in pairs(var) do
			local key_type = type(k)

			if key_type == "string" then
				dumped[i] = table.concat({ "['", k, "']=", simple_var_dump(v) })
			elseif key_type == "number" then
				dumped[i] = table.concat({ "[", k, "]=", simple_var_dump(v) })
			end
			i = i + 1
		end

		ret = "{" .. table.concat(dumped, ",") .. "}"
	elseif var_type == "string" then
		ret = "'" .. var .. "'"
	elseif var_type == "number" then
		ret = var
	elseif var_type == "boolean" then
		if var then ret = "true" else ret = "false" end
	elseif var_type == "nil" then--actually useless
		ret = "nil"
	end
	return ret
end

--[[
/**
 * 前缀匹配
 * @param string haystack 源串
 * @param string needle   查找的串
 * @return true|false
 */
]]
function utils.prefix_match(haystack, needle)
	local needle_len   = #needle
	local haystack_len = #haystack
	if needle_len == haystack_len then
		return haystack == needle
	end
	haystack = substr(haystack, 1, needle_len)
	return haystack == needle
end

--[[
/**
 * 分隔字符串
 *
 * @param string delimiter	分隔表示符
 * @param string str		带分隔字符串
 * @return table | nil
 */
]]
function utils.explode(delimiter, str)
	if type(delimiter) ~= 'string' or type(str) ~= 'string' then 
		return nil
	end
	local t, pos, len = {}, 1, #delimiter
	repeat 
		pos = string.find(str, delimiter, 1, true)
		if pos then
			table.insert(t, string.sub(str, 1, pos -1))
			str = string.sub(str, pos + len)
		end
	until(not pos)
	if str and #str > 0 then
		table.insert(t, str)
	end
	return t
end

--[[
/**
 * check if the first arg ends with the second arg
 *
 * @param string str		the string to search in
 * @param string needle	the string to be searched
 * @return bool	true or false
**/
]]
function utils.ends_with(str, needle)
	if type(str) ~= 'string' or type(needle) ~= 'string' then
		return false
	end
	return string.sub(str, #str - #needle + 1) == needle
end

--[[
/**
 * check if the first arg begins with the second arg
 *
 * @param string str		the string to search in
 * @param string needle	the string to be searched
 * @return bool	true or false
**/
]]
function utils.begins_with(str, needle)
	if type(str) ~= 'string' or type(needle) ~= 'string' then
		return false
	end
	return string.sub(str, 1, #needle) == needle
end
--[[
/**
 * int2ip
 * @param  int
 * @return string
**/
]]
function utils.int2ip(num)
    tmp = tonumber(num)
    return string.format('%u.%u.%u.%u', bd_bit32.band(tmp, 0xFF), bd_bit32.band(bd_bit32.rshift(tmp, 8), 0xFF),
        bd_bit32.band(bd_bit32.rshift(tmp, 16), 0xFF), bd_bit32.band(bd_bit32.rshift(tmp, 24), 0xFF))
end

--[[
/**
 * ip2long
 * @param  string
 * @return int
**/
]]
function utils.ip2long(ip)
	local __, __, ip1, ip2, ip3, ip4 = string.find(ip, "([0-9]+)%.([0-9]+)%.([0-9]+)%.([0-9]+)")
	ip1, ip2, ip3, ip4 = tonumber(ip1), tonumber(ip2), tonumber(ip3), tonumber(ip4)
	return bd_bit32.lshift(ip1, 24) + bd_bit32.lshift(ip2, 16) + bd_bit32.lshift(ip3, 8) + ip4
end

--[[
/**
 * ip2int
 * @param  string
 * @return int
**/
]]
function utils.ip2int(ip)
    n = ip2long(ip)

    --/** convert to network order */
    local tmp1 = bd_bit32.lshift(bd_bit32.band(n, 0xFF), 24)
    local tmp2 = bd_bit32.lshift(bd_bit32.band(bd_bit32.rshift(n, 8), 0xFF), 16)
    local tmp3 = bd_bit32.lshift(bd_bit32.band(bd_bit32.rshift(n, 16), 0xFF), 8)
    local tmp4 = bd_bit32.band(bd_bit32.rshift(n, 24), 0xFF)
    n = bd_bit32.bor(bd_bit32.bor(bd_bit32.bor(tmp1, tmp2), tmp3), tmp4)
	if n < 2147483648 then
		return n
	else
		return n - 4294967296
	end
end

function utils.table_count(tbl)
	if (not tbl) or type(tbl) ~= "table" then
		return 0
	end
	local i = 0
	for _, _ in pairs(tbl) do
		i = i + 1
	end
	return i
end

--[[
/**
 * 合并两个table的value, table中的值均视为整型，并进行去重
 * @param table tabe1
 * @param table tabe1
 * @return table, int 合并后的table，以及合并后table中有多少个value
 **/
 ]]
function utils.merge_unique_table (table1, table2, convert_to_number)
    local result, result_reverse = {}, {}
    local i = 0
    if type(table1) == 'table' and
        next(table1) then
        for __, v in pairs(table1) do
        	if v then
        		if convert_to_number then
            		v = tonumber(v)
	            end
	            if v and not result_reverse[v] then
	                i = i + 1
	                result[i] = v
	                result_reverse[v] = true
	            end
        	end
        end
    end
    if type(table2) == 'table' and
        next(table1) then
        for __, v in pairs(table2) do
        	if v then
	            if v and convert_to_number then
	            	v = tonumber(v)
	            end
	            if v and not result_reverse[v] then
	                i = i + 1
	                result[i] = v
	                result_reverse[v] = true
	            end
        	end
        end
    end
    return result, i
end

--[[
/**
 * 返回在table1中且不在table2中的value，组成的table。会进行去重。
 * @param table table1
 * @return 合并后的table，以及合并后table中有多少个value
 **/
 ]]
function utils.diff_table (table1, table2)
    if type(table1) ~= 'table' or
        not next(table1) then
        return {}, 0
    end

    local result, result_reverse, table2_reverse = {}, {}, nil
    if type(table2) == 'table' and
        next(table2) then
        --创建table2的反查table
        table2_reverse = {}
        for _, v in pairs(table2) do
            if v then
                table2_reverse[v] = true
            end
        end
    end    
    
    --计算diff，并去重
    local i = 0
    for __, v in pairs(table1) do
        if v and
            (not table2_reverse or not table2_reverse[v]) and
            not result_reverse[v] then
            i = i + 1
            result[i] = v
            result_reverse[v] = true
        end
    end

    return result, i
end

function utils.parse_url(url)
    -- initialize default parameters
    local parsed = {}
    -- empty url is parsed to nil
    if not url or url == "" then return nil, "invalid url" end
    -- remove whitespace
    -- url = string.gsub(url, "%s", "")
    -- get fragment
    url = string.gsub(url, "#(.*)$", function(f)
        parsed.fragment = f
        return ""
    end)
    -- get scheme
    url = string.gsub(url, "^([%w][%w%+%-%.]*)%:",
        function(s) parsed.scheme = s; return "" end)
    -- get authority
    url = string.gsub(url, "^//([^/]*)", function(n)
        parsed.authority = n
        return ""
    end)
    -- get query stringing
    url = string.gsub(url, "%?(.*)", function(q)
        parsed.query = q
        return ""
    end)
    -- get params
    url = string.gsub(url, "%;(.*)", function(p)
        parsed.params = p
        return ""
    end)
    -- path is whatever was left
    if url ~= "" then parsed.path = url end
    local authority = parsed.authority
    if not authority then return parsed end
    authority = string.gsub(authority,"^([^@]*)@",
        function(u) parsed.userinfo = u; return "" end)
    authority = string.gsub(authority, ":([^:]*)$",
        function(p) parsed.port = p; return "" end)
    if authority ~= "" then parsed.host = authority end
    local userinfo = parsed.userinfo
    if not userinfo then return parsed end
    userinfo = string.gsub(userinfo, ":([^:]*)$",
        function(p) parsed.password = p; return "" end)
    parsed.user = userinfo
    return parsed
end

return utils
