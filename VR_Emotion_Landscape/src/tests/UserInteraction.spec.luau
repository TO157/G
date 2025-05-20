--!strict

-- src/tests/UserInteraction.spec.luau

local Types = require(script.Parent.Parent.src.Types)
local UserInteraction = require(script.Parent.Parent.src.Modules.UserInteraction)
local LandscapeGenerator = require(script.Parent.Parent.src.Modules.LandscapeGenerator) -- To get initial states

-- Mock Vector3 if not globally available (as in LandscapeGenerator.spec.luau)
-- getfenv().Vector3 = { new = function(x,y,z) return {x=x,y=y,z=z} end }

local function countObjects(objects: { [string]: Types.LandscapeObject }): number
    local count = 0
    for _ in pairs(objects) do
        count += 1
    end
    return count
end

local function testPlantObject()
    print("Starting Test: PlantObject")
    local initialLandscape = LandscapeGenerator.generateLandscape("neutral", "testUser")
    local initialObjectCount = countObjects(initialLandscape.objects)

    local modifiedLandscape = UserInteraction.plantObject(
        initialLandscape,
        "Test Plant",
        "rbxassetid://test_plant_model",
        Vector3.new(10, 0, 10),
        "calm"
    )

    local newObjectCount = countObjects(modifiedLandscape.objects)
    assert(newObjectCount == initialObjectCount + 1, "TestPlantObject: Object count should increase by 1. Got " .. tostring(newObjectCount))

    local plantedObjectFound = false
    for _, obj in pairs(modifiedLandscape.objects) do
        if obj.name == "Test Plant" and obj.modelId == "rbxassetid://test_plant_model" and obj.themeApplied == "calm" then
            plantedObjectFound = true
            assert(obj.properties and obj.properties.isInteractable == true, "TestPlantObject: Planted object should be interactable.")
            break
        end
    end
    assert(plantedObjectFound, "TestPlantObject: The new plant was not found or its properties are incorrect.")
    print("Test Case Passed: PlantObject - Object added successfully.")

    -- Test planting with "stressed" emotion
    local landscapeForStressedPlant = LandscapeGenerator.generateLandscape("neutral", "testUser2")
    local stressedLandscape = UserInteraction.plantObject(
        landscapeForStressedPlant,
        "Sensitive Flower",
        "rbxassetid://sensitive_flower_model",
        Vector3.new(12,0,12),
        "stressed"
    )
    local stressedPlantFound = false
    for _, obj in pairs(stressedLandscape.objects) do
        if obj.name == "Sensitive Flower (Stressed)" and obj.themeApplied == "stressed" then
            stressedPlantFound = true
            break
        end
    end
    assert(stressedPlantFound, "TestPlantObject: Stressed plant name or themeApplied property incorrect.")
    print("Test Case Passed: PlantObject - Stressed plant has modified name.")
end

local function testChangeWeather()
    print("Starting Test: ChangeWeather")
    local initialLandscape = LandscapeGenerator.generateLandscape("calm", "testUser")

    local newWeatherType: Types.WeatherEffect["type"] = "rain"
    local newIntensity = 0.8

    local modifiedLandscape = UserInteraction.changeWeather(initialLandscape, newWeatherType, newIntensity)

    assert(modifiedLandscape.weather.type == newWeatherType, "TestChangeWeather: Weather type not updated. Expected " .. newWeatherType .. ", got " .. modifiedLandscape.weather.type)
    assert(modifiedLandscape.weather.intensity == newIntensity, "TestChangeWeather: Weather intensity not updated. Expected " .. tostring(newIntensity) .. ", got " .. tostring(modifiedLandscape.weather.intensity))
    print("Test Case Passed: ChangeWeather - Weather updated successfully.")
end

local function testModifyObjectProperty()
    print("Starting Test: ModifyObjectProperty")
    local initialLandscape = LandscapeGenerator.generateLandscape("neutral", "testUser")
    -- Add a known object to modify
    local objectToModifyId = "rock1" -- This ID comes from LandscapeGenerator's neutral preset
    if not initialLandscape.objects[objectToModifyId] then
        -- If rock1 isn't guaranteed, plant one for the test
        initialLandscape = UserInteraction.plantObject(initialLandscape, "ModifiableRock", "rock_model", Vector3.new(1,1,1), "neutral")
        for id, obj in pairs(initialLandscape.objects) do
            if obj.name == "ModifiableRock" then objectToModifyId = id break end
        end
    end
    
    assert(initialLandscape.objects[objectToModifyId] ~= nil, "Pre-condition failed: Object to modify not found.")
    if not initialLandscape.objects[objectToModifyId].properties then
        initialLandscape.objects[objectToModifyId].properties = { isInteractable = false } -- Ensure properties table exists
    end

    -- Test 1: Modify an existing property in 'properties'
    local modifiedLandscape = UserInteraction.modifyObjectProperty(initialLandscape, objectToModifyId, "isInteractable", true)
    assert(modifiedLandscape.objects[objectToModifyId].properties and modifiedLandscape.objects[objectToModifyId].properties.isInteractable == true,
        "TestModifyObjectProperty: 'isInteractable' property not modified correctly.")
    print("Test Case Passed: ModifyObjectProperty - Existing property in 'properties' modified.")

    -- Test 2: Modify a top-level property (e.g., 'name')
    local originalName = modifiedLandscape.objects[objectToModifyId].name
    modifiedLandscape = UserInteraction.modifyObjectProperty(modifiedLandscape, objectToModifyId, "name", "Renamed Rock")
    assert(modifiedLandscape.objects[objectToModifyId].name == "Renamed Rock",
        "TestModifyObjectProperty: 'name' property not modified correctly.")
    print("Test Case Passed: ModifyObjectProperty - Top-level 'name' property modified.")
    -- Restore original name for subsequent tests if any relied on it (not in this case)
    modifiedLandscape.objects[objectToModifyId].name = originalName


    -- Test 3: Attempt to modify a non-existent property
    local currentObjectCount = countObjects(modifiedLandscape.objects)
    local landscapeAfterNonExistentProp = UserInteraction.modifyObjectProperty(modifiedLandscape, objectToModifyId, "nonExistentProperty", "testValue")
    assert(countObjects(landscapeAfterNonExistentProp.objects) == currentObjectCount, "TestModifyObjectProperty: Object count changed on non-existent property modification.")
    -- Check if the object itself is unchanged (or specific property is not added)
    assert(landscapeAfterNonExistentProp.objects[objectToModifyId].properties and landscapeAfterNonExistentProp.objects[objectToModifyId].properties.nonExistentProperty == nil,
        "TestModifyObjectProperty: Non-existent property was added.")
    print("Test Case Passed: ModifyObjectProperty - Non-existent property handled gracefully.")

    -- Test 4: Attempt to modify a non-existent object
    local landscapeAfterNonExistentObject = UserInteraction.modifyObjectProperty(landscapeAfterNonExistentProp, "nonExistentObjectId", "name", "New Name")
    assert(countObjects(landscapeAfterNonExistentObject.objects) == currentObjectCount, "TestModifyObjectProperty: Object count changed on non-existent object modification.")
    print("Test Case Passed: ModifyObjectProperty - Non-existent object handled gracefully.")
