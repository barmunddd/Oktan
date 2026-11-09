-- Oktan 9. Full standalone source. Paste all of this file into Executor.
-- Configuration files are relative to the executor's filesystem workspace.
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local player = assert(Players.LocalPlayer, "Run in the Roblox client")
local playerGui = player:WaitForChild("PlayerGui")
local guiName = "OktanPanel"
local existing = playerGui:FindFirstChild(guiName) or playerGui:FindFirstChild("DeltaClientPanel")
if existing then
    local signal = existing:FindFirstChild("Unload")
    if signal and signal:IsA("BindableEvent") then
        signal:Fire()
        local deadline = os.clock() + 3
        repeat task.wait() until existing.Parent == nil or os.clock() >= deadline
    end
    assert(existing.Parent == nil, "Unload the previous client first")
end

-- Every exposed setting has its own description, bounds and keyboard actions.
local definitions = {
    { "motion", true, "Motion", "Плавное появление меню и переливы выбранных разделов.", "Настройки" },
    { "killFx", true, "Soul FX", "Поднимает призрачный силуэт при подтверждённом вашем убийстве. Требуется информация об убийце от игры.", "Настройки" },
    { "crossStyle", 1, "Cross Style", "1 — крестик; 2 — точка; 3 — крестик с точкой.", "Камера", 1, 3 },
    { "crossWidth", 2, "Cross Width", "Толщина линий и размер точки в пикселях.", "Камера", 1, 5 },
    { "noLeaves", false, "No Leaves", "Скрывает распознанные части листвы. Стволы и коллизия остаются.", "Мир" },
    { "noGrass", false, "No Grass", "Скрывает распознанные модели травы. Не влияет на коллизию.", "Мир" },
    { "corpseEsp", false, "Corpses", "Показывать распознанные трупы. Требует проверки структуры игры.", "ESP" },
    { "itemEsp", false, "Items", "Показывать предметы в распознанных папках лута.", "ESP" },
    { "lootThrough", false, "Loot Through Walls", "Показывать лут и трупы сквозь стены.", "ESP" },
    { "lootRange", 250, "Loot Distance", "Дальность трупов и предметов в studs.", "ESP", 25, 1500 },
    { "lootTextSize", 13, "Loot Text Size", "Размер подписей лута и трупов.", "ESP", 10, 20 },
    { "noVisor", false, "NoVisor", "Скрывает распознанную маску визора. Не меняет состояние или защиту шлема.", "Камера" },
    { "cameraFov", false, "FOV Override", "Применяет выбранное поле зрения. Удерживаемый Zoom имеет приоритет.", "Камера" },
    { "cameraFovValue", 90, "Camera FOV", "Поле зрения камеры в градусах: больше — шире обзор.", "Камера", 50, 120 },
    { "viewmodel", false, "Viewmodel", "Смещает распознанную модель рук и оружия в камере.", "Камера" },
    { "vmX", 0, "Offset X", "Смещение оружия вправо/влево, в сотых долях stud.", "Камера", -200, 200 },
    { "vmY", 0, "Offset Y", "Смещение оружия вверх/вниз, в сотых долях stud.", "Камера", -200, 200 },
    { "vmZ", 0, "Offset Z", "Отдаление/приближение модели оружия, в сотых долях stud.", "Камера", -200, 200 },
    { "sticky", true, "Sticky Target", "Удерживать выбранную цель внутри круга.", "Наведение" },
    { "noFog", false, "No Fog", "Убрать туман и атмосферную дымку.", "Мир" },
    { "bubbles", true, "Bubbles", "Плавные переливы на фоне меню.", "Настройки" },
    { "snow", true, "Snow", "Снежинки в меню.", "Настройки" },
    { "snowDrifts", true, "Snowdrifts", "Анимированный снег у нижнего края меню.", "Настройки" },
    { "friendHats", true, "Friend Hats", "Зимние шапки на добавленных друзьях.", "Настройки" },
    { "espFps", 30, "ESP FPS", "Частота отрисовки. Меньше — ниже нагрузка.", "ESP", 15, 60 },
    { "adaptiveText", true, "Adaptive Text", "Уменьшает подписи у далёких персонажей.", "ESP" },
    { "menuHue", 202, "Menu Hue", "Оттенок акцентов и стеклянной поверхности меню.", "Настройки", 0, 359 },
    { "menuSaturation", 0, "Menu Saturation", "Насыщенность акцентного цвета.", "Настройки", 0, 100 },
    { "menuValue", 95, "Menu Brightness", "Яркость акцентных элементов.", "Настройки", 20, 100 },
    { "espSaturation", 65, "ESP Saturation", "Насыщенность подписей, рамок, скелета и подсветки.", "ESP", 0, 100 },
    { "espValue", 100, "ESP Brightness", "Яркость подписей, рамок, скелета и подсветки.", "ESP", 20, 100 },
    { "fovHue", 190, "FOV Hue", "Цвет круга области наведения.", "Наведение", 0, 359 },
    { "fovSaturation", 65, "FOV Saturation", "Насыщенность круга области наведения.", "Наведение", 0, 100 },
    { "fovValue", 100, "FOV Brightness", "Яркость круга области наведения.", "Наведение", 20, 100 },
    { "weapon", false, "Weapon", "Оружие в руках: название под ногами.", "ESP" },
    { "inspectRadius", 160, "Inspect Radius", "Для проверки инвентаря выбирается ближайший к центру экрана игрок внутри этого радиуса.", "Бинды", 30, 400 },
    { "island", true, "Dynamic Island", "Компактная панель активных биндов.", "Бинды" },
    { "islandY", 74, "Island Offset", "Отступ панели от верхней границы экрана в пикселях.", "Бинды", 0, 300 },
    { "aim", false, "Aim Assist", "Включите и удерживайте клавишу наведения при закрытом меню.", "Наведение" },
    { "aimPlayers", true, "Players", "Разрешает выбирать персонажей других игроков для наведения.", "Наведение" },
    { "aimDummies", false, "Dummies", "Выбирает модели с Humanoid из папки workspace.DeltaQATargets в тестовом месте.", "Наведение" },
    { "team", true, "Team Check", "Исключает игроков с той же Roblox Team.", "Наведение" },
    { "wall", true, "Wall Check", "Перед наведением проверяет луч от камеры до выбранной части тела.", "Наведение" },
    { "head", true, "Head Aim", "Включено — Head.", "Наведение" },
    { "ring", true, "FOV Circle", "Показывает радиус выбора цели вокруг центра экрана при активном наведении и закрытом меню.", "Наведение" },
    { "radius", 140, "FOV Radius", "Расстояние от центра экрана, внутри которого выбирается цель.", "Наведение", 25, 400 },
    { "smooth", 12, "Aim Speed", "Большое значение быстрее поворачивает камеру.", "Наведение", 2, 45 },
    { "esp", false, "ESP", "Общий переключатель всех маркеров персонажей.", "ESP" },
    { "espPlayers", true, "Players", "Отображает ESP на персонажах других игроков.", "ESP" },
    { "espDummies", false, "NPCs", "Показывает живых NPC с Humanoid в загруженной части мира.", "ESP" },
    { "names", false, "Name", "Показывает имя игрока над персонажем.", "ESP" },
    { "health", false, "Health", "Показывает текущее значение Humanoid.Health рядом с именем.", "ESP" },
    { "distance", false, "Distance", "Показывает расстояние от камеры до цели в studs — единицах Roblox.", "ESP" },
    { "chams", true, "Chams", "Заливает модель полупрозрачным цветом и выделяет её контур.", "ESP" },
    { "through", false, "Through Walls", "Разрешает показывать маркеры сквозь стены.", "ESP" },
    { "boxes", false, "Box", "Рисует прямоугольник вокруг проекции габаритов персонажа.", "ESP" },
    { "corners", false, "Corner Box", "Отображает только углы рамки.", "ESP" },
    { "skeleton", false, "Skeleton", "Соединяет части тела по суставам Motor6D.", "ESP" },
    { "tracers", false, "Tracers", "Проводит линию от нижнего центра экрана до корневой части персонажа.", "ESP" },
    { "healthBar", false, "Health Bar", "Рисует слева от рамки шкалу текущего здоровья относительно максимального.", "ESP" },
    { "range", 500, "Max Distance", "Максимальное расстояние для всех видов ESP.", "ESP", 25, 2000 },
    { "espHue", 235, "ESP Hue", "Выбирает оттенок всех маркеров по цветовому кругу от 0 до 359 градусов.", "ESP", 0, 359 },
    { "espOpacity", 80, "Line Opacity", "Задаёт видимость рамок, скелета и трассеров.", "ESP", 10, 100 },
    { "fillOpacity", 18, "Fill Opacity", "Непрозрачность внутренней заливки подсветки.", "ESP", 0, 100 },
    { "lineWidth", 1, "Line Width", "Толщина рамок, скелета и трассеров.", "ESP", 1, 4 },
    { "textSize", 13, "Text Size", "Размер имени, здоровья и расстояния над персонажем.", "ESP", 10, 22 },
    { "bright", false, "Fullbright", "Локально усиливает освещение и отключает глобальные тени.", "Мир" },
    { "clock", false, "Time Override", "Применяет выбранный час локально.", "Мир" },
    { "hour", 12, "Time", "Время суток от 0 до 23.", "Мир", 0, 23 },
    { "zoom", false, "Zoom", "Включите и удерживайте назначенную клавишу зума при закрытом меню.", "Камера" },
    { "zoomFov", 30, "Zoom FOV", "Меньшее значение сильнее приближает изображение.", "Камера", 15, 70 },
    { "crosshair", false, "Crosshair", "Показывает четырёхлучевой прицел по центру экрана при закрытом меню.", "Камера" },
    { "length", 8, "Length", "Длина каждого из четырёх лучей прицела.", "Камера", 2, 24 },
    { "gap", 4, "Gap", "Свободное пространство между центром экрана и лучами прицела.", "Камера", 0, 16 },
    { "glass", 6, "Glass", "Настраивает прозрачность поверхности меню.", "Настройки", 0, 65 },
    { "blur", 8, "Blur", "Сила отдельного BlurEffect при открытом меню.", "Настройки", 0, 24 },
}
local friendNames = {}
local function isFriend(owner)
    return owner ~= nil and friendNames[string.lower(owner.Name)] == true
end
local defaults, schema, settings = {}, {}, {}
for _, definition in ipairs(definitions) do
    local key = definition[1]
    defaults[key] = definition[2]
    schema[key] = definition
    settings[key] = definition[2]
end
local bindings = { menu = "Insert", aim = "MouseButton2", zoom = "LeftAlt", inspect = "F4" }
local allowedActions = { menu = true, inspect = true, containerDump = true }
for key, value in pairs(defaults) do
    if type(value) == "boolean" then
        allowedActions[key] = true
    else
        allowedActions[key .. "Minus"] = true
        allowedActions[key .. "Plus"] = true
    end
end
local allowedKeys = { MouseButton2 = true, MouseButton3 = true }
for _, key in ipairs(Enum.KeyCode:GetEnumItems()) do
    if key ~= Enum.KeyCode.Unknown and key ~= Enum.KeyCode.Escape and key ~= Enum.KeyCode.Backspace then
        allowedKeys[key.Name] = true
    end
end
local legacyPrefix = "DeltaClient-" .. tostring(game.PlaceId) .. "-"
local filePrefix = "Oktan-shared-"
local canSave = type(writefile) == "function" and type(readfile) == "function"
local revision, dirty, lastChange, saving = 0, false, 0, false
local configStatus = canSave and "Конфиг готов" or "Файловые функции недоступны"
local function validateConfig(data)
    if type(data) ~= "table" or (data.version ~= 2 and data.version ~= 3 and data.version ~= 4 and data.version ~= 5) or type(data.revision) ~= "number"
        or data.revision < 0 or data.revision % 1 ~= 0 or data.revision > 1e12
        or type(data.settings) ~= "table" or type(data.bindings) ~= "table" then return nil end
    local validated = table.clone(defaults)
    for key, definition in pairs(schema) do
        local value = data.settings[key]
        if value ~= nil then
            if type(value) ~= type(definition[2]) then return nil end
            if type(value) == "number" then
                if value ~= value or math.abs(value) == math.huge then return nil end
                value = math.clamp(math.round(value), definition[6], definition[7])
            end
            validated[key] = value
        end
    end
    if data.version < 4 and validated.menuHue == 202 and validated.menuSaturation == 50 then
        validated.menuSaturation = 0
        validated.glass = 6
    end
    local savedBindings = table.clone(data.bindings)
    if data.version < 5 then
        savedBindings.aim = savedBindings.aimHold or savedBindings.aim
        savedBindings.zoom = savedBindings.zoomHold or savedBindings.zoom
    end
    local validatedFriends = {}
    if type(data.friends) == "table" then
        for name, enabled in pairs(data.friends) do
            if type(name) == "string" and enabled == true and #name >= 3 and #name <= 20 and name:match("^[%w_]+$") then
                validatedFriends[string.lower(name)] = true
            end
        end
    end
    local validatedBindings, used = {}, {}
    for action in pairs(allowedActions) do
        local key = savedBindings[action]
        if key ~= nil then
            if type(key) ~= "string" or not allowedKeys[key] or used[key] then return nil end
            validatedBindings[action], used[key] = key, true
        end
    end
    -- The floating OKTAN button always opens the menu even without a menu bind.
    if data.version == 2 and not used.F4 then validatedBindings.inspect = "F4" end
    if data.version < 5 then
        if not validatedBindings.aim and not used.MouseButton2 then validatedBindings.aim = "MouseButton2" end
        if not validatedBindings.zoom and not used.LeftAlt then validatedBindings.zoom = "LeftAlt" end
    end
    return { settings = validated, bindings = validatedBindings, friends = validatedFriends, revision = data.revision }
end
if canSave then
    local function readConfig(prefix)
        local newest
        for _, slot in ipairs({ "a", "b" }) do
            local ok, data = pcall(function()
                return validateConfig(HttpService:JSONDecode(readfile(prefix .. slot .. ".json")))
            end)
            if ok and data and (not newest or data.revision > newest.revision) then newest = data end
        end
        return newest
    end
    local newest = readConfig(filePrefix)
    if not newest then
        newest = readConfig("Oktan-" .. tostring(game.PlaceId) .. "-") or readConfig(legacyPrefix)
        -- Migrate the newest local Oktan place config when entering a different place first.
        if type(listfiles) == "function" then
            local ok, files = pcall(listfiles, "")
            if ok then
                for _, path in ipairs(files) do
                    local prefix = path:match("^(.*Oktan%-%d+%-)[ab]%.json$")
                    local candidate = prefix and readConfig(prefix)
                    if candidate and (not newest or candidate.revision > newest.revision) then newest = candidate end
                end
            end
        end
        if newest then dirty, lastChange = true, os.clock() end
    end
    if newest then
        settings, bindings, revision = newest.settings, newest.bindings, newest.revision
        friendNames = newest.friends
        configStatus = "Конфиг загружен"
    else
        dirty, lastChange = true, os.clock()
    end
end
local changeSerial = 0
local function changed()
    dirty, lastChange = true, os.clock()
    changeSerial += 1
    configStatus = canSave and "Ожидает сохранения…" or "Настройки только в этой сессии"
end
local function saveConfig()
    if not canSave or saving or not dirty then return end
    saving = true
    local serial = changeSerial
    local nextRevision = revision + 1
    local ok = pcall(function()
        local persistedSettings = {}
        for key in pairs(schema) do persistedSettings[key] = settings[key] end
        local content = HttpService:JSONEncode({
            version = 5, revision = nextRevision,
            settings = persistedSettings, bindings = bindings, friends = friendNames,
        })
        -- Alternate slots preserve the previous valid save if a write is interrupted.
        writefile(filePrefix .. (nextRevision % 2 == 0 and "a" or "b") .. ".json", content)
    end)
    saving = false
    if ok then
        revision = nextRevision
        dirty = serial ~= changeSerial
        configStatus = dirty and "Ожидает сохранения…" or "Конфиг сохранён"
    else
        configStatus = "Ошибка записи — повтор через 5 секунд"
        lastChange = os.clock() + 4.2
    end
end

local palette = {
    background = Color3.fromRGB(10, 10, 12), panel = Color3.fromRGB(22, 22, 25),
    control = Color3.fromRGB(34, 34, 38), edge = Color3.fromRGB(135, 135, 142),
    accent = Color3.fromRGB(238, 238, 243), text = Color3.fromRGB(240, 240, 243),
    muted = Color3.fromRGB(165, 165, 174),
}
local function create(class, parent, properties)
    local object = Instance.new(class)
    for key, value in pairs(properties or {}) do object[key] = value end
    object.Parent = parent
    return object
end
local connections = {}
local cleanups = {}
local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end
if player.OnTeleport then connect(player.OnTeleport, function() saveConfig() end) end
local function stroke(parent, color, thickness)
    return create("UIStroke", parent, {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = color or palette.edge, Thickness = thickness or 1, Transparency = 0.55,
    })
end
local function rounded(parent, radius)
    create("UICorner", parent, { CornerRadius = UDim.new(0, radius or 10) })
end
local function text(parent, value, props, class)
    local properties = {
        BackgroundTransparency = 1, BorderSizePixel = 0, Font = Enum.Font.Gotham,
        Text = value, AutoLocalize = false, RichText = false, TextColor3 = palette.text, TextSize = 13,
    }
    for key, prop in pairs(props or {}) do properties[key] = prop end
    return create(class or "TextLabel", parent, properties)
