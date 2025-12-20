-- notification_center/json.lua
-- Minimal JSON encoder/decoder for notification history

local json = {}

-- Encode Lua table to JSON string
function json.encode(value)
    local t = type(value)
    
    if t == "nil" then
        return "null"
    elseif t == "boolean" then
        return value and "true" or "false"
    elseif t == "number" then
        return tostring(value)
    elseif t == "string" then
        -- Escape special characters
        local escaped = value:gsub('\\', '\\\\')
                             :gsub('"', '\\"')
                             :gsub('\n', '\\n')
                             :gsub('\r', '\\r')
                             :gsub('\t', '\\t')
        return '"' .. escaped .. '"'
    elseif t == "table" then
        -- Check if array or object
        local is_array = true
        local max_index = 0
        for k, _ in pairs(value) do
            if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
                is_array = false
                break
            end
            max_index = math.max(max_index, k)
        end
        is_array = is_array and max_index == #value
        
        if is_array then
            local parts = {}
            for i, v in ipairs(value) do
                parts[i] = json.encode(v)
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            local parts = {}
            for k, v in pairs(value) do
                if type(k) == "string" then
                    table.insert(parts, json.encode(k) .. ":" .. json.encode(v))
                end
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    end
    
    return "null"
end

-- Decode JSON string to Lua table
function json.decode(str)
    if not str or str == "" then
        return nil
    end
    
    local pos = 1
    
    local function skip_whitespace()
        while pos <= #str and str:sub(pos, pos):match("%s") do
            pos = pos + 1
        end
    end
    
    local function parse_string()
        pos = pos + 1  -- Skip opening quote
        local start = pos
        local result = ""
        
        while pos <= #str do
            local c = str:sub(pos, pos)
            if c == '"' then
                pos = pos + 1
                return result
            elseif c == '\\' then
                pos = pos + 1
                local escaped = str:sub(pos, pos)
                if escaped == 'n' then result = result .. '\n'
                elseif escaped == 'r' then result = result .. '\r'
                elseif escaped == 't' then result = result .. '\t'
                elseif escaped == '"' then result = result .. '"'
                elseif escaped == '\\' then result = result .. '\\'
                else result = result .. escaped
                end
                pos = pos + 1
            else
                result = result .. c
                pos = pos + 1
            end
        end
        
        return result
    end
    
    local function parse_number()
        local start = pos
        while pos <= #str and str:sub(pos, pos):match("[%d%.%-eE%+]") do
            pos = pos + 1
        end
        return tonumber(str:sub(start, pos - 1))
    end
    
    local parse_value  -- Forward declaration
    
    local function parse_array()
        local arr = {}
        pos = pos + 1  -- Skip [
        skip_whitespace()
        
        if str:sub(pos, pos) == ']' then
            pos = pos + 1
            return arr
        end
        
        while true do
            table.insert(arr, parse_value())
            skip_whitespace()
            
            if str:sub(pos, pos) == ']' then
                pos = pos + 1
                return arr
            elseif str:sub(pos, pos) == ',' then
                pos = pos + 1
                skip_whitespace()
            else
                break
            end
        end
        
        return arr
    end
    
    local function parse_object()
        local obj = {}
        pos = pos + 1  -- Skip {
        skip_whitespace()
        
        if str:sub(pos, pos) == '}' then
            pos = pos + 1
            return obj
        end
        
        while true do
            skip_whitespace()
            local key = parse_string()
            skip_whitespace()
            pos = pos + 1  -- Skip :
            skip_whitespace()
            obj[key] = parse_value()
            skip_whitespace()
            
            if str:sub(pos, pos) == '}' then
                pos = pos + 1
                return obj
            elseif str:sub(pos, pos) == ',' then
                pos = pos + 1
            else
                break
            end
        end
        
        return obj
    end
    
    parse_value = function()
        skip_whitespace()
        local c = str:sub(pos, pos)
        
        if c == '"' then
            return parse_string()
        elseif c == '{' then
            return parse_object()
        elseif c == '[' then
            return parse_array()
        elseif c == 't' and str:sub(pos, pos + 3) == "true" then
            pos = pos + 4
            return true
        elseif c == 'f' and str:sub(pos, pos + 4) == "false" then
            pos = pos + 5
            return false
        elseif c == 'n' and str:sub(pos, pos + 3) == "null" then
            pos = pos + 4
            return nil
        elseif c:match("[%d%-]") then
            return parse_number()
        end
        
        return nil
    end
    
    return parse_value()
end

return json
