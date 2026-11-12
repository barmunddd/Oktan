-- Oktan 10. Full standalone source. Paste all of this file into Executor.
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
    { "mapPlayers", false, "Map Players", "Метки на карте Estonian Border после автопривязки: пройди 60–100 studs вперёд и вбок, открывая M в разных точках. Видны только переданные клиенту персонажи.", "ESP" },
    { "mapNames", true, "Map Names", "Показывать ники рядом с метками игроков на карте.", "ESP" },
    { "mapFriendsOnly", false, "Map Friends Only", "Показывать на карте только тиммейтов из списка Friends.", "ESP" },
    { "mapTextSize", 11, "Map Text Size", "Размер ников на карте. Тиммейты отмечены мятным цветом и ALLY.", "ESP", 8, 16 },
    { "containerReach", 250, "Container Reach", "Дальность Inspect для сундуков: 25–1500 studs. Наведи прицел на сундук; доступны только переданные клиенту предметы.", "Настройки", 25, 1500 },
    { "containerEsp", false, "Containers", "Метки доступных сундуков в папках Containers/Chests. Дальность — Loot Distance.", "ESP" },
    { "auroraEsp", false, "Aurora", "Отдельные метки сундуков с Aurora/Аврора в имени или DisplayName. Если имя модели другое, включи Containers.", "ESP" },
    { "espStyle", 2, "ESP Style", "Classic — прежние подписи; Glass — компактные карточки, здоровье и оружие под ногами; Minimal — без подложек. Chams и линии мягче в Glass/Minimal.", "ESP", 1, 3 },
    { "skinTextures", true, "Glass Textures", "Объёмное стекло с мягкими бликами и инеем. Отключи для более простого фона; Light Menu также скрывает декор.", "Настройки" },
    { "islandMusic", true, "Music Island", "Музыка в Dynamic Island: плавная смена трека, Pause/Stop и локальные строки LRC. В развёрнутом виде время, киллы и бинды сохраняются.", "Бинды" },
    { "adaptiveEsp", true, "Adaptive ESP", "При большом числе целей снижает частоту только ESP: до 30 обновлений/с после 16 целей и до 20 после 32. Игровой FPS не ограничивает; все цели остаются видимыми.", "Настройки" },
    { "lowFx", false, "Light Menu", "Отключает размытие и фоновые зимние анимации меню. Игровые функции и выбранные цвета не меняет.", "Настройки" },
    { "perfDebug", false, "Frame Stats", "Измеряет время основного обработчика клиента, ESP и камеры в миллисекундах CPU. Видно внизу меню и в Export Debug; это не замер нагрузки всей игры или GPU.", "Настройки" },
    { "yandexPlay", false, "Yandex Music", "Управляет приложением Яндекс Музыки на твоём ПК. Connect, Play/Pause, Previous/Next. Поиск открывается в сервисе; нужен локальный модуль. СКМ — бинд Play/Pause.", "Настройки" },
    { "spotifyPlay", false, "Spotify", "Личный Spotify: поиск исполнителей и треков, Play, Pause, Stop. Нужны локальный модуль и подключение аккаунта. СКМ — бинд Play/Pause.", "Настройки" },
    { "musicPlay", false, "Music Player", "Запуск и пауза личного плеера. Слышишь только ты; при входе музыка сама не запускается.", "Настройки" },
    { "musicVolume", 20, "Music Volume", "Громкость только личной музыки. Звуки игры не меняет.", "Настройки", 0, 100 },
    { "musicRepeat", false, "Repeat Track", "Повторяет текущий трек.", "Настройки" },
    { "musicIndex", 1, "Track Index", "Выбор трека из твоего плейлиста. На плюс и минус можно назначить клавиши переключения.", "Настройки", 1, 30 },
    { "noRecoil", false, "No Recoil", "Снижает подтверждённый локальный множитель Recoil персонажа до нуля. Отдачу конкретного оружия ещё нужно проверить в игре.", "Наведение" },
    { "aimEase", 220, "Aim Ease", "Время плавного входа в наведение в миллисекундах. Меньше — быстрее захват.", "Наведение", 50, 500 },
    { "aimFilter", 14, "Target Filter", "Сглаживание дрожания точки цели. Меньше — мягче, больше — точнее следует движению.", "Наведение", 5, 30 },
    { "graphics", false, "Visual Studio", "Включает локальные цветовые сцены, небо и эффекты освещения.", "Мир" },
    { "gfxTier", 1, "PC Profile", "1 — Low; 2 — Balanced; 3 — Ultra. Меняет набор эффектов и качество Chrono Echo.", "Мир", 1, 3 },
    { "gfxLook", 1, "Scene", "1 — Arctic; 2 — Golden; 3 — Neon; 4 — Cinema; 5 — Clean.", "Мир", 1, 5 },
    { "echo", false, "Chrono Echo", "3D-окно с записью твоих движений и задержанным воспроизведением. Снимается только твой персонаж.", "Настройки" },
    { "echoDelay", 2, "Echo Delay", "Задержка 3D-воспроизведения в секундах. Запись хранится только в памяти.", "Настройки", 1, 6 },
    { "echoFreeze", false, "Freeze Echo", "Замораживает текущий кадр в 3D-окне. Можно назначить отдельную клавишу.", "Настройки" },
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
    { "smooth", 12, "Aim Speed", "Скорость плавного доворота. Aim Ease управляет входом, Target Filter сглаживает движение цели.", "Наведение", 2, 45 },
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
settings._musicLibrary = {}
for _, definition in ipairs(definitions) do
    local key = definition[1]
    defaults[key] = definition[2]
    schema[key] = definition
    settings[key] = definition[2]
end
local bindings = { menu = "Insert", aim = "MouseButton2", zoom = "LeftAlt", inspect = "F4" }
local allowedActions = { menu = true, inspect = true, containerDump = true, friendPick = true }
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
    local friendCount=0
    if type(data.friends) == "table" then
        for name, enabled in pairs(data.friends) do
            if type(name) == "string" and enabled == true and #name >= 3 and #name <= 20 and name:match("^[%w_]+$") then
                local canonical=string.lower(name)
                if not validatedFriends[canonical] and friendCount<200 then validatedFriends[canonical]=true; friendCount+=1 end
            end
        end
    end
    local music, musicIds = {}, {}
    if type(data.music) == "table" then
        for _, track in ipairs(data.music) do
            if #music >= 30 then break end
            if type(track) == "table" and type(track.id) == "string" and #track.id <= 20
                and track.id:match("^[1-9]%d*$") and not musicIds[track.id] then
                musicIds[track.id] = true
                local name = type(track.name) == "string" and track.name:gsub("%c", " "):sub(1, 60) or "Audio " .. track.id
                table.insert(music, { id = track.id, name = name })
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
    return { settings = validated, bindings = validatedBindings, friends = validatedFriends, music = music, revision = data.revision }
