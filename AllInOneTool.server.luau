-- Helper function to create RemoteEvents if they don't exist
local function createRemoteEventIfNeeded(name)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    if not ReplicatedStorage:FindFirstChild(name) then
        local remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = name
        remoteEvent.Parent = ReplicatedStorage
        print("Created RemoteEvent: " .. name .. " (by AllInOneTool.server.luau)")
    end
end

-- Initialize all necessary RemoteEvents
createRemoteEventIfNeeded("AIO_CreateObjectEvent")
createRemoteEventIfNeeded("AIO_DeleteObjectEvent")
createRemoteEventIfNeeded("AIO_ClientFeedbackEvent")
createRemoteEventIfNeeded("AIO_UpdatePropertyEvent")
createRemoteEventIfNeeded("AIO_CSGOperationEvent")
createRemoteEventIfNeeded("AIO_UpdateEnvironmentEvent")
createRemoteEventIfNeeded("AIO_RequestEnvironmentSyncEvent")
createRemoteEventIfNeeded("AIO_SyncEnvironmentEvent")
createRemoteEventIfNeeded("AIO_AdvancedSelectEvent")
createRemoteEventIfNeeded("AIO_AlignmentEvent")
createRemoteEventIfNeeded("AIO_TerrainInspectEvent")
createRemoteEventIfNeeded("AIO_TerrainModifyEvent")

-- Confirmation print statement
print("AllInOneTool.server.luau: RemoteEvent initialization checks complete.")

---------------------------------------------------------------------------------
-- SERVICES
---------------------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Terrain = game:GetService("Terrain")
local ServerScriptService = game:GetService("ServerScriptService") -- For robustness if needed

---------------------------------------------------------------------------------
-- REMOTE EVENT REFERENCES (ensure these match client)
---------------------------------------------------------------------------------
local createObjectEvent = ReplicatedStorage:WaitForChild("AIO_CreateObjectEvent")
local deleteObjectEvent = ReplicatedStorage:WaitForChild("AIO_DeleteObjectEvent")
local clientFeedbackEvent = ReplicatedStorage:WaitForChild("AIO_ClientFeedbackEvent")
local updatePropertyEvent = ReplicatedStorage:WaitForChild("AIO_UpdatePropertyEvent")
local csgOperationEvent = ReplicatedStorage:WaitForChild("AIO_CSGOperationEvent")
local updateEnvironmentEvent = ReplicatedStorage:WaitForChild("AIO_UpdateEnvironmentEvent")
local requestEnvironmentSyncEvent = ReplicatedStorage:WaitForChild("AIO_RequestEnvironmentSyncEvent")
local syncEnvironmentEvent = ReplicatedStorage:WaitForChild("AIO_SyncEnvironmentEvent")
local advancedSelectEvent = ReplicatedStorage:WaitForChild("AIO_AdvancedSelectEvent")
local alignmentEvent = ReplicatedStorage:WaitForChild("AIO_AlignmentEvent")
local terrainInspectEvent = ReplicatedStorage:WaitForChild("AIO_TerrainInspectEvent")
local terrainModifyEvent = ReplicatedStorage:WaitForChild("AIO_TerrainModifyEvent")

---------------------------------------------------------------------------------
-- CONFIGURATION
---------------------------------------------------------------------------------
local whitelistedClassNames = {
    "Part", "SpherePart", "WedgePart", "CylinderPart", "CornerWedgePart", -- Basic parts
    "Folder", "Model",
    "SpawnLocation",
    "TrussPart",
    "Script", "LocalScript", -- Use with caution, ensure proper sandboxing or review if allowing script creation
    "IntValue", "StringValue", "BoolValue", "Vector3Value", "Color3Value", "NumberValue", "ObjectValue",
    "Attachment", "Decal", "Texture", "SurfaceGui", "BillboardGui", "ScreenGui", "Frame", "TextLabel", "TextButton", "TextBox",
    "Sound",
    "Light", "PointLight", "SpotLight", "SurfaceLight",
    "Atmosphere", "Sky", "Clouds", "FogEffect" -- For environment, though usually only one of each
}

local allowedEnvironmentParents = { Lighting, Workspace, Terrain, game:GetService("SoundService") } -- Added SoundService

