-- TestUGCService.luau
-- Unit tests for UGCService.luau

print("--- Starting TestUGCService.luau ---")

-- 0. Assertion Helpers and Module Loading
local UGCService

local function assertOk(condition, message)
    if not condition then
        error("Assertion failed: " .. (message or debug.traceback("Assertion failed", 2)), 0)
    end
end

local function assertEquals(val1, val2, message)
    if val1 ~= val2 then
        error("Assertion failed: (" .. tostring(val1) .. " ~= " .. tostring(val2) .. ") " .. (message or debug.traceback("Values not equal", 2)), 0)
    end
end

local function assertNil(val, message)
    if val ~= nil then
        error("Assertion failed: (" .. tostring(val) .. " is not nil) " .. (message or debug.traceback("Value not nil", 2)), 0)
    end
end

local function assertNotNil(val, message)
    if val == nil then
        error("Assertion failed: Value is nil. " .. (message or debug.traceback("Value is nil", 2)), 0)
    end
end

local function assertType(val, expectedType, message)
    if type(val) ~= expectedType then
        error("Assertion failed: Type of (" .. tostring(val) .. ") is " .. type(val) .. ", expected " .. expectedType .. ". " .. (message or debug.traceback("Type mismatch", 2)), 0)
    end
end

local function assertStringContains(str, findStr, message)
    assertType(str, "string", "Original string for assertStringContains must be a string. " .. message)
    assertType(findStr, "string", "Pattern for assertStringContains must be a string. " .. message)
    if not string.find(str, findStr, 1, true) then -- plain find
         error("Assertion failed: String '" .. str .. "' does not contain '" .. findStr .. "'. " .. (message or debug.traceback("String does not contain", 2)), 0)
    end
end


local successLoad, ugcModule = pcall(function()
    return require(script.Parent.UGCService) -- Adjust path if necessary
end)

if not successLoad or not ugcModule then
    error("CRITICAL: Failed to load UGCService.luau. Ensure it's present and returns a module table. Error: " .. tostring(ugcModule))
end
UGCService = ugcModule
print("UGCService module loaded successfully.")

-- Test Suite
local tests = {}
local testData = {
    creator1 = "testUser_1",
    creator2 = "testUser_2",
    scriptContent1 = "print('Hello from UGC 1')",
    scriptContent2 = "print('Greetings from UGC 2')",
    name1 = "MyFirstUGC",
    name2 = "AnotherUGC",
    desc1 = "Description for first UGC",
    desc2 = "Description for another UGC",
    ugcId1 = nil, -- To be filled by upload test
    ugcId2 = nil, -- To be filled by upload test
}

-- Simulate os.time() if it's not available or returns 0, to make tests more deterministic
local timeOffset = 0
local originalOsTime = os.time
local function getMockTime()
    timeOffset = timeOffset + 10 -- Increment by a noticeable amount
    return originalOsTime() + timeOffset -- Use actual time if available and > 0, plus offset
end

if originalOsTime() == 0 then
    print("Warning: os.time() returned 0. Overriding os.time for testing.")
    os.time = getMockTime
else
    -- Wrap os.time to ensure it increments for tests even if run quickly
    os.time = getMockTime
end