end
if canSave then
    local function readConfig(prefix)
        local newest
        for _, slot in ipairs({ "a", "b" }) do
            local ok, data = pcall(function()
                local raw=readfile(prefix .. slot .. ".json")
                if type(raw)~="string" or #raw>262144 then return nil end
                return validateConfig(HttpService:JSONDecode(raw))
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
        settings._musicLibrary = newest.music or {}
        configStatus = "Конфиг загружен"
    else
        dirty, lastChange = true, os.clock()
    end
end
settings._subscription = ...
if type(settings._subscription) ~= "table" then settings._subscription = nil end
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
            settings = persistedSettings, bindings = bindings, friends = friendNames, music = settings._musicLibrary or {},
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
    background = Color3.fromRGB(8, 13, 18), panel = Color3.fromRGB(15, 23, 30),
    control = Color3.fromRGB(22, 33, 42), edge = Color3.fromRGB(121, 144, 160),
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
text(menu, "STUDIO   /   WINTER", {
    Position = UDim2.fromOffset(65, 48), Size = UDim2.fromOffset(340, 18),
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
    if visible and settings.motion and not settings.lowFx then
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
    controlRows.bindShield.Visible=true
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
    if controlRows.bindShield then controlRows.bindShield.Visible=bindDialog.Visible end
end)
controlRows.bindShield=create("TextButton",gui,{Name="BindModalShield",Text="",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=.7,AutoButtonColor=false,Visible=false,Active=true,Modal=true,ZIndex=49})
connect(bindDialog:GetPropertyChangedSignal("Visible"),function() controlRows.bindShield.Visible=bindDialog.Visible end)
controlRows.bindGesture={}
local function middleBind(object, action, transientConnect)
    (transientConnect or connect)(object.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton3 and menu.Visible and not bindDialog.Visible then
            controlRows.bindGesture.action=action
        end
    end)
end
connect(Input.InputEnded,function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton3 then
        local action=controlRows.bindGesture.action
        controlRows.bindGesture.action=nil
        if action and menu.Visible and focused and not bindDialog.Visible then beginBind(action) end
    end
end)
connect(Input.WindowFocusReleased,function() controlRows.bindGesture.action=nil end)

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
    { "menu", "Menu" }, { "inspect", "Inspect" }, { "containerDump", "Export Container" }, { "friendPick", "Pick Friend" },
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
    if not controlRows.release.confirmReset() then return end
    local library, session = settings._musicLibrary, settings._subscription
    settings = table.clone(defaults)
    settings._subscription = session
    settings._musicLibrary = library or {}
    bindings = { menu = "Insert", aim = "MouseButton2", zoom = "LeftAlt", inspect = "F4" }
    capture = nil
    changed()
    refreshAll()
end)
connect(unloadButton.Activated, function() unloadSignal:Fire() end)
describe(saveButton, "Сохраняет настройки и клавиши в workspace исполнителя. Обычно сохранение происходит автоматически через секунду после изменения.")
describe(resetButton, "Возвращает все настройки и клавиши к исходным значениям. Новые значения автоматически сохранятся.")
describe(unloadButton, "Сохраняет конфиг, удаляет интерфейс и ESP, отключает обработчики и возвращает изменённые параметры освещения и камеры.")
do
    actionsRow.Size = UDim2.new(1, 0, 0, 110)
    local export = button(actionsRow, "Weapon Debug", UDim2.fromOffset(12, 58), UDim2.fromOffset(180, 32))
    export.Visible=false
    describe(export, "Возьми оружие и нажми: сохранит его доступные параметры и пути конфигураций в Oktan-weapon-debug.json.")
    local function dumpWeapon()
        if type(writefile) ~= "function" then configStatus = "Запись файлов недоступна"; return end
        local ok, message = pcall(function()
            local report = { version = 2, referencesFollowed = 0, placeId = game.PlaceId, roots = {}, modules = {}, truncated = false }
            local storage = game:GetService("ReplicatedStorage")
            local records = storage:FindFirstChild("Players")
            local record = records and records:FindFirstChild(player.Name)
            local status = record and record:FindFirstChild("Status")
            local variables = status and status:FindFirstChild("GameplayVariables")
            local equipped = variables and variables:FindFirstChild("EquippedTool")
            local function summary(object)
                local row = { path = object:GetFullName(), class = object.ClassName, attributes = {} }
                for key, value in pairs(object:GetAttributes()) do
                    local lower = string.lower(key)
                    if not lower:find("key", 1, true) and not lower:find("token", 1, true) and not lower:find("secret", 1, true) then
                        local kind = type(value)
                        if kind == "number" or kind == "boolean" then row.attributes[key] = value
                        elseif kind == "string" then row.attributes[key] = value:sub(1, 160) end
                    end
                end
                if object:IsA("NumberValue") or object:IsA("IntValue") or object:IsA("BoolValue") then row.value = object.Value
                elseif object:IsA("StringValue") then row.value = object.Value:sub(1, 160)
                elseif object:IsA("ObjectValue") then row.reference = object.Value and object.Value:GetFullName() end
                return row
            end
            local function scan(root)
                if not root then return end
                local rows, queue, cursor, visited = {}, { { root, 0 } }, 1, {}
                while cursor <= #queue and #rows < 1200 do
                    local item = queue[cursor]; cursor += 1
                    local object, depth = item[1], item[2]
                    if not visited[object] then
                        visited[object] = true
                        table.insert(rows, summary(object))
                        if depth < 10 then
                            for _, child in ipairs(object:GetChildren()) do table.insert(queue, { child, depth + 1 }) end
                            if object:IsA("ObjectValue") and object.Value then
                                local reference = object.Value
                                local localItem = equipped and equipped.Value
                                local shared = reference:IsDescendantOf(storage) and (not records or not reference:IsDescendantOf(records))
                                local localReference = localItem and (reference == localItem or reference:IsDescendantOf(localItem))
                                if shared or localReference then
                                    report.referencesFollowed += 1
                                    table.insert(queue, { reference, depth + 1 })
                                end
                            end
                        end
                    end
                end
                if cursor <= #queue then report.truncated = true end
                table.insert(report.roots, rows)
            end
            scan(equipped and equipped:IsA("ObjectValue") and equipped.Value)
            local character = player.Character
            scan(character and character:FindFirstChild("HumanoidRootPart"))
            local camera = workspace.CurrentCamera
            local viewmodel = camera and camera:FindFirstChild("ViewModel")
            scan(viewmodel and viewmodel:FindFirstChild("Item"))
            local queue, cursor, visited = {}, 1, 0
            for _, child in ipairs(storage:GetChildren()) do if child.Name ~= "Players" then table.insert(queue, child) end end
            while cursor <= #queue and visited < 6000 and #report.modules < 400 do
                local object = queue[cursor]; cursor += 1; visited += 1
                local path = string.lower(object:GetFullName())
                if object:IsA("ModuleScript") and (path:find("weapon", 1, true) or path:find("recoil", 1, true)
                    or path:find("spread", 1, true) or path:find("projectile", 1, true) or path:find("gun", 1, true)) then
                    table.insert(report.modules, summary(object))
                end
                for _, child in ipairs(object:GetChildren()) do table.insert(queue, child) end
            end
            report.moduleScanTruncated = cursor <= #queue
            writefile("Oktan-weapon-debug.json", game:GetService("HttpService"):JSONEncode(report))
        end)
        configStatus = ok and "Сохранено: Oktan-weapon-debug.json" or "Ошибка Weapon Debug"
        if not ok then warn("[Oktan] Weapon Debug: " .. tostring(message)) end
        return ok
    end
    connect(export.Activated, dumpWeapon)
    -- Upgrade the user's existing v1 diagnostic once after they run this update.
    -- No automatic export is created on machines that have no old weapon report.
    local needsUpgrade = false
    if type(readfile) == "function" and type(writefile) == "function" then
        local ok, old = pcall(function() return game:GetService("HttpService"):JSONDecode(readfile("Oktan-weapon-debug.json")) end)
        needsUpgrade = ok and type(old) == "table" and old.version == 1
    end
    if needsUpgrade and RunService.Heartbeat then
        local connection, elapsed, lifetime, attempts = nil, 0, 0, 0
        connection = connect(RunService.Heartbeat, function(dt)
            elapsed += dt; lifetime += dt
            if lifetime >= 30 then connection:Disconnect(); return end
            if elapsed < 0.5 then return end
            elapsed = 0
            local storage = game:GetService("ReplicatedStorage")
            local records = storage:FindFirstChild("Players")
            local record = records and records:FindFirstChild(player.Name)
            local status = record and record:FindFirstChild("Status")
            local variables = status and status:FindFirstChild("GameplayVariables")
            local equipped = variables and variables:FindFirstChild("EquippedTool")
            if equipped and equipped:IsA("ObjectValue") and equipped.Value then
                attempts += 1
                if dumpWeapon() or attempts >= 3 then connection:Disconnect() end
            end
        end)
    end
end

do
local function initializeLocalMusic()
    settings.musicPlay = false -- Explicit user gesture after each injection; never autoplay a saved flag.
    local audio, output, wire, folder, activeId
    local requested, loading, elapsed = false, nil, 1
    local message = "Только для тебя • добавь Roblox Audio ID и нажми Play"
    local function library()
        settings._musicLibrary = settings._musicLibrary or {}
        return settings._musicLibrary
    end
    local function normalize(raw)
        if type(raw) ~= "string" then return nil end
        raw = raw:match("^%s*(.-)%s*$")
        local id = raw:match("^(%d+)$") or raw:match("^rbxassetid://(%d+)$")
        if not id then return nil end
        id = id:gsub("^0+", "")
        return #id > 0 and #id <= 20 and id or nil
    end
    local form = create("Frame", pages["Настройки"], { Name = "MusicPlayer", Size = UDim2.new(1, -20, 0, 430), BackgroundTransparency = 1, Visible = false })
    local now = text(form, "Личный плеер", { Position = UDim2.fromOffset(16, 4), Size = UDim2.new(1, -32, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, TextSize = 16 })
    local idInput = text(form, "", { Position = UDim2.fromOffset(16, 42), Size = UDim2.fromOffset(210, 34), BackgroundColor3 = palette.control, BackgroundTransparency = 0.1, PlaceholderText = "Roblox Audio ID", ClearTextOnFocus = false }, "TextBox")
    local nameInput = text(form, "", { Position = UDim2.fromOffset(238, 42), Size = UDim2.fromOffset(280, 34), BackgroundColor3 = palette.control, BackgroundTransparency = 0.1, PlaceholderText = "Название (необязательно)", ClearTextOnFocus = false }, "TextBox")
    rounded(idInput, 8); rounded(nameInput, 8)
    local addButton = button(form, "Add", UDim2.fromOffset(532, 42), UDim2.fromOffset(90, 34))
    local previous = button(form, "Previous", UDim2.fromOffset(16, 92), UDim2.fromOffset(95, 34))
    local playButton = button(form, "Play", UDim2.fromOffset(120, 92), UDim2.fromOffset(95, 34))
    local nextButton = button(form, "Next", UDim2.fromOffset(224, 92), UDim2.fromOffset(95, 34))
    local stopButton = button(form, "Stop", UDim2.fromOffset(328, 92), UDim2.fromOffset(95, 34))
    local repeatButton = button(form, "Repeat: Off", UDim2.fromOffset(432, 92), UDim2.fromOffset(114, 34))
    local quieter = button(form, "Vol -", UDim2.fromOffset(560, 92), UDim2.fromOffset(66, 34))
    local louder = button(form, "Vol +", UDim2.fromOffset(632, 92), UDim2.fromOffset(66, 34))
    local info = text(form, message, { Position = UDim2.fromOffset(16, 130), Size = UDim2.new(1, -32, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = palette.muted })
    local seek = button(form, "", UDim2.fromOffset(16, 164), UDim2.new(1, -32, 0, 8))
    local fill = create("Frame", seek, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = palette.accent, BorderSizePixel = 0 })
    rounded(fill, 4)
    local list = create("ScrollingFrame", form, { Position = UDim2.fromOffset(16, 188), Size = UDim2.new(1, -32, 0, 220), BackgroundTransparency = 1, ScrollBarThickness = 3, CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y })
    local api = { form = form, normalize = normalize }
    local function current()
        local tracks = library()
        settings.musicIndex = math.clamp(settings.musicIndex, 1, math.max(1, #tracks))
        return tracks[settings.musicIndex]
    end
    local function ensureAudio()
        if audio then return true end
        local ok = pcall(function()
            folder = create("Folder", game:GetService("SoundService"), { Name = "OktanLocalMusic" })
            audio = create("AudioPlayer", folder, { Name = "Player", AutoPlay = false, AutoLoad = false, Volume = settings.musicVolume / 100 })
            output = create("AudioDeviceOutput", folder, { Name = "PrivateOutput", Player = player })
            if output.Player ~= player then error("Private audio output unavailable") end
            wire = create("Wire", folder, { SourceInstance = audio, TargetInstance = output })
            connect(audio.Ended, function()
                if not requested or settings.musicRepeat then return end
                if settings.musicIndex < #library() then api.next(1)
                else api.stop(); message = "Плейлист завершён" end
            end)
        end)
        if not ok then
            if folder then folder:Destroy() end
            audio, output, wire, folder = nil, nil, nil, nil
            message = "Локальный аудиовыход недоступен"
        end
        return ok
    end
    api.pause = function()
        if audio then audio:Stop() end
        requested, loading = false, nil
        setValue("musicPlay", false)
        message = "Пауза • слышишь только ты"
    end
    api.stop = function()
        api.pause()
        if audio then audio.TimePosition = 0 end
        message = "Остановлено"
    end
    api.play = function()
        local track = current()
        if not track then message = "Сначала добавь Roblox Audio ID"; settings.musicPlay = false; requested = false; return false end
        if not ensureAudio() then settings.musicPlay = false; requested = false; return false end
        local ok = pcall(function()
            if not output or output.Player ~= player then error("Private output changed") end
            if activeId ~= track.id then
                audio:Stop()
                audio.Asset = "rbxassetid://" .. track.id
                audio.TimePosition = 0
                activeId = track.id
            elseif audio.IsReady and audio.TimeLength > 0 and audio.TimePosition >= audio.TimeLength - 0.01 then audio.TimePosition = 0 end
            audio.Volume, audio.Looping = settings.musicVolume / 100, settings.musicRepeat
            audio:Play()
        end)
        if not ok then
            pcall(function() audio:Stop() end)
            activeId, requested, loading = nil, false, nil
            settings.musicPlay = false
            message = "Не удалось запустить локальное аудио"
            return false
        end
        requested, loading = true, 0
        setValue("musicPlay", true)
        message = "Загрузка • " .. track.name
        return true
    end
    api.next = function(delta)
        if #library() == 0 then message = "Плейлист пуст"; return end
        local shouldPlay = requested
        setValue("musicIndex", ((settings.musicIndex - 1 + delta) % #library()) + 1)
        if shouldPlay then api.play() else
            if audio then audio:Stop(); audio.TimePosition = 0 end
            activeId = nil
            message = "Трек выбран • нажми Play"
        end
    end
    local function refreshList()
        list:ClearAllChildren()
        create("UIListLayout", list, { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5) })
        for index, track in ipairs(library()) do
            local row = create("Frame", list, { Size = UDim2.new(1, -8, 0, 34), BackgroundTransparency = 1, LayoutOrder = index })
            local choose = button(row, index .. ". " .. track.name, UDim2.fromOffset(0, 0), UDim2.new(1, -76, 1, 0))
            choose.TextXAlignment = Enum.TextXAlignment.Left
            local remove = button(row, "Delete", UDim2.new(1, -70, 0, 0), UDim2.fromOffset(68, 34))
            choose.Activated:Connect(function()
                local shouldPlay = requested
                setValue("musicIndex", index)
                if shouldPlay then api.play() else activeId = nil; message = "Трек выбран • нажми Play" end
            end)
            remove.Activated:Connect(function() api.remove(index) end)
        end
    end
    api.add = function(raw, name)
        local id = normalize(raw)
        if not id then message = "Нужен Roblox Audio ID, не ссылка на YouTube/Spotify"; return false end
        local tracks = library()
        local title = type(name) == "string" and name:gsub("%c", " "):match("^%s*(.-)%s*$"):sub(1, 60) or ""
        if title == "" then title = "Audio " .. id end
        for index, track in ipairs(tracks) do
            if track.id == id then settings.musicIndex = index; track.name = title; changed(); refreshList(); return true end
        end
        if #tracks >= 30 then message = "В плейлисте максимум 30 треков"; return false end
        table.insert(tracks, { id = id, name = title })
        changed(); refreshList(); message = "Добавлено • " .. title
        return true
    end
    api.remove = function(index)
        if not library()[index] then return end
        if index == settings.musicIndex then api.stop(); activeId = nil end
        table.remove(library(), index)
        if settings.musicIndex > index then settings.musicIndex -= 1 end
        current(); changed(); refreshList()
    end
    connect(addButton.Activated, function() if api.add(idInput.Text, nameInput.Text) then idInput.Text, nameInput.Text = "", "" end end)
    connect(playButton.Activated, function() if requested then api.pause() else api.play() end end)
    connect(previous.Activated, function() api.next(-1) end)
    connect(nextButton.Activated, function() api.next(1) end)
    connect(stopButton.Activated, api.stop)
    connect(repeatButton.Activated, function() setValue("musicRepeat", not settings.musicRepeat) end)
    connect(quieter.Activated, function() setValue("musicVolume", math.max(0, settings.musicVolume - 5)) end)
    connect(louder.Activated, function() setValue("musicVolume", math.min(100, settings.musicVolume + 5)) end)
    connect(seek.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and audio and audio.IsReady and audio.TimeLength > 0 then
            audio.TimePosition = math.clamp((input.Position.X - seek.AbsolutePosition.X) / math.max(1, seek.AbsoluteSize.X), 0, 1) * audio.TimeLength
        end
    end)
    api.step = function(dt)
        elapsed += dt
        if settings.musicPlay ~= requested then if settings.musicPlay then api.play() else api.pause() end end
        if elapsed < 0.2 then return end
        local tick = elapsed
        elapsed = 0
        local track = current()
        if requested and track and activeId ~= track.id then api.play() end
        if audio then
            audio.Volume, audio.Looping = settings.musicVolume / 100, settings.musicRepeat
            if requested and loading ~= nil then
                if audio.IsReady then loading = nil; message = "Играет только у тебя"
                else loading += tick
                    if loading >= 15 then api.stop(); message = "Трек не загрузился: проверь ID и разрешение на аудио" end
                end
            end
        end
        now.Text = track and track.name or "Личный плеер • плейлист пуст"
        playButton.Text = requested and "Pause" or "Play"
        repeatButton.Text = settings.musicRepeat and "Repeat: On" or "Repeat: Off"
        info.Text = message .. "  •  " .. tostring(settings.musicVolume) .. "%"
        fill.BackgroundColor3 = palette.accent
        fill.Size = UDim2.fromScale(audio and audio.TimeLength > 0 and math.clamp(audio.TimePosition / audio.TimeLength, 0, 1) or 0, 1)
        settings._musicStatus = { title = track and track.name or "", playing = requested, localOnly = true, volume = settings.musicVolume, state = message }
    end
    table.insert(cleanups, function()
        if audio then pcall(function() audio:Stop() end) end
        if folder then folder:Destroy() end
        form:Destroy()
        settings._musicStatus = nil
    end)
    refreshList()
    return api
end
controlRows.music = initializeLocalMusic()
end

do
local function initializeSubscriptionPanel()
    local session = settings._subscription
    local elapsed, warned = 1, false
    title.Size = UDim2.fromOffset(106, 32)
    local badge = button(menu, "Subscription", UDim2.fromOffset(136, 17), UDim2.fromOffset(268, 30))
    badge.Name, badge.TextSize, badge.TextColor3 = "SubscriptionBadge", 12, palette.accent
    describe(badge, "Оставшийся срок подписки. Нажми, чтобы посмотреть подробности и продлить доступ.")
    local form = create("Frame", pages["Настройки"], { Name = "SubscriptionPanel", Size = UDim2.new(1, -20, 0, 290), BackgroundTransparency = 0.25, BackgroundColor3 = palette.panel, Visible = false })
    rounded(form, 16)
    text(form, "Твоя подписка", { Position = UDim2.fromOffset(24, 18), Size = UDim2.new(1, -48, 0, 30), TextSize = 21, TextXAlignment = Enum.TextXAlignment.Left })
    local state = text(form, "Проверка состояния...", { Position = UDim2.fromOffset(24, 58), Size = UDim2.new(1, -48, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = palette.muted })
    local remaining = text(form, "", { Position = UDim2.fromOffset(24, 94), Size = UDim2.new(1, -48, 0, 38), TextSize = 24, TextColor3 = palette.accent, TextXAlignment = Enum.TextXAlignment.Left })
    local renew = button(form, "Renew / Copy FunPay", UDim2.fromOffset(24, 152), UDim2.fromOffset(220, 40))
    local result = text(form, "Продление у разработчика на FunPay", { Position = UDim2.fromOffset(260, 152), Size = UDim2.new(1, -284, 0, 40), TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = palette.muted })
    local url = text(form, "https://funpay.com/users/15095530/", { Position = UDim2.fromOffset(24, 212), Size = UDim2.new(1, -48, 0, 34), TextEditable = false, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = palette.muted }, "TextBox")
    local warning = text(gui, "", { Name = "OktanExpiryWarning", Position = UDim2.new(0.5, -230, 0, 124), Size = UDim2.fromOffset(460, 32), BackgroundColor3 = palette.background, BackgroundTransparency = 0.12, TextColor3 = Color3.fromRGB(255, 210, 140), Visible = false })
    rounded(warning, 12)
    local function renewNow()
        if session and type(session.renew) == "function" then return session.renew() end
        local link = "https://funpay.com/users/15095530/"
        if type(openurl) == "function" then local ok, answer = pcall(openurl, link); if ok and answer ~= false then return "FunPay открыт" end end
        if type(setclipboard) == "function" then local ok = pcall(setclipboard, link); if ok then return "Ссылка FunPay скопирована" end end
        return "Скопируй ссылку из поля выше"
    end
    connect(renew.Activated, function() result.Text = renewNow() end)
    if session then
        session.unload = function() if unloadSignal.Parent then unloadSignal:Fire() end end
        table.insert(cleanups, function() if type(session.cancel) == "function" then session.cancel() end end)
    end
    return { form = form, badge = badge, step = function(dt)
        elapsed += dt
        if elapsed < 0.25 then return end
        elapsed = 0
        local seconds
        if session and type(session.remaining) == "function" then local ok, value = pcall(session.remaining); if ok and type(value) == "number" then seconds = math.max(0, math.floor(value)) end end
        state.Text = not session and "Standalone • серверная сессия не подключена"
            or session.status == "verification_unavailable" and "Сервер временно недоступен • повторная проверка"
            or session.status == "active" and "Доступ активен • OKTAN"
            or "Статус: " .. tostring(session.status)
        if seconds then
            local days, hours, minutes = math.floor(seconds / 86400), math.floor(seconds / 3600) % 24, math.floor(seconds / 60) % 60
            remaining.Text = string.format("Осталось: %dд %02d:%02d:%02d", days, hours, minutes, seconds % 60)
            badge.Text = string.format("ACTIVE  /  %dд %02dч %02dм", days, hours, minutes)
            settings._subscriptionSummary = string.format("Subscription: %dд %02d:%02d:%02d", days, hours, minutes, seconds % 60)
            if seconds <= 600 and not warned then warning.Visible = true; warned = true end
            warning.Text = "Подписка заканчивается • нажми на срок рядом с OKTAN"
            if seconds > 600 then warning.Visible, warned = false, false end
        else
            remaining.Text = session and "Сервер пока не передаёт срок действия" or "Запускай клиент через загрузчик с ключом"
            settings._subscriptionSummary = session and "Subscription: active • expiry unavailable" or nil
            badge.Text = session and "ACTIVE  /  Subscription" or "Subscription / Standalone"
            warning.Visible = false
        end
        remaining.TextColor3 = palette.accent
        badge.TextColor3 = palette.accent
        settings._subscriptionInfo = { status = session and session.status or "standalone", expiresAt = session and session.expiresAt, remaining = seconds, canOpenBrowser = session and session.canOpenBrowser or false }
    end }
end
controlRows.subscription = initializeSubscriptionPanel()
end

do
local function initializeSpotify()
    settings.spotifyPlay = false
    local alive, busy, connected, pairing, selectedDevice, lastFlag = true, false, false, nil, nil, false
    local pollElapsed, cooldown = 0, 0
    local form = create("Frame", pages["Настройки"], { Name = "SpotifyPlayer", Size = UDim2.new(1, -20, 0, 440), BackgroundTransparency = 1, Visible = false })
    text(form, "Spotify / личный плеер", { Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -24, 0, 30), TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left })
    local connectButton = button(form, "Connect", UDim2.new(1, -230, 0, 4), UDim2.fromOffset(100, 32))
    local devicesButton = button(form, "Devices", UDim2.new(1, -120, 0, 4), UDim2.fromOffset(108, 32))
    local query = text(form, "", { Name = "SpotifyQuery", Position = UDim2.fromOffset(12, 50), Size = UDim2.new(1, -140, 0, 38), BackgroundTransparency = 0.15, BackgroundColor3 = palette.control, PlaceholderText = "Исполнитель, группа или трек…", TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false }, "TextBox")
    rounded(query, 10)
    create("UIPadding", query, { PaddingLeft = UDim.new(0, 12) })
    local searchButton = button(form, "Search", UDim2.new(1, -116, 0, 50), UDim2.fromOffset(104, 38))
    local now = text(form, "Подключи Spotify и выбери свой компьютер", { Position = UDim2.fromOffset(12, 100), Size = UDim2.new(1, -24, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
    local play = button(form, "Play", UDim2.fromOffset(12, 138), UDim2.fromOffset(110, 34))
    local pause = button(form, "Pause", UDim2.fromOffset(132, 138), UDim2.fromOffset(110, 34))
    local stop = button(form, "Stop", UDim2.fromOffset(252, 138), UDim2.fromOffset(110, 34))
    local info = text(form, "Нужен локальный Spotify Bridge • музыка звучит из Spotify на выбранном ПК", { Position = UDim2.fromOffset(12, 184), Size = UDim2.new(1, -24, 0, 40), TextWrapped = true, TextColor3 = palette.muted, TextXAlignment = Enum.TextXAlignment.Left })
    local list = create("ScrollingFrame", form, { Position = UDim2.fromOffset(12, 238), Size = UDim2.new(1, -24, 0, 196), BackgroundTransparency = 1, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.fromOffset(0, 0) })
    local api = { form = form }
    local function loadPairing()
        if type(readfile) ~= "function" then error("Исполнитель не поддерживает чтение pairing-файла", 0) end
        local data = HttpService:JSONDecode(readfile("Oktan-spotify-bridge.json"))
        if type(data) ~= "table" or data.url ~= "http://127.0.0.1:8974" or type(data.token) ~= "string" or #data.token < 20 or #data.token > 100 or not data.token:match("^[%w_%-]+$") then error("Запусти локальный Spotify Bridge заново", 0) end
        pairing = data
    end
    local function send(path, payload, callback)
        if not alive or busy or cooldown > 0 then return false end
        busy = true; info.Text = "Spotify • запрос…"
        task.spawn(function()
            local ok, result = pcall(function()
                if not pairing then loadPairing() end
                local httpRequest = request or http_request or (syn and syn.request)
                if type(httpRequest) ~= "function" then error("HTTP request недоступен", 0) end
                local body = payload or {}
                body.client = "Oktan" -- Force a JSON object even for routes with no parameters.
                local response = httpRequest({ Url = pairing.url .. path, Method = "POST", Headers = { ["Content-Type"] = "application/json", ["X-Oktan-Pair"] = pairing.token }, Body = HttpService:JSONEncode(body), Timeout = 12 })
                if type(response) ~= "table" or type(response.Body) ~= "string" then error("Нет ответа от локального Spotify Bridge", 0) end
                local data = HttpService:JSONDecode(response.Body)
                if not alive then return nil end
                if response.StatusCode ~= 200 then
                    if response.StatusCode == 403 then pairing = nil end
                    if response.StatusCode == 429 then cooldown = math.clamp(tonumber(data.retry_after) or 30, 1, 3600) end
                    error(type(data.error) == "string" and data.error or "Ошибка Spotify Bridge", 0)
                end
                return data
            end)
            if not alive then return end
            busy = false
            if ok and result then callback(result)
            elseif not ok then info.Text = "Не подключено: " .. tostring(result):sub(1, 180) end
        end)
        return true
    end
    local function resetList()
        list:ClearAllChildren(); list.CanvasPosition = Vector2.new(0, 0)
        create("UIListLayout", list, { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) })
    end
    local function openLink(url)
        if type(openurl) == "function" then local ok, answer = pcall(openurl, url); if ok and answer ~= false then return "Открыто в браузере" end end
        if type(setclipboard) == "function" then local ok = pcall(setclipboard, url); if ok then return "Ссылка скопирована • открой её в браузере" end end
        return "Браузер недоступен в исполнителе"
    end
    api.control = function(action, uri)
        if not selectedDevice then info.Text = "Нажми Devices и выбери свой компьютер"; return false end
        return send("/control", { action = action, uri = uri, device_id = selectedDevice }, function()
            lastFlag = action == "play"; settings.spotifyPlay = lastFlag
            info.Text = action == "play" and "Воспроизведение на выбранном ПК" or action == "pause" and "Пауза" or "Остановлено • позиция сброшена"
            pollElapsed = 10
        end)
    end
    api.search = function()
        local term = query.Text:match("^%s*(.-)%s*$")
        if term == "" then info.Text = "Введи исполнителя, группу или название трека"; return end
        send("/search", { query = term:sub(1, 150) }, function(data)
            connected = true; resetList()
            local count = 0
            for index, track in ipairs(type(data.tracks) == "table" and data.tracks or {}) do
                if index > 10 then break end
                if type(track.uri) == "string" and track.uri:match("^spotify:track:%w+$") then
                    count += 1
                    local row = create("Frame", list, { Size = UDim2.new(1, -8, 0, 62), BackgroundTransparency = 1, LayoutOrder = index })
                    local choose = button(row, tostring(track.title) .. "\n" .. tostring(track.artist), UDim2.fromOffset(0, 0), UDim2.new(1, -132, 1, 0))
                    choose.TextSize, choose.TextXAlignment, choose.TextWrapped = 13, Enum.TextXAlignment.Left, true
                    create("UIPadding", choose, { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) })
                    choose.Activated:Connect(function() api.control("play", track.uri) end)
                    local external = button(row, "Spotify ↗", UDim2.new(1, -124, 0, 12), UDim2.fromOffset(120, 36))
                    external.Activated:Connect(function() info.Text = openLink("https://open.spotify.com/track/" .. track.uri:match("([^:]+)$")) end)
                end
            end
            info.Text = count > 0 and "Выбери трек • воспроизведение в Spotify на твоём ПК" or "Ничего не найдено • попробуй другое название"
        end)
    end
    connect(connectButton.Activated, function()
        pairing = nil
        send("/connect", {}, function(data)
            if type(data.authorize_url) == "string" and data.authorize_url:sub(1, 39) == "https://accounts.spotify.com/authorize?" then info.Text = openLink(data.authorize_url)
            else info.Text = "Некорректный ответ подключения Spotify" end
        end)
    end)
    connect(devicesButton.Activated, function()
        send("/devices", {}, function(data)
            connected = true; resetList()
            local devices = type(data.devices) == "table" and data.devices or {}
            for index, device in ipairs(devices) do
                local choose = button(list, tostring(device.name) .. (device.active and " • Active" or ""), UDim2.new(), UDim2.new(1, -8, 0, 40))
                choose.LayoutOrder = index
                choose.Activated:Connect(function() selectedDevice = device.id; info.Text = "Выбран ПК: " .. tostring(device.name) .. " • теперь найди трек" end)
            end
            info.Text = #devices > 0 and "Выбери компьютер, на котором слушаешь музыку" or "Открой Spotify на ПК, включи трек и снова нажми Devices"
        end)
    end)
    connect(searchButton.Activated, api.search)
    connect(query.FocusLost, function(enter) if enter then api.search() end end)
    connect(play.Activated, function() api.control("play") end)
    connect(pause.Activated, function() api.control("pause") end)
    connect(stop.Activated, function() api.control("stop") end)
    api.step = function(dt)
        cooldown = math.max(0, cooldown - dt)
        if settings.spotifyPlay ~= lastFlag then
            local desired = settings.spotifyPlay; settings.spotifyPlay = lastFlag
            api.control(desired and "play" or "pause")
        end
        pollElapsed += dt
        if connected and menu.Visible and form.Visible and pollElapsed >= 10 and not busy and cooldown == 0 then
            pollElapsed = 0
            send("/status", {}, function(data)
                local track = data.track
                now.Text = type(track) == "table" and tostring(track.title) .. " / " .. tostring(track.artist) or "Spotify • нет текущего трека"
                lastFlag = data.playing == true; settings.spotifyPlay = lastFlag
                play.TextColor3 = lastFlag and palette.accent or palette.text
                info.Text = (lastFlag and "Играет" or "Пауза") .. " • " .. tostring(data.device or "Выбери ПК")
            end)
        end
    end
    table.insert(cleanups, function() alive = false; pairing = nil; form:Destroy() end)
    return api
end
controlRows.spotify = initializeSpotify()
end

do
local function initializeYandexMusic()
    settings.yandexPlay = false
    local alive, busy, connected, pairing, source, lastFlag = true, false, false, nil, nil, false
    local elapsed = 0
    local form = create("Frame", pages["Настройки"], { Name = "YandexMusicPlayer", Size = UDim2.new(1, -20, 0, 320), BackgroundTransparency = 1, Visible = false })
    text(form, "Яндекс Музыка / приложение на ПК", { Position = UDim2.fromOffset(16, 8), Size = UDim2.new(1, -165, 0, 30), TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left })
    local connectButton = button(form, "Connect", UDim2.new(1, -135, 0, 8), UDim2.fromOffset(119, 34))
    local now = text(form, "Подключи запущенное приложение", { Position = UDim2.fromOffset(16, 64), Size = UDim2.new(1, -32, 0, 32), TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
    local artist = text(form, "", { Position = UDim2.fromOffset(16, 101), Size = UDim2.new(1, -32, 0, 24), TextColor3 = palette.muted, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
    local buttons = {}
    for i, entry in ipairs({ {"previous", "Previous"}, {"play", "Play"}, {"pause", "Pause"}, {"next", "Next"}, {"stop", "Stop"} }) do
        local item = button(form, entry[2], UDim2.fromOffset(16 + (i-1)*120, 146), UDim2.fromOffset(108, 36))
        buttons[entry[1]] = item
    end
    local query = text(form, "", { Name = "YandexQuery", Position = UDim2.fromOffset(16, 208), Size = UDim2.new(1, -190, 0, 38), BackgroundTransparency = 0.1, BackgroundColor3 = palette.control, PlaceholderText = "Исполнитель, группа или песня…", ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left }, "TextBox")
    rounded(query, 10); create("UIPadding", query, { PaddingLeft = UDim.new(0, 12) })
    local searchButton = button(form, "Search ↗", UDim2.new(1, -162, 0, 208), UDim2.fromOffset(146, 38))
    local info = text(form, "Музыка звучит в приложении Яндекса • поиск откроется в сервисе", { Position = UDim2.fromOffset(16, 262), Size = UDim2.new(1, -32, 0, 48), TextWrapped = true, TextColor3 = palette.muted, TextXAlignment = Enum.TextXAlignment.Left })
    local api = { form = form }
    local function send(path, data, callback)
        if not alive or busy then return false end
        busy = true
        task.spawn(function()
            local ok, result = pcall(function()
                if not pairing then
                    local loaded, raw = pcall(function() return HttpService:JSONDecode(readfile("Oktan-yandex-bridge.json")) end)
                    if not loaded or type(raw) ~= "table" or raw.url ~= "http://127.0.0.1:8975" or type(raw.token) ~= "string" or #raw.token < 20 or #raw.token > 100 or not raw.token:match("^[%w_%-]+$") then error("Запусти локальный модуль Яндекс Музыки", 0) end
                    pairing = raw
                end
                local httpRequest = request or http_request or (syn and syn.request)
                if type(httpRequest) ~= "function" then error("HTTP request недоступен", 0) end
                data = data or {}; data.client = "Oktan"
                local response = httpRequest({Url = pairing.url .. path, Method = "POST", Headers = {["Content-Type"]="application/json", ["X-Oktan-Pair"]=pairing.token}, Body = HttpService:JSONEncode(data), Timeout = 12})
                if type(response) ~= "table" or type(response.Body) ~= "string" then error("Локальный модуль не ответил", 0) end
                local decoded = HttpService:JSONDecode(response.Body)
                if response.StatusCode ~= 200 then
                    if response.StatusCode == 403 then pairing = nil end
                    error(type(decoded.error)=="string" and decoded.error or "Ошибка локального модуля", 0)
                end
                return decoded
            end)
            if not alive then return end
            busy = false
            if ok then callback(result) else info.Text = tostring(result):sub(1,180) end
        end)
        return true
    end
    local function status(data)
        connected, source, lastFlag = true, data.source, data.playing == true
        settings.yandexPlay = lastFlag
        now.Text, artist.Text = tostring(data.title or "Яндекс Музыка"), tostring(data.artist or "")
        buttons.play.TextColor3 = lastFlag and palette.accent or palette.text
        info.Text = lastFlag and "Играет в приложении на твоём ПК" or "Пауза • управление только Яндекс Музыкой"
        local old = settings._yandexStatus
        settings._yandexStatus = { title = data.title, artist = data.artist, playing = lastFlag, localOnly = true,
            stopped = old and old.title == data.title and not lastFlag and old.stopped or false,
            positionMs = tonumber(data.position_ms) or 0, positionAvailable = data.position_available == true,
            updatedAt = os.clock() }
    end
    api.control = function(action)
        if not connected or not source then info.Text = "Нажми Connect после запуска музыки в приложении"; return false end
        return send("/control", {action=action, source=source}, function(data)
            info.Text = tostring(data.message or "Команда выполнена")
            if action == "play" then lastFlag = true elseif action == "pause" or action == "stop" then lastFlag = false end
            settings.yandexPlay = lastFlag
            if settings._yandexStatus then
                local prior = settings._yandexStatus
                if prior.playing and prior.positionAvailable and prior.updatedAt then prior.positionMs += math.max(0,os.clock()-prior.updatedAt)*1000 end
                prior.updatedAt = os.clock()
                settings._yandexStatus.playing = lastFlag
                settings._yandexStatus.stopped = action == "stop"
                if action == "play" or action == "pause" or action == "stop" then settings._yandexStatus.controlAt = os.clock() end
            end
            elapsed = (action == "next" or action == "previous") and 3 or 0
        end)
    end
    connect(connectButton.Activated, function() pairing = nil; send("/connect", {}, status) end)
    for action, item in pairs(buttons) do connect(item.Activated, function() api.control(action) end) end
    local function searchYandex()
        local term = query.Text:match("^%s*(.-)%s*$")
        if term == "" then info.Text = "Введи исполнителя или песню"; return end
        send("/search", {query=term:sub(1,150)}, function(data)
            if type(data.url) ~= "string" or data.url:sub(1, 36) ~= "https://music.yandex.ru/search?text=" then info.Text = "Некорректная ссылка поиска"; return end
            if type(openurl) == "function" then local ok, answer = pcall(openurl,data.url); if ok and answer ~= false then info.Text = "Поиск открыт в Яндекс Музыке"; return end end
            if type(setclipboard) == "function" then local ok = pcall(setclipboard,data.url); if ok then info.Text = "Ссылка поиска скопирована • открой в браузере"; return end end
            info.Text = "Открой поиск в приложении Яндекс Музыки"
        end)
    end
    connect(searchButton.Activated, searchYandex)
    connect(query.FocusLost, function(enter) if enter then searchYandex() end end)
    api.step = function(dt)
        if settings.yandexPlay ~= lastFlag then
            local desired = settings.yandexPlay; settings.yandexPlay = lastFlag
            api.control(desired and "play" or "pause")
        end
        elapsed += dt
        if connected and ((menu.Visible and form.Visible) or (settings.island and settings.islandMusic)) and elapsed >= 3 and not busy then
            elapsed = 0; send("/status", {}, status)
        end
    end
    table.insert(cleanups, function() alive = false; pairing = nil; settings._yandexStatus = nil; form:Destroy() end)
    return api
end
controlRows.yandex = initializeYandexMusic()
end

do
local function initializeStudioSkin()
    local alive,attempted,loading,asset=true,false,false,nil
    local nodes={}
    local textureEnabled=settings.skinTextures
    local registeredAt
    local assetPath="OktanAssets/studio-orb-a1465ea6.png"
    local assetUrl="https://raw.githubusercontent.com/barmunddd/Oktan/49c871741c42f0c6d2e6e86dabcdeda43b53189c/assets/ui/studio-orb-v1.png"
    settings._skinStatus={texture="idle",mode="procedural"}
    local function validPng(body)
        if type(body)~="string" or #body~=1715413 or body:sub(1,8)~="\137PNG\13\10\26\10" then return false end
        local function integer(at)
            local a,b,c,d=body:byte(at,at+3)
            return ((a*256+b)*256+c)*256+d
        end
        return integer(17)==1254 and integer(21)==1254
    end
    local function fail(reason)
        if alive then settings._skinStatus={texture=reason,mode="procedural"} end
    end
    local api={}
    api.asset=function()
        if asset then return asset end
        if attempted or loading or not settings.skinTextures or settings.lowFx or not menu.Visible then return nil end
        attempted=true
        local register=getcustomasset or getsynasset
        if type(register)~="function" or type(readfile)~="function" or type(writefile)~="function" then fail("local images unavailable"); return nil end
        loading=true
        task.spawn(function()
            local ok,result=pcall(function()
                local cached,body=pcall(readfile,assetPath)
                if not cached or not validPng(body) then
                    body=game:HttpGet(assetUrl)
                    if not alive then return nil end
                    if not validPng(body) then error("invalid PNG",0) end
                    if type(makefolder)=="function" then pcall(makefolder,"OktanAssets") end
                    writefile(assetPath,body)
                end
                if not alive then return nil end
                local uri=register(assetPath)
                if type(uri)~="string" or #uri==0 then error("image registration unavailable",0) end
                return uri
            end)
            if not alive then return end
            loading=false
            if ok and result then asset=result; registeredAt=os.clock(); settings._skinStatus={texture="registered",mode="waiting for image"}
            else fail("procedural fallback") end
        end)
        return asset
    end
    api.loaded=function()
        if settings._skinStatus.mode~="textured" then settings._skinStatus={texture="loaded",mode="textured"} end
    end
    local shadow=create("Frame",gui,{Name="StudioShadow",AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(920,610),BackgroundTransparency=1,Visible=menu.Visible,ZIndex=0})
    local shadowScale=create("UIScale",shadow,{Scale=1})
    for i=3,1,-1 do
        local layer=create("Frame",shadow,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.51),Size=UDim2.new(1,12*i,1,12*i),BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=.92-i*.025,BorderSizePixel=0,ZIndex=0})
        rounded(layer,26+i*3)
    end
    local top=create("Frame",menu,{Name="StudioHeader",Size=UDim2.new(1,0,0,78),BackgroundColor3=Color3.fromRGB(14,21,27),BackgroundTransparency=.3,BorderSizePixel=0,ZIndex=0})
    create("UIGradient",top,{Rotation=90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.05),NumberSequenceKeypoint.new(1,1)})})
    local bottom=create("Frame",menu,{Position=UDim2.new(0,0,1,-47),Size=UDim2.new(1,0,0,47),BackgroundColor3=Color3.fromRGB(7,11,16),BackgroundTransparency=.25,BorderSizePixel=0,ZIndex=0})
    create("UIGradient",bottom,{Rotation=90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,.2)})})
    local emblem=create("Frame",menu,{Name="StudioEmblem",Position=UDim2.fromOffset(29,24),Size=UDim2.fromOffset(23,20),Rotation=-16,BackgroundTransparency=1,BorderSizePixel=0})
    rounded(emblem,6)
    local logoRim=stroke(emblem,palette.accent,4); logoRim.Name="DecorationStroke"; logoRim.Transparency=.08
    title.Position,title.Size=UDim2.fromOffset(65,15),UDim2.fromOffset(106,32)
    controlRows.subscription.badge.Position=UDim2.fromOffset(184,17)
    controlRows.subscription.badge.Size=UDim2.fromOffset(222,30)
    local studio=button(menu,"Studio",UDim2.fromOffset(413,19),UDim2.fromOffset(44,30))
    studio.TextSize=10; studio.TextColor3=Color3.fromRGB(205,245,145)
    describe(studio,"Оформление с обложек: лайм, стекло, Bubbles и Motion. Выключает Light Menu; игровые настройки не меняет.")
    connect(studio.Activated,function()
        settings.menuSaturation,settings.menuValue=55,96
        settings.bubbles,settings.skinTextures,settings.motion,settings.lowFx=true,true,true,false
        setValue("menuHue",78)
    end)
    api.clearNodes=function() table.clear(nodes) end
    local function paint(object,entry,accent)
        if not object.Parent then return end
        object.BackgroundColor3=entry.selected and palette.control:Lerp(accent,.12) or palette.control
        entry.rim.Color=entry.selected and accent or Color3.fromRGB(120,143,158)
        entry.rim.Transparency=entry.selected and .32 or .79
        object.TextColor3=entry.selected and accent or palette.text
    end
    api.bindNode=function(object,selected)
        local rim=object:FindFirstChildOfClass("UIStroke")
        if rim then
            rim.Name="StudioNodeRim"; rim.Thickness=1
            nodes[object]={selected=selected,rim=rim}
            paint(object,nodes[object],palette.accent)
        end
    end
    api.theme=function(accent)
        logoRim.Color=accent
        for object,entry in pairs(nodes) do if object.Parent then paint(object,entry,accent) else nodes[object]=nil end end
    end
    api.step=function()
        if textureEnabled~=settings.skinTextures then
            textureEnabled=settings.skinTextures
            if textureEnabled and not loading and not asset then attempted=false; settings._skinStatus={texture="idle",mode="procedural"} end
        end
        if not settings.skinTextures then settings._skinStatus.mode="procedural" end
        if registeredAt and settings._skinStatus.mode=="waiting for image" and os.clock()-registeredAt>8 then fail("image unavailable") end
        if not menu.Visible then shadow.Visible=false; return end
        shadow.Visible=not settings.lowFx
        if shadow.Visible then shadow.Position=menu.Position; shadowScale.Scale=scale.Scale end
    end
    table.insert(cleanups,function() alive=false; table.clear(nodes); shadow:Destroy() end)
    return api
end
controlRows.studio=initializeStudioSkin()
end

do
local function initializeFriends()
    local api={revision=0}
    local effect,age,messageAge
    local toast=text(gui,"",{Name="FriendFeedback",AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-148),Size=UDim2.fromOffset(420,38),BackgroundColor3=Color3.fromRGB(10,20,23),BackgroundTransparency=.12,TextSize=13,Visible=false,ZIndex=30})
    rounded(toast,14); stroke(toast,palette.accent).Transparency=.65
    local function notify(message)
        configStatus=message; toast.Text=message; toast.Visible=true; messageAge=0
    end
    local function clearEffect()
        if effect then effect.shine:Destroy(); effect.jewel:Destroy(); if effect.model then effect.model:Destroy() end; effect=nil end
    end
    local function findPlayer(name)
        for _,other in ipairs(Players:GetPlayers()) do if string.lower(other.Name)==name then return other end end
    end
    local function flash(other)
        clearEffect()
        if not other or not other.Character then return end
        local head=other.Character:FindFirstChild("Head")
        if not head then return end
        local shine=create("Highlight",gui,{Adornee=other.Character,FillColor=Color3.fromRGB(125,235,200),OutlineColor=Color3.fromRGB(220,255,242),FillTransparency=.78,OutlineTransparency=.18})
        local jewel=create("BillboardGui",gui,{Adornee=head,Size=UDim2.fromOffset(210,54),StudsOffsetWorldSpace=Vector3.new(0,3.5,0),AlwaysOnTop=false})
        local badge=create("Frame",jewel,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(200,45),BackgroundColor3=Color3.fromRGB(9,23,27),BackgroundTransparency=.12,BorderSizePixel=0})
        rounded(badge,14); local rim=stroke(badge,Color3.fromRGB(143,240,205)); rim.Transparency=.3
        local name=text(badge,"@"..other.Name,{Position=UDim2.fromOffset(12,5),Size=UDim2.new(1,-24,0,18),TextSize=13,TextColor3=Color3.fromRGB(235,255,247)})
        local caption=text(badge,"TEAMMATE LINKED",{Position=UDim2.fromOffset(12,24),Size=UDim2.new(1,-24,0,13),TextSize=9,TextColor3=Color3.fromRGB(143,240,205)})
        local model=create("Model",workspace,{Name="OktanSquadLink"})
        local facets,orbs={},{}
        for index=1,8 do
            facets[index]=create("WedgePart",model,{Name="JewelFacet",Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false,Material=Enum.Material.Neon,Color=index%2==0 and Color3.fromRGB(133,239,209) or Color3.fromRGB(218,255,246),Transparency=.12,Size=Vector3.new(.38,.5,.38)})
        end
        for index=1,8 do
            orbs[index]=create("Part",model,{Shape=Enum.PartType.Ball,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false,Material=Enum.Material.Neon,Color=Color3.fromRGB(176,255,225),Size=Vector3.new(.055,.055,.055),Transparency=.12})
        end
        effect,age={shine=shine,jewel=jewel,model=model,facets=facets,orbs=orbs,head=head,badge=badge,rim=rim,name=name,caption=caption},0
    end

    api.add=function(raw)
        local name=type(raw)=="string" and string.lower(raw:match("^%s*(.-)%s*$")) or ""
        if #name<3 or #name>20 or not name:match("^[%w_]+$") then notify("Нужен username: 3–20 букв, цифр или _"); return false end
        if name==string.lower(player.Name) then notify("Себя добавлять не нужно"); return false end
        if friendNames[name] then notify("@"..name.." уже в тиммейтах"); return false end
        local count=0; for _ in pairs(friendNames) do count+=1 end
        if count>=200 then notify("В списке уже 200 тиммейтов"); return false end
        friendNames[name]=true; api.revision+=1; changed()
        flash(findPlayer(name))
        notify("@"..name.." добавлен в тиммейты OKTAN")
        if api.refresh then api.refresh() end
        return true
    end
    api.remove=function(name)
        name=type(name)=="string" and string.lower(name) or ""
        if not friendNames[name] then return false end
        friendNames[name]=nil; api.revision+=1; changed()
        notify("@"..name.." удалён из тиммейтов")
        if api.refresh then api.refresh() end
        return true
    end
    api.pick=function()
        local camera=workspace.CurrentCamera
        if not camera then return false end
        local mouse=Input:GetMouseLocation()
        local ray=camera:ScreenPointToRay(mouse.X,mouse.Y)
        local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances=player.Character and {player.Character,camera} or {camera}
        local hit=workspace:Raycast(ray.Origin,ray.Direction*160,params)
        if not hit then notify("Наведи курсор на игрока рядом"); return false end
        local object,owner=hit.Instance,nil
        for _=1,12 do
            if not object or object==workspace then break end
            if object:IsA("Model") then owner=Players:GetPlayerFromCharacter(object); if owner then break end end
            object=object.Parent
        end
        local mine=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local theirs=owner and owner.Character and owner.Character:FindFirstChild("HumanoidRootPart")
        if not owner or owner==player or not mine or not theirs then notify("Выбран не игрок • наведи на персонажа"); return false end
        if (mine.Position-theirs.Position).Magnitude>80 then notify("Подойди к игроку ближе: максимум 80 studs"); return false end
        return api.add(owner.Name)
    end
    api.step=function(dt)
        if toast.Visible then messageAge+=dt; if messageAge>3 then toast.Visible=false end end
        if effect then
            age+=dt
            if age>=2.8 or not effect.shine.Parent or not effect.head.Parent then clearEffect()
            else
                local fade=math.clamp((age-1.45)/1.35,0,1)
                local entrance=math.min(1,age*5)
                local animated=settings.motion and not settings.lowFx
                effect.shine.FillTransparency=.78+.22*fade
                effect.shine.OutlineTransparency=.18+.82*fade
                effect.badge.BackgroundTransparency=.12+.88*fade
                effect.rim.Transparency=.3+.7*fade
                effect.name.TextTransparency=fade; effect.caption.TextTransparency=fade
                local base=effect.head.CFrame*CFrame.new(0,2.1+(animated and age*.16 or 0),0)*CFrame.Angles(0,animated and age*1.8 or 0,0)
                for index,part in ipairs(effect.facets) do
                    local upper=index<=4
                    local angle=((index-1)%4)*math.pi/2
                    part.CFrame=base*CFrame.Angles(0,angle,0)*CFrame.new(0,upper and .16 or -.16,.14)*CFrame.Angles(upper and 0 or math.pi,0,0)
                    part.Size=Vector3.new(.38,.5,.38)*math.max(.08,entrance*(1-fade*.3))
                    part.Transparency=.12+.88*fade
                end
                for index,orb in ipairs(effect.orbs) do
                    local angle=index*math.pi/4+(animated and age*1.3 or 0)
                    local radius=.6+fade*.7
                    orb.CFrame=base*CFrame.new(math.cos(angle)*radius,math.sin(angle*2)*.12,math.sin(angle)*radius)
                    orb.Transparency=.12+.88*fade
                end
            end
        end
        if api.uiStep then api.uiStep(dt) end
    end
    table.insert(cleanups,function() clearEffect(); toast:Destroy() end)
    return api
