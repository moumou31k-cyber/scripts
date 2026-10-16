local _H = function(h)
    local o = {}
    for i = 1, #h, 2 do
        o[#o + 1] = string.char(tonumber(h:sub(i, i+1), 16))
    end
    return table.concat(o)
end

local _SRV = "https://kanha-hub.loca.lt"
local _DISCORD = "https://discord.gg/n9vcsTdce"
local _BASE = "https://raw.githubusercontent.com/moumou31k-cyber/scripts/refs/heads/main/"

local GAMES = {
    {name = _H("526976616c73"),      file = _H("726976616c732e6c7561"),       placeIds = {17625359962}},
    {name = _H("417273656e616c"),    file = _H("617273656e616c2e6c7561"),     placeIds = {286090429}},
    {name = _H("4d4d32"),            file = _H("6d6d322e6c7561"),             placeIds = {142823291}},
}

local HttpService      = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local LocalPlayer      = game:GetService("Players").LocalPlayer
local PlayerGui        = LocalPlayer:WaitForChild("PlayerGui")

local function getHWID()
    local tries = {
        function() return gethwid and gethwid() end,
        function() return get_hwid and get_hwid() end,
        function() return syn and syn.get_hwid and syn.get_hwid() end,
        function() return KRNL_GET_HWID and KRNL_GET_HWID() end,
    }
    for _, f in ipairs(tries) do
        local ok, v = pcall(f)
        if ok and v and v ~= "" then return tostring(v) end
    end
    local ok, id = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if ok and id and id ~= "" then return "rbx-" .. tostring(id):sub(1, 24) end
    return "unknown-" .. tostring(math.random(1e6, 1e7))
end

local HWID = getHWID()

local function httpRequest(o)
    local fn = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
    if fn then
        local ok, r = pcall(fn, o)
        if ok and r then return {s = tonumber(r.StatusCode or r.Status) or 0, b = r.Body or r.body or ""} end
    end
    local ok, r = pcall(function()
        return HttpService:RequestAsync({Url = o.Url, Method = o.Method or "GET", Headers = o.Headers or {}, Body = o.Body})
    end)
    if ok and r then return {s = tonumber(r.StatusCode) or 0, b = r.Body or ""} end
    return {s = 0, b = ""}
end

local function validateKey(key)
    local res = httpRequest({
        Url = _SRV .. _H("2f76616c6964617465"),
        Method = _H("504f5354"),
        Headers = {
            [_H("436f6e74656e742d54797065")] = _H("6170706c69636174696f6e2f6a736f6e"),
            [_H("4279706173732d54756e6e656c2d52656d696e646572")] = _H("74727565"),
            [_H("557365722d4167656e74")] = _H("526f626c6f782f4b616e68614c6f61646572"),
        },
        Body = HttpService:JSONEncode({key = key, hwid = HWID}),
    })
    if res.s == 0 then return false, _H("5365727665757220696e6a6f69676e61626c652e"), nil end
    local ok, d = pcall(function() return HttpService:JSONDecode(res.b) end)
    if not ok or type(d) ~= "table" then return false, _H("52c3a9706f6e736520696e76616c6964652e"), nil end
    if d.ok ~= true then return false, tostring(d.msg or _H("436cc3a9207265667573c3a9652e")), nil end
    return true, "OK", {
        key = key,
        exp = tonumber(d.exp) or 0,
        tier = tostring(d.tier or _H("66726565")),
        sig = tostring(d.sig or ""),
        hwid = HWID,
    }
end

local CACHE = _H("6b68615f732e646174")

local function loadCache()
    if not (isfile and isfile(CACHE)) then return nil end
    local ok, raw = pcall(readfile, CACHE)
    if not ok or not raw then return nil end
    local ok2, d = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or type(d) ~= "table" or not d.k or not d.t then return nil end
    if os.time() - tonumber(d.t) > 86400 then pcall(delfile, CACHE); return nil end
    if d.h and d.h ~= HWID then pcall(delfile, CACHE); return nil end
    return d
end

local function saveCache(s)
    if writefile then
        pcall(writefile, CACHE, HttpService:JSONEncode({
            k = s.key, h = HWID, tier = s.tier, exp = s.exp, sig = s.sig, t = os.time()
        }))
    end
end

local function launchMenu(session, gameEntry)
    _G.KanhaSession = session
    _G.KanhaGame = gameEntry.name
    local url = _BASE .. gameEntry.file
    local src = game:HttpGet(url)
    loadstring(src)()
end

local function makeUIBase()
    local old = PlayerGui:FindFirstChild("KhaUI")
    if old then old:Destroy() end

    local g = Instance.new("ScreenGui")
    g.Name = "KhaUI"
    g.ResetOnSpawn = false
    g.IgnoreGuiInset = true
    g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    g.DisplayOrder = 9999
    g.Parent = PlayerGui

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
    bg.BackgroundTransparency = 0.12
    bg.BorderSizePixel = 0
    bg.Parent = g

    return g, bg
end

local function makeCard(parent, height)
    local c = Instance.new("Frame")
    c.Size = UDim2.new(0, 460, 0, height or 290)
    c.Position = UDim2.new(0.5, -230, 0.5, -(height or 290)/2)
    c.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
    c.BorderSizePixel = 0
    c.Parent = parent
    Instance.new("UICorner", c).CornerRadius = UDim.new(0, 14)

    local st = Instance.new("UIStroke")
    st.Color = Color3.fromRGB(80, 120, 220)
    st.Thickness = 1.5
    st.Transparency = 0.35
    st.Parent = c

    local ac = Instance.new("Frame")
    ac.Size = UDim2.new(1, -40, 0, 3)
    ac.Position = UDim2.new(0, 20, 0, 0)
    ac.BackgroundColor3 = Color3.fromRGB(90, 130, 230)
    ac.BorderSizePixel = 0
    ac.Parent = c
    Instance.new("UICorner", ac).CornerRadius = UDim.new(1, 0)

    local dragging, dragStart, startPos
    c.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = c.Position
        end
    end)
    c.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dragStart
            c.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)

    return c
