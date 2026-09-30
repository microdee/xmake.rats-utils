
_rtable_operand = {}

function _rtable_operand.is_rtable() return true end

--!
-- this function gives any tables common operator overloads:
-- 
-- * `<operand> | (__bor) -> piping`  
--   Feed the left side operand table into a right side operand function, known as piping or currying
--
-- @code
-- import("@addon.rats-utils.rtable")
-- rtable({1, 2, 3, 4})
--     | {table.slice, 2, 3}
--     | table.reverse
-- -- OR
-- rtable({1, 2, 3, 4})
--     | rtable.slice(2, 3)
--     | rtable.reverse()
-- @endcode
--
-- @note Use `pack = true` to use pipes on multiple returned values, not just the first one
--
-- @note `rtable` doesn't create another instance, it modifies metadata of its input table
function main(subject)
    if type(subject) == "nil" then
        subject = {}
    end
    if type(subject) == "table" then
        if subject.is_rtable then return subject end
        return table.inherit2(subject, _rtable_operand)
    end
    return subject
end

function _call(subject, func, pack, ...)
    local result = table.pack(func(subject, ...))
    for _, item in ipairs(result) do
        if type(item) == "table" then
            main(item)
        end
    end
    if pack then
        return main(table.unwrap(result))
    end
    return table.unpack(result)
end

function _rtable_operand.__bor(subject, right)
    if type(right) == "function" then
        return _call(subject, right, false)
    elseif type(right) == "table" and type(right[1]) == "function" then
        return _call(subject, right[1], right.pack, table.unpack(table.slice(right, 2)))
    else
        raise("Right hand side operand of rtable was invalid: " .. string.serialize(right))
    end
end