end
local gui = create("ScreenGui", playerGui, {
    Name = guiName, AutoLocalize = false, DisplayOrder = 85, IgnoreGuiInset = true,
    ScreenInsets = Enum.ScreenInsets.None, ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
local unloadSignal = create("BindableEvent", gui, { Name = "Unload" })
local overlay = create("Frame", gui, { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) })
local ring = create("Frame", overlay, {
    AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
    Position = UDim2.fromScale(0.5, 0.5), Visible = false,
})
rounded(ring, 1000)
local ringStroke = stroke(ring, palette.accent)
ringStroke.Transparency = 0.25
local crosshair = {}
for index = 1, 4 do
    crosshair[index] = create("Frame", overlay, {
        AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = palette.text,
        BorderSizePixel = 0, Visible = false,
    })
end
crosshair.dot = create("Frame", overlay, { BackgroundColor3 = palette.text, BorderSizePixel = 0, Visible = false })
rounded(crosshair.dot, 20)
local menu = create("CanvasGroup", gui, {
    AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = palette.background,
    BorderSizePixel = 0, Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(920, 610),
})
rounded(menu, 22)
stroke(menu, palette.accent)
create("UIGradient", menu, {
    Color = ColorSequence.new(Color3.fromRGB(235, 235, 240), Color3.fromRGB(130, 130, 140)),
    Rotation = 35,
})
local scale = create("UIScale", menu, { Scale = 1 })
local blurEffect = create("BlurEffect", Lighting, { Name = "DeltaGlass", Size = 0 })
local title = text(menu, "OKTAN", {
    Position = UDim2.fromOffset(24, 15), Size = UDim2.fromOffset(480, 32),
    TextSize = 23, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
})
text(menu, "OKTAN 09   /   MOTION", {
    Position = UDim2.fromOffset(25, 48), Size = UDim2.fromOffset(450, 18),
    TextColor3 = palette.muted, TextXAlignment = Enum.TextXAlignment.Left,
})
local function button(parent, label, position, size)
    local result = text(parent, label, {
        Position = position, Size = size, BackgroundTransparency = 0.45,
        BackgroundColor3 = palette.control, AutoButtonColor = true,
    }, "TextButton")
    rounded(result, 8)
    stroke(result)
    return result
end
local hide = button(menu, "Hide", UDim2.new(1, -132, 0, 24), UDim2.fromOffset(108, 30))
hide.Modal = true
local reopen = button(gui, "OKTAN", UDim2.new(1, -118, 0, 55), UDim2.fromOffset(100, 30))
reopen.Visible = false
local tooltip = text(gui, "", {
    BackgroundTransparency = 0.04, BackgroundColor3 = palette.background,
    Size = UDim2.fromOffset(360, 148), TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    ZIndex = 100, Visible = false,
})
rounded(tooltip, 12)
stroke(tooltip, palette.accent)
create("UIPadding", tooltip, {
    PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14),
    PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12),
})
local hovered
local function describe(object, description)
    connect(object.MouseEnter, function()
        hovered = object
        tooltip.Text = description
        tooltip.Size = UDim2.fromOffset(360, math.clamp(math.ceil(utf8.len(description) / 40) * 18 + 28, 64, 190))
        tooltip.Visible = menu.Visible
    end)
    connect(object.MouseLeave, function()
        if hovered == object then hovered = nil; tooltip.Visible = false end
    end)
end
local focused = true
local capture, activeSlider
local inspectAction
local function setMenu(visible)
    menu.Visible = visible
    if visible and settings.motion then
        menu.GroupTransparency = 0.65
        TweenService:Create(menu, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { GroupTransparency = 0 }):Play()
    else menu.GroupTransparency = 0 end
    reopen.Visible = not visible
    tooltip.Visible = false
    hovered = nil
    capture, activeSlider = nil, nil
end
connect(hide.Activated, function() setMenu(false) end)
connect(reopen.Activated, function() setMenu(true) end)
describe(hide, "Скрывает меню. Открыть его можно назначенной клавишей или кнопкой OKTAN справа на экране.")

local status = text(menu, "", {
    Position = UDim2.fromOffset(24, 575), Size = UDim2.new(1, -48, 0, 20),
    TextSize = 11, TextColor3 = palette.muted, TextXAlignment = Enum.TextXAlignment.Left,
})
local displayNames = {
    ["Наведение"] = "Aim",
    ["ESP"] = "ESP",
    ["Мир"] = "World",
    ["Камера"] = "Camera",
    ["Бинды"] = "Keybinds",
    ["Настройки"] = "Settings",
    ["Цели и проверки"] = "Targets",
    ["Область и плавность"] = "FOV & Aim",
    ["Общее"] = "General",
    ["Подписи"] = "Labels",
    ["Геометрия"] = "Visuals",
    ["Цвет и оформление"] = "Appearance",
    ["Освещение"] = "Lighting",
    ["Зум"] = "Zoom",
    ["Прицел"] = "Crosshair",
    ["Инвентарь"] = "Inventory",
    ["Управление"] = "Controls",
    ["Назначения функций"] = "Bindings",
    ["Оформление"] = "Theme",
    ["Клиент"] = "Client",
}
local pages, tabButtons = {}, {}
for index, name in ipairs({ "Наведение", "ESP", "Мир", "Камера", "Бинды", "Настройки" }) do
    local tabButton = button(menu, displayNames[name] or name, UDim2.fromOffset(20, 91 + (index - 1) * 49), UDim2.fromOffset(139, 39))
    local page = create("ScrollingFrame", menu, {
        Position = UDim2.fromOffset(177, 88), Size = UDim2.fromOffset(721, 470),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3, ScrollBarImageColor3 = palette.accent,
        Visible = index == 1,
    })
    create("UIListLayout", page, { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
    create("UIPadding", page, { PaddingLeft = UDim.new(0, 3), PaddingTop = UDim.new(0, 3), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 4) })
    pages[name], tabButtons[name] = page, tabButton
    connect(tabButton.Activated, function()
        for otherName, otherPage in pairs(pages) do
            local selected = otherName == name
            otherPage.Visible = selected
            tabButtons[otherName].TextColor3 = selected and palette.accent or palette.muted
        end
        capture = nil
        tooltip.Visible = false
    end)
    tabButton.TextColor3 = index == 1 and palette.accent or palette.muted
end
local espRows = {}
local controlRows, roleRows, sliderFills = {}, {}, {}
local refreshers = {}
local function refreshAll()
    for _, refresh in ipairs(refreshers) do refresh() end
end
local function setValue(key, value)
    settings[key] = value
    changed()
    refreshAll()
end
local bindDialog = create("Frame", menu, {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(440, 180), BackgroundColor3 = Color3.fromRGB(18, 23, 32),
    BackgroundTransparency = 0, BorderSizePixel = 0, Visible = false, ZIndex = 50,
})
rounded(bindDialog, 16)
stroke(bindDialog)
local bindCaption = text(bindDialog, "", {
    Position = UDim2.fromOffset(20, 14), Size = UDim2.fromOffset(400, 30),
    TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 51,
})
local bindHint = text(bindDialog, "Нажмите клавишу • Esc — отмена\nBackspace — удалить назначение", {
    Position = UDim2.fromOffset(20, 50), Size = UDim2.fromOffset(400, 44),
    TextSize = 13, TextColor3 = palette.muted, ZIndex = 51,
})
local bindDown = button(bindDialog, "Decrease", UDim2.fromOffset(20, 105), UDim2.fromOffset(190, 34))
local bindUp = button(bindDialog, "Increase", UDim2.fromOffset(230, 105), UDim2.fromOffset(190, 34))
bindDown.ZIndex, bindUp.ZIndex = 51, 51
local pendingNumeric
local function beginBind(action)
    pendingNumeric = schema[action] and type(settings[action]) == "number" and action or nil
    if pendingNumeric then capture = nil else capture = action end
    bindCaption.Text = (schema[action] and schema[action][3] or action) .. " · Bind"
    bindHint.Text = pendingNumeric and "Выберите действие: уменьшить или увеличить.\nEsc — отмена" or "Нажмите клавишу • Esc — отмена\nBackspace — удалить назначение"
    bindDialog.Visible = true
    bindDown.Visible, bindUp.Visible = pendingNumeric ~= nil, pendingNumeric ~= nil
    tooltip.Visible = false
    refreshAll()
end
connect(bindDown.Activated, function()
    if pendingNumeric then capture = pendingNumeric .. "Minus"; pendingNumeric = nil end
    bindHint.Text = "Нажмите клавишу • Esc — отмена\nBackspace — удалить назначение"
    bindDown.Visible, bindUp.Visible = false, false
    refreshAll()
end)
connect(bindUp.Activated, function()
    if pendingNumeric then capture = pendingNumeric .. "Plus"; pendingNumeric = nil end
    bindHint.Text = "Нажмите клавишу • Esc — отмена\nBackspace — удалить назначение"
    bindDown.Visible, bindUp.Visible = false, false
    refreshAll()
end)
table.insert(refreshers, function()
    if not capture and not pendingNumeric then bindDialog.Visible = false end
end)
local function middleBind(object, action, transientConnect)
    (transientConnect or connect)(object.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton3 then
            task.defer(function() if menu.Visible then beginBind(action) end end)
        end
    end)
end

local function bindButton(parent, action, position, size, prefix)
    local bind = button(parent, "", position, size)
    bind.TextSize = 11
    local function refresh()
        local key = bindings[action] or "—"
        bind.Text = (prefix or "") .. (capture == action and "…" or key)
    end
    table.insert(refreshers, refresh)
    connect(bind.Activated, function()
        beginBind(action)
    end)
    connect(bind.MouseButton2Click, function()
        bindings[action] = nil
        capture = nil
        changed()
        refreshAll()
    end)
    describe(bind, "Нажмите и выберите клавишу. Esc — отмена. Backspace или ПКМ — удалить.")
    refresh()
    return bind
end
local function row(parent, order, height)
    local frame = create("Frame", parent, {
        BackgroundColor3 = palette.panel, BackgroundTransparency = 0.14,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, height),
        LayoutOrder = order,
    })
    rounded(frame, 13)
    stroke(frame)
    return frame
end
for index, definition in ipairs(definitions) do
    local key, initial, label, description, pageName = table.unpack(definition)
    local numeric = type(initial) == "number"
    local frame = row(pages[pageName], index, numeric and 84 or 54)
    table.insert(controlRows, { frame = frame, key = key, page = pageName })
    local labelObject = text(frame, label, {
        Position = UDim2.fromOffset(15, 8), Size = UDim2.new(1, numeric and -90 or -90, 0, 36),
        TextXAlignment = Enum.TextXAlignment.Left, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd,
    })
    middleBind(frame, key)
    middleBind(labelObject, key)
    describe(frame, description)
    describe(labelObject, description)
    if not numeric then
        local switch = button(frame, "", UDim2.new(1, -70, 0, 13), UDim2.fromOffset(55, 27))
        switch.AutoButtonColor = false
        switch:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(1, 0)
        switch.BackgroundTransparency = 0
        local knob = create("Frame", switch, {
            Size = UDim2.fromOffset(19, 19), Position = UDim2.fromOffset(4, 4),
            BackgroundColor3 = Color3.fromRGB(245, 245, 247), BorderSizePixel = 0,
        })
        rounded(knob, 20)
        local switchTween, knobTween, previousValue
        connect(switch.Activated, function() setValue(key, not settings[key]) end)
        describe(switch, description)
        table.insert(refreshers, function()
            switch.Text = ""
            local value = settings[key]
            if previousValue == value then return end
            previousValue = value
            if switchTween then switchTween:Cancel(); knobTween:Cancel() end
            local timing = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            switchTween = TweenService:Create(switch, timing, {
                BackgroundColor3 = value and Color3.fromRGB(40, 157, 96) or Color3.fromRGB(170, 57, 64),
            })
            knobTween = TweenService:Create(knob, timing, { Position = UDim2.fromOffset(value and 32 or 4, 4) })
            switchTween:Play()
            knobTween:Play()
        end)
    else
        local minimum, maximum = definition[6], definition[7]
        local valueText = text(frame, "", { Position = UDim2.new(1, -63, 0, 10), Size = UDim2.fromOffset(48, 27) })
        local track = button(frame, "", UDim2.new(0, 16, 0, 57), UDim2.new(1, -32, 0, 12))
        track.AutoButtonColor = false
        local fill = create("Frame", track, {
            BackgroundColor3 = palette.accent, BorderSizePixel = 0,
            Size = UDim2.fromScale(0, 1),
        })
        rounded(fill, 6)
        table.insert(sliderFills, fill)
        describe(track, description)
        local function move(x)
            local fraction = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
            setValue(key, math.round(minimum + fraction * (maximum - minimum)))
        end
        connect(track.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                activeSlider = move
                move(input.Position.X)
            end
        end)
        table.insert(refreshers, function()
            fill.Size = UDim2.fromScale((settings[key] - minimum) / (maximum - minimum), 1)
            valueText.Text = tostring(settings[key])
        end)
    end