end

local function fadeOutAll(gui, card, cb)
    local tw = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local bg = gui:FindFirstChildOfClass("Frame")
    if bg then TweenService:Create(bg, tw, {BackgroundTransparency = 1}):Play() end
    TweenService:Create(card, tw, {BackgroundTransparency = 1}):Play()
    for _, ch in ipairs(card:GetDescendants()) do
        if ch:IsA("TextLabel") or ch:IsA("TextButton") or ch:IsA("ImageLabel") then
            pcall(function() TweenService:Create(ch, tw, {TextTransparency = 1, ImageTransparency = 1}):Play() end)
        end
    end
    task.wait(0.4)
    gui:Destroy()
    if cb then cb() end
end

local function showKeyUI(onValidated)
    local g, bg = makeUIBase()
    local c = makeCard(g, 290)

    local ttl = Instance.new("TextLabel")
    ttl.Size = UDim2.new(1, 0, 0, 44)
    ttl.Position = UDim2.new(0, 0, 0, 22)
    ttl.BackgroundTransparency = 1
    ttl.Font = Enum.Font.GothamBold
    ttl.TextSize = 24
    ttl.TextColor3 = Color3.fromRGB(235, 240, 255)
    ttl.Text = _H("4b414e484120485542")
    ttl.Parent = c

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, 0, 0, 20)
    sub.Position = UDim2.new(0, 0, 0, 66)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 13
    sub.TextColor3 = Color3.fromRGB(150, 160, 180)
    sub.Text = _H("456e74726520746120636cc3a920706f757220636f6e74696e756572")
    sub.Parent = c

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -60, 0, 44)
    box.Position = UDim2.new(0, 30, 0, 108)
    box.BackgroundColor3 = Color3.fromRGB(30, 34, 46)
    box.BorderSizePixel = 0
    box.Font = Enum.Font.Code
    box.TextSize = 15
    box.TextColor3 = Color3.fromRGB(235, 240, 255)
    box.PlaceholderText = _H("4b414e48412d585858582d585858582d58585858")
    box.PlaceholderColor3 = Color3.fromRGB(90, 100, 125)
    box.Text = ""
    box.ClearTextOnFocus = false
    box.Parent = c
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)

    local stat = Instance.new("TextLabel")
    stat.Size = UDim2.new(1, -60, 0, 22)
    stat.Position = UDim2.new(0, 30, 0, 162)
    stat.BackgroundTransparency = 1
    stat.Font = Enum.Font.Gotham
    stat.TextSize = 12
    stat.TextColor3 = Color3.fromRGB(150, 160, 180)
    stat.Text = ""
    stat.TextXAlignment = Enum.TextXAlignment.Left
    stat.Parent = c

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -60, 0, 46)
    btn.Position = UDim2.new(0, 30, 0, 192)
    btn.BackgroundColor3 = Color3.fromRGB(60, 100, 200)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = _H("56414c49444552")
    btn.AutoButtonColor = false
    btn.Parent = c
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local gk = Instance.new("TextButton")
    gk.Size = UDim2.new(1, -60, 0, 18)
    gk.Position = UDim2.new(0, 30, 0, 252)
    gk.BackgroundTransparency = 1
    gk.Font = Enum.Font.Gotham
    gk.TextSize = 12
    gk.TextColor3 = Color3.fromRGB(100, 160, 255)
    gk.Text = _H("4f6274656e697220756e6520636cc3a920202020") .. _DISCORD
    gk.Parent = c

    local v = false
    local function setStat(t, col)
        stat.Text = t
        stat.TextColor3 = col or Color3.fromRGB(150, 160, 180)
    end

    local function attempt()
        if v then return end
        local k = box.Text:gsub("%s+", "")
        if k == "" then setStat(_H("456e74726520756e6520636cc3a92e"), Color3.fromRGB(230, 90, 90)); return end
        v = true
        btn.Text = _H("56c3a952494649434154494f4e2e2e2e")
        btn.BackgroundColor3 = Color3.fromRGB(80, 85, 100)
        setStat(_H("436f6e7461637420647520736572766575722e2e2e"), Color3.fromRGB(210, 200, 120))
        task.spawn(function()
            local ok, msg, s = validateKey(k)
            if ok then
                setStat(_H("e29c93") .. " " .. msg, Color3.fromRGB(90, 220, 130))
                btn.Text = _H("e29c93") .. " " .. _H("414343c38853204155544f524953c389")
                btn.BackgroundColor3 = Color3.fromRGB(50, 165, 95)
                saveCache(s)
                task.wait(0.7)
                fadeOutAll(g, c, function() onValidated(s) end)
            else
                setStat(_H("e29c97") .. " " .. msg, Color3.fromRGB(230, 90, 90))
                btn.Text = _H("56414c49444552")
                btn.BackgroundColor3 = Color3.fromRGB(60, 100, 200)
                v = false
            end
        end)
    end

    btn.MouseButton1Click:Connect(attempt)
    box.FocusLost:Connect(function(e) if e then attempt() end end)
    gk.MouseButton1Click:Connect(function()
        setStat(_H("436f7069c3a9"), Color3.fromRGB(150, 180, 240))
        if setclipboard then pcall(setclipboard, _DISCORD) end
    end)
    task.wait(0.15)
    box:CaptureFocus()