function tests.testUploadUGC()
    print("\nRunning: Test Suite for uploadUGC()")

    -- Successful upload
    print("  Running: Successful UGC upload")
    local ugcId, err = UGCService.uploadUGC(testData.creator1, testData.scriptContent1, testData.name1, testData.desc1)
    assertNotNil(ugcId, "uploadUGC should return a UGC ID on success. Err: " .. tostring(err))
    assertNil(err, "Error should be nil on successful upload.")
    testData.ugcId1 = ugcId -- Save for later tests
    print("    Passed: Successful UGC upload (ID: " .. ugcId .. ")")

    local entry = UGCService.getUGC(ugcId) -- Use getUGC to verify internal state (assuming getUGC works initially)
    assertNotNil(entry, "Uploaded entry should be retrievable.")
    assertEquals(entry.Creator_ID, testData.creator1, "Creator ID mismatch.")
    assertEquals(entry.ScriptContent, testData.scriptContent1, "ScriptContent mismatch.")
    assertEquals(entry.Name, testData.name1, "Name mismatch.")
    assertEquals(entry.Description, testData.desc1, "Description mismatch.")
    assertEquals(entry.Version, 1, "Version should be 1 on first upload.")
    assertType(entry.CreationDate, "number", "CreationDate should be a number.")
    assertType(entry.LastUpdateDate, "number", "LastUpdateDate should be a number.")
    assertOk(entry.LastUpdateDate >= entry.CreationDate, "LastUpdateDate should be >= CreationDate.")
    print("    Passed: Uploaded data verification.")

    -- Invalid inputs
    print("  Running: Invalid inputs for uploadUGC")
    local idNilCreator, errNilCreator = UGCService.uploadUGC(nil, "content", "name", "desc")
    assertNil(idNilCreator, "ID should be nil for nil creatorId.")
    assertNotNil(errNilCreator, "Error message should be present for nil creatorId.")
    assertStringContains(errNilCreator, "Creator ID is required", "Error message for nil creatorId mismatch.")
    print("    Passed: Nil creatorId.")

    local idNilContent, errNilContent = UGCService.uploadUGC(testData.creator1, nil, "name", "desc")
    assertNil(idNilContent, "ID should be nil for nil scriptContent.")
    assertNotNil(errNilContent, "Error message should be present for nil scriptContent.")
    assertStringContains(errNilContent, "Script content is required", "Error message for nil scriptContent mismatch.")
    print("    Passed: Nil scriptContent.")
    
    local idNilName, errNilName = UGCService.uploadUGC(testData.creator1, "content", nil, "desc")
    assertNil(idNilName, "ID should be nil for nil name.")
    assertNotNil(errNilName, "Error message should be present for nil name.")
    assertStringContains(errNilName, "Name must be a non-empty string", "Error message for nil name mismatch.")
    print("    Passed: Nil name.")

    local idEmptyName, errEmptyName = UGCService.uploadUGC(testData.creator1, "content", "", "desc")
    assertNil(idEmptyName, "ID should be nil for empty name.")
    assertNotNil(errEmptyName, "Error message should be present for empty name.")
    assertStringContains(errEmptyName, "Name must be a non-empty string", "Error message for empty name mismatch.")
    print("    Passed: Empty name.")

    print("Test Suite for uploadUGC() completed.")
end

function tests.testGetUGC()
    print("\nRunning: Test Suite for getUGC()")
    assertNotNil(testData.ugcId1, "Pre-requisite: testData.ugcId1 must be set by upload test.")

    -- Retrieve existing UGC
    print("  Running: Retrieve existing UGC")
    local entry = UGCService.getUGC(testData.ugcId1)
    assertNotNil(entry, "Should retrieve existing UGC.")
    assertEquals(entry.UGC_ID, testData.ugcId1, "UGC_ID mismatch on retrieval.")
    assertEquals(entry.Name, testData.name1, "Name mismatch on retrieval.")
    print("    Passed: Retrieve existing UGC.")

    -- Retrieve non-existent UGC
    print("  Running: Retrieve non-existent UGC")
    local nonExistentEntry = UGCService.getUGC("non_existent_id_12345")
    assertNil(nonExistentEntry, "Should return nil for non-existent UGC.")
    print("    Passed: Retrieve non-existent UGC.")

    -- Verify a *copy* is returned
    print("  Running: Verify a copy is returned by getUGC")
    local retrievedCopy = UGCService.getUGC(testData.ugcId1)
    assertNotNil(retrievedCopy, "Failed to retrieve UGC for copy test.")
    retrievedCopy.Name = "Modified In Copy"
    retrievedCopy.Version = 1000

    local originalEntry = UGCService.getUGC(testData.ugcId1) -- Re-fetch the original
    assertNotNil(originalEntry, "Failed to re-retrieve UGC for copy test verification.")
    assertEquals(originalEntry.Name, testData.name1, "Original name in DB should not be affected by copy modification.")
    assertEquals(originalEntry.Version, 1, "Original version in DB should not be affected by copy modification (assuming version is 1).")
    print("    Passed: getUGC returns a copy.")

    print("Test Suite for getUGC() completed.")