end
controlRows.friends=initializeFriends()
end

local raidReport = button(actionsRow, "Export Debug", UDim2.fromOffset(516, 12), UDim2.fromOffset(184, 32))
raidReport.Visible=false
actionsRow.Size=UDim2.new(1,0,0,56)
for index,control in ipairs({saveButton,resetButton,unloadButton}) do
    control.Position=UDim2.new((index-1)/3,12-(index-1)*4,0,12)
    control.Size=UDim2.new(1/3,-16,0,32)
end
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
        report.skin = settings._skinStatus
        report.performance = settings._performance
        report.subscription = settings._subscriptionInfo
        report.music = settings._musicStatus
        report.weaponTuning = settings._weaponStatus
        report.visualStudio = settings._graphicsStatus
        report.chronoEcho = settings._echoStatus
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
        pendingNumeric = nil; bindDialog.Visible = false; controlRows.bindShield.Visible=false; return
    end
    if capture then
        if name == "Escape" then capture = nil; refreshAll(); return end
        local movedFrom
        if name == "Backspace" then
            bindings[capture] = nil
        elseif allowedKeys[name] then
            for action, key in pairs(bindings) do
                if key == name then movedFrom=action; bindings[action] = nil end
            end
            bindings[capture] = name
        else
            return
        end
        local assignedAction=capture
        capture = nil
        changed()
        if movedFrom and movedFrom~=assignedAction then configStatus="Бинд "..name..": "..movedFrom.." → "..assignedAction end
        refreshAll()
        return
    end
    if processed or not focused then return end
    if name == bindings.menu then setMenu(not menu.Visible); return end
    if menu.Visible or (controlRows.mapOverlay and controlRows.mapOverlay.isOpen()) then return end
    if name == bindings.friendPick then controlRows.friends.pick(); return end
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
                    if settingKey == "musicIndex" then controlRows.music.next(delta > 0 and 1 or -1)
                    else setValue(settingKey, math.clamp(settings[settingKey] + delta, definition[6], definition[7])) end
                end
            end
        end
    end
end)
controlRows.drag = {}
connect(title.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        controlRows.drag.start, controlRows.drag.position = input.Position, menu.Position
    end
end)
connect(Input.InputChanged, function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    if activeSlider then activeSlider(input.Position.X) end
    if controlRows.drag.start then
        local delta = input.Position - controlRows.drag.start
        local camera = workspace.CurrentCamera
        if camera then
            local viewport = camera.ViewportSize
            local half = menu.AbsoluteSize * 0.5
            local x = controlRows.drag.position.X.Scale * viewport.X + controlRows.drag.position.X.Offset + delta.X
            local y = controlRows.drag.position.Y.Scale * viewport.Y + controlRows.drag.position.Y.Offset + delta.Y
            menu.Position = UDim2.fromOffset(
                math.clamp(x, half.X, math.max(half.X, viewport.X - half.X)),
                math.clamp(y, half.Y, math.max(half.Y, viewport.Y - half.Y)))
        end
    end
end)
connect(Input.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        activeSlider, controlRows.drag.start = nil, nil
    end
end)
connect(Input.WindowFocusReleased, function()
    focused = false
    pendingNumeric=nil; bindDialog.Visible=false; controlRows.bindShield.Visible=false
    activeSlider, controlRows.drag.start, capture = nil, nil, nil
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
local islandLabels = { menu = "Menu", inspect = "Inspect", friendPick = "Pick Friend" }
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
do
local function initializeMusicIsland()
    local root = create("Frame", islandHeader, {Name="MusicCapsule", Size=UDim2.new(1,0,0,48), BackgroundTransparency=1, Visible=false})
    local expanded = create("Frame", islandList, {Name="MusicRow", Size=UDim2.new(1,0,0,52), BackgroundTransparency=1, LayoutOrder=-10, Visible=false})
    local emblem = button(root,"O",UDim2.fromOffset(10,9),UDim2.fromOffset(30,30))
    emblem.TextSize=16; emblem.TextColor3=palette.accent
    describe(emblem,"Открыть и свернуть Dynamic Island. Музыка управляется кнопками справа.")
    connect(emblem.Activated,function() islandExpanded=not islandExpanded end)
    local clip = create("Frame",root,{Position=UDim2.fromOffset(50,5),Size=UDim2.new(1,-188,0,39),BackgroundTransparency=1,ClipsDescendants=true})
    local first = text(clip,"",{Name="MusicLine",Position=UDim2.fromOffset(0,0),Size=UDim2.new(1,0,0,21),TextSize=14,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.None})
    local second = text(clip,"",{Name="MusicLineTransition",Position=UDim2.fromOffset(0,10),Size=UDim2.new(1,0,0,21),TextSize=14,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.None,TextTransparency=1})
    local subtitle=text(clip,"",{Position=UDim2.fromOffset(0,22),Size=UDim2.new(1,0,0,16),TextSize=10,TextColor3=palette.muted,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd})
    local bar=create("Frame",root,{Position=UDim2.fromOffset(50,45),Size=UDim2.new(1,-188,0,1),BackgroundColor3=palette.control,BackgroundTransparency=0.45,BorderSizePixel=0})
    local fill=create("Frame",bar,{Size=UDim2.fromScale(0,1),BackgroundColor3=palette.accent,BorderSizePixel=0})
    local controls={}
    for i,entry in ipairs({{"previous","<<"},{"play",">"},{"next",">>"},{"stop",""}}) do
        local item=button(root,entry[2],UDim2.new(1,-132+(i-1)*30,0,10),UDim2.fromOffset(26,28))
        item.TextSize=12; item.BackgroundTransparency=0.8
        if entry[1]=="stop" then
            local square=create("Frame",item,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(7,7),BackgroundColor3=palette.muted,BorderSizePixel=0}); rounded(square,2)
        end
        controls[entry[1]]=item
        connect(item.Activated,function()
            local state=settings._yandexStatus
            local action=entry[1]
            if action=="play" and state and state.playing then action="pause" end
            controlRows.yandex.control(action)
        end)
    end
    describe(controls.play,"Продолжить или приостановить музыку в приложении Яндекса.")
    describe(controls.stop,"Stop. Если приложение не поддерживает остановку — пауза; позиция сбрасывается только при поддержке приложения.")
    local tweens, elapsed, clock, signature, trackKey = {},1,0,nil,nil
    local incoming, outgoing=first,second
    local lineWidth, transitionUntil = 0,0
    local cues, lrcMessage, manual, manualPosition = {},"Без LRC — название и исполнитель",false,0
    local api={root=root,expanded=expanded,controls=controls}
    local function cancel()
        for _,tween in ipairs(tweens) do tween:Cancel() end; table.clear(tweens)
    end
    local function trim(value) return value:match("^%s*(.-)%s*$") end
    local function normalized(value) return string.lower(trim(value)):gsub("%s+"," ") end
    api.parse=function(raw,titleText)
        if type(raw)~="string" or #raw>131072 then return {},"LRC слишком большой" end
        raw=raw:gsub("^\239\187\191","")
        local tagged=raw:match("%[ti:(.-)%]")
        if not tagged or normalized(tagged)~=normalized(titleText or "") then return {},"В LRC нужен [ti:точное название текущего трека]" end
        local result,offset={},tonumber(raw:match("%[offset:([%+%-]?%d+)%]")) or 0
        for line in raw:gmatch("[^\r\n]+") do
            local textValue=line:gsub("%[%d+:%d+%.?%d*%]","")
            if textValue~=line then
                textValue=trim(textValue)
                local cut=utf8.offset(textValue,181); if cut then textValue=textValue:sub(1,cut-1) end
                for minutes,seconds in line:gmatch("%[(%d+):(%d+%.?%d*)%]") do
                    local sec=tonumber(seconds)
                    if sec and sec<60 and #result<1200 then table.insert(result,{time=math.max(0,tonumber(minutes)*60+sec+offset/1000),text=textValue}) end
                end
            end
        end
        table.sort(result,function(a,b) return a.time<b.time end)
        return result,#result>0 and (tostring(#result).." строк LRC") or "В файле нет временных меток"
    end
    api.reload=function()
        local state=settings._yandexStatus
        local ok,raw=pcall(function() return readfile("Oktan-lyrics.lrc") end)
        cues={}
        if ok and state then
            local parsed,values,message=pcall(api.parse,raw,state.title)
            if parsed then cues,lrcMessage=values,message else lrcMessage="Не удалось прочитать UTF-8 LRC" end
        else lrcMessage="Нет Oktan-lyrics.lrc • показываем название трека" end
        return lrcMessage
    end
    local form=controlRows.yandex.form
    form.Size=UDim2.new(1,-20,0,410)
    local reload=button(form,"Reload LRC",UDim2.fromOffset(16,326),UDim2.fromOffset(150,34))
    local sync=button(form,"Sync 0:00",UDim2.fromOffset(178,326),UDim2.fromOffset(150,34))
    local hint=text(form,"LRC: локальный файл с таймкодами; без него — название трека",{Position=UDim2.fromOffset(16,368),Size=UDim2.new(1,-32,0,34),TextColor3=palette.muted,TextSize=11,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left})
    connect(reload.Activated,function() hint.Text=api.reload(); signature=nil end)
    connect(sync.Activated,function()
        if #cues==0 then hint.Text="Сначала загрузи LRC текущего трека"; return end
        manual,manualPosition=true,0
        hint.Text="Ручная синхронизация от 0:00 • нажимай одновременно с началом трека"
        signature=nil
    end)
    describe(sync,"Когда Windows не передаёт позицию: запусти трек с начала и одновременно нажми Sync 0:00. Это ручная синхронизация, не распознавание песни.")
    local function transition(value,caption,state)
        cancel()
        outgoing,incoming=incoming,outgoing
        incoming.Text=value
        incoming.Position=UDim2.fromOffset(0,settings.motion and not settings.lowFx and 9 or 0)
        incoming.TextTransparency=settings.motion and not settings.lowFx and 1 or 0
        subtitle.Text=caption
        local measured=game:GetService("TextService"):GetTextSize(value,14,Enum.Font.GothamBold,Vector2.new(4096,30))
        lineWidth=measured.X
        incoming.Size=UDim2.fromOffset(math.max(280,lineWidth+8),21)
        transitionUntil=clock+0.3
        if settings.motion and not settings.lowFx then
            for object,goal in pairs({[outgoing]={Position=UDim2.fromOffset(0,-9),TextTransparency=1},[incoming]={Position=UDim2.fromOffset(0,0),TextTransparency=state=="stopped" and .4 or 0}}) do
                local tween=TweenService:Create(object,TweenInfo.new(.24,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),goal)
                table.insert(tweens,tween); tween:Play()
            end
        else outgoing.TextTransparency=1 end
    end
    api.current=function() return incoming.Text end
    api.step=function(dt)
        local data=settings._yandexStatus
        if manual and data and data.playing then manualPosition+=dt end
        elapsed+=dt; clock+=dt
        if elapsed<1/30 then return end
        elapsed=0
        local active=settings.island and settings.islandMusic and data and type(data.title)=="string" and data.title~=""
            and (not data.updatedAt or os.clock()-data.updatedAt<12)
        root.Visible=active==true
        expanded.Visible=active==true and islandExpanded
        islandBrand.Visible,islandClock.Visible,islandKills.Visible,islandChevron.Visible=not active or islandExpanded,not active or islandExpanded,not active or islandExpanded,not active or islandExpanded
        settings._musicIslandWidth=active and not islandExpanded and (data.stopped and 440 or 500) or 420
        if not active then return end
        local parent=islandExpanded and expanded or islandHeader
        if root.Parent~=parent then root.Parent=parent end
        local key=data.title.."\0"..tostring(data.artist)
        if key~=trackKey then trackKey=key; manual,manualPosition=false,0; api.reload(); signature=nil end
        local position
        if manual then position=manualPosition
        elseif data.positionAvailable then position=math.max(0,(data.positionMs or 0)/1000)+(data.playing and math.max(0,os.clock()-(data.updatedAt or os.clock())) or 0) end
        local value,caption=data.title,tostring(data.artist or "Яндекс Музыка")
        local progress=0
        if #cues>0 and position and not data.stopped then
            local index
            local left,right=1,#cues
            while left<=right do
                local middle=math.floor((left+right)/2)
                if cues[middle].time<=position then index=middle; left=middle+1 else right=middle-1 end
            end
            if index then
                local cue,following=cues[index],cues[index+1]
                value=cue.text~="" and cue.text or data.title
                caption=(manual and "Manual sync • " or "")..data.title
                if following and following.time>cue.time then progress=math.clamp((position-cue.time)/(following.time-cue.time),0,1) end
            end
        end
        local state=data.stopped and "stopped" or data.playing and "playing" or "paused"
        if state=="paused" then caption="Pause • "..caption elseif state=="stopped" then caption="Stopped • "..tostring(data.artist or "") end
        local nextSignature=value.."\0"..caption.."\0"..state
        if signature~=nextSignature then signature=nextSignature; transition(value,caption,state) end
        if clock>transitionUntil and settings.motion and not settings.lowFx and lineWidth>clip.AbsoluteSize.X and clip.AbsoluteSize.X>0 then
            local overflow=lineWidth-clip.AbsoluteSize.X+8
            local phase=(clock-transitionUntil)% (4+overflow/24*2)
            local offset=phase<2 and 0 or phase<2+overflow/24 and (phase-2)*24 or phase<4+overflow/24 and overflow or math.max(0,overflow-(phase-4-overflow/24)*24)
            incoming.Position=UDim2.fromOffset(-offset,0)
        end
        incoming.TextColor3=palette.text
        emblem.TextColor3,fill.BackgroundColor3=palette.accent,palette.accent
        controls.play.Text=data.playing and "II" or ">"
        fill.Size=UDim2.fromScale(progress,1)
        hint.Text=#cues>0 and not position and (lrcMessage.." • позиция недоступна, используй Sync 0:00") or hint.Text
    end
    table.insert(cleanups,function() cancel(); root:Destroy(); expanded:Destroy() end)
    return api
