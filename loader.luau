-- Oktan authenticated loader. Keys stay in memory and are never sent to the renewal URL.
local RENEW_URL = "https://funpay.com/users/15095530/"
local CLIENT_URL = "https://raw.githubusercontent.com/barmunddd/Oktan/00349ab97d72497700efe682d251ef1c17e89e32/client.luau"
local env = getgenv()
local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local ui = Instance.new("ScreenGui")
ui.Name, ui.ResetOnSpawn, ui.DisplayOrder, ui.Parent = "OktanStartup", false, 10000, playerGui
local label = Instance.new("TextLabel")
label.Size, label.Position = UDim2.fromOffset(540, 110), UDim2.new(0.5, -270, 0, 70)
label.BackgroundColor3, label.TextColor3 = Color3.fromRGB(18, 22, 30), Color3.fromRGB(235, 240, 255)
label.TextSize, label.TextWrapped, label.Text, label.Parent = 15, true, "Oktan: проверка ключа...", ui
local corner = Instance.new("UICorner"); corner.CornerRadius, corner.Parent = UDim.new(0, 14), label
local function stage(message)
    if label.Parent then label.Text = "Oktan: " .. message end
end
local function openRenewal(copyFallback)
    if type(openurl) == "function" then
        local ok, result = pcall(openurl, RENEW_URL)
        if ok and result ~= false then return "Страница FunPay открыта" end
    end
    if copyFallback and type(setclipboard) == "function" then
        local ok = pcall(setclipboard, RENEW_URL)
        if ok then return "Ссылка FunPay скопирована" end
    end
    return "Открой ссылку FunPay вручную: " .. RENEW_URL
end
local function accessNotice(state, automatic)
    if not ui.Parent then
        ui = Instance.new("ScreenGui")
        ui.Name, ui.ResetOnSpawn, ui.DisplayOrder, ui.Parent = "OktanRenewal", false, 10000, playerGui
        label = Instance.new("TextLabel")
        label.Size, label.Position = UDim2.fromOffset(540, 160), UDim2.new(0.5, -270, 0.35, -80)
        label.BackgroundColor3, label.TextColor3 = Color3.fromRGB(18, 22, 30), Color3.fromRGB(235, 240, 255)
        label.TextSize, label.TextWrapped, label.Parent = 15, true, ui
        local edge = Instance.new("UICorner"); edge.CornerRadius, edge.Parent = UDim.new(0, 14), label
    end
    label.Size = UDim2.fromOffset(540, 160)
    label.Position = UDim2.new(0.5, -270, 0.35, -80)
    local titles = { expired = "Срок ключа истёк", revoked = "Ключ отозван", invalid = "Ключ не найден", inactive = "Ключ больше не действует", unavailable = "Не удалось подтвердить подписку" }
    label.Text = (titles[state] or titles.inactive) .. "\n" .. RENEW_URL .. "\nКлюч и данные аккаунта не передаются в FunPay."
    if automatic and state == "expired" then
        local last = env.OktanRenewalOpenedAt
        if type(last) ~= "number" or os.clock() - last > 60 then
            env.OktanRenewalOpenedAt = os.clock()
            local result = openRenewal(false)
            label.Text ..= "\n" .. result
        end
    end
    local renew = Instance.new("TextButton")
    renew.Size, renew.Position = UDim2.fromOffset(230, 36), UDim2.new(0.5, -240, 0.35, 96)
    renew.Text, renew.Parent = "FunPay / Copy link", ui
    renew.BackgroundColor3, renew.TextColor3, renew.TextSize, renew.BorderSizePixel = Color3.fromRGB(38, 48, 31), Color3.fromRGB(210, 255, 135), 14, 0
    local renewCorner = Instance.new("UICorner"); renewCorner.CornerRadius, renewCorner.Parent = UDim.new(0, 12), renew
    renew.Activated:Connect(function() label.Text = (titles[state] or titles.inactive) .. "\n" .. openRenewal(true) end)
    local close = Instance.new("TextButton")
    close.Size, close.Position = UDim2.fromOffset(230, 36), UDim2.new(0.5, 10, 0.35, 96)
    close.Text, close.Parent = "Закрыть", ui
    close.BackgroundColor3, close.TextColor3, close.TextSize, close.BorderSizePixel = Color3.fromRGB(28, 33, 43), Color3.fromRGB(220, 227, 240), 14, 0
    local closeCorner = Instance.new("UICorner"); closeCorner.CornerRadius, closeCorner.Parent = UDim.new(0, 12), close
    close.Activated:Connect(function() ui:Destroy() end)
