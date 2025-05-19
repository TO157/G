-- UGCService.luau

local UGCService = {}

-- In-memory database for UGC entries
local ugcDatabase = {}
local nextUgcId = 1

-- Helper function to create a shallow copy of a table
local function shallowCopy(original)
    if type(original) ~= "table" then
        return original
    end
    local copy = {}
    for k, v in pairs(original) do
        copy[k] = v
    end
    return copy
end

-- Helper function for getting current time (simulated if os.time not available/reliable)
-- In a real Luau environment like Roblox, os.time() is available.
-- For generic Luau, it should also be.
local function getCurrentTimestamp()
    -- Assuming os.time() is available and works as expected.
    -- If not, a simple counter could be a fallback for pure simulation.
    return os.time()
end

--[[
    Uploads a new User-Generated Content script.

    Args:
        creatorId (string or number): The ID of the content creator.
        scriptContent (string): The Luau script content.
        name (string): The name of the UGC.
        description (string): A description for the UGC.

    Returns:
        string or number: The new UGC_ID if successful.
        nil, string: nil and an error message if input is invalid.
]]
function UGCService.uploadUGC(creatorId, scriptContent, name, description)
    if not creatorId then
        return nil, "Creator ID is required."
    end
    if not scriptContent then
        return nil, "Script content is required."
    end
    if type(name) ~= "string" or name == "" then
        return nil, "Name must be a non-empty string."
    end
    if type(description) ~= "string" then
        description = "" -- Default to empty string if not provided or wrong type
    end

    local newUgcId = "ugc_" .. tostring(nextUgcId)
    nextUgcId = nextUgcId + 1

    local currentTime = getCurrentTimestamp()

    local newEntry = {
        UGC_ID = newUgcId,
        Creator_ID = creatorId,
        Name = name,
        Description = description,
        ScriptContent = scriptContent,
        Version = 1,
        CreationDate = currentTime,
        LastUpdateDate = currentTime,
    }

    ugcDatabase[newUgcId] = newEntry
    return newUgcId
end

--[[
    Retrieves a UGC entry by its ID.

    Args:
        ugcId (string or number): The ID of the UGC to retrieve.

    Returns:
        table: A copy of the UGC entry if found.
        nil: nil if not found.
]]
function UGCService.getUGC(ugcId)
    local entry = ugcDatabase[ugcId]
    if entry then
        return shallowCopy(entry) -- Return a copy
    else
        return nil
    end
end

--[[
    Updates an existing UGC entry.

    Args:
        ugcId (string or number): The ID of the UGC to update.
        creatorId (string or number): The ID of the user attempting the update.
        newScriptContent (string): The new script content.
        newName (string, optional): The new name for the UGC.
        newDescription (string, optional): The new description for the UGC.

    Returns:
        string or number: The UGC_ID if update was successful.
        nil, string: nil and an error message if not found, unauthorized, or invalid input.
]]
function UGCService.updateUGC(ugcId, creatorId, newScriptContent, newName, newDescription)
    local entry = ugcDatabase[ugcId]

    if not entry then
        return nil, "UGC not found."
    end

    if entry.Creator_ID ~= creatorId then
        return nil, "Unauthorized: Creator ID does not match."
    end

    if not newScriptContent then
        return nil, "New script content is required for an update."
    end

    entry.ScriptContent = newScriptContent
    
    if newName and type(newName) == "string" then
        entry.Name = newName
    end

    if newDescription and type(newDescription) == "string" then
        entry.Description = newDescription
    end

    entry.Version = entry.Version + 1
    entry.LastUpdateDate = getCurrentTimestamp()

    return ugcId
end

--[[
    Lists all UGC entries created by a specific user.

    Args:
        creatorId (string or number): The ID of the creator.

    Returns:
        table: A list of UGC entry copies.
]]
function UGCService.listUGCByUser(creatorId)
    local userUGCs = {}
    for id, entry in pairs(ugcDatabase) do
        if entry.Creator_ID == creatorId then
            table.insert(userUGCs, shallowCopy(entry))
        end
    end
    return userUGCs
end


