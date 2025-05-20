--!strict

-- src/Modules/Logger.luau
-- This module provides basic logging functionalities (info, warn, error)
-- to output messages to the console. It's used across the system for
-- debugging, tracing events, and reporting issues.

local Logger = {}

--[[
    Logs an informational message to the console.
    @param message: The string message to log.
--]]
function Logger.info(message: string)
    print("[INFO] " .. message)
end

--[[
    Logs a warning message to the console.
    @param message: The string message to log.
--]]
function Logger.warn(message: string)
    print("[WARN] " .. message)
end

--[[
    Logs an error message to the console, with optional details.
    If errorDetails are provided, they are printed in a structured way,
    handling tables (arrays or dictionaries) and other types.
    @param message: The main error message string.
    @param errorDetails: Optional. Additional details about the error (any type).
--]]
function Logger.error(message: string, errorDetails: any?)
    print("[ERROR] " .. message)
    if errorDetails ~= nil then
        if type(errorDetails) == "table" then
            -- Check if it's an array-like table or dictionary-like
            local isArray = true
            local count = 0
            for _ in pairs(errorDetails) do
                count += 1
            end
            if count > 0 then
                for i = 1, count do
                    if errorDetails[i] == nil then
                        isArray = false
                        break
                    end
                end
            else -- empty table
                isArray = false -- treat as empty dictionary for consistent output
            end

            if isArray and count > 0 then
                 print("  Details (Array):")
                 for i = 1, count do
                    print("  - [" .. tostring(i) .. "]: " .. tostring(errorDetails[i]))
                 end
            else
                print("  Details (Table):")
                for k, v in pairs(errorDetails) do
                    print("  - " .. tostring(k) .. ": " .. tostring(v))
                end
                if count == 0 then
                    print("  (empty table)")
                end
            end
        else
            print("  Details: " .. tostring(errorDetails))
        end
    end
end

return Logger
