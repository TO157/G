--!strict

-- src/Modules/UserInteraction.luau
-- This module handles direct user interactions that modify the landscape state.
-- These interactions include planting new objects, changing weather conditions,
-- and modifying properties of existing objects. It also provides an event
-- dispatcher to call the appropriate function based on an event name.

local Types = require(script.Parent.Parent.src.Types)
local Logger = require(script.Parent.Parent.src.Modules.Logger)
-- Assuming LandscapeGenerator might have helper functions we could use, like createBasicObject
-- For now, we'll define object creation logic directly or via a local helper if needed.
-- local LandscapeGenerator = require(script.Parent.Parent.src.Modules.LandscapeGenerator)

local UserInteraction = {}

local objectIdCounter = 0 -- Used to generate unique IDs for user-planted objects.

-- Generates a unique ID for a new object based on time and a counter.
local function generateUniqueObjectId(): string
    objectIdCounter += 1
    return "userObj_" .. tostring(os.time()) .. "_" .. tostring(objectIdCounter)
end

--[[
    Adds a new object to the landscape.
    The object's properties can be influenced by the `interactionEmotion`.
    For example, planting an object while "stressed" might alter its appearance or name.
    @param landscapeState: The current state of the landscape to modify.
    @param objectName: The base name for the new object.
    @param modelId: The asset ID for the object's model.
    @param position: A Vector3 table for the object's position.
    @param interactionEmotion: The user's emotion at the time of planting.
    @return Types.LandscapeState: The modified landscape state with the new object.
--]]
function UserInteraction.plantObject(
    landscapeState: Types.LandscapeState,
    objectName: string,
    modelId: string,
    position: Types.Vector3,
    interactionEmotion: Types.Emotion
): Types.LandscapeState
    local newObjectId = generateUniqueObjectId()
    Logger.info(string.format("Planting object '%s' with model '%s' at (%s) by user interaction, emotion context: '%s'.", objectName, modelId, tostring(position), interactionEmotion))

    -- The interactionEmotion could influence properties, e.g., a "stressed" plant might have a wilted modelId or a specific property.
    -- For this example, we'll use interactionEmotion for the 'themeApplied' property.
    local newObject: Types.LandscapeObject = {
        id = newObjectId,
        name = objectName,
        position = position,
        modelId = modelId, -- In a more complex system, modelId might be chosen based on interactionEmotion
        themeApplied = interactionEmotion,
        properties = {
            isInteractable = true, -- Default for user-planted objects
            interactionType = "user_defined",
        },
    }

    -- If interactionEmotion is "stressed", perhaps we modify its appearance or properties
    if interactionEmotion == "stressed" then
        newObject.name = objectName .. " (Stressed)" -- Example modification
        -- Potentially change modelId or add a specific property
        -- newObject.modelId = "rbxassetid://stressed_version_of_" .. modelId
    end

    landscapeState.objects[newObjectId] = newObject
    return landscapeState
end

--[[
    Changes the current weather conditions in the landscape.
    @param landscapeState: The current landscape state to modify.
    @param weatherType: The type of weather to apply (e.g., "rain", "sunshine").
    @param intensity: The intensity of the weather effect (0 to 1).
    @return Types.LandscapeState: The modified landscape state with updated weather.
--]]
function UserInteraction.changeWeather(
    landscapeState: Types.LandscapeState,
    weatherType: Types.WeatherEffect["type"], -- Correctly referencing the sub-type
    intensity: number
): Types.LandscapeState
    Logger.info(string.format("Changing weather to '%s' with intensity %.2f by user interaction.", weatherType, intensity))
    landscapeState.weather = {
        type = weatherType,
        intensity = intensity,
    }
    return landscapeState
end