end

function tests.testUpdateUGC()
    print("\nRunning: Test Suite for updateUGC()")
    assertNotNil(testData.ugcId1, "Pre-requisite: testData.ugcId1 must be set by upload test.")
    
    local originalEntry = UGCService.getUGC(testData.ugcId1)
    assertNotNil(originalEntry, "Failed to get original entry for update tests.")
    local originalVersion = originalEntry.Version
    local originalUpdateDate = originalEntry.LastUpdateDate

    -- Successful update by owner
    print("  Running: Successful update by owner")
    local newContent = "print('Updated script content!')"
    local newName = "MyFirstUGC-V2"
    local newDesc = "Updated description."
    
    -- Ensure a small delay for timestamp check if system is very fast
    if os.time == getMockTime then os.time() end -- Force time increment if mocked

    local updatedId, errUpdate = UGCService.updateUGC(testData.ugcId1, testData.creator1, newContent, newName, newDesc)
    assertNotNil(updatedId, "updateUGC should return UGC ID on success. Err: " .. tostring(errUpdate))
    assertNil(errUpdate, "Error should be nil on successful update.")
    assertEquals(updatedId, testData.ugcId1, "Updated ID should match original ID.")

    local updatedEntry = UGCService.getUGC(testData.ugcId1)
    assertNotNil(updatedEntry, "Failed to retrieve entry after update.")
    assertEquals(updatedEntry.ScriptContent, newContent, "ScriptContent not updated.")
    assertEquals(updatedEntry.Name, newName, "Name not updated.")
    assertEquals(updatedEntry.Description, newDesc, "Description not updated.")
    assertEquals(updatedEntry.Version, originalVersion + 1, "Version not incremented correctly.")
    assertOk(updatedEntry.LastUpdateDate > originalUpdateDate, "LastUpdateDate not updated correctly (expected greater). Actual: " .. updatedEntry.LastUpdateDate .. ", Original: " .. originalUpdateDate)
    print("    Passed: Successful update by owner.")

    -- Unauthorized update (different creatorId)
    print("  Running: Unauthorized update attempt")
    local unauthorizedId, errUnauthorized = UGCService.updateUGC(testData.ugcId1, testData.creator2, "hacked content", "Hacked Name")
    assertNil(unauthorizedId, "ID should be nil for unauthorized update.")
    assertNotNil(errUnauthorized, "Error message should be present for unauthorized update.")
    assertStringContains(errUnauthorized, "Unauthorized", "Error message for unauthorized update mismatch.")

    local entryAfterUnauthorizedAttempt = UGCService.getUGC(testData.ugcId1) -- Check it wasn't actually changed
    assertEquals(entryAfterUnauthorizedAttempt.ScriptContent, newContent, "ScriptContent should not change on failed unauthorized update.")
    assertEquals(entryAfterUnauthorizedAttempt.Name, newName, "Name should not change on failed unauthorized update.")
    print("    Passed: Unauthorized update attempt blocked.")

    -- Update non-existent UGC
    print("  Running: Update non-existent UGC")
    local nonExistentId, errNonExistent = UGCService.updateUGC("non_existent_id_ABC", testData.creator1, "some content")
    assertNil(nonExistentId, "ID should be nil for non-existent UGC update.")
    assertNotNil(errNonExistent, "Error message should be present for non-existent UGC update.")
    assertStringContains(errNonExistent, "not found", "Error message for non-existent UGC mismatch.")
    print("    Passed: Update non-existent UGC.")
    
    -- Test update with nil script content (should fail)
    print("  Running: Update with nil script content")
    local nilScriptId, errNilScript = UGCService.updateUGC(testData.ugcId1, testData.creator1, nil, "Name Check")
    assertNil(nilScriptId, "ID should be nil when updating with nil script content.")
    assertNotNil(errNilScript, "Error should be present when updating with nil script content.")
    assertStringContains(errNilScript, "required", "Error message for nil script content on update mismatch.")
    print("    Passed: Update with nil script content.")


    print("Test Suite for updateUGC() completed.")
