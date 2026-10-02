import("core.base.graph")
import("@self.rtable",  {alias = "t"})

--!
-- Represents a step and its relationship to other steps in a step-graph. One step can be submitted
-- to multiple graphs
--
_step = {

    name = "",

    --!
    -- *Optional*. If left as nil, the step can be used as a shared node in graph relationships
    -- 
    -- @param    context: A custom table set for this graph
    -- @param  this_step: Current step
    -- @param step_graph: The graph this step is participating in
    -- @return Something truthy for aborting the entire step-graph in an invocation
    --
    func = nil,
    
    --! Steps which should always implicitly run before this one.
    depends_on = {},
    
    --! If these steps are triggered, then this step will run before them.
    dependent_for = {},
    
    --! If both this step and these steps are triggered, then this step should run before them.
    before = {},
    
    --! If both this step and these steps are triggered, then this step should run after them.
    after = {},

    --! If this step is triggered then it also implicitly triggers these steps after this step.
    triggers = {},
    
    --!
    -- When these steps are triggered, they also implicitly trigger this step after they're all
    -- finished.
    --
    triggered_by = {},
}

function _step:new(name)
    result = table.clone(self, 100)
    result.name = name
    return result
end

function _step:merge(other)
    self.func = other.func or self.func
    table.join2(self.depends_on    ,other.depends_on    | t.wrap())
    table.join2(self.dependent_for ,other.dependent_for | t.wrap())
    table.join2(self.before        ,other.before        | t.wrap())
    table.join2(self.after         ,other.after         | t.wrap())
    table.join2(self.triggers      ,other.triggers      | t.wrap())
    table.join2(self.triggered_by  ,other.triggered_by  | t.wrap())
    return self
end

function _step:with_func(func)
    self.func = func
    return self
end

--! Get all steps related to this one somehow
function _step:relatives()
    return self.depends_on
        | t.join(self.dependent_for)
        | t.join(self.before)
        | t.join(self.after)
        | t.join(self.triggers)
        | t.join(self.triggered_by)
        | t.unique()
end

--!
-- Make a reusable step:
-- @code
-- local make_manifest = rsteps.step(
--     "make-manifest",
--     {
--         depends_on = {"elaborate-file-structure", "get-permissions"},
--         triggers = "sign",
--     },
--     function()
--         -- make the manifest
--     end
-- )
-- local publish = rsteps.step("publish", { depends_on = {"make-manifest", "sign"} }, function()
--     -- publish
-- end)
-- some_graph:with_steps(make_manifest, publish)
-- some_other_graph:with_steps(make_manifest, publish)
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
function step(name, relations, func)
    local new_step = _step:new(name):with_func(func):merge(relations)
    return new_step
end

_edge = {
    from = "",
    to = "",
    dependency = false,
    triggers = false,
    order = false
}

function _edge:new()
    return table.clone(self, 100)
end

function _edge:merge(other)
    other = other or {}
    self.dependency = self.dependency or other.dependency
    self.triggers = self.triggers or other.triggers
    self.order = self.order or other.order
    return self
end

function edge_name(from, to)
    return from .. "---" .. to
end

function _edge:name()
    return edge_name(self.from, self.to)
end

--!
-- Represent a highly composable graph of steps which may be organized in multiple places
-- and their order of execution is critical. Any step in this graph can be triggered independently
-- and their order, dependencies and triggers will be executed with them.
--
_step_graph = {

    name = "",

    --! Use it for sharing information among all the steps which may be triggered
    context = nil,

    --! The steps make the vertices of this graph
    steps = {},
    
    --!
    -- The edges between steps will always maintain their supposed execution order
    -- (earlier to later). They also represent the kind of the relation between two steps
    edges = {},

    --! Actual backend graph for the steps.
    step_graph = {}
}

function _step_graph:new(name, context)
    local result = table.clone(self, 100)
    result.name = name
    result.context = context
    result.step_graph = graph.new(true)
    return result
