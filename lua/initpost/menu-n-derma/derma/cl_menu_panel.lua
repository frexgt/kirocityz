local PANEL = {}
local curent_panel 
local activeStation
local musicShouldPlay = false
local lastStationID = 0

hook.Add("Think", "ZMainMenu_MusicFailsafe", function()
    if not musicShouldPlay then
        if IsValid(activeStation) then
            activeStation:SetVolume(0)
            activeStation:Stop()
            activeStation = nil
        end
    end
end)

local fftData = {}
local smoothedBars = {}

local clr_accent = Color(140, 140, 145)
local clr_text = Color(225, 225, 225)
local clr_text_sub = Color(105, 105, 105)
local clr_bg_main = Color(10, 10, 19, 235)
local clr_sidebar_active = Color(140, 140, 145, 255)

local gradient_l = surface.GetTextureID("vgui/gradient-l")
local gradient_d = surface.GetTextureID("vgui/gradient-d")

local function GetTextChars(text)
    local chars = {}
    if utf8 then
        for _, code in utf8.codes(text) do
            chars[#chars + 1] = utf8.char(code)
        end
    else
        for i = 1, #text do chars[#chars + i] = text:sub(i, i) end
    end
    return chars
end

local function MakeLabelClickable(lbl)
    if not IsValid(lbl) then return end
    lbl:SetMouseInputEnabled(true)
    function lbl:OnMousePressed(mouseCode)
        if mouseCode == MOUSE_LEFT and self.DoClick then
            self:DoClick()
        end
    end
end

local function OpenStandaloneContent(drawFunc)
    if not isfunction(drawFunc) then return end

    hg = hg or {}
    if IsValid(hg.StandaloneEscPanel) then
        hg.StandaloneEscPanel:Remove()
    end

    local panel = vgui.Create("EditablePanel")
    panel:SetSize(ScrW(), ScrH())
    panel:SetPos(0, 0)
    panel:SetMouseInputEnabled(true)
    panel:SetKeyboardInputEnabled(true)
    panel:MakePopup()

    function panel:OnKeyCodePressed(keyCode)
        if keyCode == KEY_ESCAPE then
            self:Remove()
        end
    end

    function panel:OnRemove()
        if hg then
            hg.StandaloneEscPanel = nil
        end
        gui.EnableScreenClicker(false)
    end

    hg.StandaloneEscPanel = panel
    gui.EnableScreenClicker(true)
    drawFunc(panel)
end

local Selects = {
    {Title = "Играть", Func = function(luaMenu) luaMenu:Close() end},
    {Title = "Главное меню", Func = function(luaMenu) gui.ActivateGameUI() luaMenu:Close() end},
    {Title = "Дискорд", Func = function(luaMenu)
        luaMenu:Close()
        gui.OpenURL("https://discord.gg/YXQ5yzYQu")
    end},
    {Title = "Роль Предателя",
    GamemodeOnly = true,
    Func = function(luaMenu, parentPanel)
        if not IsValid(parentPanel) then return end
        luaMenu:RestoreMainMenuButtons()
        luaMenu.InRoleSubMenu = true
        if IsValid(luaMenu.lDock) then
            luaMenu.lDock:SetMouseInputEnabled(false)
        end

        for _, btn in ipairs(luaMenu.Buttons or {}) do
            if IsValid(btn) then
                btn:SetVisible(false)
                btn:SetMouseInputEnabled(false)
            end
        end

        local boxW = math.max(ScreenScaleH(260), ScrW() * 0.2)
        local boxH = math.max(ScreenScaleH(120), ScrH() * 0.15)

        local menuBox = vgui.Create("DPanel", luaMenu)
        menuBox:SetSize(boxW, boxH)
        menuBox:SetPos((luaMenu:GetWide() - boxW) * 0.5, (luaMenu:GetTall() - boxH) * 0.5)
        menuBox:SetMouseInputEnabled(true)
        menuBox:SetZPos(220)
        luaMenu.RoleSubMenu = menuBox
        menuBox.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, Color(18, 18, 22, 220))
            surface.SetDrawColor(120, 120, 120, 120)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText("Выбор роли предателя", "ZCity_Small", w * 0.5, ScreenScaleH(8), Color(220, 220, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end

        local function CreateRoleButton(title, mode, order)
            local btn = vgui.Create("DButton", menuBox)
            btn:SetText("")
            btn.Title = title
            btn:SetFont("ZCity_Small")
            btn:SetSize(menuBox:GetWide() - ScreenScaleH(26), ScreenScaleH(28))
            btn:SetPos(ScreenScaleH(13), ScreenScaleH(36) + (order - 1) * ScreenScaleH(32))
            btn:SetMouseInputEnabled(true)
            btn:SetCursor("hand")
            btn.Hov = 0

            function btn:DoClick()
                local pickedMode = mode
                luaMenu:Close()
                timer.Simple(0, function()
                    if hg and hg.SelectPlayerRole then
                        hg.SelectPlayerRole(nil, pickedMode)
                    end
                end)
            end

            function btn:Think()
                self.Hov = LerpFT(0.2, self.Hov or 0, self:IsHovered() and 1 or 0)
            end

            function btn:Paint(w, h)
                draw.RoundedBox(6, 0, 0, w, h, Color(28, 28, 34, Lerp(self.Hov, 200, 240)))
                surface.SetDrawColor(110, 110, 110, 90)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
                draw.SimpleText(self.Title or "", "ZCity_Small", w * 0.5, h * 0.5, Color(
                    Lerp(self.Hov, 215, clr_accent.r),
                    Lerp(self.Hov, 215, clr_accent.g),
                    Lerp(self.Hov, 215, clr_accent.b),
                    255
                ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end

        CreateRoleButton("TD", "soe", 1)
        CreateRoleButton("STD", "standard", 2)
    end,
    },
    {Title = "Достижения", Func = function(luaMenu)
        luaMenu:Close()
        timer.Simple(0, function()
            OpenStandaloneContent(hg.DrawAchievmentsMenu)
        end)
    end},
    {Title = "Настройки", Func = function(luaMenu)
        luaMenu:Close()
        timer.Simple(0, function()
            OpenStandaloneContent(hg.DrawSettings)
        end)
    end},
    {Title = "Раздевалка", Func = function(luaMenu)
        luaMenu:Close()
        timer.Simple(0, function()
            if hg and hg.CreateApperanceMenu then
                hg.CreateApperanceMenu()
            end
        end)
    end},
    {Title = "Отключение", Func = function(luaMenu) RunConsoleCommand("disconnect") end},
}

local splasheh = {
   'KIROGRAD DEAD',
    'OKIRO BOTIK',
    'OKIRO BOT BECAUSE SLIV KIROGRAD',
    'YA BOTARA',
    't.me/ok1rohgzcitypro',
    'HOP ON K-CITY',
    'okiro K-CITY'
}

--print(string.upper('I wish you good health, Jason Statham'))
surface.CreateFont("ZC_MM_Title", {
    font = "Bahnschrift",
    size = ScreenScale(40),
    weight = 800,
    antialias = true
})
-- local Title = markup.Parse("error")

local Pluv = Material("pluv/pluvkid.jpg")

function PANEL:InitializeMarkup()
	local mapname = game.GetMap()
	local prefix = string.find(mapname, "_")
	if prefix then
		mapname = string.sub(mapname, prefix + 1)
	end
	local gm = splasheh[math.random(#splasheh)] .. " | " .. string.NiceName(mapname) 

    if hg.PluvTown.Active then
        self.SelectedPluv = table.Random(hg.PluvTown.PluvMats)
        return "City", gm
    end

    return "Kirocity", gm
end

function PANEL:RestoreMainMenuButtons()
    if IsValid(self.RoleSubMenu) then
        self.RoleSubMenu:Remove()
    end

    self.RoleSubMenu = nil
    self.InRoleSubMenu = false

    for _, btn in ipairs(self.Buttons or {}) do
        if IsValid(btn) then
            btn:SetVisible(true)
            btn:SetMouseInputEnabled(true)
        end
    end
    if IsValid(self.lDock) then
        self.lDock:SetMouseInputEnabled(true)
    end

    curent_panel = nil
end

function PANEL:Init()
    self:SetAlpha(0)
    self:SetSize(ScrW(), ScrH())
    self:Center()
    self:SetTitle("")
    self:SetDraggable(false)
    self:SetBorder(false)
    self:SetColorBG(clr_bg_main)
    self:SetDraggable(false)
    self:ShowCloseButton(false)
    curent_panel = nil
    self.MainTitle, self.SubTitle = self:InitializeMarkup()

    timer.Simple(0, function()
        if self.First then
            self:First()
        end
    end)

    self.lDock = vgui.Create("DPanel", self)
    local lDock = self.lDock
    lDock:SetZPos(10)
    lDock:SetSize(math.max(ScrW() * 0.18, 260), ScrH() * 0.56)
    lDock:SetPos(ScrW() * 0.5 - lDock:GetWide() * 0.5, ScrH() * 0.2)
    lDock:DockPadding(0, ScreenScaleH(85), 0, 0)
    lDock.Paint = function(this, w, h)
        local openedAt = self.OpenedAt or RealTime()
        local shouldAppear = RealTime() >= openedAt + (self.TitleAppearDelay or 0)
        self.TitleAppearLerp = LerpFT(0.07, self.TitleAppearLerp or 0, shouldAppear and 1 or 0)
        local v = self.TitleAppearLerp or 0

        local title = self.MainTitle or "Kirocity"
        local subTitle = self.SubTitle or ""
        local x, y = w * 0.5, 8 + (1 - v) * (self.TitleAppearOffset or 0)
        local t = RealTime() * 4

        surface.SetFont("ZC_MM_Title")
        local tw = surface.GetTextSize(title)
        local startX = x - tw * 0.5
        
        draw.SimpleText(title, "ZC_MM_Title", x + 2, y + 2, Color(0, 0, 0, 150 * v), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        local chars = GetTextChars(title)
        local accumulatedW = 0
        for i, char in ipairs(chars) do
            local cw = surface.GetTextSize(char)
            local shimmer = (math.sin(t - i * 0.4) + 1) * 0.5
            local col = Color(100, 100, 100):Lerp(Color(255, 255, 255), shimmer)
            
            draw.SimpleText(char, "ZC_MM_Title", startX + accumulatedW, y, Color(col.r, col.g, col.b, 255 * v), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            accumulatedW = accumulatedW + cw
        end

        draw.SimpleText(subTitle, "ZCity_Tiny", x, y + ScreenScale(36), Color(clr_text_sub.r, clr_text_sub.g, clr_text_sub.b, 255 * v), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end


    self.Buttons = {}
    for k, v in ipairs(Selects) do
        if v.GamemodeOnly and engine.ActiveGamemode() != "zcity" then continue end
        self:AddSelect(lDock, v.Title, v)
    end

    local totalButtons = #self.Buttons
    for index, btn in ipairs(self.Buttons) do
        if IsValid(btn) then
            btn.AppearDelay = (totalButtons - index) * 0.02
        end
    end

    local buttonTall = ScreenScale(15)
    local buttonGap = ScreenScaleH(6)
    local topPadding = ScreenScaleH(85)
    local minTall = ScrH() * 0.56
    local needTall = topPadding + (#self.Buttons * (buttonTall + buttonGap)) + ScreenScaleH(12)
    local targetTall = math.min(ScrH() * 0.8, math.max(minTall, needTall))
    lDock:SetTall(targetTall)
    lDock:SetY(math.Clamp(ScrH() * 0.2, ScreenScaleH(10), ScrH() - targetTall - ScreenScaleH(10)))


    local bottomDock = vgui.Create("DPanel", self)
    local footerLineH = math.max(14, ScreenScaleH(14))
    local footerPad = 2
    bottomDock:SetVisible(true)
    bottomDock:SetSize(math.min(ScrW() * 0.45, math.max(420, ScreenScaleH(420))), footerLineH * 4 + footerPad * 2)
    bottomDock.BaseX = ScreenScale(6)
    bottomDock.AppearOffset = ScreenScaleH(18)
    bottomDock.AppearDelay = 0.18
    bottomDock.AppearLerp = 0
    bottomDock:SetAlpha(0)
    bottomDock:SetPos(bottomDock.BaseX, ScrH() - bottomDock:GetTall() - ScreenScale(6) + bottomDock.AppearOffset)
    bottomDock.Paint = function(this, w, h) end
    bottomDock.Think = function(this)
        local parentPanel = this:GetParent()
        local openedAt = IsValid(parentPanel) and (parentPanel.OpenedAt or RealTime()) or RealTime()
        local shouldAppear = RealTime() >= openedAt + this.AppearDelay

        this.AppearLerp = LerpFT(0.08, this.AppearLerp or 0, shouldAppear and 1 or 0)
        this:SetAlpha(255 * this.AppearLerp)
        this:SetPos(this.BaseX, ScrH() - this:GetTall() - ScreenScale(6) + (1 - this.AppearLerp) * this.AppearOffset)

        for _, child in ipairs(this:GetChildren()) do
            if IsValid(child) then
                child:SetAlpha(this:GetAlpha())
            end
        end
    end
    self.panelparrent = vgui.Create("DPanel", self)
    self.panelparrent:SetPos(0, 0)
    self.panelparrent:SetSize(ScrW(), ScrH())
    self.panelparrent:SetMouseInputEnabled(false)
    self.panelparrent.Paint = function(this, w, h) end

    local infoColor = Color(140, 140, 145, 220)

    local authors1 = vgui.Create("DLabel", bottomDock)
    authors1:SetPos(0, footerPad + footerLineH * 0)
    authors1:SetSize(bottomDock:GetWide(), footerLineH)
    authors1:SetFont("ZCity_Tiny")
    authors1:SetTextColor(infoColor)
    authors1:SetText("Authors: uzelezz, Sadsalat,")
    authors1:SetContentAlignment(4)

    local authors2 = vgui.Create("DLabel", bottomDock)
    authors2:SetPos(0, footerPad + footerLineH * 1)
    authors2:SetSize(bottomDock:GetWide(), footerLineH)
    authors2:SetFont("ZCity_Tiny")
    authors2:SetTextColor(infoColor)
    authors2:SetText("Mr.Point, Zac70, Deka, Mannytko")
    authors2:SetContentAlignment(4)

    local version = vgui.Create("DLabel", bottomDock)
    version:SetPos(0, footerPad + footerLineH * 2)
    version:SetSize(bottomDock:GetWide(), footerLineH)
    version:SetFont("ZCity_Tiny")
    version:SetTextColor(infoColor)
    local verText = tostring(hg.Version or "1.4.0")
    if string.find(string.lower(verText), "release", 1, true) == 1 then
        version:SetText(verText)
    else
        version:SetText("Release " .. verText)
    end
    version:SetContentAlignment(4)

    local git = vgui.Create("DLabel", bottomDock)
    git:SetPos(0, footerPad + footerLineH * 3)
    git:SetSize(bottomDock:GetWide(), footerLineH)
    git:SetFont("ZCity_Tiny")
    git:SetTextColor(clr_text_sub)
    git:SetText("GitHub: github.com/uzelezz123/Z-City")
    git:SetContentAlignment(4)
    MakeLabelClickable(git)
    function git:DoClick()
        gui.OpenURL("https://github.com/uzelezz123/Z-City")
    end

    local rightAuthors = vgui.Create("DLabel", self)
    rightAuthors:SetFont("ZCity_Tiny")
    rightAuthors:SetTextColor(infoColor)
    rightAuthors:SetText("KIROCITY authors\nok1ro, Frex,so fuck you koll")
    rightAuthors:SetContentAlignment(3)
    rightAuthors:SetWrap(true)
    rightAuthors:SetWide(math.min(ScrW() * 0.32, 320))
    rightAuthors:SetAutoStretchVertical(true)
    rightAuthors:SizeToContentsY()
    rightAuthors.AppearOffset = ScreenScaleH(18)
    rightAuthors.AppearDelay = 0.2
    rightAuthors.AppearLerp = 0
    rightAuthors:SetAlpha(0)
    rightAuthors:SetPos(ScrW() - rightAuthors:GetWide() - 16, ScrH() - rightAuthors:GetTall() - 16 + rightAuthors.AppearOffset)

    function rightAuthors:Think()
        local parentPanel = self:GetParent()
        local openedAt = IsValid(parentPanel) and (parentPanel.OpenedAt or RealTime()) or RealTime()
        local shouldAppear = RealTime() >= openedAt + self.AppearDelay

        self.AppearLerp = LerpFT(0.08, self.AppearLerp or 0, shouldAppear and 1 or 0)
        self:SetAlpha(255 * self.AppearLerp)
        self:SetPos(ScrW() - self:GetWide() - 16, ScrH() - self:GetTall() - 16 + (1 - self.AppearLerp) * self.AppearOffset)
    end
end

function PANEL:First( ply )
    self.OpenedAt = RealTime()
    self.TitleAppearDelay = 0.03
    self.TitleAppearOffset = ScreenScaleH(22)
    self.TitleAppearLerp = 0
    self:AlphaTo( 255, 0.1, 0, nil )

    local hg_dmusic = GetConVar("hg_dmusic")
    if hg_dmusic and not hg_dmusic:GetBool() then return end

    musicShouldPlay = true
    lastStationID = lastStationID + 1
    local currentID = lastStationID

    if IsValid(activeStation) then
        activeStation:SetVolume(0)
        activeStation:Stop()
        activeStation = nil
    end

    sound.PlayFile("sound/esc/nota.mp3", "noplay mono", function(station, errCode, errStr)
        if IsValid(station) then
            if musicShouldPlay and currentID == lastStationID and IsValid(self) and not self.IsClosing then
                if IsValid(activeStation) then activeStation:Stop() end
                activeStation = station
                activeStation:SetVolume(2.0)
                activeStation:Play()
            else
                station:SetVolume(0)
                station:Stop()
            end
        end
    end)
end

function PANEL:Paint(w,h)
    draw.RoundedBox( 0, 0, 0, w, h, self.ColorBG )
    hg.DrawBlur(self, 5)

    local gridSize = ScreenScale(25)
    local gridSpeed = 12
    local gridTime = RealTime() * gridSpeed
    local gridAlpha = 12
    local offset = gridTime % gridSize

    surface.SetDrawColor(200, 200, 200, gridAlpha)

    for i = -1, math.ceil(w / gridSize) + 1 do
        local x = i * gridSize - offset
        surface.DrawRect(x, 0, 1, h)
    end
    for i = -1, math.ceil(h / gridSize) + 1 do
        local y = i * gridSize + offset
        surface.DrawRect(0, y, w, 1)
    end
    
    surface.SetDrawColor( self.ColorBG )
    surface.SetTexture( gradient_l )
    surface.DrawTexturedRect(0,0,w,h)
    
    surface.SetDrawColor( 94, 94, 94, 30)
    surface.SetTexture( gradient_d )
    surface.DrawTexturedRect(0,0,w,h)

    if IsValid(activeStation) and activeStation:GetState() == GMOD_CHANNEL_PLAYING then
        activeStation:FFT(fftData, 3) 

        local barCount = 30
        local barW = ScreenScale(1)
        local spacing = ScreenScale(0.5)
        local maxH = ScreenScale(10)
        local xOff, yOff = ScreenScale(10), h - ScreenScale(65) 

        for i = 1, barCount do
            local val = fftData[i + 1] or 0 
            smoothedBars[i] = LerpFT(0.12, smoothedBars[i] or 0, val)
            
            local hVal = math.sqrt(smoothedBars[i]) * maxH * 10
            hVal = math.Clamp(hVal, 1, maxH)
            
            surface.SetDrawColor(clr_accent.r, clr_accent.g, clr_accent.b, 100 * (self:GetAlpha() / 255))
            surface.DrawRect(xOff + (i - 1) * (barW + spacing), yOff + (maxH - hVal), barW, hVal)
        end
    end
end

function PANEL:AddSelect( pParent, strTitle, tbl )
    local id = #self.Buttons + 1
    self.Buttons[id] = vgui.Create( "DLabel", pParent )
    local btn = self.Buttons[id]
    local buttonTall = ScreenScale(15)
    local buttonGap = ScreenScaleH(6)
    btn:SetText( strTitle )
    MakeLabelClickable(btn)
    btn:SetContentAlignment(5)
    btn:SetFont( "ZCity_Small" )
    btn:SetSize(pParent:GetWide(), buttonTall)
    btn.BaseY = ScreenScaleH(85) + (id - 1) * (buttonTall + buttonGap)
    btn.AppearOffset = ScreenScaleH(18)
    btn.AppearDelay = 0
    btn.AppearLerp = 0
    btn:SetAlpha(0)
    btn:SetPos(0, btn.BaseY + btn.AppearOffset)
    btn.Func = tbl.Func
    btn.HoveredFunc = tbl.HoveredFunc
    local luaMenu = self 
    if tbl.CreatedFunc then tbl.CreatedFunc(btn, self, luaMenu) end
    btn.RColor = clr_text
    function btn:DoClick()

        if curent_panel == string.lower(strTitle) then
			for i = 1, 3 do
				surface.PlaySound("shitty/tap_release.wav")
			end
            luaMenu.panelparrent:AlphaTo(0,0.2,0,function()
                luaMenu.panelparrent:Remove()
                luaMenu.panelparrent = nil
                luaMenu.panelparrent = vgui.Create("DPanel", luaMenu)
                
                luaMenu.panelparrent:SetPos(some_coordinates_x, 0)
                luaMenu.panelparrent:SetSize(some_size_x, some_size_y)
                luaMenu.panelparrent.Paint = function(this, w, h) end
                --btn.Func(luaMenu,luaMenu.panelparrent)
                curent_panel = nil
            end)
            return 
        end
        some_size_x = luaMenu.panelparrent:GetWide()
        some_size_y = luaMenu.panelparrent:GetTall()
        some_coordinates_x = luaMenu.panelparrent:GetX()
        luaMenu.panelparrent:AlphaTo(0,0.2,0,function()
            luaMenu.panelparrent:Remove()
            luaMenu.panelparrent = nil
            luaMenu.panelparrent = vgui.Create("DPanel", luaMenu)
            
            luaMenu.panelparrent:SetPos(some_coordinates_x, 0)
            luaMenu.panelparrent:SetSize(some_size_x, some_size_y)
            luaMenu.panelparrent.Paint = function(this, w, h) end
            btn.Func(luaMenu,luaMenu.panelparrent)
            curent_panel = string.lower(strTitle)
        end)
		for i = 1, 3 do
			surface.PlaySound("shitty/tap_depress.wav")
		end
    end

    function btn:Think()
        local openedAt = luaMenu.OpenedAt or RealTime()
        local shouldAppear = RealTime() >= openedAt + self.AppearDelay
        self.AppearLerp = LerpFT(0.08, self.AppearLerp or 0, shouldAppear and 1 or 0)
        self:SetAlpha(255 * self.AppearLerp)
        self:SetSize(pParent:GetWide(), buttonTall)
        self:SetPos(0, self.BaseY + (1 - self.AppearLerp) * self.AppearOffset)

        self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, (self:IsHovered() or (IsValid(self:GetChild(0)) and self:GetChild(0):IsHovered()) or (IsValid(self:GetChild(0)) and IsValid(self:GetChild(0):GetChild(0)) and self:GetChild(0):GetChild(0):IsHovered())) and 1 or 0)
        self.ActiveLerp = LerpFT(0.15, self.ActiveLerp or 0, (curent_panel == string.lower(strTitle)) and 1 or 0)

        local targetText = (self:IsHovered()) and string.upper(strTitle) or strTitle
        local crw = self:GetText()

        if (crw ~= targetText) or (curent_panel == string.lower(strTitle)) then
            local ntxt = ""
            local will_text = (curent_panel == string.lower(strTitle) and strTitle ~= "Traitor Role") and "[ "..string.upper(strTitle).." ]" or strTitle
            local v = math.max(self.HoverLerp or 0, self.ActiveLerp or 0)
            for i = 1, #will_text do
                local char = will_text:sub(i, i)
                if i <= math.ceil(#will_text * v) then
                    ntxt = ntxt .. string.upper(char)
                else
                    ntxt = ntxt .. char
                end
            end
			if self:GetText() ~= ntxt then
				surface.PlaySound("shitty/tap-resonant.wav")
			end
            self:SetText(ntxt)
        end
    end

    btn.Paint = function(s, w, h)
        local text = s:GetText()
        if text == "" then return end

        local v = math.max(s.HoverLerp or 0, s.ActiveLerp or 0)
        surface.SetFont(s:GetFont())
        local tw = surface.GetTextSize(text)
        local startX = w * 0.5 - tw * 0.5

        if v > 0.01 then
            local chars = GetTextChars(text)
            local cx = startX
            local t = CurTime() * 7
            
            for i, char in ipairs(chars) do
                local cw = surface.GetTextSize(char)
                local shimmer = (math.sin(t - i * 0.4) + 1) * 0.5
                local col_shimmer = Color(20, 20, 20):Lerp(Color(255, 255, 255), shimmer)
                
                local col = clr_text:Lerp(col_shimmer, v)
                draw.SimpleText(char, s:GetFont(), cx + 1, h / 2 + 1, Color(0, 0, 0, 200 * v * s.AppearLerp), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(char, s:GetFont(), cx, h / 2, Color(col.r, col.g, col.b, 255 * s.AppearLerp), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                cx = cx + cw
            end
        else
            draw.SimpleText(text, s:GetFont(), w * 0.5, h / 2, Color(clr_text.r, clr_text.g, clr_text.b, 255 * s.AppearLerp), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        if s.ActiveLerp and s.ActiveLerp > 0.01 then
            surface.SetDrawColor(clr_sidebar_active.r, clr_sidebar_active.g, clr_sidebar_active.b, clr_sidebar_active.a * s.ActiveLerp * s.AppearLerp)
            surface.DrawRect(w * 0.5 - tw * 0.5 - ScreenScale(10), ScreenScale(3), ScreenScale(1.5), h - ScreenScale(6))
        end
        return true
    end
end

function PANEL:Close()
    self.IsClosing = true
    musicShouldPlay = false

    if IsValid(activeStation) then
        activeStation:SetVolume(0)
        activeStation:Stop()
        activeStation = nil
    end

    curent_panel = nil
    self:RestoreMainMenuButtons()
    if IsValid(self.panelparrent) then
        self.panelparrent:Remove()
        self.panelparrent = nil
    end
    self:AlphaTo( 0, 0.1, 0, function() self:Remove() end)
    gui.EnableScreenClicker(false)
    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)
end

function PANEL:OnRemove()
    musicShouldPlay = false
    if IsValid(activeStation) then
        activeStation:SetVolume(0)
        activeStation:Stop()
        activeStation = nil
    end
end

function PANEL:OnKeyCodePressed(keyCode)
    if keyCode ~= KEY_ESCAPE then return end
    if self.InRoleSubMenu then
        self:RestoreMainMenuButtons()
        return
    end
    self:Close()
    MainMenu = nil
end

vgui.Register( "ZMainMenu", PANEL, "ZFrame")

hook.Add("OnPauseMenuShow","OpenMainMenu",function()
    if IsValid(zpan) then
        zpan:Close()
        zpan = nil
        return false
    end

    if hg and IsValid(hg.StandaloneEscPanel) then
        hg.StandaloneEscPanel:Remove()
        hg.StandaloneEscPanel = nil
        return false
    end

    local run = hook.Run("OnShowZCityPause")
    if run != nil then
        return run
    end

    if MainMenu and IsValid(MainMenu) then
        MainMenu:Close()
        MainMenu = nil
        return false
    end

    MainMenu = vgui.Create("ZMainMenu")
    MainMenu:MakePopup()
    MainMenu:SetMouseInputEnabled(true)
    MainMenu:SetKeyboardInputEnabled(true)
     gui.EnableScreenClicker(true)
    return false
end)
