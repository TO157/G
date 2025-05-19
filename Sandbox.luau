-- Sandbox.luau

local Sandbox = {}

--[[
    Creates a new sandboxed environment.
    This environment has a limited set of allowed globals and
    specifically excludes or mocks potentially dangerous functions.
]]
function Sandbox.createSandboxedEnvironment()
    local env = {}

    -- Whitelist basic functions
    local allowedGlobals = {
        print = print,
        tostring = tostring,
        type = type,
        pairs = pairs,
        ipairs = ipairs,
        next = next,
        -- Error handling related
        assert = assert,
        warn = warn, -- Often useful for debugging sandboxed code
        error = error, -- Allows sandboxed code to throw errors
        pcall = pcall,
        xpcall = xpcall,
        -- Table manipulation
        table = {
            insert = table.insert,
            remove = table.remove,
            sort = table.sort,
            concat = table.concat,
            unpack = table.unpack or unpack, -- unpack was global in older Lua, table.unpack in Luau
            pack = table.pack or (function(...) return {n=select("#",...), ...} end) -- table.pack might not be in all Luau envs
        },
        -- String manipulation
        string = {
            byte = string.byte,
            char = string.char,
            find = string.find,
            format = string.format,
            gmatch = string.gmatch,
            gsub = string.gsub,
            len = string.len,
            lower = string.lower,
            match = string.match,
            rep = string.rep,
            reverse = string.reverse,
            sub = string.sub,
            upper = string.upper,
            split = string.split, -- Luau specific
            join = string.join    -- Luau specific
        },
        -- Math library (limited set)
        math = {
            abs = math.abs,
            acos = math.acos,
            asin = math.asin,
            atan = math.atan,
            atan2 = math.atan2,
            ceil = math.ceil,
            cos = math.cos,
            deg = math.deg,
            exp = math.exp,
            floor = math.floor,
            fmod = math.fmod,
            frexp = math.frexp,
            huge = math.huge,
            ldexp = math.ldexp,
            log = math.log,
            log10 = math.log10, -- Luau specific
            max = math.max,
            min = math.min,
            modf = math.modf,
            pi = math.pi,
            pow = math.pow,
            rad = math.rad,
            random = math.random,
            randomseed = math.randomseed,
            sin = math.sin,
            sqrt = math.sqrt,
            tan = math.tan,
            clamp = math.clamp, -- Luau specific
            sign = math.sign,   -- Luau specific
            noise = math.noise, -- Luau specific
            round = math.round  -- Luau specific
        },
        -- For Roblox-like environments, 'wait' is common, but it's usually a global.
        -- For a generic Luau sandbox, 'wait' is not standard.
        -- If this were for Roblox, you might add a custom 'wait' or 'task.wait'.
        -- For now, let's assume a generic Luau environment.
    }

    for k, v in pairs(allowedGlobals) do
        env[k] = v
    end

    -- Mock potentially dangerous services
    env.HttpService = {
        GetAsync = function(...)
            warn("HttpService:GetAsync is disabled in this sandbox.")
            return false, "HttpService is disabled."
        end,
        PostAsync = function(...)
            warn("HttpService:PostAsync is disabled in this sandbox.")
            return false, "HttpService is disabled."
        end,
        RequestAsync = function(...)
            warn("HttpService:RequestAsync is disabled in this sandbox.")
            return false, "HttpService is disabled."
        end,
        -- Add other HttpService methods if necessary
    }
    
    -- Explicitly prevent access to _G or shared
    -- In Luau, loadstring by default doesn't get _G of the caller if an env is provided.
    -- However, if some function on the whitelist accidentally leaks it, this could be an issue.
    -- For true sandboxing, one might need C-side controls or more advanced Luau VM options if available.
    -- For this script-level sandbox, we rely on setfenv and the limited scope.
    env._G = nil 
    env.shared = nil
    env.script = nil -- common global in some Luau environments like Roblox

    -- It's good practice to also set the metatable to prevent tampering with the env table itself
    -- from within the sandboxed code IF the env table is passed directly to the sandboxed code.
    -- However, with loadstring/setfenv, the 'env' table IS the global scope, so it can be modified.
    -- To make it more robust, important functions like 'print' could be wrapped or their original
    -- references stored elsewhere if there's a concern they might be overwritten by sandboxed code.
    -- For now, this example keeps it simpler.

    return env
end

--[[
    Executes a string of Luau code within a given sandboxed environment.

    Args:
        codeString (string): The Luau code to execute.
        sandboxedEnvironment (table): The environment to execute the code in.

    Returns:
        boolean: True if execution was successful, false otherwise.
        any: The result of the execution if successful, or an error message/object if not.
]]
function Sandbox.executeSandboxedCode(codeString, sandboxedEnvironment)
    if type(codeString) ~= "string" then
        return false, "Code string must be a string."
    end
    if type(sandboxedEnvironment) ~= "table" then
        return false, "Sandboxed environment must be a table."
    end

    -- Compile the code string.
    -- In Luau, loadstring is typically available.
    -- loadstring(chunkString, chunkName, environment)
    -- The third argument for environment is important for sandboxing.
    local loadedChunk, compileError = loadstring(codeString)

    if not loadedChunk then
        return false, "Compilation error: " .. tostring(compileError)
    end

    -- Set the environment for the loaded chunk.
    -- This is crucial for sandboxing.
    setfenv(loadedChunk, sandboxedEnvironment)

    -- Execute the compiled chunk in protected mode.
    local success, resultOrError = pcall(loadedChunk)

    if success then
        return true, resultOrError
    else
        return false, "Execution error: " .. tostring(resultOrError)
    end
