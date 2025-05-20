--!strict

-- src/tests/Logger.spec.luau

local Logger = require(script.Parent.Parent.src.Modules.Logger)

print("Starting Logger Module tests...")
print("------------------------------------")

print("Testing Logger.info...")
Logger.info("This is a standard info message.")
Logger.info("Another info message with numbers: 12345 and booleans: " .. tostring(true))
print("Logger.info tests complete.\n")

print("Testing Logger.warn...")
Logger.warn("This is a standard warning message.")
Logger.warn("A critical warning that needs attention!")
print("Logger.warn tests complete.\n")

print("Testing Logger.error...")
Logger.error("This is a standard error message without details.")
Logger.error("This is an error message with string details.", "Network connection timed out.")
Logger.error("This is an error message with number details.", 500)
Logger.error("This is an error message with boolean details.", false)
Logger.error("This is an error message with table details (dictionary-like).", { 
    code = 101, 
    reason = "User not found", 
    userId = "testUser123" 
})
Logger.error("This is an error message with table details (array-like).", { 
    "Permission denied", 
    "Resource: /api/data", 
    "Attempt: WRITE" 
})
Logger.error("This is an error message with an empty table detail.", {})
Logger.error("This is an error message with nil details.", nil) -- Should be same as no details
print("Logger.error tests complete.\n")

print("------------------------------------")
print("Logger Module tests complete. Please visually verify the output above for correct formatting and content.")