end
for index, entry in ipairs({
    { "menu", "Menu" }, { "inspect", "Inspect" }, { "containerDump", "Export Container" },
}) do
    local frame = row(pages["Бинды"], 100 + index, 54)
    table.insert(roleRows, frame)
    text(frame, entry[2], {
        Position = UDim2.fromOffset(15, 8), Size = UDim2.new(1, -160, 0, 36),
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    bindButton(frame, entry[1], UDim2.new(1, -138, 0, 13), UDim2.fromOffset(122, 27))
end
local actionsRow = row(pages["Настройки"], 110, 58)
local saveButton = button(actionsRow, "Save", UDim2.fromOffset(12, 12), UDim2.fromOffset(155, 32))
local resetButton = button(actionsRow, "Reset", UDim2.fromOffset(180, 12), UDim2.fromOffset(155, 32))
local unloadButton = button(actionsRow, "Unload", UDim2.fromOffset(348, 12), UDim2.fromOffset(155, 32))
connect(saveButton.Activated, function() changed(); task.spawn(saveConfig) end)
connect(resetButton.Activated, function()
    settings = table.clone(defaults)
    bindings = { menu = "Insert", aim = "MouseButton2", zoom = "LeftAlt", inspect = "F4" }
    capture = nil
    changed()
    refreshAll()
end)
connect(unloadButton.Activated, function() unloadSignal:Fire() end)
describe(saveButton, "Сохраняет настройки и клавиши в workspace исполнителя. Обычно сохранение происходит автоматически через секунду после изменения.")
describe(resetButton, "Возвращает все настройки и клавиши к исходным значениям. Новые значения автоматически сохранятся.")
describe(unloadButton, "Сохраняет конфиг, удаляет интерфейс и ESP, отключает обработчики и возвращает изменённые параметры освещения и камеры.")
local raidReport = button(actionsRow, "Export Debug", UDim2.fromOffset(516, 12), UDim2.fromOffset(184, 32))
describe(raidReport, "Если Kills показывает прочерк, сохраните структуру рейдовых данных для подключения счётчика.")
connect(raidReport.Activated, function()
    if type(writefile) ~= "function" then configStatus = "Запись файлов недоступна"; return end
    local ok = pcall(function()
        local report = { placeId = game.PlaceId, records = {} }
        local records = game:GetService("ReplicatedStorage"):FindFirstChild("Players")
        local record = records and records:FindFirstChild(player.Name)
        local function scan(object, depth)
            if depth > 5 or #report.records >= 500 or object.Name == "Inventory" or object.Name == "PlayerGui" then return end
            local row = { path = object:GetFullName(), class = object.ClassName, attributes = {} }
            for name, value in pairs(object:GetAttributes()) do
                if type(value) == "number" or type(value) == "boolean" then row.attributes[name] = value end
                if type(value) == "string" then row.attributes[name] = value:sub(1, 120) end
            end
            if object:IsA("IntValue") or object:IsA("NumberValue") or object:IsA("BoolValue") then row.value = object.Value end
            table.insert(report.records, row)
            if object:IsA("Folder") or object == record or object == player then
                for _, child in ipairs(object:GetChildren()) do scan(child, depth + 1) end
            end
        end
        report.camera = { ads = settings._ads, nativeFov = settings._nativeFov, rawRmb = Input:IsMouseButtonPressed(Enum.UserInputType.MouseButton2), fov = workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView, viewmodel = settings.viewmodel, viewmodelStatus = settings._viewmodelStatus }
        report.cameraTrace = settings._cameraTrace
        report.environment = settings._environmentStatus
        report.npcs = settings._npcCount
        report.soulFx = settings._soulStatus
        report.cameraRig = {}
        if workspace.CurrentCamera then
            for _, object in ipairs(workspace.CurrentCamera:GetDescendants()) do
                if #report.cameraRig >= 300 then break end
                local row = { path = object:GetFullName(), class = object.ClassName }
                if object:IsA("JointInstance") or object:IsA("WeldConstraint") then
                    row.part0 = object.Part0 and object.Part0:GetFullName()
                    row.part1 = object.Part1 and object.Part1:GetFullName()
                end
                table.insert(report.cameraRig, row)
            end
        end
        report.visuals = {}
        local function visualScan(root)
            if not root then return end
            for _, object in ipairs(root:GetDescendants()) do
                if #report.visuals >= 1500 then break end
                if not object:IsDescendantOf(gui) and (object:IsA("GuiObject") or object:IsA("Model") or object:IsA("BasePart")) then
                    table.insert(report.visuals, { path = object:GetFullName(), class = object.ClassName })
                end
            end
        end
        visualScan(workspace.CurrentCamera)
        visualScan(player.Character)
        visualScan(playerGui)
        scan(player, 0)
        if record then scan(record, 0) end
        writefile("Oktan-debug.json", HttpService:JSONEncode(report))
    end)
    configStatus = ok and "Сохранено: Oktan-debug.json" or "Не удалось сохранить отчёт"
end)

refreshAll()

local function exportContainer()
    if type(writefile) ~= "function" then configStatus = "Экспорт: запись файлов недоступна"; return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = player.Character and { player.Character } or {}
    local ray = camera:ViewportPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local hit = workspace:Raycast(ray.Origin, ray.Direction * 40, params)
    if not hit then configStatus = "Экспорт: наведитесь на бокс с расстояния до 40 studs"; return end
    local root = hit.Instance:FindFirstAncestorOfClass("Model") or hit.Instance
    if root == player.Character or Players:GetPlayerFromCharacter(root) then
        configStatus = "Экспорт: выбран персонаж, наведитесь на контейнер"; return
    end
    local report = { version = 1, placeId = game.PlaceId, target = root:GetFullName(),
        hit = hit.Instance:GetFullName(), objects = {}, ancestors = {}, truncated = false }
    local function describeObject(object)
        local entry = { path = object:GetFullName(), class = object.ClassName, attributes = {} }
        for key, value in pairs(object:GetAttributes()) do
            local kind = type(value)
            if kind == "string" then entry.attributes[key] = value:sub(1, 200)
            elseif kind == "boolean" or kind == "number" then entry.attributes[key] = value end
        end
        if object:IsA("ObjectValue") then entry.reference = object.Value and object.Value:GetFullName() or nil
        elseif object:IsA("StringValue") then entry.value = object.Value:sub(1, 200)
        elseif object:IsA("NumberValue") or object:IsA("IntValue") or object:IsA("BoolValue") then entry.value = object.Value end
        return entry
    end
    local function scan(object, depth)
        if #report.objects >= 1200 or depth > 7 then report.truncated = true; return end
        table.insert(report.objects, describeObject(object))
        for _, child in ipairs(object:GetChildren()) do scan(child, depth + 1) end
    end
    local ok = pcall(function()
        scan(root, 0)
        local ancestor = root.Parent
        for _ = 1, 4 do
            if not ancestor or ancestor == game then break end
            table.insert(report.ancestors, describeObject(ancestor))
            ancestor = ancestor.Parent
        end
        local file = "Oktan-container-" .. tostring(DateTime.now().UnixTimestampMillis) .. ".json"
        writefile(file, HttpService:JSONEncode(report))
        configStatus = "Сохранено: " .. file
    end)
    if not ok then configStatus = "Экспорт контейнера не выполнен" end
end

local function inputName(input)
    if input.KeyCode ~= Enum.KeyCode.Unknown then return input.KeyCode.Name end
    return input.UserInputType.Name
end
local function held(action)
    local key = bindings[action]
    if not key then return false end
    if key == "MouseButton2" or key == "MouseButton3" then
        return Input:IsMouseButtonPressed(Enum.UserInputType[key])
    end
    return Input:IsKeyDown(Enum.KeyCode[key])
end
connect(Input.InputBegan, function(input, processed)
    if Input:GetFocusedTextBox() then return end
    local name = inputName(input)
    if pendingNumeric and name == "Escape" then
        pendingNumeric = nil; bindDialog.Visible = false; return
    end
    if capture then
        if name == "Escape" then capture = nil; refreshAll(); return end
        if name == "Backspace" then
            bindings[capture] = nil
        elseif allowedKeys[name] then
            for action, key in pairs(bindings) do
                if key == name then bindings[action] = nil end
            end
            bindings[capture] = name
        else
            return
        end
        capture = nil
        changed()
        refreshAll()
        return
    end
    if processed or not focused then return end
    if name == bindings.menu then setMenu(not menu.Visible); return end
    if menu.Visible then return end
    if name == bindings.containerDump then exportContainer(); return end
    if name == bindings.aim or name == bindings.zoom then return end
    if name == bindings.inspect and inspectAction then inspectAction(); return end
    for action, key in pairs(bindings) do
        if name == key then
            if schema[action] and type(settings[action]) == "boolean" then
                setValue(action, not settings[action])
            else
                local settingKey, suffix = action:match("^(.-)(Minus)$")
                if not settingKey then settingKey, suffix = action:match("^(.-)(Plus)$") end
                if settingKey and schema[settingKey] then
                    local definition = schema[settingKey]
                    local step = math.max(1, math.round((definition[7] - definition[6]) / 100))
                    local delta = suffix == "Plus" and step or -step
                    setValue(settingKey, math.clamp(settings[settingKey] + delta, definition[6], definition[7]))
                end
            end
        end
    end
end)
local dragStart, dragPosition
connect(title.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragStart, dragPosition = input.Position, menu.Position
    end
end)
connect(Input.InputChanged, function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    if activeSlider then activeSlider(input.Position.X) end
    if dragStart then
        local delta = input.Position - dragStart
        local camera = workspace.CurrentCamera
        if camera then
            local viewport = camera.ViewportSize
            local half = menu.AbsoluteSize * 0.5
            local x = dragPosition.X.Scale * viewport.X + dragPosition.X.Offset + delta.X
            local y = dragPosition.Y.Scale * viewport.Y + dragPosition.Y.Offset + delta.Y
            menu.Position = UDim2.fromOffset(
                math.clamp(x, half.X, math.max(half.X, viewport.X - half.X)),
                math.clamp(y, half.Y, math.max(half.Y, viewport.Y - half.Y)))
        end
    end
end)
connect(Input.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        activeSlider, dragStart = nil, nil
    end
end)
connect(Input.WindowFocusReleased, function()
    focused = false
    activeSlider, dragStart, capture = nil, nil, nil
    tooltip.Visible = false
    refreshAll()
end)
connect(Input.WindowFocused, function() focused = true end)

-- HUD state is scoped to this client instance. Unknown game statistics stay unknown.
local raid = { kills = nil, extracted = nil, state = "Нет данных о рейде" }
local raidTelemetry = create("BindableEvent", gui, { Name = "RaidTelemetry" })
connect(raidTelemetry.Event, function(payload)
    if type(payload) ~= "table" then return end
    if payload.reset == true then
        raid = { kills = nil, extracted = nil, state = "Нет данных о рейде" }
    end
    if type(payload.kills) == "number" and payload.kills >= 0
        and payload.kills < 100000 and payload.kills % 1 == 0 then
        raid.kills = payload.kills
    end
    if type(payload.state) == "string" then raid.state = payload.state:sub(1, 120) end
    if type(payload.extracted) == "table" then
        local items = {}
        for index, item in ipairs(payload.extracted) do
            if index > 100 then break end
            if type(item) == "string" then table.insert(items, item:sub(1, 160)) end
        end
        raid.extracted = items
    end
end)

local islandExpanded = false
local island = create("Frame", gui, {
    AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 74),
    Size = UDim2.fromOffset(330, 44), BackgroundColor3 = Color3.fromRGB(9, 12, 18),
    BackgroundTransparency = 0.08, BorderSizePixel = 0, ClipsDescendants = true,
    ZIndex = 15,
})
rounded(island, 23)
stroke(island, palette.accent).Transparency = 0.25
local islandScale = create("UIScale", island, { Scale = 1 })
local islandHeader = text(island, "", { Size = UDim2.new(1, 0, 0, 44), TextSize = 12 }, "TextButton")
connect(islandHeader.Activated, function() islandExpanded = not islandExpanded end)
local islandScroll = create("ScrollingFrame", island, {
    Position = UDim2.fromOffset(18, 50), Size = UDim2.new(1, -36, 1, -64),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
    AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.fromOffset(0, 0),
    ScrollBarImageColor3 = palette.accent,
})
local islandBody = text(islandScroll, "", {
    Visible = false,
    Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true, TextSize = 12, LineHeight = 1.45,
})

local islandRows = {}
local islandList = create("Frame", islandScroll, {
    BackgroundTransparency = 1, Size = UDim2.new(1, -5, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
})
create("UIListLayout", islandList, { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder })
islandBody.Parent = islandList
islandBody.LayoutOrder = 1000
local islandLabels = { menu = "Menu", inspect = "Inspect" }
for _, definition in ipairs(definitions) do
    local key = definition[1]
    islandLabels[key] = definition[3]
    islandLabels[key .. "Minus"] = definition[3] .. " -"
    islandLabels[key .. "Plus"] = definition[3] .. " +"
end
island.Size = UDim2.fromOffset(420, 48)
local islandBrand = text(islandHeader, "OKTAN", {
    Position = UDim2.fromOffset(18, 0), Size = UDim2.fromOffset(88, 44),
    Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
})
local islandClock = text(islandHeader, "", { Position = UDim2.fromOffset(110, 0), Size = UDim2.fromOffset(112, 44), TextSize = 13 })
local islandKills = text(islandHeader, "", { Position = UDim2.fromOffset(228, 0), Size = UDim2.fromOffset(142, 44), TextSize = 12 })
local islandChevron = text(islandHeader, "+", { Position = UDim2.fromOffset(378, 0), Size = UDim2.fromOffset(24, 44), TextSize = 17 })
local function getRaidKills()
    local records = game:GetService("ReplicatedStorage"):FindFirstChild("Players")
    local record = records and records:FindFirstChild(player.Name)
    local value = player:GetAttribute("RaidKills")
    if record then
        value = record:GetAttribute("RaidKills") or value
        local stat = record:FindFirstChild("RaidKills")
        local raidStats = record:FindFirstChild("RaidStats")
        if not stat and raidStats then stat = raidStats:FindFirstChild("Kills") end
        if stat and (stat:IsA("IntValue") or stat:IsA("NumberValue")) then value = stat.Value end
    end
    if type(value) == "number" and value >= 0 and value < 100000 and value % 1 == 0 then return value end
    local status = record and record:FindFirstChild("Status")
    local journey = status and status:FindFirstChild("Journey")
    local statistics = journey and journey:FindFirstChild("Statistics")
    local total = statistics and statistics:GetAttribute("Kills")
    if type(total) == "number" and total >= 0 and total % 1 == 0 then
        if raid.source ~= statistics or not raid.baseline or total < raid.baseline then
            raid.source, raid.baseline = statistics, total
        end
        raid.session = true
        return total - raid.baseline
    end
    return nil
end
local function updateIslandHeader()
    raid.session = false
    raid.kills = getRaidKills()
    islandHeader.Text = ""
    islandClock.Text = DateTime.now():FormatLocalTime("HH:mm:ss", "en-us")
    islandKills.Text = raid.kills == nil and "KILLS  —" or (raid.session and "SESSION  " or "KILLS  ") .. tostring(raid.kills)
    islandChevron.Text = islandExpanded and "-" or "+"
    islandBrand.TextColor3 = palette.accent
end

local function updateIslandRows()
    local actions = {}
    for action in pairs(bindings) do table.insert(actions, action) end
    table.sort(actions, function(a, b) return (islandLabels[a] or a) < (islandLabels[b] or b) end)
    for index, action in ipairs(actions) do
        local entry = islandRows[index]
        if not entry then
            local frame = create("Frame", islandList, {
                BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = index,
            })
            local name = text(frame, "", { Size = UDim2.new(1, -108, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextSize = 12 })
            local key = text(frame, "", { Position = UDim2.new(1, -108, 0, 0), Size = UDim2.fromOffset(82, 26), TextSize = 11 })
            local dot = create("Frame", frame, {
                Position = UDim2.new(1, -12, 0.5, -3), Size = UDim2.fromOffset(6, 6), BorderSizePixel = 0,
            })
            rounded(dot, 6)
            entry = { frame = frame, name = name, key = key, dot = dot }
            islandRows[index] = entry
        end
        entry.frame.Visible = true
        entry.name.Text = islandLabels[action] or action
        entry.key.Text = bindings[action]
        local on = settings[action] == true
        if action == "aim" or action == "zoom" then on = held(action) end
        entry.dot.BackgroundColor3 = on and Color3.fromRGB(56, 200, 125) or Color3.fromRGB(100, 100, 110)
    end
    for index = #actions + 1, #islandRows do islandRows[index].frame.Visible = false end
    updateIslandHeader()
end

local inspectTarget
local inspector = create("Frame", gui, {
    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -24, 0.5, 0),
    Size = UDim2.fromOffset(360, 350), BackgroundColor3 = palette.background,
    BackgroundTransparency = 0.06, BorderSizePixel = 0, Visible = false, ZIndex = 16,
})
rounded(inspector, 18)
stroke(inspector, palette.accent)
local inspectorScale = create("UIScale", inspector, { Scale = 1 })
text(inspector, "INVENTORY", {
    Position = UDim2.fromOffset(18, 16), Size = UDim2.fromOffset(280, 26),
    TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold,
})
local inspectClose = text(inspector, "×", {
    Position = UDim2.new(1, -42, 0, 12), Size = UDim2.fromOffset(30, 30), TextSize = 22,
}, "TextButton")
connect(inspectClose.Activated, function() inspector.Visible = false; inspectTarget = nil end)
local inventoryScroll = create("ScrollingFrame", inspector, {
    Position = UDim2.fromOffset(18, 55), Size = UDim2.new(1, -36, 1, -73),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
    AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.fromOffset(0, 0),
})
local inventoryBody = text(inventoryScroll, "", {
    Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true, TextSize = 13, LineHeight = 1.4,
})
local corpseTargets = {}
local function deltaInventory(owner)
    if (type(owner) == "table" and owner.Corpse) then
        local model = owner.Character
        return model and (model:FindFirstChild("Inventory") or model:FindFirstChild("Contents") or model:FindFirstChild("Loot"))
    end
    local replicatedPlayers = game:GetService("ReplicatedStorage"):FindFirstChild("Players")
    local record = replicatedPlayers and replicatedPlayers:FindFirstChild(owner.Name)
    return record and record:FindFirstChild("Inventory")
end
local function heldItem(character)
    if not character then return nil end
    local holding = character:FindFirstChild("Holding")
    if holding and holding:IsA("ObjectValue") then
        return holding.Value
    end
    return character:FindFirstChildOfClass("Tool")
end
local function inspectNearest()
    if inspector.Visible then inspector.Visible = false; inspectTarget = nil; return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    local nearest, best = nil, settings.inspectRadius
    local center = camera.ViewportSize * 0.5
    for _, other in ipairs(Players:GetPlayers()) do
        local character = other.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if other ~= player and root and root:IsA("BasePart")
            and (root.Position - camera.CFrame.Position).Magnitude <= settings.range then
            local point, visible = camera:WorldToViewportPoint(root.Position)
            local distance = (Vector2.new(point.X, point.Y) - center).Magnitude
            if visible and point.Z > 0 and distance < best then nearest, best = other, distance end
        end
    end
    for model, root in pairs(corpseTargets) do
        if model.Parent and root.Parent and (root.Position - camera.CFrame.Position).Magnitude <= settings.lootRange then
            local point, visible = camera:WorldToViewportPoint(root.Position)
            local distance = (Vector2.new(point.X, point.Y) - center).Magnitude
            if visible and point.Z > 0 and distance < best then
                nearest, best = { Name = model.Name, Character = model, Parent = Players, Corpse = true }, distance
            end
        end
    end
    inspectTarget = nearest
    inspector.Visible = true
    inventoryScroll.CanvasPosition = Vector2.new(0, 0)
end
-- The keyboard handler is installed before this HUD, so it uses this shared callback.
inspectAction = inspectNearest

inventoryScroll.Size = UDim2.new(1, -36, 1, -122)
local diagnosticsButton = button(inspector, "Сохранить структуру предметов", UDim2.new(0, 18, 1, -48), UDim2.new(1, -36, 0, 30))
connect(diagnosticsButton.Activated, function()
    if not inspectTarget then diagnosticsButton.Text = "Сначала выберите игрока"; return end
    if type(writefile) ~= "function" then diagnosticsButton.Text = "Запись файлов недоступна"; return end
    local ok = pcall(function()
        local report = { placeId = game.PlaceId, version = 1, objects = {} }
        local roots = { inspectTarget.Character, inspectTarget:FindFirstChildOfClass("Backpack") }
        for _, root in pairs(roots) do
            if root then
                local descendants = root:GetDescendants()
                table.insert(descendants, 1, root)
                for _, object in ipairs(descendants) do
                    if #report.objects >= 1200 then report.truncated = true; break end
                    local entry = { path = object:GetFullName(), class = object.ClassName, attributes = {} }
                    for name, value in pairs(object:GetAttributes()) do
                        local kind = type(value)
                        if kind == "number" or kind == "boolean" then entry.attributes[name] = value end
                        if kind == "string" then entry.attributes[name] = value:sub(1, 256) end
                    end
                    if object:IsA("StringValue") then entry.value = object.Value:sub(1, 512) end
                    if object:IsA("IntValue") or object:IsA("NumberValue") or object:IsA("BoolValue") then entry.value = object.Value end
                    if object:IsA("ObjectValue") and object.Value then entry.reference = object.Value:GetFullName() end
                    table.insert(report.objects, entry)
                end
            end
        end
        writefile("DeltaClient-item-structure.json", HttpService:JSONEncode(report))
    end)
    diagnosticsButton.Text = ok and "Сохранено: DeltaClient-item-structure.json" or "Не удалось сохранить"
end)

inventoryBody.Visible = false
inventoryScroll.Visible = false
diagnosticsButton.Visible = false
inspector.Size = UDim2.fromOffset(670, 540)
local preview = create("ViewportFrame", inspector, {
    Position = UDim2.fromOffset(16, 58), Size = UDim2.fromOffset(210, 380),
    BackgroundColor3 = Color3.fromRGB(19, 19, 23), BackgroundTransparency = 0.1,
    BorderSizePixel = 0, Ambient = Color3.fromRGB(180, 180, 185),
    LightColor = Color3.fromRGB(240, 240, 245),
    LightDirection = Vector3.new(-1, -1, -1),
})
rounded(preview, 12)
local previewCamera = create("Camera", preview, { FieldOfView = 40 })
preview.CurrentCamera = previewCamera
local previewName = text(inspector, "", {
    Position = UDim2.fromOffset(16, 448), Size = UDim2.fromOffset(210, 48),
    TextWrapped = true, TextSize = 14,
})
local inventoryNote = text(inspector, "", {
    Position = UDim2.fromOffset(244, 465), Size = UDim2.fromOffset(408, 22),
    TextColor3 = palette.muted, TextSize = 11,
})
local cardArea = create("Frame", inspector, {
    Position = UDim2.fromOffset(244, 104), Size = UDim2.fromOffset(408, 350),
    BackgroundTransparency = 1,
})
create("UIGridLayout", cardArea, {
    CellSize = UDim2.fromOffset(130, 108), CellPadding = UDim2.fromOffset(8, 10),
    SortOrder = Enum.SortOrder.LayoutOrder,
})
local selectedInventoryTab, inventoryPage = "Gear", 1
local inventorySignature
local previewWorld, previewCenter, previewRadius
local cards = {}
local tabsInventory = {}
for index, name in ipairs({ "Gear", "Weapons", "Loot" }) do
    local control = button(inspector, name, UDim2.fromOffset(244 + (index - 1) * 138, 58), UDim2.fromOffset(130, 32))
    tabsInventory[name] = control
    connect(control.Activated, function()
        selectedInventoryTab, inventoryPage, inventorySignature = name, 1, nil
    end)
end
local previousInventory = button(inspector, "Previous", UDim2.fromOffset(244, 497), UDim2.fromOffset(130, 28))
local nextInventory = button(inspector, "Next", UDim2.fromOffset(522, 497), UDim2.fromOffset(130, 28))
connect(previousInventory.Activated, function()
    inventoryPage = math.max(1, inventoryPage - 1)
    inventorySignature = nil
end)
connect(nextInventory.Activated, function()
    inventoryPage += 1
    inventorySignature = nil
end)
local function visualCopy(source, parent)
    if not source then return nil end
    local ok, copy = pcall(function() return source:Clone() end)
    if not ok or not copy then return nil end
    for _, object in ipairs(copy:GetDescendants()) do
        if object:IsA("LuaSourceContainer") then object:Destroy() end
        if object:IsA("BasePart") then object.Anchored = true; object.CanCollide = false end
    end
    if copy:IsA("BasePart") then copy.Anchored = true; copy.CanCollide = false end
    copy.Parent = parent
    return copy
end
local function rebuildPreview(character)
    if previewWorld then previewWorld:Destroy() end
    previewCenter = nil
    previewWorld = create("WorldModel", preview)
    local model = create("Model", previewWorld)
    if not character then return end
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("BasePart") or child:IsA("Model") or child:IsA("Accessory") then
            visualCopy(child, model)
        end
    end
    if not model:FindFirstChildWhichIsA("BasePart", true) then return end
    local root = model:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        model.PrimaryPart = root
        model:PivotTo(CFrame.Angles(0, math.pi, 0))
    end
    local cf, size = model:GetBoundingBox()
    previewCenter, previewRadius = cf.Position, math.max(size.X, size.Y, size.Z, 2) * 2.1
    previewCamera.CFrame = CFrame.lookAt(previewCenter + Vector3.new(0, size.Y * 0.08, previewRadius), previewCenter)
end
local function itemImage(item)
    if item:IsA("Tool") and item.TextureId ~= "" then return item.TextureId end
    for _, key in ipairs({ "Icon", "Image", "Thumbnail" }) do
        local value = item:GetAttribute(key)
        if type(value) == "string" and value:match("^rbxassetid://%d+$") then return value end
    end
    return nil
end
local function collectInventory(owner)
    local categories = { Gear = {}, Weapons = {}, Loot = {} }
    local character = owner.Character
    local assigned, seen = {}, {}
    local function add(category, item, slot)
        if not item then return end
        if not seen[item] then
            seen[item] = true
            table.insert(categories[category], { item = item, slot = slot })
        end
        assigned[item] = category
    end
    add("Weapons", heldItem(character), "In hand")
    for _, pair in ipairs({ { "Clothing", "Gear" }, { "Holstered", "Weapons" } }) do
        local folder = character and character:FindFirstChild(pair[1])
        if folder then
            for _, reference in ipairs(folder:GetChildren()) do
                if reference:IsA("ObjectValue") then
                    add(pair[2], reference.Value, reference.Name:gsub("^Clothing", ""))
                end
            end
        end
    end
    local visited = {}
    local function scan(container)
        if not container or visited[container] then return end
        visited[container] = true
        for _, item in ipairs(container:GetChildren()) do
            if not assigned[item] then add("Loot", item, container.Name) end
            for _, child in ipairs(item:GetChildren()) do
                if (child.Name == "Inventory" or child.Name == "Contents")
                    and (child:IsA("Folder") or child:IsA("Model")) then scan(child) end
            end
        end
    end
    scan(deltaInventory(owner))
    for _, list in pairs(categories) do
        table.sort(list, function(a, b)
            if a.item.Name == b.item.Name then return a.slot < b.slot end
            return a.item.Name < b.item.Name
        end)
    end
    return categories
end
local previewSignature
local function updateInventoryCards()
    if not inspector.Visible then return end
    if not inspectTarget or inspectTarget.Parent ~= Players or ((type(inspectTarget) == "table" and inspectTarget.Corpse) and not inspectTarget.Character.Parent) then
        inventoryNote.Text = "Наведитесь на игрока или распознанный труп и нажмите Inspect."
        previewName.Text = "No target"
        for _, card in ipairs(cards) do card:Destroy() end
        table.clear(cards)
        if previewWorld then previewWorld:Destroy(); previewWorld = nil end
        inventorySignature, previewSignature = nil, nil
        return
    end
    local categories = collectInventory(inspectTarget)
    local entries = categories[selectedInventoryTab]
    local pagesCount = math.max(1, math.ceil(#entries / 9))
    inventoryPage = math.clamp(inventoryPage, 1, pagesCount)
    local signature = { inspectTarget.Name, selectedInventoryTab, tostring(inventoryPage) }
    local equipment = { inspectTarget.Name, tostring(inspectTarget.Character),
        tostring(inspectTarget.Character and #inspectTarget.Character:GetChildren() or 0) }
    for _, name in ipairs({ "Gear", "Weapons", "Loot" }) do
        local list = categories[name]
        for _, entry in ipairs(list) do
            table.insert(signature, name .. "/" .. entry.slot .. "/" .. entry.item.Name .. "/" .. tostring(itemImage(entry.item)))
            if name ~= "Loot" then table.insert(equipment, name .. entry.item.Name) end
        end
    end
    local currentPreview = table.concat(equipment, "|")
    if previewSignature ~= currentPreview then
        rebuildPreview(inspectTarget.Character)
        previewSignature = currentPreview
    end
    previewName.Text = ((type(inspectTarget) == "table" and inspectTarget.Corpse) and "CORPSE · " or "") .. inspectTarget.Name
    inventoryNote.Text = string.format("%d items  |  Page %d / %d", #entries, inventoryPage, pagesCount)
    if (type(inspectTarget) == "table" and inspectTarget.Corpse) and not deltaInventory(inspectTarget) then
        inventoryNote.Text = "Лут недоступен клиенту. Показано только распознанное снаряжение."
    end
    local current = table.concat(signature, "|")
    if inventorySignature == current then return end
    inventorySignature = current
    for _, card in ipairs(cards) do card:Destroy() end
    table.clear(cards)
    for name, control in pairs(tabsInventory) do
        control.TextColor3 = name == selectedInventoryTab and palette.accent or palette.muted
    end
    for index = (inventoryPage - 1) * 9 + 1, math.min(inventoryPage * 9, #entries) do
        local entry = entries[index]
        local card = create("Frame", cardArea, {
            BackgroundColor3 = palette.panel, BorderSizePixel = 0, LayoutOrder = index,
        })
        rounded(card, 10)
        stroke(card)
        local imageId = itemImage(entry.item)
        if imageId then
            create("ImageLabel", card, {
                BackgroundTransparency = 1, Image = imageId, ScaleType = Enum.ScaleType.Fit,
                Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 0, 48),
            })
        else
            local character = inspectTarget.Character
            local model = character and character:FindFirstChild(entry.item.Name)
            if not model and entry.item:IsA("Model") then model = entry.item end
            if model and model:FindFirstChildWhichIsA("BasePart", true) then
                local viewport = create("ViewportFrame", card, {
                    BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 4),
                    Size = UDim2.new(1, -16, 0, 52), Ambient = Color3.fromRGB(200, 200, 200),
                })
                local world = create("WorldModel", viewport)
                local copy = visualCopy(model, world)
                if copy and copy:IsA("Model") then
                    local cf, size = copy:GetBoundingBox()
                    local camera = create("Camera", viewport, {
                        FieldOfView = 40,
                        CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, 0, math.max(size.X, size.Y, size.Z) * 2), cf.Position),
                    })
                    viewport.CurrentCamera = camera
                end
            else
                text(card, selectedInventoryTab == "Weapons" and "WEAPON" or "ITEM", {
                    Position = UDim2.fromOffset(8, 10), Size = UDim2.new(1, -16, 0, 34),
                    TextColor3 = palette.muted, TextSize = 10,
                })
            end
        end
        local caption = text(card, entry.item.Name, {
            Position = UDim2.fromOffset(6, 56), Size = UDim2.new(1, -12, 0, 34),
            TextWrapped = true, TextSize = 12, TextScaled = true,
        })
        create("UITextSizeConstraint", caption, { MinTextSize = 8, MaxTextSize = 12 })
        text(card, entry.slot, {
            Position = UDim2.fromOffset(6, 91), Size = UDim2.new(1, -12, 0, 14),
            TextSize = 9, TextColor3 = palette.muted,
        })
        table.insert(cards, card)
    end
end

connect(inspector:GetPropertyChangedSignal("Visible"), function()
    if inspector.Visible then
        updateInventoryCards()
    else
        for _, card in ipairs(cards) do card:Destroy() end
        table.clear(cards)
        if previewWorld then previewWorld:Destroy(); previewWorld = nil end
        inventorySignature, previewSignature, previewCenter = nil, nil, nil
    end
end)

local inventoryElapsed = 1
local hudElapsed = 1
local function updateHud(dt)
    inventoryElapsed += dt
    hudElapsed += dt
    local camera = workspace.CurrentCamera
    if camera then
        local viewport = camera.ViewportSize
        local hudScale = math.min(1, math.max(0.2, (viewport.X - 32) / 390), math.max(0.2, (viewport.Y - 32) / 560))
        islandScale.Scale = hudScale
        inspectorScale.Scale = hudScale
        island.Position = UDim2.new(0.5, 0, 0, math.min(settings.islandY, math.max(0, viewport.Y - 300 * hudScale)))
    end
    island.Visible = settings.island
    local desiredSize = islandExpanded and UDim2.fromOffset(420, 300) or UDim2.fromOffset(420, 48)
    island.Size = island.Size:Lerp(desiredSize, 1 - math.exp(-14 * dt))
    islandScroll.Visible = islandExpanded
    if hudElapsed >= 0.2 then
    hudElapsed = 0
    local sections = {}
    if raid.kills ~= nil then table.insert(sections, (raid.session and "Session kills: " or "Raid kills: ") .. tostring(raid.kills)) end
    if raid.extracted ~= nil then
        table.insert(sections, "Extracted")
        table.insert(sections, #raid.extracted > 0 and table.concat(raid.extracted, "\n") or "No items")
    end
    islandBody.Visible = #sections > 0
    islandBody.Text = table.concat(sections, "\n")
    updateIslandRows()
    end

    if inspector.Visible and inventoryElapsed >= 0.5 then
        inventoryElapsed = 0
        updateInventoryCards()

    end
end

-- One hierarchy owns each row. Searching temporarily moves entire branches.
local function normalizeQuery(value)
    local output = {}
    for _, codepoint in utf8.codes(value) do
        if codepoint >= 1040 and codepoint <= 1071 then codepoint += 32 end
        if codepoint == 1025 then codepoint = 1105 end
        table.insert(output, utf8.char(codepoint))
    end
    return string.lower(table.concat(output))
end
local search = text(menu, "", {
    Position = UDim2.fromOffset(465, 24), Size = UDim2.fromOffset(300, 32),
    BackgroundTransparency = 0.15, BackgroundColor3 = palette.control,
    PlaceholderText = "Search...", PlaceholderColor3 = palette.muted,
    ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
}, "TextBox")
rounded(search, 9)
create("UIPadding", search, { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) })
describe(search, "Ищет по всем разделам, названиям и описаниям. Например: оружие, цвет, рамка, зум. Очистите строку для возврата к разделам.")

local treeGroups = {
    ["Наведение"] = { "Наведение", "Цели и проверки", "Область и плавность" },
    ESP = { "Общее", "Подписи", "Геометрия", "Цвет и оформление", "Loot" },
    ["Мир"] = { "Освещение", "Vegetation" },
    ["Камера"] = { "Зум", "Прицел", "Vision", "Viewmodel" },
    ["Бинды"] = { "Инвентарь", "Dynamic Island", "Управление", "Назначения функций" },
    ["Настройки"] = { "Оформление", "Клиент" },
}
local settingGroup = { motion = "Оформление", killFx = "Оформление", crossStyle = "Прицел", crossWidth = "Прицел", noLeaves = "Vegetation", noGrass = "Vegetation", corpseEsp = "Loot", itemEsp = "Loot", lootThrough = "Loot", lootRange = "Loot", lootTextSize = "Loot",
    noVisor = "Vision", cameraFov = "Vision", cameraFovValue = "Vision",
    viewmodel = "Viewmodel", vmX = "Viewmodel", vmY = "Viewmodel", vmZ = "Viewmodel", sticky = "Наведение", noFog = "Освещение", bubbles = "Оформление", snow = "Оформление", snowDrifts = "Оформление", friendHats = "Оформление", espFps = "Цвет и оформление", adaptiveText = "Подписи",
    aim = "Наведение", aimPlayers = "Цели и проверки", aimDummies = "Цели и проверки",
    team = "Цели и проверки", wall = "Цели и проверки", head = "Цели и проверки",
    ring = "Область и плавность", radius = "Область и плавность", smooth = "Область и плавность",
    fovHue = "Область и плавность", fovSaturation = "Область и плавность", fovValue = "Область и плавность",
    esp = "Общее", espPlayers = "Общее", espDummies = "Общее", through = "Общее", range = "Общее",
    names = "Подписи", health = "Подписи", distance = "Подписи", weapon = "Подписи", textSize = "Подписи",
    chams = "Геометрия", boxes = "Геометрия", corners = "Геометрия",
    skeleton = "Геометрия", tracers = "Геометрия", healthBar = "Геометрия",
    espHue = "Цвет и оформление", espSaturation = "Цвет и оформление", espValue = "Цвет и оформление",
    espOpacity = "Цвет и оформление", fillOpacity = "Цвет и оформление", lineWidth = "Цвет и оформление",
    bright = "Освещение", clock = "Освещение", hour = "Освещение",
    zoom = "Зум", zoomFov = "Зум", crosshair = "Прицел", length = "Прицел", gap = "Прицел",
    inspectRadius = "Инвентарь", island = "Dynamic Island", islandY = "Dynamic Island",
    glass = "Оформление", blur = "Оформление",
    menuHue = "Оформление", menuSaturation = "Оформление", menuValue = "Оформление",
}
local searchResults = create("ScrollingFrame", menu, {
    Position = UDim2.fromOffset(177, 88), Size = UDim2.fromOffset(721, 470),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
    AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.fromOffset(0, 0),
    Visible = false,
})
create("UIListLayout", searchResults, { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
create("UIPadding", searchResults, {
    PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 12),
    PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 4),
})
local emptySearch = text(searchResults, "Ничего не найдено", { Size = UDim2.new(1, 0, 0, 44), Visible = false })
local branches = {}
local branchByName = {}
local order = 0
for _, pageName in ipairs({ "Наведение", "ESP", "Мир", "Камера", "Бинды", "Настройки" }) do
    for _, name in ipairs(treeGroups[pageName]) do
        order += 1
        local branch = create("Frame", pages[pageName], {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order,
        })
        create("UIListLayout", branch, { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
        local header = button(branch, "", UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 40))
        header.TextXAlignment = Enum.TextXAlignment.Left
        create("UIPadding", header, { PaddingLeft = UDim.new(0, 14) })
        local body = create("Frame", branch, {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1,
        })
        create("UIListLayout", body, { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
        create("UIPadding", body, { PaddingLeft = UDim.new(0, 16), PaddingBottom = UDim.new(0, 3) })
        local entry = { frame = branch, body = body, header = header, page = pageName,
            name = name, expanded = name == treeGroups[pageName][1], rows = {} }
        header.Text = (entry.expanded and "-   " or "+   ") .. (displayNames[name] or name)
        body.Visible = entry.expanded
        connect(header.Activated, function()
            entry.expanded = not entry.expanded
            body.Visible = entry.expanded
            header.Text = (entry.expanded and "-   " or "+   ") .. (displayNames[name] or name)
            tooltip.Visible = false
        end)
        table.insert(branches, entry)
        branchByName[pageName .. "/" .. name] = entry
    end
end
for _, entry in ipairs(controlRows) do
    local branch = branchByName[entry.page .. "/" .. (settingGroup[entry.key] or "Клиент")]
    if branch then
        entry.frame.Parent = branch.body
        table.insert(branch.rows, entry)
    end
end
for _, frame in ipairs(roleRows) do
    local branch = branchByName["Бинды/Управление"]
    frame.Parent = branch.body
    table.insert(branch.rows, { frame = frame, query = normalizeQuery("управление меню наведение зум инвентарь бинды") })
end
actionsRow.Parent = branchByName["Настройки/Клиент"].body
table.insert(branchByName["Настройки/Клиент"].rows, { frame = actionsRow, query = normalizeQuery("сохранить сбросить выгрузить") })
local assignedBranch = branchByName["Бинды/Назначения функций"]
local bindingRows = {}
for _, definition in ipairs(definitions) do
    local key = definition[1]
    local actions = type(definition[2]) == "boolean" and { key } or { key .. "Minus", key .. "Plus" }
    for _, action in ipairs(actions) do
        local suffix = action == key and "" or (action == key .. "Minus" and " - Down" or " - Up")
        local frame = row(assignedBranch.body, #bindingRows + 1, 48)
        local label = definition[3] .. suffix
        text(frame, label, {
            Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -154, 0, 40),
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        })
        bindButton(frame, action, UDim2.new(1, -130, 0, 10), UDim2.fromOffset(114, 28))
        local entry = { frame = frame, action = action, query = normalizeQuery(label .. " бинды назначение") }
        table.insert(bindingRows, entry)
        table.insert(assignedBranch.rows, entry)
    end
end
local previousPage = "Наведение"
local renderGraph
local function applySearch()
    if renderGraph then renderGraph() end
end
connect(search:GetPropertyChangedSignal("Text"), function()
    searchResults.CanvasPosition = Vector2.new(0, 0)
end)
for name, tabButton in pairs(tabButtons) do
    connect(tabButton.Activated, function()
        previousPage = name
        search.Text = ""
        applySearch()
    end)
end
applySearch()

local function initializeGraph()
local graphConnections = {}
table.insert(cleanups, function() for _, connection in ipairs(graphConnections) do connection:Disconnect() end end)
local graphTweens = {}
local function animate(object, properties, duration, delay)
    local tween = TweenService:Create(object,
        TweenInfo.new(settings.motion and (duration or 0.22) or 0, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, false, delay or 0), properties)
    table.insert(graphTweens, tween)
    tween:Play()
    return tween
end
local function cancelAnimations()
    for _, tween in ipairs(graphTweens) do tween:Cancel() end
    table.clear(graphTweens)
end
table.insert(cleanups, cancelAnimations)
local graph = create("ScrollingFrame", menu, {
    Position = UDim2.fromOffset(20, 88), Size = UDim2.fromOffset(880, 470),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
    CanvasSize = UDim2.fromOffset(880, 470), ScrollBarImageColor3 = palette.accent,
})
local detail = create("Frame", menu, {
    Position = UDim2.fromOffset(20, 88), Size = UDim2.fromOffset(880, 470),
    BackgroundColor3 = palette.background, BackgroundTransparency = 0.06,
    BorderSizePixel = 0, Visible = false, ZIndex = 5,
})
rounded(detail, 16)
stroke(detail, palette.accent)
local detailTitle = text(detail, "", {
    Position = UDim2.fromOffset(110, 8), Size = UDim2.fromOffset(700, 32),
    TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left,
})
local back = button(detail, "Back", UDim2.fromOffset(12, 8), UDim2.fromOffset(80, 32))
local detailBody = create("ScrollingFrame", detail, {
    Position = UDim2.fromOffset(12, 54), Size = UDim2.new(1, -24, 1, -68),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
    AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.fromOffset(0, 0),
})
create("UIListLayout", detailBody, { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) })
create("UIPadding", detailBody, { PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 3) })
local movedRows, temporaryRows = {}, {}
local selectedCategory, selectedGroup = "Наведение", "Наведение"
local function clearDetail()
    for _, entry in ipairs(movedRows) do entry.object.Parent = entry.parent end
    table.clear(movedRows)
    for _, object in ipairs(temporaryRows) do object:Destroy() end
    table.clear(temporaryRows)
end
local function moveDetail(object, order)
    table.insert(movedRows, { object = object, parent = object.Parent })
    object.Parent = detailBody
    object.LayoutOrder = order
    object.Visible = true
end
local function openDetail(titleText)
    clearDetail()
    detailTitle.Text = titleText
    detail.Visible, graph.Visible = true, false
    detail.Position = UDim2.fromOffset(32, 88)
    detail.BackgroundTransparency = 0.35
    animate(detail, { Position = UDim2.fromOffset(20, 88), BackgroundTransparency = 0.04 }, 0.24)
    detailBody.CanvasPosition = Vector2.new(0, 0)
    tooltip.Visible = false
end
local friendForm = create("Frame", pages["Настройки"], {
    Size = UDim2.new(1, 0, 0, 280), BackgroundTransparency = 1, Visible = false,
})
local friendInput = text(friendForm, "", {
    Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -180, 0, 36),
    BackgroundColor3 = palette.control, BackgroundTransparency = 0.1,
    ClearTextOnFocus = false, PlaceholderText = "Roblox username", TextXAlignment = Enum.TextXAlignment.Left,
}, "TextBox")
rounded(friendInput, 10)
create("UIPadding", friendInput, { PaddingLeft = UDim.new(0, 12) })
local friendAdd = button(friendForm, "Add / Remove", UDim2.new(1, -158, 0, 8), UDim2.fromOffset(150, 36))
local friendList = text(friendForm, "", {
    Position = UDim2.fromOffset(8, 60), Size = UDim2.new(1, -16, 0, 200),
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
})
local function refreshFriendList()
    local names = {}
    for name in pairs(friendNames) do table.insert(names, name) end
    table.sort(names)
    friendList.Text = #names > 0 and table.concat(names, "\n") or "No friends added"
end
describe(friendInput, "Введите username, а не отображаемое имя. Повторное добавление удаляет друга.")
connect(friendAdd.Activated, function()
    local name = string.lower(friendInput.Text:match("^%s*(.-)%s*$"))
    if #name < 3 or #name > 20 or not name:match("^[%w_]+$") then
        friendList.Text = "Введите username из 3–20 букв, цифр или подчёркиваний."
        return
    end
    friendNames[name] = not friendNames[name] or nil
    if friendNames[name] then
        local other = Players:FindFirstChild(friendInput.Text:match("^%s*(.-)%s*$"))
        if not other then
            for _, candidate in ipairs(Players:GetPlayers()) do if string.lower(candidate.Name) == name then other = candidate; break end end
        end
        if other and other.Character then
            local shine = create("Highlight", gui, { Adornee = other.Character, FillColor = Color3.fromRGB(160, 240, 255), OutlineColor = Color3.fromRGB(245, 255, 255), FillTransparency = 0.2, OutlineTransparency = 0 })
            local jewel = create("BillboardGui", gui, { Adornee = other.Character:FindFirstChild("Head"), Size = UDim2.fromOffset(70, 70), StudsOffsetWorldSpace = Vector3.new(0, 3, 0), AlwaysOnTop = true })
            local diamond = create("Frame", jewel, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(24, 24), Rotation = 45, BackgroundColor3 = Color3.fromRGB(180, 245, 255), BorderSizePixel = 0 })
            local started = os.clock()
            local pulse
            pulse = RunService.RenderStepped:Connect(function()
                local age = os.clock() - started
                if age > 2.5 or not shine.Parent then pulse:Disconnect(); shine:Destroy(); jewel:Destroy(); return end
                shine.FillTransparency = math.clamp(0.35 + age / 4 + math.sin(age * 12) * 0.15, 0, 1)
                shine.OutlineTransparency = age / 2.5
                diamond.BackgroundTransparency = age / 2.5
                diamond.Rotation = 45 + math.sin(age * 4) * 20
            end)
            table.insert(cleanups, function() pulse:Disconnect(); shine:Destroy(); jewel:Destroy() end)
        end
    end
    friendInput.Text = ""
    changed()
    refreshFriendList()
end)
local function gconnect(event, callback)
    table.insert(graphConnections, event:Connect(callback))
end
local function wire(a, b)
    local reach = (b.X - a.X) * 0.5
    local path = create("Path2D", graph, {
        Name = "BranchCurve", Color3 = Color3.fromRGB(104, 116, 136),
        Thickness = 1.5, ZIndex = 1, Visible = true,
    })
    path:SetControlPoints({
        Path2DControlPoint.new(UDim2.fromOffset(a.X, a.Y), UDim2.fromOffset(0, 0), UDim2.fromOffset(reach, 0)),
        Path2DControlPoint.new(UDim2.fromOffset(b.X, b.Y), UDim2.fromOffset(-reach, 0), UDim2.fromOffset(0, 0)),
    })
end
local function node(label, x, y, width, selected, callback)
    local object = button(graph, label, UDim2.fromOffset(x, y), UDim2.fromOffset(width, 30))
    object.BackgroundTransparency = selected and 0 or 0.08
    object.TextColor3 = selected and palette.accent or palette.text
    object.TextSize = 13
    object.ZIndex = 3
    object.AutoButtonColor = false
    object:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, 10)
    create("UIGradient", object, {
        Rotation = 90,
        Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(195, 205, 225)),
    })
    object.TextXAlignment = Enum.TextXAlignment.Left
    create("UIPadding", object, { PaddingLeft = UDim.new(0, 24), PaddingRight = UDim.new(0, 10) })
    local indicator = create("Frame", object, {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, -15, 0.5, 0), Size = UDim2.fromOffset(3, 12),
        BackgroundColor3 = palette.accent, BackgroundTransparency = selected and 0.1 or 1,
        BorderSizePixel = 0,
    })
    rounded(indicator, 3)
    if selected and settings.motion then
        local gradient = object:FindFirstChildOfClass("UIGradient")
        gradient.Offset = Vector2.new(-0.25, 0)
        local shimmer = TweenService:Create(gradient, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Offset = Vector2.new(0.25, 0) })
        table.insert(graphTweens, shimmer)
        shimmer:Play()
    end
    local restTransparency = object.BackgroundTransparency
    object.Position = UDim2.fromOffset(x + 12, y)
    object.BackgroundTransparency, object.TextTransparency = 1, 1
    animate(object, { Position = UDim2.fromOffset(x, y), BackgroundTransparency = restTransparency,
        TextTransparency = 0 }, 0.24, math.min(0.16, x / 6000 + y / 6000))
    local hoverTween
    gconnect(object.MouseEnter, function()
        if hoverTween then hoverTween:Cancel() end
        hoverTween = TweenService:Create(object, TweenInfo.new(0.14), {
            BackgroundColor3 = Color3.fromRGB(42, 49, 64), TextColor3 = Color3.fromRGB(255, 255, 255),
        })
        hoverTween:Play()
    end)
    gconnect(object.MouseLeave, function()
        if hoverTween then hoverTween:Cancel() end
        hoverTween = TweenService:Create(object, TweenInfo.new(0.2), {
            BackgroundColor3 = palette.control, TextColor3 = selected and palette.accent or palette.text,
        })
        hoverTween:Play()
    end)
    gconnect(object.Activated, callback)
    return object
