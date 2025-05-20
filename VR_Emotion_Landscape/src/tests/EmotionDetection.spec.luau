--!strict

-- src/tests/EmotionDetection.spec.luau

-- Adjust the path based on your project structure and how you run tests.
-- This assumes the test runner or environment can resolve this path.
-- If running from the root, 'src.Types' might be needed, or relative paths from the test file location.
local Types = require(script.Parent.Parent.src.Types)
local EmotionDetection = require(script.Parent.Parent.src.Modules.EmotionDetection)

local function testClassifyCalm()
    local data: Types.BiometricData = { heartRate = 50, skinConductance = 0.1 }
    local emotion = EmotionDetection.classifyEmotion(data)
    assert(emotion == "calm", "Test Case Failed: Classify Calm - Expected calm, got " .. emotion)
    print("Test Case Passed: Classify Calm")
end

local function testClassifyExcited()
    local data: Types.BiometricData = { heartRate = 120, skinConductance = 0.7 }
    local emotion = EmotionDetection.classifyEmotion(data)
    assert(emotion == "excited", "Test Case Failed: Classify Excited - Expected excited, got " .. emotion)
    print("Test Case Passed: Classify Excited")
end

local function testClassifyNeutral()
    local data: Types.BiometricData = { heartRate = 70, skinConductance = 0.3 }
    local emotion = EmotionDetection.classifyEmotion(data)
    assert(emotion == "neutral", "Test Case Failed: Classify Neutral - Expected neutral, got " .. emotion)
    print("Test Case Passed: Classify Neutral")
end

local function testClassifyStressed()
    -- Example 1: Higher heart rate but not meeting "excited" skin conductance
    local data1: Types.BiometricData = { heartRate = 110, skinConductance = 0.4 }
    local emotion1 = EmotionDetection.classifyEmotion(data1)
    assert(emotion1 == "stressed", "Test Case Failed: Classify Stressed (HR high, SC normal) - Expected stressed, got " .. emotion1)
    print("Test Case Passed: Classify Stressed (HR high, SC normal)")

    -- Example 2: Skin conductance high, but not meeting "excited" heart rate
    local data2: Types.BiometricData = { heartRate = 90, skinConductance = 0.6 }
    local emotion2 = EmotionDetection.classifyEmotion(data2)
    assert(emotion2 == "stressed", "Test Case Failed: Classify Stressed (HR normal, SC high) - Expected stressed, got " .. emotion2)
    print("Test Case Passed: Classify Stressed (HR normal, SC high)")
    
    -- Example 3: Data that falls into the "stressed" category by not matching others
    local data3: Types.BiometricData = { heartRate = 80, skinConductance = 0.8 } -- Doesn't fit calm, excited, or neutral
    local emotion3 = EmotionDetection.classifyEmotion(data3)
    assert(emotion3 == "stressed", "Test Case Failed: Classify Stressed (General) - Expected stressed, got " .. emotion3)
    print("Test Case Passed: Classify Stressed (General)")
end

local function testGetSimulatedDataCalm()
    local data = EmotionDetection.getSimulatedBiometricData("calm")
    assert(data.heartRate == 50 and data.skinConductance == 0.1, "Test Case Failed: Get Simulated Calm Data")
    print("Test Case Passed: Get Simulated Calm Data")
end

local function testGetSimulatedDataExcited()
    local data = EmotionDetection.getSimulatedBiometricData("excited")
    assert(data.heartRate == 120 and data.skinConductance == 0.7, "Test Case Failed: Get Simulated Excited Data")
    print("Test Case Passed: Get Simulated Excited Data")
end

local function testGetSimulatedDataNeutral()
    local data = EmotionDetection.getSimulatedBiometricData("neutral")
    assert(data.heartRate == 70 and data.skinConductance == 0.3, "Test Case Failed: Get Simulated Neutral Data")
    print("Test Case Passed: Get Simulated Neutral Data")
end

local function testGetSimulatedDataStressed()
    local data = EmotionDetection.getSimulatedBiometricData("stressed")
    assert(data.heartRate == 90 and data.skinConductance == 0.6, "Test Case Failed: Get Simulated Stressed Data")
    print("Test Case Passed: Get Simulated Stressed Data")
end

local function testGetSimulatedDataUnknown()
    local success, err = pcall(function()
        EmotionDetection.getSimulatedBiometricData("unknown_mood")
    end)
    assert(not success, "Test Case Failed: Get Simulated Unknown Data - Expected error, but function succeeded.")
    if err then
        print("Test Case Passed: Get Simulated Unknown Data (Error message: " .. tostring(err) .. ")")
    else
        print("Test Case Passed: Get Simulated Unknown Data (Error as expected)")
    end
end


-- Run tests
testClassifyCalm()
testClassifyExcited()
testClassifyNeutral()
testClassifyStressed()

testGetSimulatedDataCalm()
testGetSimulatedDataExcited()
testGetSimulatedDataNeutral()
testGetSimulatedDataStressed()
testGetSimulatedDataUnknown()

print("All EmotionDetection tests executed.")
