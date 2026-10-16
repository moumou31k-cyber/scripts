--[[
    Kanha Hub Loader — No Key Edition
    Discord : discord.gg/n9vcsTdce
    Aucune vérification de clé. Lancement direct.
]]

local _H = function(h)
    local o = {}
    for i = 1, #h, 2 do
        o[#o + 1] = string.char(tonumber(h:sub(i, i+1), 16))
    end
    return table.concat(o)
end

------------------------------------------------------------
-- Session par défaut (pour compat avec les modules)
------------------------------------------------------------
_G.KanhaSession = {
    tier = "owner",
    exp = 0,
    key = "nokey",
    sig = "none",
    hwid = "none",
}

------------------------------------------------------------
-- Registry des jeux
------------------------------------------------------------
local GAMES = {
    {name = _H("526976616c73"),          file = _H("726976616c732e6c7561"),          placeIds = {17625359962}},
    {name = _H("417273656e616c"),        file = _H("617273656e616c2e6c7561"),        placeIds = {286090429}},
    {name = _H("4d4d32"),                file = _H("6d6d322e6c7561"),                placeIds = {142823291}},
    {name = _H("536e69706572204172656e61"), file = _H("736e697065722d6172656e612e6c7561"), placeIds = {122446657157717}},
    {name = _H("556e6976657273616c"),    file = _H("756e6976657273616c2e6c7561"),    placeIds = {}},
}

local BASE_URL = _H("68747470733a2f2f7261772e67697468756275736572636f6e74656e742e636f6d2f6d6f756d6f7533316b2d63796265722f736372697074732f726566732f68656164732f6d61696e2f")

------------------------------------------------------------
-- Notify
------------------------------------------------------------
local function notify(title, text, dur)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title, Text = text, Duration = dur or 4,
        })
    end)
end

------------------------------------------------------------
-- Trouver le jeu courant
------------------------------------------------------------
local function findCurrentGame()
    for _, g in ipairs(GAMES) do
        for _, id in ipairs(g.placeIds) do
            if id == game.PlaceId then return g end
        end
    end
    return nil
end

------------------------------------------------------------
-- Picker UI (Rayfield)
------------------------------------------------------------
local function showGamePicker()
    local Rayfield = loadstring(game:HttpGet(_H("68747470733a2f2f7369726975732e6d656e752f7261796669656c64")))()

    local Window = Rayfield:CreateWindow({
        Name = _H("4b616e686120487562"),
        LoadingTitle = _H("4b616e686120487562"),
        LoadingSubtitle = _H("6279204b616e6861"),
        Theme = "Dark",
        ToggleUIKeybind = Enum.KeyCode.RightShift,
        ConfigurationSaving = { Enabled = false },
        KeySystem = false,
    })

    local PickerTab = Window:CreateTab(_H("47616d6573"), 6031097226)

    local currentGame = findCurrentGame()
    if currentGame then
        PickerTab:CreateParagraph({
            Title = _H("4465746563746564"),
            Content = _H("4a657520656e20636f757273203a20") .. currentGame.name,
        })
    end

    PickerTab:CreateSection(_H("43686f6973697220756e206a6575"))

    for _, g in ipairs(GAMES) do
        local isCurrent = currentGame and currentGame.name == g.name
        PickerTab:CreateButton({
            Name = g.name .. (isCurrent and _H("2028656e20636f75727329") or ""),
            Callback = function()
                Window:Destroy()
                task.wait(0.1)

                local url = BASE_URL .. g.file
                local ok, src = pcall(function() return game:HttpGet(url) end)
                if not ok or not src or #src < 10 then
                    notify(_H("4b616e686120487562"), _H("4572726575722066657463683a20") .. g.name, 5)
                    return
                end

                local fn, err = loadstring(src)
                if not fn then
                    notify(_H("4b616e686120487562"), _H("45727265757220636f6d70696c653a20") .. tostring(err), 5)
                    return
                end

                local success, result = pcall(fn)
                if not success then
                    notify(_H("4b616e686120487562"), _H("45727265757220657865633a20") .. tostring(result), 5)
                end
            end,
        })
    end

    PickerTab:CreateSection(_H("496e666f73"))
    PickerTab:CreateButton({
        Name = _H("556e6c6f6164"),
        Callback = function() Window:Destroy() end,
    })

    Rayfield:Notify({
        Title = _H("4b616e686120487562"),
        Content = _H("43686f6973697320756e206a65752e"),
        Duration = 4,
    })
end

------------------------------------------------------------
-- Main
------------------------------------------------------------
if _G.KanhaLoaded then
    notify(_H("4b616e686120487562"), _H("44656a61206368617267652e"), 3)
    return
end
_G.KanhaLoaded = true

showGamePicker()