end
controlRows.musicIsland=initializeMusicIsland()
end

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
    BackgroundTransparency = 0.035, BorderSizePixel = 0, Visible = false, ZIndex = 16,
})
rounded(inspector, 18)
stroke(inspector, palette.accent)
local inspectorScale = create("UIScale", inspector, { Scale = 1 })
text(inspector, "INSPECT / LOADOUT", {
    Position = UDim2.fromOffset(18, 16), Size = UDim2.fromOffset(280, 26),
    TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold,
})
local inspectClose = text(inspector, "×", {
    Position = UDim2.new(1, -42, 0, 12), Size = UDim2.fromOffset(30, 30), TextSize = 22,
}, "TextButton")
connect(inspectClose.Activated, function() controlRows.inspectorMotion.close() end)
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
    if inspector.Visible then controlRows.inspectorMotion.close(); return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    local nearest, best = controlRows.inventoryArt.containerTarget(camera), settings.inspectRadius
    if nearest then best=0 end
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
    BackgroundColor3 = palette.panel, BackgroundTransparency = 0.12,
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
local cardArea = create("CanvasGroup", inspector, {
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
        controlRows.inspectorMotion.tab(name)
    end)
end
local previousInventory = button(inspector, "Previous", UDim2.fromOffset(244, 497), UDim2.fromOffset(130, 28))
local nextInventory = button(inspector, "Next", UDim2.fromOffset(522, 497), UDim2.fromOffset(130, 28))
connect(previousInventory.Activated, function()
    controlRows.inspectorMotion.page(-1)
end)
connect(nextInventory.Activated, function()
    controlRows.inspectorMotion.page(1)
end)
local function visualCopy(source, parent)
    if not source then return nil end
    local archivable=source.Archivable
    local ok, copy = pcall(function() source.Archivable=true; return source:Clone() end)
    source.Archivable=archivable
    if not ok or not copy then return nil end
    for _, object in ipairs(copy:GetDescendants()) do
        if object:IsA("LuaSourceContainer") then object:Destroy() end
        if object:IsA("BasePart") then object.Anchored = true; object.CanCollide = false end
    end
    if copy:IsA("BasePart") then copy.Anchored = true; copy.CanCollide = false end
    copy.Parent = parent
    return copy
end
do
local function initializeLiveInspector()
    local api={parts={},bones={},elapsed=0,scan=0}
    api.clear=function() table.clear(api.parts); table.clear(api.bones); api.character=nil; api.root=nil end
    local function sync()
        local root=api.root
        if not root or not root.Parent then return end
        local front=CFrame.Angles(0,math.pi,0)
        for _,pair in ipairs(api.parts) do
            if pair.source.Parent and pair.copy.Parent then
                pair.copy.CFrame=front*root.CFrame:ToObjectSpace(pair.source.CFrame)
                pair.copy.Transparency=pair.source.Transparency
                pair.copy.LocalTransparencyModifier=0
            else api.needsRebuild=true end
        end
        for _,pair in ipairs(api.bones) do
            if pair.source.Parent and pair.copy.Parent then pair.copy.Transform=pair.source.Transform end
        end
    end
    api.build=function(character)
        api.clear(); api.needsRebuild=false
        if previewWorld then previewWorld:Destroy() end
        previewCenter=nil
        previewWorld=create("WorldModel",preview)
        if not character then return end
        local root=character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
        if not root or not root:IsA("BasePart") then return end
        local model=visualCopy(character,previewWorld)
        if not model then return end
        -- Manual pose mirroring owns the clone. No cloned animation/physics,
        -- particle/audio logic, nor joints with references outside the viewport.
        for _,object in ipairs(model:GetDescendants()) do
            if object:IsA("JointInstance") or object:IsA("Constraint") or object:IsA("Animator") or object:IsA("Sound") then object:Destroy()
            elseif object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam") then object.Enabled=false
            elseif object:IsA("Humanoid") then object.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None end
        end
        local function match(source,copy,depth)
            if depth>16 or #api.parts>=320 then return end
            if source:IsA("BasePart") and copy:IsA("BasePart") then table.insert(api.parts,{source=source,copy=copy})
            elseif source:IsA("Bone") and copy:IsA("Bone") then table.insert(api.bones,{source=source,copy=copy}) end
            local byName={}
            for _,child in ipairs(copy:GetChildren()) do
                local key=child.Name.."/"..child.ClassName
                byName[key]=byName[key] or {}; table.insert(byName[key],child)
            end
            local used={}
            for _,child in ipairs(source:GetChildren()) do
                local key=child.Name.."/"..child.ClassName
                used[key]=(used[key] or 0)+1
                local target=byName[key] and byName[key][used[key]]
                if target then match(child,target,depth+1) end
            end
        end
        match(character,model,0)
        api.character,api.root=character,root
        api.count=#character:GetDescendants()
        sync()
        if #api.parts==0 then return end
        local cf,size=model:GetBoundingBox()
        previewCenter,previewRadius=cf.Position,math.max(size.X,size.Y,size.Z,2)*2.1
        previewCamera.CFrame=CFrame.lookAt(previewCenter+Vector3.new(0,size.Y*.08,previewRadius),previewCenter)
    end
    api.step=function(dt)
        if not inspector.Visible or not api.character then return end
        if inspectTarget and inspectTarget.Character~=api.character then api.needsRebuild=true; return end
        api.elapsed+=dt; api.scan+=dt
        if api.elapsed<1/(settings.lowFx and 15 or 30) then return end
        api.elapsed=0; sync()
        if api.scan>=1 then
            api.scan=0
            if #api.character:GetDescendants()~=api.count then api.needsRebuild=true end
        end
    end
    table.insert(cleanups,api.clear)
    return api
end
controlRows.inspectorLive=initializeLiveInspector()
end
local function rebuildPreview(character) controlRows.inspectorLive.build(character) end

do
local function initializeInventoryArt()
    local api={pending={},epoch=0}
    local imageCache=setmetatable({},{__mode="k"})
    local function source(item)
        if item and item:IsA("ObjectValue") then return item.Value or item end
        return item
    end
    api.source=source
    local function imageValue(value)
        if type(value)=="number" and value>0 and value%1==0 then return "rbxassetid://"..string.format("%.0f",value) end
        if type(value)~="string" then return nil end
        if value:match("^%d+$") then return "rbxassetid://"..value end
        if value:match("^rbxassetid://%d+$") or value:match("^rbxasset://") or value:match("^rbxthumb://") then return value end
        local id=value:match("^https?://www%.roblox%.com/asset/%?id=(%d+)")
        return id and "rbxassetid://"..id or nil
    end
    local function resolveImage(item)
        item=source(item); if not item then return nil end
        if item:IsA("Tool") then local id=imageValue(item.TextureId); if id then return id end end
        for _,key in ipairs({"Icon","Image","Thumbnail","ImageId","IconId","TextureId"}) do
            local id=imageValue(item:GetAttribute(key)); if id then return id end
            local child=item:FindFirstChild(key)
            if child and (child:IsA("StringValue") or child:IsA("NumberValue") or child:IsA("IntValue")) then id=imageValue(child.Value); if id then return id end end
        end
        local count=0
        for _,child in ipairs(item:GetDescendants()) do
            count+=1; if count>128 then break end
            if child:IsA("ImageLabel") or child:IsA("ImageButton") then local id=imageValue(child.Image); if id then return id end end
        end
        return nil
    end
    api.image=function(item)
        item=source(item); if not item then return nil end
        local cached=imageCache[item]
        if cached and os.clock()-cached.at<2 then return cached.id end
        local id=resolveImage(item)
        imageCache[item]={at=os.clock(),id=id}
        return id
    end
    api.containerTarget=function(camera)
        local ray=camera:ViewportPointToRay(camera.ViewportSize.X*.5,camera.ViewportSize.Y*.5)
        local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances=player.Character and {player.Character,camera} or {camera}
        local hit=workspace:Raycast(ray.Origin,ray.Direction*settings.containerReach,params)
        local current=hit and hit.Instance
        for _=1,12 do
            if not current or current==workspace then break end
            local inventory=current:FindFirstChild("Inventory")
            local properties=current:FindFirstChild("Properties")
            if current:IsA("Model") and inventory and (current.Parent and current.Parent.Name=="Containers" or properties and properties:GetAttribute("ContainerType")=="Container") then
                return {Name=current:GetAttribute("DisplayName") or current.Name,Character=current,Parent=Players,Corpse=true,Container=true}
            end
            current=current.Parent
        end
    end
    local function viewport(card,item,character)
        local candidates={}
        local equipped=character and character:FindFirstChild(item.Name)
        if equipped then table.insert(candidates,equipped) end
        table.insert(candidates,source(item))
        local catalog=game:GetService("ReplicatedStorage"):FindFirstChild("ItemsList")
        local catalogItem=catalog and catalog:FindFirstChild(item.Name)
        if catalogItem then table.insert(candidates,catalogItem) end
        local definition=source(item)
        if definition then
            for _,name in ipairs({"Model","ViewModel","WorldModel","DisplayModel"}) do
                local visual=definition:FindFirstChild(name)
                if visual and visual:IsA("ObjectValue") and visual.Value then table.insert(candidates,visual.Value) end
            end
        end
        for _,model in ipairs(candidates) do
            if model and (model:IsA("BasePart") or model:FindFirstChildWhichIsA("BasePart",true)) and #model:GetDescendants()<=320 then
                local frame
                local ok,drawn=pcall(function()
                    frame=create("ViewportFrame",card,{Name="ItemModel",BackgroundTransparency=1,Position=UDim2.fromOffset(8,3),Size=UDim2.new(1,-16,0,53),Ambient=Color3.fromRGB(190,205,215),LightColor=Color3.fromRGB(235,245,255),LightDirection=Vector3.new(-1,-1,-1)})
                    local world=create("WorldModel",frame)
                    local wrapper=create("Model",world)
                    local copy=visualCopy(model,wrapper)
                    if not copy then frame:Destroy(); return false end
                    for _,part in ipairs(copy:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.LocalTransparencyModifier=0
                            if part.Transparency>=.99 then part:Destroy() end
                        end
                    end
                    if copy:IsA("BasePart") then copy.LocalTransparencyModifier=0 end
                    if not wrapper:FindFirstChildWhichIsA("BasePart",true) then frame:Destroy(); return false end
                    local cf,size=wrapper:GetBoundingBox()
                    local radius=math.max(size.X,size.Y,size.Z,.5)*1.9
                    frame.CurrentCamera=create("Camera",frame,{FieldOfView=35,CFrame=CFrame.lookAt(cf.Position+Vector3.new(radius*.18,radius*.12,radius),cf.Position)})
                    return true
                end)
                if ok and drawn then return true end
                if frame and frame.Parent then frame:Destroy() end
            end
        end
        return false
    end
    api.clear=function() api.epoch+=1; table.clear(api.pending); if controlRows.hudMotion then controlRows.hudMotion.clear() end end
    api.draw=function(card,item,character,reference)
        reference=reference or item
        local durability,maximum=reference:GetAttribute("Durability"),reference:GetAttribute("MaxDurability")
        if type(durability)=="number" and type(maximum)=="number" and maximum>0 then
            local percent=math.round(math.clamp(durability/maximum,0,1)*100)
            local chip=text(card,"COND "..percent.."%",{Name="ItemCondition",Position=UDim2.new(1,-68,0,4),Size=UDim2.fromOffset(62,16),TextSize=8,TextColor3=Color3.fromRGB(188,211,190),BackgroundColor3=palette.background,BackgroundTransparency=.15,ZIndex=4})
            rounded(chip,5)
        end
        local fallback=text(card,"",{Name="ArtStatus",Position=UDim2.fromOffset(8,8),Size=UDim2.new(1,-16,0,36),TextSize=10,TextColor3=palette.muted})
        local id=api.image(item)
        local function modelFallback()
            if not card.Parent then return end
            local existing=card:FindFirstChild("ItemModel")
            fallback.Text=(existing and existing.CurrentCamera or viewport(card,item,character)) and "" or "NO PREVIEW"
        end
        if not id then modelFallback(); return end
        modelFallback()
        local image=create("ImageLabel",card,{Name="ItemIcon",BackgroundTransparency=1,Image=id,ImageTransparency=1,ScaleType=Enum.ScaleType.Fit,Position=UDim2.fromOffset(10,4),Size=UDim2.new(1,-20,0,50)})
        local entry={card=card,image=image,fallback=fallback,age=0,failed=false,model=modelFallback,epoch=api.epoch}
        table.insert(api.pending,entry)
        task.spawn(function()
            pcall(function() game:GetService("ContentProvider"):PreloadAsync({image},function(_,status)
                if status~=Enum.AssetFetchStatus.Success then entry.failed=true end
            end) end)
        end)
    end
    api.step=function(dt)
        for i=#api.pending,1,-1 do
            local entry=api.pending[i]
            if entry.epoch~=api.epoch or not entry.card.Parent then table.remove(api.pending,i)
            else
                entry.age+=dt
                if entry.image.IsLoaded then
                    entry.fallback.Text=""
                    local model=entry.card:FindFirstChild("ItemModel"); if model then model.Visible=false end
                    if settings.motion and not settings.lowFx then TweenService:Create(entry.image,TweenInfo.new(.22),{ImageTransparency=0}):Play() else entry.image.ImageTransparency=0 end
                    table.remove(api.pending,i)
                elseif entry.failed or entry.age>3 then
                    entry.image:Destroy(); entry.model(); table.remove(api.pending,i)
                end
            end
        end
    end
    return api
end
controlRows.inventoryArt=initializeInventoryArt()
end

local function itemImage(item) return controlRows.inventoryArt.image(item) end
local function collectInventory(owner)
    local categories = { Gear = {}, Weapons = {}, Loot = {} }
    local character = owner.Character
    local assigned, seen = {}, {}
    local function add(category, item, slot)
        if not item then return end
        local reference=item
        item=controlRows.inventoryArt.source(item)
        if not item then return end
        if not seen[item] then
            seen[item] = true
            table.insert(categories[category], { item = item, reference = reference, slot = slot })
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
            if not assigned[controlRows.inventoryArt.source(item)] then add("Loot", item, item:GetAttribute("Slot") or container.Name) end
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
    if type(inspectTarget)=="table" and inspectTarget.Container and previewSignature==nil then selectedInventoryTab,inventoryPage="Loot",1 end
    local categories = collectInventory(inspectTarget)
    settings._inventoryCounts=string.format("%d gear  /  %d weapons  /  %d loot",#categories.Gear,#categories.Weapons,#categories.Loot)
    local entries = categories[selectedInventoryTab]
    local pagesCount = math.max(1, math.ceil(#entries / 9))
    inventoryPage = math.clamp(inventoryPage, 1, pagesCount)
    local signature = { inspectTarget.Name, selectedInventoryTab, tostring(inventoryPage) }
    local equipment = { inspectTarget.Name, tostring(inspectTarget.Character),
        tostring(inspectTarget.Character and #inspectTarget.Character:GetChildren() or 0) }
    for _, name in ipairs({ "Gear", "Weapons", "Loot" }) do
        local list = categories[name]
        for _, entry in ipairs(list) do
            table.insert(signature, name .. "/" .. entry.slot .. "/" .. entry.item.Name .. "/" .. tostring(itemImage(entry.item)) .. "/" .. tostring(entry.reference:GetAttribute("Amount")) .. "/" .. tostring(entry.reference:GetAttribute("Durability")))
            if name ~= "Loot" then table.insert(equipment, name .. entry.item.Name) end
        end
    end
    local currentPreview = table.concat(equipment, "|")
    if previewSignature ~= currentPreview or controlRows.inspectorLive.needsRebuild then
        if type(inspectTarget)=="table" and inspectTarget.Container then
            controlRows.inspectorLive.clear()
            if previewWorld then previewWorld:Destroy(); previewWorld=nil end
            previewCenter=nil
        else rebuildPreview(inspectTarget.Character) end
        previewSignature = currentPreview
    end
    previewName.Text = ((type(inspectTarget) == "table" and inspectTarget.Container) and "CONTAINER · " or (type(inspectTarget) == "table" and inspectTarget.Corpse) and "CORPSE · " or "") .. inspectTarget.Name
    previousInventory.Visible=pagesCount>1
    nextInventory.Visible=pagesCount>1
    inventoryNote.Text = string.format("%d items  |  Page %d / %d", #entries, inventoryPage, pagesCount)
    if (type(inspectTarget) == "table" and inspectTarget.Corpse) and not deltaInventory(inspectTarget) then
        inventoryNote.Text = "Лут недоступен клиенту. Показано только распознанное снаряжение."
    end
    local current = table.concat(signature, "|")
    if inventorySignature == current then return end
    inventorySignature = current
    controlRows.inventoryArt.clear()
    for _, card in ipairs(cards) do card:Destroy() end
    table.clear(cards)
    for name, control in pairs(tabsInventory) do
        control.TextColor3 = name == selectedInventoryTab and palette.accent or palette.muted
        control.BackgroundColor3=name==selectedInventoryTab and palette.control:Lerp(palette.accent,.12) or palette.control
        control.BackgroundTransparency=name==selectedInventoryTab and .05 or .45
    end
    for index = (inventoryPage - 1) * 9 + 1, math.min(inventoryPage * 9, #entries) do
        local entry = entries[index]
        local card = create("Frame", cardArea, {
            BackgroundColor3 = palette.panel, BorderSizePixel = 0, LayoutOrder = index,
        })
        rounded(card, 10)
        stroke(card,palette.accent).Transparency=.82
        controlRows.hudMotion.card(card,index)
        controlRows.inventoryArt.draw(card,entry.item,inspectTarget.Character,entry.reference)
        local caption = text(card, entry.item.Name, {
            Position = UDim2.fromOffset(6, 56), Size = UDim2.new(1, -12, 0, 34),
            TextWrapped = true, TextSize = 12, TextScaled = true,
        })
        create("UITextSizeConstraint", caption, { MinTextSize = 8, MaxTextSize = 12 })
        text(card, entry.slot .. (entry.reference:GetAttribute("Amount") and " · ×"..tostring(entry.reference:GetAttribute("Amount")) or ""), {
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
        controlRows.inspectorLive.clear()
        controlRows.inventoryArt.clear()
        for _, card in ipairs(cards) do card:Destroy() end
        table.clear(cards)
        if previewWorld then previewWorld:Destroy(); previewWorld = nil end
        inventorySignature, previewSignature, previewCenter = nil, nil, nil
    end
end)

do
local function initializeHudMotion()
    local api={tweens={},clock=0,elapsed=1,previewElapsed=0}
    local titleLine=create("Frame",inspector,{Name="InspectorAccent",Position=UDim2.fromOffset(18,46),Size=UDim2.new(1,-36,0,1),BackgroundColor3=palette.accent,BackgroundTransparency=.55,BorderSizePixel=0})
    local mode=text(inspector,"LIVE LOADOUT",{Position=UDim2.new(1,-190,0,18),Size=UDim2.fromOffset(134,22),TextColor3=palette.accent,TextSize=9,BackgroundColor3=palette.control,BackgroundTransparency=.3})
    rounded(mode,8)
    local empty=text(preview,"",{Name="InspectorPreviewState",Position=UDim2.new(0,12,1,-72),Size=UDim2.new(1,-24,0,54),TextWrapped=true,TextSize=11,TextColor3=palette.muted})
    local totals=text(inspector,"",{Name="InspectorTotals",Position=UDim2.fromOffset(16,500),Size=UDim2.fromOffset(210,22),TextSize=10,TextColor3=palette.muted})
    local logo=create("Frame",islandHeader,{Name="IslandMark",Position=UDim2.fromOffset(18,17),Size=UDim2.fromOffset(12,12),Rotation=-15,BackgroundTransparency=1,BorderSizePixel=0})
    rounded(logo,4); local logoRim=stroke(logo,palette.accent); logoRim.Thickness=2
    islandBrand.Position=UDim2.fromOffset(42,0); islandBrand.Size=UDim2.fromOffset(66,44)
    local divider=create("Frame",island,{Position=UDim2.new(0,20,0,47),Size=UDim2.new(1,-40,0,1),BackgroundColor3=palette.accent,BackgroundTransparency=.78,BorderSizePixel=0})
    local dashboard=create("Frame",islandList,{Name="IslandDashboard",Size=UDim2.new(1,0,0,68),BackgroundTransparency=1,LayoutOrder=-20})
    local values={}
    for i,label in ipairs({"RAID / SESSION","BOUND KEYS","TEAMMATES"}) do
        local tile=create("Frame",dashboard,{Position=UDim2.new((i-1)/3,3,0,3),Size=UDim2.new(1/3,-6,1,-6),BackgroundColor3=palette.panel,BackgroundTransparency=.18,BorderSizePixel=0})
        rounded(tile,12); stroke(tile,palette.accent).Transparency=.88
        text(tile,label,{Position=UDim2.fromOffset(10,8),Size=UDim2.new(1,-20,0,12),TextSize=8,TextColor3=palette.muted,TextXAlignment=Enum.TextXAlignment.Left})
        values[i]=text(tile,"—",{Position=UDim2.fromOffset(10,26),Size=UDim2.new(1,-20,0,26),TextSize=20,Font=Enum.Font.GothamBold,TextColor3=palette.text,TextXAlignment=Enum.TextXAlignment.Left})
    end
    text(islandList,"SHORTCUTS",{Name="IslandShortcutsTitle",LayoutOrder=-1,Size=UDim2.new(1,0,0,24),TextSize=9,TextColor3=palette.muted,TextXAlignment=Enum.TextXAlignment.Left})
    api.clear=function()
        for _,tween in ipairs(api.tweens) do tween:Cancel() end
        table.clear(api.tweens)
    end
    api.card=function(card,index)
        local hoverTween
        local function hover(color)
            if hoverTween then hoverTween:Cancel() end
            if not settings.motion or settings.lowFx then card.BackgroundColor3=color; return end
            hoverTween=TweenService:Create(card,TweenInfo.new(.2),{BackgroundColor3=color}); hoverTween:Play()
        end
        card.MouseEnter:Connect(function() hover(palette.control) end)
        card.MouseLeave:Connect(function() hover(palette.panel) end)
        card.AncestryChanged:Connect(function() if not card.Parent and hoverTween then hoverTween:Cancel() end end)
        if not settings.motion or settings.lowFx then return end
        local scale=create("UIScale",card,{Scale=.95})
        card.BackgroundTransparency=.65
        local tween=TweenService:Create(scale,TweenInfo.new(.24,Enum.EasingStyle.Quart,Enum.EasingDirection.Out,0,false,((index-1)%9)*.018),{Scale=1})
        local fade=TweenService:Create(card,TweenInfo.new(.26),{BackgroundTransparency=.12})
        table.insert(api.tweens,tween); table.insert(api.tweens,fade); tween:Play(); fade:Play()
    end
    local shown=false
    api.step=function(dt)
        api.clock+=dt; api.elapsed+=dt
        api.previewElapsed+=dt
        logo.Visible=islandBrand.Visible
        logoRim.Color,divider.BackgroundColor3,titleLine.BackgroundColor3=palette.accent,palette.accent,palette.accent
        divider.Visible=islandExpanded
        local target=islandExpanded and 45 or 0
        islandChevron.Text="+"
        local rotation=islandChevron.Rotation or 0
        islandChevron.Rotation=settings.motion and rotation+(target-rotation)*(1-math.exp(-16*dt)) or target
        if inspector.Visible~=shown then shown=inspector.Visible; if not shown then api.clear() end end
        if api.elapsed<.25 then return end
        api.elapsed=0
        if inspector.Visible then
            totals.Text=settings._inventoryCounts or ""
            local proxy=type(inspectTarget)=="table" and inspectTarget
            mode.Text=proxy and proxy.Container and "CONTAINER / LIVE" or proxy and proxy.Corpse and "CORPSE / LOOT" or "LIVE LOADOUT"
            mode.TextColor3=palette.accent
            empty.Text=proxy and proxy.Container and "Содержимое доступно справа во вкладке Loot" or not previewCenter and "3D-модель недоступна\nПредметы показаны справа" or ""
        end
        if island.Visible and islandExpanded then
            local bound,friends=0,0
            for _ in pairs(bindings) do bound+=1 end
            for _ in pairs(friendNames) do friends+=1 end
            values[1].Text=raid.kills~=nil and tostring(raid.kills) or "—"
            values[2].Text,values[3].Text=tostring(bound),tostring(friends)
        end
    end
    table.insert(cleanups,function() api.clear() end)
    return api
end
controlRows.hudMotion=initializeHudMotion()
end

controlRows.hudTiming={inventory=1,hud=1}
local function updateHud(dt)
    controlRows.inspectorLive.step(dt)
    controlRows.inventoryArt.step(dt)
    controlRows.hudMotion.step(dt)
    controlRows.release.step(dt)
    controlRows.profiles.uiStep()
    controlRows.inspectorMotion.step(dt)
    controlRows.hudTiming.inventory += dt
    controlRows.hudTiming.hud += dt
    local camera = workspace.CurrentCamera
    if camera then
        local viewport = camera.ViewportSize
        local hudScale = math.min(1, math.max(0.2, (viewport.X - 32) / math.max(390, settings._musicIslandWidth or 420)), math.max(0.2, (viewport.Y - 32) / 560))
        islandScale.Scale = hudScale
        inspectorScale.Scale = hudScale
        island.Position = UDim2.new(0.5, 0, 0, math.min(settings.islandY, math.max(0, viewport.Y - 300 * hudScale)))
    end
    island.Visible = settings.island
    local desiredSize = islandExpanded and UDim2.fromOffset(420, 300) or UDim2.fromOffset(settings._musicIslandWidth or 420, 48)
    island.Size = settings.motion and island.Size:Lerp(desiredSize, 1 - math.exp(-14 * dt)) or desiredSize
    islandScroll.Visible = islandExpanded
    if controlRows.hudTiming.hud >= 0.2 then
    controlRows.hudTiming.hud = 0
    local sections = {}
    if settings._subscriptionSummary then table.insert(sections, settings._subscriptionSummary) end
    if settings._musicStatus and settings._musicStatus.playing then table.insert(sections, "Music: " .. settings._musicStatus.title:sub(1, 42)) end
    if raid.kills ~= nil then table.insert(sections, (raid.session and "Session kills: " or "Raid kills: ") .. tostring(raid.kills)) end
    if raid.extracted ~= nil then
        table.insert(sections, "Extracted")
        table.insert(sections, #raid.extracted > 0 and table.concat(raid.extracted, "\n") or "No items")
    end
    islandBody.Visible = #sections > 0
    islandBody.Text = table.concat(sections, "\n")
    updateIslandRows()
    end

    if inspector.Visible and controlRows.hudTiming.inventory >= 0.5 then
        controlRows.hudTiming.inventory = 0
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
    ["Наведение"] = { "Наведение", "Цели и проверки", "Область и плавность", "Weapon Tuning" },
    ESP = { "Общее", "Подписи", "Геометрия", "Цвет и оформление", "Loot" , "Map" },
    ["Мир"] = { "Освещение", "Vegetation", "Visual Studio" },
    ["Камера"] = { "Зум", "Прицел", "Vision", "Viewmodel" },
    ["Бинды"] = { "Инвентарь", "Dynamic Island", "Управление", "Назначения функций" },
    ["Настройки"] = { "Оформление", "Клиент", "Music", "Performance" },
}
local settingGroup = { mapPlayers="Map", mapNames="Map", mapFriendsOnly="Map", mapTextSize="Map", containerReach="Инвентарь", containerEsp="Loot", auroraEsp="Loot", espStyle = "Цвет и оформление", skinTextures = "Оформление", islandMusic = "Dynamic Island", adaptiveEsp = "Performance", lowFx = "Performance", perfDebug = "Performance", yandexPlay = "Music", spotifyPlay = "Music", musicPlay = "Music", musicVolume = "Music", musicRepeat = "Music", musicIndex = "Music", noRecoil = "Weapon Tuning", aimEase = "Область и плавность", aimFilter = "Область и плавность", graphics = "Visual Studio", gfxTier = "Visual Studio", gfxLook = "Visual Studio", echo = "Оформление", echoDelay = "Оформление", echoFreeze = "Оформление", motion = "Оформление", killFx = "Оформление", crossStyle = "Прицел", crossWidth = "Прицел", noLeaves = "Vegetation", noGrass = "Vegetation", corpseEsp = "Loot", itemEsp = "Loot", lootThrough = "Loot", lootRange = "Loot", lootTextSize = "Loot",
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
local graphBindingLabels = {}
local activeDetailEntry
local function bindingSuffix(key)
    local assigned = bindings[key]
    if assigned then return "  [" .. assigned .. "]" end
    local down, up = bindings[key .. "Minus"], bindings[key .. "Plus"]
    if down or up then return "  [− " .. (down or "—") .. " / + " .. (up or "—") .. "]" end
    return ""
end
table.insert(refreshers, function()
    for object, entry in pairs(graphBindingLabels) do
        if object.Parent then object.Text = entry.label .. bindingSuffix(entry.key) end
    end
end)
local graphConnections = {}
table.insert(cleanups, function() for _, connection in ipairs(graphConnections) do connection:Disconnect() end end)
local graphTweens, shimmerTweens = {}, {}
local shimmerEnabled
local function syncShimmers()
    local enabled=menu.Visible and settings.motion and not settings.lowFx
    if enabled==shimmerEnabled then return end
    shimmerEnabled=enabled
    for _,tween in ipairs(shimmerTweens) do if enabled then tween:Play() else tween:Pause() end end
end
connect(menu:GetPropertyChangedSignal("Visible"),syncShimmers)
table.insert(refreshers,syncShimmers)
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
    table.clear(shimmerTweens)
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
table.insert(refreshers, function()
    if activeDetailEntry then detailTitle.Text = activeDetailEntry.label .. bindingSuffix(activeDetailEntry.key) end
end)
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
    activeDetailEntry = nil
    clearDetail()
    detailTitle.Text = titleText
    detail.Visible, graph.Visible = true, false
    detail.Position = UDim2.fromOffset(32, 88)
    detail.BackgroundTransparency = 0.35
    animate(detail, { Position = UDim2.fromOffset(20, 88), BackgroundTransparency = 0.04 }, 0.24)
    detailBody.CanvasPosition = Vector2.new(0, 0)
    tooltip.Visible = false
end
connect(controlRows.subscription.badge.Activated, function()
    openDetail("Subscription")
    moveDetail(controlRows.subscription.form, 1)
end)
local friendForm,refreshFriendList
do
    local api=controlRows.friends
    friendForm=create("Frame",pages["Настройки"],{Name="FriendsPanel",Size=UDim2.new(1,-12,0,390),BackgroundTransparency=1,Visible=false})
    api.form=friendForm
    text(friendForm,"YOUR SQUAD",{Position=UDim2.fromOffset(8,0),Size=UDim2.new(1,-16,0,22),TextColor3=palette.accent,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left})
    local input=text(friendForm,"",{Name="FriendUsername",Position=UDim2.fromOffset(8,30),Size=UDim2.new(1,-132,0,36),BackgroundColor3=palette.control,BackgroundTransparency=.15,PlaceholderText="Add Roblox username…",ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left},"TextBox")
    rounded(input,11); create("UIPadding",input,{PaddingLeft=UDim.new(0,12)})
    local add=button(friendForm,"Add",UDim2.new(1,-112,0,30),UDim2.fromOffset(104,36))
    local quick=row(friendForm,0,64); quick.Position,quick.Size=UDim2.fromOffset(8,78),UDim2.new(1,-16,0,64)
    text(quick,"Quick Add",{Position=UDim2.fromOffset(14,6),Size=UDim2.new(1,-180,0,24),TextSize=14,TextXAlignment=Enum.TextXAlignment.Left})
    text(quick,"Наведи на игрока → нажми бинд",{Position=UDim2.fromOffset(14,33),Size=UDim2.new(1,-160,0,22),TextSize=11,TextColor3=palette.muted,TextXAlignment=Enum.TextXAlignment.Left})
    bindButton(quick,"friendPick",UDim2.new(1,-144,0,18),UDim2.fromOffset(130,28))
    local searchBox=text(friendForm,"",{Name="FriendSearch",Position=UDim2.fromOffset(8,155),Size=UDim2.new(1,-165,0,30),BackgroundColor3=palette.control,BackgroundTransparency=.4,PlaceholderText="Search squad…",ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left},"TextBox")
    rounded(searchBox,9); create("UIPadding",searchBox,{PaddingLeft=UDim.new(0,11)})
    local countLabel=text(friendForm,"",{Position=UDim2.new(1,-150,0,155),Size=UDim2.fromOffset(142,30),TextSize=11,TextColor3=palette.muted,TextXAlignment=Enum.TextXAlignment.Right})
    local list=create("ScrollingFrame",friendForm,{Name="SquadCards",Position=UDim2.fromOffset(8,198),Size=UDim2.new(1,-16,0,186),BackgroundTransparency=1,BorderSizePixel=0,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.fromOffset(0,0),ScrollBarThickness=3})
    local cards={}
    local function roster()
        local players={}
        for _,other in ipairs(Players:GetPlayers()) do players[string.lower(other.Name)]=other end
        return players
    end
    local function updatePresence()
        local players=roster()
        local saved,here=0,0
        for name in pairs(friendNames) do saved+=1; if players[name] then here+=1 end end
        countLabel.Text=string.format("%d saved • %d here",saved,here)
        for name,entry in pairs(cards) do
            local other=players[name]
            entry.presence.Text=other and "ON SERVER" or "SAVED TEAMMATE"
            entry.presence.TextColor3=other and Color3.fromRGB(125,231,183) or palette.muted
            entry.dot.BackgroundColor3=other and Color3.fromRGB(125,231,183) or Color3.fromRGB(92,107,119)
        end
    end
    refreshFriendList=function()
        list:ClearAllChildren(); table.clear(cards)
        create("UIListLayout",list,{Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder})
        local names={}; local query=string.lower(searchBox.Text)
        for name in pairs(friendNames) do if query=="" or name:find(query,1,true) then table.insert(names,name) end end
        table.sort(names)
        for i,name in ipairs(names) do
            if i>200 then break end
            local card=create("Frame",list,{Name="SquadCard",Size=UDim2.new(1,-8,0,56),BackgroundColor3=palette.panel,BackgroundTransparency=.16,BorderSizePixel=0,LayoutOrder=i})
            rounded(card,13); stroke(card,palette.accent).Transparency=.85
            local initials=text(card,string.upper(name:sub(1,2)),{Position=UDim2.fromOffset(10,10),Size=UDim2.fromOffset(36,36),BackgroundColor3=palette.control,BackgroundTransparency=.1,TextColor3=palette.accent,TextSize=13})
            rounded(initials,12)
            text(card,"@"..name,{Position=UDim2.fromOffset(60,7),Size=UDim2.new(1,-170,0,22),TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd})
            local presence=text(card,"",{Position=UDim2.fromOffset(72,31),Size=UDim2.new(1,-180,0,17),TextSize=9,TextXAlignment=Enum.TextXAlignment.Left})
            local dot=create("Frame",card,{Position=UDim2.fromOffset(61,36),Size=UDim2.fromOffset(5,5),BorderSizePixel=0}); rounded(dot,5)
            local remove=button(card,"Remove",UDim2.new(1,-94,0,14),UDim2.fromOffset(82,28)); remove.TextSize=11
            remove.Activated:Connect(function() api.remove(name) end)
            cards[name]={presence=presence,dot=dot}
        end
        if #names==0 then
            text(list,query=="" and "Пока никого нет • добавь username или используй Quick Add" or "Совпадений нет",{Size=UDim2.new(1,-10,0,72),TextColor3=palette.muted,TextWrapped=true,TextSize=13})
        end
        updatePresence()
    end
    api.refresh=refreshFriendList
    connect(add.Activated,function() if api.add(input.Text) then input.Text="" end end)
    connect(input.FocusLost,function(enter) if enter and api.add(input.Text) then input.Text="" end end)
    connect(searchBox:GetPropertyChangedSignal("Text"),refreshFriendList)
    describe(input,"Username, не Display Name. Это локальные тиммейты OKTAN, без заявки в Roblox.")
    local elapsed=0
    api.uiStep=function(dt)
        elapsed+=dt
        if elapsed>=1 and menu.Visible and detail.Visible and friendForm.Parent==detailBody then elapsed=0; updatePresence() end
    end
end

local function gconnect(event, callback)
    table.insert(graphConnections, event:Connect(callback))
end
local function wire(a, b)
    local reach = (b.X - a.X) * 0.5
    local path = create("Path2D", controlRows.graphCanvas, {
        Name = "BranchCurve", Color3 = Color3.fromRGB(104, 116, 136),
        Thickness = 1.5, ZIndex = 1, Visible = true,
    })
    path:SetControlPoints({
        Path2DControlPoint.new(UDim2.fromOffset(a.X, a.Y), UDim2.fromOffset(0, 0), UDim2.fromOffset(reach, 0)),
        Path2DControlPoint.new(UDim2.fromOffset(b.X, b.Y), UDim2.fromOffset(-reach, 0), UDim2.fromOffset(0, 0)),
    })
end
local function node(label, x, y, width, selected, callback)
    local object = button(controlRows.graphCanvas, label, UDim2.fromOffset(x, y), UDim2.fromOffset(width, 34))
    object.BackgroundTransparency = selected and 0.08 or 0.18
    object.TextColor3 = selected and palette.accent or palette.text
    object.TextSize = 13
    object.ZIndex = 3
    object.AutoButtonColor = false
    object:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, 10)
    create("UIGradient", object, {
        Rotation = 90,
        Color = ColorSequence.new(Color3.fromRGB(230, 241, 252), Color3.fromRGB(100, 125, 146)),
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
    if selected and settings.motion and not settings.lowFx then
        local gradient = object:FindFirstChildOfClass("UIGradient")
        gradient.Offset = Vector2.new(-0.25, 0)
        local shimmer = TweenService:Create(gradient, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Offset = Vector2.new(0.25, 0) })
        table.insert(graphTweens, shimmer)
        table.insert(shimmerTweens,shimmer)
        if menu.Visible then shimmer:Play() end
    end
    controlRows.studio.bindNode(object,selected)
    local restTransparency = object.BackgroundTransparency
    object.Position = UDim2.fromOffset(x + 12, y)
    object.BackgroundTransparency, object.TextTransparency = 1, 1
    animate(object, { Position = UDim2.fromOffset(x, y), BackgroundTransparency = restTransparency,
        TextTransparency = 0 }, 0.24, math.min(0.16, x / 6000 + y / 6000))
    local hoverTween
    gconnect(object.MouseEnter, function()
        if hoverTween then hoverTween:Cancel() end
        hoverTween = TweenService:Create(object, TweenInfo.new(0.14), {
            BackgroundColor3 = palette.control:Lerp(palette.accent,.15), TextColor3 = Color3.fromRGB(255, 255, 255),
        })
        hoverTween:Play()
    end)
    gconnect(object.MouseLeave, function()
        if hoverTween then hoverTween:Cancel() end
        hoverTween = TweenService:Create(object, TweenInfo.new(0.2), {
            BackgroundColor3 = selected and palette.control:Lerp(palette.accent,.12) or palette.control, TextColor3 = selected and palette.accent or palette.text,
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
    table.clear(graphBindingLabels)
    controlRows.studio.clearNodes()
    graph:ClearAllChildren()
    tooltip.Visible=false; hovered=nil
    controlRows.graphCanvas=create("Frame",graph,{Name="TreeCanvas",BackgroundTransparency=1,Size=UDim2.fromOffset(870,470),BorderSizePixel=0})
    for _, page in pairs(pages) do page.Visible = false end
    searchResults.Visible = false
    for _, tabButton in pairs(tabButtons) do tabButton.Visible = false end
    graph.Visible = true
    local query = normalizeQuery(search.Text)
    local categories = { "Наведение", "ESP", "Мир", "Камера", "Настройки", "Friends", "Бинды" }
    node("OKTAN", 12, 212, 105, true, function() selectedCategory = "Наведение"; selectedGroup = "Наведение"; renderGraph() end)
    for index, category in ipairs(categories) do
        local y = 18 + (index - 1) * 52
        wire(Vector2.new(117, 229), Vector2.new(174, y + 17))
        node(displayNames[category] or category, 174, y, 130, category == selectedCategory, function()
            graph.CanvasPosition = Vector2.new(0, 0)
            selectedCategory = category
            if category == "Бинды" then
                openDetail("Keybinds")
                local order = 0
                local function heading(label)
                    order += 1
                    local labelObject = text(detailBody, label, { Size = UDim2.new(1, -20, 0, 30), LayoutOrder = order, TextSize = 14, TextColor3 = palette.accent, TextXAlignment = Enum.TextXAlignment.Left })
                    table.insert(temporaryRows, labelObject)
                end
                heading("CONTROLS  /  нажми клавишу справа для изменения")
                for _, object in ipairs(roleRows) do order += 1; moveDetail(object, order) end
                for _, categoryName in ipairs({ "Наведение", "ESP", "Мир", "Камера", "Бинды", "Настройки" }) do
                    heading(string.upper(displayNames[categoryName] or categoryName))
                    for _, entry in ipairs(bindingRows) do
                        local key = entry.action:gsub("Minus$", ""):gsub("Plus$", "")
                        if schema[key] and schema[key][5] == categoryName then order += 1; moveDetail(entry.frame, order) end
                    end
                end
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
    local categoryY = 35
    for index, category in ipairs(categories) do
        if category == selectedCategory then categoryY = 35 + (index - 1) * 52 end
    end
    local groups = treeGroups[selectedCategory] or {}
    if selectedCategory == "Настройки" then groups = { "Оформление", "Инвентарь", "Dynamic Island", "Клиент", "Music", "Performance" } end
    local selectedY = 90
    for index, group in ipairs(groups) do
        local y = 35 + (index - 1) * 88
        wire(Vector2.new(304, categoryY), Vector2.new(350, y + 17))
        node(displayNames[group] or group, 350, y, 170, group == selectedGroup, function()
            graph.CanvasPosition = Vector2.new(0, 0)
            selectedGroup = group
            renderGraph()
        end)
        if group == selectedGroup then selectedY = y + 17 end
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
        text(controlRows.graphCanvas, "Ничего не найдено", { Position = UDim2.fromOffset(588, 24), Size = UDim2.fromOffset(258, 40), TextColor3 = palette.muted })
    end
    for index, entry in ipairs(leaves) do
        local definition = schema[entry.key]
        local y = 14 + (index - 1) * 40
        wire(Vector2.new(520, selectedY), Vector2.new(588, y + 17))
        local assigned = bindings[entry.key]
        local label = (entry.key:match("Hue$") and (entry.key == "menuHue" and "Menu Color" or entry.key == "espHue" and "ESP Color" or "FOV Color") or definition[3])
        if query ~= "" then label = (displayNames[entry.page] or entry.page) .. " / " .. label end
        local control = node(label .. bindingSuffix(entry.key), 588, y, 258, settings[entry.key] == true, function()
            openDetail(definition[3])
            activeDetailEntry = { label = definition[3], key = entry.key }
            detailTitle.Text = definition[3] .. bindingSuffix(entry.key)
            if entry.key == "yandexPlay" then
                moveDetail(controlRows.yandex.form, 1)
            elseif entry.key == "spotifyPlay" then
                moveDetail(controlRows.spotify.form, 1)
            elseif entry.key == "musicPlay" then
                moveDetail(controlRows.music.form, 1)
            elseif entry.key:match("Hue$") then
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
            elseif entry.key == "gfxTier" or entry.key == "gfxLook" or entry.key == "espStyle" then
                local names = entry.key == "espStyle" and { "Classic", "Glass", "Minimal" } or entry.key == "gfxTier" and { "Low", "Balanced", "Ultra" } or { "Arctic", "Golden", "Neon", "Cinema", "Clean" }
                local panel = create("Frame", detailBody, { Size = UDim2.new(1, -20, 0, 95), BackgroundTransparency = 1, LayoutOrder = 1 })
                table.insert(temporaryRows, panel)
                local buttons = {}
                for index, name in ipairs(names) do
                    local option = button(panel, name, UDim2.fromOffset(10 + (index - 1) * 132, 24), UDim2.fromOffset(120, 42))
                    buttons[index] = option
                    option.TextColor3 = index == settings[entry.key] and palette.accent or palette.muted
                    option.Activated:Connect(function()
                        setValue(entry.key, index)
                        for i, item in ipairs(buttons) do item.TextColor3 = i == index and palette.accent or palette.muted end
                    end)
                end
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
        graphBindingLabels[control] = { label = label, key = entry.key }
        middleBind(control, entry.key, gconnect)
        gconnect(control.MouseEnter, function() tooltip.Text = definition[4] .. "\nСКМ — назначить клавишу"; tooltip.Visible = menu.Visible end)
        gconnect(control.MouseLeave, function() tooltip.Visible = false end)
    end
    if selectedCategory == "Настройки" and selectedGroup == "Клиент" then
        node("Client / Quick Start", 588, 14 + #leaves * 40, 258, false, function()
            openDetail("Client")
            moveDetail(actionsRow, 1)
            moveDetail(controlRows.release.form,2)
        end)
    end
    graph.CanvasSize = UDim2.fromOffset(870, math.max(465, #leaves * 40 + 100, #groups * 88 + 40))
    controlRows.graphCanvas.Size=graph.CanvasSize
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
    menu.BackgroundColor3 = Color3.fromRGB(8, 13, 18)
    for _, object in ipairs(menu:GetDescendants()) do
        if object:IsA("UIStroke") and object.Name ~= "DecorationStroke" and object.Name ~= "StudioNodeRim" then object.Color = accent; object.Transparency = 0.8 end
        if object:IsA("ScrollingFrame") then object.ScrollBarImageColor3 = accent end
    end
    controlRows.studio.theme(accent)
    for _, fill in ipairs(sliderFills) do fill.BackgroundColor3 = accent end
    refreshAll()
end

do
local function initializeReleaseCenter()
    local api={elapsed=1}
    local form=create("Frame",pages["Настройки"],{Name="ReleaseCenter",Size=UDim2.new(1,-12,0,410),BackgroundTransparency=1,Visible=true})
    api.form=form
    text(form,"QUICK START",{Position=UDim2.fromOffset(12,6),Size=UDim2.new(1,-24,0,24),TextSize=12,TextColor3=palette.accent,TextXAlignment=Enum.TextXAlignment.Left})
    local storage=text(form,"",{Position=UDim2.fromOffset(12,34),Size=UDim2.new(1,-24,0,36),TextSize=12,TextWrapped=true,TextColor3=palette.muted,TextXAlignment=Enum.TextXAlignment.Left})
    text(form,"INTERFACE PROFILES",{Position=UDim2.fromOffset(12,80),Size=UDim2.new(1,-24,0,20),TextSize=10,TextColor3=palette.muted,TextXAlignment=Enum.TextXAlignment.Left})
    local hint=text(form,"",{Position=UDim2.fromOffset(12,148),Size=UDim2.new(1,-24,0,32),TextSize=11,TextWrapped=true,TextColor3=palette.muted,TextXAlignment=Enum.TextXAlignment.Left})
    local undo=button(form,"Undo Profile",UDim2.new(1,-152,0,78),UDim2.fromOffset(140,26)); undo.Visible=false
    local profiles={
        {name="Light",description="Меньше декора и обновлений. Подходит для слабых ПК.",values={lowFx=true,skinTextures=false,bubbles=false,snow=false,snowDrifts=false,friendHats=false,motion=false,espFps=20,adaptiveEsp=true}},
        {name="Balanced",description="Плавное меню и умеренная частота обновления ESP.",values={lowFx=false,skinTextures=false,bubbles=true,snow=true,snowDrifts=false,friendHats=true,motion=true,espFps=30,adaptiveEsp=true}},
        {name="Studio",description="Полное оформление и 45 Hz ESP. Выше нагрузка на ПК.",values={lowFx=false,skinTextures=true,bubbles=true,snow=true,snowDrifts=true,friendHats=true,motion=true,espFps=45,adaptiveEsp=true}},
    }
    api.apply=function(index)
        local preset=profiles[index]; if not preset then return false end
        api.previous={}
        for key,value in pairs(preset.values) do api.previous[key]=settings[key]; settings[key]=value end
        api.resetUntil=nil; resetButton.Text="Reset"
        changed(); refreshAll()
        hint.Text=preset.name.." · "..preset.description
        undo.Visible=true
        return true
    end
    api.undo=function()
        if not api.previous then return false end
        for key,value in pairs(api.previous) do settings[key]=value end
        api.previous=nil; undo.Visible=false
        changed(); refreshAll(); hint.Text="Предыдущие настройки оформления восстановлены."
        return true
    end
    for index,preset in ipairs(profiles) do
        local control=button(form,preset.name,UDim2.new((index-1)/3,12-(index-1)*4,0,108),UDim2.new(1/3,-16,0,34))
        describe(control,preset.description.." Наведение, бинды, друзья и параметры оружия не меняются.")
        connect(control.Activated,function() api.apply(index) end)
    end
    connect(undo.Activated,api.undo)
    local guides={}
    for index,label in ipairs({"Menu & Search","Bind any function","Inspect & Teammates","Music"}) do
        local tile=create("Frame",form,{Position=UDim2.fromOffset(12,190+(index-1)*51),Size=UDim2.new(1,-24,0,45),BackgroundColor3=palette.panel,BackgroundTransparency=.18,BorderSizePixel=0})
        rounded(tile,11); stroke(tile,palette.accent).Transparency=.87
        text(tile,label,{Position=UDim2.fromOffset(12,5),Size=UDim2.new(1,-24,0,15),TextSize=11,TextColor3=palette.accent,TextXAlignment=Enum.TextXAlignment.Left})
        guides[index]=text(tile,"",{Position=UDim2.fromOffset(12,22),Size=UDim2.new(1,-24,0,18),TextSize=10,TextColor3=palette.muted,TextXAlignment=Enum.TextXAlignment.Left})
    end
    api.confirmReset=function()
        local now=os.clock()
        if not api.resetUntil or now>api.resetUntil then
            api.resetUntil=now+5; resetButton.Text="Confirm Reset"
            configStatus="Сбросить настройки и бинды? Нажми Confirm Reset в течение 5 секунд."
            return false
        end
        api.resetUntil=nil; api.previous=nil; undo.Visible=false; resetButton.Text="Reset"
        return true
    end
    api.step=function(dt)
        if api.resetUntil and os.clock()>api.resetUntil then api.resetUntil=nil; resetButton.Text="Reset" end
        api.elapsed+=dt; if api.elapsed<.5 then return end; api.elapsed=0
        local parent=form
        while parent and parent~=gui do if parent.Visible==false then return end; parent=parent.Parent end
        if not menu.Visible then return end
        storage.Text=(canSave and "Autosave · общий конфиг метро и рейда" or "Session only · исполнитель не поддерживает сохранение").."\n"..configStatus
        guides[1].Text="Меню: "..(bindings.menu or "кнопка OKTAN").." · поиск: Ctrl+F · настройки сохраняются автоматически."
        guides[2].Text="Нажми и отпусти СКМ на функции → новая клавиша. Esc — отмена, Backspace — убрать."
        guides[3].Text="Inspect: "..(bindings.inspect or "не назначен").." · Quick Add: "..(bindings.friendPick or "назначь Pick Friend").." · наведи курсор на цель."
        guides[4].Text="Яндекс Музыка управляется локальным модулем на твоём ПК. Подключение — Settings → Music."
    end
    connect(Input.InputBegan,function(input)
        if menu.Visible and not bindDialog.Visible and not capture and not pendingNumeric and not Input:GetFocusedTextBox()
            and input.KeyCode==Enum.KeyCode.F and (Input:IsKeyDown(Enum.KeyCode.LeftControl) or Input:IsKeyDown(Enum.KeyCode.RightControl)) then
            search:CaptureFocus()
        end
    end)
    return api
end
controlRows.release=initializeReleaseCenter()
end

do
local function initializeProfiles()
    local api={items={},revision=0,serial=0,status="Готово",disk=canSave}
    local excluded={musicPlay=true,spotifyPlay=true,yandexPlay=true,echoFreeze=true,perfDebug=true}
    local function nameOf(value)
        if type(value)~="string" then return nil end
        value=value:match("^%s*(.-)%s*$")
        local ok,length=pcall(utf8.len,value)
        if not ok or not length or length<1 or length>48 or #value>96 or value:find("%c") then return nil end
        return value
    end
    local function validate(data)
        if type(data)~="table" or data.format~="OktanProfile" or data.version~=1 or not nameOf(data.name)
            or type(data.settings)~="table" or type(data.bindings)~="table" then return nil,"Нужен JSON-конфиг OktanProfile v1." end
        local result={format="OktanProfile",version=1,name=nameOf(data.name),settings={},bindings={}}
        local count=0
        for key,value in pairs(data.settings) do
            count+=1; if count>400 then return nil,"Слишком много параметров." end
            local entry=schema[key]
            if entry and not excluded[key] then
                if type(value)~=type(entry[2]) then return nil,"Неверный тип параметра: "..key end
                if type(value)=="number" then
                    if value~=value or math.abs(value)==math.huge or value<entry[6] or value>entry[7] then return nil,"Значение вне диапазона: "..key end
                    value=math.round(value)
                end
                result.settings[key]=value
            end
        end
        local used={}; count=0
        for action,key in pairs(data.bindings) do
            count+=1; if count>600 then return nil,"Слишком много биндов." end
            if allowedActions[action] then
                if type(key)~="string" or not allowedKeys[key] or used[key] then return nil,"Некорректные или повторяющиеся бинды." end
                result.bindings[action]=key; used[key]=true
            end
        end
        return result
    end
    api.validate=validate
    local function current(name)
        local payload={format="OktanProfile",version=1,name=name,settings={},bindings=table.clone(bindings)}
        for key in pairs(schema) do if not excluded[key] then payload.settings[key]=settings[key] end end
        return payload
    end
    local function find(id) for index,item in ipairs(api.items) do if item.id==id then return item,index end end end
    api.find=find
    local function persist()
        if not canSave then api.status="Сохранено в памяти: файловые функции недоступны."; return false end
        local nextRevision=api.revision+1
        local ok=pcall(function()
            writefile("Oktan-profiles-"..(nextRevision%2==0 and "a" or "b")..".json",HttpService:JSONEncode({format="OktanProfileLibrary",version=1,revision=nextRevision,profiles=api.items}))
        end)
        if ok then api.revision=nextRevision; api.status="Библиотека сохранена в workspace."
        else api.status="Профили в памяти; запись на диск не удалась." end
        return ok
    end
    if canSave then
        for _,slot in ipairs({"a","b"}) do
            local ok,data=pcall(function()
                local raw=readfile("Oktan-profiles-"..slot..".json")
                if type(raw)~="string" or #raw>1048576 then return nil end
                local library=HttpService:JSONDecode(raw)
                if type(library)~="table" or library.format~="OktanProfileLibrary" or library.version~=1 or type(library.revision)~="number" or library.revision~=library.revision or library.revision<0 or library.revision>1e9 or library.revision%1~=0
                    or type(library.profiles)~="table" or #library.profiles>30 then return nil end
                local ids,items={},{}
                for key in pairs(library.profiles) do if type(key)~="number" or key%1~=0 or key<1 or key>#library.profiles then return nil end end
                for _,entry in ipairs(library.profiles) do
                    local profile=validate(entry)
                    if not profile or type(entry.id)~="string" or #entry.id>80 or not entry.id:match("^[%w%-]+$") or ids[entry.id] then return nil end
                    profile.id=entry.id; ids[entry.id]=true; table.insert(items,profile)
                end
                return {revision=library.revision,items=items}
            end)
            if ok and data and data.revision>=api.revision then api.items,api.revision=data.items,data.revision end
        end
    end
    local function unique(name)
        for _,profile in ipairs(api.items) do if string.lower(profile.name)==string.lower(name) then return profile end end
    end
    local function add(profile)
        if #api.items>=30 then return false,"Лимит: 30 конфигов." end
        api.serial+=1
        profile.id=HttpService:GenerateGUID(false):gsub("[^%w]","").."-"..api.serial
        table.insert(api.items,profile); persist()
        return true,profile.id
    end
    api.save=function(name,overwrite)
        name=nameOf(name); if not name then return false,"Название: 1–48 символов, без переноса строк." end
        local existing=unique(name)
        if existing and not overwrite then return false,"CONFIRM",existing.id end
        local profile=current(name)
        if existing then profile.id=existing.id; local _,index=find(existing.id); api.items[index]=profile; persist(); return true,profile.id end
        return add(profile)
    end
    api.export=function(id)
        local profile=find(id); if not profile then return nil,"Выбери конфиг." end
        local copy={format="OktanProfile",version=1,name=profile.name,settings=profile.settings,bindings=profile.bindings}
        return HttpService:JSONEncode(copy)
    end
    api.import=function(raw)
        if type(raw)~="string" or #raw==0 or #raw>65536 then return false,"Вставь JSON-конфиг размером до 64 КБ." end
        local ok,data=pcall(function() return HttpService:JSONDecode(raw) end)
        if not ok then return false,"Это не JSON-конфиг. Lua-код и ссылки не импортируются." end
        local profile,message=validate(data); if not profile then return false,message end
        if unique(profile.name) then
            local base=utf8.len(profile.name)<=40 and profile.name or "Imported"
            for index=2,32 do if not unique(base.." ("..index..")") then profile.name=base.." ("..index..")"; break end end
        end
        return add(profile)
    end
    api.apply=function(id,includeBindings)
        local profile=find(id); if not profile then return false,"Выбери конфиг." end
        api.previous=current("Undo"); api.previous.bindings=table.clone(bindings)
        for key,value in pairs(profile.settings) do settings[key]=value end
        if includeBindings then bindings=table.clone(profile.bindings) end
        capture=nil; pendingNumeric=nil; changed(); applyTheme(); refreshAll()
        return true,"Загружен: "..profile.name..(includeBindings and " · с биндами" or " · твои бинды сохранены")
    end
    api.undo=function()
        if not api.previous then return false,"Пока нечего отменять." end
        for key,value in pairs(api.previous.settings) do settings[key]=value end
        bindings=table.clone(api.previous.bindings); api.previous=nil
        changed(); applyTheme(); refreshAll(); return true,"Предыдущие настройки восстановлены."
    end
    api.remove=function(id)
        local _,index=find(id); if not index then return false,"Выбери конфиг." end
        table.remove(api.items,index); persist(); return true,"Конфиг удалён из библиотеки."
    end
    return api
end
controlRows.profiles=initializeProfiles()
end

do
local function initializeProfilesUI()
    local api=controlRows.profiles
    local selected,withBinds,confirm,notice=nil,false,nil,""
    local shield=create("TextButton",gui,{Name="ConfigShield",Text="",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=.45,AutoButtonColor=false,Visible=false,Active=true,Modal=true,ZIndex=33})
    local window=create("CanvasGroup",gui,{Name="ConfigLibrary",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(840,550),BackgroundColor3=palette.background,BackgroundTransparency=.02,BorderSizePixel=0,Visible=false,ZIndex=34})
    rounded(window,22); local rim=stroke(window,palette.accent); rim.Transparency=.5
    local fit=create("UIScale",window,{Scale=1})
    text(window,"CONFIG LIBRARY",{Position=UDim2.fromOffset(22,15),Size=UDim2.fromOffset(550,27),TextSize=17,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left})
    text(window,"Твои настройки · готовые конфиги · обмен с другом",{Position=UDim2.fromOffset(22,43),Size=UDim2.fromOffset(690,18),TextSize=11,TextColor3=palette.muted,TextXAlignment=Enum.TextXAlignment.Left})
    local close=button(window,"Close",UDim2.new(1,-102,0,20),UDim2.fromOffset(80,30))
    local input=text(window,"",{Name="ProfileName",Position=UDim2.fromOffset(22,78),Size=UDim2.fromOffset(540,36),BackgroundColor3=palette.control,BackgroundTransparency=.2,PlaceholderText="Название конфига…",ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left},"TextBox")
    rounded(input,10); create("UIPadding",input,{PaddingLeft=UDim.new(0,12)})
    local save=button(window,"Save Current",UDim2.fromOffset(574,78),UDim2.fromOffset(244,36))
    local list=create("ScrollingFrame",window,{Name="SavedProfiles",Position=UDim2.fromOffset(22,130),Size=UDim2.fromOffset(232,336),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.fromOffset(0,0)})
    local panel=create("Frame",window,{Position=UDim2.fromOffset(270,130),Size=UDim2.fromOffset(548,336),BackgroundColor3=palette.panel,BackgroundTransparency=.12,BorderSizePixel=0}); rounded(panel,14)
    local summary=text(panel,"Выбери сохранённый конфиг или импортируй готовый.",{Position=UDim2.fromOffset(14,10),Size=UDim2.fromOffset(520,38),TextSize=12,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left})
    local load=button(panel,"Load",UDim2.fromOffset(14,53),UDim2.fromOffset(120,30))
    local copy=button(panel,"Copy JSON",UDim2.fromOffset(144,53),UDim2.fromOffset(120,30))
    local export=button(panel,"Save File",UDim2.fromOffset(274,53),UDim2.fromOffset(120,30))
    local remove=button(panel,"Delete",UDim2.fromOffset(404,53),UDim2.fromOffset(130,30))
    local binds=button(panel,"Load binds: OFF",UDim2.fromOffset(14,94),UDim2.fromOffset(250,27))
    local undo=button(panel,"Undo Load",UDim2.fromOffset(274,94),UDim2.fromOffset(260,27))
    local raw=text(panel,"",{Name="ProfileJSON",Position=UDim2.fromOffset(14,134),Size=UDim2.fromOffset(520,145),BackgroundColor3=palette.background,BackgroundTransparency=.15,TextSize=11,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,MultiLine=true,ClearTextOnFocus=false,PlaceholderText="Вставь JSON-конфиг друга или продавца, затем нажми Import. Импорт добавляет профиль, Load применяет его."},"TextBox")
    rounded(raw,9); create("UIPadding",raw,{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10),PaddingTop=UDim.new(0,8)})
    local import=button(panel,"Import JSON",UDim2.fromOffset(14,291),UDim2.fromOffset(250,30))
    local importFile=button(panel,"Import File",UDim2.fromOffset(274,291),UDim2.fromOffset(260,30))
    local status=text(window,"",{Position=UDim2.fromOffset(22,477),Size=UDim2.fromOffset(796,48),TextSize=11,TextWrapped=true,TextColor3=palette.muted,TextXAlignment=Enum.TextXAlignment.Left})
    local launcher=button(menu,"Configs",UDim2.new(1,-132,1,-34),UDim2.fromOffset(110,25))
    local function refresh()
        list:ClearAllChildren(); create("UIListLayout",list,{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder})
        local items=table.clone(api.items); table.sort(items,function(a,b) return a.name:lower()<b.name:lower() end)
        for index,profile in ipairs(items) do
            local item=button(list,profile.name,UDim2.fromOffset(0,0),UDim2.new(1,-8,0,42)); item.LayoutOrder=index
            item.TextSize=12; item.TextColor3=selected==profile.id and palette.accent or palette.text
            item.Activated:Connect(function() selected=profile.id; input.Text=profile.name; confirm=nil; notice=""; refresh() end)
        end
        if #items==0 then text(list,"Пока нет конфигов.\nСохрани текущие настройки под своим именем.",{Size=UDim2.new(1,-8,0,96),TextWrapped=true,TextSize=12,TextColor3=palette.muted}) end
        local profile=api.find(selected)
        if profile then
            local settingsCount,bindCount=0,0
            for _ in pairs(profile.settings) do settingsCount+=1 end
            for _ in pairs(profile.bindings) do bindCount+=1 end
            summary.Text=profile.name.."\n"..settingsCount.." настроек · "..bindCount.." биндов"
        else summary.Text="Выбери сохранённый конфиг или импортируй готовый." end
        save.Text=confirm and confirm.kind=="save" and "Confirm Save" or "Save Current"
        remove.Text=confirm and confirm.kind=="delete" and "Confirm Delete" or "Delete"
        binds.Text="Load binds: "..(withBinds and "ON" or "OFF")
        status.Text=(notice~="" and notice or api.status).."\nЭкспорт: настройки и бинды. Ключ, подписка, друзья и музыкальные подключения не передаются."
    end
    local function result(ok,message)
        notice=message or (ok and "Готово" or "Ошибка"); refresh()
    end
    api.open=function()
        selected=api.find(selected) and selected or nil; confirm=nil
        window.Visible=true; shield.Visible=true; refresh()
        if settings.motion and not settings.lowFx then window.GroupTransparency=1; TweenService:Create(window,TweenInfo.new(.22),{GroupTransparency=0}):Play() else window.GroupTransparency=0 end
    end
    api.close=function() window.Visible=false; shield.Visible=false; confirm=nil end
    connect(close.Activated,api.close); connect(launcher.Activated,api.open)
    connect(save.Activated,function()
        local overwrite=confirm and confirm.kind=="save" and confirm.name==input.Text and os.clock()<confirm.untilTime
        local ok,message,id=api.save(input.Text,overwrite)
        if ok then selected=message; confirm=nil; result(true,api.status)
        elseif message=="CONFIRM" then confirm={kind="save",name=input.Text,untilTime=os.clock()+5}; result(false,"Имя уже занято. Повтори Save в течение 5 секунд для обновления.")
        else result(false,message) end
    end)
    connect(load.Activated,function() result(api.apply(selected,withBinds)) end)
    connect(undo.Activated,function() result(api.undo()) end)
    connect(binds.Activated,function() withBinds=not withBinds; refresh() end)
    connect(copy.Activated,function()
        local code,message=api.export(selected)
        if not code then result(false,message); return end
        raw.Text=code
        local ok=type(setclipboard)=="function" and pcall(setclipboard,code)
        result(true,ok and "JSON скопирован — отправь другу." or "JSON в поле справа: выдели и скопируй его.")
    end)
    connect(export.Activated,function()
        local code,message=api.export(selected)
        if not code then result(false,message); return end
        local path="Oktan-profile-"..selected..".json"
        local ok=type(writefile)=="function" and pcall(writefile,path,code)
        result(ok,ok and "Файл в workspace: "..path or "Не удалось записать файл.")
    end)
    local function importCode(code)
        local ok,message=api.import(code)
        if ok then selected=message; raw.Text=""; result(true,"Конфиг добавлен. Проверь выбор биндов и нажми Load.") else result(false,message) end
    end
    connect(import.Activated,function() importCode(raw.Text) end)
    connect(importFile.Activated,function()
        local ok,code=pcall(function() return readfile("Oktan-profile-import.json") end)
        if ok then importCode(code) else result(false,"Помести файл в workspace под именем Oktan-profile-import.json.") end
    end)
    connect(remove.Activated,function()
        if not api.find(selected) then result(false,"Выбери конфиг."); return end
        if confirm and confirm.kind=="delete" and confirm.id==selected and os.clock()<confirm.untilTime then
            local ok,message=api.remove(selected); selected=nil; confirm=nil; result(ok,message)
        else confirm={kind="delete",id=selected,untilTime=os.clock()+5}; result(false,"Повтори Delete в течение 5 секунд, чтобы удалить профиль.") end
    end)
    describe(launcher,"Открыть библиотеку конфигов: сохранить, загрузить, импортировать или поделиться JSON.")
    api.uiStep=function()
        if not menu.Visible then api.close() end
        if confirm and os.clock()>confirm.untilTime then confirm=nil; if window.Visible then refresh() end end
        if window.Visible then fit.Scale=scale.Scale; window.BackgroundColor3=palette.background; rim.Color=palette.accent end
    end
    api.window=window; api.refresh=refresh
    table.insert(cleanups,function() shield:Destroy(); window:Destroy(); api.previous=nil end)
end
initializeProfilesUI()
end

do
local function initializeInspectorMotion()
    local api={tweens={}}
    local body=create("CanvasGroup",inspector,{Name="InspectorMotion",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(1,1),BackgroundTransparency=1,GroupTransparency=0})
    local zoom=create("UIScale",body,{Scale=1})
    for _,child in ipairs(inspector:GetChildren()) do if child~=body and child:IsA("GuiObject") then child.Parent=body end end
    local shown=inspector.Visible
    local function enabled() return settings.motion and not settings.lowFx end
    local function cancel()
        for _,tween in ipairs(api.tweens) do tween:Cancel() end; table.clear(api.tweens)
    end
    local function tween(object,properties,duration)
        local value=TweenService:Create(object,TweenInfo.new(duration,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),properties)
        table.insert(api.tweens,value); value:Play()
    end
    local function reset()
        body.GroupTransparency=0; zoom.Scale=1; inspector.BackgroundTransparency=.035
        cardArea.GroupTransparency=0; cardArea.Position=UDim2.fromOffset(244,104)
    end
    api.reveal=function()
        cancel(); api.closing=nil; api.pending=nil; reset(); shown=true
        if enabled() then
            body.GroupTransparency=1; zoom.Scale=.97; inspector.BackgroundTransparency=.35
            tween(body,{GroupTransparency=0},.24); tween(zoom,{Scale=1},.28); tween(inspector,{BackgroundTransparency=.035},.24)
        end
    end
    local function finishClose()
        cancel(); api.closing=nil; api.pending=nil
        inspector.Visible=false; inspectTarget=nil; shown=false; reset()
    end
    api.close=function()
        if api.closing then return end
        if not enabled() then finishClose(); return end
        cancel(); api.pending=nil; api.closing=0
        tween(body,{GroupTransparency=1},.16); tween(zoom,{Scale=.98},.18); tween(inspector,{BackgroundTransparency=.8},.18)
    end
    local function commit(target)
        selectedInventoryTab,inventoryPage,inventorySignature=target.tab,target.page,nil
        updateInventoryCards()
        if enabled() then
            cardArea.GroupTransparency=1; cardArea.Position=UDim2.fromOffset(244,110)
            tween(cardArea,{GroupTransparency=0,Position=UDim2.fromOffset(244,104)},.22)
        else cardArea.GroupTransparency=0; cardArea.Position=UDim2.fromOffset(244,104) end
    end
    local function switch(tab,page)
        if api.closing then return end
        cancel(); api.pending=nil
        body.GroupTransparency=0; zoom.Scale=1; inspector.BackgroundTransparency=.035
        local target={tab=tab,page=math.max(1,page),age=0}
        if not enabled() then commit(target); return end
        api.pending=target
        tween(cardArea,{GroupTransparency=1,Position=UDim2.fromOffset(244,100)},.1)
    end
    api.tab=function(name) switch(name,1) end
    api.page=function(delta)
        local target=api.pending
        switch(target and target.tab or selectedInventoryTab,(target and target.page or inventoryPage)+delta)
    end
    api.step=function(dt)
        if inspector.Visible and not shown then api.reveal() end
        if not inspector.Visible then
            if shown then cancel(); reset() end
            shown=false; api.pending=nil; api.closing=nil; return
        end
        if api.closing then
            api.closing+=dt
            if not enabled() or api.closing>=.18 then finishClose() end
        elseif api.pending then
            api.pending.age+=dt
            if not enabled() or api.pending.age>=.1 then local target=api.pending; api.pending=nil; cancel(); commit(target) end
        end
    end
    connect(inspector:GetPropertyChangedSignal("Visible"),function()
        if inspector.Visible then api.reveal() else cancel(); api.pending=nil; api.closing=nil; shown=false; reset() end
    end)
    table.insert(cleanups,cancel)
    return api
end
controlRows.inspectorMotion=initializeInspectorMotion()
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
        elseif object:IsA("ColorCorrectionEffect") and object.Name ~= "OktanGrade" then
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
local function placeLabel(label, value, x, y, size, anchorX, anchorY, camera, color, avoidOverlap, verticalPadding)
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
    local height = (size + 4) * (breaks + 1) + (verticalPadding or 0)
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
        local placed=false
        local function try(shift)
            local proposed=originalLeft+shift
            if proposed>=0 and proposed+width<=viewport.X and not overlaps(proposed) then left=proposed; return true end
            return false
        end
        placed=try(metrics.shift or 0) or try(0)
        if not placed then
            for lane=1,6 do
                local step=(width+8)*lane
                if try(step) or try(-step) then break end
            end
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
    return metrics.shift, rectangle, width, height
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
    if not (settings.boxes or settings.corners or settings.healthBar) then
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
local renderLabels
do
local function classicLabels(screen, candidate, low, high, camera, color)
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


local function ensureCard(screen)
    if screen.infoCard then return end
    screen.layoutLabel=screenLabel(screen.container)
    screen.infoCard=create("Frame",screen.container,{Name="EspIdentityCard",BackgroundColor3=Color3.fromRGB(10,17,23),BackgroundTransparency=.16,BorderSizePixel=0,ZIndex=2})
    rounded(screen.infoCard,8)
    screen.infoRim=stroke(screen.infoCard,Color3.fromRGB(175,193,202)); screen.infoRim.Transparency=.78
    for _,label in ipairs({screen.nameLabel,screen.healthLabel,screen.distanceLabel}) do label.Parent=screen.infoCard; label.ZIndex=3 end
    screen.hpTrack=create("Frame",screen.infoCard,{Position=UDim2.new(0,6,1,-3),Size=UDim2.new(1,-12,0,2),BackgroundColor3=Color3.fromRGB(42,57,65),BorderSizePixel=0,ZIndex=3})
    rounded(screen.hpTrack,2)
    screen.hpFill=create("Frame",screen.hpTrack,{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(140,225,180),BorderSizePixel=0,ZIndex=3}); rounded(screen.hpFill,2)
    screen.weaponChip=create("Frame",screen.container,{Name="EspWeaponChip",BackgroundColor3=Color3.fromRGB(10,17,23),BackgroundTransparency=.22,BorderSizePixel=0,ZIndex=2,Visible=false})
    rounded(screen.weaponChip,6); screen.weaponRim=stroke(screen.weaponChip,Color3.fromRGB(175,193,202)); screen.weaponRim.Transparency=.86
    screen.weaponLabel.ZIndex=3
    screen.anchorDot=create("Frame",screen.container,{Size=UDim2.fromOffset(3,3),BorderSizePixel=0,ZIndex=2,Visible=false}); rounded(screen.anchorDot,3)
end
renderLabels=function(screen,candidate,low,high,camera,color)
    if settings.espStyle==1 then
        if screen.infoCard then
            screen.infoCard.Visible,screen.weaponChip.Visible,screen.anchorDot.Visible=false,false,false
            for _,label in ipairs({screen.nameLabel,screen.healthLabel,screen.distanceLabel}) do label.Parent=screen.container; label.TextStrokeTransparency=.35; label.Font=Enum.Font.Gotham; label.TextXAlignment=Enum.TextXAlignment.Center end
        end
        classicLabels(screen,candidate,low,high,camera,color)
        return
    end
    ensureCard(screen)
    for _,label in ipairs({screen.nameLabel,screen.healthLabel,screen.distanceLabel}) do if label.Parent~=screen.infoCard then label.Parent=screen.infoCard end end
    local minimal=settings.espStyle==3
    local size=settings.textSize
    if settings.adaptiveText then size=math.clamp(math.floor(size*math.sqrt(math.max(1,high.Y-low.Y)/110)),10,settings.textSize) end
    local center=(low.X+high.X)*.5
    local now=os.clock()
    if not screen.metaAt or now-screen.metaAt>.12 then
        screen.metaAt=now
        screen.metaDistance=math.round((candidate.root.Position-camera.CFrame.Position).Magnitude)
    end
    local name=settings.names and ((candidate.owner and candidate.owner.Name or candidate.model.Name)..(isFriend(candidate.owner) and " · ALLY" or "")) or ""
    local hp=settings.health and string.format("%d HP",math.ceil(candidate.humanoid.Health)) or ""
    local distance=settings.distance and tostring(screen.metaDistance).." st" or ""
    local meta=hp..(hp~="" and distance~="" and "     " or "")..distance
    local value=name..(name~="" and meta~="" and "\n" or "")..meta
    local shift,rectangle,width,height=placeLabel(screen.layoutLabel,value,center,low.Y-8,size,.5,1,camera,palette.text,true,8)
    screen.layoutLabel.Visible=false
    screen.infoCard.Visible=rectangle~=nil
    screen.nameLabel.Visible=name~=""
    screen.healthLabel.Visible=hp~=""
    screen.distanceLabel.Visible=distance~=""
    if rectangle then
        screen.infoCard.Position=UDim2.fromOffset(math.round(rectangle.left),math.round(rectangle.top))
        screen.infoCard.Size=UDim2.fromOffset(width,height)
        screen.infoCard.BackgroundTransparency=minimal and 1 or .16
        screen.infoRim.Enabled=not minimal
        screen.infoRim.Color=isFriend(candidate.owner) and Color3.fromRGB(135,225,181) or color:Lerp(Color3.fromRGB(187,206,214),.8)
        screen.nameLabel.Position=UDim2.fromOffset(8,3)
        screen.nameLabel.Size=UDim2.new(1,-16,0,size+4)
        screen.nameLabel.Text,screen.nameLabel.TextSize=name,size
        screen.nameLabel.Font=Enum.Font.GothamBold
        screen.nameLabel.TextColor3=Color3.fromRGB(237,243,246)
        screen.nameLabel.TextXAlignment=Enum.TextXAlignment.Left
        local y=name~="" and size+7 or 4
        local two=hp~="" and distance~=""
        screen.healthLabel.Position=UDim2.fromOffset(8,y)
        screen.healthLabel.Size=two and UDim2.new(.5,-8,0,size+2) or UDim2.new(1,-16,0,size+2)
        screen.distanceLabel.Position=two and UDim2.new(.5,0,0,y) or UDim2.fromOffset(8,y)
        screen.distanceLabel.Size=two and UDim2.new(.5,-8,0,size+2) or UDim2.new(1,-16,0,size+2)
        screen.healthLabel.Text,screen.distanceLabel.Text=hp,distance
        screen.healthLabel.TextSize,screen.distanceLabel.TextSize=math.max(9,size-2),math.max(9,size-2)
        screen.healthLabel.TextXAlignment=Enum.TextXAlignment.Left
        screen.distanceLabel.TextXAlignment=two and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
        for _,label in ipairs({screen.nameLabel,screen.healthLabel,screen.distanceLabel}) do label.TextStrokeTransparency=1 end
        screen.distanceLabel.TextColor3=Color3.fromRGB(156,177,188)
        local fraction=math.clamp(candidate.humanoid.Health/math.max(1,candidate.humanoid.MaxHealth),0,1)
        local hpColor=Color3.fromHSV(fraction/3,.4,.9)
        screen.healthLabel.TextColor3=hpColor
        screen.hpTrack.Visible=settings.health and not settings.healthBar
        screen.hpFill.BackgroundColor3=hpColor
        if screen.shownHp~=fraction then
            if screen.healthTween then screen.healthTween:Cancel(); screen.healthTween=nil end
            if screen.shownHp and settings.motion and not settings.lowFx then
                screen.healthTween=TweenService:Create(screen.hpFill,TweenInfo.new(.18,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=UDim2.fromScale(fraction,1)})
                screen.healthTween:Play()
            else screen.hpFill.Size=UDim2.fromScale(fraction,1) end
            screen.shownHp=fraction
        end
    end
    local weapon=settings.weapon and heldItem(candidate.model)
    local _,weaponRect,weaponWidth,weaponHeight=placeLabel(screen.weaponLabel,weapon and weapon.Name or "",center+shift,high.Y+6,math.max(10,size-1),.5,0,camera,Color3.fromRGB(215,229,235),false,4)
    screen.weaponChip.Visible=weaponRect~=nil and not minimal
    screen.weaponLabel.TextStrokeTransparency=minimal and .35 or 1
    if weaponRect then screen.weaponChip.Position=UDim2.fromOffset(math.round(weaponRect.left),math.round(weaponRect.top)); screen.weaponChip.Size=UDim2.fromOffset(weaponWidth,weaponHeight) end
    if not screen.labelLeader then screen.labelLeader=create("Frame",screen.container,{BorderSizePixel=0,ZIndex=2}) end
    screen.labelLeader.Visible=rectangle~=nil and math.abs(shift)>2
    screen.labelLeader.BackgroundColor3=color
    screen.labelLeader.BackgroundTransparency=.65
    screen.labelLeader.Position=UDim2.fromOffset(math.round(math.min(center,center+shift)),math.round(low.Y-5))
    screen.labelLeader.Size=UDim2.fromOffset(math.round(math.abs(shift)),1)
    screen.anchorDot.Visible=screen.labelLeader.Visible
    screen.anchorDot.BackgroundColor3=color
    screen.anchorDot.Position=UDim2.fromOffset(math.round(center)-1,math.round(low.Y-6))
end

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
    segment.BackgroundTransparency = settings.espStyle == 1 and (1 - settings.espOpacity / 100) or math.max(.48, 1 - settings.espOpacity / 100)
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
    local enabled = settings.esp and not settings._mapOpen and not menu.Visible and camera and candidate and candidate.model:IsDescendantOf(workspace)
        and candidate.root:IsDescendantOf(workspace) and candidate.humanoid.Health > 0
        and (settings.through or not marker.occluded)
    enabled = enabled and (settings.names or settings.health or settings.distance or settings.weapon
        or settings.boxes or settings.corners or settings.healthBar or settings.skeleton or settings.tracers)
    screen.container.Visible = enabled == true
    if not enabled then return end
    local model = candidate.model
    if isFriend(candidate.owner) then color = Color3.fromRGB(85, 235, 150) end
    local projected = camera:WorldToViewportPoint(candidate.root.Position)
    local viewport = camera.ViewportSize
    if projected.Z <= 0.1 then screen.container.Visible = false; return end
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
            local function considerJoint(joint)
                if joint:IsA("Motor6D") and joint.Part0 and joint.Part1
                    and joint.Part0.Parent == model and joint.Part1.Parent == model then
                    table.insert(screen.joints, joint)
                end
            end
            -- R6/R15 body motors live on the rig or its direct body parts.
            -- Clothing/accessory descendants cannot produce a body-to-body motor.
            for _, child in ipairs(model:GetChildren()) do
                considerJoint(child)
                if child:IsA("BasePart") then for _, joint in ipairs(child:GetChildren()) do considerJoint(joint) end end
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
    if marker.screen.healthTween then marker.screen.healthTween:Cancel() end
    marker.screen.container:Destroy()
    marker.highlight:Destroy()
end

local function updateMarkers(camera)
    local seen = {}
    if settings.esp and camera then
        espRay.FilterDescendantsInstances = player.Character and { player.Character, camera } or { camera }
        local baseColor = Color3.fromHSV(settings.espHue / 360, settings.espSaturation / 100, settings.espValue / 100)
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
                    local hit = not settings.through and workspace:Raycast(
                        camera.CFrame.Position, candidate.root.Position - camera.CFrame.Position, espRay)
                    marker.occluded = hit and not hit.Instance:IsDescendantOf(model) or false
                    local color = baseColor
                    if isFriend(owner) then color = Color3.fromRGB(85, 235, 150) end
                    marker.highlight.FillColor = color
                    marker.highlight.OutlineColor = color
                    marker.highlight.FillTransparency = settings.espStyle == 1 and (1 - settings.fillOpacity / 100) or math.max(.94, 1 - settings.fillOpacity / 100)
                    marker.highlight.OutlineTransparency = settings.espStyle == 1 and (1 - settings.espOpacity / 100) or math.max(.38, 1 - settings.espOpacity / 100)
                    marker.highlight.Enabled = not settings._mapOpen and not menu.Visible and settings.chams
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

local aimContext = { ray = RaycastParams.new() }
aimContext.ray.FilterType = Enum.RaycastFilterType.Exclude
aimContext.ray.IgnoreWater = true
local function aimAt(camera, deltaTime)
    local character = player.Character
    aimContext.ray.FilterDescendantsInstances = character and { character, camera } or { camera }
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
                if settings.sticky and candidate.model == aimContext.locked then score *= 0.65 end
                if errorPixels <= settings.radius and score < bestError then
                    local hit = settings.wall and workspace:Raycast(origin, point - origin, aimContext.ray)
                    if not hit or hit.Instance:IsDescendantOf(candidate.model) then
                        bestError, bestPosition, bestModel = score, point, candidate.model
                    end
                end
            end
        end
    end
    if bestPosition then
        if aimContext.locked ~= bestModel or not aimContext.filter then aimContext.filter = { point = bestPosition, engagement = 0 } end
        aimContext.locked = bestModel
        local dt = math.min(math.max(deltaTime, 0), 0.05)
        aimContext.filter.engagement = math.min(1, aimContext.filter.engagement + dt / (settings.aimEase / 1000))
        aimContext.filter.point += (bestPosition - aimContext.filter.point) * (1 - math.exp(-settings.aimFilter * dt))
        local lag = bestPosition - aimContext.filter.point
        if lag.Magnitude > 0.45 then aimContext.filter.point = bestPosition - lag * (0.45 / lag.Magnitude) end
        local t = aimContext.filter.engagement
        local ease = t * t * (3 - 2 * t)
        local alpha = 1 - math.exp(-settings.smooth * ease * dt)
        if alpha > 0 then
            local goal = CFrame.lookAt(origin, aimContext.filter.point, camera.CFrame.UpVector)
            camera.CFrame = camera.CFrame:Lerp(goal, alpha)
        end
    else
        aimContext.locked, aimContext.filter = nil, nil
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
    local separators = {}
    for _, y in ipairs({ 77, 565 }) do
        local divider = create("Frame", menu, { Position = UDim2.fromOffset(28, y), Size = UDim2.fromOffset(864, 1), BackgroundColor3 = palette.accent, BackgroundTransparency = 0.9, BorderSizePixel = 0 })
        create("UIGradient", divider, { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.3), NumberSequenceKeypoint.new(0.8, 0.3), NumberSequenceKeypoint.new(1, 1) }) })
        table.insert(separators, divider)
    end
    local bubbles, flakes, drifts, hats = {}, {}, {}, {}
    local hatElapsed=0
    -- Procedural glass: soft halos, a Fresnel rim and a small specular reflection.
    -- Four fixed hosts; animation only changes transforms, never creates instances.
    local orbStyle = {
        { x = 0.11, y = 0.23, size = 154, phase = 0.3 },
        { x = 0.88, y = 0.38, size = 218, phase = 2.4 },
        { x = 0.71, y = 0.88, size = 126, phase = 4.7 },
        { x = 0.28, y = 0.89, size = 88, phase = 6.1 },
    }
    for index, style in ipairs(orbStyle) do
        local host = create("Frame", decoration, { Name = "GlassBubble", AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(style.size, style.size), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 0 })
        local halos = {}
        for layer = 5, 1, -1 do
            local halo = create("Frame", host, { Name = "SoftHalo", AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1 + layer * 0.055, 1 + layer * 0.055),
                BackgroundColor3 = palette.accent, BackgroundTransparency = 0.988 - (5-layer)*0.001,
                BorderSizePixel = 0, ZIndex = 0 })
            rounded(halo, 1000); table.insert(halos, halo)
        end
        local body = create("Frame", host, { Name = "GlassBody", Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = palette.accent, BackgroundTransparency = 0.84, BorderSizePixel = 0, ZIndex = 0 })
        rounded(body, 1000)
        local depth = create("UIGradient", body, { Rotation = 125,
            Color = ColorSequence.new(Color3.fromRGB(185, 208, 235), Color3.fromRGB(12, 17, 27)),
            Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(0.4, 0.9), NumberSequenceKeypoint.new(1, 0.16) }) })
        local rim = stroke(body, palette.accent); rim.Name = "DecorationStroke"
        rim.Thickness, rim.Transparency = 1, 0.7
        local rimLight = create("UIGradient", rim, { Rotation = -40,
            Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(100, 140, 185)),
            Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.25, 0.82), NumberSequenceKeypoint.new(0.65, 0.98), NumberSequenceKeypoint.new(1, 0.38) }) })
        local reflection = create("Frame", host, { Name = "SoftReflection", Position = UDim2.fromScale(0.17, 0.13),
            Size = UDim2.fromScale(0.42, 0.15), Rotation = -28,
            BackgroundColor3 = Color3.fromRGB(235, 247, 255), BackgroundTransparency = 0.79, BorderSizePixel = 0, ZIndex = 0 })
        rounded(reflection, 1000)
        create("UIGradient", reflection, { Rotation = 90,
            Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(0.5, 0.08), NumberSequenceKeypoint.new(1, 1) }) })
        local glint = create("Frame", host, { Name = "Glint", Position = UDim2.fromScale(0.23, 0.16),
            Size = UDim2.fromOffset(3, 3), BackgroundColor3 = Color3.fromRGB(240, 249, 255),
            BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 0 })
        rounded(glint, 1000)
        local texture=create("ImageLabel",host,{Name="StudioOrbTexture",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(1.18,1.18),BackgroundTransparency=1,ImageTransparency=1,ZIndex=0})
        table.insert(bubbles, { texture=texture, glint=glint, host = host, body = body, rim = rim, halos = halos,
            depth = depth, rimLight = rimLight, reflection = reflection, style = style,
            scale = create("UIScale", host, { Scale = 1 }) })
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
    for index = 1, 4 do
        local drift = create("Frame", decoration, {
            Size = UDim2.fromOffset(310, 80), BackgroundColor3 = Color3.fromRGB(228, 240, 250),
            BackgroundTransparency = 0.94, BorderSizePixel = 0,
        })
        create("UIGradient", drift, { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }) })
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
    local decorElapsed, decorTime, decorAccent, decorVisible = 1, 0, nil, false
    local decorBubbles, decorSnow, decorDrifts, decorMotion, decorTexture, decorAsset
    return function(dt)
        time += dt
        scanElapsed += dt
        decoration.Visible = menu.Visible and not settings.lowFx
        if decoration.Visible then
            decorElapsed += dt
            if settings.motion then decorTime += dt end
        end
        local repaint = decoration.Visible and (not decorVisible or palette.accent ~= decorAccent
            or decorBubbles ~= settings.bubbles or decorSnow ~= settings.snow or decorDrifts ~= settings.snowDrifts or decorMotion ~= settings.motion or decorTexture ~= settings.skinTextures or decorAsset ~= (settings._skinStatus and settings._skinStatus.texture)
            or (settings.motion and decorElapsed >= 1 / 30) or (settings._skinStatus.mode=="waiting for image" and decorElapsed>=.1))
        decorVisible = decoration.Visible
        if repaint then
            decorElapsed = 0
            local changedColor = palette.accent ~= decorAccent
            decorAccent = palette.accent
            decorBubbles, decorSnow, decorDrifts, decorMotion = settings.bubbles, settings.snow, settings.snowDrifts, settings.motion
            decorTexture,decorAsset=settings.skinTextures,settings._skinStatus and settings._skinStatus.texture
            if changedColor then for _, divider in ipairs(separators) do divider.BackgroundColor3 = palette.accent end end
            for _, orb in ipairs(bubbles) do
                orb.host.Visible = settings.bubbles
                if settings.bubbles then
                    local style, t = orb.style, decorTime
                    local uri=settings.skinTextures and controlRows.studio.asset()
                    if uri and orb.texture.Image~=uri then orb.texture.Image=uri end
                    local textured=uri and orb.texture.IsLoaded
                    orb.texture.ImageTransparency=textured and .12 or 1
                    orb.body.Visible,orb.reflection.Visible,orb.glint.Visible=not textured,not textured,not textured
                    if textured then
                        controlRows.studio.loaded()
                        orb.texture.ImageColor3=palette.accent:Lerp(Color3.fromRGB(245,250,255),.82)
                        orb.texture.Rotation=math.sin(t*.08+style.phase)*4
                    end
                    orb.host.Position = UDim2.fromScale(style.x + math.sin(t * 0.12 + style.phase) * 0.018,
                        style.y + math.cos(t * 0.1 + style.phase) * 0.026)
                    orb.scale.Scale = 1 + math.sin(t * 0.22 + style.phase) * 0.018
                    orb.depth.Rotation = 125 + math.sin(t * 0.08 + style.phase) * 12
                    orb.rimLight.Rotation = -40 + math.sin(t * 0.1 + style.phase) * 18
                    if orb.accent ~= palette.accent then
                        orb.accent = palette.accent
                        orb.body.BackgroundColor3 = palette.accent
                        orb.rim.Color = palette.accent:Lerp(Color3.fromRGB(225, 241, 255), 0.55)
                        for _, halo in ipairs(orb.halos) do halo.BackgroundColor3 = palette.accent end
                    end
                end
            end
            for index, flake in ipairs(flakes) do
                flake.Visible = settings.snow
                if settings.snow then
                    flake.Position = UDim2.fromScale((index * 0.137 + math.sin(decorTime * 0.3 + index) * 0.02) % 1,
                        (index * 0.113 + decorTime * 0.025) % 1)
                    flake.Rotation = (decorTime * 9 + index * 24) % 360
                end
            end
            for index, drift in ipairs(drifts) do
                drift.Visible = settings.snowDrifts
                if settings.snowDrifts then
                    drift.Position = UDim2.new(0, -64 + (index - 1) * 260, 1, -12 + math.sin(decorTime + index) * 3)
                end
            end
        end
        if scanElapsed >= 0.5 then
            scanElapsed = 0
            local seen = {}
            local hatCount=0
            if settings.friendHats and not settings.lowFx and next(friendNames) ~= nil then
                for _, other in ipairs(Players:GetPlayers()) do
                    local character = isFriend(other) and other.Character
                    local head = character and character:FindFirstChild("Head")
                    local camera=workspace.CurrentCamera
                    if isFriend(other) and head and head:IsA("BasePart") and camera and (head.Position-camera.CFrame.Position).Magnitude<=150 and hatCount<12 then
                        hatCount+=1
                        seen[other] = true
                        if not hats[other] or hats[other].head ~= head then
                            if hats[other] then removeHat(hats[other]) end
                            local model = create("Model", hatFolder)
                            local parts = {}
                            for index = 1, 18 do
                                parts[index] = create("Part", model, {
                                    Shape = index == 1 and Enum.PartType.Cylinder or Enum.PartType.Ball, Anchored = true,
                                    CanCollide = false, CanTouch = false, CanQuery = false,
                                    CastShadow = false, Material = Enum.Material.Fabric,
                                    Color = (index == 1 or index >= 9) and Color3.fromRGB(246, 240, 233) or Color3.fromRGB(176, 28, 52),
                                    Size = Vector3.new(1, 1, 1),
                                })
                            end
                            for _,part in ipairs(parts) do part.Transparency=0; part.LocalTransparencyModifier=0 end
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
        hatElapsed+=dt
        if hatElapsed<1/30 then return end
        hatElapsed=0
        for _,entry in pairs(hats) do
            if entry.head:IsDescendantOf(workspace) then
                local head=entry.head
                entry.tag.Enabled=not settings.esp
                for index,part in ipairs(entry.parts) do
                    if index==1 then
                        part.Size=Vector3.new(.22,head.Size.Z*1.42,head.Size.X*1.42)
                        part.CFrame=head.CFrame*CFrame.new(0,head.Size.Y/2+.15,0)*CFrame.Angles(0,0,math.pi/2)
                    elseif index==18 then
                        part.Size=Vector3.new(.34,.34,.34)
                        part.CFrame=head.CFrame*CFrame.new(.96,head.Size.Y/2+.62,0)
                    elseif index>=9 then
                        local angle=(index-9)*math.pi*2/9
                        part.Size=Vector3.new(.28,.28,.28)
                        part.CFrame=head.CFrame*CFrame.new(math.cos(angle)*head.Size.X*.64,head.Size.Y/2+.16,math.sin(angle)*head.Size.Z*.64)
                    else
                        local t=(index-2)/6
                        local width=1.23*(1-t)^.8+.1
                        part.Size=Vector3.new(head.Size.X*width,.62-.36*t,head.Size.Z*width)
                        part.CFrame=head.CFrame*CFrame.new(.95*t*t,head.Size.Y/2+.46+1.35*t-1.1*t*t*t,0)*CFrame.Angles(0,0,-.42*t)
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
    local function mapOpen() return controlRows.mapOverlay and controlRows.mapOverlay.isOpen() or false end
    local function adsInput()
        if mapOpen() then return false end
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
        if mapOpen() then restoreFov(false); return end
        if fov.camera ~= camera or not desired then restoreFov(adsInput()) end
        if not camera or not desired then return end
        if not fov.camera then
            fov.camera, fov.native = camera, camera.FieldOfView
            fov.connection = camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
                if mapOpen() then restoreFov(true); return end
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
        if mapOpen() then
            blend=0
            for _,entry in pairs(viewmodels) do
                for joint,pose in pairs(entry.joints or {}) do
                    if pose.applied and joint.Parent and joint.Transform==pose.applied then joint.Transform=pose.original end
                    pose.applied=nil
                end
            end
            return
        end
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
    local lastSightItem, tiltedSight = nil, false
    local function updateSightMode(camera)
        settings._crosshairAds = settings._ads
        settings._sightMode = settings._ads and "normal" or "hip"
        if not camera or not settings._ads then return end
        local rig = camera:FindFirstChild("ViewModel")
        local item = rig and rig:FindFirstChild("Item")
        if item ~= lastSightItem then lastSightItem, tiltedSight = item, false end
        local offsets = item and item:FindFirstChild("Offsets")
        local normal = offsets and offsets:FindFirstChild("AimPart")
        local canted = offsets and offsets:FindFirstChild("AimPartCanted")
        if not normal or not canted or not normal:IsA("BasePart") or not canted:IsA("BasePart") then return end
        -- Compare the real sight anchors to the camera axis, including weapon roll.
        -- Does not infer sight state from the B key, so rebinding/switching weapons stays valid.
        local function score(part)
            local p = camera.CFrame:PointToObjectSpace(part.Position)
            return math.sqrt(p.X * p.X + p.Y * p.Y) / math.max(0.25, math.abs(p.Z))
                + (1 - math.abs(part.CFrame.UpVector:Dot(camera.CFrame.UpVector))) * 0.35
        end
        local normalScore, cantedScore = score(normal), score(canted)
        if cantedScore + 0.025 < normalScore then tiltedSight = true
        elseif normalScore + 0.025 < cantedScore then tiltedSight = false end
        settings._crosshairAds = not tiltedSight
        settings._sightMode = tiltedSight and "canted" or "normal"
    end
    return function(dt, camera, desiredFov)
        updateSightMode(camera)
        applyFov(camera, not adsInput() and desiredFov or nil, dt)
        settings._nativeFov = fov.native or (camera and camera.FieldOfView)
        traceElapsed += dt
        if traceElapsed >= 0.1 then
            traceElapsed = 0
            local trace = settings._cameraTrace
            if #trace >= 240 then table.remove(trace, 1) end
            table.insert(trace, { time = os.clock(), fov = camera and camera.FieldOfView,
                native = settings._nativeFov, requested = desiredFov, ads = settings._ads, sightMode = settings._sightMode,
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
        if camera ~= cameraLast or ((settings.viewmodel or settings.noVisor) and scanTime >= 1) then
            scanTime = 0
            if camera ~= cameraLast then
                for model, entry in pairs(viewmodels) do restoreModel(model, entry) end
                table.clear(viewmodels)
                cameraLast = camera
                if cameraConnection then cameraConnection:Disconnect() end
                cameraConnection = camera and camera.DescendantAdded:Connect(function() scanTime = 1 end)
            end
            if camera and (settings.viewmodel or settings.noVisor) then
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
    local roots = { containers="container", chests="container", lootcontainers="container", corpses = "corpse", bodies = "corpse", deadbodies = "corpse",
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
                local display=object:GetAttribute("DisplayName")
                local name=string.lower(object.Name.." "..(type(display)=="string" and display or ""))
                local aurora=name:find("aurora",1,true)~=nil or name:find("аврора",1,true)~=nil or name:find("Аврора",1,true)~=nil
                if kind=="container" and not (settings.containerEsp or settings.auroraEsp and aurora) then return end
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
                marks[object].aurora=aurora
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
                mark.gui.Enabled = not settings._mapOpen and not menu.Visible and distance <= settings.lootRange
                    and (mark.kind == "corpse" and settings.corpseEsp or mark.kind == "item" and settings.itemEsp or mark.kind=="container" and (settings.containerEsp or settings.auroraEsp and mark.aurora))
                mark.gui.AlwaysOnTop = settings.lootThrough
                mark.label.TextSize = settings.lootTextSize
                mark.label.TextColor3 = mark.kind=="container" and (mark.aurora and Color3.fromRGB(190,163,255) or palette.accent) or mark.kind == "corpse" and Color3.fromRGB(255, 156, 125) or Color3.fromRGB(115, 229, 185)
                local name = object:GetAttribute("DisplayName")
                name = type(name) == "string" and name or object.Name
                mark.label.Text = (mark.kind == "corpse" and "CORPSE · " or mark.kind=="container" and "CONTAINER · " or "") .. name .. "\n" .. math.round(distance) .. " st"
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

local visualStudio
do
local function initializeVisualStudio()
    local owned, keys, createdSky, sky, signature = {}, {}, nil, nil, nil
    local elapsed = 1
    local looks = {
        { name = "Arctic", tint = Color3.fromRGB(205, 231, 255), contrast = 0.06, saturation = -0.08, exposure = 0.12, time = 13.5 },
        { name = "Golden", tint = Color3.fromRGB(255, 227, 190), contrast = 0.08, saturation = 0.08, exposure = 0.06, time = 17.4 },
        { name = "Neon", tint = Color3.fromRGB(206, 199, 255), contrast = 0.12, saturation = 0.18, exposure = 0.15, time = 21.5 },
        { name = "Cinema", tint = Color3.fromRGB(215, 235, 232), contrast = 0.13, saturation = -0.2, exposure = 0.03, time = 16.3 },
        { name = "Clean", tint = Color3.fromRGB(255, 255, 255), contrast = 0.03, saturation = 0.02, exposure = 0.08, time = 14 },
    }
    local function property(name, object, field, value)
        if not keys[name] then keys[name] = {} end
        override(keys[name], object, field, value)
    end
    local function effect(class, name)
        if not owned[name] then owned[name] = create(class, Lighting, { Name = name }) end
        return owned[name]
    end
    local function release()
        for _, key in pairs(keys) do
            local entry = overrides[key]
            if entry then override(key, entry.instance, entry.property, nil) end
        end
        for name, object in pairs(owned) do object:Destroy(); owned[name] = nil end
        if createdSky then createdSky:Destroy(); createdSky = nil end
        sky, signature = nil, nil
    end
    table.insert(cleanups, release)
    return { step = function(dt)
        elapsed += dt
        if not settings.graphics then
            if signature then release() end
            settings._graphicsStatus = "Off"
            return
        end
        local nextSignature = table.concat({ settings.gfxTier, settings.gfxLook, tostring(settings.bright), tostring(settings.clock) }, ":")
        if elapsed < 0.2 and signature == nextSignature then return end
        elapsed = 0
        signature = nextSignature
        local tier, look = settings.gfxTier, looks[settings.gfxLook]
        local grade = effect("ColorCorrectionEffect", "OktanGrade")
        grade.Enabled, grade.TintColor, grade.Contrast, grade.Saturation = true, look.tint, look.contrast, look.saturation
        grade.Brightness = 0
        property("exposure", Lighting, "ExposureCompensation", not settings.bright and look.exposure or nil)
        property("time", Lighting, "ClockTime", not settings.clock and look.time or nil)
        local shadows
        if not settings.bright and tier == 1 then shadows = false end
        property("shadows", Lighting, "GlobalShadows", shadows)
        if tier >= 2 then
            local bloom = effect("BloomEffect", "OktanBloom")
            bloom.Enabled, bloom.Intensity, bloom.Size, bloom.Threshold = true, tier == 3 and 0.16 or 0.08, 18, 1.2
        elseif owned.OktanBloom then owned.OktanBloom:Destroy(); owned.OktanBloom = nil end
        if tier == 3 then
            local rays = effect("SunRaysEffect", "OktanSunRays")
            rays.Enabled, rays.Intensity, rays.Spread = true, 0.035, 0.65
            local depth = effect("DepthOfFieldEffect", "OktanDepth")
            depth.Enabled, depth.FocusDistance, depth.InFocusRadius, depth.NearIntensity, depth.FarIntensity = true, 70, 140, 0, 0.06
        else
            for _, name in ipairs({ "OktanSunRays", "OktanDepth" }) do if owned[name] then owned[name]:Destroy(); owned[name] = nil end end
        end
        if not sky or not sky.Parent then
            sky = Lighting:FindFirstChildOfClass("Sky")
            if not sky then createdSky = create("Sky", Lighting, { Name = "OktanSky" }); sky = createdSky end
        end
        for face, suffix in pairs({ Bk = "bk", Dn = "dn", Ft = "ft", Lf = "lf", Rt = "rt", Up = "up" }) do
            property("sky" .. face, sky, "Skybox" .. face, "rbxasset://textures/sky/sky512_" .. suffix .. ".tex")
        end
        property("stars", sky, "StarCount", look.name == "Neon" and 4500 or 1800)
        property("sun", sky, "CelestialBodiesShown", true)
        settings._graphicsStatus = look.name .. " / " .. ({ "Low", "Balanced", "Ultra" })[tier]
    end }
end
visualStudio = initializeVisualStudio()
end

local chronoEcho
do
local function initializeChronoEcho()
    local frames, clones, trails = {}, {}, {}
    local panel, viewport, viewCamera, header, caption, world, avatar
    local priority = { Head = 1, UpperTorso = 2, Torso = 2, LeftUpperArm = 3, ["Left Arm"] = 3,
        RightUpperArm = 4, ["Right Arm"] = 4, LeftUpperLeg = 5, ["Left Leg"] = 5, RightUpperLeg = 6, ["Right Leg"] = 6, LowerTorso = 7 }
    local elapsed, sampleClock, renderClock, lastCharacter, lastTier = 0, 0, 0, nil, nil
    local function clear()
        table.clear(frames); table.clear(clones); table.clear(trails)
        if panel then panel:Destroy() end
        panel, viewport, viewCamera, world, avatar = nil, nil, nil, nil, nil
        lastCharacter, lastTier = nil, nil
    end
    table.insert(cleanups, clear)
    local function ensureUi()
        if panel then return end
        panel = create("Frame", gui, { Name = "OktanChronoEcho", Position = UDim2.new(0, 18, 1, -238), Size = UDim2.fromOffset(304, 220), BackgroundColor3 = Color3.fromRGB(10, 15, 24), BackgroundTransparency = 0.08, BorderSizePixel = 0 })
        rounded(panel, 18); stroke(panel, palette.accent).Transparency = 0.25
        header = text(panel, "CHRONO ECHO", { Position = UDim2.fromOffset(14, 7), Size = UDim2.fromOffset(276, 28), TextSize = 12, TextColor3 = palette.accent }, "TextButton")
        header.Activated:Connect(function() setValue("echoFreeze", not settings.echoFreeze) end)
        viewport = create("ViewportFrame", panel, { Position = UDim2.fromOffset(8, 38), Size = UDim2.fromOffset(288, 150), BackgroundTransparency = 1, Ambient = Color3.fromRGB(190, 210, 255), LightColor = Color3.fromRGB(220, 235, 255) })
        world = create("WorldModel", viewport)
        avatar = create("Model", world)
        viewCamera = create("Camera", viewport, { FieldOfView = 48 })
        viewport.CurrentCamera = viewCamera
        caption = text(panel, "Recording memory...", { Position = UDim2.fromOffset(14, 190), Size = UDim2.fromOffset(276, 22), TextSize = 11, TextColor3 = palette.muted })
    end
    local function copyPart(part)
        local ok, copy = pcall(function() return part:Clone() end)
        if not ok or not copy then return nil end
        for _, child in ipairs(copy:GetDescendants()) do
            if child:IsA("JointInstance") or child:IsA("Constraint") or child:IsA("WeldConstraint")
                or child:IsA("LuaSourceContainer") or child:IsA("SurfaceAppearance") or child:IsA("SurfaceGui")
                or child:IsA("ParticleEmitter") then child:Destroy() end
        end
        copy.Anchored, copy.CanCollide, copy.CanTouch, copy.CanQuery = true, false, false, false
        copy.CastShadow, copy.LocalTransparencyModifier, copy.Transparency = false, 0, 0.35
        copy.Material, copy.Color, copy.Parent = Enum.Material.Neon, palette.accent, avatar
        return copy
    end
    return { step = function(dt)
        elapsed += dt
        if not settings.echo then
            if panel then clear() end
            settings._echoStatus = "Off"
            return
        end
        local character = player.Character
        if character ~= lastCharacter or lastTier ~= settings.gfxTier then
            clear(); lastCharacter, lastTier = character, settings.gfxTier
        end
        ensureUi()
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then caption.Text = "Waiting for character..."; return end
        local tier = settings.gfxTier
        local interval, limit = ({ 0.2, 0.12, 0.08 })[tier], ({ 6, 12, 16 })[tier]
        sampleClock += dt; renderClock += dt
        if sampleClock >= interval then
            sampleClock = 0
            local pose, count = {}, 0
            local body = character:GetChildren()
            table.sort(body, function(a, b)
                local ap, bp = priority[a.Name] or 100, priority[b.Name] or 100
                if ap == bp then return a.Name < b.Name end
                return ap < bp
            end)
            for _, part in ipairs(body) do
                if part:IsA("BasePart") and bodyNames[part.Name] and count < limit then
                    if not clones[part.Name] then clones[part.Name] = copyPart(part) end
                    if clones[part.Name] then pose[part.Name] = part.CFrame; count += 1 end
                end
            end
            table.insert(frames, { time = elapsed, root = root.CFrame, pose = pose })
            while #frames > 90 or (#frames > 1 and elapsed - frames[1].time > 8) do table.remove(frames, 1) end
        end
        settings._echoStatus = { frames = #frames, parts = limit, delay = settings.echoDelay, frozen = settings.echoFreeze }
        header.Text = settings.echoFreeze and "CHRONO ECHO  /  FROZEN" or "CHRONO ECHO  /  LIVE MEMORY"
        header.TextColor3 = palette.accent
        panel:FindFirstChildOfClass("UIStroke").Color = palette.accent
        if renderClock < 1 / ({ 15, 30, 60 })[tier] then return end
        renderClock = 0
        if settings.echoFreeze then caption.Text = "Frozen • click title to resume"; return end
        local target, a, b = elapsed - settings.echoDelay, nil, nil
        for _, frame in ipairs(frames) do
            if frame.time <= target then a = frame elseif a then b = frame; break end
        end
        if not a then caption.Text = "Recording memory..."; return end
        b = b or a
        local alpha = a == b and 0 or math.clamp((target - a.time) / (b.time - a.time), 0, 1)
        for name, copy in pairs(clones) do
            if a.pose[name] and b.pose[name] then
                copy.CFrame = a.pose[name]:Lerp(b.pose[name], alpha)
                copy.Color, copy.Transparency = palette.accent, 0.35
            else copy.Transparency = 1 end
        end
        local position = a.root:Lerp(b.root, alpha).Position
        viewCamera.CFrame = CFrame.lookAt(position + Vector3.new(6, 3.5, 8), position + Vector3.new(0, 1, 0))
        local number = 0
        for i = 1, #frames, math.max(1, math.floor(#frames / 16)) do
            if frames[i].time <= target and target - frames[i].time < 3 then
                number += 1
                local trail = trails[number]
                if not trail then trail = create("Part", world, { Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false, Shape = Enum.PartType.Ball, Size = Vector3.new(0.1, 0.1, 0.1), Material = Enum.Material.Neon }); trails[number] = trail end
                trail.CFrame, trail.Color, trail.Transparency = frames[i].root, palette.accent, 0.25
            end
        end
        for i = number + 1, #trails do trails[i].Transparency = 1 end
        caption.Text = string.format("%.1fs ago  •  %d frames  •  click to freeze", settings.echoDelay, #frames)
        settings._echoStatus = { frames = #frames, parts = limit, delay = settings.echoDelay, frozen = settings.echoFreeze }
    end }
end
chronoEcho = initializeChronoEcho()
end

do
local function initializeWeaponTuning()
    local entry, elapsed
    elapsed = 1
    local previousStatus
    local function status(message)
        if previousStatus == message then return end
        previousStatus = message
        settings._weaponStatus = { recoil = message, spread = "Waiting for weapon definition data" }
    end
    local function valid(value)
        return type(value) == "number" and value == value and value >= 0 and value <= 100
    end
    local function restore()
        local previous = entry
        entry = nil
        if not previous then return end
        previous.connection:Disconnect()
        if previous.root.Parent and previous.root:GetAttribute("Recoil") == 0 then
            previous.root:SetAttribute("Recoil", previous.original)
        end
    end
    table.insert(cleanups, restore)
    return { step = function(dt)
        elapsed += dt
        if elapsed < 0.2 and settings.noRecoil and entry and player.Character == entry.character then return end
        elapsed = 0
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if entry and (not settings.noRecoil or root ~= entry.root) then restore() end
        if not settings.noRecoil then status("Off"); return end
        if not root or not valid(root:GetAttribute("Recoil")) then
            restore()
            status("No supported local Recoil multiplier")
            return
        end
        if not entry then
            local owned = { root = root, character = character, original = root:GetAttribute("Recoil"), writing = false }
            entry = owned
            owned.connection = root:GetAttributeChangedSignal("Recoil"):Connect(function()
                if entry ~= owned or owned.writing then return end
                local value = root:GetAttribute("Recoil")
                if value == 0 then return end
                if not valid(value) then restore(); status("Recoil multiplier removed or unsupported"); return end
                owned.original, owned.writing = value, true
                root:SetAttribute("Recoil", 0)
                owned.writing = false
            end)
        end
        if root:GetAttribute("Recoil") ~= 0 then
            entry.original, entry.writing = root:GetAttribute("Recoil"), true
            root:SetAttribute("Recoil", 0)
            entry.writing = false
        end
        status("Local Recoil multiplier = 0; firing response unverified")
    end }
end
aimContext.weaponTuning = initializeWeaponTuning()
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

do
local function initializeMapCalibration()
    local api={samples={},state="Нужны точки привязки",bad=0}
    api.reset=function(key)
        api.key=key; api.matrix=nil; api.samples={}; api.bad=0; api.state="Нужны точки привязки"
    end
    api.predict=function(position)
        local m=api.matrix
        if not m then return nil end
        return m.ux*position.X+m.uz*position.Z+m.u0,m.vx*position.X+m.vz*position.Z+m.v0
    end
    api.project=function(position,mine,anchor)
        local m=api.matrix
        if not m then return nil end
        local x,z=position.X-mine.X,position.Z-mine.Z
        return anchor.X+m.ux*x+m.uz*z,anchor.Y+m.vx*x+m.vz*z
    end
    api.observe=function(key,position,anchor,tolerance)
        if key~=api.key then api.reset(key) end
        if api.matrix then
            local u,v=api.predict(position)
            if math.sqrt((u-anchor.X)^2+(v-anchor.Y)^2)<=tolerance then api.bad=0; api.state="Привязка подтверждена"; return true end
            api.bad+=1; api.state="Сверяем штатную стрелку…"
            if api.bad>=5 then api.reset(key) end
            return false
        end
        local last=api.samples[#api.samples]
        if last and (position.X-last.x)^2+(position.Z-last.z)^2<30^2 then return false end
        table.insert(api.samples,{x=position.X,z=position.Z,u=anchor.X,v=anchor.Y})
        if #api.samples>16 then table.remove(api.samples,1) end
        local n=#api.samples
        if n<4 then api.state="Пройди вперёд, затем вбок"; return false end
        local x,z,u,v=0,0,0,0
        for _,sample in ipairs(api.samples) do x+=sample.x; z+=sample.z; u+=sample.u; v+=sample.v end
        x/=n; z/=n; u/=n; v/=n
        local xx,zz,xz,xu,zu,xv,zv=0,0,0,0,0,0,0
        for _,sample in ipairs(api.samples) do
            local dx,dz,du,dv=sample.x-x,sample.z-z,sample.u-u,sample.v-v
            xx+=dx*dx; zz+=dz*dz; xz+=dx*dz; xu+=dx*du; zu+=dz*du; xv+=dx*dv; zv+=dz*dv
        end
        local det=xx*zz-xz*xz
        if xx<400 or zz<400 or det<=0 or det/math.max(1,xx*zz)<.08 then api.state="Нужно пройти в другую сторону"; return false end
        local m={ux=(xu*zz-zu*xz)/det,uz=(zu*xx-xu*xz)/det,vx=(xv*zz-zv*xz)/det,vz=(zv*xx-xv*xz)/det}
        m.u0=u-m.ux*x-m.uz*z; m.v0=v-m.vx*x-m.vz*z
        local scaleU,scaleV=math.sqrt(m.ux*m.ux+m.uz*m.uz),math.sqrt(m.vx*m.vx+m.vz*m.vz)
        if scaleU<1/100000 or scaleU>1/100 or scaleV<1/100000 or scaleV>1/100
            or math.abs(m.ux*m.vz-m.uz*m.vx)<1e-11 then api.state="Масштаб не подтверждён"; return false end
        local worst,worstIndex=0,1
        for index,sample in ipairs(api.samples) do
            local error=math.sqrt((m.ux*sample.x+m.uz*sample.z+m.u0-sample.u)^2+(m.vx*sample.x+m.vz*sample.z+m.v0-sample.v)^2)
            if error>worst then worst,worstIndex=error,index end
        end
        if worst>tolerance then
            if n>=6 then table.remove(api.samples,worstIndex) end
            api.state="Ожидаем стабильные точки"; return false
        end
        api.matrix=m; api.state="Привязка подтверждена"; return true
    end
    table.insert(cleanups,function() api.reset(nil) end)
    return api
end
controlRows.mapCalibration=initializeMapCalibration()
end

do
local function initializeMapOverlay()
    local api={elapsed=1,marks={},state="Off"}
    local host,container,origin,notice
    local function clear()
        if host then host:Destroy() end
        if origin then origin.Visible=false end
        host,container=nil,nil; table.clear(api.marks)
    end
    local function hide()
        if host then host.Visible=false end
        if origin then origin.Visible=false end
    end
    local function shown(object)
        while object and object~=playerGui do
            if object:IsA("GuiObject") and not object.Visible then return false end
            if object:IsA("ScreenGui") and not object.Enabled then return false end
            object=object.Parent
        end
        return true
    end
    api.isOpen=function()
        local mainGui=playerGui:FindFirstChild("MainGui")
        local main=mainGui and mainGui:FindFirstChild("MainFrame")
        local frame=main and main:FindFirstChild("MapFrame")
        return frame~=nil and shown(frame)
    end
    api.surface=function(surface)
        local left,top,right,bottom=math.huge,math.huge,-math.huge,-math.huge
        for index=1,4 do
            local tile=surface:FindFirstChild("S"..index)
            if not tile or tile.AbsoluteSize.X<=0 or tile.AbsoluteSize.Y<=0 then return nil end
            left=math.min(left,tile.AbsolutePosition.X); top=math.min(top,tile.AbsolutePosition.Y)
            right=math.max(right,tile.AbsolutePosition.X+tile.AbsoluteSize.X)
            bottom=math.max(bottom,tile.AbsolutePosition.Y+tile.AbsoluteSize.Y)
        end
        return left,top,right-left,bottom-top
    end
    api.anchor=function(marker,left,top,width,height)
        return Vector2.new((marker.AbsolutePosition.X+marker.AbsoluteSize.X*.5-left)/width,(marker.AbsolutePosition.Y+marker.AbsoluteSize.Y*.5-top)/height)
    end
    api.project=function(position,mine,anchor)
        return controlRows.mapCalibration.project(position,mine,anchor)
    end
    api.step=function(dt)
        api.elapsed+=dt
        if not settings.mapPlayers then if host then clear() end; api.state="Off"; return end
        local mainGui=playerGui:FindFirstChild("MainGui")
        local main=mainGui and mainGui:FindFirstChild("MainFrame")
        local frame=main and main:FindFirstChild("MapFrame")
        local map=frame and frame:FindFirstChild("MainFrame")
        local markers=map and map:FindFirstChild("Markers")
        local selfMarker=markers and markers:FindFirstChild("SelfMarker")
        local maps=map and map:FindFirstChild("Maps")
        local mine=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not frame or not shown(frame) or not maps or not markers or not selfMarker or not mine then
            hide(); api.state="Open map in a raid"; return
        end
        local current
        local worldName=workspace:GetAttribute("MapName")
        for _,candidate in ipairs(maps:GetChildren()) do
            if candidate:IsA("GuiObject") and candidate.Visible and candidate:GetAttribute("MapName")==worldName then current=candidate; break end
        end
        local size=current and current:GetAttribute("SizeReal")
        -- Only the exported map orientation is supported. Unknown maps stay empty.
        if worldName~="Estonian Border" or type(size)~="number" or size~=size or size<100 or size>100000
            or not selfMarker.Visible or markers.AbsoluteSize.X<=0 or markers.AbsoluteSize.Y<=0 then
            hide(); api.state="Unsupported map or no self marker"; return
        end
        local left,top,width,height=api.surface(current)
        if current.Rotation~=0 or not left or width<=0 or height<=0 then
            hide(); api.state="Map alignment unavailable"; return
        end
        if not host or not host.Parent or container~=markers then
            clear(); container=markers
            if not origin then origin=create("Frame",gui,{Name="OktanMapOrigin",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,Active=false,Selectable=false,ZIndex=14}) end
            host=create("Frame",origin,{Name="OktanMapPlayers",BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true,Active=false,Selectable=false,ZIndex=15})
            notice=text(host,"",{Name="MapCalibration",Position=UDim2.fromOffset(12,12),Size=UDim2.fromOffset(390,48),TextSize=11,TextWrapped=true,BackgroundColor3=palette.background,BackgroundTransparency=.12,TextColor3=palette.text,Active=false,ZIndex=18})
            rounded(notice,10)
        end
        host.Visible=true
        origin.Visible=true
        -- Geometry follows the actual four image tiles every render frame.
        -- No objects or input handlers are installed in the game's Markers tree.
        host.Position=UDim2.fromOffset(left-origin.AbsolutePosition.X,top-origin.AbsolutePosition.Y)
        host.Size=UDim2.fromOffset(width,height)
        if api.elapsed<.1 then return end
        local sampleDt=api.elapsed; api.elapsed=0
        local anchor=api.anchor(selfMarker,left,top,width,height)
        local worldCoordinates=workspace:GetAttribute("Cordinates")
        local mapCoordinates=current:GetAttribute("Cordinates")
        local key=tostring(worldName).."/"..tostring(worldCoordinates).."/"..tostring(mapCoordinates).."/"..tostring(size)
        local calibration=controlRows.mapCalibration
        if calibration.key~=key then calibration.reset(key); api.stableAge=0; api.stablePosition=nil; api.stableAnchor=nil end
        local stable=true
        if not calibration.matrix then
            if not api.stablePosition or (mine.Position-api.stablePosition).Magnitude>.4 or not api.stableAnchor or (anchor-api.stableAnchor).Magnitude>1/math.max(width,height) then api.stableAge=0 end
            api.stablePosition,api.stableAnchor=mine.Position,anchor
            api.stableAge=(api.stableAge or 0)+sampleDt
            stable=api.stableAge>=.3
            if not stable then calibration.state="Остановись на секунду для замера" end
        end
        local calibrated=stable and calibration.observe(key,mine.Position,anchor,math.max(.001,3/math.max(width,height))) or false
        notice.Visible=not calibrated
        if not calibrated then
            notice.Text="Привязка карты · "..math.min(4,#controlRows.mapCalibration.samples).."/4\n"..controlRows.mapCalibration.state..". Можно закрывать карту между точками."
            for _,mark in pairs(api.marks) do mark.dot.Visible=false end
            api.state="Calibration: "..controlRows.mapCalibration.state
            return
        end
        local seen,count={},0
        for _,owner in ipairs(Players:GetPlayers()) do
            local character=owner.Character
            local root=character and character:FindFirstChild("HumanoidRootPart")
            local humanoid=character and character:FindFirstChildOfClass("Humanoid")
            if owner~=player and root and root:IsA("BasePart") and humanoid and humanoid.Health>0 and count<200 then
                local friend=isFriend(owner)
                if not settings.mapFriendsOnly or friend then
                    local u,v=api.project(root.Position,mine.Position,anchor)
                    if u>=0 and u<=1 and v>=0 and v<=1 then
                        count+=1; seen[owner]=true
                        local mark=api.marks[owner]
                        if not mark then
                            local dot=create("Frame",host,{Name="PlayerDot",AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(8,8),BorderSizePixel=0,Active=false,Selectable=false,ZIndex=16})
                            rounded(dot,8); stroke(dot,Color3.fromRGB(8,17,23),2)
                            local name=text(dot,owner.Name,{Name="PlayerName",Position=UDim2.fromOffset(12,-7),Size=UDim2.fromOffset(160,22),TextXAlignment=Enum.TextXAlignment.Left,TextSize=11,TextStrokeColor3=Color3.fromRGB(6,12,16),TextStrokeTransparency=.2,Active=false,Selectable=false,ZIndex=17})
                            mark={dot=dot,name=name}; api.marks[owner]=mark
                        end
                        local color=friend and Color3.fromRGB(125,239,190) or Color3.fromHSV(settings.espHue/360,settings.espSaturation/100,settings.espValue/100)
                        mark.dot.Position=UDim2.fromScale(u,v)
                        mark.dot.Visible=true
                        mark.dot.BackgroundColor3=color
                        mark.name.Text=owner.Name..(friend and " · ALLY" or "")
                        mark.name.TextColor3=color
                        mark.name.Visible=settings.mapNames
                        mark.name.TextSize=settings.mapTextSize
                        mark.name.Position=UDim2.fromOffset(u>.8 and -172 or 12,v>.98 and -22 or v<.02 and 0 or -7)
                        mark.name.TextXAlignment=u>.8 and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
                    end
                end
            end
        end
        for owner,mark in pairs(api.marks) do if not seen[owner] then mark.dot:Destroy(); api.marks[owner]=nil end end
        api.state="Estonian Border · "..count.." players"
    end
    table.insert(cleanups,function() clear(); if origin then origin:Destroy(); origin=nil end end)
    return api
end
controlRows.mapOverlay=initializeMapOverlay()
end

local renderState = { elapsed = 1, visualElapsed = 1, perfElapsed = 0, perfFrames = 0, perfTotal = 0, perfEsp = 0, perfCamera = 0, perfPeak = 0 }
RunService:BindToRenderStep(renderName, Enum.RenderPriority.Last.Value + 1, function(dt)
    local perfStarted = settings.perfDebug and os.clock()
    local camera = workspace.CurrentCamera
    controlRows.musicIsland.step(dt)
    updateHud(dt)
    controlRows.mapOverlay.step(dt)
    settings._mapOpen=controlRows.mapOverlay.isOpen()
    overlay.Visible=not settings._mapOpen
    controlRows.friends.step(dt)
    controlRows.studio.step()
    updateWinter(dt)
    soulFx.step(dt)
    visualStudio.step(dt)
    chronoEcho.step(dt)
    aimContext.weaponTuning.step(dt)
    controlRows.music.step(dt)
    controlRows.spotify.step(dt)
    controlRows.yandex.step(dt)
    controlRows.subscription.step(dt)
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
        if settings.perfDebug and settings._performance then
            status.Text ..= string.format(" • CPU %.2fms • ESP %.2fms / %dHz", settings._performance.meanMs, settings._performance.espMs, settings._performance.espHz)
        end
    end

    menu.BackgroundTransparency = math.min(settings.glass, 12) / 100
    if not menu.Visible then
        bindDialog.Visible = false
        controlRows.bindShield.Visible=false; controlRows.bindGesture.action=nil
        pendingNumeric = nil
    end
    blurEffect.Size = menu.Visible and not settings.lowFx and settings.blur or 0
    blurEffect.Enabled = menu.Visible and not settings.lowFx and settings.blur > 0
    if tooltip.Visible then
        local mouse = Input:GetMouseLocation()
        local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
        tooltip.Position = UDim2.fromOffset(
            math.clamp(mouse.X + 18, 0, math.max(0, viewport.X - 364)),
            math.clamp(mouse.Y + 20, 0, math.max(0, viewport.Y - tooltip.AbsoluteSize.Y - 4)))
    end
    local color = Color3.fromHSV(settings.espHue / 360, settings.espSaturation / 100, settings.espValue / 100)
    renderState.visualElapsed += dt
    renderState.effectiveEspFps = settings.espFps
    if settings.adaptiveEsp then
        if #orderedMarkers > 32 then renderState.effectiveEspFps = math.min(settings.espFps, 20)
        elseif #orderedMarkers > 16 then renderState.effectiveEspFps = math.min(settings.espFps, 30) end
    end
    local espStarted = perfStarted and os.clock()
    if renderState.visualElapsed >= 1 / renderState.effectiveEspFps then
        renderState.visualElapsed = 0
        table.clear(occupiedLabels)
        for _, marker in ipairs(orderedMarkers) do renderScreenMarker(marker, camera, color) end
    end
    if espStarted then renderState.perfEsp += os.clock() - espStarted end
    local mapOpen=controlRows.mapOverlay.isOpen()
    settings._mapOpen=mapOpen
    overlay.Visible=not mapOpen
    local inputReady = focused and not menu.Visible and not mapOpen and not capture and Input:GetFocusedTextBox() == nil
    local records = game:GetService("ReplicatedStorage"):FindFirstChild("Players")
    local record = records and records:FindFirstChild(player.Name)
    local status = record and record:FindFirstChild("Status")
    local variables = status and status:FindFirstChild("GameplayVariables")
    settings._equipId = variables and variables:GetAttribute("EquipId")
    local equipped = variables and variables:FindFirstChild("EquippedTool")
    local weaponPresent = (equipped and equipped.Value ~= nil) or (variables and (variables:GetAttribute("EquipId") or 0) ~= 0) or (player.Character and heldItem(player.Character) ~= nil)
    local rightMouse = focused and not menu.Visible and not mapOpen and Input:GetFocusedTextBox() == nil and Input:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    local function aimingFlag(object)
        return object and (object:GetAttribute("Aiming") == true or object:GetAttribute("ADS") == true or object:GetAttribute("IsAiming") == true)
    end
    settings._ads = not mapOpen and (aimingFlag(variables) or aimingFlag(player.Character) or aimingFlag(camera) or (weaponPresent and rightMouse)) or false
    local zooming = camera and inputReady and settings.zoom and held("zoom")
    local cameraStarted = perfStarted and os.clock()
    updateCameraVisuals(dt, camera, (not settings._ads) and (zooming and settings.zoomFov or (settings.cameraFov and settings.cameraFovValue or nil)) or nil)
    if cameraStarted then renderState.perfCamera += os.clock() - cameraStarted end
    enforceOverrides()
    ring.Visible = camera ~= nil and inputReady and settings.aim and settings.ring
    if renderState.shownRingRadius ~= settings.radius then
        renderState.shownRingRadius = settings.radius
        ring.Size = UDim2.fromOffset(renderState.shownRingRadius * 2, renderState.shownRingRadius * 2)
    end
    local showCross = camera ~= nil and inputReady and settings.crosshair and not settings._crosshairAds
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
        aimContext.locked, aimContext.filter = nil, nil
    end
    if perfStarted then
        local cost = os.clock() - perfStarted
        renderState.perfFrames += 1; renderState.perfElapsed += dt; renderState.perfTotal += cost
        renderState.perfPeak = math.max(renderState.perfPeak, cost)
        if renderState.perfElapsed >= 1 then
            settings._performance = { scope = "main render callback CPU; excludes GPU/other scripts",
                meanMs = renderState.perfTotal * 1000 / renderState.perfFrames,
                espMs = renderState.perfEsp * 1000 / renderState.perfFrames,
                cameraMs = renderState.perfCamera * 1000 / renderState.perfFrames,
                peakMs = renderState.perfPeak * 1000, markers = #orderedMarkers, espHz = renderState.effectiveEspFps }
            renderState.perfFrames, renderState.perfElapsed, renderState.perfTotal = 0, 0, 0
            renderState.perfEsp, renderState.perfCamera, renderState.perfPeak = 0, 0, 0
        end
    elseif settings._performance then
        settings._performance = nil
        renderState.perfFrames, renderState.perfElapsed, renderState.perfTotal = 0, 0, 0
        renderState.perfEsp, renderState.perfCamera, renderState.perfPeak = 0, 0, 0
    end
end)
