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
import("@addon.rats-utils.rtable", {alias = "t"})
local result = {1, 2, 3, 4}
    | t(table.slice, 2, 3)
    | t(table.reverse)
-- OR
local result = {1, 2, 3, 4}
    | t.slice(2, 3)
    | t.reverse()
```

> [!NOTE]
> Discarding the results of `|` or apparently any operator is a syntax error in lua. I guess it's an opinionated stance about how these operators shouldn't have side effects. In any case it means that free standing expressions like `a | t.append(b)` are not allowed.

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

### `rsteps`

A fully customizable graph of steps each declaring their own relationship to others. This was inspired by Nuke/Fallout/Cake targets which can declare their position in the graph of tasks very expressively. `rsteps` can give you step-graph instances which provides a context for the co-relating steps. For example a rule may expose its inner working, and may let its users hook into its behavior, via individual step-graphs associated with each target.

```lua
target("rsteps-tests")
    set_kind("phony")
    add_rules("@addon/rats-utils/rsteps") -- allows more easy scheduling of steps from description scope

    add_step("basic-graph", "1st", {}, function(ctx)
        print(1)
    end)
    add_step("basic-graph", "2nd", { depends_on = "1st" }, function(ctx)
        print(2)
    end)
    add_step("basic-graph", "3rd", { triggered_by = "2nd" }, function(ctx)
        print(3)
    end)
    add_step("basic-graph", "4th", { depends_on = "2nd", triggers = "5th" }) -- function is optional!
    add_step("basic-graph", "5th", {}, function(ctx)
        print(5)
    end)
    on_config(function(target)
        import("@addon.rats-utils.rsteps")
        rsteps.get_steps(target, "basic-graph"):invoke("4th") -- invoke these steps and their relations
    end)
```

Setting up a chain of tasks like this however can be pretty tedious, especially when their depency graph is just a straight line. For that reason you also have `add_sequence` convenience function:

```lua
target("rsteps-tests")
    set_kind("phony")
    add_rules("@addon/rats-utils/rsteps") -- allows more easy scheduling of steps from description scope

    -- steps are woven together via dependency by default, so last step depends on previous one
    -- and all steps are executed if the last step is invoked
    add_sequence("sequence-graph-dep", "seq", {}, 
        function() print(1) end,
        function() print(2) end,
        function() print(3) end,
        function() print(4) end
    )
    
    -- OR steps may be woven together via triggering, so first step triggers the second
    -- and all steps are executed if the first step is invoked
    add_sequence("sequence-graph-trig", "seq", { trigger = true },
        function() print(1) end,
        function() print(2) end,
        function() print(3) end,
        function() print(4) end
    )
    
    on_config(function(target)
        import("@addon.rats-utils.rsteps")
        rsteps.get_steps(target, "sequence-graph-dep"):invoke("seq4")
        rsteps.get_steps(target, "sequence-graph-trig"):invoke("seq")
    end)
```

You can also name steps individually in `add_sequence`, which is actually recommended for publicly hookable step-graphs. The following example also demonstrates the usability in rules. `add_sequence` (and `add_step`) has the same usage in both description and script scopes.

```lua
rule("engine-rule")
    add_deps("@addon/rats-utils/rsteps") -- allows more easy scheduling of steps from description scope
    on_load(function(target)
        import("@addon.rats-utils.rsteps")
        rsteps.add_sequence(target, "engine", "seq", { trigger = true }, 
            { "intake", function() print(1) end },
            { "compress", function() print(2) end },
            { "combust", function() print(3) end },
            { "exhaust", function() print(4) end }
        )
    end)
    
    on_config(function(target)
        import("@addon.rats-utils.rsteps")
        rsteps.get_steps(target, "engine"):invoke("intake")
    end)

target("engine")
    set_kind("phony")
    add_rules("engine-rule")
    add_step(
        "engine", "spark_plug",
        {
            dependent_for = "combust",
            after = "compress"
        },
        function(ctx)
            print("zap")
        end
    )
```

Actually a step-graph can be created in any context in the script scope, not just for targets. Only the description scope API is bound currently to targets. A global one could be also nice (TODO).