end

local function testHandleInteractionEvent()
    print("Starting Test: HandleInteractionEvent")
    local initialLandscape = LandscapeGenerator.generateLandscape("neutral", "testUserEvent")
    local initialObjectCount = countObjects(initialLandscape.objects)

    -- Test 1: USER_PLANTED_OBJECT event
    local plantEventParams = {
        objectName = "EventPlant",
        modelId = "rbxassetid://event_plant_model",
        position = Vector3.new(5, 0, 5),
        emotion = "excited",
    }
    local landscapeAfterPlantEvent = UserInteraction.handleInteractionEvent("USER_PLANTED_OBJECT", initialLandscape, plantEventParams)
    assert(countObjects(landscapeAfterPlantEvent.objects) == initialObjectCount + 1,
        "TestHandleEvent (Plant): Object count did not increase.")
    local plantedEventObjectFound = false
    for _, obj in pairs(landscapeAfterPlantEvent.objects) do
        if obj.name == "EventPlant" and obj.themeApplied == "excited" then
            plantedEventObjectFound = true
            break
        end
    end
    assert(plantedEventObjectFound, "TestHandleEvent (Plant): Event-planted object not found or incorrect.")
    print("Test Case Passed: HandleInteractionEvent - USER_PLANTED_OBJECT.")

    -- Test 2: USER_CHANGED_WEATHER event
    local weatherEventParams = { weatherType = "snow" :: Types.WeatherEffect["type"], intensity = 0.9 }
    local landscapeAfterWeatherEvent = UserInteraction.handleInteractionEvent("USER_CHANGED_WEATHER", landscapeAfterPlantEvent, weatherEventParams)
    assert(landscapeAfterWeatherEvent.weather.type == "snow", "TestHandleEvent (Weather): Weather type not changed.")
    assert(landscapeAfterWeatherEvent.weather.intensity == 0.9, "TestHandleEvent (Weather): Weather intensity not changed.")
    print("Test Case Passed: HandleInteractionEvent - USER_CHANGED_WEATHER.")

    -- Test 3: USER_MODIFIED_OBJECT_PROPERTY event
    local targetObjectId = "" -- Find the ID of the "EventPlant"
    for id, obj in pairs(landscapeAfterWeatherEvent.objects) do
        if obj.name == "EventPlant" then
            targetObjectId = id
            break
        end
    end
    assert(targetObjectId ~= "", "Pre-condition for Modify Event failed: Could not find EventPlant.")
    
    local modifyEventParams = { objectId = targetObjectId, propertyName = "name", propertyValue = "Super Event Plant" }
    local landscapeAfterModifyEvent = UserInteraction.handleInteractionEvent("USER_MODIFIED_OBJECT_PROPERTY", landscapeAfterWeatherEvent, modifyEventParams)
    assert(landscapeAfterModifyEvent.objects[targetObjectId] and landscapeAfterModifyEvent.objects[targetObjectId].name == "Super Event Plant",
        "TestHandleEvent (Modify): Object name not modified via event.")
    print("Test Case Passed: HandleInteractionEvent - USER_MODIFIED_OBJECT_PROPERTY.")

    -- Test 4: Unknown event
    local landscapeAfterUnknownEvent = UserInteraction.handleInteractionEvent("UNKNOWN_EVENT", landscapeAfterModifyEvent, {})
    -- State should ideally be unchanged. Simple check: object count and weather.
    assert(countObjects(landscapeAfterUnknownEvent.objects) == countObjects(landscapeAfterModifyEvent.objects), "TestHandleEvent (Unknown): Object count changed.")
    assert(landscapeAfterUnknownEvent.weather.type == landscapeAfterModifyEvent.weather.type, "TestHandleEvent (Unknown): Weather changed.")
    print("Test Case Passed: HandleInteractionEvent - Unknown event handled gracefully.")
end


-- Run tests
print("Starting UserInteraction tests...")

testPlantObject()
testChangeWeather()
testModifyObjectProperty()
testHandleInteractionEvent()

print("All UserInteraction tests executed.")
