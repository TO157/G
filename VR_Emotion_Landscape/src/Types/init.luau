--!strict

-- src/Types/init.luau

export type BiometricData = {
    heartRate: number,
    skinConductance: number, -- Example biometric data points
    -- Add more data points as needed, e.g., temperature: number
}

export type Emotion = "calm" | "excited" | "stressed" | "neutral" -- Added neutral as a baseline

export type LandscapeTheme = {
    name: string,
    skyColor: Color3,
    groundTexture: string,
    ambientSound: string,
    -- Add other theme-specific properties
}

export type LandscapeObjectProperty = {
    isInteractable: boolean,
    interactionType: string?, -- e.g., "plant", "modify", "observe"
}

export type LandscapeObject = {
    id: string,
    name: string,
    position: Vector3,
    modelId: string, -- Asset ID for the visual model
    themeApplied: Emotion, -- Which emotion generated this object or its area
    properties: LandscapeObjectProperty?,
}

-- Example: A specific type of landscape object
export type TreeObject = LandscapeObject & {
    species: string,
    growthStage: number,
}

-- Example: Weather data
export type WeatherEffect = {
    type: "rain" | "sunshine" | "wind" | "snow",
    intensity: number, -- 0 to 1
}

export type LandscapeState = {
    userId: string,
    currentEmotion: Emotion,
    activeTheme: LandscapeTheme,
    objects: { [string]: LandscapeObject }, -- Dictionary of objects by ID
    weather: WeatherEffect,
}

export type PlayerState = {
    userId: string,
    currentEmotion: Emotion,
    lastInteractionTime: number,
}

-- For Color3 and Vector3, we'll assume they are provided by the VR environment.
-- If not, basic definitions can be added:
-- export type Color3 = { r: number, g: number, b: number }
-- export type Vector3 = { x: number, y: number, z: number }

return {} -- Return an empty table as is common for type modules
