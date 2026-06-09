hg.settings = hg.settings or {}
hg.settings.tbl = hg.settings.tbl or {}

function hg.settings:AddOpt( strCategory, strConVar, strTitle, bDecimals, bString, category )
    self.tbl[strCategory] = self.tbl[strCategory] or {}
    self.tbl[strCategory][strConVar] = { strCategory, strConVar, strTitle, bDecimals or false, bString or false, category }
end
local hg_firstperson_death = CreateClientConVar("hg_firstperson_death", "0", true, false, "Переключение вида камеры смерти от первого лица", 0, 1)
local hg_font = CreateClientConVar("hg_font", "Bahnschrift", true, false, "изменение каждого шрифта текста на выбранный, потому что настройка пользовательского интерфейса - это крутоё")
local hg_attachment_draw_distance = CreateClientConVar("hg_attachment_draw_distance", 0, true, nil, "расстояние достижений", 0, 4096)

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

local gradient_l = Material("vgui/gradient-l")
local gradient_d = surface.GetTextureID("vgui/gradient-d")
local gradient_l_tex = surface.GetTextureID("vgui/gradient-l")

local clr_bg = Color(30, 30, 36, 197)
local clr_accent = Color(200, 40, 40)
local clr_text = Color(225, 225, 225)
local clr_hover = Color(170, 170, 170)
local clr_sub = Color(105, 105, 105)
local clr_toggle_off = Color(50, 50, 55, 220)
local clr_toggle_on = Color(220, 220, 225, 255)
local title_grad_white = Color(255, 255, 255)
local title_grad_gray = Color(70, 70, 70)
local title_shadow = Color(0, 0, 0, 160)

local settings_pad_l = ScreenScale(16)
local settings_text_frac = 0.52
local settings_dock_x = ScrW() * 0.06

local function GetSettingsLayout(w)
    local ctrlX = math.floor(w * settings_text_frac)

    return {
        padL = settings_pad_l,
        ctrlX = ctrlX,
        ctrlW = w - ctrlX - ScreenScale(10),
        textW = math.max(ctrlX - settings_pad_l - ScreenScale(12), ScreenScale(80)),
    }
end

local function NumLerp(t, a, b)
    t = math.Clamp(tonumber(t) or 0, 0, 1)
    a = tonumber(a) or 0
    b = tonumber(b) or 0
    return a + (b - a) * t
end

local function GetTextWidth(text, font)
    surface.SetFont(font)
    local w = select(1, surface.GetTextSize(tostring(text or "")))
    return tonumber(w) or 0
end

local function DrawClippedText(text, font, x, y, maxW, color, alignY)
    local fullW = GetTextWidth(text, font)

    if fullW <= maxW then
        draw.SimpleText(text, font, x, y, color, TEXT_ALIGN_LEFT, alignY)
        return fullW
    end

    local trimmed = text
    while #trimmed > 1 and GetTextWidth(trimmed .. "...", font) > maxW do
        trimmed = trimmed:sub(1, -2)
    end

    draw.SimpleText(trimmed .. "...", font, x, y, color, TEXT_ALIGN_LEFT, alignY)
    return maxW
end

local function DrawRowText(text, font, x, y, normalW, fullW, expand, color, alignY)
    local drawW = NumLerp(expand, normalW, fullW)

    if expand > 0.95 or fullW <= normalW then
        draw.SimpleText(text, font, x, y, color, TEXT_ALIGN_LEFT, alignY)
        return
    end

    DrawClippedText(text, font, x, y, drawW, color, alignY)
end

local function GetExpandedCtrlX(w, layout, maxTextW, expand)
    w = tonumber(w) or 0
    maxTextW = tonumber(maxTextW) or 0
    expand = math.Clamp(tonumber(expand) or 0, 0, 1)

    local textW = tonumber(layout and layout.textW) or 0
    local padL = tonumber(layout and layout.padL) or settings_pad_l
    local expandedTextW = NumLerp(expand, textW, maxTextW)
    local ctrlX = padL + expandedTextW + ScreenScale(12)
    local minCtrlX = math.floor(w * settings_text_frac)

    return math.Clamp(ctrlX, minCtrlX, w - ScreenScale(80))
end

surface.CreateFont("ZC_Settings_Title", {
    font = "Bahnschrift",
    size = ScreenScale(28),
    weight = 800,
    antialias = true,
    extended = true
})

