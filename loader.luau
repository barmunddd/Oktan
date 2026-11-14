-- Oktan authenticated loader. Keys stay in memory and are never sent to the renewal URL.
local RENEW_URL = "https://funpay.com/users/15095530/"
local CLIENT_URL = "https://raw.githubusercontent.com/barmunddd/Oktan/d5a798659de245c59daebef4fe3f1858b4c64dfb/client.luau"
local env = getgenv()
local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local function makeStartup(name)
    local function add(class,parent,properties)
        local object=Instance.new(class)
        for key,value in pairs(properties or {}) do object[key]=value end
        object.Parent=parent; return object
    end
    local screen=add("ScreenGui",playerGui,{Name=name,ResetOnSpawn=false,DisplayOrder=10000})
    local card=add("Frame",screen,{Name="StudioAccess",Size=UDim2.fromOffset(480,230),Position=UDim2.new(.5,-240,.22,0),BackgroundColor3=Color3.fromRGB(18,19,33),BackgroundTransparency=.04,BorderSizePixel=0})
    add("UICorner",card,{CornerRadius=UDim.new(0,22)})
    add("UIStroke",card,{Color=Color3.fromRGB(203,187,250),Transparency=.45,Thickness=1})
    local fit=add("UIScale",card,{Scale=1})
    pcall(function() card.AnchorPoint=Vector2.new(.5,0); card.Position=UDim2.new(.5,0,.22,0) end)
    pcall(function()
        local camera=workspace.CurrentCamera
        if camera then fit.Scale=math.min(1,(camera.ViewportSize.X-24)/480,(camera.ViewportSize.Y-24)/300) end
    end)
    local function text(value,position,size,color,fontSize)
        local object=add("TextLabel",card,{Text=value,Position=position,Size=size,BackgroundTransparency=1,TextColor3=color,TextSize=fontSize,TextWrapped=true,BorderSizePixel=0})
        pcall(function() object.Font=Enum.Font.Gotham; object.TextXAlignment=Enum.TextXAlignment.Left end)
        return object
    end
    local accent=Color3.fromRGB(203,187,250)
    local mark=add("Frame",card,{Position=UDim2.fromOffset(25,26),Size=UDim2.fromOffset(22,22),Rotation=-14,BackgroundTransparency=1,BorderSizePixel=0})
    add("UICorner",mark,{CornerRadius=UDim.new(0,7)}); add("UIStroke",mark,{Color=accent,Thickness=3})
    text("OKTAN",UDim2.fromOffset(60,18),UDim2.fromOffset(180,28),Color3.fromRGB(238,245,249),20)
    text("ATELIER / ACCESS",UDim2.fromOffset(61,45),UDim2.fromOffset(250,18),Color3.fromRGB(155,157,181),9)
    text("01 / CONNECT",UDim2.fromOffset(325,25),UDim2.fromOffset(130,20),accent,10)
    local status=text("Проверяем ключ…",UDim2.fromOffset(25,82),UDim2.fromOffset(430,60),Color3.fromRGB(227,237,244),14)
    local track=add("Frame",card,{Position=UDim2.fromOffset(25,160),Size=UDim2.new(1,-50,0,3),BackgroundColor3=Color3.fromRGB(34,46,54),BorderSizePixel=0,ClipsDescendants=true})
    add("UICorner",track,{CornerRadius=UDim.new(0,3)})
    local beam=add("Frame",track,{Size=UDim2.new(.24,0,1,0),BackgroundColor3=accent,BorderSizePixel=0})
    local foot=text("VERIFY     /     DOWNLOAD     /     LAUNCH",UDim2.fromOffset(25,183),UDim2.fromOffset(430,22),Color3.fromRGB(135,155,170),9)
    local animation
    pcall(function()
        animation=game:GetService("TweenService"):Create(beam,TweenInfo.new(1.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Position=UDim2.new(.76,0,0,0)})
        animation:Play()
    end)
    if screen.AncestryChanged then screen.AncestryChanged:Connect(function() if not screen.Parent and animation then animation:Cancel() end end) end
    local function arrival()
        pcall(function()
            local tweenService=game:GetService("TweenService")
            local portal=add("Frame",screen,{Name="ArrivalStar",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(1,1),BackgroundTransparency=1,BorderSizePixel=0})
            for index=0,7 do
                local ray=add("Frame",portal,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(index%2==0 and 90 or 48,2),Rotation=index*45,BackgroundColor3=accent,BackgroundTransparency=.35,BorderSizePixel=0})
                add("UIGradient",ray,{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.5,0),NumberSequenceKeypoint.new(1,1)})})
                tweenService:Create(ray,TweenInfo.new(.65,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(index%2==0 and 560 or 300,1),BackgroundTransparency=1}):Play()
            end
            tweenService:Create(card,TweenInfo.new(.45,Enum.EasingStyle.Quart,Enum.EasingDirection.In),{Position=UDim2.new(.5,0,.18,0),BackgroundTransparency=1}):Play()
            for _,child in ipairs(card:GetDescendants()) do
                if child:IsA("TextLabel") then tweenService:Create(child,TweenInfo.new(.35),{TextTransparency=1}):Play() end
            end
        end)
    end
    return screen,status,{card=card,track=track,beam=beam,foot=foot,arrival=arrival,stop=function() if animation then animation:Cancel() end end}
