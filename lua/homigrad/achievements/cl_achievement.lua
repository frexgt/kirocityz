hg.achievements = hg.achievements or {}
hg.achievements.achievements_data = hg.achievements.achievements_data or {}
hg.achievements.achievements_data.player_achievements = hg.achievements.achievements_data.player_achievements or {}
hg.achievements.achievements_data.created_achevements = {}

hg.achievements.MenuPanel = hg.achievements.MenuPanel or nil

local curent_panel_ach  
concommand.Add("hg_achievements",function()
    --hg.DrawAchievmentsMenu() doesn't work as for 15.02.2026 | from bogler with love 🥴
    print('use esc menu')
end)

local clr_bg = Color(10, 10, 19, 235)
local clr_accent = Color(140, 140, 145)
local clr_text = Color(225, 225, 225)
local clr_hover = Color(170, 170, 170)
local clr_sub = Color(105, 105, 105)

local settings_pad_l = ScreenScale(16)
local settings_dock_x = ScrW() * 0.06

local gradient_l = Material("vgui/gradient-l")
local gradient_d = Material("vgui/gradient-d")
local gradient_u = Material("vgui/gradient-u")

local function GetTextChars(text)
    local chars = {}
    if utf8 then
        for _, code in utf8.codes(text) do
            chars[#chars + 1] = utf8.char(code)
        end
    else
        for i = 1, #text do chars[#chars + 1] = text:sub(i, i) end
    end
    return chars
end

surface.CreateFont("ZC_Settings_Title", {
    font = "Bahnschrift",
    size = ScreenScale(28),
    weight = 800,
    antialias = true,
    extended = true
})

function hg.DrawAchievmentsMenu(ParentPanel)
    hg.achievements.LoadAchievements()

    hg.achievements.MenuPanel = ParentPanel

    if ParentPanel.SetDraggable then
        ParentPanel:SetDraggable(false)
    end

    ParentPanel:SetAlpha(0)
    ParentPanel.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, clr_bg)
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

        surface.SetDrawColor(clr_bg)
        surface.SetMaterial(gradient_l)
        surface.DrawTexturedRect(0, 0, w, h)

        surface.SetDrawColor(60, 60, 60, 30)
        surface.SetMaterial(gradient_d)
        surface.DrawTexturedRect(0, 0, w, h)
    end
    ParentPanel:AlphaTo(255, 0.15, 0)

    local dockW = math.max(ScrW() * 0.42, 520)
    local headerH = ScreenScaleH(70)

    local header = vgui.Create("DPanel", ParentPanel)
    header:SetSize(dockW, headerH)
    header:SetPos(settings_dock_x, ScrH() * 0.08)
    header.Paint = function(s, w, h)
        local title = "ACHIEVEMENTS"
        local x, y = settings_pad_l, h * 0.5
        local t = RealTime() * 4

        surface.SetFont("ZC_Settings_Title")
        draw.SimpleText(title, "ZC_Settings_Title", x + 2, y + 2, Color(0, 0, 0, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        local chars = GetTextChars(title)
        local accumulatedW = 0
        for i, char in ipairs(chars) do
            local shimmer = (math.sin(t - i * 0.4) + 1) * 0.5
            local col = Color(100, 100, 100):Lerp(Color(255, 255, 255), shimmer)
            draw.SimpleText(char, "ZC_Settings_Title", x + accumulatedW, y, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            accumulatedW = accumulatedW + surface.GetTextSize(char)
        end
    end

    local scroll = vgui.Create("DScrollPanel", ParentPanel)
    scroll:SetSize(dockW, ScrH() * 0.72)
    scroll:SetPos(settings_dock_x, header:GetY() + headerH + ScreenScaleH(8))

    ParentPanel.Scroll = scroll

    local vbar = scroll:GetVBar()
    vbar:SetWide(ScreenScale(4))
    vbar.Paint = function(s, w, h) draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 45, 100)) end
    vbar.btnUp.Paint = function() end
    vbar.btnDown.Paint = function() end
    vbar.btnGrip.Paint = function(s, w, h)
        local col = s:IsHovered() and clr_hover or Color(120, 120, 125, 150)
        draw.RoundedBox(0, 0, 0, w, h, col)
    end

    function ParentPanel:UpdateValues()
        if not IsValid(self.Scroll) then return end
        self.Scroll:Clear()

        local localach = hg.achievements.GetLocalAchievements() or {}
        local yOffset = 0

        for id, ach in pairs(hg.achievements.achievements_data.created_achevements) do
            local p = vgui.Create("DPanel", self.Scroll)
            p:SetSize(self.Scroll:GetWide(), ScreenScale(38))
            p:SetPos(0, yOffset)
            p.Hover = 0
            
            local progress = localach[id] and localach[id].value or ach.start_value
            local isDone = progress >= ach.needed_value

            p.Paint = function(s, w, h)
                local hv = s.Hover
                local t = RealTime() * 7
                
                local title = string.upper(ach.name or id)
                local chars = GetTextChars(title)
                local cx = settings_pad_l
                surface.SetFont("ZCity_Small")
                for i, char in ipairs(chars) do
                    local cw = surface.GetTextSize(char)
                    local shimmer = (math.sin(t - i * 0.4) + 1) * 0.5
                    local col = clr_text:Lerp(Color(255, 255, 255), hv * shimmer)
                    draw.SimpleText(char, "ZCity_Small", cx, h * 0.3, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    cx = cx + cw
                end

                draw.SimpleText(ach.description or "", "ZCity_Tiny", settings_pad_l, h * 0.7, clr_sub:Lerp(Color(200, 200, 200), hv), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                
                local status = isDone and "COMPLETED" or (ach.showpercent and math.floor(progress / ach.needed_value * 100) .. "%" or "IN PROGRESS")
                local scol = isDone and Color(100, 255, 100, 200) or Color(200, 200, 200, 100)
                draw.SimpleText(status, "ZCity_Tiny", w - ScreenScale(10), h * 0.5, scol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

                local barW = w - settings_pad_l - ScreenScale(10)
                local barH = ScreenScale(1.5)
                local barX = settings_pad_l
                local barY = h - ScreenScale(2.5)
                draw.RoundedBox(0, barX, barY, barW, barH, Color(40, 40, 45, 100))
                local fillW = barW * math.Clamp(progress / ach.needed_value, 0, 1)
                local fillCol = isDone and Color(100, 255, 100, 200) or clr_accent:Lerp(Color(255, 255, 255), hv * 0.2)
                draw.RoundedBox(0, barX, barY, fillW, barH, fillCol)
            end
            
            p.Think = function(s)
                s.Hover = LerpFT(0.1, s.Hover, s:IsHovered() and 1 or 0)
            end
            
            yOffset = yOffset + p:GetTall() + 8
        end
    end

    ParentPanel:UpdateValues()
end

local time_wait = 0
function hg.achievements.LoadAchievements()
    if time_wait > CurTime() then return end
    time_wait = CurTime() + 2

    net.Start("req_ach")
    net.SendToServer()
end

function hg.achievements.GetLocalAchievements()
    return hg.achievements.achievements_data.player_achievements[LocalPlayer():SteamID64()]
end

net.Receive("req_ach",function()
    hg.achievements.achievements_data.created_achevements = net.ReadTable()
    hg.achievements.achievements_data.player_achievements[LocalPlayer():SteamID64()] = net.ReadTable()
    
    if IsValid(hg.achievements.MenuPanel) then
        hg.achievements.MenuPanel:UpdateValues()
    end
end)

hg.achievements.NewAchievements = hg.achievements.NewAchievements or {}
local AchTable = hg.achievements.NewAchievements 
net.Receive("hg_NewAchievement",function()
    local Ach = {time = CurTime() + 7.5,name = net.ReadString(),img = net.ReadString()}
    table.insert(AchTable,1,Ach)
	surface.PlaySound("homigrad/vgui/achievement_earned.wav")
end)

local ach_clr1 , ach_clr2 = Color(140, 140, 145), Color(30, 30, 35)
hook.Add("HUDPaint","hg_NewAchievement", function()
    local frametime = FrameTime() * 10
    for i = 1, #AchTable do
        local ach = AchTable[i]
        if not ach then continue end
        local txt = "Achievement! "..ach.name
        ach.img = isstring(ach.img) and Material(ach.img) or ach.img
        local wt, _ = surface.GetTextSize(txt)

        ach.Lerp = Lerp( frametime, ach.Lerp or 0, math.min( ach.time - CurTime(), 1 ) * i )
        WSize, HSize = (ScrW() * 0.1) + (wt), ScrH() * 0.05
        local HPos = ScrH() - ( HSize * ach.Lerp )
        draw.RoundedBox( 0, 2, HPos + 2, WSize - 4, HSize - 4, ach_clr2 )
		
		surface.SetDrawColor(clr_accent.r, clr_accent.g, clr_accent.b, 80)
		if gradient_u then surface.SetMaterial(gradient_u) end
		surface.DrawTexturedRect( 0, HPos, WSize, HSize )
	
		surface.SetDrawColor(clr_accent.r, clr_accent.g, clr_accent.b, 150)
		surface.DrawOutlinedRect( 0, HPos, WSize, HSize, 1 )

        surface.SetFont("HomigradFontMedium")
        surface.SetTextColor(255,255,255)
        surface.SetTextPos(HSize*1.25,(HPos + ( HSize/2 ) - ( HSize/4 )) )
        surface.DrawText(txt)
        surface.SetDrawColor(255,255,255)
        surface.SetMaterial(ach.img)
        surface.DrawTexturedRect(2,HPos+2,HSize-4,HSize-4)
        if ach.time < CurTime() then 
            table.remove(AchTable,i)
        end
    end
end)