end
local function boot()
    local key = env.Key
    env.Key = nil
    if type(key) ~= "string" or #key == 0 or #key > 128 then error("Укажи getgenv().Key перед запуском", 0) end
    local http = game:GetService("HttpService")
    local send = request or http_request or (syn and syn.request)
    if type(send) ~= "function" then error("HTTP request недоступен", 0) end
    local function verify()
        if not key then return nil end
        local ok, response = pcall(send, { Url = "https://oktandev.pythonanywhere.com/verify", Method = "POST",
            Headers = { ["Content-Type"] = "application/json" }, Body = http:JSONEncode({ key = key }), Timeout = 10 })
        if not ok or type(response) ~= "table" or response.StatusCode ~= 200 then return nil end
        local decoded, result = pcall(function() return http:JSONDecode(response.Body) end)
        if not decoded or type(result) ~= "table" or type(result.valid) ~= "boolean" then return nil end
        if result.valid and result.status and result.status ~= "active" then return nil end
        return result
    end
    local first = verify()
    if not first then key = nil; accessNotice("unavailable", false); return false end
    if not first.valid then
        local reason = first.status == "expired" and "expired" or first.status == "revoked" and "revoked" or first.status == "invalid" and "invalid" or "inactive"
        key = nil; accessNotice(reason, reason == "expired"); return false
    end
    local session = { status = "active", renewUrl = RENEW_URL, cancelled = false, terminated = false }
    local function timestamp(value) return type(value) == "number" and value == value and value >= 1000000000 and value < 1000000000000 end
    local function update(result)
        session.status = "active"
        session.expiresAt, session.deadline = nil, nil
        if timestamp(result.expires_at) and timestamp(result.server_time) and result.expires_at >= result.server_time then
            session.expiresAt = result.expires_at
            session.deadline = os.clock() + result.expires_at - result.server_time
        end
    end
    update(first)
    session.remaining = function() return session.deadline and math.max(0, session.deadline - os.clock()) or nil end
    session.renew = function() return openRenewal(true) end
    session.cancel = function() session.cancelled = true; key = nil end
    session.canOpenBrowser = type(openurl) == "function"
    local function terminate(state)
        if session.cancelled or session.terminated then return end
        session.terminated, session.status = true, state
        if type(session.unload) == "function" then pcall(session.unload) end
        key = nil
        accessNotice(state, state == "expired")
    end
    stage("Ключ принят. Загрузка клиента...")
    local fetched, source = pcall(function() return game:HttpGet(CLIENT_URL) end)
    if not fetched or type(source) ~= "string" or #source == 0 then session.cancel(); error("Не удалось загрузить клиент", 0) end
    local program, compileError = loadstring(source)
    if not program then session.cancel(); error("Ошибка компиляции клиента: " .. tostring(compileError), 0) end
    -- Check again after download if the trusted lease ended while loading.
    if session.remaining() ~= nil and session.remaining() <= 0 then
        local result = verify()
        if not result then session.cancel(); accessNotice("unavailable", false); return false end
        if not result.valid then terminate(result.status == "expired" and "expired" or "inactive"); return false end
        update(result)
    end
    local old = env.OktanLicenseSession
    if type(old) == "table" and type(old.cancel) == "function" then old.cancel() end
    env.OktanLicenseSession = session
    stage("Запуск клиента...")
    local started, startError = pcall(program, session)
    if not started then session.cancel(); error(tostring(startError), 0) end
    task.spawn(function()
        local failures = 0
        while not session.cancelled and not session.terminated do
            local remaining = session.remaining()
            local delay = failures > 0 and math.min(30, 10 * failures) or (remaining and math.clamp(remaining, 1, 60) or 60)
            local untilTime = os.clock() + delay
            while not session.cancelled and os.clock() < untilTime do task.wait(math.min(5, untilTime - os.clock())) end
            if session.cancelled then return end
            local result = verify()
            if session.cancelled then return end
            if result then
                failures = 0
                if not result.valid then
                    local reason = result.status == "expired" and "expired" or result.status == "revoked" and "revoked" or result.status == "invalid" and "invalid" or "inactive"
                    terminate(reason); return
                end
                update(result)
            else
                failures += 1
                session.status = "verification_unavailable"
                -- An outage never sends the user shopping. End access after bounded retries.
                if failures >= 3 then terminate("unavailable"); return end
            end
        end
    end)
    return true
end
local finished = false
task.delay(20, function() if not finished and ui.Parent then stage("Ожидаем ответ сервера. Проверь консоль исполнителя.") end end)
local ok, result = pcall(boot)
finished = true
if ok and result == true then ui:Destroy()
elseif not ok then stage(tostring(result)); warn("[Oktan] Startup failed: " .. tostring(result)) end
