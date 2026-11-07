-- Oktan access check. No keys are stored in this repository.
local env = getgenv()
local key = env.Key
if type(key) ~= "string" or #key < 1 or #key > 128 then
    error("Oktan: set getgenv().Key before running the loader", 0)
end
local http = game:GetService("HttpService")
local send = request or http_request or (syn and syn.request)
if type(send) ~= "function" then error("Oktan: HTTP request is unavailable", 0) end
local ok, response = pcall(send, {
    Url = "https://oktandev.pythonanywhere.com/verify",
    Method = "POST",
    Headers = { ["Content-Type"] = "application/json" },
    Body = http:JSONEncode({ key = key }),
})
if not ok or type(response) ~= "table" or response.StatusCode ~= 200 then
    error("Oktan: key server unavailable; client was not started", 0)
end
local decoded, result = pcall(function() return http:JSONDecode(response.Body) end)
if not decoded or type(result) ~= "table" or result.valid ~= true then
    error("Oktan: invalid, expired or revoked key", 0)
end
local fetched, source = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/barmunddd/Oktan/252e82fb27e6eb069160994724eae54a912a1ac7/client.luau")
end)
if not fetched or type(source) ~= "string" or #source == 0 then
    error("Oktan: client download failed", 0)
end
local program, compileError = loadstring(source)
if not program then error("Oktan: client compilation failed: " .. tostring(compileError), 0) end
env.Key = nil
program()
