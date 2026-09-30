# Rats Utils xmake addon

Commonly usable very generic utilities for [xmake](https://xmake.io) for other xmake addons.

Manual installation before it gets canonized in XRepo:

```
xmake addon --install github:microdee/xmake.rats-utils
```

Once it's available on XRepo you can just do

```lua
add_addons("rats-utils")
```

## Features

### `rtable`

Give any table common operator overloads:

* `<operand> | (__bor) -> piping`  
  Feed the left side operand table into a right side operand function, known as piping or currying.

```lua
import("@addon.rats-utils.rtable")
rtable({1, 2, 3, 4})
    | {table.slice, 2, 3}
    | table.reverse
-- OR
rtable({1, 2, 3, 4})
    | rtable.slice(2, 3)
    | rtable.reverse()
```
> [!IMPORTANT]
> Use `pack = true` to use pipes on multiple returned values, not just the first one

> [!IMPORTANT]
> `rtable` doesn't create another instance, it modifies metadata of its input table

### `rpath`

Start a chain of paths from either `"."` or an input path, Usage:
```lua
import("@addon.rats-utils.rpath")
-- OR in description
includes("@addon/rats-utils/rpath")

local mypath = rpath() / "foo" / "bar" / "etc"
-- then convert to string with unary minus operator
print(mypath.p)              --> "/abs/scriptdir/path/foo/bar/etc"
-- or
print(mypath / "more" .."") --> "/abs/scriptdir/path/foo/bar/etc/more"
```

`mypath.p` === `mypath ..""` === `"".. mypath`  
**OR**  
`(mypath / "more").p` === `mypath / "more" ..""` === `"".. mypath / "more"`  
The only difference is that `..` has lower precedence than `/` so it can be used to append more
path items in-place without wrapping parenthesis. Furthermore this allows `rpath()` to be used in
string concatenation chain like

```lua
print("buildir=" .. mypath / "more" .. ";") --> "buildir=/abs/scriptdir/path/foo/bar/etc/more;"
```

```
This also means `mypath /  myvar .. ".txt"  / "yo"` won't compile,
but             `mypath / (myvar .. ".txt") / "yo"` is ok (result is rpath).
but then        `mypath /  myvar .. ".txt"`         is also ok (result is string)
but then again  `mypath / (myvar .. ".txt")`        is also ok (result is rpath)
```

Paths composed this way are always normalized and its built-in variables are expanded which means

```lua
print("" .. mypath / "..")          --> "/abs/scriptdir/path/foo/bar"
print("" .. mypath / ".." / "more") --> "/abs/scriptdir/path/foo/bar/more"
```