function append(...)              local args = {...}; return function(subject) return table.append(         subject, table.unpack(args)) end end
function clear(...)               local args = {...}; return function(subject) return table.clear(          subject, table.unpack(args)) end end
function clone(...)               local args = {...}; return function(subject) return table.clone(          subject, table.unpack(args)) end end
function concat(...)              local args = {...}; return function(subject) return table.concat(         subject, table.unpack(args)) end end
function contains(...)            local args = {...}; return function(subject) return table.contains(       subject, table.unpack(args)) end end
function copy(...)                local args = {...}; return function(subject) return table.copy(           subject, table.unpack(args)) end end
function copy2(...)               local args = {...}; return function(subject) return table.copy2(          subject, table.unpack(args)) end end
function copy_inline(...)         local args = {...}; return function(subject) return table.copy2(          subject, table.unpack(args)) end end
function create(...)              local args = {...}; return function(subject) return table.create(         subject, table.unpack(args)) end end
function empty(...)               local args = {...}; return function(subject) return table.empty(          subject, table.unpack(args)) end end
function find_first_if(...)       local args = {...}; return function(subject) return table.find_first_if(  subject, table.unpack(args)) end end
function find_first(...)          local args = {...}; return function(subject) return table.find_first(     subject, table.unpack(args)) end end
function find_if(...)             local args = {...}; return function(subject) return table.find_if(        subject, table.unpack(args)) end end
function find(...)                local args = {...}; return function(subject) return table.find(           subject, table.unpack(args)) end end
function getn(...)                local args = {...}; return function(subject) return table.getn(           subject, table.unpack(args)) end end
function imap(...)                local args = {...}; return function(subject) return table.imap(           subject, table.unpack(args)) end end
function inherit(...)             local args = {...}; return function(subject) return table.inherit(        subject, table.unpack(args)) end end
function inherit2(...)            local args = {...}; return function(subject) return table.inherit2(       subject, table.unpack(args)) end end
function inherit_inline(...)      local args = {...}; return function(subject) return table.inherit2(       subject, table.unpack(args)) end end
function insert(...)              local args = {...}; return function(subject) return table.insert(         subject, table.unpack(args)) end end
function is_array(...)            local args = {...}; return function(subject) return table.is_array(       subject, table.unpack(args)) end end
function is_dictionary(...)       local args = {...}; return function(subject) return table.is_dictionary(  subject, table.unpack(args)) end end
function join(...)                local args = {...}; return function(subject) return table.join(           subject, table.unpack(args)) end end
function join2(...)               local args = {...}; return function(subject) return table.join2(          subject, table.unpack(args)) end end
function join_inline(...)         local args = {...}; return function(subject) return table.join2(          subject, table.unpack(args)) end end
function keys(...)                local args = {...}; return function(subject) return table.keys(           subject, table.unpack(args)) end end
function map(...)                 local args = {...}; return function(subject) return table.map(            subject, table.unpack(args)) end end
function maxn(...)                local args = {...}; return function(subject) return table.maxn(           subject, table.unpack(args)) end end
function move(...)                local args = {...}; return function(subject) return table.move(           subject, table.unpack(args)) end end
function orderkeys(...)           local args = {...}; return function(subject) return table.orderkeys(      subject, table.unpack(args)) end end
function orderpairs(...)          local args = {...}; return function(subject) return table.orderpairs(     subject, table.unpack(args)) end end
function pack(...)                local args = {...}; return function(subject) return table.pack(           subject, table.unpack(args)) end end
function remove_if(...)           local args = {...}; return function(subject) return table.remove_if(      subject, table.unpack(args)) end end
function remove(...)              local args = {...}; return function(subject) return table.remove(         subject, table.unpack(args)) end end
function reverse_unique(...)      local args = {...}; return function(subject) return table.reverse_unique( subject, table.unpack(args)) end end
function reverse(...)             local args = {...}; return function(subject) return table.reverse(        subject, table.unpack(args)) end end
function shallow_join(...)        local args = {...}; return function(subject) return table.shallow_join(   subject, table.unpack(args)) end end
function shallow_join2(...)       local args = {...}; return function(subject) return table.shallow_join2(  subject, table.unpack(args)) end end
function shallow_join_inline(...) local args = {...}; return function(subject) return table.shallow_join2(  subject, table.unpack(args)) end end
function slice(...)               local args = {...}; return function(subject) return table.slice(          subject, table.unpack(args)) end end
function swap(...)                local args = {...}; return function(subject) return table.swap(           subject, table.unpack(args)) end end
function to_array(...)            local args = {...}; return function(subject) return table.to_array(       subject, table.unpack(args)) end end
function unique(...)              local args = {...}; return function(subject) return table.unique(         subject, table.unpack(args)) end end
function unpack(...)              local args = {...}; return function(subject) return table.unpack(         subject, table.unpack(args)) end end
function unwrap(...)              local args = {...}; return function(subject) return table.unwrap(         subject, table.unpack(args)) end end
function values(...)              local args = {...}; return function(subject) return table.values(         subject, table.unpack(args)) end end
function wrap_lock(...)           local args = {...}; return function(subject) return table.wrap_lock(      subject, table.unpack(args)) end end
function wrap_unlock(...)         local args = {...}; return function(subject) return table.wrap_unlock(    subject, table.unpack(args)) end end
function wrap(...)                local args = {...}; return function(subject) return table.wrap(           subject, table.unpack(args)) end end

function last() return function(subject)
    return subject[#subject]
end end

function sort(comparer) return function(subject)
    local result = table.clone(subject)
    table.sort(result, comparer)
    return main(result)
end end

function filter(predicate) return function(subject)
    local result = table.find_if(subject, predicate) or {}
    for i = 1, #result, 1 do
        result[i] = subject[result[i]]
    end
    return main(result)
end end

function default_inline(from) return function(subject)
    subject = subject or {}
    for k, v in pairs(from) do
        if type(subject[k]) == "table" and type(v) == "table" then
            table.default_from(subject[k], v)
        elseif type(subject[k]) == "nil" then
            subject[k] = v
        end
    end
    return subject
end end

function default(from, depth) return function(subject)
    return main(subject) | clone(depth) | default_inline(from)
end end

function merge_inline(from) return function(subject)
    subject = subject or {}
    for k, v in pairs(from) do
        if type(subject[k]) == "table" and type(v) == "table" then
            table.merge_from(subject[k], v)
        else
            subject[k] = v
        end
    end
    return subject
end end

function merge(from, depth) return function(subject)
    return main(subject) | clone(depth) | merge_inline(from)
end end