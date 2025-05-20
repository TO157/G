--!strict

-- src/Modules/LandscapeGenerator.luau
-- This module is responsible for generating the entire landscape state based on a given emotion.
-- It defines different themes (collections of visual and auditory properties) and
-- populates the landscape with appropriate objects and weather conditions that reflect
-- the specified emotion.

local Types = require(script.Parent.Parent.src.Types)
local Logger = require(script.Parent.Parent.src.Modules.Logger)

local LandscapeGenerator = {}

-- Define LandscapeTheme constants
-- These themes provide the base aesthetic for a landscape tied to an emotion.
local THEMES: { [Types.Emotion]: Types.LandscapeTheme } = {
    calm = {
        name = "Serene Beach",
        skyColor = Color3.new(0.5, 0.7, 1.0), -- Assuming Color3.new() global
        groundTexture = "rbxassetid://sand_texture_id", -- Placeholder asset ID
        ambientSound = "rbxassetid://ocean_waves_sound_id", -- Placeholder asset ID
    },
    excited = {
        name = "Vibrant Forest",
        skyColor = Color3.new(0.2, 0.8, 0.2),
        groundTexture = "rbxassetid://forest_floor_texture_id",
        ambientSound = "rbxassetid://forest_ambience_sound_id",
    },
    neutral = {
        name = "Quiet Meadow",
        skyColor = Color3.new(0.6, 0.6, 0.6),
        groundTexture = "rbxassetid://grass_texture_id",
        ambientSound = "rbxassetid://meadow_sounds_id",
    },
    stressed = {
        name = "Stormy Highlands",
        skyColor = Color3.new(0.3, 0.3, 0.4),
        groundTexture = "rbxassetid://rocky_ground_texture_id",
        ambientSound = "rbxassetid://wind_howling_sound_id",
    },
}

local DEFAULT_WEATHER: { [Types.Emotion]: Types.WeatherEffect } = {
    calm = { type = "sunshine", intensity = 0.8 },
    excited = { type = "sunshine", intensity = 1.0 },
    neutral = { type = "sunshine", intensity = 0.5 },
    stressed = { type = "rain", intensity = 0.3 },
}

--[[
    Creates a basic landscape object with common properties.
    This is a utility function used by more specific object creators.
    @param id: Unique identifier for the object.
    @param name: Display name of the object.
    @param modelId: Asset ID for the object's visual model.
    @param position: A Vector3 table representing the object's position.
    @param emotionTheme: The emotion that this object's theme is tied to.
    @param isInteractable: Boolean indicating if the object can be interacted with.
    @param interactionType: Optional string defining the type of interaction.
    @return Types.LandscapeObject: The created landscape object.
--]]
function LandscapeGenerator.createBasicObject(
    id: string,
    name: string,
    modelId: string,
    position: Vector3, -- Assuming Vector3.new() global
    emotionTheme: Types.Emotion,
    isInteractable: boolean,
    interactionType: string?
): Types.LandscapeObject
    return {
        id = id,
        name = name,
        position = position,
        modelId = modelId,
        themeApplied = emotionTheme,
        properties = {
            isInteractable = isInteractable,
            interactionType = interactionType,
        },
    }
end

-- Example of a theme-specific object creation helper
function LandscapeGenerator.createPalmTree(id: string, position: Vector3): Types.TreeObject
    local baseObject = LandscapeGenerator.createBasicObject(
        id,
        "Palm Tree",
        "rbxassetid://palm_tree_model_id", -- Placeholder
        position,
        "calm",
        true,
        "observe"
    )
    -- Add TreeObject specific properties
    local treeObject: Types.TreeObject = table.clone(baseObject) -- Shallow clone, be careful with nested tables if any
    treeObject.species = "Cocos Nucifera"
    treeObject.growthStage = 3 -- Mature
    return treeObject
end

--[[
    Creates a 'Giant Glowing Mushroom' object, themed for "excited" emotion.
    @param id: Unique identifier for the mushroom.
    @param position: A Vector3 table for its position.
    @return Types.LandscapeObject: The created mushroom object.
--]]
function LandscapeGenerator.createGlowingMushroom(id: string, position: Vector3): Types.LandscapeObject
    return LandscapeGenerator.createBasicObject(
        id,
        "Giant Glowing Mushroom",
        "rbxassetid://glowing_mushroom_model_id", -- Placeholder
        position,
        "excited",
        true,
        "touch_toggle_light"
    )
end

