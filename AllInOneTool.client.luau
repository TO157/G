-- Get the LocalPlayer
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

local objectCustomPropertiesMap = {} -- Added as per instruction
local selectedObject = nil -- For tracking the currently selected object

-- Create a ScreenGui instance
local screenGui = Instance.new("ScreenGui")

-- Set the Name property of the ScreenGui
screenGui.Name = "AllInOneToolGui"

-- Set the Parent property of the ScreenGui to the LocalPlayer's PlayerGui folder
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

-- Print a success message
print("AllInOneToolGui created successfully.")

-- Helper function to create UI elements
local function createElement(elementType, props)
	local element = Instance.new(elementType)
	for propName, propValue in pairs(props) do
		if propName == "Parent" and type(propValue) == "string" then
			-- Handle string parent names if needed, though direct parent instance is better
			if propValue == "screenGui" then
				element.Parent = screenGui
			else
				-- For simplicity, assuming direct parent instance is passed for others
				-- or screenGui if it's the direct parent string
				element.Parent = props.Parent 
			end
		else
			element[propName] = propValue
		end
	end
	return element
end

-- Default properties for text elements
local defaultTextProps = {
	Font = Enum.Font.SourceSans,
	TextColor3 = Color3.fromRGB(220, 220, 220)
}

local defaultTextBoxProps = {
	BackgroundColor3 = Color3.fromRGB(60, 60, 60),
	BorderColor3 = Color3.fromRGB(30, 30, 30)
}

local defaultButtonProps = {
	BackgroundColor3 = Color3.fromRGB(70, 70, 70)
}

-- 1. Main Panel
local mainPanel = createElement("Frame", {
	Name = "MainPanel",
	Parent = screenGui,
	Size = UDim2.new(0.4, 0, 0.6, 0),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Color3.fromRGB(50, 50, 50),
	BorderColor3 = Color3.fromRGB(200, 200, 200)
})

-- 2. Object Creation Section
local classNameInput = createElement("TextBox", {
	Name = "ClassNameInput",
	Parent = mainPanel,
	PlaceholderText = "Enter ClassName (e.g., Part)",
	Position = UDim2.new(0.05, 0, 0.05, 0),
	Size = UDim2.new(0.6, 0, 0.08, 0),
	Font = defaultTextProps.Font,
	TextColor3 = defaultTextProps.TextColor3,
	BackgroundColor3 = defaultTextBoxProps.BackgroundColor3,
	BorderColor3 = defaultTextBoxProps.BorderColor3
})

local createObjectButton = createElement("TextButton", {
	Name = "CreateObjectButton",
	Parent = mainPanel,
	Text = "Create",
	Position = UDim2.new(0.7, 0, 0.05, 0),
	Size = UDim2.new(0.25, 0, 0.08, 0),
	Font = defaultTextProps.Font,
	TextColor3 = defaultTextProps.TextColor3,
	BackgroundColor3 = defaultButtonProps.BackgroundColor3
})

createObjectButton.MouseButton1Click:Connect(function()
	local className = classNameInput.Text
	if className == "" then
		warn("ClassName input is empty.")
		return
	end

	local success, result = pcall(function()
		return Instance.new(className)
	end)

	if success then
		if result then
			local newInstance = result
			newInstance.Parent = game.Workspace
			objectCustomPropertiesMap[newInstance] = {}
			print("Successfully created instance of type: " .. className)
			classNameInput.Text = "" -- Clear input
		else
			-- This case should ideally not happen if pcall is true and Instance.new was called,
			-- but good to have a safeguard.
			warn("Error creating instance: pcall success but instance is nil for " .. className)
		end
	else
		warn("Error creating instance: " .. tostring(result)) -- result is error message here
	end
end)

-- 3. Selection Info
local selectedObjectLabel = createElement("TextLabel", {
	Name = "SelectedObjectLabel",
	Parent = mainPanel,
	Text = "Selected: None",
	Position = UDim2.new(0.05, 0, 0.15, 0),
	Size = UDim2.new(0.9, 0, 0.05, 0),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(240, 240, 240), -- Specified
	BackgroundTransparency = 1,
	Font = defaultTextProps.Font
})

