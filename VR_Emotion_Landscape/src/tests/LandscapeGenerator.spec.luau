--!strict

-- src/tests/LandscapeGenerator.spec.luau

local Types = require(script.Parent.Parent.src.Types)
local LandscapeGenerator = require(script.Parent.Parent.src.Modules.LandscapeGenerator)

-- Mock Color3 and Vector3 if they are not globally available in the test environment
-- For this example, we assume they are available or not strictly needed for the logic being tested
-- (e.g., we're checking names and existence, not actual Vector3 math)
-- If Color3.new or Vector3.new calls were made *during the test itself* for assertions,
-- and they aren't global, you'd need to mock them:
-- getfenv().Color3 = { new = function(r,g,b) return {r=r,g=g,b=b} end }
-- getfenv().Vector3 = { new = function(x,y,z) return {x=x,y=y,z=z} end }

local function countObjects(objects: { [string]: Types.LandscapeObject }): number
    local count = 0
    for _ in pairs(objects) do
        count += 1
    end
    return count
end

local function testGenerateLandscapeForEmotion(emotion: Types.Emotion, expectedThemeName: string, expectedWeatherType: Types.WeatherEffect["type"])
    local userId = "testUser123"
    local state = LandscapeGenerator.generateLandscape(emotion, userId)

    assert(state.userId == userId, string.format("Test Case Failed: UserID for %s - Expected %s, got %s", emotion, userId, state.userId))
    assert(state.currentEmotion == emotion, string.format("Test Case Failed: CurrentEmotion for %s - Expected %s, got %s", emotion, emotion, state.currentEmotion))
    assert(state.activeTheme.name == expectedThemeName, string.format("Test Case Failed: ThemeName for %s - Expected %s, got %s", emotion, expectedThemeName, state.activeTheme.name))
    
    local numObjects = countObjects(state.objects)
    assert(numObjects > 0, string.format("Test Case Failed: Objects for %s - Expected at least 1 object, got %d", emotion, numObjects))
    
    assert(state.weather.type == expectedWeatherType, string.format("Test Case Failed: WeatherType for %s - Expected %s, got %s", emotion, expectedWeatherType, state.weather.type))

    print(string.format("Test Case Passed: GenerateLandscape for %s (Theme: %s, Weather: %s, Objects: %d)", emotion, expectedThemeName, expectedWeatherType, numObjects))
end

local function testCreateBasicObject()
    local obj = LandscapeGenerator.createBasicObject("obj1", "Test Object", "model123", Vector3.new(1,2,3), "neutral", true, "test_interaction")
    assert(obj.id == "obj1", "Test BasicObject: ID failed")
    assert(obj.name == "Test Object", "Test BasicObject: Name failed")
    assert(obj.modelId == "model123", "Test BasicObject: ModelID failed")
    assert(obj.position.x == 1 and obj.position.y == 2 and obj.position.z == 3, "Test BasicObject: Position failed")
    assert(obj.themeApplied == "neutral", "Test BasicObject: ThemeApplied failed")
    assert(obj.properties and obj.properties.isInteractable == true, "Test BasicObject: Interactable failed")
    assert(obj.properties and obj.properties.interactionType == "test_interaction", "Test BasicObject: InteractionType failed")
    print("Test Case Passed: CreateBasicObject")
end

local function testThemeSpecificObjectCreation()
    -- Test Palm Tree (Calm theme object)
    local palm = LandscapeGenerator.createPalmTree("palmTest", Vector3.new(10,0,10))
    assert(palm.name == "Palm Tree", "Test PalmTree: Name failed")
    assert(palm.themeApplied == "calm", "Test PalmTree: Theme failed")
    assert(palm.species == "Cocos Nucifera", "Test PalmTree: Species failed")
    print("Test Case Passed: CreatePalmTree (Theme-specific)")

    -- Test Glowing Mushroom (Excited theme object)
    local mushroom = LandscapeGenerator.createGlowingMushroom("mushroomTest", Vector3.new(0,0,0))
    assert(mushroom.name == "Giant Glowing Mushroom", "Test GlowingMushroom: Name failed")
    assert(mushroom.themeApplied == "excited", "Test GlowingMushroom: Theme failed")
    assert(mushroom.properties and mushroom.properties.interactionType == "touch_toggle_light", "Test GlowingMushroom: InteractionType failed")
    print("Test Case Passed: CreateGlowingMushroom (Theme-specific)")
end


-- Run tests
print("Starting LandscapeGenerator tests...")

testGenerateLandscapeForEmotion("calm", "Serene Beach", "sunshine")
testGenerateLandscapeForEmotion("excited", "Vibrant Forest", "sunshine")
testGenerateLandscapeForEmotion("neutral", "Quiet Meadow", "sunshine")
testGenerateLandscapeForEmotion("stressed", "Stormy Highlands", "rain")

testCreateBasicObject()
testThemeSpecificObjectCreation()

print("All LandscapeGenerator tests executed.")