end
renderGraph = function()
    if detail.Visible then return end
    if selectedCategory == "Бинды" or selectedCategory == "Friends" then
        selectedCategory, selectedGroup = "Настройки", "Оформление"
    end
    cancelAnimations()
    for _, connection in ipairs(graphConnections) do connection:Disconnect() end
    table.clear(graphConnections)
    graph:ClearAllChildren()
    for _, page in pairs(pages) do page.Visible = false end
    searchResults.Visible = false
    for _, tabButton in pairs(tabButtons) do tabButton.Visible = false end
    graph.Visible = true
    local query = normalizeQuery(search.Text)
    local categories = { "Наведение", "ESP", "Мир", "Камера", "Бинды", "Настройки", "Friends" }
    node("OKTAN", 12, 212, 105, true, function() selectedCategory = "Наведение"; selectedGroup = "Наведение"; renderGraph() end)
    for index, category in ipairs(categories) do
        local y = 18 + (index - 1) * 52
        wire(Vector2.new(117, 227), Vector2.new(174, y + 15))
        node(displayNames[category] or category, 174, y, 130, category == selectedCategory, function()
            graph.CanvasPosition = Vector2.new(0, 0)
            selectedCategory = category
            if category == "Бинды" then
                openDetail("Keybinds")
                for index, object in ipairs(roleRows) do moveDetail(object, index) end
                for index, entry in ipairs(bindingRows) do moveDetail(entry.frame, index + #roleRows) end
            elseif category == "Friends" then
                openDetail("Friends")
                refreshFriendList()
                moveDetail(friendForm, 1)
            else
                selectedGroup = treeGroups[category][1]
                renderGraph()
            end
        end)
    end
    local categoryY = 33
    for index, category in ipairs(categories) do
        if category == selectedCategory then categoryY = 33 + (index - 1) * 52 end
    end
    local groups = treeGroups[selectedCategory] or {}
    if selectedCategory == "Настройки" then groups = { "Оформление", "Инвентарь", "Dynamic Island", "Клиент" } end
    local selectedY = 90
    for index, group in ipairs(groups) do
        local y = 35 + (index - 1) * 88
        wire(Vector2.new(304, categoryY), Vector2.new(350, y + 15))
        node(displayNames[group] or group, 350, y, 170, group == selectedGroup, function()
            graph.CanvasPosition = Vector2.new(0, 0)
            selectedGroup = group
            renderGraph()
        end)
        if group == selectedGroup then selectedY = y + 15 end
    end
    local leaves = {}
    for _, entry in ipairs(controlRows) do
        local definition = schema[entry.key]
        local hiddenColorChannel = entry.key:match("Saturation$") or entry.key:match("Value$")
        local matches = query ~= "" and normalizeQuery(definition[3] .. " " .. definition[4] .. " " .. entry.key):find(query, 1, true)
        if not hiddenColorChannel and (matches or (query == "" and (entry.page == selectedCategory or (selectedCategory == "Настройки" and entry.page == "Бинды")) and settingGroup[entry.key] == selectedGroup)) then
            table.insert(leaves, entry)
        end
    end
    if query ~= "" and #leaves == 0 then
        text(graph, "Ничего не найдено", { Position = UDim2.fromOffset(588, 24), Size = UDim2.fromOffset(258, 40), TextColor3 = palette.muted })
    end
    for index, entry in ipairs(leaves) do
        local definition = schema[entry.key]
        local y = 14 + (index - 1) * 40
        wire(Vector2.new(520, selectedY), Vector2.new(588, y + 15))
        local assigned = bindings[entry.key]
        local label = (entry.key:match("Hue$") and (entry.key == "menuHue" and "Menu Color" or entry.key == "espHue" and "ESP Color" or "FOV Color") or definition[3]) .. (assigned and "  [" .. assigned .. "]" or "")
        if query ~= "" then label = (displayNames[entry.page] or entry.page) .. " / " .. label end
        local control = node(label, 588, y, 258, settings[entry.key] == true, function()
            openDetail(definition[3])
            if entry.key:match("Hue$") then
                local prefix = entry.key:gsub("Hue$", "")
                local panel = create("Frame", detailBody, { Size = UDim2.new(1, -20, 0, 410), BackgroundTransparency = 1, LayoutOrder = 1 })
                table.insert(temporaryRows, panel)
                local initial = Color3.fromHSV(settings[entry.key] / 360, settings[prefix .. "Saturation"] / 100, settings[prefix .. "Value"] / 100)
                local before = create("Frame", panel, { Position = UDim2.fromOffset(8, 28), Size = UDim2.fromOffset(110, 36), BackgroundColor3 = initial })
                local after = create("Frame", panel, { Position = UDim2.fromOffset(132, 28), Size = UDim2.fromOffset(110, 36), BackgroundColor3 = initial })
                rounded(before, 8); rounded(after, 8)
                text(panel, "Было                     Стало", { Position = UDim2.fromOffset(8, 0), Size = UDim2.fromOffset(280, 24) })
                local function choose(color)
                    local h, sat, value = color:ToHSV()
                    setValue(entry.key, math.round(h * 359))
                    setValue(prefix .. "Saturation", math.round(sat * 100))
                    setValue(prefix .. "Value", math.round(value * 100))
                    after.BackgroundColor3 = color
                end
                local presets = { {235,215,180}, {255,195,210}, {245,160,185}, {210,180,245}, {175,190,250}, {150,210,250}, {155,230,225}, {170,235,195}, {215,245,145}, {250,230,155}, {250,195,145}, {245,155,140}, {205,205,220}, {245,245,245}, {130,150,180} }
                for index, rgb in ipairs(presets) do
                    local color = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
                    local swatch = button(panel, "", UDim2.fromOffset(8 + ((index - 1) % 15) * 36, 82), UDim2.fromOffset(30, 30))
                    swatch.BackgroundColor3 = color
                    swatch.Activated:Connect(function() choose(color) end)
                end
                for row = 0, 5 do
                    for column = 0, 23 do
                        local color = Color3.fromHSV(column / 24, row < 3 and (row + 1) / 3 or 1, row < 3 and 1 or (7 - row) / 5)
                        local swatch = button(panel, "", UDim2.fromOffset(8 + column * 22, 132 + row * 32), UDim2.fromOffset(21, 30))
                        swatch.BackgroundColor3 = color
                        swatch.Activated:Connect(function() choose(color) end)
                    end
                end
                local hex = text(panel, "", { Position = UDim2.fromOffset(270, 342), Size = UDim2.fromOffset(150, 34), PlaceholderText = "#RRGGBB", ClearTextOnFocus = false }, "TextBox")
                hex.FocusLost:Connect(function()
                    local value = hex.Text:gsub("#", ""):match("^%s*(%x%x%x%x%x%x)%s*$")
                    if value then
                        choose(Color3.fromRGB(tonumber(value:sub(1, 2), 16), tonumber(value:sub(3, 4), 16), tonumber(value:sub(5, 6), 16)))
                    end
                end)
                local reset = button(panel, "Вернуть исходный", UDim2.fromOffset(8, 342), UDim2.fromOffset(200, 34))
                reset.Activated:Connect(function() choose(initial) end)
            else moveDetail(entry.frame, 1) end
            if entry.key == "killFx" then
                local preview = button(detailBody, "Preview Soul", UDim2.fromOffset(0, 0), UDim2.fromOffset(180, 36))
                preview.LayoutOrder = 3
                table.insert(temporaryRows, preview)
                preview.Activated:Connect(function() settings._soulPreviewRequested = true end)
            end
            local explanation = text(detailBody, definition[4], {
                Size = UDim2.new(1, -20, 0, 70), TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
                TextColor3 = palette.muted, LayoutOrder = 2,
            })
            table.insert(temporaryRows, explanation)
        end)
        middleBind(control, entry.key, gconnect)
        gconnect(control.MouseEnter, function() tooltip.Text = definition[4] .. "\nСКМ — назначить клавишу"; tooltip.Visible = menu.Visible end)
        gconnect(control.MouseLeave, function() tooltip.Visible = false end)
    end
    if selectedCategory == "Настройки" and selectedGroup == "Клиент" then
        node("Save / Reset / Unload", 588, 14 + #leaves * 40, 258, false, function()
            openDetail("Client")
            moveDetail(actionsRow, 1)
        end)
    end
    graph.CanvasSize = UDim2.fromOffset(870, math.max(465, #leaves * 40 + 20))
end
connect(back.Activated, function()
    clearDetail()
    capture, pendingNumeric = nil, nil
    refreshAll()
    detail.Visible = false
    renderGraph()
end)
connect(search:GetPropertyChangedSignal("Text"), function()
    graph.CanvasPosition = Vector2.new(0, 0)
    if detail.Visible then clearDetail(); detail.Visible = false end
    renderGraph()
end)
renderGraph()

end
initializeGraph()

local themeLast
local function applyTheme()
    local signature = table.concat({ settings.menuHue, settings.menuSaturation, settings.menuValue }, ":")
    if themeLast == signature then return end
    themeLast = signature
    local accent = Color3.fromHSV(settings.menuHue / 360, settings.menuSaturation / 100, settings.menuValue / 100)
    palette.accent = accent
    for _, object in ipairs(island:GetDescendants()) do
        if object:IsA("UIStroke") then object.Color = accent end
    end
    menu.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
    for _, object in ipairs(menu:GetDescendants()) do
        if object:IsA("UIStroke") and object.Name ~= "DecorationStroke" then object.Color = accent; object.Transparency = 0.8 end
        if object:IsA("ScrollingFrame") then object.ScrollBarImageColor3 = accent end
    end
    for _, fill in ipairs(sliderFills) do fill.BackgroundColor3 = accent end
    refreshAll()
end

local overrides = {}
local function override(key, instance, property, value)
    local previous = overrides[key]
    if previous and (previous.instance ~= instance or value == nil) then
        previous.connection:Disconnect()
        overrides[key] = nil
        if previous.instance.Parent and previous.instance[property] == previous.applied then
            previous.instance[property] = previous.original
        end
        previous = nil
    end
    if value == nil or not instance then return end
    if not previous then
        previous = { instance = instance, property = property, original = instance[property],
            applied = value, writing = false }
        overrides[key] = previous
        previous.connection = instance:GetPropertyChangedSignal(property):Connect(function()
            if previous.writing or overrides[key] ~= previous then return end
            local current = instance[property]
            if current == previous.applied then return end
            previous.original = current
            previous.reapplied = true
            previous.writing = true
            instance[property] = previous.applied
            previous.writing = false
        end)
    end
    previous.applied = value
    if instance[property] ~= value then
        previous.writing = true
        instance[property] = value
        previous.writing = false
    end
end
local function enforceOverrides()
    for _, entry in pairs(overrides) do
        entry.reapplied = false
        if entry.instance.Parent and entry.instance[entry.property] ~= entry.applied then
            entry.original = entry.instance[entry.property]
            entry.writing, entry.reapplied = true, true
            entry.instance[entry.property] = entry.applied
            entry.writing = false
        end
    end
end
local brightProperties = {
    Brightness = 3, Ambient = Color3.fromRGB(210, 210, 210),
    OutdoorAmbient = Color3.fromRGB(210, 210, 210), GlobalShadows = false,
    ExposureCompensation = 0.4,
}
local atmosphericOverrides = {}
local function updateLighting()
    for property, value in pairs(brightProperties) do
        local desired
        if settings.bright then desired = value end
        override(property, Lighting, property, desired)
    end
    override("ClockTime", Lighting, "ClockTime", settings.clock and settings.hour or nil)
    override("FogEnd", Lighting, "FogEnd", settings.noFog and 100000 or nil)
    local seen = {}
    local lightingObjects = Lighting:GetChildren()
    if workspace.CurrentCamera then
        for _, effect in ipairs(workspace.CurrentCamera:GetChildren()) do table.insert(lightingObjects, effect) end
    end
    for _, object in ipairs(lightingObjects) do
        if object:IsA("Atmosphere") then
            local entry = atmosphericOverrides[object]
            if not entry then
                entry = { density = {}, haze = {} }
                atmosphericOverrides[object] = entry
            end
            seen[object] = true
            override(entry.density, object, "Density", (settings.noFog or settings.bright) and 0 or nil)
            override(entry.haze, object, "Haze", (settings.noFog or settings.bright) and 0 or nil)
        elseif object:IsA("ColorCorrectionEffect") then
            local entry = atmosphericOverrides[object]
            if not entry then
                entry = { enabled = {} }
                atmosphericOverrides[object] = entry
            end
            seen[object] = true
            local enabled
            if settings.bright then enabled = false end
            override(entry.enabled, object, "Enabled", enabled)
        end
    end
    for object, entry in pairs(atmosphericOverrides) do
        if not seen[object] then
            for _, key in pairs(entry) do
                local record = overrides[key]
                if record then override(key, record.instance, record.property, nil) end
            end
            atmosphericOverrides[object] = nil
        end
    end
end

do
    local cameraConnection
    local function watchCameraEffects()
        if cameraConnection then cameraConnection:Disconnect() end
        local camera = workspace.CurrentCamera
        cameraConnection = camera and camera.ChildAdded and camera.ChildAdded:Connect(updateLighting)
        updateLighting()
    end
    if Lighting.ChildAdded then connect(Lighting.ChildAdded, updateLighting) end
    connect(workspace:GetPropertyChangedSignal("CurrentCamera"), watchCameraEffects)
    table.insert(cleanups, function() if cameraConnection then cameraConnection:Disconnect() end end)
    watchCameraEffects()
end
local occupiedLabels = {}
local labelMetrics = setmetatable({}, { __mode = "k" })
local function screenLabel(parent)
    return text(parent, "", {
        Visible = false, Font = Enum.Font.Gotham,
        TextSize = 12, TextColor3 = Color3.fromRGB(235, 237, 240),
        TextStrokeColor3 = Color3.fromRGB(8, 8, 10), TextStrokeTransparency = 0.35,
        TextWrapped = false, TextTruncate = Enum.TextTruncate.None,
    })
end
local function placeLabel(label, value, x, y, size, anchorX, anchorY, camera, color, avoidOverlap)
    label.Visible = false
    if value == "" then return 0 end
    local metrics = labelMetrics[label]
    if not metrics or metrics.value ~= value or metrics.size ~= size then
        local measured = game:GetService("TextService"):GetTextSize(value, size, Enum.Font.Gotham, Vector2.new(4096, 100))
        metrics = { value = value, size = size, width = math.ceil(measured.X) + 16 }
        labelMetrics[label] = metrics
    end
    local width = metrics.width
    local _, breaks = value:gsub("\n", "")
    local height = (size + 4) * (breaks + 1)
    local left, top = x - width * anchorX, y - height * anchorY
    local viewport = camera.ViewportSize
    left = math.clamp(left, 0, math.max(0, viewport.X - width))
    top = math.clamp(top, 0, math.max(0, viewport.Y - height))
    local originalLeft = left
    local function cells(candidateLeft, callback)
        for gx = math.floor(candidateLeft / 128), math.floor((candidateLeft + width + 2) / 128) do
            for gy = math.floor(top / 64), math.floor((top + height + 2) / 64) do
                if callback(gx .. ":" .. gy) then return true end
            end
        end
        return false
    end
    local function overlaps(candidateLeft)
        return cells(candidateLeft, function(key)
            for _, rectangle in ipairs(occupiedLabels[key] or {}) do
                if candidateLeft < rectangle.right + 2 and candidateLeft + width + 2 > rectangle.left
                    and top < rectangle.bottom + 2 and top + height + 2 > rectangle.top then return true end
            end
            return false
        end)
    end
    if avoidOverlap ~= false then
        for _, shift in ipairs({ metrics.shift or 0, 0, math.min(width + 6, 160), -math.min(width + 6, 160) }) do
            local proposed = originalLeft + shift
            if proposed >= 0 and proposed + width <= viewport.X and not overlaps(proposed) then left = proposed; break end
        end
    end
    metrics.shift = left - originalLeft
    local rectangle = { left = left, top = top, right = left + width, bottom = top + height }
    cells(left, function(key)
        occupiedLabels[key] = occupiedLabels[key] or {}
        table.insert(occupiedLabels[key], rectangle)
        return false
    end)
    label.Position = UDim2.fromOffset(math.round(left), math.round(top))
    label.Size = UDim2.fromOffset(width, height)
    label.Text = value
    label.TextSize = size
    label.TextColor3 = color
    label.Visible = true
    return metrics.shift
end
local bodyNames = {
    Head = true, UpperTorso = true, LowerTorso = true, Torso = true,
    LeftUpperArm = true, LeftLowerArm = true, LeftHand = true,
    RightUpperArm = true, RightLowerArm = true, RightHand = true,
    LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true,
    RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
    ["Left Arm"] = true, ["Right Arm"] = true, ["Left Leg"] = true, ["Right Leg"] = true,
}
local function bodyBounds(camera, candidate)
    local minimum = Vector2.new(math.huge, math.huge)
    local maximum = Vector2.new(-math.huge, -math.huge)
    local found = false
    local parts = candidate.bodyParts
    if not (settings.boxes or settings.corners or settings.healthBar or settings.skeleton) then
        local headPoint = camera:WorldToViewportPoint(candidate.head.Position + Vector3.new(0, candidate.head.Size.Y * 0.5, 0))
        local feetPoint = camera:WorldToViewportPoint(candidate.root.Position - Vector3.new(0, 3, 0))
        if headPoint.Z <= 0.1 or feetPoint.Z <= 0.1 then return nil end
        return Vector2.new(math.min(headPoint.X, feetPoint.X) - 10, math.min(headPoint.Y, feetPoint.Y)),
            Vector2.new(math.max(headPoint.X, feetPoint.X) + 10, math.max(headPoint.Y, feetPoint.Y))
    end
    for _, part in ipairs(parts) do
        if part:IsDescendantOf(workspace) then
            local half = part.Size * 0.5
            for x = -1, 1, 2 do
                for y = -1, 1, 2 do
                    for z = -1, 1, 2 do
                        local position = part.CFrame:PointToWorldSpace(Vector3.new(half.X * x, half.Y * y, half.Z * z))
                        local point = camera:WorldToViewportPoint(position)
                        if point.Z <= 0.1 then return nil end
                        minimum = Vector2.new(math.min(minimum.X, point.X), math.min(minimum.Y, point.Y))
                        maximum = Vector2.new(math.max(maximum.X, point.X), math.max(maximum.Y, point.Y))
                        found = true
                    end
                end
            end
        end
    end
    if not found or maximum.X < 0 or maximum.Y < 0
        or minimum.X > camera.ViewportSize.X or minimum.Y > camera.ViewportSize.Y then return nil end
    return minimum, maximum
end
local function renderLabels(screen, candidate, low, high, camera, color)
    local height = math.max(1, high.Y - low.Y)
    local size = settings.textSize
    if settings.adaptiveText then
        size = math.clamp(math.floor(size * math.sqrt(height / 110)), 9, settings.textSize)
    end
    local center = (low.X + high.X) / 2
    -- Screen-space gaps keep text outside the body at any distance or lean angle.
    local weapon = settings.weapon and heldItem(candidate.model)
    local lines = {}
    if settings.names then table.insert(lines, (candidate.owner and candidate.owner.Name or candidate.model.Name) .. (isFriend(candidate.owner) and " [ALLY]" or "")) end
    if settings.health then table.insert(lines, string.format("%d HP", math.ceil(candidate.humanoid.Health))) end
    local distance = (candidate.root.Position - camera.CFrame.Position).Magnitude
    if settings.distance then table.insert(lines, string.format("%d st", math.round(distance))) end
    screen.healthLabel.Visible, screen.distanceLabel.Visible = false, false
    local shift = placeLabel(screen.nameLabel, table.concat(lines, "\n"), center, low.Y - 4, size, 0.5, 1, camera, color)
    if not screen.labelLeader then screen.labelLeader = create("Frame", screen.container, { BorderSizePixel = 0, BackgroundTransparency = 0.45 }) end
    screen.labelLeader.Visible = screen.nameLabel.Visible and math.abs(shift) > 2
    screen.labelLeader.BackgroundColor3 = color
    screen.labelLeader.Position = UDim2.fromOffset(math.round(math.min(center, center + shift)), math.round(low.Y - 3))
    screen.labelLeader.Size = UDim2.fromOffset(math.round(math.abs(shift)), 1)
    placeLabel(screen.weaponLabel, weapon and weapon.Name or "", center + shift, high.Y + 4, size, 0.5, 0, camera, color, false)
end

local worldIndex
do
local function initializeWorldIndex()
    local index, pending, queued, cursor = {}, {}, setmetatable({}, { __mode = "k" }), 1
    local function enqueue(object)
        if not queued[object] then queued[object] = true; table.insert(pending, object) end
    end
    for _, child in ipairs(workspace:GetChildren()) do enqueue(child) end
    connect(workspace.DescendantAdded, function(object)
        if object:IsA("Humanoid") and object.Parent and object.Parent:IsA("Model") then index[object.Parent] = object end
        enqueue(object)
    end)
    worldIndex = { npcs = index }
    worldIndex.step = function(budget)
        while cursor <= #pending and budget > 0 do
            local object = pending[cursor]
            cursor += 1; budget -= 1
            if object.Parent and object ~= workspace.CurrentCamera then
                if object:IsA("Humanoid") and object.Parent:IsA("Model") then index[object.Parent] = object end
                if not (object:IsA("Model") and Players:GetPlayerFromCharacter(object)) then
                    for _, child in ipairs(object:GetChildren()) do enqueue(child) end
                end
            end
        end
        if cursor > #pending then table.clear(pending); cursor = 1 end
        local count = 0
        for model, humanoid in pairs(index) do
            if not model.Parent or not humanoid.Parent then index[model] = nil
            elseif not Players:GetPlayerFromCharacter(model) and not (workspace.CurrentCamera and model:IsDescendantOf(workspace.CurrentCamera)) then count += 1 end
        end
        settings._npcCount = count
    end
    table.insert(cleanups, function() table.clear(index); table.clear(pending) end)
    return worldIndex
end
worldIndex = initializeWorldIndex()
end

local candidates = {}
local function addCandidate(model, owner)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")
    if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
        local head = model:FindFirstChild("Head")
        local bodyParts = {}
        for _, part in ipairs(model:GetChildren()) do
            if part:IsA("BasePart") and bodyNames[part.Name] then table.insert(bodyParts, part) end
        end
        if #bodyParts == 0 then table.insert(bodyParts, root) end
        table.insert(candidates, {
            model = model,
            owner = owner,
            root = root,
            head = head and head:IsA("BasePart") and head or root,
            humanoid = humanoid, bodyParts = bodyParts,
        })
    end
end

local function refreshCandidates()
    table.clear(candidates)
    if (settings.aim and settings.aimPlayers) or (settings.esp and settings.espPlayers) then
        for _, other in ipairs(Players:GetPlayers()) do
            if other ~= player and other.Character then
                addCandidate(other.Character, other)
            end
        end
    end
    if (settings.aim and settings.aimDummies) or (settings.esp and settings.espDummies) then
        worldIndex.step(256)
        for model, humanoid in pairs(worldIndex.npcs) do
            if model.Parent and humanoid.Health > 0 and not Players:GetPlayerFromCharacter(model)
                and not (workspace.CurrentCamera and model:IsDescendantOf(workspace.CurrentCamera)) then addCandidate(model, nil) end
        end
    end
end

local espRay = RaycastParams.new()
espRay.FilterType = Enum.RaycastFilterType.Exclude
espRay.IgnoreWater = true
local function newScreenMarker()
    local container = create("Frame", overlay, {
        BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false,
    })
    return {
        container = container, lines = {}, used = 0, joints = {}, jointsAt = -1,
        nameLabel = screenLabel(container), healthLabel = screenLabel(container),
        weaponLabel = screenLabel(container), distanceLabel = screenLabel(container),
    }
end
local function line(screen, a, b, color, thickness)
    local difference = b - a
    local length = difference.Magnitude
    if length < 0.1 then return end
    screen.used += 1
    local segment = screen.lines[screen.used]
    if not segment then
        segment = create("Frame", screen.container, {
            AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0,
        })
        screen.lines[screen.used] = segment
    end
    local center = (a + b) * 0.5
    segment.Position = UDim2.fromOffset(center.X, center.Y)
    segment.Size = UDim2.fromOffset(length, thickness or settings.lineWidth)
    segment.Rotation = math.deg(math.atan2(difference.Y, difference.X))
    segment.BackgroundColor3 = color
    segment.BackgroundTransparency = 1 - settings.espOpacity / 100
    segment.Visible = true
end
local function project(camera, position)
    local point = camera:WorldToViewportPoint(position)
    if point.Z <= 0.1 then return nil end
    return Vector2.new(point.X, point.Y)
end
local function renderScreenMarker(marker, camera, color)
    local screen = marker.screen
    screen.used = 0
    local candidate = marker.candidate
    local enabled = settings.esp and not menu.Visible and camera and candidate and candidate.model:IsDescendantOf(workspace)
        and candidate.root:IsDescendantOf(workspace) and candidate.humanoid.Health > 0
        and (settings.through or not marker.occluded)
    screen.container.Visible = enabled == true
    if not enabled then return end
    local model = candidate.model
    if isFriend(candidate.owner) then color = Color3.fromRGB(85, 235, 150) end
    local projected = camera:WorldToViewportPoint(candidate.root.Position)
    local viewport = camera.ViewportSize
    if projected.Z > 10 and (projected.X < -260 or projected.Y < -260
        or projected.X > viewport.X + 260 or projected.Y > viewport.Y + 260) then
        screen.container.Visible = false
        return
    end
    local low, high = bodyBounds(camera, candidate)
    screen.container.Visible = low ~= nil
    if not low then return end
    renderLabels(screen, candidate, low, high, camera, color)
    if settings.boxes or settings.corners or settings.healthBar then
        if low then
            local width, height = high.X - low.X, high.Y - low.Y
            local topRight = Vector2.new(high.X, low.Y)
            local bottomLeft = Vector2.new(low.X, high.Y)
            if settings.corners then
                for _, corner in ipairs({
                    { low, 1, 1 }, { topRight, -1, 1 }, { high, -1, -1 }, { bottomLeft, 1, -1 },
                }) do
                    local point = corner[1]
                    line(screen, point, point + Vector2.new(width * 0.25 * corner[2], 0), color)
                    line(screen, point, point + Vector2.new(0, height * 0.25 * corner[3]), color)
                end
            elseif settings.boxes then
                line(screen, low, topRight, color)
                line(screen, topRight, high, color)
                line(screen, high, bottomLeft, color)
                line(screen, bottomLeft, low, color)
            end
            if settings.healthBar then
                local fraction = math.clamp(candidate.humanoid.Health / math.max(candidate.humanoid.MaxHealth, 1), 0, 1)
                local bottom = Vector2.new(low.X - 6, high.Y)
                line(screen, bottom, Vector2.new(low.X - 6, low.Y), Color3.fromRGB(25, 30, 40), 5)
                line(screen, bottom, Vector2.new(low.X - 6, high.Y - height * fraction),
                    Color3.fromHSV(fraction / 3, 0.8, 1), 3)
            end
        end
    end
    if settings.tracers then
        local point = project(camera, candidate.root.Position)
        if point then line(screen, Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y - 5), point, color) end
    end
    if settings.skeleton then
        if os.clock() - screen.jointsAt > 1 then
            screen.jointsAt = os.clock()
            table.clear(screen.joints)
            for _, joint in ipairs(model:GetDescendants()) do
                if joint:IsA("Motor6D") and joint.Part0 and joint.Part1
                    and joint.Part0.Parent == model and joint.Part1.Parent == model then
                    table.insert(screen.joints, joint)
                end
            end
        end
        for _, joint in ipairs(screen.joints) do
            if joint.Parent and joint.Part0 and joint.Part1 then
                local a = project(camera, joint.Part0.Position)
                local b = project(camera, joint.Part1.Position)
                if a and b then line(screen, a, b, color) end
            end
        end
    end
    for index = screen.used + 1, #screen.lines do screen.lines[index].Visible = false end
end

local markersByModel = {}
local orderedMarkers = {}
local function destroyMarker(marker)
    marker.screen.container:Destroy()
    marker.highlight:Destroy()
end

local function updateMarkers(camera)
    local seen = {}
    if settings.esp and camera then
        for _, candidate in ipairs(candidates) do
            local owner = candidate.owner
            if (owner and settings.espPlayers) or (not owner and settings.espDummies) then
                local distance = (candidate.root.Position - camera.CFrame.Position).Magnitude
                if distance <= settings.range then
                    local model = candidate.model
                    seen[model] = true
                    local marker = markersByModel[model]
                    if not marker then
                        local highlight = create("Highlight", model, {
                            Name = "DeltaOutline",
                            Adornee = model,
                            FillTransparency = 0.82,
                            FillColor = palette.accent,
                            OutlineColor = palette.accent,
                        })
                        marker = { highlight = highlight, screen = newScreenMarker() }
                        markersByModel[model] = marker
                    end
                    marker.candidate = candidate
                    marker.distance = distance
                    espRay.FilterDescendantsInstances = player.Character and { player.Character, camera } or { camera }
                    local hit = not settings.through and workspace:Raycast(
                        camera.CFrame.Position, candidate.root.Position - camera.CFrame.Position, espRay)
                    marker.occluded = hit and not hit.Instance:IsDescendantOf(model) or false
                    local color = Color3.fromHSV(settings.espHue / 360, settings.espSaturation / 100, settings.espValue / 100)
                    if isFriend(owner) then color = Color3.fromRGB(85, 235, 150) end
                    marker.highlight.FillColor = color
                    marker.highlight.OutlineColor = color
                    marker.highlight.FillTransparency = 1 - settings.fillOpacity / 100
                    marker.highlight.OutlineTransparency = 1 - settings.espOpacity / 100
                    marker.highlight.Enabled = not menu.Visible and settings.chams
                    marker.highlight.DepthMode = settings.through
                        and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
                end
            end
        end
    end
    for model, marker in pairs(markersByModel) do
        if not seen[model] then
            destroyMarker(marker)
            markersByModel[model] = nil
        end
    end
    table.clear(orderedMarkers)
    for _, marker in pairs(markersByModel) do table.insert(orderedMarkers, marker) end
    table.sort(orderedMarkers, function(a, b)
        if a.distance == b.distance then return a.candidate.model.Name < b.candidate.model.Name end
        return a.distance < b.distance
    end)
end

local castParams = RaycastParams.new()
castParams.FilterType = Enum.RaycastFilterType.Exclude
castParams.IgnoreWater = true
local lockedModel, aimRotation
local function aimAt(camera, deltaTime)
    local character = player.Character
    castParams.FilterDescendantsInstances = character and { character, camera } or { camera }
    local center = camera.ViewportSize * 0.5
    local origin = camera.CFrame.Position
    local bestPosition, bestModel
    local bestError = settings.radius
    for _, candidate in ipairs(candidates) do
        local owner = candidate.owner
        local teammate = owner and player.Team ~= nil and not player.Neutral and not owner.Neutral
            and owner.Team == player.Team
        local eligible = (owner and settings.aimPlayers) or (not owner and settings.aimDummies)
        local part = settings.head and candidate.head or candidate.root
        if eligible and not isFriend(owner) and not (settings.team and teammate)
            and part:IsDescendantOf(workspace) and candidate.humanoid.Health > 0 then
            local point = part.Position
            local projected, visible = camera:WorldToViewportPoint(point)
            if visible and projected.Z > 0 then
                local errorPixels = (Vector2.new(projected.X, projected.Y) - center).Magnitude
                local score = errorPixels
                if settings.sticky and candidate.model == lockedModel then score *= 0.65 end
                if errorPixels <= settings.radius and score < bestError then
                    local hit = settings.wall and workspace:Raycast(origin, point - origin, castParams)
                    if not hit or hit.Instance:IsDescendantOf(candidate.model) then
                        bestError, bestPosition, bestModel = score, point, candidate.model
                    end
                end
            end
        end
    end
    if bestPosition then
        if lockedModel ~= bestModel then aimRotation = camera.CFrame.Rotation end
        lockedModel = bestModel
        local base = CFrame.new(origin) * (aimRotation or camera.CFrame.Rotation)
        local goal = CFrame.lookAt(origin, bestPosition)
        local nextFrame = base:Lerp(goal, 1 - math.exp(-settings.smooth * math.min(deltaTime, 0.1)))
        aimRotation = nextFrame.Rotation
        camera.CFrame = nextFrame
    else
        lockedModel, aimRotation = nil, nil
    end
end

local updateWinter
do
local function initializeWinter()
    local decoration = create("Frame", menu, {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        ClipsDescendants = true, ZIndex = 0,
    })
    rounded(decoration, 22)
    local bubbles, flakes, drifts, hats = {}, {}, {}, {}
    for index = 1, 5 do
        local bubble = create("Frame", decoration, {
            BackgroundColor3 = palette.accent, BackgroundTransparency = 0.95,
            BorderSizePixel = 0, Size = UDim2.fromOffset(120 + index * 24, 120 + index * 24),
        })
        rounded(bubble, 1000)
        local border = stroke(bubble, palette.accent)
        border.Name = "DecorationStroke"
        border.Transparency = 0.97
        create("UIGradient", bubble, {
            Rotation = index * 43,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.5, 0.7),
                NumberSequenceKeypoint.new(1, 0.95),
            }),
        })
        table.insert(bubbles, bubble)
    end
    for index = 1, 18 do
        local flake = create("Frame", decoration, {
            BackgroundTransparency = 1, Size = UDim2.fromOffset(8, 8),
        })
        for angle = 0, 120, 60 do
            create("Frame", flake, {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(8, 1), BackgroundColor3 = Color3.fromRGB(235, 245, 255),
                BackgroundTransparency = 0.25, BorderSizePixel = 0, Rotation = angle,
            })
        end
        table.insert(flakes, flake)
    end
    for index = 1, 10 do
        local drift = create("Frame", decoration, {
            Size = UDim2.fromOffset(140, 55), BackgroundColor3 = Color3.fromRGB(228, 240, 250),
            BackgroundTransparency = 0.86, BorderSizePixel = 0,
        })
        rounded(drift, 100)
        table.insert(drifts, drift)
    end
    local hatFolder = create("Folder", workspace, { Name = "OktanFriendHats" })
    local function removeHat(entry)
        entry.model:Destroy()
        entry.tag:Destroy()
    end
    table.insert(cleanups, function()
        for _, entry in pairs(hats) do removeHat(entry) end
        hatFolder:Destroy()
    end)
    local time, scanElapsed = 0, 1
    return function(dt)
        time += dt
        scanElapsed += dt
        decoration.Visible = menu.Visible
        if menu.Visible then
            for index, bubble in ipairs(bubbles) do
                bubble.Visible = settings.bubbles
                if settings.bubbles then
                    bubble.Position = UDim2.fromOffset(
                        360 + math.sin(time * 0.14 + index * 1.7) * 360,
                        220 + math.cos(time * 0.11 + index) * 210)
                    bubble.BackgroundColor3 = palette.accent
                end
            end
            for index, flake in ipairs(flakes) do
                flake.Visible = settings.snow
                if settings.snow then
                    flake.Position = UDim2.fromScale((index * 0.137 + math.sin(time * 0.3 + index) * 0.02) % 1,
                        (index * 0.113 + time * 0.025) % 1)
                    flake.Rotation = (time * 9 + index * 24) % 360
                end
            end
            for index, drift in ipairs(drifts) do
                drift.Visible = settings.snowDrifts
                if settings.snowDrifts then
                    drift.Position = UDim2.new(0, 28 + (index - 1) * 80, 1, -12 + math.sin(time + index) * 3)
                end
            end
        end
        if scanElapsed >= 0.5 then
            scanElapsed = 0
            local seen = {}
            if settings.friendHats then
                for _, other in ipairs(Players:GetPlayers()) do
                    local character = other.Character
                    local head = character and character:FindFirstChild("Head")
                    if isFriend(other) and head and head:IsA("BasePart") then
                        seen[other] = true
                        if not hats[other] or hats[other].head ~= head then
                            if hats[other] then removeHat(hats[other]) end
                            local model = create("Model", hatFolder)
                            local parts = {}
                            for index = 1, 5 do
                                parts[index] = create("Part", model, {
                                    Shape = index == 1 and Enum.PartType.Cylinder or Enum.PartType.Ball, Anchored = true,
                                    CanCollide = false, CanTouch = false, CanQuery = false,
                                    CastShadow = false, Material = Enum.Material.SmoothPlastic,
                                    Color = (index == 1 or index == 5) and Color3.fromRGB(245, 245, 250) or Color3.fromRGB(195, 45, 66),
                                    Size = Vector3.new(1, 1, 1),
                                })
                            end
                            create("SpecialMesh", parts[2], { MeshType = Enum.MeshType.FileMesh, MeshId = "rbxasset://fonts/cone.mesh" })
                            parts[3].Transparency, parts[4].Transparency = 1, 1
                            local tag = create("BillboardGui", gui, {
                                Adornee = head, Size = UDim2.fromOffset(160, 22),
                                StudsOffsetWorldSpace = Vector3.new(0, 2.4, 0), AlwaysOnTop = false,
                            })
                            text(tag, other.Name .. " [ALLY]", {
                                Size = UDim2.fromScale(1, 1), TextColor3 = Color3.fromRGB(90, 235, 155),
                                TextSize = 12, TextStrokeTransparency = 0.3,
                            })
                            hats[other] = { model = model, parts = parts, head = head, tag = tag }
                        end
                    end
                end
            end
            for other, entry in pairs(hats) do
                if not seen[other] then removeHat(entry); hats[other] = nil end
            end
        end
        for _, entry in pairs(hats) do
            if entry.head:IsDescendantOf(workspace) then
                local head = entry.head
                entry.tag.Enabled = not settings.esp
                for index, part in ipairs(entry.parts) do
                    if index == 1 then
                        part.Size = Vector3.new(0.24, head.Size.Z * 1.35, head.Size.X * 1.35)
                        part.CFrame = head.CFrame * CFrame.new(0, head.Size.Y / 2 + 0.12, 0) * CFrame.Angles(0, 0, math.pi / 2)
                    elseif index == 2 then
                        part.Size = Vector3.new(head.Size.X * 1.2, 1.15, head.Size.Z * 1.2)
                        part.CFrame = head.CFrame * CFrame.new(0.1, head.Size.Y / 2 + 0.7, 0) * CFrame.Angles(0, 0, -0.15)
                    elseif index == 5 then
                        part.Size = Vector3.new(0.32, 0.32, 0.32)
                        part.CFrame = head.CFrame * CFrame.new(0.2, head.Size.Y / 2 + 1.3, 0)
                    end
                end
            end
        end
    end
