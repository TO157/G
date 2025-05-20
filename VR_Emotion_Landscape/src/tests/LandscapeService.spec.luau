--!strict

-- src/tests/LandscapeService.spec.luau

local Types = require(script.Parent.Parent.src.Types)
local LandscapeService = require(script.Parent.Parent.src.Services.LandscapeService)
local Persistence = require(script.Parent.Parent.src.Modules.Persistence) -- For clearing DB
local Logger = require(script.Parent.Parent.src.Modules.Logger)

-- Helper to count objects in a state
local function countObjects(state: Types.LandscapeState?): number
    if not state or not state.objects then return 0 end
    local count = 0
    for _ in pairs(state.objects) do
        count += 1
    end
    return count
end

local function beforeEach()
    Logger.info("--- Test Case Start ---")
    Persistence.clearMockDatabase() -- Clear mock DB before each test
end

local function afterEach()
    Logger.info("--- Test Case End ---")
end

local function testInitializeNewUserSession()
    beforeEach()
    Logger.info("Test: InitializeNewUserSession - New User")
    local userId = "newUser_InitTest"
    local initialMood = "calm"

    local landscapeState = LandscapeService.initializeUserSession(userId, initialMood)

    assert(landscapeState ~= nil, "New user session should return a landscape state.")
    if landscapeState then
        assert(landscapeState.userId == userId, "User ID mismatch in new session.")
        assert(landscapeState.currentEmotion == "calm", "Emotion mismatch for calm mood in new session. Got: " .. landscapeState.currentEmotion)
        assert(countObjects(landscapeState) > 0, "New landscape should have objects.")
        Logger.info("PASS: New user session initialized correctly.")
    end
    afterEach()
end

local function testInitializeExistingUserSession()
    beforeEach()
    Logger.info("Test: InitializeExistingUserSession - Existing User")
    local userId = "existingUser_InitTest"
    local initialMood = "excited"

    -- Setup: Create and save an initial state
    local initialGeneratedState = LandscapeService.initializeUserSession(userId, initialMood)
    assert(initialGeneratedState ~= nil, "Failed to setup initial state for existing user test.")
    if not initialGeneratedState then return afterEach() end -- Guard against nil
    initialGeneratedState.objects["testObj1"] = { -- Add a unique object to identify this saved state
        id = "testObj1", name = "MyMarker", position = Vector3.new(1,1,1), modelId = "id", themeApplied = "excited"
    }
    local saveSuccess = LandscapeService.saveUserLandscape(initialGeneratedState)
    assert(saveSuccess, "Failed to save initial state for existing user test.")

    -- Test: Initialize session for the same user
    local loadedState = LandscapeService.initializeUserSession(userId, initialMood)
    assert(loadedState ~= nil, "Existing user session should load a landscape state.")
    if loadedState then
        assert(loadedState.userId == userId, "User ID mismatch in loaded session.")
        assert(loadedState.currentEmotion == "excited", "Emotion mismatch in loaded session. Got: " .. loadedState.currentEmotion)
        assert(loadedState.objects["testObj1"] ~= nil and loadedState.objects["testObj1"].name == "MyMarker",
            "Loaded state does not contain the marker object, indicating it might be a new state.")
        Logger.info("PASS: Existing user session loaded correctly.")
    end
    afterEach()
end

local function testUpdateUserEmotionAndLandscape_EmotionChange()
    beforeEach()
    Logger.info("Test: UpdateUserEmotionAndLandscape - Emotion Changes")
    local userId = "user_EmotionUpdateTest"
    local initialMood = "neutral"
    local initialLandscape = LandscapeService.initializeUserSession(userId, initialMood)
    assert(initialLandscape ~= nil, "Failed to initialize session for emotion update test.")
    if not initialLandscape then return afterEach() end

    local initialThemeName = initialLandscape.activeTheme.name

    local newMood = "stressed" -- This should result in a different emotion and theme
    local updatedLandscape = LandscapeService.updateUserEmotionAndLandscape(userId, initialLandscape, newMood)

    assert(updatedLandscape ~= nil, "Updated landscape state is nil.")
    if updatedLandscape then
        assert(updatedLandscape.currentEmotion == "stressed", "Emotion did not update to stressed. Got: "..updatedLandscape.currentEmotion)
        assert(updatedLandscape.activeTheme.name ~= initialThemeName, "Theme should change when emotion changes significantly.")
        Logger.info("PASS: Landscape updated correctly on emotion change.")
    end
    afterEach()
end

local function testUpdateUserEmotionAndLandscape_EmotionSame()
    beforeEach()
    Logger.info("Test: UpdateUserEmotionAndLandscape - Emotion Stays Same")
    local userId = "user_EmotionNoChangeTest"
    local initialMood = "calm" -- e.g. heartRate = 50, skinConductance = 0.1
    local initialLandscape = LandscapeService.initializeUserSession(userId, initialMood)
    assert(initialLandscape ~= nil, "Failed to initialize session for emotion no-change test.")
    if not initialLandscape then return afterEach() end

    local initialThemeName = initialLandscape.activeTheme.name
    local initialObjectCount = countObjects(initialLandscape)

    -- A mood that should still be classified as "calm"
    -- Depending on EmotionDetection logic, this might need adjustment.
    -- For instance, if `getSimulatedBiometricData("calm_variant")` existed and returned different HR/SC
    -- but still within "calm" classification. For now, using the same mood implies same emotion.
    local newMood = "calm"
    local updatedLandscape = LandscapeService.updateUserEmotionAndLandscape(userId, initialLandscape, newMood)

    assert(updatedLandscape ~= nil, "Updated landscape state is nil.")
    if updatedLandscape then
        assert(updatedLandscape.currentEmotion == "calm", "Emotion should remain calm.")
        assert(updatedLandscape.activeTheme.name == initialThemeName, "Theme should not change if emotion is the same.")
        assert(countObjects(updatedLandscape) == initialObjectCount, "Object count should not change if emotion is the same and no regeneration occurs.")
        Logger.info("PASS: Landscape remains unchanged when emotion is the same.")
    end
    afterEach()
