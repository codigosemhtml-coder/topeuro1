local LoadingTick = os.clock()
if getgenv().Library then getgenv().Library:Unload() end

local Library do
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local HttpService = game:GetService("HttpService")
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
    local TextService = game:GetService("TextService")
    local CoreGui = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")
    gethui = gethui or function() return CoreGui end

    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera
    local Mouse = LocalPlayer:GetMouse()

    local FromRGB = Color3.fromRGB
    local UDim2New = UDim2.new
    local UDimNew = UDim.new
    local V2 = Vector2.new
    local InstanceNew = Instance.new

    Library = {
        Flags = {},
        MenuKeybind = tostring(Enum.KeyCode.RightShift),
        Tween = {Time = 0.25, Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out},
        Folders = {Directory = "testpath", Configs = "testpath/Configs", Assets = "testpath/Assets", Themes = "testpath/Themes"},
        Pages = {}, Sections = {},
        Connections = {}, Threads = {},
        ThemeMap = {}, ThemeItems = {},
        SetFlags = {}, CopiedColor = nil,
        UnnamedConnections = 0, UnnamedFlags = 0,
        Holder = nil, NotifHolder = nil, Font = nil, KeyList = nil,
    }

    local Keys = {
        ["Backspace"]="Back",["Tab"]="Tab",["Return"]="Return",["Escape"]="Escape",["Space"]="Space",
        ["RightShift"]="RightShift",["LeftShift"]="LeftShift",["RightControl"]="RControl",
        ["LeftControl"]="LControl",["LeftAlt"]="LAlt",["RightAlt"]="RAlt",
    }

    Library.__index = Library
    Library.Pages.__index = Library.Pages
    Library.Sections.__index = Library.Sections

    for _, f in Library.Folders do if not isfolder(f) then makefolder(f) end end

    -- ─── c0caine palette ───
    local C = {
        bg=FromRGB(15,14,19), side=FromRGB(11,10,15), surface=FromRGB(22,21,27),
        card=FromRGB(28,27,34), pop=FromRGB(20,19,26), hairline=FromRGB(30,29,36),
        edge=FromRGB(38,37,45), text=FromRGB(236,234,242), dim=FromRGB(161,157,173),
        muted=FromRGB(106,102,116), faint=FromRGB(74,71,82), off=FromRGB(38,36,46),
        knobOff=FromRGB(119,114,127), accent=FromRGB(173,102,255), accent2=FromRGB(103,52,244),
        danger=FromRGB(255,92,122), ok=FromRGB(69,223,160), warn=FromRGB(255,181,71),
    }
    Library.C = C

    local TW = {
        open=TweenInfo.new(0.32,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),
        close=TweenInfo.new(0.24,Enum.EasingStyle.Quart,Enum.EasingDirection.In),
        tab=TweenInfo.new(0.34,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),
        toggle=TweenInfo.new(0.26,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),
        knob=TweenInfo.new(0.22,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out),
        hover=TweenInfo.new(0.20,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out),
        lead=TweenInfo.new(0.24,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),
        trail=TweenInfo.new(0.42,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),
    }
    Library.TW = TW

    Library.Font = Font.fromEnum(Enum.Font.BuilderSansExtraBold)

    -- ─── helpers ───
    local function tw(obj, info, props)
        local t = TweenService:Create(obj, info, props); t:Play(); return t
    end
    local function corner(f, r)
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = f; return c
    end
    local function stroke(f, col, trans)
        local s = Instance.new("UIStroke"); s.Color = col or C.edge; s.Transparency = trans or 0
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = f; return s
    end
    local function grad(f, c1, c2, rot)
        local g = Instance.new("UIGradient"); g.Color = ColorSequence.new(c1, c2)
        g.Rotation = rot or 90; g.Parent = f; return g
    end
    local function frame(parent, bg)
        local f = Instance.new("Frame"); f.BorderSizePixel = 0
        if bg then f.BackgroundColor3 = bg else f.BackgroundTransparency = 1 end
        f.Parent = parent; return f
    end
    local function label(parent, text, size, color, font)
        local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1
        t.FontFace = font or Library.Font; t.TextSize = size; t.TextColor3 = color or C.text
        t.TextXAlignment = Enum.TextXAlignment.Left; t.Text = text or ""; t.Parent = parent
        return t
    end
    local function vlist(p, pad, horizontal)
        local l = Instance.new("UIListLayout"); l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Padding = UDim.new(0, pad or 0)
        if horizontal then l.FillDirection = Enum.FillDirection.Horizontal end
        l.Parent = p; return l
    end
    local function padding(p, t, r, b, l)
        local u = Instance.new("UIPadding"); u.PaddingTop = UDim.new(0, t); u.PaddingRight = UDim.new(0, r)
        u.PaddingBottom = UDim.new(0, b); u.PaddingLeft = UDim.new(0, l); u.Parent = p
    end
    Library.tw, Library.corner, Library.stroke, Library.grad = tw, corner, stroke, grad
    Library.frame, Library.label, Library.vlist, Library.padding = frame, label, vlist, padding

    local order = 0
    local function nextOrder() order += 1; return order end
    Library.nextOrder = nextOrder

    -- ─── connections ───
    Library.Connect = function(self, event, cb, name)
        local c = {Event=event, Callback=cb, Name=name or ("C"..HttpService:GenerateGUID(false)), Connection=nil}
        task.spawn(function() c.Connection = event:Connect(cb) end)
        table.insert(self.Connections, c); return c
    end
    Library.Thread = function(self, fn)
        local th = coroutine.create(fn); coroutine.wrap(function() coroutine.resume(th) end)()
        table.insert(self.Threads, th); return th
    end
    Library.Unload = function(self)
        for _, c in self.Connections do if c.Connection then pcall(c.Connection.Disconnect, c.Connection) end end
        for _, th in self.Threads do pcall(coroutine.close, th) end
        if self.Holder then self.Holder.Instance:Destroy() end
        Library = nil; getgenv().Library = nil
    end
    Library.NextFlag = function(self)
        self.UnnamedFlags += 1
        return ("Flag_%d_%s"):format(self.UnnamedFlags, HttpService:GenerateGUID(false))
    end
    Library.Round = function(self, n, f)
        local m = 1 / (f or 1); return math.floor(n * m + 0.5) / m
    end
    Library.ToRich = function(self, text, color)
        return ('<font color="rgb(%d, %d, %d)">%s</font>'):format(math.floor(color.R*255), math.floor(color.G*255), math.floor(color.B*255), text)
    end
    Library.IsMouseOverFrame = function(self, f)
        local p, s = f.AbsolutePosition, f.AbsoluteSize
        return Mouse.X >= p.X and Mouse.X <= p.X + s.X and Mouse.Y >= p.Y and Mouse.Y <= p.Y + s.Y
    end
    Library.SafeCall = function(self, fn, ...)
        local ok, res = pcall(fn, ...)
        if not ok then warn("[Library]", res) return false end
        return ok
    end

    -- Config/Theme helpers (unchanged API)
    Library.GetConfig = function(self)
        local cfg = {}
        for k, v in self.Flags do
            if type(v) == "table" and v.Key then cfg[k] = {Key=tostring(v.Key), Mode=v.Mode}
            elseif type(v) == "table" and v.Color then cfg[k] = {Color=v.HexValue, Alpha=v.Alpha}
            else cfg[k] = v end
        end
        return HttpService:JSONEncode(cfg)
    end
    Library.LoadConfig = function(self, s)
        local ok, d = pcall(HttpService.JSONDecode, HttpService, s); if not ok then return end
        for k, v in d do
            local set = self.SetFlags[k]; if not set then continue end
            if type(v) == "table" and v.Key then set(v)
            elseif type(v) == "table" and v.Color then set(v.Color, v.Alpha)
            else set(v) end
        end
        self:Notification("Config loaded", 3, C.ok)
    end
    Library.SaveConfig = function(self, name)
        if isfile(self.Folders.Configs.."/"..name) then
            writefile(self.Folders.Configs.."/"..name, self:GetConfig())
            self:Notification("Saved "..name, 3, C.ok)
        end
    end
    Library.DeleteConfig = function(self, name)
        if isfile(self.Folders.Configs.."/"..name) then delfile(self.Folders.Configs.."/"..name) end
    end
    Library.GetTheme = function(self)
        local t = {}
        for k, v in self.Flags do
            if type(v) == "table" and v.Color and string.find(v.Flag, "Theme") then t[k] = {Color=v.HexValue, Alpha=v.Alpha} end
        end
        return HttpService:JSONEncode(t)
    end
    Library.LoadTheme = function(self, s)
        local ok, d = pcall(HttpService.JSONDecode, HttpService, s); if not ok then return end
        for k, v in d do local set = self.SetFlags[k]; if set and v.Color then set(v.Color, v.Alpha) end end
    end
    Library.SaveTheme = function(self, name)
        if isfile(self.Folders.Themes.."/"..name) then writefile(self.Folders.Themes.."/"..name, self:GetTheme()) end
    end
    Library.DeleteTheme = function(self, name)
        if isfile(self.Folders.Themes.."/"..name) then delfile(self.Folders.Themes.."/"..name) end
    end
    Library.RefreshConfigsList = function(self, _) end
    Library.RefreshThemeList = function(self, _) end

    -- ScreenGui
    Library.Holder = {Instance = InstanceNew("ScreenGui")}
    Library.Holder.Instance.Name = "\0"
    Library.Holder.Instance.ZIndexBehavior = Enum.ZIndexBehavior.Global
    Library.Holder.Instance.IgnoreGuiInset = true
    Library.Holder.Instance.ResetOnSpawn = false
    Library.Holder.Instance.Parent = gethui()

    Library.NotifHolder = {Instance = frame(Library.Holder.Instance)}
    Library.NotifHolder.Instance.Name = "\0"
    Library.NotifHolder.Instance.AnchorPoint = V2(0.5, 0)
    Library.NotifHolder.Instance.Position = UDim2New(0.5, 0, 0, 0)
    Library.NotifHolder.Instance.Size = UDim2New(0.34, 0, 1, -14)
    local nl = vlist(Library.NotifHolder.Instance, 10)
    nl.VerticalAlignment = Enum.VerticalAlignment.Bottom
    nl.HorizontalAlignment = Enum.HorizontalAlignment.Center

    -- ─── WINDOW ───
    local MENU_W, MENU_H, RAIL_W, HEADER_H, LOGO_H, CARD_H = 820, 520, 184, 50, 58, 56

    local function makeWindow(Data)
        Data = Data or {}
        local Window = {
            Name = Data.Name or Data.name or "Window",
            Size = Data.Size or Data.size or UDim2New(0, MENU_W, 0, MENU_H),
            Pages = {}, Sections = {}, IsOpen = true,
            NavButtons = {}, NavSections = {}, CurrentPage = nil,
            ActiveConfig = nil,
        }

        -- host
        local host = frame(Library.Holder.Instance)
        host.Name = "CocaineHost"
        host.AnchorPoint = V2(0.5, 0.5)
        host.Position = UDim2New(0.5, 0, 0.5, 0)
        host.Size = Window.Size
        host.Visible = false
        host.ZIndex = 2
        Window.Host = host

        -- root (the visible window)
        local root = frame(host)
        root.Name = "Root"
        root.Size = UDim2New(1, 0, 1, 0)
        root.BackgroundColor3 = C.bg
        root.ZIndex = 1
        root.Active = true
        root.ClipsDescendants = true
        corner(root, 12)
        stroke(root, C.edge, 0)
        Window.Root = root

        -- drag by top-bar / logo (install later)
        local dragging, dragStart, startPos = false, nil, nil
        local function installDrag(g)
            g.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true; dragStart = i.Position; startPos = host.Position
                end
            end)
            g.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)
        end
        UserInputService.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                local d = i.Position - dragStart
                host.Position = UDim2New(0, startPos.X.Offset + d.X, 0, startPos.Y.Offset + d.Y)
            end
        end)

        -- ── sidebar ──
        local side = frame(root)
        side.Name = "Sidebar"
        side.Size = UDim2New(0, RAIL_W, 1, 0)
        side.BackgroundColor3 = C.side
        side.ZIndex = 2
        corner(side, 12)

        -- rail hairline (vertical)
        local railLine = frame(side)
        railLine.Size = UDim2New(0, 1, 1, 0)
        railLine.Position = UDim2New(1, -1, 0, 0)
        railLine.BackgroundColor3 = C.hairline
        railLine.ZIndex = 3

        -- logo area
        local logo = frame(side)
        logo.Name = "Logo"
        logo.Size = UDim2New(1, 0, 0, LOGO_H)
        logo.ZIndex = 4
        logo.Active = true
        installDrag(logo)
        local logoWord = label(logo, "", 22, C.text)
        logoWord.RichText = true
        logoWord.Text = ('c<font color="#%s">0</font>caine'):format(C.accent:ToHex())
        logoWord.FontFace = Font.fromEnum(Enum.Font.GothamBold)
        logoWord.AnchorPoint = V2(0, 0.5)
        logoWord.Position = UDim2New(0, 18, 0.5, 0)
        logoWord.Size = UDim2New(1, -18, 1, 0)
        logoWord.TextXAlignment = Enum.TextXAlignment.Left

        -- nav clip (contains pill)
        local navClip = frame(side)
        navClip.Name = "NavClip"
        navClip.Position = UDim2New(0, 0, 0, LOGO_H)
        navClip.Size = UDim2New(1, 0, 1, -LOGO_H - CARD_H)
        navClip.ClipsDescendants = true
        navClip.ZIndex = 3
        local pill = frame(navClip)
        pill.Name = "Pill"
        pill.BackgroundColor3 = C.card
        pill.BackgroundTransparency = 0.1
        pill.Size = UDim2New(1, -16, 0, 30)
        pill.Position = UDim2New(0, 8, 0, 6)
        pill.ZIndex = 3
        pill.Visible = false
        corner(pill, 6)
        stroke(pill, C.edge, 0.6)

        -- nav (scrolling)
        local nav = Instance.new("ScrollingFrame")
        nav.Name = "Nav"
        nav.Position = UDim2New(0, 0, 0, LOGO_H)
        nav.Size = UDim2New(1, 0, 1, -LOGO_H - CARD_H)
        nav.BackgroundTransparency = 1; nav.BorderSizePixel = 0
        nav.ScrollBarThickness = 2; nav.ScrollBarImageColor3 = C.faint
        nav.ScrollingDirection = Enum.ScrollingDirection.Y
        nav.AutomaticCanvasSize = Enum.AutomaticSize.Y
        nav.CanvasSize = UDim2New(0, 0, 0, 0)
        nav.ZIndex = 4; nav.Parent = side
        vlist(nav, 1)
        padding(nav, 0, 8, 6, 8)

        -- user card
        local card = frame(side)
        card.Name = "UserCard"
        card.Size = UDim2New(1, 0, 0, CARD_H)
        card.Position = UDim2New(0, 0, 1, -CARD_H)
        card.ZIndex = 8
        local cardLine = frame(card)
        cardLine.Size = UDim2New(1, 0, 0, 1)
        cardLine.BackgroundColor3 = C.hairline
        cardLine.ZIndex = 8

        local avatar = Instance.new("ImageLabel")
        avatar.Size = UDim2New(0, 28, 0, 28)
        avatar.AnchorPoint = V2(0, 0.5)
        avatar.Position = UDim2New(0, 14, 0.5, 0)
        avatar.BackgroundColor3 = C.surface
        avatar.Image = "rbxthumb://type=AvatarHeadShot&id="..LocalPlayer.UserId.."&w=48&h=48"
        avatar.ZIndex = 9; avatar.Parent = card
        corner(avatar, 14)
        stroke(avatar, C.edge, 0.3)

        local userName = label(card, LocalPlayer.DisplayName, 14, C.text)
        userName.FontFace = Font.fromEnum(Enum.Font.GothamBold)
        userName.Position = UDim2New(0, 50, 0, 11)
        userName.Size = UDim2New(1, -60, 0, 16)
        userName.TextTruncate = Enum.TextTruncate.AtEnd
        userName.ZIndex = 9
        local userSub = label(card, ("%s · v1.0"):format("lua"))
        userSub.Name = "Sub"
        userSub.Position = UDim2New(0, 50, 0, 28)
        userSub.Size = UDim2New(1, -60, 0, 14)
        userSub.TextColor3 = C.muted
        userSub.ZIndex = 9

        -- ── top bar ──
        local top = frame(root)
        top.Name = "TopBar"
        top.Size = UDim2New(1, -RAIL_W, 0, HEADER_H)
        top.Position = UDim2New(0, RAIL_W, 0, 0)
        top.ZIndex = 3
        top.Active = true
        installDrag(top)
        local topLine = frame(top)
        topLine.Size = UDim2New(1, 0, 0, 1)
        topLine.Position = UDim2New(0, 0, 1, -1)
        topLine.BackgroundColor3 = C.hairline
        topLine.ZIndex = 3

        local function topBtn(w, x, right)
            local b = Instance.new("TextButton")
            b.Size = UDim2New(0, w, 0, 28)
            b.AnchorPoint = V2(if right then 1 else 0, 0.5)
            b.Position = UDim2New(if right then 1 else 0, x, 0.5, 0)
            b.BackgroundColor3 = C.surface
            b.BorderSizePixel = 0; b.AutoButtonColor = false; b.Text = ""
            b.ZIndex = 4; b.Parent = top
            corner(b, 6); stroke(b, C.edge, 0)
            return b
        end

        local cfgBtn = topBtn(140, 16, false)
        local cfgLbl = label(cfgBtn, "No config", 13, C.muted)
        cfgLbl.Size = UDim2New(1, -30, 1, 0)
        cfgLbl.Position = UDim2New(0, 10, 0, 0)
        cfgLbl.TextTruncate = Enum.TextTruncate.AtEnd
        cfgLbl.ZIndex = 5
        local cfgChev = label(cfgBtn, "v", 10, C.muted)
        cfgChev.AnchorPoint = V2(1, 0.5)
        cfgChev.Position = UDim2New(1, -8, 0.5, 0)
        cfgChev.Size = UDim2New(0, 12, 0, 12)
        cfgChev.TextXAlignment = Enum.TextXAlignment.Center
        cfgChev.ZIndex = 5

        local saveBtn = topBtn(76, 164, false)
        local saveLbl = label(saveBtn, "save", 13, C.dim)
        saveLbl.Size = UDim2New(1, 0, 1, 0)
        saveLbl.TextXAlignment = Enum.TextXAlignment.Center
        saveLbl.ZIndex = 5

        local closeBtn = topBtn(28, -14, true)
        local closeLbl = label(closeBtn, "x", 14, C.muted)
        closeLbl.Size = UDim2New(1, 0, 1, 0)
        closeLbl.TextXAlignment = Enum.TextXAlignment.Center
        closeLbl.ZIndex = 5

        local setBtn = topBtn(28, -46, true)
        local setLbl = label(setBtn, "o", 14, C.muted)
        setLbl.Size = UDim2New(1, 0, 1, 0)
        setLbl.TextXAlignment = Enum.TextXAlignment.Center
        setLbl.ZIndex = 5

        local searchBox = frame(top, C.surface)
        searchBox.Size = UDim2New(0, 176, 0, 28)
        searchBox.AnchorPoint = V2(1, 0.5)
        searchBox.Position = UDim2New(1, -82, 0.5, 0)
        searchBox.ZIndex = 4
        corner(searchBox, 6); stroke(searchBox, C.edge, 0)
        local search = Instance.new("TextBox")
        search.Size = UDim2New(1, -24, 1, 0)
        search.Position = UDim2New(0, 12, 0, 0)
        search.BackgroundTransparency = 1; search.BorderSizePixel = 0
        search.FontFace = Library.Font; search.TextSize = 13; search.TextColor3 = C.text
        search.PlaceholderText = "search settings"; search.PlaceholderColor3 = C.muted
        search.Text = ""; search.ClearTextOnFocus = false
        search.TextXAlignment = Enum.TextXAlignment.Left
        search.ZIndex = 5; search.Parent = searchBox

        -- ── content area ──
        local content = frame(root)
        content.Name = "Content"
        content.Size = UDim2New(1, -RAIL_W, 1, -HEADER_H)
        content.Position = UDim2New(0, RAIL_W, 0, HEADER_H)
        content.ZIndex = 3
        content.ClipsDescendants = true

        Window.Items = {
            Gui = Library.Holder.Instance,
            Host = host, Root = root, Sidebar = side,
            Nav = nav, NavClip = navClip, Pill = pill,
            Top = top, Content = content,
        }

        -- ── behaviour ──
        local pillMoving = false
        local function movePill(navBtn, animate)
            if not navBtn then pill.Visible = false; return end
            local relY = navBtn.AbsolutePosition.Y - navClip.AbsolutePosition.Y - nav.AbsolutePosition.Y + navClip.AbsolutePosition.Y
            -- nav is inside navClip's parent (side), both share the same AbsolutePosition offset
            -- so relY = navBtn.AbsolutePosition.Y - nav.AbsolutePosition.Y - nav.Position.Y.Offset
            relY = navBtn.AbsolutePosition.Y - nav.AbsolutePosition.Y
            local relX = navBtn.AbsolutePosition.X - nav.AbsolutePosition.X
            local w, h = navBtn.AbsoluteSize.X, navBtn.AbsoluteSize.Y
            pill.Visible = true
            local goal = UDim2New(0, relX, 0, relY)
            local sizeGoal = UDim2New(0, w, 0, h)
            if animate and pillMoving == false then
                pillMoving = true
                tw(pill, TW.tab, {Position = goal, Size = sizeGoal}).Completed:Connect(function()
                    pillMoving = false
                end)
            else
                pill.Position = goal; pill.Size = sizeGoal
            end
        end

        function Window:ShowPage(pageName, animate)
            for name, page in pairs(self.Pages) do
                page:Turn(name == pageName)
            end
            self.CurrentPage = pageName
            local nb = self.NavButtons[pageName]
            if nb then movePill(nb, animate ~= false) end
        end

        -- menu open/close
        local function setOpen(bool)
            Window.IsOpen = bool
            if bool then
                host.Visible = true
                host.BackgroundTransparency = 1
                tw(host, TW.open, {BackgroundTransparency = 0})
                task.defer(function() if Window.CurrentPage then Window:ShowPage(Window.CurrentPage, false) end end)
            else
                tw(host, TW.close, {BackgroundTransparency = 1}).Completed:Connect(function(state)
                    if state == Enum.PlaybackState.Completed and not Window.IsOpen then
                        host.Visible = false
                        host.BackgroundTransparency = 1
                    end
                end)
            end
        end
        Window.SetOpen = setOpen

        closeBtn.MouseButton1Click:Connect(function() setOpen(false) end)
        closeBtn.MouseEnter:Connect(function() closeLbl.TextColor3 = C.text end)
        closeBtn.MouseLeave:Connect(function() closeLbl.TextColor3 = C.muted end)
        setBtn.MouseEnter:Connect(function() setLbl.TextColor3 = C.text end)
        setBtn.MouseLeave:Connect(function() setLbl.TextColor3 = C.muted end)

        -- config picker (list files)
        local function refreshCfgLabel()
            cfgLbl.Text = Window.ActiveConfig or "No config"
            cfgLbl.TextColor3 = Window.ActiveConfig and C.text or C.muted
        end
        refreshCfgLabel()

        local function closeDropdown()
            if Window._Dropdown then
                Window._Dropdown:Destroy(); Window._Dropdown = nil
            end
        end
        cfgBtn.MouseButton1Click:Connect(function()
            closeDropdown()
            local drop = frame(host, C.pop)
            drop.Name = "CfgDrop"
            drop.Size = UDim2New(0, 180, 0, 0)
            drop.AutomaticSize = Enum.AutomaticSize.Y
            drop.ZIndex = 60
            corner(drop, 8); stroke(drop, C.edge, 0)
            vlist(drop, 0); padding(drop, 6, 6, 6, 6)
            drop.Position = UDim2New(0, RAIL_W + 16, 0, HEADER_H + 4)
            Window._Dropdown = drop

            local files = {}
            pcall(function()
                if listfiles then
                    for _, f in ipairs(listfiles(Library.Folders.Configs) or {}) do
                        table.insert(files, f)
                    end
                end
            end)
            if #files == 0 then
                local e = label(drop, "no configs", 12, C.muted)
                e.Size = UDim2New(1, 0, 0, 22); e.TextXAlignment = Enum.TextXAlignment.Center
                e.ZIndex = 61
            else
                for _, path in ipairs(files) do
                    local name = path:match("([^/\\]+)$") or path
                    local b = Instance.new("TextButton")
                    b.Size = UDim2New(1, 0, 0, 24)
                    b.BackgroundColor3 = C.card; b.BackgroundTransparency = 1
                    b.BorderSizePixel = 0; b.AutoButtonColor = false; b.Text = ""
                    b.ZIndex = 61; b.Parent = drop
                    corner(b, 5)
                    local l = label(b, name, 12, C.dim)
                    l.Size = UDim2New(1, 0, 1, 0); l.Position = UDim2New(0, 8, 0, 0)
                    l.ZIndex = 62
                    b.MouseButton1Click:Connect(function()
                        Window.ActiveConfig = name
                        refreshCfgLabel()
                        local ok, contents = pcall(readfile, Library.Folders.Configs.."/"..name)
                        if ok and contents then pcall(function() Library:LoadConfig(contents) end) end
                        closeDropdown()
                    end)
                    b.MouseEnter:Connect(function()
                        b.BackgroundTransparency = 0
                        l.TextColor3 = C.text
                    end)
                    b.MouseLeave:Connect(function()
                        b.BackgroundTransparency = 1
                        l.TextColor3 = C.dim
                    end)
                end
            end

            -- click outside closes
            local conn
            conn = UserInputService.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 and Window._Dropdown then
                    if not Library:IsMouseOverFrame(Window._Dropdown) and not Library:IsMouseOverFrame(cfgBtn) then
                        closeDropdown()
                        conn:Disconnect()
                    end
                end
            end)
        end)

        saveBtn.MouseButton1Click:Connect(function()
            if Window.ActiveConfig then
                Library:SaveConfig(Window.ActiveConfig)
            else
                Library:Notification("Select a config first", 2, C.warn)
            end
        end)
        saveBtn.MouseEnter:Connect(function() saveBtn.BackgroundColor3 = C.card; saveLbl.TextColor3 = C.text end)
        saveBtn.MouseLeave:Connect(function() saveBtn.BackgroundColor3 = C.surface; saveLbl.TextColor3 = C.dim end)

        -- search filter (filters sections by name)
        local function filterSections()
            local q = string.lower(search.Text)
            for _, p in pairs(Window.Pages) do
                for _, s in ipairs(p.SectionList or {}) do
                    if not s.Frame then continue end
                    local show = q == "" or string.find(string.lower(s.Name or ""), q, 1, true) ~= nil
                    s.Frame.Visible = show
                end
            end
        end
        search:GetPropertyChangedSignal("Text"):Connect(filterSections)

        -- global menu key (RightShift or Ctrl+O)
        local function isMenuKey(i)
            if i.KeyCode == Enum.KeyCode.RightShift then return true end
            if i.KeyCode == Enum.KeyCode.O and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
                return true
            end
            return false
        end
        Library:Connect(UserInputService.InputBegan, function(i, gp)
            if gp then return end
            if isMenuKey(i) then setOpen(not Window.IsOpen) end
        end)

        -- show
        setOpen(true)
        task.delay(0.1, function() setOpen(true) end)
        return Window
    end

    -- ─── PAGE ───
    local function makePage(Window, Data)
        Data = Data or {}
        local Page = {
            Window = Window,
            Name = Data.Name or Data.name or "Page",
            Columns = Data.Columns or Data.columns or 2,
            Section = Data.Section or Data.section or "Other",
            ColumnsData = {}, SectionList = {}, Active = false,
        }

        -- nav section caption
        local side = Window.Items.Sidebar
        local nav = Window.Items.Nav
        local lastSection
        local sectionsList = Window.NavSections
        if #sectionsList == 0 or sectionsList[#sectionsList].Name ~= Page.Section then
            local cap = label(nav, string.lower(Page.Section), 11, C.muted)
            cap.Size = UDim2New(1, 0, 0, 24)
            cap.LayoutOrder = nextOrder()
            cap.TextXAlignment = Enum.TextXAlignment.Left
            cap.TextYAlignment = Enum.TextYAlignment.Bottom
            padding(cap, 0, 0, 4, 10)
            cap.ZIndex = 5
            table.insert(sectionsList, {Name = Page.Section, Caption = cap})
        end

        -- nav button
        local navBtn = Instance.new("TextButton")
        navBtn.Name = "Nav_"..Page.Name
        navBtn.Size = UDim2New(1, 0, 0, 30)
        navBtn.BackgroundColor3 = C.surface
        navBtn.BackgroundTransparency = 1
        navBtn.BorderSizePixel = 0; navBtn.AutoButtonColor = false; navBtn.Text = ""
        navBtn.LayoutOrder = nextOrder()
        navBtn.ZIndex = 5; navBtn.Parent = nav
        corner(navBtn, 6)
        local navLbl = label(navBtn, string.lower(Page.Name), 13, C.dim)
        navLbl.Position = UDim2New(0, 12, 0, 0)
        navLbl.Size = UDim2New(1, -24, 1, 0)
        navLbl.TextYAlignment = Enum.TextYAlignment.Center
        navLbl.ZIndex = 5
        Window.NavButtons[Page.Name] = navBtn

        -- hover
        navBtn.MouseEnter:Connect(function()
            if not Page.Active then navBtn.BackgroundTransparency = 0.94 end
        end)
        navBtn.MouseLeave:Connect(function()
            if not Page.Active then navBtn.BackgroundTransparency = 1 end
        end)
        navBtn.MouseButton1Click:Connect(function()
            Window:ShowPage(Page.Name, true)
        end)

        -- content frame (page)
        local content = Window.Items.Content
        local pageFrame = frame(content)
        pageFrame.Name = "Page_"..Page.Name
        pageFrame.Size = UDim2New(1, 0, 1, 0)
        pageFrame.Visible = false
        pageFrame.ZIndex = 3
        Page.Frame = pageFrame

        -- scrolling with 1 or 2 columns
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2New(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 4; scroll.ScrollBarImageColor3 = C.faint
        scroll.ScrollBarImageTransparency = 0.1
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.CanvasSize = UDim2New(0, 0, 0, 0)
        scroll.Parent = pageFrame
        padding(scroll, 14, 18, 10, 18)
        Page.Scroll = scroll

        local function makeCol(xScale, xOffset)
            local col = frame(scroll)
            col.Size = UDim2New(xScale, xOffset, 0, 0)
            col.AutomaticSize = Enum.AutomaticSize.Y
            col.ZIndex = 3
            vlist(col, 12)
            return col
        end
        if Page.Columns == 1 then
            Page.ColumnsData[1] = makeCol(1, 0)
        else
            Page.ColumnsData[1] = makeCol(0.5, -30)
            Page.ColumnsData[2] = makeCol(0.5, -30)
            Page.ColumnsData[2].Position = UDim2New(0.5, 12, 0, 0)
        end

        function Page:Turn(bool)
            Page.Active = bool
            pageFrame.Visible = bool
            navBtn.BackgroundTransparency = if bool then 0 else 1
            navLbl.TextColor3 = if bool then C.text else C.dim
        end

        function Page:Column(i) return Page.ColumnsData[i] end

        table.insert(Window.Pages, Page)
        -- first page → show
        if #Window.Pages == 1 then
            Window:ShowPage(Page.Name, false)
        end

        return setmetatable(Page, Library.Pages)
    end

    -- ─── SECTION (card) ───
    local function makeSection(Page, Data)
        Data = Data or {}
        local Section = {
            Page = Page, Window = Page.Window,
            Name = Data.Name or Data.name or "Section",
            Side = Data.Side or Data.side or 1,
        }
        local col = Page.ColumnsData[Section.Side] or Page.ColumnsData[1]
        if not col then return end

        -- card
        local card = frame(col, C.surface)
        card.Name = "Section_"..Section.Name
        card.Size = UDim2New(1, 0, 0, 0)
        card.AutomaticSize = Enum.AutomaticSize.Y
        card.LayoutOrder = nextOrder()
        card.ZIndex = 3
        corner(card, 10); stroke(card, C.hairline, 0)
        vlist(card, 0); padding(card, 0, 10, 8, 10)

        -- header (title + hairline)
        local head = frame(card)
        head.Size = UDim2New(1, 0, 0, 30)
        head.LayoutOrder = nextOrder()
        head.ZIndex = 3
        local title = label(head, string.lower(Section.Name), 13, C.dim)
        title.FontFace = Font.fromEnum(Enum.Font.GothamBold)
        title.Size = UDim2New(1, 0, 1, 0)
        title.ZIndex = 4

        local hair = frame(card)
        hair.Size = UDim2New(1, 20, 0, 1)
        hair.Position = UDim2New(0, -10, 0, 30)
        hair.BackgroundColor3 = C.hairline
        hair.ZIndex = 3

        -- content
        local content = frame(card)
        content.Name = "Content"
        content.Size = UDim2New(1, 0, 0, 0)
        content.AutomaticSize = Enum.AutomaticSize.Y
        content.LayoutOrder = nextOrder()
        content.ZIndex = 3
        vlist(content, 6)
        padding(content, 4, 0, 0, 0)

        Section.Frame = card
        Section.Content = content
        table.insert(Page.SectionList, Section)

        -- ── Controls ──
        local function ensureSpace()
            local spacer = frame(content)
            spacer.Size = UDim2New(1, 0, 0, 2)
            spacer.LayoutOrder = nextOrder()
        end

        -- Toggle (pill)
        function Section:Toggle(d)
            d = d or {}
            local flag = d.Flag or d.flag or Library:NextFlag()
            local Tog = {Value = d.Default or d.default or false, Flag = flag}
            local row = Instance.new("TextButton")
            row.Name = "Toggle"
            row.Size = UDim2New(1, 0, 0, 26)
            row.BackgroundColor3 = C.card
            row.BackgroundTransparency = 1
            row.BorderSizePixel = 0; row.AutoButtonColor = false; row.Text = ""
            row.LayoutOrder = nextOrder(); row.ZIndex = 4; row.Parent = content
            corner(row, 4)

            local txt = label(row, string.lower(d.Name or "Toggle"), 13, C.text)
            txt.Size = UDim2New(1, -50, 1, 0)
            txt.Position = UDim2New(0, 6, 0, 0)
            txt.TextYAlignment = Enum.TextYAlignment.Center
            txt.ZIndex = 5

            -- pill switch (28×16)
            local pill = frame(row, C.off)
            pill.Size = UDim2New(0, 28, 0, 16)
            pill.AnchorPoint = V2(1, 0.5)
            pill.Position = UDim2New(1, -2, 0.5, 0)
            pill.ZIndex = 5
            corner(pill, 8); stroke(pill, C.edge, 0.4)

            local fill = frame(pill, C.accent)
            fill.Size = UDim2New(1, 0, 1, 0); fill.BackgroundTransparency = 1
            fill.ZIndex = 5; corner(fill, 8)
            grad(fill, C.accent2, C.accent, 90)

            local knob = frame(pill, C.knobOff)
            knob.Size = UDim2New(0, 12, 0, 12)
            knob.AnchorPoint = V2(0, 0.5)
            knob.Position = UDim2New(0, 2, 0.5, 0)
            knob.ZIndex = 6; corner(knob, 6)

            local function set(bool, animate)
                Tog.Value = bool
                Library.Flags[flag] = bool
                if bool then
                    if animate then
                        tw(knob, TW.knob, {Position = UDim2New(1, -14, 0.5, 0), BackgroundColor3 = Color3.new(1,1,1)})
                        tw(fill, TW.toggle, {BackgroundTransparency = 0})
                        tw(txt, TW.hover, {TextColor3 = C.text})
                    else
                        knob.Position = UDim2New(1, -14, 0.5, 0); knob.BackgroundColor3 = Color3.new(1,1,1)
                        fill.BackgroundTransparency = 0; txt.TextColor3 = C.text
                    end
                else
                    if animate then
                        tw(knob, TW.knob, {Position = UDim2New(0, 2, 0.5, 0), BackgroundColor3 = C.knobOff})
                        tw(fill, TW.toggle, {BackgroundTransparency = 1})
                        tw(txt, TW.hover, {TextColor3 = C.dim})
                    else
                        knob.Position = UDim2New(0, 2, 0.5, 0); knob.BackgroundColor3 = C.knobOff
                        fill.BackgroundTransparency = 1; txt.TextColor3 = C.dim
                    end
                end
                if d.Callback or d.callback then Library:SafeCall(d.Callback or d.callback, bool) end
            end
            Tog.Set = set
            Tog.Get = function() return Tog.Value end
            set(d.Default or d.default or false, false)
            row.MouseButton1Click:Connect(function() set(not Tog.Value, true) end)
            Library.SetFlags[flag] = function(v) set(v, true) end
            return Tog
        end

        -- Button
        function Section:Button(d)
            d = d or {}
            local row = Instance.new("TextButton")
            row.Size = UDim2New(1, 0, 0, 26)
            row.BackgroundColor3 = C.card
            row.BorderSizePixel = 0; row.AutoButtonColor = false; row.Text = ""
            row.LayoutOrder = nextOrder(); row.ZIndex = 4; row.Parent = content
            corner(row, 6); stroke(row, C.hairline, 0)

            local txt = label(row, string.lower(d.Name or "Button"), 13, C.dim)
            txt.Size = UDim2New(1, 0, 1, 0)
            txt.TextXAlignment = Enum.TextXAlignment.Center
            txt.ZIndex = 5

            row.MouseEnter:Connect(function()
                tw(row, TW.hover, {BackgroundColor3 = C.edge})
                txt.TextColor3 = C.text
            end)
            row.MouseLeave:Connect(function()
                tw(row, TW.hover, {BackgroundColor3 = C.card})
                txt.TextColor3 = C.dim
            end)
            row.MouseButton1Click:Connect(function()
                if d.Callback or d.callback then Library:SafeCall(d.Callback or d.callback) end
            end)

            local Btn = {}
            Btn.SetVisibility = function(_, b) row.Visible = b end
            Btn.SubButton = function(_, sd)
                sd = sd or {}
                -- split into two buttons
                row.Size = UDim2New(0.48, 0, 0, 26)
                local srow = Instance.new("TextButton")
                srow.Size = UDim2New(0.48, 0, 0, 26)
                srow.Position = UDim2New(0.52, 0, 0, 0)
                srow.BackgroundColor3 = C.card; srow.BorderSizePixel = 0; srow.AutoButtonColor = false; srow.Text = ""
                srow.LayoutOrder = row.LayoutOrder; srow.ZIndex = 4; srow.Parent = content
                corner(srow, 6); stroke(srow, C.hairline, 0)
                local stxt = label(srow, string.lower(sd.Name or "Button"), 13, C.dim)
                stxt.Size = UDim2New(1, 0, 1, 0); stxt.TextXAlignment = Enum.TextXAlignment.Center; stxt.ZIndex = 5
                srow.MouseEnter:Connect(function() tw(srow, TW.hover, {BackgroundColor3 = C.edge}); stxt.TextColor3 = C.text end)
                srow.MouseLeave:Connect(function() tw(srow, TW.hover, {BackgroundColor3 = C.card}); stxt.TextColor3 = C.dim end)
                srow.MouseButton1Click:Connect(function() if sd.Callback or sd.callback then Library:SafeCall(sd.Callback or sd.callback) end end)
                return {SetVisibility = function(_, b) srow.Visible = b end}
            end
            return Btn
        end

        -- Slider (thin rail)
        function Section:Slider(d)
            d = d or {}
            local flag = d.Flag or d.flag or Library:NextFlag()
            local min = d.Min or d.min or 0
            local max = d.Max or d.max or 100
            local default = d.Default or d.default or 0
            local decimals = d.Decimals or d.decimals or 1
            local suffix = d.Suffix or d.suffix or ""

            local Sld = {Value = default, Flag = flag}
            local row = frame(content, nil)
            row.Size = UDim2New(1, 0, 0, 32)
            row.LayoutOrder = nextOrder(); row.ZIndex = 4

            local txt = label(row, string.lower(d.Name or "Slider"), 13, C.text)
            txt.Size = UDim2New(1, -60, 0, 14)
            txt.Position = UDim2New(0, 6, 0, 0)
            txt.ZIndex = 5

            local valTxt = label(row, "", 12, C.dim)
            valTxt.Size = UDim2New(0, 60, 0, 14)
            valTxt.Position = UDim2New(1, -60, 0, 0)
            valTxt.TextXAlignment = Enum.TextXAlignment.Right
            valTxt.ZIndex = 5

            -- rail (thin 4px)
            local rail = Instance.new("TextButton")
            rail.Size = UDim2New(1, -12, 0, 4)
            rail.Position = UDim2New(0, 6, 0, 22)
            rail.BackgroundColor3 = C.off
            rail.BorderSizePixel = 0; rail.AutoButtonColor = false; rail.Text = ""
            rail.ZIndex = 4; rail.Parent = row
            corner(rail, 2)

            local fill = frame(rail, C.accent)
            fill.Size = UDim2New(0, 0, 1, 0); fill.ZIndex = 5
            corner(fill, 2); grad(fill, C.accent2, C.accent, 0)

            local knob = frame(rail, Color3.new(1,1,1))
            knob.Size = UDim2New(0, 10, 0, 10)
            knob.AnchorPoint = V2(0.5, 0.5)
            knob.Position = UDim2New(0, 0, 0.5, 0)
            knob.ZIndex = 6; corner(knob, 5)
            stroke(knob, C.accent, 1)

            local sliding = false
            local function set(v, animate)
                v = math.clamp(Library:Round(v, decimals), min, max)
                Sld.Value = v
                Library.Flags[flag] = v
                local ratio = (v - min) / (max - min)
                local goal = UDim2New(ratio, 0, 0.5, 0)
                if animate then
                    tw(knob, TW.knob, {Position = goal})
                    tw(fill, TW.knob, {Size = UDim2New(ratio, 0, 1, 0)})
                else
                    knob.Position = goal
                    fill.Size = UDim2New(ratio, 0, 1, 0)
                end
                valTxt.Text = ("%s%s"):format(tostring(v), suffix)
                if d.Callback or d.callback then Library:SafeCall(d.Callback or d.callback, v) end
            end
            Sld.Set = set
            Sld.Get = function() return Sld.Value end
            set(default, false)
            rail.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    local ratio = (Mouse.X - rail.AbsolutePosition.X) / rail.AbsoluteSize.X
                    set(min + (max - min) * ratio, false)
                end
            end)
            Library:Connect(UserInputService.InputEnded, function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
            end)
            Library:Connect(UserInputService.InputChanged, function(i)
                if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                    local ratio = (Mouse.X - rail.AbsolutePosition.X) / rail.AbsoluteSize.X
                    set(min + (max - min) * ratio, false)
                end
            end)
            Library.SetFlags[flag] = function(v) set(v, true) end
            return Sld
        end

        -- Dropdown
        function Section:Dropdown(d)
            d = d or {}
            local flag = d.Flag or d.flag or Library:NextFlag()
            local DD = {Value = nil, Flag = flag, Options = {}, IsOpen = false}
            local row = frame(content, nil)
            row.Size = UDim2New(1, 0, 0, 24)
            row.LayoutOrder = nextOrder(); row.ZIndex = 4
            local txt = label(row, string.lower(d.Name or "Dropdown"), 13, C.text)
            txt.Size = UDim2New(1, -120, 1, 0)
            txt.Position = UDim2New(0, 6, 0, 0)
            txt.TextYAlignment = Enum.TextYAlignment.Center
            txt.ZIndex = 5

            local box = Instance.new("TextButton")
            box.Size = UDim2New(0, 112, 0, 22)
            box.AnchorPoint = V2(1, 0.5)
            box.Position = UDim2New(1, -2, 0.5, 0)
            box.BackgroundColor3 = C.surface
            box.BorderSizePixel = 0; box.AutoButtonColor = false; box.Text = ""
            box.ZIndex = 4; box.Parent = row
            corner(box, 5); stroke(box, C.edge, 0)

            local val = label(box, "--", 12, C.text)
            val.Size = UDim2New(1, -20, 1, 0)
            val.Position = UDim2New(0, 8, 0, 0)
            val.TextYAlignment = Enum.TextYAlignment.Center
            val.TextTruncate = Enum.TextTruncate.AtEnd
            val.ZIndex = 5
            local chev = label(box, "v", 10, C.muted)
            chev.AnchorPoint = V2(1, 0.5)
            chev.Position = UDim2New(1, -6, 0.5, 0)
            chev.Size = UDim2New(0, 12, 0, 12)
            chev.TextXAlignment = Enum.TextXAlignment.Center
            chev.ZIndex = 5

            local function toggleOpen()
                DD.IsOpen = not DD.IsOpen
                if not DD.IsOpen then
                    if DD.Popup then DD.Popup:Destroy(); DD.Popup = nil end
                    return
                end
                local pop = frame(row.Parent.Parent, C.pop)
                pop.Size = UDim2New(0, 112, 0, #d.Items * 22 + 8)
                pop.Position = UDim2New(0, 0, 0, box.AbsolutePosition.Y - box.Parent.Parent.AbsolutePosition.Y + 24)
                pop.ZIndex = 50
                corner(pop, 6); stroke(pop, C.edge, 0)
                pop.Parent = row.Parent.Parent

                for i, item in ipairs(d.Items or {}) do
                    local opt = Instance.new("TextButton")
                    opt.Size = UDim2New(1, -8, 0, 20)
                    opt.Position = UDim2New(0, 4, 0, 4 + (i-1) * 20)
                    opt.BackgroundColor3 = C.card; opt.BackgroundTransparency = 1
                    opt.BorderSizePixel = 0; opt.AutoButtonColor = false; opt.Text = ""
                    opt.ZIndex = 51; opt.Parent = pop
                    corner(opt, 4)
                    local ol = label(opt, tostring(item), 12, C.dim)
                    ol.Size = UDim2New(1, 0, 1, 0); ol.Position = UDim2New(0, 8, 0, 0)
                    ol.TextYAlignment = Enum.TextYAlignment.Center
                    ol.ZIndex = 52
                    opt.MouseButton1Click:Connect(function()
                        DD.Value = item
                        Library.Flags[flag] = item
                        val.Text = tostring(item)
                        if d.Callback or d.callback then Library:SafeCall(d.Callback or d.callback, item) end
                        toggleOpen()
                    end)
                    opt.MouseEnter:Connect(function() opt.BackgroundTransparency = 0; ol.TextColor3 = C.text end)
                    opt.MouseLeave:Connect(function() opt.BackgroundTransparency = 1; ol.TextColor3 = C.dim end)
                end
                DD.Popup = pop
            end
            box.MouseButton1Click:Connect(toggleOpen)
            DD.Set = function(_, v)
                DD.Value = v; Library.Flags[flag] = v
                val.Text = tostring(v)
                if d.Callback or d.callback then Library:SafeCall(d.Callback or d.callback, v) end
            end
            DD.Get = function() return DD.Value end
            DD.Add = function(_, v)
                table.insert(d.Items, v)
            end
            DD.Remove = function(_, v)
                for i, x in ipairs(d.Items) do if x == v then table.remove(d.Items, i); break end end
            end
            DD.Refresh = function(_, list)
                d.Items = list
            end
            if d.Default or d.default then DD:Set(d.Default or d.default) end
            Library.SetFlags[flag] = function(v) DD:Set(v) end
            return DD
        end

        -- Textbox
        function Section:Textbox(d)
            d = d or {}
            local flag = d.Flag or d.flag or Library:NextFlag()
            local TB = {Value = d.Default or d.default or "", Flag = flag}
            local row = frame(content, nil)
            row.Size = UDim2New(1, 0, 0, 38)
            row.LayoutOrder = nextOrder(); row.ZIndex = 4
            local txt = label(row, string.lower(d.Name or "Textbox"), 13, C.text)
            txt.Size = UDim2New(1, 0, 0, 14)
            txt.Position = UDim2New(0, 6, 0, 0)
            txt.ZIndex = 5

            local bg = frame(row, C.surface)
            bg.Size = UDim2New(1, -12, 0, 20)
            bg.Position = UDim2New(0, 6, 0, 16)
            bg.ZIndex = 4
            corner(bg, 5); stroke(bg, C.edge, 0)

            local tb = Instance.new("TextBox")
            tb.Size = UDim2New(1, -12, 1, 0)
            tb.Position = UDim2New(0, 6, 0, 0)
            tb.BackgroundTransparency = 1; tb.BorderSizePixel = 0
            tb.FontFace = Library.Font; tb.TextSize = 13; tb.TextColor3 = C.text
            tb.PlaceholderText = d.Placeholder or d.placeholder or "..."; tb.PlaceholderColor3 = C.muted
            tb.Text = TB.Value; tb.ClearTextOnFocus = false
            tb.TextXAlignment = Enum.TextXAlignment.Left
            tb.ZIndex = 5; tb.Parent = bg

            local function set(v)
                TB.Value = tostring(v); Library.Flags[flag] = TB.Value; tb.Text = TB.Value
                if d.Callback or d.callback then Library:SafeCall(d.Callback or d.callback, TB.Value) end
            end
            TB.Set = set
            TB.Get = function() return TB.Value end
            tb.FocusLost:Connect(function() set(tb.Text) end)
            Library.SetFlags[flag] = function(v) set(v) end
            return TB
        end

        -- Label
        function Section:Label(text, align)
            local L = {Name = text or "Label", Alignment = align or "Left"}
            local row = frame(content, nil)
            row.Size = UDim2New(1, 0, 0, 16)
            row.LayoutOrder = nextOrder(); row.ZIndex = 4
            local t = label(row, text or "", 12, C.dim)
            t.Size = UDim2New(1, 0, 1, 0)
            t.TextXAlignment = Enum.TextXAlignment[L.Alignment] or Enum.TextXAlignment.Left
            t.RichText = true
            t.ZIndex = 5
            L.SetVisibility = function(_, b) row.Visible = b end
            L.Colorpicker = function(self2, cd)
                cd = cd or {}
                local cflag = cd.Flag or cd.flag or Library:NextFlag()
                local CP = {Flag = cflag, Color = cd.Default or cd.default or Color3.new(1,1,1), Alpha = cd.Alpha or cd.alpha or 0}
                local sw = Instance.new("TextButton")
                sw.Size = UDim2New(0, 20, 0, 14)
                sw.AnchorPoint = V2(1, 0.5)
                sw.Position = UDim2New(1, -6, 0.5, 0)
                sw.BackgroundColor3 = CP.Color; sw.BorderSizePixel = 0; sw.AutoButtonColor = false; sw.Text = ""
                sw.ZIndex = 5; sw.Parent = row
                corner(sw, 4); stroke(sw, C.edge, 0.3)
                CP.Set = function(_, c, a)
                    CP.Color = c; CP.Alpha = a or CP.Alpha
                    sw.BackgroundColor3 = c
                    Library.Flags[cflag] = {HexValue = c:ToHex(), Color = c, Alpha = CP.Alpha, Flag = cflag}
                    if cd.Callback or cd.callback then Library:SafeCall(cd.Callback or cd.callback, c, CP.Alpha) end
                end
                CP.Get = function() return CP.Color, CP.Alpha end
                CP.SetVisibility = function(_, b) sw.Visible = b end
                sw.MouseButton1Click:Connect(function()
                    -- Cycle through a few preset colors on click (simplified picker)
                    local current = CP.Color
                    local h, s, v = current:ToHSV()
                    h = (h + 0.08) % 1
                    CP:Set(Color3.fromHSV(h, s, v), CP.Alpha)
                end)
                Library.SetFlags[cflag] = function(c, a) CP:Set(c, a) end
                return CP
            end
            L.Keybind = function(self2, kd)
                kd = kd or {}
                local kflag = kd.Flag or kd.flag or Library:NextFlag()
                local KB = {Toggled = false, Key = tostring(kd.Default or kd.default or Enum.KeyCode.Unknown), Mode = kd.Mode or kd.mode or "Toggle", Flag = kflag, Value = ""}
                local kbBtn = Instance.new("TextButton")
                kbBtn.Size = UDim2New(0, 32, 0, 16)
                kbBtn.AnchorPoint = V2(1, 0.5)
                kbBtn.Position = UDim2New(1, -6, 0.5, 0)
                kbBtn.BackgroundColor3 = C.card; kbBtn.BorderSizePixel = 0
                kbBtn.AutoButtonColor = false; kbBtn.Text = "-"
                kbBtn.FontFace = Library.Font; kbBtn.TextSize = 11; kbBtn.TextColor3 = C.text
                kbBtn.ZIndex = 5; kbBtn.Parent = row
                corner(kbBtn, 4); stroke(kbBtn, C.edge, 0.4)
                local function set(k)
                    if type(k) == "EnumItem" then
                        KB.Key = tostring(k); KB.Value = k.Name
                        kbBtn.Text = k.Name
                    elseif type(k) == "table" then
                        if k.Key then KB.Key = tostring(k.Key); KB.Value = tostring(k.Key):gsub("Enum.", ""):gsub("KeyCode.", "") end
                        if k.Mode then KB.Mode = k.Mode end
                        kbBtn.Text = KB.Value
                    end
                    Library.Flags[kflag] = {Key = KB.Key, Mode = KB.Mode, Toggled = KB.Toggled}
                    if kd.Callback or kd.callback then Library:SafeCall(kd.Callback or kd.callback, KB.Toggled) end
                end
                KB.Set = set
                KB.Get = function() return KB.Toggled, KB.Key, KB.Mode end
                KB.SetVisibility = function(_, b) kbBtn.Visible = b end
                kbBtn.MouseButton1Click:Connect(function()
                    kbBtn.Text = "..."
                    local conn
                    conn = UserInputService.InputBegan:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.Keyboard or i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.MouseButton2 then
                            if i.UserInputType == Enum.UserInputType.Keyboard then set(i.KeyCode) else set(i.UserInputType) end
                            conn:Disconnect()
                        end
                    end)
                end)
                Library.SetFlags[kflag] = function(v) set(v) end
                set(KB.Key)
                return KB
            end
            return L
        end

        -- Listbox
        function Section:Listbox(d)
            d = d or {}
            local flag = d.Flag or d.flag or Library:NextFlag()
            local LB = {Value = {}, Flag = flag, Options = {}}
            local row = frame(content, nil)
            row.Size = UDim2New(1, 0, 0, d.Size or d.size or 175)
            row.LayoutOrder = nextOrder(); row.ZIndex = 4
            local bg = frame(row, C.surface)
            bg.Size = UDim2New(1, 0, 1, 0); bg.ZIndex = 4
            corner(bg, 6); stroke(bg, C.edge, 0)
            local scroll = Instance.new("ScrollingFrame")
            scroll.Size = UDim2New(1, 0, 1, 0); scroll.BackgroundTransparency = 1
            scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 2
            scroll.ScrollBarImageColor3 = C.faint
            scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
            scroll.CanvasSize = UDim2New(0, 0, 0, 0)
            scroll.ZIndex = 5; scroll.Parent = bg
            vlist(scroll, 1)
            local function addOpt(name)
                local opt = Instance.new("TextButton")
                opt.Size = UDim2New(1, 0, 0, 20)
                opt.BackgroundColor3 = C.card; opt.BackgroundTransparency = 1
                opt.BorderSizePixel = 0; opt.AutoButtonColor = false; opt.Text = ""
                opt.LayoutOrder = nextOrder(); opt.ZIndex = 5; opt.Parent = scroll
                corner(opt, 4)
                local l = label(opt, tostring(name), 12, C.dim)
                l.Size = UDim2New(1, 0, 1, 0); l.TextXAlignment = Enum.TextXAlignment.Center
                l.ZIndex = 6
                local function toggle()
                    if d.Multi or d.multi then
                        local idx
                        for i, v in ipairs(LB.Value) do if v == name then idx = i; break end end
                        if idx then table.remove(LB.Value, idx); l.TextColor3 = C.dim
                        else table.insert(LB.Value, name); l.TextColor3 = C.accent end
                    else
                        LB.Value = {name}; l.TextColor3 = C.accent
                        for _, ch in ipairs(scroll:GetChildren()) do
                            if ch:IsA("TextButton") and ch ~= opt then
                                local cl = ch:FindFirstChildOfClass("TextLabel")
                                if cl then cl.TextColor3 = C.dim end
                            end
                        end
                    end
                    Library.Flags[flag] = LB.Value
                    if d.Callback or d.callback then Library:SafeCall(d.Callback or d.callback, LB.Value) end
                end
                opt.MouseButton1Click:Connect(toggle)
                opt.MouseEnter:Connect(function() opt.BackgroundTransparency = 0; l.TextColor3 = C.text end)
                opt.MouseLeave:Connect(function() opt.BackgroundTransparency = 1; l.TextColor3 = LB.Value and (function() for _, v in ipairs(LB.Value) do if v == name then return C.accent end end return C.dim end)() end)
            end
            for _, item in ipairs(d.Items or d.items or {}) do addOpt(item) end
            LB.Set = function(_, v)
                LB.Value = type(v) == "table" and v or {v}
                Library.Flags[flag] = LB.Value
                if d.Callback or d.callback then Library:SafeCall(d.Callback or d.callback, LB.Value) end
            end
            LB.Get = function() return LB.Value end
            LB.Add = function(_, name) addOpt(name) end
            LB.Remove = function() end
            LB.Refresh = function() end
            LB.SetVisibility = function(_, b) row.Visible = b end
            Library.SetFlags[flag] = function(v) LB:Set(v) end
            return LB
        end

        return setmetatable(Section, Library.Sections)
    end

    -- ─── Watermark ───
    Library.Watermark = function(self, text)
        local W = {}
        local wm = frame(Library.Holder.Instance, C.side)
        wm.Name = "CocaineWM"
        wm.AnchorPoint = V2(0.5, 0)
        wm.Position = UDim2New(0.5, 0, 0, 20)
        wm.AutomaticSize = Enum.AutomaticSize.X
        wm.Size = UDim2New(0, 0, 0, 26)
        wm.ZIndex = 100
        corner(wm, 6); stroke(wm, C.edge, 0)
        padding(wm, 0, 10, 0, 10)
        local t = label(wm, text or "c0caine", 12, C.dim)
        t.Size = UDim2New(0, 0, 1, 0)
        t.AutomaticSize = Enum.AutomaticSize.X
        t.TextYAlignment = Enum.TextYAlignment.Center
        t.ZIndex = 101
        -- drag
        local drag, ds, sp
        wm.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true; ds = i.Position; sp = wm.Position end end)
        wm.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)
        UserInputService.InputChanged:Connect(function(i) if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - ds; wm.Position = UDim2New(0, sp.X.Offset + d.X, 0, sp.Y.Offset + d.Y)
        end end)
        W.SetVisibility = function(_, b) wm.Visible = b end
        W.Set = function(_, s) t.Text = tostring(s) end
        W.Instance = wm
        W.Label = t
        return W
    end

    -- ─── Notification ───
    Library.Notification = function(self, text, duration, color, icon)
        local n = frame(Library.NotifHolder.Instance, C.surface)
        n.Size = UDim2New(0, 0, 0, 26)
        n.AutomaticSize = Enum.AutomaticSize.X
        n.ZIndex = 150
        corner(n, 6); stroke(n, C.edge, 0)
        padding(n, 0, 10, 0, 10)
        local t = label(n, text, 12, C.text)
        t.Size = UDim2New(0, 0, 1, 0)
        t.AutomaticSize = Enum.AutomaticSize.X
        t.TextYAlignment = Enum.TextYAlignment.Center
        t.ZIndex = 151
        -- accent dot on the right
        local dot = frame(n, color or C.accent)
        dot.Size = UDim2New(0, 6, 0, 6)
        dot.AnchorPoint = V2(1, 0.5); dot.Position = UDim2New(1, 0, 0.5, 0)
        dot.ZIndex = 151; corner(dot, 3)

        local origSize = n.Size
        n.BackgroundTransparency = 1
        t.TextTransparency = 1
        dot.BackgroundTransparency = 1
        tw(n, TW.open, {BackgroundTransparency = 0})
        tw(t, TW.open, {TextTransparency = 0})
        tw(dot, TW.open, {BackgroundTransparency = 0})
        task.delay(duration or 3, function()
            tw(n, TW.close, {BackgroundTransparency = 1})
            tw(t, TW.close, {TextTransparency = 1})
            tw(dot, TW.close, {BackgroundTransparency = 1})
            task.wait(0.3)
            n:Destroy()
        end)
    end

    -- ─── KeybindList ───
    Library.KeybindList = function(self)
        local KL = {}
        Library.KeyList = KL
        local frame_ = frame(Library.Holder.Instance, C.side)
        frame_.Name = "CocaineKBList"
        frame_.AnchorPoint = V2(0, 0.5)
        frame_.Position = UDim2New(0, 20, 0.5, 0)
        frame_.AutomaticSize = Enum.AutomaticSize.XY
        frame_.Size = UDim2New(0, 100, 0, 0)
        frame_.ZIndex = 100
        corner(frame_, 8); stroke(frame_, C.edge, 0)
        vlist(frame_, 2); padding(frame_, 10, 12, 10, 12)
        local title = label(frame_, "keybinds", 11, C.muted)
        title.Size = UDim2New(1, 0, 0, 16)
        title.ZIndex = 101
        local content = frame(frame_)
        content.AutomaticSize = Enum.AutomaticSize.XY
        content.Size = UDim2New(0, 0, 0, 0)
        content.ZIndex = 101
        vlist(content, 2)
        -- drag
        local drag, ds, sp
        frame_.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true; ds = i.Position; sp = frame_.Position end end)
        frame_.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)
        UserInputService.InputChanged:Connect(function(i) if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - ds; frame_.Position = UDim2New(0, sp.X.Offset + d.X, 0, sp.Y.Offset + d.Y)
        end end)
        function KL:Add(mode, name, key)
            local e = label(content, ("(%s) %s - %s"):format(mode, name, key), 11, C.dim)
            e.Size = UDim2New(0, 0, 0, 16)
            e.AutomaticSize = Enum.AutomaticSize.X
            e.ZIndex = 101
            local entry = {}
            entry.Set = function(_, m, n, k) e.Text = ("(%s) %s - %s"):format(m, n, k) end
            entry.SetStatus = function(_, on) e.TextColor3 = on and C.accent or C.dim end
            return entry
        end
        function KL:SetVisibility(b) frame_.Visible = b end
        return KL
    end

    -- ─── PlayerList ───
    Library.Pages.PlayerList = function(self, Data)
        local Page = self
        local PL = {Page = Page, Window = Page.Window, Players = {}, Selected = nil}
        local col = Page.ColumnsData[1] or Page.ColumnsData[2]
        local card = frame(col, C.surface)
        card.Size = UDim2New(1, 0, 0, 419)
        card.LayoutOrder = nextOrder(); card.ZIndex = 3
        corner(card, 10); stroke(card, C.hairline, 0)
        padding(card, 0, 10, 10, 10)

        local title = label(card, "players", 13, C.dim)
        title.FontFace = Font.fromEnum(Enum.Font.GothamBold)
        title.Size = UDim2New(1, 0, 0, 30)
        title.ZIndex = 4

        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2New(1, 0, 1, -90)
        scroll.Position = UDim2New(0, 0, 0, 34)
        scroll.BackgroundColor3 = C.bg
        scroll.BackgroundTransparency = 0.3
        scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 2
        scroll.ScrollBarImageColor3 = C.faint
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.CanvasSize = UDim2New(0, 0, 0, 0)
        scroll.ZIndex = 4; scroll.Parent = card
        corner(scroll, 6); stroke(scroll, C.edge, 0)
        vlist(scroll, 2); padding(scroll, 4, 6, 4, 6)

        local function addPlayer(plr)
            if PL.Players[plr.Name] then return end
            local row = Instance.new("TextButton")
            row.Size = UDim2New(1, 0, 0, 22)
            row.BackgroundColor3 = C.card; row.BackgroundTransparency = 1
            row.BorderSizePixel = 0; row.AutoButtonColor = false; row.Text = ""
            row.LayoutOrder = nextOrder(); row.ZIndex = 5; row.Parent = scroll
            corner(row, 4)
            local nm = label(row, plr.Name, 12, C.dim)
            nm.Size = UDim2New(0.6, 0, 1, 0); nm.Position = UDim2New(0, 6, 0, 0)
            nm.TextYAlignment = Enum.TextYAlignment.Center
            nm.ZIndex = 6
            local status = label(row, plr == LocalPlayer and "you" or "neutral", 11, C.muted)
            status.Size = UDim2New(0.4, -6, 1, 0); status.Position = UDim2New(0.6, 0, 0, 0)
            status.TextXAlignment = Enum.TextXAlignment.Right
            status.TextYAlignment = Enum.TextYAlignment.Center
            status.ZIndex = 6
            local data = {Name = plr.Name, Player = plr, Row = row, NameLabel = nm, Status = status}
            PL.Players[plr.Name] = data
            row.MouseButton1Click:Connect(function()
                PL.Selected = plr
                for _, d in pairs(PL.Players) do d.Row.BackgroundTransparency = 1; d.NameLabel.TextColor3 = C.dim end
                row.BackgroundTransparency = 0; nm.TextColor3 = C.accent
                if Data and (Data.Callback or Data.callback) then Library:SafeCall(Data.Callback or Data.callback, plr) end
            end)
            row.MouseEnter:Connect(function() if PL.Selected ~= plr then row.BackgroundTransparency = 0.5 end end)
            row.MouseLeave:Connect(function() if PL.Selected ~= plr then row.BackgroundTransparency = 1 end end)
        end
        for _, p in ipairs(Players:GetPlayers()) do addPlayer(p) end
        Library:Connect(Players.PlayerAdded, function(p) addPlayer(p) end)
        Library:Connect(Players.PlayerRemoving, function(p)
            local d = PL.Players[p.Name]; if d then d.Row:Destroy(); PL.Players[p.Name] = nil end
        end)
        return PL
    end

    -- ─── Public API ───
    Library.Window = function(self, Data)
        Data = Data or {}
        local w = makeWindow(Data)
        return setmetatable(w, self)
    end
    Library.Pages.Page = function(self, Data) return makePage(self, Data) end
    Library.Sections.Section = function(self, Data) return makeSection(self, Data) end

    -- Bind makePage to Window instances
    Library.Pages.__index = function(self, k)
        if k == "Page" then return function(_, Data) return makePage(self, Data) end end
        return nil
    end
    Library.Pages.__call = nil

    Library.Window.Page = function(win, data) return makePage(win, data) end

    -- Section constructors on Page
    Library.Pages.Section = function(page, data)
        return makeSection(page, data)
    end
    -- For Section creation via Page:Section
    local basePage = Library.Pages
    function basePage.Section(self, data) return makeSection(self, data) end

    -- Fix metatables
    Library.__index = Library
    Library.Pages.__index = Library.Pages
    Library.Sections.__index = Library.Sections
end

getgenv().Library = Library
return Library