end
updateWinter = initializeWinter()
end

local updateCameraVisuals
do
local function initializeCameraVisuals()
    local tracked, viewmodels = {}, {}
    local fov = {}
    local traceElapsed = 0
    settings._cameraTrace = {}
    local function adsInput()
        return settings._ads or (focused and not menu.Visible and Input:GetFocusedTextBox() == nil and Input:IsMouseButtonPressed(Enum.UserInputType.MouseButton2))
    end
    local function restoreFov(preservePresentation)
        if fov.connection then fov.connection:Disconnect() end
        if not preservePresentation and fov.camera and fov.camera.Parent and fov.camera.FieldOfView == fov.applied then
            fov.camera.FieldOfView = fov.native
        end
        table.clear(fov)
    end
    local function applyFov(camera, desired, dt)
        if fov.camera ~= camera or not desired then restoreFov(adsInput()) end
        if not camera or not desired then return end
        if not fov.camera then
            fov.camera, fov.native = camera, camera.FieldOfView
            fov.connection = camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
                if not fov.writing and fov.camera == camera and camera.FieldOfView ~= fov.applied then
                    fov.native = camera.FieldOfView
                    -- Keep equip/sprint FOV writes out of the rendered projection.
                    -- ADS relinquishes ownership immediately from the physical input.
                    if not adsInput() and fov.applied then
                        fov.writing = true
                        camera.FieldOfView = fov.applied
                        fov.writing = false
                    end
                end
            end)
        end
        local previous = fov.applied or camera.FieldOfView
        fov.applied = previous + (desired - previous) * math.min(1, dt / 0.12)
        if math.abs(fov.applied - desired) < 0.01 then fov.applied = desired end
        if camera.FieldOfView ~= fov.applied then
            fov.writing = true
            camera.FieldOfView = fov.applied
            fov.writing = false
        end
    end
    local function initializeVegetation()
    local tracked, queue, queued, cursor = {}, {}, setmetatable({}, { __mode = "k" }), 1
    local tick, previousGrass, previousLeaves, discovered = 1, nil, nil, false
    local terrainState, samples = {}, {}
    local function enqueue(object)
        if not queued[object] then queued[object] = true; table.insert(queue, object) end
    end
    local function category(object)
        local key, ancestor, depth = nil, object, 0
        while ancestor and ancestor ~= workspace and depth < 12 do
            if ancestor == workspace.CurrentCamera or ancestor:FindFirstChildOfClass("Humanoid") then return nil end
            local name = string.lower(ancestor.Name):gsub("[%s_%-]", "")
            local tag = ancestor:GetAttribute("VegetationType")
            if not key then
                if name:find("leaves", 1, true) or name:find("leaf", 1, true) or name:find("foliage", 1, true) or tag == "Leaves" then key = "noLeaves"
                elseif name:find("grass", 1, true) or tag == "Grass" then key = "noGrass" end
            end
            ancestor, depth = ancestor.Parent, depth + 1
        end
        return key
    end
    local function restore(object, entry)
        if entry.original ~= nil and object.Parent and object.LocalTransparencyModifier == 1 then object.LocalTransparencyModifier = entry.original end
        entry.original = nil
    end
    local function terrainGrass(enabled)
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if not terrain then return "Terrain unavailable" end
        if terrainState.object ~= terrain then terrainState = { object = terrain } end
        if enabled and not terrainState.applied then
            local ok, original = pcall(function() return terrain.Decoration end)
            if (not ok or type(original) ~= "boolean") and type(gethiddenproperty) == "function" then
                ok, original = pcall(gethiddenproperty, terrain, "Decoration")
            end
            if not ok or type(original) ~= "boolean" then return "Terrain grass control unavailable" end
            local setOk = pcall(function()
                if type(sethiddenproperty) == "function" then sethiddenproperty(terrain, "Decoration", false)
                else terrain.Decoration = false end
            end)
            if not setOk then return "Terrain grass control unavailable" end
            terrainState.original, terrainState.applied = original, true
        elseif not enabled and terrainState.applied then
            local ok = pcall(function()
                if type(sethiddenproperty) == "function" then sethiddenproperty(terrain, "Decoration", terrainState.original)
                else terrain.Decoration = terrainState.original end
            end)
            if ok then terrainState.applied = false end
        end
        return terrainState.applied and "Terrain grass hidden" or "Terrain grass native"
    end
    for _, child in ipairs(workspace:GetChildren()) do enqueue(child) end
    connect(workspace.DescendantAdded, enqueue)
    table.insert(cleanups, function()
        for object, entry in pairs(tracked) do restore(object, entry) end
        terrainGrass(false)
        table.clear(tracked); table.clear(queue)
    end)
    return function(dt)
        local budget = 160
        while cursor <= #queue and budget > 0 do
            local object = queue[cursor]
            cursor += 1; budget -= 1
            if object.Parent and object ~= workspace.CurrentCamera and not object:FindFirstChildOfClass("Humanoid") then
                if object:IsA("BasePart") and not object:IsA("Terrain") then
                    local key = category(object)
                    if #samples < 80 then
                        local path = object:GetFullName()
                        local lower = string.lower(path)
                        if key or lower:find("tree", 1, true) or lower:find("bush", 1, true) then
                            table.insert(samples, { path = path, class = object.ClassName, category = key,
                                mesh = object:IsA("MeshPart") and object.MeshId or nil })
                        end
                    end
                    if key == "noGrass" and object.CanCollide and object.Size.X > 12 and object.Size.Z > 12 then key = nil end
                    if key and not tracked[object] then tracked[object] = { key = key }; discovered = true end
                end
                for _, child in ipairs(object:GetChildren()) do enqueue(child) end
            end
        end
        if cursor > #queue then table.clear(queue); cursor = 1 end
        tick += dt
        if not discovered and tick < 0.5 and previousGrass == settings.noGrass and previousLeaves == settings.noLeaves then return end
        tick, discovered = 0, false
        previousGrass, previousLeaves = settings.noGrass, settings.noLeaves
        local counts = { noGrass = 0, noLeaves = 0 }
        for object, entry in pairs(tracked) do
            if not object.Parent then tracked[object] = nil
            else
                counts[entry.key] += 1
                if settings[entry.key] then
                    if entry.original == nil or object.LocalTransparencyModifier ~= 1 then entry.original = object.LocalTransparencyModifier end
                    object.LocalTransparencyModifier = 1
                else restore(object, entry) end
            end
        end
        settings._environmentStatus = { grassParts = counts.noGrass, leafParts = counts.noLeaves, terrain = terrainGrass(settings.noGrass), samples = samples }
    end