end

function tests.testListUGCByUser()
    print("\nRunning: Test Suite for listUGCByUser()")
    
    -- Upload a second UGC for creator1 and one for creator2
    print("  Setup: Uploading additional UGCs for list test")
    local _, errC1U2 = UGCService.uploadUGC(testData.creator1, testData.scriptContent2, "Creator1_UGC2", "Desc C1U2")
    assertNotNil(_,"Failed to upload second UGC for creator1")
    testData.ugcId2, errC2U1 = UGCService.uploadUGC(testData.creator2, "content for user 2", testData.name2, testData.desc2)
    assertNotNil(testData.ugcId2,"Failed to upload UGC for creator2")

    -- List for user with UGC (creator1 should have 2)
    print("  Running: List for user with UGC (creator1)")
    local listCreator1 = UGCService.listUGCByUser(testData.creator1)
    assertType(listCreator1, "table", "listUGCByUser should return a table.")
    assertEquals(#listCreator1, 2, "Creator1 should have 2 UGCs listed. Found: " .. #listCreator1)
    -- Verify one of the items (e.g., the first one uploaded)
    local foundFirstUGC = false
    for _, item in ipairs(listCreator1) do
        if item.UGC_ID == testData.ugcId1 then
            foundFirstUGC = true
            assertEquals(item.Name, "MyFirstUGC-V2", "Name mismatch in listed UGC (expected updated name).") -- Name was updated in updateUGC test
        end
    end
    assertOk(foundFirstUGC, "The first UGC (ugcId1) was not found in the list for creator1.")
    print("    Passed: List for user with UGC (creator1).")

    -- List for user with no UGC (a new, temporary user)
    print("  Running: List for user with no UGC")
    local listNewUser = UGCService.listUGCByUser("newUser_NoUGC_XYZ")
    assertType(listNewUser, "table", "listUGCByUser should return a table for user with no UGC.")
    assertEquals(#listNewUser, 0, "List for user with no UGC should be empty.")
    print("    Passed: List for user with no UGC.")

    -- Verify copies are returned
    print("  Running: Verify copies are returned by listUGCByUser")
    local listForCopyTest = UGCService.listUGCByUser(testData.creator2)
    assertOk(#listForCopyTest > 0, "Need at least one UGC for creator2 to test copy functionality.")
    local itemFromList = listForCopyTest[1]
    itemFromList.Name = "Modified In List Copy"
    itemFromList.Version = 2000

    local originalItemInDB = UGCService.getUGC(itemFromList.UGC_ID)
    assertNotNil(originalItemInDB, "Failed to get original item from DB for list copy test.")
    assertEquals(originalItemInDB.Name, testData.name2, "Original name in DB should not be affected by list copy modification.")
    assertEquals(originalItemInDB.Version, 1, "Original version in DB should not be affected by list copy modification.")
    print("    Passed: listUGCByUser returns copies.")

    print("Test Suite for listUGCByUser() completed.")
end


-- Run all tests
local function runAllTests()
    local testOrder = {
        "testUploadUGC", -- Must run first to populate testData.ugcId1
        "testGetUGC",    -- Depends on upload
        "testUpdateUGC", -- Depends on upload
        "testListUGCByUser" -- Depends on upload for setup
    }
    local testCount = #testOrder
    local passedCount = 0

    for _, name in ipairs(testOrder) do
        local testFunc = tests[name]
        testCount = testCount + 1
        print("------------------------------------------")
        print("Starting test function: " .. name)
        local success, err = pcall(testFunc)
        if success then
            print(name .. " PASSED.")
            passedCount = passedCount + 1
        else
            print(name .. " FAILED: " .. tostring(err))
        end
    end
    print("------------------------------------------")
    if passedCount == #testOrder then
        print("All " .. passedCount .. " test functions passed successfully!")
    else
        error("FAILURE: " .. (#testOrder - passedCount) .. " out of " .. #testOrder .. " test functions failed.")
    end
end

runAllTests()

print("--- TestUGCService.luau Finished ---")