local function TextChars(text)
    local chars = {}

    if utf8 and utf8.codes then
        for _, code in utf8.codes(text) do
            chars[#chars + 1] = utf8.char(code)
        end
    else
        for i = 1, #text do
            chars[#chars + 1] = text:sub(i, i)
        end
    end

    return chars
end

local function MakePanelClickable(panel, onClick)
    if not IsValid(panel) then return end
    panel:SetMouseInputEnabled(true)
    function panel:OnMousePressed(mouseCode)
        if mouseCode == MOUSE_LEFT and onClick then
            onClick(self)
        end
    end
end

local function PanelHovered(panel)
    if not IsValid(panel) then return false end
    if panel:IsHovered() then return true end

    for _, child in ipairs(panel:GetChildren()) do
        if IsValid(child) and child:IsHovered() then
            return true
        end
    end

    return false
end

local font = function() -- hg_coolvetica:GetBool() and "Coolvetica" or "Bahnschrift"
    local usefont = "Bahnschrift"

    if hg_font:GetString() != "" then
        usefont = hg_font:GetString()
    end

    return usefont
end

surface.CreateFont("ZCity_setiings_tiny", {
	font = font(),
	size = ScreenScale(7),
	weight = 100
})

surface.CreateFont("ZCity_setiings_fine", {
	font = font(),
	size = ScreenScale(10),
	weight = 100
})

surface.CreateFont("ZCity_setiings_category", {
	font = font(),
	size = ScreenScale(15),
	weight = 100
})


hg.settings:AddOpt("Gameplay","hg_old_notificate", "Старые уведомления")
hg.settings:AddOpt("Gameplay","hg_cheats", "Включить читы")
hg.settings:AddOpt("Gameplay","hg_showthoughts", "Показывайть свои мысли")
hg.settings:AddOpt("Gameplay","hg_hints", "показывать подсказки")
hg.settings:AddOpt("Gameplay","hg_gary", "HG GARY")
hg.settings:AddOpt("Gameplay","hg_deathfadeout", "Death fade out")
--hg_gary
--hg_deathfadeout
if not game.IsDedicated() then
	hg.settings:AddOpt("Serverside gameplay","hg_toughnpcs", "Tough npcs")
	hg.settings:AddOpt("Serverside gameplay","hg_thirdperson", "Третье лицо (WIP)")
	hg.settings:AddOpt("Serverside gameplay","hg_legacycam", "Старая камера")
	hg.settings:AddOpt("Serverside gameplay","hg_ragdollcombat", "Боевой режим ragdoll")
	hg.settings:AddOpt("Serverside gameplay","hg_movement_stamina_debuff", "Снижение выносливости при движении")
	hg.settings:AddOpt("Serverside gameplay","hg_furcity", "фурсити")
	hg.settings:AddOpt("Serverside gameplay","hg_appearance_access_for_all", "Внешний вид полный доступ для всех", nil, nil, "bool")
	hg.settings:AddOpt("Serverside gameplay","hg_healanims", "Анимация лечения и еды")
	hg.settings:AddOpt("Serverside gameplay","hg_aimtoshoot", "Система стрельбы, похожая на DarkRP (не работает)")
	hg.settings:AddOpt("Serverside gameplay","hg_slings", "Sling system")
end
--hg_appearance_access_for_all
--hg_furcity
--hg_legacycam
--hg_toughnpcs

hg.settings:AddOpt("Debug","hg_show_hitposmuzzle", "Показывает хитпосы с оружием")
hg.settings:AddOpt("Debug","hg_setzoompos", "Редактируйте масштабирование оружия, проверяйте результаты на консоли")
hg.settings:AddOpt("Debug","hg_show_hitbox", "Показывать хитбоксы")

hg.settings:AddOpt("Optimization","hg_potatopc", "говно компутер мод")
hg.settings:AddOpt("Optimization","hg_anims_draw_distance", "Анимация Увеличивает расстояние", true, nil, "int")
hg.settings:AddOpt("Optimization","hg_anim_fps", "анимация FPS", nil, nil, "int")
hg.settings:AddOpt("Optimization","hg_attachment_draw_distance", "Расстояние обвесов на оружиях", true, nil, "int")
hg.settings:AddOpt("Optimization","hg_maxsmoketrails", "Максимальное количество дымовых следов", nil, nil, "int")
hg.settings:AddOpt("Optimization","hg_tpik_distance", "TPIK Расстояние рендеринга", true, nil, "int")

hg.settings:AddOpt("Blood","hg_blood_draw_distance", "Расстояние крови")
hg.settings:AddOpt("Blood","hg_blood_fps", "Кровь FPS")
hg.settings:AddOpt("Blood","hg_blood_sprites", "Спрайты крови (ОТКЛЮЧЕНЫ ДЛЯ ВСЕХ)")
hg.settings:AddOpt("Blood","hg_old_blood", "старая кровь")

hg.settings:AddOpt("UI","hg_font", "Изменить пользовательский шрифт", false, true)

hg.settings:AddOpt("Weapons","hg_weaponshotblur_enable", "Размытие при стрельбе")
hg.settings:AddOpt("Weapons","hg_dynamic_mags", "Динамическая проверка боеприпасов")
hg.settings:AddOpt("Weapons","hg_zoomsensitivity", "чувствительный прицел")
hg.settings:AddOpt("Weapons","hg_highpitchgunfire", "Переключение звуков стрельбы на высоких частотах внутри зданий")

hg.settings:AddOpt("View","hg_firstperson_death", "Смерть от первого лица")
hg.settings:AddOpt("View","hg_fov", "поле зрения")
hg.settings:AddOpt("View","hg_newspectate", "Плавная камера наблюдателя")
hg.settings:AddOpt("View","hg_cshs_fake", "C'sHS Ragdoll камера")
hg.settings:AddOpt("View","hg_gun_cam", "оружейная камера (для админов)")
hg.settings:AddOpt("View","hg_nofovzoom", "выключить/включить FOV Zoom")
hg.settings:AddOpt("View","hg_realismcam", "Realism camera (shitty)")
hg.settings:AddOpt("View","hg_gopro", "GoPro камера (не работает)")
hg.settings:AddOpt("View","hg_newfakecam", "New fake camera")
hg.settings:AddOpt("View","hg_leancam_mul", "Lean camera mul", true, nil, "int")
hg.settings:AddOpt("View","hg_gun_cam", "Оружейная камера (WIP только для админов)")
--hg_hints
--hg_leancam_mul
  --hg_newfakecam
hg.settings:AddOpt("Sound","hg_dmusic", "Включить музыку")
hg.settings:AddOpt("Sound","hg_quietshots", "включить/выключить тихие звуки выстрелов")


function hg.CreateCategory(ctgName, ParentPanel, yPos)
    local pppanel = vgui.Create("DPanel", ParentPanel)
    pppanel:SetSize(ParentPanel:GetWide(), ScreenScale(18))
    pppanel:SetPos(0, yPos)
    pppanel:SetMouseInputEnabled(true)
    pppanel.SettingsHover = 0

    local ctgText = string.upper(ctgName)
    pppanel.CtgFullW = GetTextWidth(ctgText, "ZCity_Small")

    pppanel.Paint = function(self, w, h)
        local drawX = ScreenScale(16)
        local t = RealTime() * 7
        local chars = GetTextChars(ctgText)
        local cx = drawX

        surface.SetFont("ZCity_Small")
        for i, char in ipairs(chars) do
            local cw = surface.GetTextSize(char)
            local shimmer = (math.sin(t - i * 0.4) + 1) * 0.5
            local col_shimmer = Color(40, 40, 40):Lerp(Color(255, 255, 255), shimmer)
            
            local v = self.SettingsHover or 0
            local col = title_grad_white:Lerp(col_shimmer, v)

            draw.SimpleText(char, "ZCity_Small", cx + 1, h * 0.5 + 1, Color(0, 0, 0, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(char, "ZCity_Small", cx, h * 0.5, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            cx = cx + cw
        end
    end

    pppanel.Think = function(self)
        self.SettingsHover = LerpFT(0.2, self.SettingsHover or 0, self:IsHovered() and 1 or 0)
    end

    return pppanel
end

function hg.GetConVarType(convar)
    local stringv = convar:GetString()
    local floatVal = convar:GetFloat()
    local intVal = convar:GetInt()
    local boolVal = convar:GetBool()

    if (stringv == '0' and not boolVal) or (stringv == '1' and boolVal) then
        return 'bool'
    end

    if tonumber(stringv) then
        if floatVal ~= intVal or string.find(stringv, "%.") then
            return "int"
        end

        if intVal == floatVal then
            return "int"
        end
    end

    return "string"
end

local function SetConVarValue(convar, value)
    if not convar then
        return
    end

    local name = convar.GetName and convar:GetName()
    if not name or name == "" then
        return
    end

    if isbool(value) then
        RunConsoleCommand(name, value and "1" or "0")
        return
    end

    RunConsoleCommand(name, tostring(value))
end

local function StyleNumSlider(slider)
    if not IsValid(slider) then return end

    slider:SetDark(true)
    slider.Paint = function() end
    slider.Label:SetVisible(false)

    if IsValid(slider.TextArea) then
        slider.TextArea:SetVisible(false)
    end

    if IsValid(slider.Slider) then
        slider.Slider.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, h * 0.5 - 2, w, 4, Color(45, 45, 50, 255))
        end

        if IsValid(slider.Slider.Knob) then
            slider.Slider.Knob.Paint = function(self, w, h)
                local col = self:IsHovered() and clr_hover or clr_text
                draw.RoundedBox(0, 0, 0, w, h, col)
            end
        end
    end
end

function hg.CreateButton(buttonData, convarName, ParentPanel, yPos)
    local convar = GetConVar(convarName)

    if not convar then 
        return 
    end
    local pppanel = vgui.Create("DPanel", ParentPanel)
    pppanel:SetSize(ParentPanel:GetWide(), ScreenScale(28))
    pppanel:SetPos(0, yPos)
    pppanel.SettingsHover = 0

    surface.SetFont("ZCity_Tiny")
    local _, helpH = surface.GetTextSize(convar:GetHelpText() or "")
    local hasHelp = convar:GetHelpText() and convar:GetHelpText() ~= ""
    if hasHelp then
        pppanel:SetTall(ScreenScale(34) + helpH * 0.5)
    end

    convarType = buttonData[6] or hg.GetConVarType(convar)
    local layout = GetSettingsLayout(pppanel:GetWide())
    local helpText = convar:GetHelpText() or ""

    pppanel:SetMouseInputEnabled(true)
    pppanel.TitleText = buttonData[3]
    pppanel.HelpText = helpText
    pppanel.SettingsTitleW = GetTextWidth(buttonData[3], "ZCity_Small")
    pppanel.SettingsHelpW = hasHelp and GetTextWidth(helpText, "ZCity_Tiny") or 0
    pppanel.SettingsMaxTextW = math.max(pppanel.SettingsTitleW, pppanel.SettingsHelpW)
    pppanel.NeedsExpand = pppanel.SettingsTitleW > layout.textW or pppanel.SettingsHelpW > layout.textW

    local function UpdateControlPositions(expand)
        expand = math.Clamp(tonumber(expand) or 0, 0, 1)
        local w = pppanel:GetWide()
        local rowLayout = GetSettingsLayout(w)
        local ctrlX = GetExpandedCtrlX(w, rowLayout, pppanel.SettingsMaxTextW, expand)
        local ctrlW = w - ctrlX - ScreenScale(10)
        local rowCtrlY = pppanel:GetTall() * 0.5

        if IsValid(pppanel.Toggle) then
            local tw, th = pppanel.Toggle:GetSize()
            pppanel.Toggle:SetPos(ctrlX + ctrlW - tw, rowCtrlY - th * 0.5)
        end

        if IsValid(pppanel.ValueLabel) and IsValid(pppanel.Slider) then
            local valW = ScreenScale(42)
            local sliderH = ScreenScale(14)
            local sliderW = math.max(ctrlW - valW - ScreenScale(8), ScreenScale(40))

            pppanel.ValueLabel:SetPos(ctrlX, rowCtrlY - sliderH * 0.5)
            pppanel.Slider:SetSize(sliderW, sliderH)
            pppanel.Slider:SetPos(ctrlX + valW + ScreenScale(8), rowCtrlY - sliderH * 0.5)
        end

        if IsValid(pppanel.TextEntry) then
            local entryW = ScreenScale(80)
            pppanel.TextEntry:SetPos(ctrlX + ctrlW - entryW, rowCtrlY - pppanel.TextEntry:GetTall() * 0.5)
        end
    end

    pppanel.UpdateControlPositions = UpdateControlPositions

    pppanel.Paint = function(self, w, h)
        local hover = tonumber(self.SettingsHover) or 0
        local expand = self.NeedsExpand and hover or 0
        local col = clr_text:Lerp(clr_hover, hover)
        local subCol = clr_sub:Lerp(Color(140, 140, 145), hover)
        local rowLayout = GetSettingsLayout(w)
        local titleY = hasHelp and h * 0.26 or h * 0.5

        local v = self.SettingsHover or 0
        local strTitle = self.TitleText
        local ntxt = ""
        for i = 1, #strTitle do
            local char = strTitle:sub(i, i)
            if i <= math.ceil(#strTitle * v) then
                ntxt = ntxt .. string.upper(char)
            else
                ntxt = ntxt .. char
            end
        end

        local chars = GetTextChars(ntxt)
        local cx = rowLayout.padL
        local t = RealTime() * 7
        surface.SetFont("ZCity_Small")

        for i, char in ipairs(chars) do
            local cw = surface.GetTextSize(char)
            local shimmer = (math.sin(t - i * 0.4) + 1) * 0.5
            local col_shimmer = Color(30, 30, 30):Lerp(Color(255, 255, 255), shimmer)
            local finalCol = clr_text:Lerp(col_shimmer, v)

            draw.SimpleText(char, "ZCity_Small", cx + 1, titleY + 1, Color(0, 0, 0, 180 * v), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(char, "ZCity_Small", cx, titleY, finalCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            cx = cx + cw
        end

        if hasHelp then
            draw.SimpleText(self.HelpText, "ZCity_Tiny", rowLayout.padL, h * 0.74, subCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    pppanel.Think = function(self)
        self.SettingsHover = LerpFT(0.2, tonumber(self.SettingsHover) or 0, PanelHovered(self) and 1 or 0)
        local expand = self.NeedsExpand and (tonumber(self.SettingsHover) or 0) or 0
        self:UpdateControlPositions(expand)
        self:SetZPos(expand > 0.01 and 50 or 0)
    end

    local ctrlY = pppanel:GetTall() * 0.5

    if convarType == 'bool' then
        local toggleW, toggleH = ScreenScale(36), ScreenScale(14)
        local toggle = vgui.Create("DPanel", pppanel)
        pppanel.Toggle = toggle
        toggle:SetSize(toggleW, toggleH)
        toggle:SetPos(layout.ctrlX + layout.ctrlW - toggleW, ctrlY - toggleH * 0.5)

        local animProgress = convar:GetBool() and 1 or 0
        local targetProgress = animProgress

        toggle.Paint = function(s, w, h)
            if animProgress ~= targetProgress then
                animProgress = Lerp(FrameTime() * 8, animProgress, targetProgress)
            end

            local trackCol = clr_toggle_off:Lerp(clr_toggle_on, animProgress)
            draw.RoundedBox(0, 0, 0, w, h, trackCol)

            local slsize = h - 6
            local slPos = Lerp(animProgress, 3, w - slsize - 3)
            local knobCol = Color(
                Lerp(animProgress, 120, 255),
                Lerp(animProgress, 120, 255),
                Lerp(animProgress, 125, 255)
            )
            draw.RoundedBox(0, slPos, 3, slsize, slsize, knobCol)
        end

        MakePanelClickable(toggle, function()
            if not convar then return end
            local newValue = not convar:GetBool()
            SetConVarValue(convar, newValue)
            surface.PlaySound("shitty/tap_depress.wav")
            targetProgress = newValue and 1 or 0
        end)

    elseif convarType == 'int' then
        local valW = ScreenScale(42)
        local sliderH = ScreenScale(14)
        local sliderW = layout.ctrlW - valW - ScreenScale(8)

        local valueLabel = vgui.Create("DLabel", pppanel)
        pppanel.ValueLabel = valueLabel
        valueLabel:SetPos(layout.ctrlX, ctrlY - sliderH * 0.5)
        valueLabel:SetSize(valW, sliderH)
        valueLabel:SetTextColor(clr_text)
        valueLabel:SetFont("ZCity_Tiny")
        valueLabel:SetContentAlignment(6)

        local slider = vgui.Create("DNumSlider", pppanel)
        pppanel.Slider = slider
        slider:SetSize(sliderW, sliderH)
        slider:SetPos(layout.ctrlX + valW + ScreenScale(8), ctrlY - sliderH * 0.5)
        slider:SetText("")

        local min = convar:GetMin() or 0
        local max = convar:GetMax() or 100
        local decimals = buttonData[4] and 2 or (convar:GetFloat() ~= convar:GetInt() and 2 or 0)

        slider:SetMin(min)
        slider:SetMax(max)
        slider:SetDecimals(decimals)
        slider:SetValue(decimals > 0 and convar:GetFloat() or convar:GetInt())
        StyleNumSlider(slider)

        function slider:OnValueChanged(val)
            if convar then
                SetConVarValue(convar, decimals > 0 and math.Round(val, decimals) or math.Round(val))
            end
        end

        slider.Think = function()
            if convar then
                valueLabel:SetText(decimals > 0 and string.format("%." .. decimals .. "f", convar:GetFloat()) or tostring(convar:GetInt()))
            end
        end
        slider:OnValueChanged(slider:GetValue())

    elseif convarType == 'string' then
        local entryW = ScreenScale(80)
        local textEntry = vgui.Create("DTextEntry", pppanel)
        pppanel.TextEntry = textEntry
        textEntry:SetSize(entryW, ScreenScale(14))
        textEntry:SetPos(layout.ctrlX + layout.ctrlW - entryW, ctrlY - textEntry:GetTall() * 0.5)
        textEntry:SetText(convar:GetString())
        textEntry:SetUpdateOnType(true) 
        textEntry:SetFont('ZCity_Tiny')
        
    
        textEntry.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 45, 220))
            surface.SetDrawColor(90, 90, 95, 180)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            self:DrawTextEntryText(clr_text, clr_hover, color_white)
        end
        
        function textEntry:OnValueChange(val)
            if convar then
                SetConVarValue(convar, val)
            end
        end
    end
    
    return pppanel
end

function hg.DrawSettings(ParentPanel)
    ParentPanel:SetAlpha(0)
    if ParentPanel.SetDraggable then
        ParentPanel:SetDraggable(false)
    end

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
        surface.SetTexture(gradient_l_tex)
        surface.DrawTexturedRect(0, 0, w, h)

        surface.SetDrawColor(60, 60, 60, 30)
        surface.SetTexture(gradient_d)
        surface.DrawTexturedRect(0, 0, w, h)
    end
    ParentPanel:AlphaTo(255, 0.15, 0)

    local dockW = math.max(ScrW() * 0.42, 520)
    local headerH = ScreenScaleH(70)

    local header = vgui.Create("DPanel", ParentPanel)
    header:SetSize(dockW, headerH)
    header:SetPos(settings_dock_x, ScrH() * 0.08)
    header:SetMouseInputEnabled(false)
    header.Paint = function(s, w, h)
        local title = "Настройки"
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
            
            local currentStr = table.concat(chars, "", 1, i)
            accumulatedW = surface.GetTextSize(currentStr)
        end
    end

    local pppanel3 = vgui.Create("DScrollPanel", ParentPanel)
    pppanel3:SetSize(dockW, ScrH() * 0.72)
    pppanel3:SetPos(settings_dock_x, header:GetY() + headerH + ScreenScaleH(8))
    pppanel3.Paint = function() end

    local vbar = pppanel3:GetVBar()
    vbar:SetWide(ScreenScale(4))
    vbar.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(66, 66, 66, 131))
    end
    vbar.btnUp.Paint = function() end
    vbar.btnDown.Paint = function() end
    vbar.btnGrip.Paint = function(s, w, h)
        local col = s:IsHovered() and clr_hover or Color(120, 120, 125, 150)
        draw.RoundedBox(0, 0, 0, w, h, col)
    end

    local yOffset = ScreenScaleH(4)

    for categoryName, categoryTable in pairs(hg.settings.tbl) do
        local category = hg.CreateCategory(categoryName, pppanel3, yOffset)
        yOffset = yOffset + category:GetTall() + 12
        for convarName, settingData in pairs(categoryTable) do
            local vbv = hg.CreateButton(settingData,convarName,pppanel3,yOffset)
            if not vbv then continue end
            yOffset = yOffset + (vbv:GetTall()) + 12
        end
    end
    local pppanel23 = vgui.Create('DPanel', pppanel3)
    pppanel23:SetSize(0, 0)
    pppanel23:SetPos(0,yOffset+12)
end
