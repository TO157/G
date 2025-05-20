--!strict

-- src/Services/LandscapeService.luau
-- This service module acts as the central orchestrator for the VR Emotion Landscape system.
-- It integrates functionalities from various modules (EmotionDetection, LandscapeGenerator,
-- UserInteraction, Persistence, Logger) to manage user sessions, update landscapes
-- based on emotions, handle user interactions, and persist landscape states.

local Types = require(script.Parent.Parent.src.Types)
local EmotionDetection = require(script.Parent.Parent.src.Modules.EmotionDetection)
local LandscapeGenerator = require(script.Parent.Parent.src.Modules.LandscapeGenerator)
local UserInteraction = require(script.Parent.Parent.src.Modules.UserInteraction)
local Persistence = require(script.Parent.Parent.src.Modules.Persistence)
local Logger = require(script.Parent.Parent.src.Modules.Logger)

local LandscapeService = {}

--[[
    Initializes a user session. This involves:
    1. Simulating biometric data based on the `initialMood`.
    2. Classifying the initial emotion from this data.
    3. Attempting to load an existing landscape state for the `userId`.
    4. If a state is loaded and its emotion matches the new initial emotion, it's returned.
       If the emotions differ, a new landscape is generated for the new initial emotion.
    5. If no state is loaded, a new landscape is generated based on the `initialEmotion`.
    Logs key steps and errors encountered.
    @param userId: The unique identifier for the user.
    @param initialMood: A string representing the user's starting mood (e.g., "calm", "excited").
    @return Types.LandscapeState?: The initialized or loaded landscape state, or nil if critical error occurs.
--]]
function LandscapeService.initializeUserSession(userId: string, initialMood: string): Types.LandscapeState?
    Logger.info(string.format("Initializing user session for userId: %s with initial mood: %s.", userId, initialMood))

    local biometricData: Types.BiometricData
    local pcallSuccess, result = pcall(function()
        biometricData = EmotionDetection.getSimulatedBiometricData(initialMood)
    end)

    if not pcallSuccess then
        Logger.error(string.format("Failed to get simulated biometric data for mood: %s. Error: %s", initialMood, tostring(result)), result)
        return nil -- Or handle error more gracefully
    end

    local initialEmotion = EmotionDetection.classifyEmotion(biometricData)
    Logger.info(string.format("Initial mood '%s' classified as emotion '%s' for userId: %s.", initialMood, initialEmotion, userId))

    local loadedState = Persistence.loadLandscapeState(userId)

    if loadedState then
        Logger.info(string.format("Loaded existing landscape state for userId: %s.", userId))
        -- Optionally, update currentEmotion if the new initialMood leads to a different predominant emotion
        -- For simplicity, we'll assume the loaded state's emotion is what we want, or regenerate if different.
        -- Or, more robustly:
        if loadedState.currentEmotion ~= initialEmotion then
            Logger.info(string.format("Initial mood ('%s') results in a different emotion ('%s') than stored ('%s'). Regenerating landscape for userId: %s.", initialMood, initialEmotion, loadedState.currentEmotion, userId))
            loadedState = LandscapeGenerator.generateLandscape(initialEmotion, userId)
            loadedState.currentEmotion = initialEmotion -- Ensure this is set
        else
            -- Ensure the current emotion of the loaded state reflects the classified initial emotion,
            -- even if the theme itself isn't regenerated. This keeps the state consistent.
            loadedState.currentEmotion = initialEmotion
        end
        return loadedState
    else
        Logger.info(string.format("No existing landscape state found for userId: %s. Generating new landscape.", userId))
        local newState = LandscapeGenerator.generateLandscape(initialEmotion, userId)
        return newState
    end
end

