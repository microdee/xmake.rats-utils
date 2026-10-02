
_rtable_operand = {
    func = nil,
    args = {}
}

--!
-- this function gives any tables common operator overloads:
-- 
-- * `<operand> | (__bor) -> piping`  
--   Feed the left side operand table into a right side operand function, known as piping or currying
--
-- @code
-- import("@addon.rats-utils.rtable", {alias = "t"})
-- {1, 2, 3, 4}
--     | t(table.slice, 2, 3)
--     | t(table.reverse)
-- -- OR
-- {1, 2, 3, 4}
--     | t.slice(2, 3)
--     | t.reverse()
-- @endcode
--
function main(func, ...)
    return _rtable_operand:new(func, ...)
end

function _rtable_operand:new(func, ...)
    local result = table.inherit({}, self)
    result.func = func
    result.args = {...}
    return result
end

function _rtable_operand.__bor(left, right)
    return right.func(left, table.unpack(right.args))
end

function append(...)              return main(table.append,         ...) end
function clear(...)               return main(table.clear,          ...) end
function clone(...)               return main(table.clone,          ...) end
function contains(...)            return main(table.contains,       ...) end
function empty(...)               return main(table.empty,          ...) end
function find_first_if(...)       return main(table.find_first_if,  ...) end
function find_first(...)          return main(table.find_first,     ...) end
function find_if(...)             return main(table.find_if,        ...) end
function find(...)                return main(table.find,           ...) end
function getn(...)                return main(table.getn,           ...) end
function imap(...)                return main(table.imap,           ...) end
function inherit(...)             return main(table.inherit,        ...) end
function inherit2(...)            return main(table.inherit2,       ...) end
function inherit_inline(...)      return main(table.inherit2,       ...) end
function is_array(...)            return main(table.is_array,       ...) end
function is_dictionary(...)       return main(table.is_dictionary,  ...) end
function join_inline(...)         return main(table.join2,          ...) end
function join(...)                return main(table.join,           ...) end
function join2(...)               return main(table.join2,          ...) end
function keys(...)                return main(table.keys,           ...) end
function map(...)                 return main(table.map,            ...) end
function maxn(...)                return main(table.maxn,           ...) end
function orderkeys(...)           return main(table.orderkeys,      ...) end
function orderpairs(...)          return main(table.orderpairs,     ...) end
function pack(...)                return main(table.pack,           ...) end
function remove_if(...)           return main(table.remove_if,      ...) end
function reverse_unique(...)      return main(table.reverse_unique, ...) end
function reverse(...)             return main(table.reverse,        ...) end
function shallow_join(...)        return main(table.shallow_join,   ...) end
function shallow_join2(...)       return main(table.shallow_join2,  ...) end
function shallow_join_inline(...) return main(table.shallow_join2,  ...) end
function slice(...)               return main(table.slice,          ...) end
function swap(...)                return main(table.swap,           ...) end
function to_array(...)            return main(table.to_array,       ...) end
function unique(...)              return main(table.unique,         ...) end
function unwrap(...)              return main(table.unwrap,         ...) end
function values(...)              return main(table.values,         ...) end
function wrap_lock(...)           return main(table.wrap_lock,      ...) end
function wrap_unlock(...)         return main(table.wrap_unlock,    ...) end
function wrap(...)                return main(table.wrap,           ...) end

function concat(...) return main(function(...) table.concat(...) end, ...) end
function create(...) return main(function(...) table.create(...) end, ...) end
function remove(...) return main(function(...) table.remove(...) end, ...) end
function insert(...) return main(function(...) table.insert(...) end, ...) end
function move(...)   return main(function(...) table.move(...)   end, ...) end

function last()
    return main(function(subject)
        return subject[#subject]
    end)
end

function sort(...)
    return main(function(subject, comparer)
        local result = table.clone(subject)
        table.sort(result, comparer)
        return result
    end, ...)
end

function filter(...)
    return main(function(subject, predicate)
        local result = table.find_if(subject, predicate) or {}
        for i = 1, #result, 1 do
            result[i] = subject[result[i]]
        end
        return result
    end, ...)
end

function default_inline(...)
    return main(function(subject, from)
        subject = subject or {}
        for k, v in pairs(from) do
            if type(subject[k]) == "table" and type(v) == "table" then
                table.default_from(subject[k], v)
            elseif type(subject[k]) == "nil" then
                subject[k] = v
            end
        end
        return subject
    end, ...)
end

function default(...)
    return main(function(subject, from, depth)
        return subject | clone(depth) | default_inline(from)
    end, ...)
end

function merge_inline(...)
    return main(function(subject, from)
        subject = subject or {}
        for k, v in pairs(from) do
            if type(subject[k]) == "table" and type(v) == "table" then
                table.merge_from(subject[k], v)
            else
                subject[k] = v
            end
        end
        return subject
    end, ...)
end

function merge(...)
    return main(function(subject, from, depth)
        return subject | clone(depth) | merge_inline(from)
    end, ...)
end