end

--!
-- Make a highly composable graph of steps which may be organized in multiple places and their
-- order of execution is critical. Any step in this graph can be triggered independently and their
-- order, dependencies and triggers will be executed with them.
--
function make_graph(name, context)
    return _step_graph:new(name, context)
end

function _step_graph:make_edge(a, b)
    local new_edge = _edge:new()
    if a.dependent_for | t.contains(b.name) or b.depends_on | t.contains(a.name) then
        new_edge.from = a.name
        new_edge.to = b.name
        new_edge.dependency = true
    elseif a.depends_on | t.contains(b.name) or b.dependent_for | t.contains(a.name) then
        new_edge.from = b.name
        new_edge.to = a.name
        new_edge.dependency = true
    elseif a.triggers | t.contains(b.name) or b.triggered_by | t.contains(a.name) then
        new_edge.from = a.name
        new_edge.to = b.name
        new_edge.triggers = true
    elseif a.triggered_by | t.contains(b.name) or b.triggers | t.contains(a.name) then
        new_edge.from = b.name
        new_edge.to = a.name
        new_edge.triggers = true
    elseif a.before | t.contains(b.name) or b.after | t.contains(a.name) then
        new_edge.from = a.name
        new_edge.to = b.name
        new_edge.order = true
    elseif a.after | t.contains(b.name) or b.before | t.contains(a.name) then
        new_edge.from = b.name
        new_edge.to = a.name
        new_edge.order = true
    else
        return nil
    end
    local existed = self.edges[new_edge:name()]
    self.edges[new_edge:name()] = new_edge:merge(existed)
    if not existed then
        self.step_graph:add_edge(new_edge.from, new_edge.to)
    end
    return new_edge
end

--! Equivalent of returning nothing
function continue() return nil end

--! Signal that the context where a function is called should halt everything related
function halt() return "break" end

--!
-- Signal to not continue with the specific context where a function is called but let other
-- parallel matters continue their work
--
function stop() return "stop" end