--[[
    Updates the user's landscape based on a new mood.
    1. Simulates biometric data for the `newMood`.
    2. Classifies the `newEmotion`.
    3. If the `newEmotion` is different from the `currentLandscape.currentEmotion`,
       a new landscape is generated.
    4. Otherwise, the current landscape is returned with its emotion field updated if necessary.
    Logs key steps and errors.
    @param userId: The user's ID.
    @param currentLandscape: The user's current Types.LandscapeState.
    @param newMood: A string for the user's new mood.
    @return Types.LandscapeState: The (potentially new) landscape state.
--]]
function LandscapeService.updateUserEmotionAndLandscape(userId: string, currentLandscape: Types.LandscapeState, newMood: string): Types.LandscapeState
    Logger.info(string.format("Updating user emotion and landscape for userId: %s with new mood: %s.", userId, newMood))

    local biometricData: Types.BiometricData
    local pcallSuccess, result = pcall(function()
        biometricData = EmotionDetection.getSimulatedBiometricData(newMood)
    end)

    if not pcallSuccess then
        Logger.error(string.format("Failed to get simulated biometric data for new mood: %s. Error: %s", newMood, tostring(result)), result)
        return currentLandscape -- Return original state if mood processing fails
    end
    
    local newEmotion = EmotionDetection.classifyEmotion(biometricData)
    Logger.info(string.format("New mood '%s' classified as emotion '%s' for userId: %s.", newMood, newEmotion, userId))

    if newEmotion ~= currentLandscape.currentEmotion then
        Logger.info(string.format("Emotion changed for userId: %s from '%s' to '%s'. Generating new landscape.", userId, currentLandscape.currentEmotion, newEmotion))
        local newLandscape = LandscapeGenerator.generateLandscape(newEmotion, userId)
        return newLandscape
    else
        Logger.info(string.format("Emotion ('%s') unchanged for userId: %s. Landscape remains the same.", newEmotion, userId))
        -- Ensure currentLandscape.currentEmotion is updated if it somehow diverged, though logic implies it should be newEmotion
        currentLandscape.currentEmotion = newEmotion
        return currentLandscape
    end
end

--[[
    Processes a user interaction event and updates the landscape accordingly.
    This function acts as a wrapper around `UserInteraction.handleInteractionEvent`,
    providing logging and error handling via pcall.
    @param currentLandscape: The current Types.LandscapeState.
    @param eventName: A string identifying the interaction event (e.g., "USER_PLANTED_OBJECT").
    @param eventParams: A table of parameters for the event.
    @return Types.LandscapeState: The modified landscape state, or original if an error occurs.
--]]
function LandscapeService.handleUserInteraction(currentLandscape: Types.LandscapeState, eventName: string, eventParams: table): Types.LandscapeState
    Logger.info(string.format("Handling user interaction event '%s' for landscape of userId: %s.", eventName, currentLandscape.userId))
    
    local pcallSuccess, resultOrState = pcall(function()
        return UserInteraction.handleInteractionEvent(eventName, currentLandscape, eventParams)
    end)

    if not pcallSuccess then
        Logger.error(string.format("Error during UserInteraction.handleInteractionEvent for event '%s', userId '%s'. Error: %s", eventName, currentLandscape.userId, tostring(resultOrState)), resultOrState)
        return currentLandscape -- Return original state on error
    end
    
    local modifiedLandscape = resultOrState :: Types.LandscapeState 
    return modifiedLandscape
end

--[[
    Saves the user's current landscape state using the Persistence module.
    Logs the success or failure of the save operation.
    @param landscapeState: The Types.LandscapeState to be saved.
    @return boolean: True if saving was successful (as per Persistence module), false otherwise.
--]]
function LandscapeService.saveUserLandscape(landscapeState: Types.LandscapeState): boolean
    Logger.info(string.format("Attempting to save landscape state for userId: %s.", landscapeState.userId))
    
    local success = Persistence.saveLandscapeState(landscapeState)
    if success then
        Logger.info(string.format("Landscape state successfully saved for userId: %s.", landscapeState.userId))
    else
        Logger.error(string.format("Failed to save landscape state for userId: %s.", landscapeState.userId))
    end
    return success
end

return LandscapeService
