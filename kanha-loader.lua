--[[
    Kanha Hub Loader — Rebuild
    Discord : discord.gg/n9vcsTdce
    No key. No HWID. Direct load.
]]

------------------------------------------------------------
-- Decode helper (obfuscation maison)
------------------------------------------------------------
local function _H(h)
    local o = {}
    for i = 1, #h, 2 do
        o[#o + 1] = string.char(tonumber(h:sub(i, i+1), 16))
    end
    return table.concat(o)
end

------------------------------------------------------------
-- Session par défaut (modules en ont besoin)
------------------------------------------------------------
_G.KanhaSession = _G.KanhaSession or {
    tier = "owner",
    exp = 0,
    key = "nokey",
    sig = "none",
    hwid = "none",
}

------------------------------------------------------------
-- Constantes
------------------------------------------------------------
local BASE_URL = _H("68747470733a2f2f7261772e67697468756275736572636f6e74656e742e636f6d2f6d6f756d6f7533316b2d63796265722f736372697074732f726566732f68656164732f6d61696e2f")
local RAYFIELD_URL = _H("68747470733a2f2f7369726975732e6d656e752f7261796669656c64")

local GAMES = {
    { name = _H("526976616c73"),          file = _H("726976616c732e6c7561"),            placeIds = { 17625359962 } },
    { name = _H("417273656e616c"),        file = _H("617273656e616c2e6c7561"),          placeIds = { 286090429 } },
    { name = _H("4d4d32"),                file = _H("6d6d322e6c7561"),                  placeIds = { 142823291 } },
    { name = _H("536e69706572204172656e61"), file = _H("736e697065722d6172656e612e6c7561"), placeIds = { 122446657157717 } },
    { name = _H("556e6976657273616c"),    file = _H("756e6976657273616c2e6c7561"),      placeIds = {} },
}

------------------------------------------------------------
-- Notify
------------------------------------------------------------
local function notify(title, text, dur)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = dur or 4,
        })
    end)
end

------------------------------------------------------------
-- Find current game
------------------------------------------------------------
local function findCurrentGame()
    for _, g in ipairs(GAMES) do
        for _, id in ipairs(g.placeIds) do
            if id == game.PlaceId then
                return g
            end
        end
    end
    return nil
end

------------------------------------------------------------
-- Load a module
------------------------------------------------------------
local function loadModule(game_def)
    local url = BASE_URL .. game_def.file
    warn("[KanhaHub] Fetching:", url)

    -- 1) Fetch
    local ok, src = pcall(function()
        return game:HttpGet(url)
    end)

    if not ok then
        warn("[KanhaHub] HttpGet failed:", tostring(src))
        notify("KanhaHub", "Erreur reseau: " .. game_def.name, 5)
        return false
    end

    if type(src) ~= "string" or #src < 10 then
        warn("[KanhaHub] Source empty. len:", type(src) == "string" and #src or "nil")
        notify("KanhaHub", "Source vide: " .. game_def.name, 5)
        return false
    end

    -- 2) Compile
    local fn, err = loadstring(src)
    if type(fn) ~= "function" then
        warn("[KanhaHub] Compile failed:", tostring(err))
        notify("KanhaHub", "Compile error: " .. game_def.name, 5)
        return false
    end

    -- 3) Execute
    local success, result = pcall(fn)
    if not success then
        warn("[KanhaHub] Exec failed:", tostring(result))
        notify("KanhaHub", "Exec error: " .. game_def.name, 5)
        return false
    end

    warn("[KanhaHub] Module loaded:", game_def.name)
    return true
end

------------------------------------------------------------
-- Picker
------------------------------------------------------------
local function openPicker()
    local ok_rf, Rayfield = pcall(function()
        return loadstring(game:HttpGet(RAYFIELD_URL))()
    end)

    if not ok_rf or not Rayfield then
        warn("[KanhaHub] Rayfield failed:", tostring(Rayfield))
        notify("KanhaHub", "Rayfield introuvable.", 5)
        return
    end

    local Window = Rayfield:CreateWindow({
        Name = "Kanha Hub",
        LoadingTitle = "Kanha Hub",
        LoadingSubtitle = "by Kanha",
        Theme = "Dark",
        ToggleUIKeybind = Enum.KeyCode.RightShift,
        ConfigurationSaving = { Enabled = false },
        KeySystem = false,
    })

    local PickerTab = Window:CreateTab("Games", 6031097226)

    local currentGame = findCurrentGame()
    if currentGame then
        PickerTab:CreateParagraph({
            Title = "Detecte",
            Content = "Jeu en cours : " .. currentGame.name,
        })
    end

    PickerTab:CreateSection("Choisir un jeu")

    for _, g in ipairs(GAMES) do
        local isCurrent = currentGame and currentGame.name == g.name
        local label = g.name .. (isCurrent and "  (en cours)" or "")

        PickerTab:CreateButton({
            Name = label,
            Callback = function()
                task.spawn(function()
                    pcall(function()
                        loadModule(g)
                    end)
                end)

                task.defer(function()
                    task.wait(0.2)
                    pcall(function() Window:Destroy() end)
                end)
            end,
        })
    end

    PickerTab:CreateSection("Infos")
    PickerTab:CreateButton({
        Name = "Unload",
        Callback = function()
            task.defer(function()
                pcall(function() Window:Destroy() end)
            end)
        end,
    })

    pcall(function()
        Rayfield:Notify({
            Title = "Kanha Hub",
            Content = "Choisis un jeu.",
            Duration = 4,
        })
    end)
end

------------------------------------------------------------
-- Main
------------------------------------------------------------
if _G.KanhaLoaded then
    notify("Kanha Hub", "Deja charge.", 3)
    return
end
_G.KanhaLoaded = true

local ok, err = pcall(openPicker)
if not ok then
    warn("[KanhaHub] Picker crash:", tostring(err))
    notify("Kanha Hub", "Crash: " .. tostring(err), 6)
end
