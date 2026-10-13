rule("rsteps")
    on_load(function(target)
        import("@self.rsteps")
        import("@self.rtable", {alias = "t"})

        local desc_step_queue = target:values("desc_step_queue") | t.wrap()
        for _, item in ipairs(desc_step_queue) do
            local func = item | t.unwrap()
            debug.setfenv(func, debug.getfenv(1))
            func(target)
        end
    end)