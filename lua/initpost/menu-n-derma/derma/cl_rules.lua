hg = hg or {}

local clr_category_bg = Color(60, 60, 60, 145)
local clr_category_border = Color(42, 42, 42, 184)
local clr_rule_bg = Color(43, 43, 43, 145)
local clr_rule_border = Color(47, 47, 47, 145)
local clr_text = Color(255, 255, 255, 104)

local function CreateCategory(name, parent, yOffset)
    local pppanel = vgui.Create('DPanel', parent)
    pppanel:SetSize(parent:GetWide() / 1.05, parent:GetTall() * 0.07)
    pppanel:SetPos(parent:GetWide() / 2 - pppanel:GetWide() / 2, yOffset)
    pppanel.Paint = function(self, w, h)
        surface.SetDrawColor(clr_category_bg)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(clr_category_border)
        surface.DrawRect(0, h - 5, w, 5)

        draw.SimpleText(name, 'ZCity_setiings_category', w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    return pppanel
end

local function AddRule(text, parent, yOffset)
    local pppanel = vgui.Create('DPanel', parent)
    pppanel:SetWide(parent:GetWide() / 1.05)
    pppanel:SetPos(parent:GetWide() / 2 - pppanel:GetWide() / 2, yOffset)

    local label = vgui.Create("DLabel", pppanel)
    label:SetFont("ZCity_Tiny")
    label:SetTextColor(clr_text)
    label:SetText(text)
    label:SetWrap(true)
    label:SetAutoStretchVertical(true)
    label:Dock(FILL)
    label:DockMargin(30, 10, 10, 10)

    pppanel.Paint = function(self, w, h)
        surface.SetDrawColor(clr_rule_bg)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(clr_rule_border)
        surface.DrawRect(0, h - 3, w, 3)
    end

    label:InvalidateLayout(true)
    pppanel:SetTall(label:GetTall() + 20)

    return pppanel
end

function hg.DrawRules(ParentPanel)
    ParentPanel:SetAlpha(0)
    ParentPanel.Paint = function(self, w, h) end
    ParentPanel:AlphaTo(255, 0.15, 0)

    local scroll = vgui.Create('DScrollPanel', ParentPanel)
    scroll:SetSize(ParentPanel:GetWide(), ParentPanel:GetTall())
    scroll:SetPos(0, 0)
    scroll.Paint = function() end

    local yOffset = scroll:GetTall() / 100
    local rulesOrder = { "Основные правила", "Правила Roleplay" }
    local rules = {
        ["Основные правила"] = {
            "1. Не убивайте без причины (RDM).",
            "2. Не арестовывайте без причины (RDA).",
            "3. Уважайте других игроков и администрацию.",
            "4. Запрещено использование стороннего ПО (Читов).",
            "5. Не используйте баги игры."
        },
        ["Правила Roleplay"] = {
            "1. Соблюдайте свою роль.",
            "2. Не используйте информацию из жизни (MetaGaming).",
            "3. Не делайте того, что невозможно в реальности (PowerGaming).",
            "4. FearRP - бойтесь за свою жизнь.",
            "5. New Life Rule (NLR) - после смерти забудьте прошлую жизнь."
        }
    }

    for _, categoryName in ipairs(rulesOrder) do
        local ruleList = rules[categoryName]
        local category = CreateCategory(categoryName, scroll, yOffset)
        yOffset = yOffset + category:GetTall() + 12
        for _, ruleText in ipairs(ruleList) do
            local rulePanel = AddRule(ruleText, scroll, yOffset)
            yOffset = yOffset + rulePanel:GetTall() + 8
        end
        yOffset = yOffset + 10
    end

    local spacer = vgui.Create('DPanel', scroll)
    spacer:SetSize(0, 0)
    spacer:SetPos(0, yOffset + 12)
end
