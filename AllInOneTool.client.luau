--[[
    AllInOneTool.client.luau
    Client-side script for the AllInOneTool.
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui") -- Ensure CoreGui is available

-- Player
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remote Events (ensure names match server script)
local createObjectEvent = ReplicatedStorage:WaitForChild("AIO_CreateObjectEvent")
local deleteObjectEvent = ReplicatedStorage:WaitForChild("AIO_DeleteObjectEvent")
local clientFeedbackEvent = ReplicatedStorage:WaitForChild("AIO_ClientFeedbackEvent")
local updatePropertyEvent = ReplicatedStorage:WaitForChild("AIO_UpdatePropertyEvent")
local csgOperationEvent = ReplicatedStorage:WaitForChild("AIO_CSGOperationEvent")
local updateEnvironmentEvent = ReplicatedStorage:WaitForChild("AIO_UpdateEnvironmentEvent")
local requestEnvironmentSyncEvent = ReplicatedStorage:WaitForChild("AIO_RequestEnvironmentSyncEvent")
local syncEnvironmentEvent = ReplicatedStorage:WaitForChild("AIO_SyncEnvironmentEvent")
local advancedSelectEvent = ReplicatedStorage:WaitForChild("AIO_AdvancedSelectEvent")
local alignmentEvent = ReplicatedStorage:WaitForChild("AIO_AlignmentEvent")
local terrainInspectEvent = ReplicatedStorage:WaitForChild("AIO_TerrainInspectEvent")
local terrainModifyEvent = ReplicatedStorage:WaitForChild("AIO_TerrainModifyEvent")

-- Selected Object
local selectedObject = nil
local selectionBox = nil

-- UI Elements Storage
local uiElements = {}
uiElements.panels = {} -- To store references to different feature panels

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AllInOneToolGUIs"
screenGui.ResetOnSpawn = false -- Keep UI persistent
screenGui.Parent = playerGui

-- Helper function to create UI elements
local function createElement(elementType, properties)
    local element = Instance.new(elementType)
    for prop, value in pairs(properties) do
        element[prop] = value
    end
    return element
end

-- Main Toggle Button
uiElements.mainToggleButton = createElement("TextButton", {
    Name = "MainToggleButton",
    Text = "AIO",
    Size = UDim2.new(0, 60, 0, 30),
    Position = UDim2.new(0, 10, 0, 10), -- Top-left corner
    BackgroundColor3 = Color3.fromRGB(70, 70, 180),
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Parent = screenGui
})

-- Main Panel (initially hidden)
uiElements.mainPanel = createElement("Frame", {
    Name = "MainPanel",
    Size = UDim2.new(0, 300, 0, 400),
    Position = UDim2.new(0.5, -150, 0.5, -200), -- Centered
    BackgroundColor3 = Color3.fromRGB(50, 50, 50),
    BorderSizePixel = 2,
    BorderColor3 = Color3.fromRGB(20, 20, 20),
    Visible = false,
    Active = true, -- Allows dragging
    Draggable = true,
    Parent = screenGui
})

-- Title Label for Main Panel
local titleLabel = createElement("TextLabel", {
    Name = "TitleLabel",
    Text = "All-In-One Tool",
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.SourceSansBold,
    TextSize = 18,
    Parent = uiElements.mainPanel
})

-- Close button for Main Panel
local closeButton = createElement("TextButton", {
    Name = "CloseButton",
    Text = "X",
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -30, 0, 0),
    BackgroundColor3 = Color3.fromRGB(200, 50, 50),
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.SourceSansBold,
    TextSize = 18,
    Parent = titleLabel -- Parent to titleLabel to keep it on top right
})

closeButton.MouseButton1Click:Connect(function()
    uiElements.mainPanel.Visible = false
end)


-- Feedback Label
uiElements.feedbackLabel = createElement("TextLabel", {
    Name = "FeedbackLabel",
    Text = "Welcome to the All-In-One Tool!",
    Size = UDim2.new(1, -10, 0, 20), -- Slightly smaller than panel width
    Position = UDim2.new(0, 5, 1, -25), -- Bottom of the main panel
    BackgroundColor3 = Color3.fromRGB(60, 60, 60),
    TextColor3 = Color3.fromRGB(200, 200, 200),
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = uiElements.mainPanel
})

local function showFeedback(message, isError)
    uiElements.feedbackLabel.Text = message
    if isError then
        uiElements.feedbackLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    else
        uiElements.feedbackLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    end
    -- Optional: clear feedback after a few seconds
    delay(5, function()
        if uiElements.feedbackLabel.Text == message then -- Only clear if it hasn't been replaced
            uiElements.feedbackLabel.Text = ""
            uiElements.feedbackLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end)
end

clientFeedbackEvent.OnClientEvent:Connect(function(message, isError)
    showFeedback(message, isError)
end)

-- Toggle Main Panel Visibility
uiElements.mainToggleButton.MouseButton1Click:Connect(function()
    uiElements.mainPanel.Visible = not uiElements.mainPanel.Visible
    if uiElements.mainPanel.Visible then
        -- Bring to front if it was made visible
        uiElements.mainPanel.ZIndex = (uiElements.mainPanel.ZIndex + 1)
        -- Potentially request environment sync when opening
        -- requestEnvironmentSyncEvent:FireServer() 
        showFeedback("Main panel opened.", false)
    else
        showFeedback("Main panel closed.", false)
    end
end)

-- Function to create a standard toggle button for feature panels
local function createFeatureToggleButton(name, text, order, parentPanel)
    local button = createElement("TextButton", {
        Name = name .. "ToggleButton",
        Text = text,
        Size = UDim2.new(0.9, 0, 0, 30), -- Relative width, fixed height
        Position = UDim2.new(0.05, 0, 0, 40 + (order * 35)), -- Stack them below title
        BackgroundColor3 = Color3.fromRGB(80, 80, 150),
        TextColor3 = Color3.fromRGB(220, 220, 255),
        Parent = parentPanel
    })
    return button
end

-- Function to create a standard feature panel
local function createFeaturePanel(name, parentPanel)
    local panel = createElement("Frame", {
        Name = name .. "Panel",
        Size = UDim2.new(1, -10, 0.8, -45), -- Relative to main panel, adjust as needed
        Position = UDim2.new(0, 5, 0.2, 40), -- Positioned below buttons, adjust as needed
        BackgroundColor3 = Color3.fromRGB(55, 55, 55),
        BorderSizePixel = 1,
        BorderColor3 = Color3.fromRGB(25, 25, 25),
        Visible = false, -- Initially hidden
        Parent = parentPanel,
        ClipsDescendants = true, -- Important for scrolling frames
    })
    uiElements.panels[name] = panel -- Store reference
    return panel
end

-- Helper to toggle visibility of feature panels
local function toggleFeaturePanel(panelName)
    for name, pnl in pairs(uiElements.panels) do
        if name == panelName then
            pnl.Visible = not pnl.Visible
            if pnl.Visible then showFeedback(panelName .. " panel opened.", false) else showFeedback(panelName .. " panel closed.", false) end
        else
            pnl.Visible = false -- Hide other panels
        end
    end
end

---------------------------------------------------------------------------------
-- Feature Sections Initialization (Stubs for now)
---------------------------------------------------------------------------------

-- 1. Object Creation & Management
local function initObjectCreation()
    local toggleBtn = createFeatureToggleButton("ObjectCreation", "Create/Manage", 0, uiElements.mainPanel)
    local panel = createFeaturePanel("ObjectCreation", uiElements.mainPanel)
    toggleBtn.MouseButton1Click:Connect(function() toggleFeaturePanel("ObjectCreation") end)
    showFeedback("Object Creation UI stub initialized.", false)
    
    -- TODO: Add ClassName input, create button, selection info, delete, duplicate buttons
    -- Example:
    -- local classNameInput = createElement("TextBox", {... Parent = panel})
    -- local createBtn = createElement("TextButton", {Text = "Create", ... Parent = panel})
    -- createBtn.MouseButton1Click:Connect(function() ... createObjectEvent:FireServer(...) ... end)
end

-- 2. Property Display & Custom Properties
local function initPropertySystem()
    local toggleBtn = createFeatureToggleButton("PropertyEditor", "Property Editor", 1, uiElements.mainPanel)
    local panel = createFeaturePanel("PropertyEditor", uiElements.mainPanel)
    toggleBtn.MouseButton1Click:Connect(function() toggleFeaturePanel("PropertyEditor") end)
    showFeedback("Property System UI stub initialized.", false)

    -- TODO: Add property scroll frame, list layout, custom prop inputs, add button
    -- TODO: Implement updatePropertyDisplay, handlePropertyUpdate
end

-- 3. JSON Import/Export for Custom Properties
local function initCustomPropsJSON()
    -- This might be part of the PropertyEditor panel or its own
    showFeedback("Custom Props JSON UI stub initialized.", false)
    -- TODO: Add TextBox, Import/Export buttons for objectCustomPropertiesMap
end

-- 4. Environment Settings
local function initEnvironmentSettings()
    local toggleBtn = createFeatureToggleButton("Environment", "Environment", 2, uiElements.mainPanel)
    local panel = createFeaturePanel("Environment", uiElements.mainPanel)
    toggleBtn.MouseButton1Click:Connect(function() 
        toggleFeaturePanel("Environment") 
        if panel.Visible then requestEnvironmentSyncEvent:FireServer() end
    end)
    showFeedback("Environment Settings UI stub initialized.", false)

    -- TODO: Add UI rows for Lighting, Atmosphere, Sky properties
    -- TODO: Add JSON import/export for presets
end

-- 5. Theming Tool
local function initThemingTool()
    local toggleBtn = createFeatureToggleButton("Theming", "Theming", 3, uiElements.mainPanel)
    local panel = createFeaturePanel("Theming", uiElements.mainPanel)
    toggleBtn.MouseButton1Click:Connect(function() toggleFeaturePanel("Theming") end)
    showFeedback("Theming Tool UI stub initialized.", false)

    -- TODO: Add UI for theme definition, management, and application
end

-- 6. Advanced Selection
local function initAdvancedSelection()
    local toggleBtn = createFeatureToggleButton("AdvSelection", "Adv. Select", 4, uiElements.mainPanel)
    local panel = createFeaturePanel("AdvSelection", uiElements.mainPanel)
    toggleBtn.MouseButton1Click:Connect(function() toggleFeaturePanel("AdvSelection") end)
    showFeedback("Advanced Selection UI stub initialized.", false)

    -- TODO: Add UI for selecting by Material, Color, ClassName
end

-- 7. CSG Tools
local function initCSGTools()
    local toggleBtn = createFeatureToggleButton("CSG", "CSG Tools", 5, uiElements.mainPanel)
    local panel = createFeaturePanel("CSG", uiElements.mainPanel)
    toggleBtn.MouseButton1Click:Connect(function() toggleFeaturePanel("CSG") end)
    showFeedback("CSG Tools UI stub initialized.", false)

    -- TODO: Add buttons for Union, Subtract, Intersect; selection logic
end

-- 8. Alignment Tools
local function initAlignmentTools()
    local toggleBtn = createFeatureToggleButton("Alignment", "Alignment", 6, uiElements.mainPanel)
    local panel = createFeaturePanel("Alignment", uiElements.mainPanel)
    toggleBtn.MouseButton1Click:Connect(function() toggleFeaturePanel("Alignment") end)
    showFeedback("Alignment Tools UI stub initialized.", false)

    -- TODO: Add buttons for various alignment operations
end

-- 9. Terrain Interaction Tool
local function initTerrainTool()
    local toggleBtn = createFeatureToggleButton("Terrain", "Terrain", 7, uiElements.mainPanel)
    local panel = createFeaturePanel("Terrain", uiElements.mainPanel)
    toggleBtn.MouseButton1Click:Connect(function() toggleFeaturePanel("Terrain") end)
    showFeedback("Terrain Tool UI stub initialized.", false)

    -- TODO: Add Inspect Voxel, Basic Stamp/Fill UI
end

-- 10. Session Data Import/Export
local function initSessionData()
    local toggleBtn = createFeatureToggleButton("SessionData", "Session Data", 8, uiElements.mainPanel)
    local panel = createFeaturePanel("SessionData", uiElements.mainPanel)
    toggleBtn.MouseButton1Click:Connect(function() toggleFeaturePanel("SessionData") end)
    showFeedback("Session Data UI stub initialized.", false)

    -- TODO: Add TextBox, Import/Export buttons for full session
end


---------------------------------------------------------------------------------
-- Event Handlers (Stubs for now)
---------------------------------------------------------------------------------
-- updatePropertyEvent.OnClientEvent:Connect(function(instance, property, value) ... end)
-- syncEnvironmentEvent.OnClientEvent:Connect(function(environmentData) ... end)
-- AIO_AdvancedSelectEvent (if server sends back selection confirmation/data)
-- AIO_AlignmentEvent (if server sends back status)
-- AIO_TerrainInspectEvent (if server sends back voxel info)

---------------------------------------------------------------------------------
-- Initialization Calls
---------------------------------------------------------------------------------
initObjectCreation()
initPropertySystem()
initCustomPropsJSON() -- Might be called within initPropertySystem
initEnvironmentSettings()
initThemingTool()
initAdvancedSelection()
initCSGTools()
initAlignmentTools()
initTerrainTool()
initSessionData()

showFeedback("AllInOneTool Client Initialized.", false)

-- Selection Handling (Basic Example)
local function onSelectionChanged(newSelection)
    selectedObject = newSelection
    if selectionBox then
        selectionBox.Adornee = selectedObject
        selectionBox.Visible = selectedObject ~= nil
    end
    if selectedObject then
        showFeedback("Selected: " .. selectedObject.Name, false)
        -- TODO: Call updatePropertyDisplay(selectedObject) here
    else
        showFeedback("Selection cleared.", false)
        -- TODO: Call updatePropertyDisplay(nil) or clear display
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end -- Don't interfere with game inputs

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local target = UserInputService:GetMouseLocation()
        local ray = game.Workspace.CurrentCamera:ViewportPointToRay(target.X, target.Y)
        local raycastResult = game.Workspace:Raycast(ray.Origin, ray.Direction * 1000)
        
        if raycastResult and raycastResult.Instance then
            local hitPart = raycastResult.Instance
            if hitPart:IsA("BasePart") and not hitPart:IsDescendantOf(screenGui) then -- Ensure not clicking UI
                onSelectionChanged(hitPart)
            end
        else
            onSelectionChanged(nil) -- Clicked on nothing selectable
        end
    end
end)

-- Create a SelectionBox visual
selectionBox = createElement("SelectionBox", {
    Name = "AIOSelectionBox",
    LineThickness = 0.05,
    Color3 = Color3.fromRGB(0, 255, 0), -- Bright green
    Adornee = nil, -- Will be set on selection
    Visible = false,
    Parent = CoreGui -- Or screenGui, depending on preference for layering
})

print("AllInOneTool.client.luau loaded.")

-- Initial request for environment settings when the tool loads
-- This helps sync if the panel isn't opened immediately.
-- Consider if this is always desired or only when main panel is first opened.
-- requestEnvironmentSyncEvent:FireServer()

-- End of script
print("AllInOneTool.client.luau execution finished.")