-- 4. Property Display & Modification Section
local propertyScrollFrame = createElement("ScrollingFrame", {
	Name = "PropertyScrollFrame",
	Parent = mainPanel,
	Position = UDim2.new(0.05, 0, 0.22, 0),
	Size = UDim2.new(0.9, 0, 0.35, 0),
	CanvasSize = UDim2.new(0, 0, 2, 0),
	BackgroundColor3 = Color3.fromRGB(40, 40, 40),
	ScrollBarThickness = 6,
	-- Child UIListLayout added below
})

local propertyListLayout = createElement("UIListLayout", {
	Name = "PropertyListLayout",
	Parent = propertyScrollFrame,
	FillDirection = Enum.FillDirection.Vertical,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 5),
	HorizontalAlignment = Enum.HorizontalAlignment.Center
})

-- Forward declaration for updatePropertyDisplay
local updatePropertyDisplay
local handlePropertyUpdate -- Forward declare

-- Helper function to create a property entry in the scroll frame
local function createPropertyEntry(propertyNameString, propertyValue, propertyTypeString, layoutOrder, objectRef)
	local entryFrame = createElement("Frame", {
		Name = "PropertyEntry_" .. propertyNameString,
		Parent = propertyScrollFrame,
		Size = UDim2.new(1, -10, 0, 30),
		BackgroundTransparency = 1,
		LayoutOrder = layoutOrder
	})

	createElement("TextLabel", {
		Name = "PropertyNameLabel",
		Parent = entryFrame,
		Text = propertyNameString,
		Size = UDim2.new(0.35, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Font = defaultTextProps.Font,
		TextColor3 = Color3.fromRGB(200, 200, 200),
		TextXAlignment = Enum.TextXAlignment.Left
	})

	local valueInput = createElement("TextBox", {
		Name = "PropertyValueInput",
		Parent = entryFrame,
		Text = tostring(propertyValue),
		PlaceholderText = propertyTypeString,
		Size = UDim2.new(0.63, 0, 1, 0),
		Position = UDim2.new(0.37, 0, 0, 0),
		Font = defaultTextProps.Font,
		TextColor3 = Color3.fromRGB(240,240,240),
		BackgroundColor3 = Color3.fromRGB(80,80,80),
		BorderColor3 = Color3.fromRGB(30,30,30)
	})
	valueInput:SetAttribute("PropertyName", propertyNameString)
	valueInput:SetAttribute("PropertyType", propertyTypeString)

	valueInput.FocusLost:Connect(function(enterPressed)
		if enterPressed then -- Only update if Enter was pressed
			local currentPropertyName = valueInput:GetAttribute("PropertyName")
			local currentPropertyType = valueInput:GetAttribute("PropertyType")
			handlePropertyUpdate(objectRef, currentPropertyName, currentPropertyType, valueInput.Text, valueInput)
		else -- User clicked off, revert to actual current value if text changed
			local currentPropertyName = valueInput:GetAttribute("PropertyName")
			local currentPropertyType = valueInput:GetAttribute("PropertyType")
			local actualValue
			local successGetValue
			
			if objectRef:IsA("ValueBase") and currentPropertyName == "Value" then -- Special case for ValueBase itself being selected
				actualValue = objectRef.Value
				successGetValue = true
			elseif objectRef:FindFirstChild(currentPropertyName) and objectRef:FindFirstChild(currentPropertyName):IsA(currentPropertyType) then
				local valueInstance = objectRef:FindFirstChild(currentPropertyName)
				actualValue = valueInstance.Value
				successGetValue = true
			else
				successGetValue, actualValue = pcall(function() return objectRef[currentPropertyName] end)
			end

			if successGetValue then
				local formattedActualValue = tostring(actualValue)
				if currentPropertyType == "BrickColor" then formattedActualValue = actualValue.Name
				elseif currentPropertyType == "Material" then formattedActualValue = actualValue.Name
				elseif currentPropertyType == "Vector3" then formattedActualValue = string.format("%.2f, %.2f, %.2f", actualValue.X, actualValue.Y, actualValue.Z)
				elseif typeof(actualValue) == "number" then formattedActualValue = string.format("%.3f", actualValue)
				end
				if valueInput.Text ~= formattedActualValue then
					valueInput.Text = formattedActualValue -- Revert if text was changed but not submitted via Enter
				end
			end
		end
	end)

	return entryFrame
end

handlePropertyUpdate = function(object, propertyName, propertyType, newValueText, sourceTextBox)
	if not object then return end

	local success, result
	local convertedValue

	if propertyType == "string" then
		convertedValue = newValueText
		success, result = pcall(function() object[propertyName] = convertedValue end)
	elseif propertyType == "number" then
		convertedValue = tonumber(newValueText)
		if convertedValue then
			success, result = pcall(function() object[propertyName] = convertedValue end)
		else
			success = false; result = "Invalid number format"
		end
	elseif propertyType == "boolean" then
		local lowerText = newValueText:lower()
		if lowerText == "true" then convertedValue = true
		elseif lowerText == "false" then convertedValue = false
		else success = false; result = "Invalid boolean format (expected true/false)"; end
		if convertedValue ~= nil then
			success, result = pcall(function() object[propertyName] = convertedValue end)
		end
	elseif propertyType == "BrickColor" then
		success, convertedValue = pcall(function() return BrickColor.new(newValueText) end)
		if not success then -- Try by name if new() failed (e.g. "Really red")
			success, convertedValue = pcall(function() return BrickColor.new(BrickColor[newValueText] and BrickColor[newValueText].Name or newValueText) end)
		end
		if success then
			success, result = pcall(function() object[propertyName] = convertedValue end)
		else
			result = "Invalid BrickColor format/name"
		end
	elseif propertyType == "Material" then
		local materialEnum = Enum.Material:FindFirstEnumItem(newValueText)
		if materialEnum then
			convertedValue = materialEnum
			success, result = pcall(function() object[propertyName] = convertedValue end)
		else
			success = false; result = "Invalid Material name"
		end
	elseif propertyType == "Vector3" then
		local parts = {}
		for part in string.gmatch(newValueText, "[^,]+") do table.insert(parts, tonumber(part)) end
		if #parts == 3 and parts[1] and parts[2] and parts[3] then
			convertedValue = Vector3.new(parts[1], parts[2], parts[3])
			success, result = pcall(function() object[propertyName] = convertedValue end)
		else
			success = false; result = "Invalid Vector3 format (expected x,y,z)"
		end
	else -- Handle ValueBase types (e.g. StringValue, IntValue etc.)
		local valueInstance = object:FindFirstChild(propertyName)
		if propertyType == "TableEntry" then
			local customProps = objectCustomPropertiesMap[object]
			if customProps then
				success, result = pcall(function() customProps[propertyName] = newValueText end) -- Store as string
			else
				success = false; result = "Custom property table not found for object."
			end
		elseif valueInstance and valueInstance:IsA(propertyType) then
			if propertyType == "StringValue" then convertedValue = newValueText
			elseif propertyType == "NumberValue" or propertyType == "IntValue" or propertyType == "FloatValue" then convertedValue = tonumber(newValueText)
			elseif propertyType == "BoolValue" then
				local lowerText = newValueText:lower()
				if lowerText == "true" then convertedValue = true elseif lowerText == "false" then convertedValue = false end
			elseif propertyType == "Color3Value" then
				local parts = {}
				for part in string.gmatch(newValueText, "[^,]+") do table.insert(parts, tonumber(part)) end
				if #parts == 3 and parts[1] and parts[2] and parts[3] then
					convertedValue = Color3.fromRGB(parts[1], parts[2], parts[3])
				else success = false; result = "Invalid Color3 format for " .. propertyType .. " (expected r,g,b)"; end
			elseif propertyType == "Vector3Value" then
				local parts = {}
				for part in string.gmatch(newValueText, "[^,]+") do table.insert(parts, tonumber(part)) end
				if #parts == 3 and parts[1] and parts[2] and parts[3] then
					convertedValue = Vector3.new(parts[1], parts[2], parts[3])
				else success = false; result = "Invalid Vector3 format for " .. propertyType .. " (expected x,y,z)"; end
			elseif propertyType == "ObjectValue" then
				-- For ObjectValue, we might need a more complex picker or rely on path string.
				-- For now, let's assume direct assignment if a valid object path is given, or nil.
				-- This is a simplification. A real tool might use Selection.Get() or path.
				if newValueText == "nil" or newValueText == "" then convertedValue = nil
				else convertedValue = game:GetService("Workspace"):FindFirstChild(newValueText, true) or game.Players:FindFirstChild(newValueText, true) -- Example search paths
				end
				-- No pcall here for finding, but assign will be pcalled
			else
				success = false; result = "Unsupported ValueBase type for direct modification: " .. propertyType
			end

			if convertedValue ~= nil or (propertyType == "ObjectValue" and (newValueText == "nil" or newValueText == "")) then -- Ensure conversion was valid or it's a valid nil for ObjectValue
				if success ~= false then -- Check if a conversion error happened above
					success, result = pcall(function() valueInstance.Value = convertedValue end)
				end
			elseif success ~= false then -- If no conversion error but convertedValue is nil for non-ObjectValue types
				success = false; result = "Invalid value for " .. propertyType
			end
		else
			success = false; result = "ValueInstance not found or type mismatch for " .. propertyName .. " as " .. propertyType
		end
	end

	if success then
		print("Updated " .. propertyName .. " successfully.")
		-- Optional: Reformat text in sourceTextBox if needed, e.g., for Vector3 to ensure consistency
		-- For instance, if user types "1, 2, 3", it might become "1.00, 2.00, 3.00" after conversion.
		-- For simplicity, this is omitted for now.
		-- updatePropertyDisplay() -- Could refresh the whole list, or just this entry.
		-- For now, direct text update is fine.
	else
		warn("Failed to update " .. propertyName .. ": " .. tostring(result))
		-- Revert sourceTextBox.Text to the actual current value
		local actualValue
		local successGetValue
		if propertyType == "TableEntry" then
			local customProps = objectCustomPropertiesMap[object]
			if customProps and customProps[propertyName] ~= nil then
				actualValue = customProps[propertyName]
				successGetValue = true
			else
				successGetValue = false
			end
		elseif object:FindFirstChild(propertyName) and object:FindFirstChild(propertyName):IsA(propertyType) then
			local valueInstance = object:FindFirstChild(propertyName)
			actualValue = valueInstance.Value
			successGetValue = true
		else
			successGetValue, actualValue = pcall(function() return object[propertyName] end)
		end

		if successGetValue then
			local formattedActualValue = tostring(actualValue)
			if propertyType == "BrickColor" and typeof(actualValue) == "BrickColor" then formattedActualValue = actualValue.Name
			elseif propertyType == "Material" and typeof(actualValue) == "EnumItem" then formattedActualValue = actualValue.Name
			elseif propertyType == "Vector3" and typeof(actualValue) == "Vector3" then formattedActualValue = string.format("%.2f, %.2f, %.2f", actualValue.X, actualValue.Y, actualValue.Z)
			elseif propertyType == "number" then formattedActualValue = string.format("%.3f", actualValue)
			elseif propertyType == "boolean" then formattedActualValue = tostring(actualValue)
			-- For TableEntry, actualValue is already a string, no special formatting needed beyond tostring()
			end
			sourceTextBox.Text = formattedActualValue
		else
			sourceTextBox.Text = "Error fetching current value" -- Fallback
		end
	end
end

updatePropertyDisplay = function()
	-- Clear existing properties
	for _, child in ipairs(propertyScrollFrame:GetChildren()) do
		if child ~= propertyListLayout and (child:IsA("Frame") or child:IsA("TextBox") or child:IsA("TextLabel")) then
			child:Destroy()
		end
	end

	if not selectedObject then
		propertyScrollFrame.CanvasSize = UDim2.new(0,0,0,0)
		return
	end

	local layoutOrder = 0

	-- Display Built-in Properties (BasePart example)
	local basePartProperties = {"Name", "BrickColor", "Material", "Transparency", "Reflectance", "Anchored", "CanCollide", "Position", "Orientation", "Size"}
	if selectedObject:IsA("BasePart") then
		for _, propName in ipairs(basePartProperties) do
			local success, value = pcall(function() return selectedObject[propName] end)
			if success then
				local propType = typeof(value)
				local displayValue = tostring(value)

				if type(value) == "BrickColor" then
					propType = "BrickColor"
					displayValue = value.Name -- Or string.format("%.2f, %.2f, %.2f", value.r, value.g, value.b)
				elseif type(value) == "Material" then
					propType = "Material"
					displayValue = value.Name
				elseif type(value) == "Vector3" then
					propType = "Vector3"
					displayValue = string.format("%.2f, %.2f, %.2f", value.X, value.Y, value.Z)
				elseif type(value) == "boolean" then
					propType = "boolean"
					displayValue = tostring(value)
				elseif type(value) == "number" then
					propType = "number"
					displayValue = string.format("%.3f", value) -- Format numbers nicely
				end
				
				createPropertyEntry(propName, displayValue, propType, layoutOrder, selectedObject)
				layoutOrder = layoutOrder + 1
			else
				warn("Failed to get property " .. propName .. " for " .. selectedObject.Name .. ": " .. tostring(value))
			end
		end
	end

	-- Display ValueBase Custom Properties
	for _, childInstance in ipairs(selectedObject:GetChildren()) do
		if childInstance:IsA("ValueBase") then
			createPropertyEntry(childInstance.Name, tostring(childInstance.Value), childInstance.ClassName, layoutOrder, selectedObject) -- Pass selectedObject as objectRef
			layoutOrder = layoutOrder + 1
		end
	end

	-- Display Table-Based Custom Properties
	if selectedObject and objectCustomPropertiesMap[selectedObject] then
		for propName, propValue in pairs(objectCustomPropertiesMap[selectedObject]) do
			createPropertyEntry(propName, tostring(propValue), "TableEntry", layoutOrder, selectedObject)
			layoutOrder = layoutOrder + 1
		end
	end
	
	-- Update CanvasSize after a short delay to allow UIListLayout to update
	-- This is a common workaround for UIListLayout's AbsoluteContentSize not updating immediately
	task.wait() 
	propertyScrollFrame.CanvasSize = UDim2.new(0, 0, 0, propertyListLayout.AbsoluteContentSize.Y)
end


-- 5. Custom Property Management Section
local customPropNameInput = createElement("TextBox", {
	Name = "CustomPropNameInput",
	Parent = mainPanel,
	PlaceholderText = "Property Name",
	Position = UDim2.new(0.05, 0, 0.6, 0),
	Size = UDim2.new(0.4, 0, 0.08, 0),
	Font = defaultTextProps.Font,
	TextColor3 = defaultTextProps.TextColor3,
	BackgroundColor3 = defaultTextBoxProps.BackgroundColor3,
	BorderColor3 = defaultTextBoxProps.BorderColor3
})

local customPropValueInput = createElement("TextBox", {
	Name = "CustomPropValueInput",
	Parent = mainPanel,
	PlaceholderText = "Property Value",
	Position = UDim2.new(0.5, 0, 0.6, 0),
	Size = UDim2.new(0.45, 0, 0.08, 0),
	Font = defaultTextProps.Font,
	TextColor3 = defaultTextProps.TextColor3,
	BackgroundColor3 = defaultTextBoxProps.BackgroundColor3,
	BorderColor3 = defaultTextBoxProps.BorderColor3
})

local customPropTypeInput = createElement("TextBox", {
	Name = "CustomPropTypeInput",
	Parent = mainPanel,
	PlaceholderText = "Type (StringValue, TableEntry...)",
	Position = UDim2.new(0.05, 0, 0.7, 0),
	Size = UDim2.new(0.6, 0, 0.08, 0),
	Font = defaultTextProps.Font,
	TextColor3 = defaultTextProps.TextColor3,
	BackgroundColor3 = defaultTextBoxProps.BackgroundColor3,
	BorderColor3 = defaultTextBoxProps.BorderColor3
})

local addCustomPropButton = createElement("TextButton", {
	Name = "AddCustomPropButton",
	Parent = mainPanel,
	Text = "Add Custom Prop",
	Position = UDim2.new(0.7, 0, 0.7, 0),
	Size = UDim2.new(0.25, 0, 0.08, 0),
	Font = defaultTextProps.Font,
	TextColor3 = defaultTextProps.TextColor3,
	BackgroundColor3 = defaultButtonProps.BackgroundColor3
})

addCustomPropButton.MouseButton1Click:Connect(function()
	if not selectedObject then
		warn("No object selected to add property to.")
		return
	end

	local propName = customPropNameInput.Text
	local propValueStr = customPropValueInput.Text
	local propTypeStr = customPropTypeInput.Text

	if propName == "" then
		warn("Property name cannot be empty.")
		return
	end
	if propTypeStr == "" then
		warn("Property type cannot be empty.")
		return
	end

	if selectedObject:FindFirstChild(propName) or (objectCustomPropertiesMap[selectedObject] and objectCustomPropertiesMap[selectedObject][propName] ~= nil) then
		warn("Property or child with this name already exists.")
		return
	end

	local typeKey = propTypeStr:lower():gsub("%s+", "")
	local validValueBaseTypes = {
		stringvalue = "StringValue",
		intvalue = "IntValue",
		numbervalue = "NumberValue",
		boolvalue = "BoolValue",
		booleanvalue = "BoolValue", -- Alias
		color3value = "Color3Value",
		vector3value = "Vector3Value",
		objectvalue = "ObjectValue",
		floatvalue = "FloatValue" -- Common alias for NumberValue
	}

	local propertyAdded = false

	if validValueBaseTypes[typeKey] then
		local actualValueBaseType = validValueBaseTypes[typeKey]
		local success, valueInstance = pcall(function() return Instance.new(actualValueBaseType) end)

		if success and valueInstance then
			valueInstance.Name = propName
			local conversionSuccess = true
			local convertedValue

			-- Attempt to convert propValueStr to the correct type
			if actualValueBaseType == "StringValue" then
				convertedValue = propValueStr
			elseif actualValueBaseType == "IntValue" or actualValueBaseType == "NumberValue" or actualValueBaseType == "FloatValue" then
				convertedValue = tonumber(propValueStr)
				if convertedValue == nil then
					warn("Invalid number format for " .. actualValueBaseType .. ": " .. propValueStr)
					conversionSuccess = false
				end
			elseif actualValueBaseType == "BoolValue" then
				local lowerVal = propValueStr:lower()
				if lowerVal == "true" then convertedValue = true
				elseif lowerVal == "false" then convertedValue = false
				else
					warn("Invalid boolean format for BoolValue (expected 'true' or 'false'): " .. propValueStr)
					conversionSuccess = false
				end
			elseif actualValueBaseType == "Color3Value" then
				local parts = {}
				for part in string.gmatch(propValueStr, "[^,]+") do table.insert(parts, tonumber(part)) end
				if #parts == 3 and parts[1] and parts[2] and parts[3] then
					convertedValue = Color3.fromRGB(parts[1], parts[2], parts[3])
				else
					warn("Invalid Color3 format for Color3Value (expected r,g,b): " .. propValueStr)
					conversionSuccess = false
				end
			elseif actualValueBaseType == "Vector3Value" then
				local parts = {}
				for part in string.gmatch(propValueStr, "[^,]+") do table.insert(parts, tonumber(part)) end
				if #parts == 3 and parts[1] and parts[2] and parts[3] then
					convertedValue = Vector3.new(parts[1], parts[2], parts[3])
				else
					warn("Invalid Vector3 format for Vector3Value (expected x,y,z): " .. propValueStr)
					conversionSuccess = false
				end
			elseif actualValueBaseType == "ObjectValue" then
				if propValueStr == "" or propValueStr:lower() == "nil" then
					convertedValue = nil
				else
					-- Search in Workspace, then ReplicatedStorage, then Players for flexibility
					convertedValue = game.Workspace:FindFirstChild(propValueStr, true) or 
					                 game:GetService("ReplicatedStorage"):FindFirstChild(propValueStr, true) or 
					                 game:GetService("Players"):FindFirstChild(propValueStr, true)
					if not convertedValue then
						warn("ObjectValue target not found: " .. propValueStr)
						-- Do not set conversionSuccess to false, nil is a valid value for ObjectValue.
						-- The user might intend to set it to nil or an object that doesn't exist yet.
					end
				end
			end

			if conversionSuccess then
				local assignSuccess, assignError = pcall(function() valueInstance.Value = convertedValue end)
				if assignSuccess then
					valueInstance.Parent = selectedObject
					print("Added " .. actualValueBaseType .. " property '" .. propName .. "' to " .. selectedObject.Name)
					propertyAdded = true
				else
					warn("Failed to assign value to " .. actualValueBaseType .. ": " .. assignError)
					valueInstance:Destroy() -- Clean up failed instance
				end
			else
				valueInstance:Destroy() -- Clean up failed instance
			end
		else
			warn("Failed to create ValueBase instance of type: " .. actualValueBaseType .. ". Error: " .. tostring(valueInstance))
		end
	elseif typeKey == "tableentry" then
		if not objectCustomPropertiesMap[selectedObject] then
			objectCustomPropertiesMap[selectedObject] = {}
		end
		objectCustomPropertiesMap[selectedObject][propName] = propValueStr -- Store as string
		print("Added table entry property '" .. propName .. "' to " .. selectedObject.Name)
		propertyAdded = true
	else
		warn("Unsupported property type: " .. propTypeStr .. ". Use a valid ValueBase type (e.g., StringValue, IntValue, BoolValue, Color3Value, Vector3Value, ObjectValue) or 'TableEntry'.")
		return -- Do not clear inputs or refresh if type is invalid
	end

	if propertyAdded then
		updatePropertyDisplay()
		customPropNameInput.Text = ""
		customPropValueInput.Text = ""
		customPropTypeInput.Text = ""
	end
end)

-- 6. Object Management Buttons
local deleteButton = createElement("TextButton", {
	Name = "DeleteButton",
	Parent = mainPanel,
	Text = "Delete Selected",
	Position = UDim2.new(0.05, 0, 0.8, 0),
	Size = UDim2.new(0.4, 0, 0.08, 0),
	Font = defaultTextProps.Font,
	TextColor3 = defaultTextProps.TextColor3,
	BackgroundColor3 = defaultButtonProps.BackgroundColor3
})

local duplicateButton = createElement("TextButton", {
	Name = "DuplicateButton",
	Parent = mainPanel,
	Text = "Duplicate Selected",
	Position = UDim2.new(0.5, 0, 0.8, 0),
	Size = UDim2.new(0.45, 0, 0.08, 0),
	Font = defaultTextProps.Font,
	TextColor3 = defaultTextProps.TextColor3,
	BackgroundColor3 = defaultButtonProps.BackgroundColor3
})

deleteButton.MouseButton1Click:Connect(function()
	if not selectedObject then
		warn("No object selected to delete.")
		return
	end

	local objectToDelete = selectedObject
	local objectName = objectToDelete.Name

	-- Clear current selection state
	selectedObject = nil
	SelectedObjectLabel.Text = "Selected: None"
	updatePropertyDisplay() -- Update display before potential errors during deletion

	-- Remove from custom property map
	if objectCustomPropertiesMap[objectToDelete] then
		objectCustomPropertiesMap[objectToDelete] = nil
	end

	-- Destroy the Instance
	local success, err = pcall(function()
		objectToDelete:Destroy()
	end)

	if success then
		print("Object '" .. objectName .. "' and its custom properties deleted successfully.")
	else
		warn("Error destroying object '" .. objectName .. "': " .. tostring(err))
	end
end)

print("AllInOneTool UI elements created successfully.")

-- Selection Logic
local mouse = localPlayer:GetMouse()

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then
		-- Try to deselect if clicking on nothing specific within our UI, but not on other game UI
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local target = mouse.Target
			if not target or not target:IsDescendantOf(mainPanel) then
				-- Potentially deselect if clicking "off" the main panel
				-- but this logic is tricky; the primary deselection is below
			end
		end
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local target = mouse.Target
		if target and target:IsA("BasePart") and not target:IsDescendantOf(screenGui) then
			selectedObject = target
			SelectedObjectLabel.Text = "Selected: " .. selectedObject.Name
			print("Selected object: " .. selectedObject:GetFullName())
			updatePropertyDisplay()
		else
			-- Clicked on sky, non-BasePart, or our own UI (if not caught by gameProcessedEvent)
			if selectedObject then -- only print if there was a selection
				print("Selection cleared.")
			end
			selectedObject = nil
			SelectedObjectLabel.Text = "Selected: None"
			updatePropertyDisplay()
		end
	end
end)