--[[
    Modifies a specific property of an existing object in the landscape.
    It can change properties in the `object.properties` table or some top-level ones like `name`.
    Logs a warning if the object or property is not found.
    @param landscapeState: The current landscape state.
    @param objectId: The ID of the object to modify.
    @param propertyName: The name of the property to change.
    @param propertyValue: The new value for the property.
    @return Types.LandscapeState: The modified (or original, if error) landscape state.
--]]
function UserInteraction.modifyObjectProperty(
    landscapeState: Types.LandscapeState,
    objectId: string,
    propertyName: string,
    propertyValue: any
): Types.LandscapeState
    local object = landscapeState.objects[objectId]
    if not object then
        Logger.warn(string.format("UserInteraction.modifyObjectProperty: Object with ID '%s' not found.", objectId))
        return landscapeState
    end

    -- Modify direct properties of the object, or properties within its 'properties' table.
    -- This example prioritizes the 'properties' sub-table for common game attributes.
    if object.properties and object.properties[propertyName] ~= nil then
        object.properties[propertyName] = propertyValue
    elseif object[propertyName] ~= nil then
        -- Allow modification of top-level known properties if needed, but with caution.
        -- Example: object.name = propertyValue
        -- For safety, restrict which top-level properties can be changed or handle type checking.
        -- For now, only modifying 'name' as an example if not in 'properties'.
        if propertyName == "name" and typeof(propertyValue) == "string" then
            object.name = propertyValue
        else
            Logger.warn(string.format("UserInteraction.modifyObjectProperty: Property '%s' not found or not directly modifiable on object ID '%s'.", propertyName, objectId))
        end
    else
        Logger.warn(string.format("UserInteraction.modifyObjectProperty: Property '%s' not found on object ID '%s'.", propertyName, objectId))
    end

    return landscapeState
end

--[[
    Handles various user interaction events by dispatching to the appropriate function.
    This acts as a central point for processing different types of user actions
    defined by `eventName`.
    Logs a warning if event parameters are missing or the event name is unknown.
    @param eventName: A string identifying the type of event (e.g., "USER_PLANTED_OBJECT").
    @param landscapeState: The current landscape state.
    @param eventParams: A table containing parameters specific to the event.
    @return Types.LandscapeState: The modified landscape state, or original if event not handled.
--]]
function UserInteraction.handleInteractionEvent(
    eventName: string,
    landscapeState: Types.LandscapeState,
    eventParams: table
): Types.LandscapeState
    Logger.info(string.format("Handling interaction event: '%s'.", eventName))
    if eventName == "USER_PLANTED_OBJECT" then
        local params = eventParams :: {
            objectName: string,
            modelId: string,
            position: Types.Vector3,
            emotion: Types.Emotion,
        }
        if params then
            return UserInteraction.plantObject(landscapeState, params.objectName, params.modelId, params.position, params.emotion)
        else
            Logger.warn("UserInteraction.handleInteractionEvent: Missing parameters for USER_PLANTED_OBJECT")
        end
    elseif eventName == "USER_CHANGED_WEATHER" then
        local params = eventParams :: { weatherType: Types.WeatherEffect["type"], intensity: number }
        if params then
            return UserInteraction.changeWeather(landscapeState, params.weatherType, params.intensity)
        else
            Logger.warn("UserInteraction.handleInteractionEvent: Missing parameters for USER_CHANGED_WEATHER")
        end
    elseif eventName == "USER_MODIFIED_OBJECT_PROPERTY" then
        local params = eventParams :: { objectId: string, propertyName: string, propertyValue: any }
        if params then
            return UserInteraction.modifyObjectProperty(landscapeState, params.objectId, params.propertyName, params.propertyValue)
        else
            Logger.warn("UserInteraction.handleInteractionEvent: Missing parameters for USER_MODIFIED_OBJECT_PROPERTY")
        end
    else
        Logger.warn(string.format("UserInteraction.handleInteractionEvent: Unknown eventName '%s'.", eventName))
    end

    return landscapeState -- Return unchanged state if event not handled or params missing
end

return UserInteraction