end
local updateVegetation = initializeVegetation()

    local cameraLast, characterLast, characterConnection, scanTime = nil, nil, nil, 1
    local cameraConnection
    local visorNames = { visor = true, visoroverlay = true, helmetvisor = true,
        facevisor = true, faceplate = true, visoreffect = true }
    local modelNames = { viewmodel = true, viewmodels = true, arms = true, firstperson = true }
    local function normalized(object) return string.lower(object.Name):gsub("[%s_%-]", "") end
    local function remember(object)
        if object:IsDescendantOf(gui) then return end
        if not visorNames[normalized(object)] then return end
        if object:IsA("GuiObject") then tracked[object] = { property = "Visible" }
        elseif object:IsA("BasePart") then tracked[object] = { property = "LocalTransparencyModifier" } end
    end
    for _, object in ipairs(playerGui:GetDescendants()) do remember(object) end
    connect(playerGui.DescendantAdded, remember)
    local function restoreVisor(object, entry)
        if entry.applied ~= nil and object.Parent and object[entry.property] == entry.applied then
            object[entry.property] = entry.original
        end
        entry.applied = nil
    end
    local function restoreModel(model, entry)
        for joint, pose in pairs(entry.joints or {}) do
            if joint.Parent and joint.Transform == pose.applied then joint.Transform = pose.original end
        end
        entry.joints = {}
    end
    local function bindRig(model)
        local root = model:FindFirstChild("HumanoidRootPart")
        local fakeCamera = model:FindFirstChild("FakeCamera")
        local item = model:FindFirstChild("Item")
        if not root or not fakeCamera or not root:IsA("BasePart") then return nil end
        local joints = {}
        for _, joint in ipairs(root:GetChildren()) do
            if joint:IsA("Motor6D") and joint.Part0 == root and joint.Part1 and joint.Part1 ~= fakeCamera then
                local part = joint.Part1
                if (part.Parent == model and (part.Name == "LeftUpperArm" or part.Name == "RightUpperArm"))
                    or (item and part.Name == "ItemRoot" and part:IsDescendantOf(item)) then
                    joints[joint] = {}
                end
            end
        end
        if next(joints) == nil then return nil end
        return root, joints
    end
    local blend = 0
    connect(RunService.PreAnimation, function()
        for _, entry in pairs(viewmodels) do
            for joint, pose in pairs(entry.joints or {}) do
                if pose.applied and joint.Parent and joint.Transform == pose.applied then joint.Transform = pose.original end
                pose.applied = nil
            end
        end
    end)
    connect(RunService.PreSimulation, function(dt)
        local camera = workspace.CurrentCamera
        local target = settings.viewmodel and not adsInput() and 1 or 0
        blend += (target - blend) * math.min(1, dt / 0.1)
        if math.abs(blend - target) < 0.001 then blend = target end
        for model, entry in pairs(viewmodels) do
            if entry.root and entry.root.Parent and model.Parent and camera and model:IsDescendantOf(camera) then
                local worldOffset = camera.CFrame:VectorToWorldSpace(Vector3.new(settings.vmX / 100, settings.vmY / 100, settings.vmZ / 100)) * blend
                local rootOffset = entry.root.CFrame:VectorToObjectSpace(worldOffset)
                for joint, pose in pairs(entry.joints or {}) do
                    if joint.Parent and joint.Part0 == entry.root and joint.Part1 and joint.Part1:IsDescendantOf(model) then
                        if pose.applied and joint.Transform == pose.applied then joint.Transform = pose.original end
                        pose.original = joint.Transform
                        if blend > 0 then
                            pose.applied = pose.original + joint.C0:VectorToObjectSpace(rootOffset)
                            joint.Transform = pose.applied
                        else pose.applied = nil end
                    end
                end
            end
        end
    end)
    table.insert(cleanups, function()
        if cameraConnection then cameraConnection:Disconnect() end
        if characterConnection then characterConnection:Disconnect() end
        for object, entry in pairs(tracked) do restoreVisor(object, entry) end
        for model, entry in pairs(viewmodels) do restoreModel(model, entry) end
        restoreFov()
    end)
    return function(dt, camera, desiredFov)
        applyFov(camera, not adsInput() and desiredFov or nil, dt)
        settings._nativeFov = fov.native or (camera and camera.FieldOfView)
        traceElapsed += dt
        if traceElapsed >= 0.1 then
            traceElapsed = 0
            local trace = settings._cameraTrace
            if #trace >= 240 then table.remove(trace, 1) end
            table.insert(trace, { time = os.clock(), fov = camera and camera.FieldOfView,
                native = settings._nativeFov, requested = desiredFov, ads = settings._ads,
                rmb = Input:IsMouseButtonPressed(Enum.UserInputType.MouseButton2),
                shift = Input:IsKeyDown(Enum.KeyCode.LeftShift) or Input:IsKeyDown(Enum.KeyCode.RightShift),
                equip = settings._equipId, offsetBlend = blend })
        end
        updateVegetation(dt)
        scanTime += dt
        if characterLast ~= player.Character then
            if characterConnection then characterConnection:Disconnect() end
            characterLast = player.Character
            if characterLast then
                for _, object in ipairs(characterLast:GetDescendants()) do remember(object) end
                characterConnection = characterLast.DescendantAdded:Connect(remember)
            end
        end
        if camera ~= cameraLast or scanTime >= 1 then
            scanTime = 0
            if camera ~= cameraLast then
                for model, entry in pairs(viewmodels) do restoreModel(model, entry) end
                table.clear(viewmodels)
                cameraLast = camera
                if cameraConnection then cameraConnection:Disconnect() end
                cameraConnection = camera and camera.DescendantAdded:Connect(function() scanTime = 1 end)
            end
            if camera then
                for _, object in ipairs(camera:GetDescendants()) do
                    if not tracked[object] then remember(object) end
                    if object:IsA("Model") and modelNames[normalized(object)] then
                        local parent, nested = object.Parent, false
                        while parent and parent ~= camera do
                            if parent:IsA("Model") and modelNames[normalized(parent)] then nested = true; break end
                            parent = parent.Parent
                        end
                        if not nested then
                            local entry = viewmodels[object] or {}
                            restoreModel(object, entry)
                            entry.root, entry.joints = bindRig(object)
                            viewmodels[object] = entry
                        end
                    end
                end
            end
        end
        for object, entry in pairs(tracked) do
            if not object.Parent then tracked[object] = nil
            elseif settings.noVisor then
                if entry.applied == nil or object[entry.property] ~= entry.applied then entry.original = object[entry.property] end
                if entry.property == "Visible" then entry.applied = false else entry.applied = 1 end
                object[entry.property] = entry.applied
            else restoreVisor(object, entry) end
        end
        settings._viewmodelStatus = "No supported Delta arm rig found"
        for model, entry in pairs(viewmodels) do
            if not model.Parent then
                restoreModel(model, entry)
                viewmodels[model] = nil
            elseif entry.root then
                settings._viewmodelStatus = "Delta animation Transform layer; C0 and FakeCamera unchanged"
            end
        end
    end
