local PANEL = {}
local curent_panel 
local red_select = Color(170,170,170)

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
	    {Title = "Правила", Func = function(luaMenu,pp) 
        
        pp:SetSize(ScrW(), ScrH())
        pp:SetPos(0, 0)
        hg.DrawRules(pp) 
luaMenu:Close()
        timer.Simple(0, function()
            OpenStandaloneContent(hg.DrawRules)
        end)
    {Title = "Главное меню", Func = function(luaMenu) gui.ActivateGameUI() luaMenu:Close() end},
    {Title = "Телеграм", Func = function(luaMenu)
        luaMenu:Close()
        gui.OpenURL("https://t.me/ok1rohgzcitypro")
    end},
    {Title = "Роль Предателя",
    GamemodeOnly = true,
    CreatedFunc = function(self, parent, luaMenu)
        local btn = vgui.Create( "DLabel", self )
        btn:SetText( "SOE" )
        MakeLabelClickable(btn)
        btn:SetContentAlignment(5)
        btn:SetFont( "ZCity_Small" )
        btn:SetTall( ScreenScale( 15 ) )
        btn:Dock(TOP)
        btn:DockMargin(ScreenScale(20),ScreenScale(10),0,0)
        btn:SetTextColor(Color(255,255,255))
        btn:InvalidateParent()
        btn.RColor = Color(225, 225, 225, 0)
        btn.WColor = Color(225, 225, 225, 255)
        btn.x = btn:GetX()

        function btn:DoClick()
            luaMenu:Close()
            hg.SelectPlayerRole(nil, "soe")
        end
    
        local selfa = self
        function btn:Think()
            self.HoverLerp = selfa.HoverLerp
            self.HoverLerp2 = LerpFT(0.2, self.HoverLerp2 or 0, self:IsHovered() and 1 or 0)
                
            self:SetTextColor(self.RColor:Lerp(self.WColor:Lerp(red_select, self.HoverLerp2), self.HoverLerp))
            self:SetX(self.x + ScreenScaleH(40) + self.HoverLerp * ScreenScaleH(50))
        end

        local btn = vgui.Create( "DLabel", btn )
        btn:SetText( "STD" )
        MakeLabelClickable(btn)
        btn:SetContentAlignment(5)
        btn:SetFont( "ZCity_Small" )
        btn:SetTall( ScreenScale( 15 ) )
        btn:Dock(TOP)
        btn:DockMargin(0,ScreenScale(2),0,0)
        btn:SetTextColor(Color(255,255,255))
        btn:InvalidateParent()
        btn.RColor = Color(225, 225, 225, 0)
        btn.WColor = Color(225, 225, 225, 255)
        btn.x = btn:GetX()

        function btn:DoClick()
            luaMenu:Close()
            hg.SelectPlayerRole(nil, "standard")
        end
    
        function btn:Think()
            self.HoverLerp = selfa.HoverLerp
            self.HoverLerp2 = LerpFT(0.2, self.HoverLerp2 or 0, self:IsHovered() and 1 or 0)
    
            self:SetTextColor(self.RColor:Lerp(self.WColor:Lerp(red_select, self.HoverLerp2), self.HoverLerp))
            self:SetX(self.x + ScreenScaleH(35))
        end
    end,
    Func = function(luaMenu)
        
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

local title_grad_white = Color(255, 255, 255)
local title_grad_gray = Color(90, 90, 95)
local title_shadow = Color(0, 0, 0, 160)

local function MarkupGradientText(str, font, colStart, colEnd)
    if str == "" then return "" end

    local out = "<font=" .. font .. ">"
    local len = #str

    for i = 1, len do
        local t = len > 1 and (i - 1) / (len - 1) or 0
        local c = colStart:Lerp(colEnd, t)
        out = out .. string.format("<colour=%d,%d,%d,%d>%s</colour>", c.r, c.g, c.b, c.a, str:sub(i, i))
    end

    return out .. "</font>"
end

local function MarkupShadowText(str, font, col)
    return "<font=" .. font .. "><colour=" .. col.r .. "," .. col.g .. "," .. col.b .. "," .. col.a .. ">" .. str .. "</colour></font>"
end

function PANEL:InitializeMarkup()
	local mapname = game.GetMap()
	local prefix = string.find(mapname, "_")
	if prefix then
		mapname = string.sub(mapname, prefix + 1)
	end
	local gm = splasheh[math.random(#splasheh)] .. " | " .. string.NiceName(mapname) 

    if hg.PluvTown.Active then
        local titleStr = "    City"
        local text = MarkupGradientText(titleStr, "ZC_MM_Title", title_grad_white, title_grad_gray) .. "\n<font=ZCity_Tiny><colour=140,140,140>" .. gm .. "</colour></font>"
        local shadow = MarkupShadowText(titleStr, "ZC_MM_Title", title_shadow) .. "\n<font=ZCity_Tiny><colour=0,0,0,0>.</colour></font>"

        self.SelectedPluv = table.Random(hg.PluvTown.PluvMats)

        return markup.Parse(text), markup.Parse(shadow)
    end

    local titleStr = "Kirocity"
    local text = MarkupGradientText(titleStr, "ZC_MM_Title", title_grad_white, title_grad_gray) .. "\n<font=ZCity_Tiny><colour=140,140,140>" .. gm .. "</colour></font>"
    local shadow = MarkupShadowText(titleStr, "ZC_MM_Title", title_shadow) .. "\n<font=ZCity_Tiny><colour=0,0,0,0>.</colour></font>"
    return markup.Parse(text), markup.Parse(shadow)
end

local color_red = Color(160,160,160,45)
local clr_gray = Color(255,255,255,25)
local clr_verygray = Color(24,24,28,235)

function PANEL:Init()
    self:SetAlpha(0)
    self:SetSize(ScrW(), ScrH())
    self:Center()
    self:SetTitle("")
    self:SetDraggable(false)
    self:SetBorder(false)
    self:SetColorBG(clr_verygray)
    self:SetDraggable(false)
    self:ShowCloseButton(false)
    curent_panel = nil
    self.Title, self.TitleShadow = self:InitializeMarkup()

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
        local cx, cy = w * 0.5, 8
        if self.TitleShadow then
            self.TitleShadow:Draw(cx + 2, cy + 2, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 255, TEXT_ALIGN_CENTER)
        end
        self.Title:Draw(cx, cy, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 255, TEXT_ALIGN_CENTER)
    end

    self.Buttons = {}
    for k, v in ipairs(Selects) do
        if v.GamemodeOnly and engine.ActiveGamemode() != "zcity" then continue end
        self:AddSelect(lDock, v.Title, v)
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
    bottomDock:SetVisible(false)
    bottomDock:SetSize(0, 0)
    bottomDock.Paint = function(this, w, h) end
    self.panelparrent = vgui.Create("DPanel", self)
    self.panelparrent:SetPos(0, 0)
    self.panelparrent:SetSize(ScrW(), ScrH())
    self.panelparrent.Paint = function(this, w, h) end
    
    local git = vgui.Create("DLabel", bottomDock)
    git:Dock(BOTTOM)
    git:DockMargin(ScreenScale(10), 0, 0, 0)
    git:SetFont("ZCity_Tiny")
    git:SetTextColor(clr_gray)
    git:SetText("GitHub: github.com/" .. hg.GitHub_ReposOwner .. "/" .. hg.GitHub_ReposName)
    git:SetContentAlignment(4)
    MakeLabelClickable(git)
    git:SizeToContents()

    function git:DoClick()
        gui.OpenURL("https://github.com/" .. hg.GitHub_ReposOwner .. "/" .. hg.GitHub_ReposName)
    end

    local version = vgui.Create("DLabel", bottomDock)
    version:Dock(BOTTOM)
    version:DockMargin(ScreenScale(10), 0, 0, 0)
    version:SetFont("ZCity_Tiny")
    version:SetTextColor(clr_gray)
    version:SetText(hg.Version)
    version:SetContentAlignment(4)
    version:SizeToContents()

    local zteam = vgui.Create("DLabel", bottomDock)
    zteam:Dock(BOTTOM)
    zteam:DockMargin(ScreenScale(10), 0, 0, 0)
    zteam:SetFont("ZCity_Tiny")
    zteam:SetTextColor(clr_gray)
    zteam:SetText("Authors: ok1ro, sobakaнолик, \nнеразвиваемый, pluv, vekad")
    zteam:SetContentAlignment(4)
    zteam:SizeToContents()
end

function PANEL:First( ply )
    self:AlphaTo( 255, 0.1, 0, nil )
end

local gradient_d = surface.GetTextureID("vgui/gradient-d")
local gradient_r = surface.GetTextureID("vgui/gradient-u")
local gradient_l = surface.GetTextureID("vgui/gradient-l")

local clr_1 = Color(95,95,105,45)
function PANEL:Paint(w,h)
    draw.RoundedBox( 0, 0, 0, w, h, self.ColorBG )
    hg.DrawBlur(self, 5)
    surface.SetDrawColor( self.ColorBG )
    surface.SetTexture( gradient_l )
    surface.DrawTexturedRect(0,0,w,h)
    surface.SetDrawColor( clr_1 )
    surface.SetTexture( gradient_d )
    surface.DrawTexturedRect(0,0,w,h)
end

function PANEL:AddSelect( pParent, strTitle, tbl )
    local id = #self.Buttons + 1
    self.Buttons[id] = vgui.Create( "DLabel", pParent )
    local btn = self.Buttons[id]
    btn:SetText( strTitle )
    MakeLabelClickable(btn)
    btn:SetContentAlignment(5)
    btn:SetFont( "ZCity_Small" )
    btn:SetTall( ScreenScale( 15 ) )
    btn:Dock(TOP)
    btn:DockMargin(0, ScreenScaleH(6), 0, 0)
    btn.Func = tbl.Func
    btn.HoveredFunc = tbl.HoveredFunc
    local luaMenu = self 
    if tbl.CreatedFunc then tbl.CreatedFunc(btn, self, luaMenu) end
    btn.RColor = Color(190,190,190)
    function btn:DoClick()
        -- ,kz РѕРїС‚РёРјРёР·РёСЂРѕРІР°С‚СЊ РЅР°РґРѕ, РЅРѕ РёРґС‘С‚ РѕС€РёР±РєР°(РєСЌС€РёСЂРѕРІР°С‚СЊ Р±С‹ luaMenu.panelparrent РІРјРµСЃС‚Рѕ РІС‹Р·РѕРІР° РµРіРѕ РєР°Р¶РґС‹Р№ СЂР°Р·)
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
        self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, (self:IsHovered() or (IsValid(self:GetChild(0)) and self:GetChild(0):IsHovered()) or (IsValid(self:GetChild(0)) and IsValid(self:GetChild(0):GetChild(0)) and self:GetChild(0):GetChild(0):IsHovered())) and 1 or 0)

        local v = self.HoverLerp
        self:SetTextColor(self.RColor:Lerp(red_select, v))

        local targetText = (self:IsHovered()) and string.upper(strTitle) or strTitle
        local crw = self:GetText()

        if (crw ~= targetText) or (curent_panel == string.lower(strTitle)) then
            local ntxt = ""
            local will_text = (curent_panel == string.lower(strTitle) and strTitle ~= "Traitor Role") and "[ "..string.upper(strTitle).." ]" or strTitle
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
        self:SetContentAlignment(5)
    end
end

function PANEL:Close()
    curent_panel = nil
    if IsValid(self.panelparrent) then
        self.panelparrent:Remove()
        self.panelparrent = nil
    end
    self:AlphaTo( 0, 0.1, 0, function() self:Remove() end)
    gui.EnableScreenClicker(false)
    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)
end

function PANEL:OnKeyCodePressed(keyCode)
    if keyCode ~= KEY_ESCAPE then return end
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