-- Example Usage (not part of the returned module)
local function runExample()
    print("--- UGCService Example ---")

    -- Simulate os.time() if it's not available in the test environment or returns 0
    local timeOffset = 0
    if os.time() == 0 then
        print("Warning: os.time() returned 0. Simulating time with an offset.")
        local originalOsTime = os.time
        os.time = function()
            timeOffset = timeOffset + 1
            return originalOsTime() + timeOffset
        end
    end

    -- 1. Upload a new script
    print("\n1. Uploading UGC...")
    local creator1 = "user123"
    local script1_content = "print('Hello from my first script!')"
    local name1 = "MyFirstScript"
    local desc1 = "A simple hello world script."
    
    local ugcId1, err1 = UGCService.uploadUGC(creator1, script1_content, name1, desc1)
    if ugcId1 then
        print("UGC Uploaded successfully! ID:", ugcId1)
    else
        print("Error uploading UGC:", err1)
    end

    local creator2 = "user456"
    local ugcId2, err2 = UGCService.uploadUGC(creator2, "print('Another script by user456')", "Script Utils", "Some utilities")
    if ugcId2 then
        print("UGC Uploaded successfully! ID:", ugcId2)
    else
        print("Error uploading UGC:", err2)
    end

    -- 2. Retrieve the script
    print("\n2. Retrieving UGC...")
    if ugcId1 then
        local retrievedUGC = UGCService.getUGC(ugcId1)
        if retrievedUGC then
            print("Retrieved UGC:", retrievedUGC.Name, "Version:", retrievedUGC.Version)
            -- print("Full data:", retrievedUGC) -- For more detail
        else
            print("Failed to retrieve UGC:", ugcId1)
        end
    end

    -- 3. Attempt to update the script by the original creator
    print("\n3. Updating UGC (original creator)...")
    if ugcId1 then
        local updatedContent1 = "print('Hello world! -- V2')"
        local updatedName1 = "MyFirstScript V2"
        local updatedId, updateErr = UGCService.updateUGC(ugcId1, creator1, updatedContent1, updatedName1, "Now with more greetings!")
        if updatedId then
            print("UGC Updated successfully by original creator. ID:", updatedId)
            local updatedUGC = UGCService.getUGC(updatedId)
            print("Updated Name:", updatedUGC.Name, "Version:", updatedUGC.Version, "Description:", updatedUGC.Description)
        else
            print("Error updating UGC:", updateErr)
        end
    end
    
    -- 4. Attempt to update the script by a different user (should fail)
    print("\n4. Attempting to update UGC (different user)...")
    if ugcId1 then
        local anotherUser = "imposter789"
        local updatedContent2 = "print('Malicious script attempt!')"
        local failedUpdateId, failedUpdateErr = UGCService.updateUGC(ugcId1, anotherUser, updatedContent2, "Malicious Name")
        if failedUpdateId then
            print("UGC Update unexpectedly succeeded by different user. ID:", failedUpdateId)
        else
            print("UGC Update failed by different user (as expected):", failedUpdateErr)
        end
        -- Verify it wasn't actually changed
        local originalUGC = UGCService.getUGC(ugcId1)
        print("Original UGC after failed attempt - Name:", originalUGC.Name, "Version:", originalUGC.Version, "Content:", originalUGC.ScriptContent)
    end

    -- 5. Listing scripts by a user
    print("\n5. Listing UGC by creator:", creator1)
    local user1Scripts = UGCService.listUGCByUser(creator1)
    print("Found", #user1Scripts, "script(s) for", creator1)
    for i, scriptData in ipairs(user1Scripts) do
        print("  - ", scriptData.Name, "(ID:", scriptData.UGC_ID, "Version:", scriptData.Version, ")")
    end

    print("\n5b. Listing UGC by creator:", creator2)
    local user2Scripts = UGCService.listUGCByUser(creator2)
    print("Found", #user2Scripts, "script(s) for", creator2)
    for i, scriptData in ipairs(user2Scripts) do
        print("  - ", scriptData.Name, "(ID:", scriptData.UGC_ID, "Version:", scriptData.Version, ")")
    end
    
    print("\n6. Test invalid upload inputs")
    local _, errNoCreator = UGCService.uploadUGC(nil, "content", "name", "desc")
    print("Error (no creatorId):", errNoCreator)
    local _, errNoContent = UGCService.uploadUGC("user777", nil, "name", "desc")
    print("Error (no scriptContent):", errNoContent)
    local _, errNoName = UGCService.uploadUGC("user777", "content", "", "desc")
    print("Error (no name):", errNoName)
    
    print("\n--- Example End ---")
end

-- To run the example when this file is executed (e.g., via `luau UGCService.luau`):
-- This would typically be removed or conditional if it's purely a library module.
runExample()

return UGCService
