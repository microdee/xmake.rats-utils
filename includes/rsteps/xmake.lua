
--!
-- Add a step to a step-graph associated with a target or any other component which has `data` and
-- `name` members.
-- 
-- @code
-- includes("@addon/rats-utils/rsteps")
-- add_step("manifest",
--     "make-manifest",
--     {
--         depends_on = {"elaborate-file-structure", "get-permissions"},
--         triggers = "sign",
--     },
--     function()
--         -- make the manifest
--     end
-- )
-- @endcode
-- 
-- @note Relations can be scheduled at any order. Even if a dependency is not yet fully scheduled
--       the step-graph can already create an empty record for it, which can be filled in by the
--       step scheduled at a later point. The important bit is that by the time one or more steps
--       are invoked, all components had their chance to schedule their steps in the graph.
-- @note Usually scheduling is done earliest possible like `on_load` and invocation of steps are
--       done at later point (like `on_config` or later). Steps can be individually invoked at any
--       time, and other steps can use this knowledge when they're setting up their relations.
--
function add_step(graph_name, name, relations, func)
    add_values("desc_step_queue", function(target)
        import("@self.rsteps")
        rsteps.add_step(target, graph_name, name, relations, func)
    end)
end

--!
-- Easily add a sequence of steps to a step-graph associated with a target so you don't have to
-- explicitly define their chain of dependency
-- 
-- @code
-- includes("@addon/rats-utils/rsteps")
-- add_sequence("manifest",
--     "step-name", {},
--     function() --[[ do stuff ]] end, -- "step-name"
--     function() --[[ do stuff ]] end, -- "step-name2"
--     function() --[[ do stuff ]] end, -- "step-name3"
--     function() --[[ do stuff ]] end, -- "step-name4"
--     { "custom-name", function()
--         --[[ do stuff ]]
--     end},
--     function() --[[ do stuff ]] end, -- "custom-name2"
--     function() --[[ do stuff ]] end, -- "custom-name3"
--     function() --[[ do stuff ]] end, -- "custom-name4"
--     {
--         "make-manifest",
--         {
--             depends_on = {"elaborate-file-structure", "get-permissions"},
--             triggers = "sign",
--         },
--         function()
--             -- make the manifest
--         end
--     }
-- )
-- @endcode
-- 
-- By default the sequence is composed with dependency (running the last will run the rest), however
-- you can compose the sequence with triggering (running the first will run the rest) via the
-- second argument (options)
-- @code
-- add_sequence("manifest", "step-name", {trigger = true}, ...)
-- @endcode
-- 
-- The second argument can also set up relations to all given steps here
-- @code
-- add_sequence("manifest", "step-name", {triggered_by = "something-else"}, ...)
-- @endcode
-- Now `something-else` triggers this whole sequence.
-- 
-- @note Relations can be scheduled at any order. Even if a dependency is not yet fully scheduled
--       the step-graph can already create an empty record for it, which can be filled in by the
--       step scheduled at a later point. The important bit is that by the time one or more steps
--       are invoked, all components had their chance to schedule their steps in the graph.
-- @note Usually scheduling is done earliest possible like `on_load` and invocation of steps are
--       done at later point (like `on_config` or later). Steps can be individually invoked at any
--       time, and other steps can use this knowledge when they're setting up their relations.
--
function add_sequence(graph_name, ...)
    local args = {...}
    add_values("desc_step_queue", function(target)
        import("@self.rsteps")
        rsteps.add_sequence(target, graph_name, table.unpack(args))
    end)
end