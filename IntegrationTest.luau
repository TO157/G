-- IntegrationTest.luau
-- This script demonstrates the integration of Sandbox.luau and UGCService.luau.

print("--- Starting Integration Test ---")

-- 1. Load Modules
local Sandbox, UGCService

local successSandbox, sandboxModule = pcall(function()
    -- Assuming Sandbox.luau is in the same directory or accessible via this path
    -- For Roblox, this might be script.Parent.Sandbox
    -- For a generic Luau setup, the path might differ or require custom loader.
    return require(script.Parent.Sandbox) 
end)

if not successSandbox or not sandboxModule then
    print("Error: Failed to load Sandbox.luau. Ensure it's present and returns a module table.")
    print("Pcall error:", sandboxModule) -- sandboxModule here is the error message
    return -- Stop execution if critical module is missing
end
Sandbox = sandboxModule
print("Sandbox module loaded successfully.")

local successUGC, ugcModule = pcall(function()
    -- Assuming UGCService.luau is in the same directory
    return require(script.Parent.UGCService)
end)

if not successUGC or not ugcModule then
    print("Error: Failed to load UGCService.luau. Ensure it's present and returns a module table.")
    print("Pcall error:", ugcModule) -- ugcModule here is the error message
    return -- Stop execution if critical module is missing
end
UGCService = ugcModule
print("UGCService module loaded successfully.")

-- 2. Initialize Services (if needed)
-- Based on previous design, these modules do not require explicit initialization calls
-- UGCService initializes its database internally.
-- Sandbox provides utility functions.

-- 3. Upload a Test UGC Script
print("\n--- Step 1: Uploading Test UGC Script ---")
local testCreatorId = "integration_tester_001"
local testUGCName = "Sandbox Test Script"
local testUGCDescription = "A script to test sandbox functionality."

local testScriptContent = [[
    print("Test UGC script running in sandbox!")
    
    local a = 10
    local b = 20
    print("Calculation: a + b = ", a + b)

    print("Attempting to use math.random():")
    local randomNumber = math.random(1, 100)
    print("Generated random number: " .. tostring(randomNumber))

    print("Attempting to use a disallowed service (HttpService):")
    -- This should trigger the mocked HttpService and print a warning
    local httpSuccess, httpContent = HttpService:GetAsync("http://example.com")
    if not httpSuccess then
        print("HttpService:GetAsync call failed as expected in sandbox: " .. tostring(httpContent))
    else
        print("HttpService:GetAsync call unexpectedly succeeded in sandbox.")
    end

    print("Attempting to access a non-whitelisted global (game):")
    if game then
        print("Error: 'game' global is accessible in sandbox!")
    else
        print("'game' global is nil, as expected in sandbox.")
    end
    
    -- Test returning a value
    return "Script execution completed. Random number was: " .. tostring(randomNumber)
]]

local ugcId, uploadError = UGCService.uploadUGC(testCreatorId, testScriptContent, testUGCName, testUGCDescription)

if not ugcId then
    print("Error uploading UGC script:", uploadError)
    print("--- Integration Test Failed at UGC Upload ---")
    return
end
print("Test UGC script uploaded successfully. UGC_ID:", ugcId)

-- 4. Retrieve the UGC Script
print("\n--- Step 2: Retrieving UGC Script ---")
local retrievedUGC = UGCService.getUGC(ugcId)

if not retrievedUGC then
    print("Error retrieving UGC script with ID:", ugcId)
    print("--- Integration Test Failed at UGC Retrieval ---")
    return
end
print("Test UGC script retrieved successfully. Name:", retrievedUGC.Name)

local scriptToExecute = retrievedUGC.ScriptContent
if not scriptToExecute then
    print("Error: Retrieved UGC does not contain ScriptContent.")
    print("--- Integration Test Failed - No Script Content ---")
    return
end
-- print("Script content to execute:\n" .. scriptToExecute) -- Optional: print the script

-- 5. Prepare Sandbox
print("\n--- Step 3: Preparing Sandboxed Environment ---")
local sandboxedEnvironment = Sandbox.createSandboxedEnvironment()
if not sandboxedEnvironment then
    print("Error: Failed to create sandboxed environment.")
    print("--- Integration Test Failed at Sandbox Creation ---")
    return
end
print("Sandboxed environment created.")
-- You could inspect the environment here if needed, e.g., print(sandboxedEnvironment.print)

-- 6. Execute Script in Sandbox
print("\n--- Step 4: Executing Script in Sandbox ---")
-- The prints from within the sandboxed script should appear here, prefixed by its own print calls
local executionSuccess, executionResultOrError = Sandbox.executeSandboxedCode(scriptToExecute, sandboxedEnvironment)

-- 7. Report Results
print("\n--- Step 5: Reporting Execution Results ---")
if executionSuccess then
    print("✅ Sandboxed script execution successful.")
    print("   Return value(s) from script:", executionResultOrError)
else
    print("❌ Sandboxed script execution failed.")
    print("   Error message:", executionResultOrError)
end

-- Example of trying to update the UGC (Optional, but good for further testing)
print("\n--- Optional: Attempting to update UGC (demonstrates further UGCService use) ---")
local updatedScriptContent = testScriptContent .. "\nprint('This is version 2!')"
local updatedId, updateErr = UGCService.updateUGC(ugcId, testCreatorId, updatedScriptContent, "Sandbox Test Script V2", "Now with a V2 marker.")
if updatedId then
    print("UGC updated successfully. New version should be reflected if retrieved again.")
    local updatedUGC = UGCService.getUGC(ugcId)
    print("Retrieved updated UGC: Name -", updatedUGC.Name, "Version -", updatedUGC.Version)
else
    print("Failed to update UGC:", updateErr)
end


print("\n--- Integration Test Completed ---")