---------------------------------------------------------------------------------
-- HELPER FUNCTIONS
---------------------------------------------------------------------------------

-- Send feedback to a specific client
local function sendFeedback(player, message, isError)
    if player and clientFeedbackEvent then
        clientFeedbackEvent:FireClient(player, message, isError or false)
    else
        warn("Attempted to send feedback but player or clientFeedbackEvent is nil. Message:", message)
    end
end

-- Get object from path (scoped to Workspace or player's character for security)
local function getObjectFromPath(player, pathString)
    if not pathString or type(pathString) ~= "string" then
        return nil, "Invalid path string."
    end

    local parts = string.split(pathString, ".")
    if #parts == 0 then
        return nil, "Empty path string."
    end

    local currentObject = Workspace -- Default search in Workspace
    if parts[1] == "Workspace" then
        table.remove(parts, 1) -- Remove "Workspace" prefix if present
    elseif player and player.Character and parts[1] == player.Character.Name then
        currentObject = player.Character -- Allow access to own character
        table.remove(parts, 1)
    end
    
    -- Also allow direct access to Lighting and Terrain services by name
    if parts[1] == "Lighting" then
        currentObject = Lighting
        table.remove(parts, 1)
    elseif parts[1] == "Terrain" then
        currentObject = Terrain -- Note: Terrain doesn't have children in the same way
        table.remove(parts, 1)
         if #parts == 0 then return Terrain, nil end -- If path is just "Terrain"
    end


    for _, name in ipairs(parts) do
        if not currentObject or not currentObject:IsA("Instance") then -- currentObject can be Terrain which is not an Instance
            return nil, "Invalid path, intermediate object not found or not an Instance."
        end
        currentObject = currentObject:FindFirstChild(name)
        if not currentObject then
            return nil, "Object not found at: " .. name .. " in path " .. pathString
        end
    end
    return currentObject, nil
end


-- Type conversion and validation
local function convertValue(valueStr, targetType)
    if targetType == "string" then return tostring(valueStr) end
    if targetType == "number" then return tonumber(valueStr) end
    if targetType == "boolean" then return string.lower(tostring(valueStr)) == "true" end
    if targetType == "Color3" then
        local nums = {}
        for numStr in string.gmatch(valueStr, "[^,]+") do table.insert(nums, tonumber(numStr)) end
        if #nums == 3 then return Color3.fromRGB(nums[1], nums[2], nums[3]) end
    end
    if targetType == "Vector3" then
        local nums = {}
        for numStr in string.gmatch(valueStr, "[^,]+") do table.insert(nums, tonumber(numStr)) end
        if #nums == 3 then return Vector3.new(nums[1], nums[2], nums[3]) end
    end
    if targetType == "BrickColor" then return BrickColor.new(valueStr) end
    if targetType == "Material" then return Enum.Material[valueStr] end
    
    -- Handle Enum types (e.g., "Enum.Material.Plastic")
    if string.sub(targetType, 1, 5) == "Enum." then
        local enumParts = string.split(targetType, ".")
        if #enumParts == 3 then
            local enumType = enumParts[2]
            local enumItem = enumParts[3]
            if Enum[enumType] and Enum[enumType][enumItem] then
                return Enum[enumType][enumItem]
            end
        end
    end
    return nil, "Unsupported target type or invalid value format for " .. targetType
end

---------------------------------------------------------------------------------
-- EVENT HANDLERS
---------------------------------------------------------------------------------

-- 1. Create Object
createObjectEvent.OnServerEvent:Connect(function(player, className, name, parentPath)
    local allowed = false
    for _, allowedName in ipairs(whitelistedClassNames) do
        if className == allowedName then
            allowed = true
            break
        end
    end

    if not allowed then
        sendFeedback(player, "Error: ClassName '" .. tostring(className) .. "' is not whitelisted for creation.", true)
        return
    end

    local parentInstance = Workspace
    if parentPath and parentPath ~= "" then
        local foundParent, err = getObjectFromPath(player, parentPath)
        if err or not foundParent then
            sendFeedback(player, "Error creating object: Invalid parent path '" .. tostring(parentPath) .. "'. " .. (err or ""), true)
            return
        end
        parentInstance = foundParent
    end
    
    local success, newInstanceOrError = pcall(function()
        local newInstance = Instance.new(className)
        if name and type(name) == "string" and name ~= "" then
            newInstance.Name = name
        end
        newInstance.Parent = parentInstance
        return newInstance
    end)

    if success then
        sendFeedback(player, "Object '" .. newInstanceOrError.Name .. "' (" .. className .. ") created successfully under " .. parentInstance:GetFullName(), false)
    else
        sendFeedback(player, "Error creating object: " .. tostring(newInstanceOrError), true)
    end
end)

-- 2. Delete Object
deleteObjectEvent.OnServerEvent:Connect(function(player, objectPath)
    local obj, err = getObjectFromPath(player, objectPath)
    if err or not obj then
        sendFeedback(player, "Error deleting object: " .. (err or "Object not found at path '"..tostring(objectPath).."'."), true)
        return
    end

    if not (obj:IsA("BasePart") or obj:IsA("Model") or obj:IsA("Folder") or obj:IsA("GuiBase") or obj:IsA("Light") or obj:IsA("ValueBase") or obj:IsA("Attachment") or obj:IsA("Sound") or obj:IsA("Script")) then
        sendFeedback(player, "Error: Only BaseParts, Models, Folders, GUIs, Lights, Values, Attachments, Sounds, and Scripts can be deleted via this tool.", true)
        return
    end
    
    -- Security: Prevent deleting core services or things not in Workspace or Character
    local isWorkspaceDescendant = obj:IsDescendantOf(Workspace)
    local isCharacterDescendant = player.Character and obj:IsDescendantOf(player.Character)
    
    if not (isWorkspaceDescendant or isCharacterDescendant) then
        sendFeedback(player, "Error: Cannot delete objects outside of Workspace or your character.", true)
        return
    end
    if obj == Workspace then -- Cannot delete Workspace itself
         sendFeedback(player, "Error: Cannot delete the Workspace.", true)
        return
    end


    local success, errorMsg = pcall(function()
        obj:Destroy()
    end)

    if success then
        sendFeedback(player, "Object '" .. tostring(objectPath) .. "' deleted successfully.", false)
    else
        sendFeedback(player, "Error deleting object '" .. tostring(objectPath) .. "': " .. tostring(errorMsg), true)
    end
end)

-- 3. Update Property
updatePropertyEvent.OnServerEvent:Connect(function(player, objectPath, propertyName, propertyValueStr, propertyType)
    local obj, err = getObjectFromPath(player, objectPath)
    if err or not obj then
        sendFeedback(player, "Error updating property: " .. (err or "Object not found at path."), true)
        return
    end

    -- Security: Prevent modifying properties of core services directly unless explicitly handled (like Lighting)
    if not (obj:IsDescendantOf(Workspace) or (player.Character and obj:IsDescendantOf(player.Character)) or obj == Lighting or obj == Terrain or obj:IsA("Atmosphere") or obj:IsA("Sky") or obj:IsA("Clouds") or obj:IsA("FogEffect") or obj:IsA("Sound")) then
        if not table.find(allowedEnvironmentParents, obj) then -- Check if obj itself is an allowed service
             sendFeedback(player, "Error: Cannot modify properties of objects outside Workspace, Character, Lighting, Terrain, or other environment services.", true)
             return
        end
    end


    local convertedValue, convertError = convertValue(propertyValueStr, propertyType)
    if convertError then
        sendFeedback(player, "Error converting value for '" .. propertyName .. "': " .. convertError, true)
        return
    end
    if convertedValue == nil and propertyType ~= "string" and propertyValueStr ~= "" then -- Allow empty string for strings, otherwise nil is usually an error
         if not (propertyType == "Material" and convertedValue == Enum.Material.Plastic) then -- default material can be nil-ish
            sendFeedback(player, "Error: Converted value is nil for '" .. propertyName .. "' with type " .. propertyType .. " from string '"..propertyValueStr.."'", true)
            return
         end
    end


    local success, errorMsg = pcall(function()
        if propertyType == "Material" and convertedValue == nil then -- Handle potential nil for Material if Plastic is intended
             obj[propertyName] = Enum.Material.Plastic
        else
            obj[propertyName] = convertedValue
        end
    end)

    if success then
        sendFeedback(player, "Property '" .. propertyName .. "' of '" .. obj.Name .. "' updated to " .. tostring(propertyValueStr) .. ".", false)
        -- If it's an environment property, consider broadcasting (see UpdateEnvironmentEvent)
        if obj == Lighting or obj:IsA("Atmosphere") or obj:IsA("Sky") or obj:IsA("Clouds") or obj:IsA("FogEffect") then
             -- This will be handled by AIO_UpdateEnvironmentEvent if a dedicated table is sent
             -- For individual property changes, you might want a more granular sync or rely on client refresh
        end
    else
        sendFeedback(player, "Error updating property '" .. propertyName .. "' of '" .. obj.Name .. "': " .. tostring(errorMsg), true)
    end
end)

-- 4. CSG Operation
csgOperationEvent.OnServerEvent:Connect(function(player, operationType, partPaths)
    if not (#partPaths >= 2 and (operationType == "Union" or operationType == "Subtract" or operationType == "Intersect")) then
        sendFeedback(player, "Error: CSG operations require at least two parts and a valid operation type (Union, Subtract, Intersect).", true)
        return
    end

    local parts = {}
    for _, path in ipairs(partPaths) do
        local obj, err = getObjectFromPath(player, path)
        if err or not obj or not obj:IsA("BasePart") then
            sendFeedback(player, "Error: CSG operation failed. Invalid part path or not a BasePart: " .. (err or path), true)
            return
        end
        if not obj:IsDescendantOf(Workspace) then
            sendFeedback(player, "Error: CSG parts must be in Workspace.", true)
            return
        end
        table.insert(parts, obj)
    end

    local primaryPart = parts[1]
    local otherParts = {}
    for i = 2, #parts do table.insert(otherParts, parts[i]) end

    local success, resultOrError = pcall(function()
        local newPart
        if operationType == "Union" then
            newPart = primaryPart:UnionAsync(otherParts)
        elseif operationType == "Subtract" then
            newPart = primaryPart:SubtractAsync(otherParts)
        elseif operationType == "Intersect" then
            newPart = primaryPart:IntersectAsync(otherParts)
        end
        return newPart
    end)

    if success and resultOrError then
        resultOrError.Parent = Workspace -- Or primaryPart.Parent
        resultOrError.Name = operationType .. "Result"
        -- Destroy original parts
        for _, part in ipairs(parts) do part:Destroy() end
        sendFeedback(player, "CSG " .. operationType .. " successful. New part: " .. resultOrError.Name, false)
    else
        sendFeedback(player, "Error during CSG " .. operationType .. ": " .. tostring(resultOrError), true)
    end
end)

-- 5. Update Environment
updateEnvironmentEvent.OnServerEvent:Connect(function(player, settingsTable)
    if type(settingsTable) ~= "table" then
        sendFeedback(player, "Error: Environment settings must be a table.", true)
        return
    end

    local changesMade = {}
    local errors = {}

    for pathString, valueStr in pairs(settingsTable) do
        local pathParts = string.split(pathString, ".")
        if #pathParts < 2 then
            table.insert(errors, "Invalid path: " .. pathString)
            goto continueEnvLoop
        end

        local serviceName = pathParts[1]
        local propertyName = pathParts[#pathParts]
        local parentService
        
        if serviceName == "Lighting" then parentService = Lighting
        elseif serviceName == "Atmosphere" then parentService = Lighting:FindFirstChildOfClass("Atmosphere")
        elseif serviceName == "Sky" then parentService = Lighting:FindFirstChildOfClass("Sky") or Workspace:FindFirstChildOfClass("Sky")
        elseif serviceName == "Clouds" then parentService = Workspace:FindFirstChildOfClass("Clouds") or Terrain:FindFirstChildOfClass("Clouds") -- Clouds can be under Workspace or Terrain
        elseif serviceName == "FogEffect" then parentService = Lighting:FindFirstChildOfClass("FogEffect")
        elseif serviceName == "Terrain" then parentService = Terrain
        else
            table.insert(errors, "Unsupported service for environment: " .. serviceName)
            goto continueEnvLoop
        end

        if not parentService then
            table.insert(errors, "Service/Effect not found: " .. serviceName)
            goto continueEnvLoop
        end
        
        local targetObject = parentService
        if #pathParts > 2 then -- e.g. Lighting.Fog.FogColor
             local current = parentService
             for i = 2, #pathParts -1 do
                 current = current:FindFirstChild(pathParts[i])
                 if not current then 
                     table.insert(errors, "Intermediate object " .. pathParts[i] .. " not found in " .. pathString)
                     goto continueEnvLoop 
                 end
             end
             targetObject = current
        end


        -- Determine property type (this is tricky without knowing all properties)
        -- For now, let's try to infer or use a predefined map if available
        -- Simplified: try converting to number, then Color3, then boolean, then string
        local actualValue
        local propType = type(targetObject[propertyName]) -- Get type of existing property
        local convertedVal, convertErr

        if propType == "number" then convertedVal, convertErr = convertValue(valueStr, "number")
        elseif propType == "boolean" then convertedVal, convertErr = convertValue(valueStr, "boolean")
        elseif string.find(string.lower(propType), "color3") then convertedVal, convertErr = convertValue(valueStr, "Color3") -- Covers Color3, BrickColor
        elseif string.find(string.lower(propType), "vector3") then convertedVal, convertErr = convertValue(valueStr, "Vector3")
        elseif string.find(string.lower(propType), "enum") then
            local pinfo = script:GetPropertyChangedSignal(propertyName) -- This is not how to get Enum type
            -- More robust way: check targetObject[propertyName].EnumType if it exists
            -- For simplicity, assuming client sends "Enum.Type.Value" as propertyType if it knows it
            -- This part needs more robust type detection for Enums if not explicitly passed.
            -- For now, we assume the client sends a string that can be directly used if it's an Enum.
            local enumMatch = string.match(valueStr, "^Enum%.([^%.]+)%.([^%.]+)$")
            if enumMatch then
                 local enumType, enumValName = string.match(valueStr, "^Enum%.([^%.]+)%.([^%.]+)$")
                 if Enum[enumType] and Enum[enumType][enumValName] then
                    convertedVal = Enum[enumType][enumValName]
                 else
                    convertErr = "Invalid Enum value: " .. valueStr
                 end
            else
                 convertedVal = valueStr -- Fallback to string if not a clear Enum format
            end
        else -- Default to string if type is unknown or other
            convertedVal = valueStr
        end
        
        if convertErr then
            table.insert(errors, "Conversion error for " .. pathString .. ": " .. convertErr)
            goto continueEnvLoop
        end
        if convertedVal == nil and propType ~= "string" and valueStr ~= "" then
             table.insert(errors, "Nil conversion for " .. pathString .. " (type: " .. propType .. ", value: '" .. valueStr .. "')")
             goto continueEnvLoop
        end

        local success, pcallError = pcall(function()
            targetObject[propertyName] = convertedVal
        end)

        if success then
            table.insert(changesMade, pathString .. " set to " .. tostring(valueStr))
        else
            table.insert(errors, "Error setting " .. pathString .. ": " .. pcallError)
        end
        ::continueEnvLoop::
    end

    local feedbackMsg = ""
    if #changesMade > 0 then feedbackMsg = feedbackMsg .. "Applied: " .. table.concat(changesMade, ", ") .. ". " end
    if #errors > 0 then feedbackMsg = feedbackMsg .. "Errors: " .. table.concat(errors, ", ") end

    if feedbackMsg ~= "" then sendFeedback(player, feedbackMsg, #errors > 0) end

    if #changesMade > 0 then
        -- Broadcast to all clients
        local currentEnvData = getCurrentEnvironmentSettings()
        syncEnvironmentEvent:FireAllClients(currentEnvData)
    end
end)

-- Helper for getting current environment settings
function getCurrentEnvironmentSettings()
    local envData = {}
    -- Lighting properties
    local lightingProps = {"Ambient", "Brightness", "ColorShift_Top", "OutdoorAmbient", "GlobalShadows", "ClockTime", "GeographicLatitude", "TimeOfDay"} -- Add more as needed
    for _, prop in ipairs(lightingProps) do
        if Lighting[prop] ~= nil then envData["Lighting." .. prop] = tostring(Lighting[prop]) end
    end
    
    -- Atmosphere properties (if exists)
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmosphere then
        local atmProps = {"Density", "Offset", "Color", "Decay", "Glare", "Haze"} -- Add more
        for _, prop in ipairs(atmProps) do
            if atmosphere[prop] ~= nil then envData["Atmosphere." .. prop] = tostring(atmosphere[prop]) end
        end
    end

    -- Sky properties (if exists)
    local sky = Lighting:FindFirstChildOfClass("Sky") or Workspace:FindFirstChildOfClass("Sky")
    if sky then
        local skyProps = {"SkyboxUp", "SkyboxLf", "SkyboxBk", "SkyboxFt", "SkyboxRt", "SkyboxDn", "SunAngularSize", "SunTextureId", "MoonTextureId", "MoonAngularSize", "StarsCount", "CelestialBodiesShown"} -- Add more
         for _, prop in ipairs(skyProps) do
            if sky[prop] ~= nil then envData["Sky." .. prop] = tostring(sky[prop]) end
        end
    end
    
    -- Terrain properties (Example: Water properties)
    local terrainWaterProps = {"WaterColor", "WaterReflectance", "WaterTransparency", "WaterWaveSize", "WaterWaveSpeed"}
    for _,prop in ipairs(terrainWaterProps) do
        if Terrain[prop] ~= nil then envData["Terrain."..prop] = tostring(Terrain[prop]) end
    end

    return envData
end

-- 6. Request Environment Sync
requestEnvironmentSyncEvent.OnServerEvent:Connect(function(player)
    local envData = getCurrentEnvironmentSettings()
    syncEnvironmentEvent:FireClient(player, envData)
    sendFeedback(player, "Environment settings synced to your client.", false)
end)

-- 7. Advanced Select
advancedSelectEvent.OnServerEvent:Connect(function(player, selectType, value)
    local foundObject = nil
    local searchPath = ""

    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if descendant:IsA("BasePart") then -- Only select BaseParts for now
            local match = false
            if selectType == "ClassName" and descendant.ClassName == value then
                match = true
            elseif selectType == "Material" and descendant.Material.Name == value then
                 match = true
            elseif selectType == "Color" then -- Expects value like "255,0,0"
                local color, err = convertValue(value, "Color3")
                if color and descendant.Color == color then match = true end
            elseif selectType == "Name" and descendant.Name == value then
                match = true
            end
            
            if match then
                foundObject = descendant
                searchPath = foundObject:GetFullName() -- Get path relative to game, client can parse Workspace prefix
                break
            end
        end
    end

    if foundObject then
        sendFeedback(player, "Found object: " .. searchPath .. " matching criteria. Client should select it.", false)
        -- Client side will use this path to visually select.
        -- To make it directly usable by getObjectFromPath, ensure path is relative to Workspace if needed.
        -- clientFeedbackEvent:FireClient(player, {type="AdvancedSelectionResult", path=searchPath}) -- Alternative structured feedback
    else
        sendFeedback(player, "No object found matching criteria '" .. tostring(value) .. "' for type '" .. selectType .. "'.", true)
    end
end)

-- 8. Alignment Event
alignmentEvent.OnServerEvent:Connect(function(player, partPaths, command)
    if not partPaths or #partPaths < 1 then
        sendFeedback(player, "Alignment Error: No parts provided.", true)
        return
    end

    local parts = {}
    for _, path in ipairs(partPaths) do
        local obj, err = getObjectFromPath(player, path)
        if err or not obj or not obj:IsA("BasePart") then
            sendFeedback(player, "Alignment Error: Invalid part or path: " .. (err or path), true)
            return
        end
        if not obj:IsDescendantOf(Workspace) then
            sendFeedback(player, "Alignment Error: Parts must be in Workspace.", true)
            return
        end
        table.insert(parts, obj)
    end

    if #parts == 0 then
        sendFeedback(player, "Alignment Error: No valid parts found for alignment.", true)
        return
    end
    
    -- Simplified example: Align X Min of all selected to the first part's X Min
    -- A full alignment tool would be much more complex.
    local success, err = pcall(function()
        if command == "AlignMinX" and #parts > 0 then
            local primaryPart = parts[1]
            local targetX = primaryPart.Position.X - (primaryPart.Size.X / 2)
            for i = 1, #parts do
                local part = parts[i]
                part.Position = Vector3.new(targetX + (part.Size.X / 2), part.Position.Y, part.Position.Z)
            end
        elseif command == "AlignMaxX" and #parts > 0 then
             local primaryPart = parts[1]
             local targetX = primaryPart.Position.X + (primaryPart.Size.X / 2)
             for i = 1, #parts do
                local part = parts[i]
                part.Position = Vector3.new(targetX - (part.Size.X / 2), part.Position.Y, part.Position.Z)
            end
        elseif command == "AlignCenterX" and #parts > 0 then
            local primaryPart = parts[1]
            local targetX = primaryPart.Position.X
            for i = 1, #parts do
                local part = parts[i]
                part.Position = Vector3.new(targetX, part.Position.Y, part.Position.Z)
            end
        -- Add Y and Z similar commands, and distribution commands (more complex)
        else
            error("Unsupported alignment command: " .. tostring(command))
        end
    end)

    if success then
        sendFeedback(player, "Alignment command '" .. command .. "' executed.", false)
    else
        sendFeedback(player, "Alignment Error: " .. tostring(err), true)
    end
end)

-- 9. Terrain Inspect
terrainInspectEvent.OnServerEvent:Connect(function(player, position)
    if not (type(position) == "Vector3") then
        sendFeedback(player, "Terrain Inspect Error: Invalid position provided.", true)
        return
    end

    local region = Region3.new(position - Vector3.new(0.5,0.5,0.5), position + Vector3.new(0.5,0.5,0.5))
    region = region:ExpandToGrid(4) -- Terrain grid is 4x4x4 studs

    local materials, occupancies, water = nil, nil, nil
    local success, err = pcall(function()
        materials, occupancies, water = Terrain:ReadVoxels(region, 4)
    end)
    
    if not success then
        sendFeedback(player, "Terrain Inspect Error: Could not read voxels - " .. tostring(err), true)
        return
    end

    if materials and materials[1] and materials[1][1] and materials[1][1][1] then
        local materialAtPoint = materials[1][1][1]
        local occupancyAtPoint = occupancies[1][1][1]
        local waterAtPoint = water and water[1] and water[1][1] and water[1][1][1] or 0 -- water might be nil if no water service
        
        local feedbackMsg = string.format("Terrain Voxel Info at [%.1f, %.1f, %.1f]: Material=%s, Occupancy=%.2f, Water=%.2f",
            position.X, position.Y, position.Z,
            tostring(materialAtPoint), occupancyAtPoint, waterAtPoint)
        sendFeedback(player, feedbackMsg, false)
    else
        sendFeedback(player, "Terrain Inspect Error: No terrain data found at the specified point or data format unexpected.", true)
    end
end)

-- 10. Terrain Modify
terrainModifyEvent.OnServerEvent:Connect(function(player, position, shape, size, materialStr)
    if not (type(position) == "Vector3" and type(shape) == "string" and type(size) == "Vector3" and type(materialStr) == "string") then
        sendFeedback(player, "Terrain Modify Error: Invalid parameters.", true)
        return
    end

    local materialEnum, err = convertValue(materialStr, "Material")
    if err or materialEnum == nil then
        sendFeedback(player, "Terrain Modify Error: Invalid material - " .. (err or materialStr), true)
        return
    end

    local success, pcallErr = pcall(function()
        if shape == "Sphere" then
            Terrain:FillBall(position, size.X, materialEnum) -- Assuming size.X is radius for sphere
        elseif shape == "Block" then
            local region = Region3.new(position - size/2, position + size/2)
            Terrain:FillRegion(region:ExpandToGrid(4), 4, materialEnum)
        -- elseif shape == "Cylinder" then Terrain:FillCylinder(CFrame.new(position), size.Y, size.X, materialEnum) -- Height, Radius
        else
            error("Unsupported terrain shape: " .. shape)
        end
    end)

    if success then
        sendFeedback(player, "Terrain modified with " .. shape .. " of " .. materialStr .. " at " .. tostring(position), false)
    else
        sendFeedback(player, "Terrain Modify Error: " .. tostring(pcallErr), true)
    end
end)


print("AllInOneTool.server.luau: All event handlers connected.")
