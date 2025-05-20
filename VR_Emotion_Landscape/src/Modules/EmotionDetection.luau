--!strict

-- src/Modules/EmotionDetection.luau
-- This module is responsible for classifying user emotions based on
-- simulated biometric data and providing functions to generate this
-- simulated data based on predefined mood strings.

local Types = require(script.Parent.Parent.src.Types)
local Logger = require(script.Parent.Parent.src.Modules.Logger)

local EmotionDetection = {}

--[[
    Classifies an emotion based on biometric data.
    The logic is a simplified model:
    - "excited": High heart rate and high skin conductance.
    - "calm": Low heart rate and low skin conductance.
    - "neutral": Moderate heart rate and skin conductance.
    - "stressed": Other combinations (default if no specific match).
    @param data: A BiometricData table containing heartRate and skinConductance.
    @return Types.Emotion: The classified emotion string.
--]]
function EmotionDetection.classifyEmotion(data: Types.BiometricData): Types.Emotion
    if data.heartRate > 100 and data.skinConductance > 0.5 then
        return "excited"
    elseif data.heartRate < 60 and data.skinConductance < 0.2 then
        return "calm"
    elseif data.heartRate >= 60 and data.heartRate <= 100 and data.skinConductance >= 0.2 and data.skinConductance <= 0.5 then
        return "neutral"
    else
        return "stressed"
    end
end

--[[
    Generates simulated biometric data for a given mood.
    This function provides predefined BiometricData values for different
    mood strings, which can then be used by `classifyEmotion`.
    An error is logged and thrown if an unknown mood is provided.
    @param mood: A string representing the desired mood (e.g., "excited", "calm").
    @return Types.BiometricData: A table with simulated heartRate and skinConductance.
--]]
function EmotionDetection.getSimulatedBiometricData(mood: string): Types.BiometricData
    if mood == "excited" then
        return { heartRate = 120, skinConductance = 0.7 }
    elseif mood == "calm" then
        return { heartRate = 50, skinConductance = 0.1 }
    elseif mood == "neutral" then
        return { heartRate = 70, skinConductance = 0.3 }
    elseif mood == "stressed" then
        return { heartRate = 90, skinConductance = 0.6 } -- This might be classified as "excited" by classifyEmotion
        -- Adjusted stressed biometric data to not overlap with "excited" based on classifyEmotion logic.
        -- classifyEmotion: excited if heartRate > 100 and skinConductance > 0.5
        -- So, for "stressed", let's ensure it doesn't meet this.
        -- return { heartRate = 90, skinConductance = 0.6 } is fine.
        -- Let's refine the "stressed" case for getSimulatedBiometricData to be distinct.
        -- Stressed: heartRate = 90 (not >100), skinConductance = 0.6 (is >0.5, but HR condition not met for excited)
        -- This will be classified as "stressed" by the current logic.
    else
        -- It's good practice to handle unknown moods, either by erroring or returning a default.
        -- For now, let's error. In a real game, you might want a more graceful fallback.
        Logger.error("Unknown mood provided to getSimulatedBiometricData: " .. mood)
        error("Unknown mood provided to getSimulatedBiometricData: " .. mood)
    end
    -- Fallback, though the 'else error' should prevent reaching here with an unknown mood.
    -- To satisfy the type checker if it can't infer the error stops execution for all paths.
    return { heartRate = -1, skinConductance = -1} -- Should not be reached if mood is valid
end

return EmotionDetection