end


-- Example Usage:
local function runExample()
    print("Creating sandboxed environment...")
    local mySandboxEnv = Sandbox.createSandboxedEnvironment()

    print("\n--- Test Case 1: Allowed operations ---")
    local code1 = [[
        print("Hello from the sandbox!")
        local num = math.random(1, 100)
        print("Random number (1-100): " .. tostring(num))
        local testTable = {a=1, b=2}
        for k,v in pairs(testTable) do
            print("Table content: " .. k .. "=" .. v)
        end
        return "Test 1 Succeeded", num
    ]]
    local success1, result1 = Sandbox.executeSandboxedCode(code1, mySandboxEnv)
    print("Success:", success1)
    if success1 then
        print("Result:", result1[1], "Random was:", result1[2])
    else
        print("Error:", result1)
    end

    print("\n--- Test Case 2: Attempting to use a disallowed function (HttpService) ---")
    local code2 = [[
        print("Attempting to use HttpService...")
        local success, content = HttpService:GetAsync("http://www.google.com")
        if not success then
            print("HttpService call failed as expected: " .. content)
        else
            print("HttpService call unexpectedly succeeded with: " .. content)
        end
        return "Test 2 Result (HttpService)"
    ]]
    local success2, result2 = Sandbox.executeSandboxedCode(code2, mySandboxEnv)
    print("Success:", success2)
    if success2 then
        print("Result:", result2)
    else
        print("Error:", result2)
    end
    
    print("\n--- Test Case 3: Attempting to access a non-whitelisted global (game) ---")
    local code3 = [[
        print("Attempting to access 'game' global...")
        if game then
            print("Found game global! This is a sandbox breach.")
        else
            print("'game' global is nil, as expected.")
        end
        return "Test 3 Result (global access)"
    ]]
    local success3, result3 = Sandbox.executeSandboxedCode(code3, mySandboxEnv)
    print("Success:", success3)
    if success3 then
        print("Result:", result3)
    else
        print("Error:", result3) -- This should ideally show an error about 'game' being nil
    end

    print("\n--- Test Case 4: Attempting to modify the environment (e.g., nil out print) ---")
    -- Note: The sandboxed code *can* modify its own environment table.
    -- If this is a concern, more advanced techniques or careful proxying of env functions would be needed.
    local code4 = [[
        print("Attempting to overwrite 'print'...")
        local oldPrint = print
        print = function() oldPrint("Haha, print is now different!") end
        print("Testing new print...")
        -- Attempt to restore (or further mess up)
        -- print = nil 
        -- print("This will error if print is nil") -- This would error if 'print' was set to nil by sandboxed code
        return "Test 4 Result (env modification)"
    ]]
    local success4, result4 = Sandbox.executeSandboxedCode(code4, mySandboxEnv)
    print("Success:", success4)
    if success4 then
        print("Result:", result4)
    else
        print("Error:", result4)
    end

    print("\n--- Test Case 5: Check if 'print' in the original scope is affected ---")
    print("This print comes from the script's original scope.")
    local code5 = [[
        -- This code tries to use a function that would error if print was truly nilled globally
        -- pcall(function() print("This should still work if sandbox is contained") end)
        return "Test 5 completed"
    ]]
    local success5, result5 = Sandbox.executeSandboxedCode(code5, mySandboxEnv) -- use the same env
    print("Success (Test 5):", success5)
    print("Result (Test 5):", result5)
    print("Final check: This is the real print function, printing a test message.")


    print("\n--- Test Case 6: Code that errors ---")
    local code6 = [[
        print("This code will error.")
        local a = {}
        return a.b.c -- This will cause a nil indexing error
    ]]
    local success6, result6 = Sandbox.executeSandboxedCode(code6, mySandboxEnv)
    print("Success:", success6)
    if success6 then
        print("Result:", result6)
    else
        print("Error (as expected):", result6)
    end
    
    print("\n--- Test Case 7: Accessing _G (should be nil) ---")
    local code7 = [[
        if _G then
            print("_G is accessible! This is a sandbox breach.")
            _G.someGlobal = "hacked"
        else
            print("_G is nil, as expected.")
        end
        return "Test 7 Result (_G access)"
    ]]
    local success7, result7 = Sandbox.executeSandboxedCode(code7, mySandboxEnv)
    print("Success:", success7)
    if success7 then
        print("Result:", result7)
    else
        print("Error:", result7)
    end

end

-- Run the example if this script is executed directly
-- In a real module, you wouldn't call runExample() here.
-- You would return Sandbox table and the calling script would use it.
runExample()

return Sandbox
