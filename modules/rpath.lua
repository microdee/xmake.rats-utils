
if not import and _rpath_include_guard then return end _rpath_include_guard = {}

_rpath_operand = {}

function resolve(p, options)
    options = options or {}
    local pf = options.plain and p or vformat(p)
    return (options.plain or options.relative)
        and path.normalize(path.translate(pf))
        or  path.normalize(path.absolute(path.translate(pf)))
end

--!
-- Start a chain of paths from either "." or an input path, Usage:
-- @code
-- import("@addon.rats-utils.rpath")
-- -- OR in description
-- includes("@addon/rats-utils/rpath")
--
-- local mypath = rpath() / "foo" / "bar" / "etc"
-- -- then convert to string with unary minus operator
-- print(mypath.p)              --> "/abs/scriptdir/path/foo/bar/etc"
-- -- or
-- print("" .. mypath / "more") --> "/abs/scriptdir/path/foo/bar/etc/more"
-- 
-- `mypath.p` === `"" .. mypath`
-- OR
-- `(mypath/ "more").p` === `"" .. mypath / "more"`
-- The only difference is that because .. has lower precedence than / it can be used to append more
-- path items in-place without wrapping parenthesis. Furthermore this allows rpath() to be used in
-- string concatenation chain like
-- 
-- print("buildir=" .. mypath / "more" .. ";") --> "buildir=/abs/scriptdir/path/foo/bar/etc/more;"
-- 
-- This also means `mypath /  myvar .. ".txt"  / "yo"` won't compile,
-- but             `mypath / (myvar .. ".txt") / "yo"` is ok (result is rpath).
-- but then        `mypath /  myvar .. ".txt"`         is also ok (result is string)
-- but then again  `mypath / (myvar .. ".txt")`        is also ok (result is rpath)
-- 
-- Paths composed this way are always normalized and its built-in variables are expanded which means
-- 
-- print("" .. mypath / "..")          --> "/abs/scriptdir/path/foo/bar"
-- print("" .. mypath / ".." / "more") --> "/abs/scriptdir/path/foo/bar/more"
-- 
function rpath(subject, options)
    if type(subject) == "table" and subject.p then return subject end
    local result = {}
    result.p = resolve(subject or ".", options)
    result.options = options
    return table.inherit2(result, _rpath_operand)
end

if import then
    function main(...) return rpath(...) end
end

function _rpath_operand.__div(self, next)
    local result = table.clone(self, -1)
    result.p = resolve(path.join(self.p, next), result.options)
    return result
end

function _rpath_operand.__concat(lh, rh)
    if type(lh) == "string" then
        return lh .. rh.p
    end
    return lh.p .. rh
end