local ui = Instance.new("ScreenGui")
ui.Name = "OktanStartup"
ui.ResetOnSpawn = false
ui.DisplayOrder = 10000
ui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local label = Instance.new("TextLabel")
label.Size = UDim2.fromOffset(540, 110)
label.Position = UDim2.new(0.5, -270, 0, 70)
label.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
label.TextColor3 = Color3.fromRGB(235, 240, 255)
label.TextSize = 15
label.TextWrapped = true
label.Text = "Oktan: loader started"
label.Parent = ui
local function stage(value)
    if label.Parent then label.Text = "Oktan: " .. value end
    print("[Oktan] " .. value)
end
local function boot()
-- Oktan access check. No keys are stored in this repository.
local env = getgenv()
local key = env.Key
if type(key) ~= "string" or #key < 1 or #key > 128 then
    error("Oktan: set getgenv().Key before running the loader", 0)
end
local http = game:GetService("HttpService")
local send = request or http_request or (syn and syn.request)
if type(send) ~= "function" then error("Oktan: HTTP request is unavailable", 0) end
stage("Checking key server...")
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
stage("Key accepted. Downloading client...")
local fetched, source = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/barmunddd/Oktan/7b23e13f5727ba780ea941938cbb0135be315379/client.luau")
end)
if not fetched or type(source) ~= "string" or #source == 0 then
    error("Oktan: client download failed", 0)
end
stage("Compiling client...")
local program, compileError = loadstring(source)
if not program then error("Oktan: client compilation failed: " .. tostring(compileError), 0) end
env.Key = nil
stage("Starting client...")
program()

end
local finished = false
task.delay(20, function()
    if not finished and ui.Parent then stage("Still waiting. Check the executor console; request or client startup may be delayed.") end
end)
local ok, message = pcall(boot)
finished = true
if ok then
    ui:Destroy()
else
    stage(tostring(message))
    warn("[Oktan] Startup failed: " .. tostring(message))
end