end
updateCameraVisuals = initializeCameraVisuals()
end

local updateLootESP
do
local function initializeLootESP()
    local marks, elapsed, scanElapsed = {}, 0, 2
    local roots = { corpses = "corpse", bodies = "corpse", deadbodies = "corpse",
        droppeditems = "item", grounditems = "item", loot = "item", items = "item" }
    local function normalize(value) return value:lower():gsub("[%s_%-]", "") end
    local function clear(object)
        local mark = marks[object]
        if mark then mark.gui:Destroy(); marks[object] = nil end
        corpseTargets[object] = nil
    end
    table.insert(cleanups, function()
        for object in pairs(marks) do clear(object) end
    end)
    return function(dt, camera)
        elapsed += dt
        scanElapsed += dt
        if elapsed < 0.25 then return end
        local scan = scanElapsed >= 2
        elapsed = 0
        if scan then scanElapsed = 0 end
        if scan then
            local seen, count = {}, 0
            local function consider(object, kind)
                if count >= 250 or (not object:IsA("Model") and not object:IsA("BasePart")) then return end
                if Players:GetPlayerFromCharacter(object) then return end
                local humanoid = object:IsA("Model") and object:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then return end
                if humanoid then kind = "corpse" end
                if kind == "item" and not settings.itemEsp then return end
                local part = object:IsA("BasePart") and object or object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart", true)
                if not part then return end
                seen[object], count = true, count + 1
                if kind == "corpse" then corpseTargets[object] = part end
                if not marks[object] then
                    local billboard = create("BillboardGui", gui, {
                        Name = "OktanLootMarker", Adornee = part, Size = UDim2.fromOffset(230, 42),
                        StudsOffset = Vector3.new(0, 1.5, 0), AlwaysOnTop = false, Enabled = false,
                    })
                    local label = text(billboard, "", {
                        Size = UDim2.fromScale(1, 1), TextSize = 13,
                        TextStrokeTransparency = 0.3, TextWrapped = true,
                    })
                    marks[object] = { gui = billboard, label = label, kind = kind, part = part }
                end
                marks[object].kind, marks[object].part = kind, part
                marks[object].gui.Adornee = part
            end
            local function visit(folder, depth)
                if depth > 3 then return end
                for _, object in ipairs(folder:GetChildren()) do
                    local kind = roots[normalize(object.Name)]
                    if kind then
                        for _, child in ipairs(object:GetChildren()) do
                            if child:IsA("Folder") then
                                for _, item in ipairs(child:GetChildren()) do consider(item, kind) end
                            else consider(child, kind) end
                        end
                    elseif object:IsA("Folder") then visit(object, depth + 1)
                    elseif object:IsA("Model") then
                        local human = object:FindFirstChildOfClass("Humanoid")
                        if human and human.Health <= 0 then consider(object, "corpse") end
                    end
                end
            end
            visit(workspace, 0)
            for object in pairs(marks) do if not seen[object] then clear(object) end end
        end
        for object, mark in pairs(marks) do
            if not object.Parent or not mark.part.Parent then clear(object)
            else
                local distance = camera and (mark.part.Position - camera.CFrame.Position).Magnitude or math.huge
                mark.gui.Enabled = not menu.Visible and distance <= settings.lootRange
                    and (mark.kind == "corpse" and settings.corpseEsp or mark.kind == "item" and settings.itemEsp)
                mark.gui.AlwaysOnTop = settings.lootThrough
                mark.label.TextSize = settings.lootTextSize
                mark.label.TextColor3 = mark.kind == "corpse" and Color3.fromRGB(255, 156, 125) or Color3.fromRGB(115, 229, 185)
                local name = object:GetAttribute("DisplayName")
                name = type(name) == "string" and name or object.Name
                mark.label.Text = (mark.kind == "corpse" and "CORPSE · " or "") .. name .. "\n" .. math.round(distance) .. " st"
            end
        end
    end
