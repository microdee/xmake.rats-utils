
includes("@addon/rats-utils/rsteps")

target("rtable-tests")
    set_kind("phony")
    on_load(function(target)
        import("@addon.rats-utils.rtable", {alias = "t"})
        local stuff = {
            "foo", "bar", "asdasd", "hello"
        }
        assert(table.contains(stuff, "asdasd"))
        assert(stuff | t.contains("asdasd"))
        assert(t.concat)
        assert(t.create)
        assert(t.remove)
        assert(t.insert)
        assert(t.move)
        assert(t.pack)
    end)

target("rsteps-tests")
    set_kind("phony")
    -- set_enabled(false)
    add_rules("@addon/rats-utils/rsteps")
    add_step("basic-graph", "1st", {}, function(ctx)
        import("@addon.rats-utils.rtable")
        print({1, 2, 3, 4} | rtable.slice(3))
    end)
    add_step("basic-graph", "2nd", { depends_on = "1st" }, function(ctx)
        print(2)
    end)
    add_step("basic-graph", "3rd", { triggered_by = "2nd" }, function(ctx)
        print(3)
    end)
    add_step("basic-graph", "4th", { depends_on = "2nd", triggers = "5th", after = "3rd" })
    add_step("basic-graph", "5th", {}, function(ctx)
        print(5)
    end)
    add_sequence("sequence-graph-dep", "seq", {},
        function() print(1) end,
        function() print(2) end,
        function() print(3) end,
        function() print(4) end,
        function() print(5) end,
        function() print(6) end,
        function() print(7) end
    )
    add_sequence("sequence-graph-trig", "seq", { trigger = true },
        function() print(1) end,
        function() print(2) end,
        function() print(3) end,
        function() print(4) end,
        function() print(5) end,
        function() print(6) end,
        function() print(7) end
    )

    on_config(function(target)
        import("@addon.rats-utils.rsteps")
        rsteps.get_steps(target, "basic-graph"):invoke("4th")
        rsteps.get_steps(target, "basic-graph"):invoke("nonexistent")
        rsteps.get_steps(target, "sequence-graph-dep"):invoke("seq5")
        rsteps.get_steps(target, "sequence-graph-trig"):invoke("seq3")
    end)