end

local function testHandleUserInteraction_PlantObject()
    beforeEach()
    Logger.info("Test: HandleUserInteraction - Plant Object")
    local userId = "user_InteractionTest"
    local initialMood = "neutral"
    local currentLandscape = LandscapeService.initializeUserSession(userId, initialMood)
    assert(currentLandscape ~= nil, "Failed to initialize session for interaction test.")
    if not currentLandscape then return afterEach() end

    local initialObjectCount = countObjects(currentLandscape)

    local eventName = "USER_PLANTED_OBJECT"
    local eventParams = {
        objectName = "TestTreeFromService",
        modelId = "rbxassetid://tree_model",
        position = Vector3.new(10, 0, 5),
        emotion = currentLandscape.currentEmotion, -- Plant with current emotion
    }

    local modifiedLandscape = LandscapeService.handleUserInteraction(currentLandscape, eventName, eventParams)
    assert(modifiedLandscape ~= nil, "Modified landscape is nil after interaction.")
    if modifiedLandscape then
        assert(countObjects(modifiedLandscape) == initialObjectCount + 1, "Object count should increase after planting.")
        local foundPlantedObject = false
        for _, obj in pairs(modifiedLandscape.objects) do
            if obj.name == "TestTreeFromService" then
                foundPlantedObject = true
                break
            end
        end
        assert(foundPlantedObject, "The planted object 'TestTreeFromService' was not found.")
        Logger.info("PASS: User interaction (plant object) handled correctly.")
    end
    afterEach()
end

local function testSaveAndLoadUserLandscape()
    beforeEach()
    Logger.info("Test: SaveAndLoadUserLandscape")
    local userId = "user_SaveLoadTest"
    local initialMood = "excited"

    -- 1. Initialize and get a state
    local landscapeToSave = LandscapeService.initializeUserSession(userId, initialMood)
    assert(landscapeToSave ~= nil, "Failed to initialize session for save/load test.")
    if not landscapeToSave then return afterEach() end

    -- 2. Modify it (e.g., add an object through interaction)
    local plantParams = { objectName = "SavedFlower", modelId = "flower_id", position = Vector3.new(1,0,1), emotion = "excited" }
    landscapeToSave = LandscapeService.handleUserInteraction(landscapeToSave, "USER_PLANTED_OBJECT", plantParams)
    assert(landscapeToSave.objects["SavedFlower"] == nil, "Object 'SavedFlower' was not added as expected before saving. Check object ID generation in UserInteraction or the test key.")
    -- Correction: UserInteraction.plantObject generates a unique ID. We need to find the object by name or a known property.
    local savedFlowerId = ""
    for id, obj in pairs(landscapeToSave.objects) do
        if obj.name == "SavedFlower" then
            savedFlowerId = id
            break
        end
    end
    assert(savedFlowerId ~= "", "Object 'SavedFlower' was not added as expected before saving.")


    -- 3. Save it
    local saveSuccess = LandscapeService.saveUserLandscape(landscapeToSave)
    assert(saveSuccess, "Saving landscape failed.")

    -- 4. Load it again (e.g., through a new session initialization for the same user)
    local loadedLandscape = LandscapeService.initializeUserSession(userId, initialMood) -- Should load from persistence
    assert(loadedLandscape ~= nil, "Failed to load landscape after saving.")
    if loadedLandscape then
        assert(loadedLandscape.userId == userId, "Loaded landscape has incorrect userId.")
        assert(loadedLandscape.currentEmotion == "excited", "Loaded landscape has incorrect emotion.")
        assert(loadedLandscape.objects[savedFlowerId] ~= nil and loadedLandscape.objects[savedFlowerId].name == "SavedFlower",
            "The specific modification (SavedFlower) was not found in the loaded landscape.")
        Logger.info("PASS: Landscape saved and loaded correctly, reflecting modifications.")
    end
    afterEach()
end

local function testInitializeUserSession_ErrorInBiometricData()
    beforeEach()
    Logger.info("Test: InitializeUserSession - Error in getSimulatedBiometricData")
    local userId = "user_BioErrorTest"
    local initialMood = "unknown_mood_for_error" -- This mood should cause an error in EmotionDetection

    local landscapeState = LandscapeService.initializeUserSession(userId, initialMood)

    assert(landscapeState == nil, "Landscape state should be nil when biometric data generation fails.")
    Logger.info("PASS: InitializeUserSession handles error from EmotionDetection.getSimulatedBiometricData correctly (returns nil).")
    afterEach()
end


-- Run tests
Logger.info("===== Starting LandscapeService Tests =====")

testInitializeNewUserSession()
testInitializeExistingUserSession()
testUpdateUserEmotionAndLandscape_EmotionChange()
testUpdateUserEmotionAndLandscape_EmotionSame()
testHandleUserInteraction_PlantObject()
testSaveAndLoadUserLandscape()
testInitializeUserSession_ErrorInBiometricData()

Logger.info("===== LandscapeService Tests Complete =====")