--!
-- Add a step to this step-graph
-- @code
-- mystepgraph:add(
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
function _step_graph:add(...)
    local args = {...}
    local new_step = #args == 1 and args[1] or step(...)
    if not new_step.name then
        raise("Step name was nil")
    end
    if new_step.name:find("---") then
        raise("Step name " .. new_step.name .. " cannot contain sequence '---'")
    end
    if self.steps[new_step.name] then
        new_step = self.steps[new_step.name]:merge(new_step)
    end
    self.step_graph:add_vertex(new_step.name)
    self.steps[new_step.name] = new_step
    for _, relative in ipairs(new_step:relatives()) do
        self.steps[relative] = self.steps[relative] or _step:new(relative)
        self:make_edge(new_step, self.steps[relative])
        local cycle = self.step_graph:find_cycle()
        if cycle then
            cprint("${bright red}Cannot add step %s in %s, because that would form a cyclic step-graph", new_step.name, self.name)
            for _, c in ipairs(cycle) do
                print(c)
            end
            print(self.step_graph:dump())
            raise("Cyclic steps found in step-graph")
        end
    end
    return new_step
end

--!
-- Add multiple steps to this stepgraph in one go:
-- @code
-- mystepgraph:with_steps(
--     rsteps.step(
--         "make-manifest",
--         {
--             depends_on = {"elaborate-file-structure", "get-permissions"},
--             triggers = "sign",
--         },
--         function()
--             -- make the manifest
--         end
--     ),
--     rsteps.step("publish", { depends_on = {"make-manifest", "sign"} }, function()
--         -- publish
--     end)
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
function _step_graph:with_steps(...)
    for _, step in {...} do
        self:add(step)
    end
    return self
end

--!
-- Easily add a sequence of steps so you don't have to explicitly define their chain of dependency
-- @code
-- mystepgraph:with_sequence(
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
-- mystepgraph:with_sequence("step-name", {trigger = true}, ...)
-- @endcode
-- 
-- The second argument can also set up relations to all given steps here
-- @code
-- mystepgraph:with_sequence("step-name", {triggered_by = "something-else"}, ...)
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
function _step_graph:with_sequence(name, options, ...)
    local last_name = name
    local previous_name = nil
    local idx = 1
    for _, func in ipairs({...}) do
        local relations = _step:new():merge(options)
        if previous_name then
            if options.trigger then
                relations = { triggered_by = previous_name }
            else
                relations = { depends_on = previous_name }
            end
        end
        local step_name = idx <= 1 and last_name or last_name .. idx
        if type(func) == "function" then
            self:add(step_name, relations, func)
        elseif #func == 2 then
            last_name = func[1]
            step_name = func[1]
            idx = 0
            self:add(step_name, relations, func[2])
        elseif #func == 3 then
            last_name = func[1]
            step_name = func[1]
            idx = 0
            self:add(step(step_name, func[2], func[3]):merge(relations))
        end
        previous_name = step_name
        idx = idx + 1
    end
    return self
end

function forward() return 2 end
function backward() return 1 end

function _step_graph:visit_step(from, direction, visitor, depth)
    depth = depth or 1
    for key, edge in pairs(self.edges) do
        local vertices = key:split("---", {plain = true})
        local from_candidate = vertices[3 - direction]
        local to_candidate = vertices[direction]
        if from_candidate == from then
            local response = visitor(edge, self.steps[from_candidate], self.steps[to_candidate], depth)
            if not response then
                response = self:visit_step(to_candidate, direction, visitor, depth + 1)
            end
            if response == halt() then
                return halt()
            end
        end
    end
end

_invoke_graph_visitor = {
    step_graph = {},
    invoke_graph = {},
    order_edges = {}
}

function _invoke_graph_visitor:new(step_graph)
    result = table.clone(self, 100)
    result.invoke_graph = graph.new()
    result.step_graph = step_graph
    return result
end

function _invoke_graph_visitor:add_invoke_edge(earlier_name, later_name)
    if not self.invoke_graph:has_edge(earlier_name, later_name) then
        self.invoke_graph:add_edge(earlier_name, later_name)
    end
end

function _invoke_graph_visitor:visit_forward(edge, earlier, later)
    if edge.triggers then
        self:add_invoke_edge(earlier.name, later.name)
        self:visit_neighbours(later)
    end
    return stop()
end

function _invoke_graph_visitor:visit_backward(edge, later, earlier)
    if edge.dependency then
        self:add_invoke_edge(earlier.name, later.name)
        self:visit_neighbours(earlier)
    elseif edge.order then
        table.append(self.order_edges, edge)
    end
    return stop()
end

function _invoke_graph_visitor:visit_neighbours(step)
    if not self.invoke_graph:has_vertex(step.name) then
        self.invoke_graph:add_vertex(step.name)
    end
    self.step_graph:visit_step(step.name, forward(), function(edge, earlier, later)
        return self:visit_forward(edge, earlier, later)
    end)
    
    self.step_graph:visit_step(step.name, backward(), function(edge, later, earlier)
        return self:visit_backward(edge, later, earlier)
    end)
end

function _invoke_graph_visitor:apply_order_edges()
    for _, edge in ipairs(self.order_edges) do
        if self.invoke_graph:has_vertex(edge.from) and self.invoke_graph:has_vertex(edge.to) then
            self:add_invoke_edge(edge.from, edge.to)
        end
    end
end

--!
-- Run these steps and their dependencies/triggers in this graph in the correct order. Don't run
-- this in `on_load` since that's the earliest opportunity when targets, rules, packages can
-- schedule their steps
--
function _step_graph:invoke(...)
    local steps = {...}
    if #steps == 0 then return end

    local visitor = _invoke_graph_visitor:new(self)

    for _, stepname in ipairs(steps) do
        local step = self.steps[stepname]
        if step then
            visitor:visit_neighbours(step)
        end
    end
    visitor:apply_order_edges()
    local ordered, cyclic = visitor.invoke_graph:topo_sort()
    if not cyclic then
        if #ordered == 0 then
            cprint("${red}There was nothing to run in: " .. self.name)
            print("requested steps:", steps)
            print(self.step_graph:dump())
            return halt()
        end
        cprint("${bright green}Running steps from step-graph: " .. self.name)
        for _, stepname in ipairs(ordered) do
            if self.steps[stepname].func then
                cprint("${green}    " .. stepname)
            else
                cprint("${dim}    " .. stepname)
            end
        end
        for _, stepname in ipairs(ordered) do
            local step = self.steps[stepname]
            if step.func then
                cprint("${green}-------- %s --------", stepname)
                debug.setfenv(step.func, debug.getfenv(1))
                local response = step.func(self.context, step, self)
                if response then
                    cprint("${red}%s has aborted this run.", stepname)
                    return halt()
                end
            end
        end
    else
        cprint("${bright red}Cannot run selected steps from step-graph %s, because they form a loop", self.name)
        local cycle = visitor.invoke_graph:find_cycle()
        for _, c in ipairs(cycle) do
            print(c)
        end
        raise("Cyclic steps found in step-graph")
    end
end

--!
-- Get or add a step-graph to a target or any other component which has `data` and `name` members
--
function get_steps(target, graph_name)
    local data_name = "steps." .. graph_name
    local target_steps = target:data(data_name)
    if not target_steps then
        target_steps = _step_graph:new(
            target:name() .. "/" .. graph_name,
            {target = target}
        )
        target:data_set(data_name, target_steps)
    end
    return target_steps
end

--!
-- Add a step to a step-graph associated with a target or any other component which has `data` and
-- `name` members.
-- 
-- @code
-- on_load(function(target)
--     import("@addon.rats-utils.rsteps")
--     rsteps.add_step(target, "manifest",
--         "make-manifest",
--         {
--             depends_on = {"elaborate-file-structure", "get-permissions"},
--             triggers = "sign",
--         },
--         function()
--             -- make the manifest
--         end
--     )
-- end)
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
function add_step(target, graph_name, ...)
    local steps = get_steps(target, graph_name)
    return steps:add(...)
end

--!
-- Easily add a sequence of steps to a step-graph associated with a target so you don't have to
-- explicitly define their chain of dependency
-- 
-- @code
-- on_load(function(target)
--     import("@addon.rats-utils.rsteps")
--     rsteps.add_sequence(target, "manifest",
--         "step-name", {},
--         function() --[[ do stuff ]] end, -- "step-name"
--         function() --[[ do stuff ]] end, -- "step-name2"
--         function() --[[ do stuff ]] end, -- "step-name3"
--         function() --[[ do stuff ]] end, -- "step-name4"
--         { "custom-name", function()
--             --[[ do stuff ]]
--         end},
--         function() --[[ do stuff ]] end, -- "custom-name2"
--         function() --[[ do stuff ]] end, -- "custom-name3"
--         function() --[[ do stuff ]] end, -- "custom-name4"
--         {
--             "make-manifest",
--             {
--                 depends_on = {"elaborate-file-structure", "get-permissions"},
--                 triggers = "sign",
--             },
--             function()
--                 -- make the manifest
--             end
--         }
--     )
-- end)
-- @endcode
-- 
-- By default the sequence is composed with dependency (running the last will run the rest), however
-- you can compose the sequence with triggering (running the first will run the rest) via the
-- second argument (options)
-- @code
-- rsteps.add_sequence(target, "manifest", "step-name", {trigger = true}, ...)
-- @endcode
-- 
-- The second argument can also set up relations to all given steps here
-- @code
-- rsteps.add_sequence(target, "manifest", "step-name", {triggered_by = "something-else"}, ...)
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
function add_sequence(target, graph_name, ...)
    local steps = get_steps(target, graph_name)
    return steps:with_sequence(...)
end