--[[
    Creates a 'Relaxation Stone' object, themed for "calm" emotion.
    @param id: Unique identifier for the stone.
    @param position: A Vector3 table for its position.
    @return Types.LandscapeObject: The created stone object.
--]]
function LandscapeGenerator.createRelaxationStone(id: string, position: Vector3): Types.LandscapeObject
    return LandscapeGenerator.createBasicObject(
        id,
        "Relaxation Stone",
        "rbxassetid://smooth_stone_model_id", -- Placeholder
        position,
        "calm",
        true,
        "sit"
    )
end

--[[
    Creates a 'Sparkling Energy Orb' object, themed for "excited" emotion. Non-interactable.
    @param id: Unique identifier for the orb.
    @param position: A Vector3 table for its position.
    @return Types.LandscapeObject: The created orb object.
--]]
function LandscapeGenerator.createSparklingEnergyOrb(id: string, position: Vector3): Types.LandscapeObject
    return LandscapeGenerator.createBasicObject(
        id,
        "Sparkling Energy Orb",
        "rbxassetid://energy_orb_model_id", -- Placeholder
        position,
        "excited",
        false
    )
end

--[[
    Creates a 'Neutral Rock Formation' object, themed for "neutral" emotion. Non-interactable.
    @param id: Unique identifier for the rock formation.
    @param position: A Vector3 table for its position.
    @return Types.LandscapeObject: The created rock object.
--]]
function LandscapeGenerator.createNeutralRock(id: string, position: Vector3): Types.LandscapeObject
    return LandscapeGenerator.createBasicObject(
        id,
        "Neutral Rock Formation",
        "rbxassetid://neutral_rock_model_id", -- Placeholder
        position,
        "neutral",
        false
    )
end

--[[
    Creates a 'Wilting Plant' object, themed for "stressed" emotion.
    @param id: Unique identifier for the plant.
    @param position: A Vector3 table for its position.
    @return Types.LandscapeObject: The created plant object.
--]]
function LandscapeGenerator.createWiltingPlant(id: string, position: Vector3): Types.LandscapeObject
    return LandscapeGenerator.createBasicObject(
        id,
        "Wilting Plant",
        "rbxassetid://wilting_plant_model_id", -- Placeholder
        position,
        "stressed",
        true,
        "water"
    )
end


--[[
    Generates a complete landscape state based on the given emotion and user ID.
    It selects an appropriate theme, populates objects specific to that theme,
    and sets the initial weather. If a theme for the given emotion is not found,
    it defaults to the "neutral" theme.
    @param emotion: The Types.Emotion to base the landscape on.
    @param userId: The ID of the user for whom the landscape is being generated.
    @return Types.LandscapeState: The newly generated landscape state.
--]]
function LandscapeGenerator.generateLandscape(emotion: Types.Emotion, userId: string): Types.LandscapeState
    Logger.info(string.format("Generating landscape for user '%s' with emotion '%s'.", userId, emotion))
    local theme = THEMES[emotion]
    if not theme then
        -- Fallback to neutral if emotion has no defined theme (should not happen with current setup)
        Logger.warn(string.format("No theme defined for emotion '%s'. Defaulting to 'neutral'.", emotion))
        theme = THEMES["neutral"]
        emotion = "neutral" -- Ensure currentEmotion reflects the actual theme applied
    end

    local objects: { [string]: Types.LandscapeObject } = {}
    local weather = DEFAULT_WEATHER[emotion] or DEFAULT_WEATHER["neutral"]

    -- Populate objects based on the theme
    if emotion == "calm" then
        objects["palm1"] = LandscapeGenerator.createPalmTree("palm1", Vector3.new(5, 0, 5))
        objects["stone1"] = LandscapeGenerator.createRelaxationStone("stone1", Vector3.new(-3, 0, 2))
    elseif emotion == "excited" then
        objects["mushroom1"] = LandscapeGenerator.createGlowingMushroom("mushroom1", Vector3.new(2, 0, -4))
        objects["orb1"] = LandscapeGenerator.createSparklingEnergyOrb("orb1", Vector3.new(-5, 1, -5))
    elseif emotion == "neutral" then
        objects["rock1"] = LandscapeGenerator.createNeutralRock("rock1", Vector3.new(0, 0, 0))
    elseif emotion == "stressed" then
        objects["plant1"] = LandscapeGenerator.createWiltingPlant("plant1", Vector3.new(1, 0, 1))
        -- Add another object for stressed to ensure tests can check for "at least one object" robustly
        objects["rock_stressed"] = LandscapeGenerator.createBasicObject("rock_stressed", "Jagged Rock", "rbxassetid://jagged_rock_id", Vector3.new(-4,0,3), "stressed", false, nil)

    end

    local landscapeState: Types.LandscapeState = {
        userId = userId,
        currentEmotion = emotion,
        activeTheme = theme,
        objects = objects,
        weather = weather,
    }

    return landscapeState
end

return LandscapeGenerator
