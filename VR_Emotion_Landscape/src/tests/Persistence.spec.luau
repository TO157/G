--!strict

-- src/tests/Persistence.spec.luau

local Types = require(script.Parent.Parent.src.Types)
local Persistence = require(script.Parent.Parent.src.Modules.Persistence)
local LandscapeGenerator = require(script.Parent.Parent.src.Modules.LandscapeGenerator)

-- Helper function to count objects in a landscape state
local function countObjects(state: Types.LandscapeState?): number
    if not state or not state.objects then return 0 end
    local count = 0
    for _ in pairs(state.objects) do
        count += 1
    end
    return count
end

-- Helper function for basic deep comparison of relevant fields
local function compareLandscapeStates(state1: Types.LandscapeState?, state2: Types.LandscapeState?): boolean
    if not state1 and not state2 then return true end -- Both nil is considered equal for this test's purpose
    if not state1 or not state2 then return false end -- One nil, other not

    if state1.userId ~= state2.userId then return false end
    if state1.currentEmotion ~= state2.currentEmotion then return false end
    if state1.activeTheme.name ~= state2.activeTheme.name then return false end
    if countObjects(state1) ~= countObjects(state2) then return false end
    
    -- For a more thorough check, one might iterate over objects and compare their properties,
    -- but for this test, the above checks are sufficient to demonstrate basic integrity.
    return true
end

local function testSaveAndLoadSingleState()
    print("Starting Test: SaveAndLoadSingleState")
    Persistence.clearMockDatabase() -- Ensure clean state for the test

    local userId = "user123_single"
    local initialEmotion: Types.Emotion = "calm"
    local originalState = LandscapeGenerator.generateLandscape(initialEmotion, userId)

    local saveSuccess = Persistence.saveLandscapeState(originalState)
    assert(saveSuccess, "TestSaveAndLoadSingleState: Save operation failed.")
    print("Test Case Info: State saved for " .. userId)

    local loadedState = Persistence.loadLandscapeState(userId)
    assert(loadedState ~= nil, "TestSaveAndLoadSingleState: Loaded state is nil for existing user.")
    assert(compareLandscapeStates(originalState, loadedState), "TestSaveAndLoadSingleState: Loaded state does not match original state.")
    print("Test Case Passed: SaveAndLoadSingleState - State saved and loaded successfully, matches original.")

    -- Test loading non-existent user
    local nonExistentState = Persistence.loadLandscapeState("nonExistentUser_abc123")
    assert(nonExistentState == nil, "TestSaveAndLoadSingleState: Loading state for non-existent user did not return nil.")
    print("Test Case Passed: SaveAndLoadSingleState - Loading non-existent user returns nil.")
end

local function testSaveAndLoadMultipleStates()
    print("Starting Test: SaveAndLoadMultipleStates")
    Persistence.clearMockDatabase()

    local user1Id = "userMulti_1"
    local user1Emotion: Types.Emotion = "excited"
    local user1State = LandscapeGenerator.generateLandscape(user1Emotion, user1Id)

    local user2Id = "userMulti_2"
    local user2Emotion: Types.Emotion = "stressed"
    local user2State = LandscapeGenerator.generateLandscape(user2Emotion, user2Id)

    assert(Persistence.saveLandscapeState(user1State), "TestSaveAndLoadMultipleStates: Save failed for user1.")
    assert(Persistence.saveLandscapeState(user2State), "TestSaveAndLoadMultipleStates: Save failed for user2.")
    print("Test Case Info: States saved for " .. user1Id .. " and " .. user2Id)

    local loadedUser1State = Persistence.loadLandscapeState(user1Id)
    local loadedUser2State = Persistence.loadLandscapeState(user2Id)

    assert(loadedUser1State ~= nil, "TestSaveAndLoadMultipleStates: Loaded state for user1 is nil.")
    assert(compareLandscapeStates(user1State, loadedUser1State), "TestSaveAndLoadMultipleStates: Loaded state for user1 does not match original.")
    print("Test Case Passed: SaveAndLoadMultipleStates - User1 state loaded correctly.")

    assert(loadedUser2State ~= nil, "TestSaveAndLoadMultipleStates: Loaded state for user2 is nil.")
    assert(compareLandscapeStates(user2State, loadedUser2State), "TestSaveAndLoadMultipleStates: Loaded state for user2 does not match original.")
    print("Test Case Passed: SaveAndLoadMultipleStates - User2 state loaded correctly.")
end

local function testGetSharedLandscapeUpdates()
    print("Starting Test: GetSharedLandscapeUpdates")
    Persistence.clearMockDatabase()

    local initialTime = os.time()

    -- Wait a second to ensure subsequent saves have a later timestamp
    -- Note: In a real test environment, os.time() might be too coarse.
    -- You might need to mock os.time() or use a more precise timer if available.
    -- For this simulation, a small delay is acceptable.
    local t0 = os.time()
    repeat until os.time() > t0 -- busy wait for 1 second

    local user1Id = "userSync_1"
    local state1 = LandscapeGenerator.generateLandscape("calm", user1Id)
    Persistence.saveLandscapeState(state1) -- Saved after initialTime

    local user2Id = "userSync_2"
    local state2 = LandscapeGenerator.generateLandscape("neutral", user2Id)
    -- Do not save state2 yet

    local user3Id = "userSync_3"
    local state3 = LandscapeGenerator.generateLandscape("excited", user3Id)
    Persistence.saveLandscapeState(state3) -- Saved after initialTime

    local updates = Persistence.getSharedLandscapeUpdates(initialTime)
    assert(updates[user1Id] ~= nil, "TestGetSharedUpdates: User1's update not found.")
    assert(compareLandscapeStates(state1, updates[user1Id]), "TestGetSharedUpdates: User1's state mismatch.")
    assert(updates[user3Id] ~= nil, "TestGetSharedUpdates: User3's update not found.")
    assert(compareLandscapeStates(state3, updates[user3Id]), "TestGetSharedUpdates: User3's state mismatch.")
    assert(updates[user2Id] == nil, "TestGetSharedUpdates: User2's state (unsaved) should not be present.")
    
    local updateCount = 0
    for _ in pairs(updates) do updateCount += 1 end
    assert(updateCount == 2, "TestGetSharedUpdates: Expected 2 updates, got " .. tostring(updateCount))

    print("Test Case Passed: GetSharedLandscapeUpdates - Correctly retrieved states modified after timestamp.")

    -- Test with no new updates
    local currentTime = os.time()
    local noNewUpdates = Persistence.getSharedLandscapeUpdates(currentTime)
    local noNewUpdateCount = 0
    for _ in pairs(noNewUpdates) do noNewUpdateCount += 1 end
    assert(noNewUpdateCount == 0, "TestGetSharedUpdates: Expected 0 updates when timestamp is current, got " .. tostring(noNewUpdateCount))
    print("Test Case Passed: GetSharedLandscapeUpdates - Correctly returns no updates for current timestamp.")
end


-- Run tests
print("Starting Persistence tests...")

testSaveAndLoadSingleState()
testSaveAndLoadMultipleStates()
testGetSharedLandscapeUpdates()

print("All Persistence tests executed.")
