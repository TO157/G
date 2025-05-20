--!strict

-- src/main.luau
-- This script serves as the main entry point for a simulation of the
-- VR Emotion-Driven Dynamic Landscape System. It demonstrates the core
-- functionalities of the system by initializing a user session,
-- simulating emotion changes, handling user interactions, and managing
-- data persistence through the LandscapeService.

-- Assume script is run in an environment where 'src' is a known root for modules
-- or paths are adjusted accordingly by the execution environment.
-- Example for Roblox-like: local LandscapeService = require(game.ReplicatedStorage.VR_Emotion_Landscape.src.Services.LandscapeService)
-- For standalone Luau, paths might be relative or configured.
-- Using a placeholder style that needs correct path resolution by the Luau runtime.
local LandscapeService = require(script.Parent.Services.LandscapeService)
local Logger = require(script.Parent.Modules.Logger)
local Types = require(script.Parent.Types) -- For type hints and constructing params

-- Helper to count objects (if not already in a shared utility)
local function countObjects(objects: { [string]: Types.LandscapeObject }): number
    local count = 0
    for _ in pairs(objects) do
        count += 1
    end
    return count
end

--[[
    The main function to run the VR Emotion Landscape simulation.
    It performs a sequence of operations:
    1. Initializes a user session with a "neutral" mood.
    2. Simulates an emotion change to "excited".
    3. Simulates user interaction: planting an object ("MysticFlower").
    4. Simulates another user interaction: changing weather to "rain".
    5. Saves the user's landscape state.
    6. Attempts to reload the session for the same user to demonstrate persistence.
    Logs information at each step using the Logger module.
--]]
local function main()
    local userId = "testUserMain123"
    Logger.info("Starting VR Emotion Landscape Simulation for userId: " .. userId)

    -- Initial Session
    Logger.info("Step 1: Initializing user session with mood: 'neutral'.")
    local currentLandscapeState = LandscapeService.initializeUserSession(userId, "neutral")

    if not currentLandscapeState then
        Logger.error("Failed to initialize landscape state. Simulation cannot continue.")
        return
    end
    Logger.info(string.format("Session initialized. Current emotion: '%s', Theme: '%s'. Objects: %d",
        currentLandscapeState.currentEmotion,
        currentLandscapeState.activeTheme.name,
        countObjects(currentLandscapeState.objects)))
    print("----------------------------------------------------")

    -- Simulate an Emotion Change
    Logger.info("Step 2: Simulating emotion change to 'excited'.")
    currentLandscapeState = LandscapeService.updateUserEmotionAndLandscape(userId, currentLandscapeState, "excited")
    Logger.info(string.format("Emotion updated. New emotion: '%s', New Theme: '%s'. Objects: %d",
        currentLandscapeState.currentEmotion,
        currentLandscapeState.activeTheme.name,
        countObjects(currentLandscapeState.objects)))
    print("----------------------------------------------------")

    -- Simulate a User Interaction: Plant Object
    Logger.info("Step 3: Simulating user interaction - Plant Object ('MysticFlower').")
    local plantEventParams = {
        objectName = "MysticFlower", -- Changed from 'name' to 'objectName' to match UserInteraction.plantObject if event params are passed directly
        modelId = "flower_model_01",
        position = { x = 10, y = 0, z = 5 }, -- Using table for Vector3
        emotion = currentLandscapeState.currentEmotion,
    }
    currentLandscapeState = LandscapeService.handleUserInteraction(currentLandscapeState, "USER_PLANTED_OBJECT", plantEventParams)
    Logger.info(string.format("Object planted. Total objects now: %d. Current weather: %s (%.2f intensity)",
        countObjects(currentLandscapeState.objects),
        currentLandscapeState.weather.type,
        currentLandscapeState.weather.intensity))
    -- Verify MysticFlower exists
    local mysticFlowerExists = false
    for _, obj in pairs(currentLandscapeState.objects) do
        if obj.name == "MysticFlower" then
            mysticFlowerExists = true
            Logger.info("Verified: 'MysticFlower' is present in the landscape.")
            break
        end
    end
    if not mysticFlowerExists then
        Logger.warn("Warning: 'MysticFlower' was not found after planting event.")
    end
    print("----------------------------------------------------")

    -- Simulate Another Interaction: Change Weather
    Logger.info("Step 4: Simulating user interaction - Change Weather to 'rain'.")
    local weatherEventParams = {
        weatherType = "rain", -- This is Types.WeatherEffect["type"]
        intensity = 0.7,
    }
    currentLandscapeState = LandscapeService.handleUserInteraction(currentLandscapeState, "USER_CHANGED_WEATHER", weatherEventParams)
    Logger.info(string.format("Weather changed. New weather: %s, Intensity: %.2f.",
        currentLandscapeState.weather.type,
        currentLandscapeState.weather.intensity))
    print("----------------------------------------------------")

    -- Save Session
    Logger.info("Step 5: Saving user session.")
    local saveSuccess = LandscapeService.saveUserLandscape(currentLandscapeState)
    if saveSuccess then
        Logger.info("Session saved successfully.")
    else
        Logger.error("Failed to save session.")
    end
    print("----------------------------------------------------")

    -- Reload Session (Demonstration)
    Logger.info("Step 6: Attempting to reload session for userId: " .. userId .. " with initial mood 'calm'.")
    local reloadedLandscapeState = LandscapeService.initializeUserSession(userId, "calm")

    if not reloadedLandscapeState then
        Logger.error("Failed to reload landscape state.")
    else
        Logger.info("Session reloaded successfully.")
        Logger.info(string.format("Reloaded State Info - Emotion: '%s', Theme: '%s', Objects: %d, Weather: %s (%.2f intensity)",
            reloadedLandscapeState.currentEmotion,
            reloadedLandscapeState.activeTheme.name,
            countObjects(reloadedLandscapeState.objects),
            reloadedLandscapeState.weather.type,
            reloadedLandscapeState.weather.intensity))
        
        -- Verify MysticFlower persisted
        local reloadedMysticFlowerExists = false
        for _, obj in pairs(reloadedLandscapeState.objects) do
            if obj.name == "MysticFlower" then
                reloadedMysticFlowerExists = true
                Logger.info("Verified: 'MysticFlower' persisted and is present in the reloaded landscape.")
                break
            end
        end
        if not reloadedMysticFlowerExists then
            Logger.warn("Warning: 'MysticFlower' did NOT persist or was not found in the reloaded landscape.")
        end
    end
    print("----------------------------------------------------")

    Logger.info("VR Emotion Landscape Simulation Complete.")
end

-- Run the simulation
-- In some Luau environments, pcall is good practice for the main execution too
local success, err = pcall(main)
if not success then
    Logger.error("Simulation CRASHED: " .. tostring(err), err)
end