end

local function findCurrentGame()
    local placeId = game.PlaceId
    for _, g in ipairs(GAMES) do
        for _, id in ipairs(g.placeIds) do
            if id == placeId then return g end
        end
    end
    return nil
end

local function showGamePicker(session)
    local g, bg = makeUIBase()
    local cardHeight = 130 + (#GAMES * 56)
    local c = makeCard(g, cardHeight)

    local ttl = Instance.new("TextLabel")
    ttl.Size = UDim2.new(1, 0, 0, 44)
    ttl.Position = UDim2.new(0, 0, 0, 22)
    ttl.BackgroundTransparency = 1
    ttl.Font = Enum.Font.GothamBold
    ttl.TextSize = 24
    ttl.TextColor3 = Color3.fromRGB(235, 240, 255)
    ttl.Text = _H("43484f4953495320544f4e204a4555")
    ttl.Parent = c

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, 0, 0, 20)
    sub.Position = UDim2.new(0, 0, 0, 66)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 13
    sub.TextColor3 = Color3.fromRGB(150, 160, 180)
    sub.Text = _H("436c697175652073757220756e206a657520706f75722063686172676572206c65206d656e75")
    sub.Parent = c

    local current = findCurrentGame()
    local currentTag = _H("202020e280a2202020656e20636f757273")

    for i, gameEntry in ipairs(GAMES) do
        local y = 100 + ((i - 1) * 56)
        local isCurrent = (current and current.name == gameEntry.name)

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -60, 0, 44)
        btn.Position = UDim2.new(0, 30, 0, y)
        btn.BackgroundColor3 = isCurrent and Color3.fromRGB(70, 120, 220) or Color3.fromRGB(30, 34, 46)
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 15
        btn.TextColor3 = Color3.fromRGB(235, 240, 255)
        btn.Text = gameEntry.name .. (isCurrent and currentTag or "")
        btn.AutoButtonColor = false
        btn.Parent = c
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        btn.MouseButton1Click:Connect(function()
            btn.Text = _H("4348415247454d454e542e2e2e")
            btn.BackgroundColor3 = Color3.fromRGB(80, 85, 100)
            task.wait(0.2)
            fadeOutAll(g, c, function()
                launchMenu(session, gameEntry)
            end)
        end)

        btn.MouseEnter:Connect(function()
            if not isCurrent then
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(45, 50, 65)}):Play()
            end
        end)
        btn.MouseLeave:Connect(function()
            if not isCurrent then
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(30, 34, 46)}):Play()
            end
        end)
    end

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(1, -60, 0, 30)
    closeBtn.Position = UDim2.new(0, 30, 0, cardHeight - 42)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Font = Enum.Font.Gotham
    closeBtn.TextSize = 12
    closeBtn.TextColor3 = Color3.fromRGB(140, 150, 170)
    closeBtn.Text = _H("4665726d6572")
    closeBtn.Parent = c

    closeBtn.MouseButton1Click:Connect(function()
        g:Destroy()
    end)
end

local cached = loadCache()
if cached then
    task.spawn(function()
        local ok, _, s = validateKey(cached.k)
        if ok then
            saveCache(s)
            showGamePicker(s)
        else
            pcall(delfile, CACHE)
            showKeyUI(showGamePicker)
        end
    end)
else
    showKeyUI(showGamePicker)
end
