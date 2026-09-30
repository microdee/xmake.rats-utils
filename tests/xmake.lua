

target("rtable-tests")
    set_kind("phony")
    on_load(function(target)
        import("@addon.rats-utils.rtable")
        local stuff = rtable({
            "foo", "bar", "asdasd", "hello"
        })
        assert(table.contains(stuff, "asdasd"))
        assert(stuff | rtable.contains("asdasd"))
    end)