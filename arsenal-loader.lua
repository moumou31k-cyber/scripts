local _H = function(h)
    local o = {}
    for i = 1, #h, 2 do
        o[#o + 1] = string.char(tonumber(h:sub(i, i+1), 16))
    end
    return table.concat(o)
end

local _u1 = _H("68747470733a2f2f6b616e68612d6875622e6c6f63612e6c74")
local _u2 = _H("68747470733a2f2f7261772e67697468756275736572636f6e74656e742e636f6d2f6d6f756d6f7533316b2d63796265722f736372697074732f726566732f68656164732f6d61696e2f617273656e616c2e6c7561")
local _sc = _H("68747470733a2f2f646973636f72642e67672f6e3976637354646365")
local _cache = _H("6b68615f732e646174")
local _uiName = _H("4b68615549")

local _a = game:GetService(_H("4874747053657276696365"))
local _b = game:GetService(_H("55736572496e70757453657276696365"))
local _c = game:GetService(_H("547765656e53657276696365"))
local _d = game:GetService(_H("506c6179657273")).LocalPlayer
local _e = _d:WaitForChild(_H("506c61796572477569"))

local function _f()
    local t = {
        function() return gethwid and gethwid() end,
        function() return get_hwid and get_hwid() end,
        function() return syn and syn.get_hwid and syn.get_hwid() end,
        function() return KRNL_GET_HWID and KRNL_GET_HWID() end,
    }
    for _, g in ipairs(t) do
        local h, i = pcall(g)
        if h and i and i ~= "" then return tostring(i) end
    end
    local h, i = pcall(function()
        return game:GetService(_H("526278416e616c797469637353657276696365")):GetClientId()
    end)
    if h and i and i ~= "" then return _H("7262782d") .. tostring(i):sub(1, 24) end
    return _H("756e6b6e6f776e2d") .. tostring(math.random(1e6, 1e7))
end

local _hw = _f()

local function _g(o)
    local h = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
    if h then
        local i, j = pcall(h, o)
        if i and j then return {s = tonumber(j.StatusCode or j.Status) or 0, b = j.Body or j.body or ""} end
    end
    local i, j = pcall(function()
        return _a:RequestAsync({Url = o.Url, Method = o.Method or "GET", Headers = o.Headers or {}, Body = o.Body})
    end)
    if i and j then return {s = tonumber(j.StatusCode) or 0, b = j.Body or ""} end
    return {s = 0, b = ""}
end

local function _h(k)
    local r = _g({
        Url = _u1 .. _H("2f76616c6964617465"),
        Method = _H("504f5354"),
        Headers = {
            [_H("436f6e74656e742d54797065")] = _H("6170706c69636174696f6e2f6a736f6e"),
            [_H("4279706173732d54756e6e656c2d52656d696e646572")] = _H("74727565"),
            [_H("557365722d4167656e74")] = _H("526f626c6f782f4b616e68614c6f61646572"),
        },
        Body = _a:JSONEncode({key = k, hwid = _hw}),
    })
    if r.s == 0 then return false, _H("5365727665757220696e6a6f69676e61626c652e"), nil end
    local i, j = pcall(function() return _a:JSONDecode(r.b) end)
    if not i or type(j) ~= "table" then return false, _H("52c3a9706f6e736520696e76616c6964652e"), nil end
    if j.ok ~= true then return false, tostring(j.msg or _H("436cc3a9207265667573c3a9652e")), nil end
    return true, _H("4f4b"), {
        key = k,
        exp = tonumber(j.exp) or 0,
        tier = tostring(j.tier or _H("66726565")),
        sig = tostring(j.sig or ""),
        hwid = _hw,
    }
end

local function _i()
    if not (isfile and isfile(_cache)) then return nil end
    local h, i = pcall(readfile, _cache)
    if not h or not i then return nil end
    local j, k = pcall(function() return _a:JSONDecode(i) end)
    if not j or type(k) ~= "table" or not k.k or not k.t then return nil end
    if os.time() - tonumber(k.t) > 86400 then pcall(delfile, _cache); return nil end
    if k.h and k.h ~= _hw then pcall(delfile, _cache); return nil end
    return k
end

local function _j(s)
    if writefile then
        pcall(writefile, _cache, _a:JSONEncode({
            k = s.key, h = _hw, tier = s.tier, exp = s.exp, sig = s.sig, t = os.time()
        }))
    end
end

local function _k(s)
    _G.KanhaSession = s
    local h = game:HttpGet(_u2)
    loadstring(h)()
end

local function _l(cb)
    local old = _e:FindFirstChild(_uiName)
    if old then old:Destroy() end

    local g = Instance.new("ScreenGui")
    g.Name = _uiName
    g.ResetOnSpawn = false
    g.IgnoreGuiInset = true
    g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    g.DisplayOrder = 9999
    g.Parent = _e

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
    bg.BackgroundTransparency = 0.12
    bg.BorderSizePixel = 0
    bg.Parent = g

    local c = Instance.new("Frame")
    c.Size = UDim2.new(0, 460, 0, 290)
    c.Position = UDim2.new(0.5, -230, 0.5, -145)
    c.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
    c.BorderSizePixel = 0
    c.Parent = g
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

    local ttl = Instance.new("TextLabel")
    ttl.Size = UDim2.new(1, 0, 0, 44)
    ttl.Position = UDim2.new(0, 0, 0, 22)
    ttl.BackgroundTransparency = 1
    ttl.Font = Enum.Font.GothamBold
    ttl.TextSize = 24
    ttl.TextColor3 = Color3.fromRGB(235, 240, 255)
    ttl.Text = _H("4b414e4841204b45592053595354454d")
    ttl.Parent = c

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, 0, 0, 20)
    sub.Position = UDim2.new(0, 0, 0, 66)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 13
    sub.TextColor3 = Color3.fromRGB(150, 160, 180)
    sub.Text = _H("456e74726520746120636cc3a920706f757220616363c3a964657220617520736372697074")
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

    local bs = Instance.new("UIStroke")
    bs.Color = Color3.fromRGB(60, 70, 92)
    bs.Thickness = 1
    bs.Parent = box

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
    gk.Text = _H("4f6274656e697220756e6520636cc3a920202020646973636f72642e67672f6e3976637354646365")
    gk.Parent = c

    local dr, dS, sP
    ttl.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dr = true; dS = i.Position; sP = c.Position
        end
    end)
    ttl.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dr = false end
    end)
    _b.InputChanged:Connect(function(i)
        if dr and i.UserInputType == Enum.UserInputType.MouseMovement then
            local h = i.Position - dS
            c.Position = UDim2.new(sP.X.Scale, sP.X.Offset + h.X, sP.Y.Scale, sP.Y.Offset + h.Y)
        end
    end)

    local v = false
    local function _set(t, col)
        stat.Text = t
        stat.TextColor3 = col or Color3.fromRGB(150, 160, 180)
    end

    local function _out(s)
        local tw = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        _c:Create(bg, tw, {BackgroundTransparency = 1}):Play()
        _c:Create(c, tw, {BackgroundTransparency = 1}):Play()
        for _, ch in ipairs(c:GetDescendants()) do
            if ch:IsA("TextLabel") or ch:IsA("TextButton") then
                pcall(function() _c:Create(ch, tw, {TextTransparency = 1}):Play() end)
            end
        end
        task.wait(0.4)
        g:Destroy()
        if cb then cb(s) end
    end

    local function _att()
        if v then return end
        local k = box.Text:gsub("%s+", "")
        if k == "" then _set(_H("456e74726520756e6520636cc3a92e"), Color3.fromRGB(230, 90, 90)); return end
        v = true
        btn.Text = _H("56c3a952494649434154494f4e2e2e2e")
        btn.BackgroundColor3 = Color3.fromRGB(80, 85, 100)
        _set(_H("436f6e7461637420647520736572766575722e2e2e"), Color3.fromRGB(210, 200, 120))
        task.spawn(function()
            local ok, msg, s = _h(k)
            if ok then
                _set(_H("e29c93") .. msg, Color3.fromRGB(90, 220, 130))
                btn.Text = _H("e29c93") .. _H("20414343c38853204155544f524953c389")
                btn.BackgroundColor3 = Color3.fromRGB(50, 165, 95)
                _j(s)
                task.wait(0.7)
                _out(s)
            else
                _set(_H("e29c97") .. " " .. msg, Color3.fromRGB(230, 90, 90))
                btn.Text = _H("56414c49444552")
                btn.BackgroundColor3 = Color3.fromRGB(60, 100, 200)
                v = false
            end
        end)
    end

    btn.MouseButton1Click:Connect(_att)
    box.FocusLost:Connect(function(e) if e then _att() end end)
    gk.MouseButton1Click:Connect(function()
        _set(_H("436f7069c3a9"), Color3.fromRGB(150, 180, 240))
        if setclipboard then pcall(setclipboard, _sc) end
    end)
    task.wait(0.15)
    box:CaptureFocus()
end

local function _start()
    local cached = _i()
    if cached then
        task.spawn(function()
            local ok, _, s = _h(cached.k)
            if ok then
                _j(s)
                _k(s)
            else
                pcall(delfile, _cache)
                _l(_k)
            end
        end)
        return
    end
    _l(_k)
end

_start()