end
local ui,label,startup=makeStartup("OktanStartup")
local function stage(message)
    if label.Parent then label.Text=message end
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
    local networkProblem=startup.problem
    if not ui.Parent then ui,label,startup=makeStartup("OktanRenewal") end
    startup.stop(); startup.track.Visible=false
    startup.card.Size=UDim2.fromOffset(480,300)
    startup.foot.Visible=false
    label.Size=UDim2.fromOffset(430,118)
    label.TextColor3=state=="unavailable" and Color3.fromRGB(227,237,244) or Color3.fromRGB(255,191,145)
    local titles={expired="Срок ключа истёк",revoked="Ключ отозван",invalid="Ключ не найден",inactive="Ключ больше не действует",unavailable="Не удалось подтвердить подписку"}
    label.Text=(titles[state] or titles.inactive).."\n"..RENEW_URL.."\nКлюч и данные аккаунта не передаются в FunPay."
    if state=="unavailable" and networkProblem then label.Text=(titles.unavailable).."\n"..networkProblem.."\nПовтори запуск позже. Ключ не признан недействительным." end
    if automatic and state=="expired" then
        local last=env.OktanRenewalOpenedAt
        if type(last)~="number" or os.clock()-last>60 then
            env.OktanRenewalOpenedAt=os.clock()
            label.Text ..= "\n"..openRenewal(false)
        end
    end
    for index,name in ipairs({"FunPay / Copy link","Закрыть"}) do
        local control=Instance.new("TextButton")
        control.Size,control.Position=UDim2.fromOffset(208,38),UDim2.fromOffset(25+(index-1)*222,238)
        control.Text,control.Parent=name,startup.card
        control.BackgroundColor3,control.TextColor3,control.TextSize,control.BorderSizePixel=Color3.fromRGB(25,38,44),Color3.fromRGB(210,238,165),13,0
        local corner=Instance.new("UICorner"); corner.CornerRadius,corner.Parent=UDim.new(0,12),control
        control.Activated:Connect(function()
            if index==1 then label.Text=(titles[state] or titles.inactive).."\n"..openRenewal(true) else startup.stop(); ui:Destroy() end
        end)
    end
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
        local completed,closed,ok,response=false,false,false,nil
        local payload={Url="https://oktandev.pythonanywhere.com/verify",Method="POST",Headers={["Content-Type"]="application/json"},Body=http:JSONEncode({key=key}),Timeout=12}
        local worker=task.spawn(function()
            local sent,result=pcall(send,payload)
            if not closed then ok,response,completed=sent,result,true end
        end)
        local deadline=os.clock()+15
        while not completed and key and os.clock()<deadline do task.wait(.05) end
        closed=true
        if not completed then
            if type(task.cancel)=="function" and worker then pcall(task.cancel,worker) end
            startup.problem="Сервер не ответил за 15 секунд."
            return nil
        end
        if not ok or type(response)~="table" then startup.problem="Ошибка соединения с сервером проверки."; return nil end
        if response.StatusCode~=200 then startup.problem="Сервер проверки ответил HTTP "..tostring(response.StatusCode).."."; return nil end
        local decoded, result = pcall(function() return http:JSONDecode(response.Body) end)
        if not decoded or type(result) ~= "table" or type(result.valid) ~= "boolean" then startup.problem="Некорректный ответ сервера проверки."; return nil end
        if result.valid and result.status and result.status ~= "active" then return nil end
        startup.problem=nil
        return result
    end
    local first = verify()
    if not first then key = nil; accessNotice("unavailable", false); return false end
    if not first.valid then
        local reason = first.status == "expired" and "expired" or first.status == "revoked" and "revoked" or first.status == "invalid" and "invalid" or "inactive"
        key = nil; accessNotice(reason, reason == "expired"); return false
    end
    local session = { status = "active", renewUrl = RENEW_URL, cancelled = false, terminated = false }
    session.presence = function(op, fields)
        if not key or session.cancelled or session.terminated then return nil, 401 end
        local body={key=key,op=op}
        for _,name in ipairs({"username","user_id","place_id","job_id","label","friends"}) do body[name]=fields and fields[name] end
        local ok,response=pcall(send,{Url="https://oktandev.pythonanywhere.com/presence",Method="POST",Headers={["Content-Type"]="application/json"},Body=http:JSONEncode(body),Timeout=10})
        if not ok or type(response)~="table" then return nil,0 end
        if response.StatusCode~=200 then return nil,response.StatusCode end
        local parsed,result=pcall(function() return http:JSONDecode(response.Body) end)
        if not parsed or type(result)~="table" or result.ok~=true then return nil,0 end
        return result,200
    end
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
    stage("Ключ принят. Загрузка клиента…")
    startup.foot.Text="VERIFIED     /     DOWNLOADING"
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
    stage("Запуск клиента…")
    startup.foot.Text="VERIFIED     /     DOWNLOADED     /     LAUNCHING"
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
if ok and result == true then
    startup.stop(); startup.beam.Position=UDim2.new(0,0,0,0); startup.beam.Size=UDim2.new(1,0,1,0)
    stage("Готово. Приятной игры!"); startup.foot.Text="ACCESS VERIFIED / CLIENT READY"
    startup.arrival()
    local closing=ui; task.delay(.75,function() closing:Destroy() end)
elseif not ok then startup.stop(); label.TextColor3=Color3.fromRGB(255,165,165); startup.foot.Text="STARTUP FAILED"; stage(tostring(result)); warn("[Oktan] Startup failed: " .. tostring(result)) end