end
updateLootESP = initializeLootESP()
end

local soulFx
do
local function initializeSoulFx()
    local active, watched, pending, elapsed, poll = {}, {}, {}, 0, 1
    local function remove(entry)
        for _, tween in ipairs(entry.tweens) do tween:Cancel() end
        entry.model:Destroy()
    end
    local function spawn(model)
        if not settings.killFx or not model or not model.Parent then return false end
        if #active >= 4 then remove(table.remove(active, 1)) end
        local ghost = create("Model", workspace, { Name = "OktanSoul" })
        local entry = { model = ghost, tweens = {}, expires = elapsed + 1.8 }
        local count = 0
        for _, part in ipairs(model:GetChildren()) do
            if part:IsA("BasePart") and bodyNames[part.Name] and count < 16 then
                local ok, copy = pcall(function() return part:Clone() end)
                if ok and copy then
                    for _, child in ipairs(copy:GetDescendants()) do
                        if child:IsA("JointInstance") or child:IsA("Constraint") or child:IsA("WeldConstraint") or child:IsA("LuaSourceContainer")
                            or child:IsA("ParticleEmitter") or child:IsA("SurfaceAppearance") or child:IsA("SurfaceGui") then child:Destroy() end
                    end
                    copy.Anchored, copy.CanCollide, copy.CanTouch, copy.CanQuery = true, false, false, false
                    copy.CastShadow, copy.Transparency, copy.LocalTransparencyModifier = false, 0.5, 0
                    copy.Material, copy.Color = Enum.Material.Neon, Color3.fromRGB(185, 230, 255)
                    copy.CFrame, copy.Parent = part.CFrame, ghost
                    local tween = TweenService:Create(copy, TweenInfo.new(1.7, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                        CFrame = part.CFrame + Vector3.new(0, 4, 0), Transparency = 1,
                    })
                    table.insert(entry.tweens, tween); tween:Play(); count += 1
                end
            end
        end
        if count == 0 then ghost:Destroy(); return false end
        table.insert(active, entry)
        settings._soulStatus = "Confirmed local kill: soul spawned"
        return true
    end
    local function ownsKill(humanoid, model, victim)
        local creator = humanoid:FindFirstChild("creator") or humanoid:FindFirstChild("Creator")
        if creator and creator:IsA("ObjectValue") and creator.Value == player then return true end
        if model:GetAttribute("KillerUserId") == player.UserId and player.UserId ~= nil then return true end
        local records = game:GetService("ReplicatedStorage"):FindFirstChild("Players")
        local record = records and records:FindFirstChild(victim and victim.Name or model.Name)
        local status = record and record:FindFirstChild("Status")
        local variables = status and status:FindFirstChild("GameplayVariables")
        local killer = variables and variables:GetAttribute("DeathCausedBy")
        return killer ~= nil and killer ~= "" and (killer == player.Name or (player.UserId ~= nil and tostring(killer) == tostring(player.UserId)))
    end
    local function watch(victim)
        local model = victim.Character
        local humanoid = model and model:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 or watched[humanoid] or not humanoid.Died then return end
        watched[humanoid] = humanoid.Died:Connect(function()
            if watched[humanoid] then watched[humanoid]:Disconnect(); watched[humanoid] = nil end
            if not settings.killFx then return end
            if ownsKill(humanoid, model, victim) then spawn(model)
            elseif #pending < 16 then table.insert(pending, { humanoid = humanoid, model = model, victim = victim, expires = elapsed + 0.8 }) end
        end)
    end
    soulFx = { preview = spawn }
    soulFx.step = function(dt)
        elapsed += dt; poll += dt
        if settings._soulPreviewRequested then
            settings._soulPreviewRequested = nil
            spawn(player.Character)
        end
        if poll >= 0.5 then
            poll = 0
            if settings.killFx then
                for _, victim in ipairs(Players:GetPlayers()) do if victim ~= player then watch(victim) end end
            end
            for humanoid, connection in pairs(watched) do
                if not humanoid.Parent then connection:Disconnect(); watched[humanoid] = nil end
            end
        end
        for i = #pending, 1, -1 do
            local death = pending[i]
            if settings.killFx and death.model.Parent and ownsKill(death.humanoid, death.model, death.victim) then
                spawn(death.model); table.remove(pending, i)
            elseif not settings.killFx or not death.model.Parent or elapsed >= death.expires then
                table.remove(pending, i)
                settings._soulStatus = "No confirmed killer attribution; effect skipped"
            end
        end
        for i = #active, 1, -1 do
            if not settings.killFx or elapsed >= active[i].expires then remove(table.remove(active, i)) end
        end
    end
    table.insert(cleanups, function()
        for _, connection in pairs(watched) do connection:Disconnect() end
        for _, entry in ipairs(active) do remove(entry) end
        table.clear(watched); table.clear(active); table.clear(pending)
    end)
    return soulFx
end
soulFx = initializeSoulFx()
end

local renderName = "Oktan_" .. HttpService:GenerateGUID(false)
local unloaded = false
local function unload()
    if unloaded then return end
    unloaded = true
    -- A pending write is serialized with this final save before a new instance starts.
    while saving do task.wait() end
    saveConfig()
    for _, cleanup in ipairs(cleanups) do cleanup() end
    blurEffect:Destroy()
    RunService:UnbindFromRenderStep(renderName)
    for _, connection in ipairs(connections) do connection:Disconnect() end
    for key, entry in pairs(overrides) do
        override(key, entry.instance, entry.property, nil)
    end
    for _, marker in pairs(markersByModel) do destroyMarker(marker) end
    gui:Destroy()
end
connect(unloadSignal.Event, unload)
connect(gui.AncestryChanged, function()
    if gui.Parent == nil then unload() end
end)

task.spawn(function()
    while not unloaded do
        task.wait(0.25)
        if not unloaded and dirty and os.clock() - lastChange >= 0.8 then saveConfig() end
    end
end)

local renderState = { elapsed = 1, visualElapsed = 1 }
RunService:BindToRenderStep(renderName, Enum.RenderPriority.Last.Value + 1, function(dt)
    local camera = workspace.CurrentCamera
    updateHud(dt)
    updateWinter(dt)
    soulFx.step(dt)
    updateLootESP(dt, camera)

    applyTheme()
    ringStroke.Color = Color3.fromHSV(settings.fovHue / 360, settings.fovSaturation / 100, settings.fovValue / 100)
    renderState.elapsed += dt
    if renderState.elapsed >= 0.2 then
        renderState.elapsed = 0
        refreshCandidates()
        updateMarkers(camera)
        updateLighting()
        local count = #candidates
        status.Text = capture and "Нажмите клавишу • Esc — отмена • Backspace — убрать назначение"
            or string.format("%s   •   Меню [%s]   •   Целей %d", configStatus, bindings.menu or "OKTAN", count)
    end

    menu.BackgroundTransparency = math.min(settings.glass, 12) / 100
    if not menu.Visible then
        bindDialog.Visible = false
        pendingNumeric = nil
    end
    blurEffect.Size = menu.Visible and settings.blur or 0
    blurEffect.Enabled = menu.Visible and settings.blur > 0
    if tooltip.Visible then
        local mouse = Input:GetMouseLocation()
        local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
        tooltip.Position = UDim2.fromOffset(
            math.clamp(mouse.X + 18, 0, math.max(0, viewport.X - 364)),
            math.clamp(mouse.Y + 20, 0, math.max(0, viewport.Y - tooltip.AbsoluteSize.Y - 4)))
    end
    local color = Color3.fromHSV(settings.espHue / 360, settings.espSaturation / 100, settings.espValue / 100)
    renderState.visualElapsed += dt
    if renderState.visualElapsed >= 1 / settings.espFps then
        renderState.visualElapsed = 0
        table.clear(occupiedLabels)
        for _, marker in ipairs(orderedMarkers) do renderScreenMarker(marker, camera, color) end
    end
    local inputReady = focused and not menu.Visible and not capture and Input:GetFocusedTextBox() == nil
    local records = game:GetService("ReplicatedStorage"):FindFirstChild("Players")
    local record = records and records:FindFirstChild(player.Name)
    local status = record and record:FindFirstChild("Status")
    local variables = status and status:FindFirstChild("GameplayVariables")
    settings._equipId = variables and variables:GetAttribute("EquipId")
    local equipped = variables and variables:FindFirstChild("EquippedTool")
    local weaponPresent = (equipped and equipped.Value ~= nil) or (variables and (variables:GetAttribute("EquipId") or 0) ~= 0) or (player.Character and heldItem(player.Character) ~= nil)
    local rightMouse = focused and not menu.Visible and Input:GetFocusedTextBox() == nil and Input:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    local function aimingFlag(object)
        return object and (object:GetAttribute("Aiming") == true or object:GetAttribute("ADS") == true or object:GetAttribute("IsAiming") == true)
    end
    settings._ads = aimingFlag(variables) or aimingFlag(player.Character) or aimingFlag(camera) or (weaponPresent and rightMouse) or false
    local zooming = camera and inputReady and settings.zoom and held("zoom")
    updateCameraVisuals(dt, camera, (not settings._ads) and (zooming and settings.zoomFov or (settings.cameraFov and settings.cameraFovValue or nil)) or nil)
    enforceOverrides()
    ring.Visible = camera ~= nil and inputReady and settings.aim and settings.ring
    if renderState.shownRingRadius ~= settings.radius then
        renderState.shownRingRadius = settings.radius
        ring.Size = UDim2.fromOffset(renderState.shownRingRadius * 2, renderState.shownRingRadius * 2)
    end
    local showCross = camera ~= nil and inputReady and settings.crosshair and not settings._ads
    local style, thickness = settings.crossStyle, settings.crossWidth
    for _, arm in ipairs(crosshair) do arm.Visible = showCross and style ~= 2 end
    crosshair.dot.Visible = showCross and style ~= 1
    if camera and (renderState.crossStyle ~= style or renderState.crossWidth ~= thickness or renderState.crossLength ~= settings.length or renderState.crossGap ~= settings.gap or renderState.crossViewport ~= camera.ViewportSize) then
        renderState.crossStyle, renderState.crossWidth, renderState.crossLength, renderState.crossGap, renderState.crossViewport = style, thickness, settings.length, settings.gap, camera.ViewportSize
        local cx, cy = math.floor(camera.ViewportSize.X / 2), math.floor(camera.ViewportSize.Y / 2)
        local length, gap = settings.length, settings.gap
        local half = math.floor(thickness / 2)
        local rectangles = {
            { cx - gap - length, cy - half, length, thickness }, { cx + gap, cy - half, length, thickness },
            { cx - half, cy - gap - length, thickness, length }, { cx - half, cy + gap, thickness, length },
        }
        for index, arm in ipairs(crosshair) do
            local r = rectangles[index]
            arm.AnchorPoint = Vector2.new(0, 0)
            arm.Position, arm.Size = UDim2.fromOffset(r[1], r[2]), UDim2.fromOffset(r[3], r[4])
        end
        local diameter = thickness + 2
        crosshair.dot.Position = UDim2.fromOffset(cx - math.floor(diameter / 2), cy - math.floor(diameter / 2))
        crosshair.dot.Size = UDim2.fromOffset(diameter, diameter)
    end
    if camera and camera.ViewportSize ~= renderState.viewportSize then
        renderState.viewportSize = camera.ViewportSize
        menu.Position = UDim2.fromScale(0.5, 0.5)
        scale.Scale = math.clamp(math.min((renderState.viewportSize.X - 22) / 920, (renderState.viewportSize.Y - 22) / 610), 0.2, 1)
    end
    if camera and inputReady and settings.aim and held("aim") then
        aimAt(camera, dt)
    else
        lockedModel, aimRotation = nil, nil
    end
end)
