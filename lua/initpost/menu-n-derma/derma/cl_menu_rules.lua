local gradient_l = Material("vgui/gradient-l")
local blur = Material("pp/blurscreen")

local sw, sh = ScrW(), ScrH()
local xbars = 17
local ybars = 30

local clr_title = Color(200, 50, 50, 255)
local clr_rule_num = Color(100, 200, 255, 255)
local clr_desc = Color(180, 180, 180, 255)
local clr_punishment = Color(255, 100, 100, 255)

hg.rules = hg.rules or {}

local col_red = Color(255, 100, 100)
local col_yellow = Color(255, 255, 100)
local col_orange = Color(255, 180, 100)

hg.rules.list = {
    { category = "0. Основное", items = {
        { name = "0.1", desc = "Незнание правил не освобождает от ответственности." },
        { name = "0.2", desc = "Любые попытки обойти правила (лазейки) считаются нарушением." },
        { name = "0.3", desc = "Решение администрации является окончательным." }
    }},
    { category = "1. Общие правила", items = {
        { name = "1.1 — Дискредитация сервера", desc = "Запрещено оскорблять сервер, рекламировать другие проекты или распространять ложную информацию.", punishment = "бан навсегда", color = col_red },
        { name = "1.2 — Оскорбления и токсичность", desc = "Запрещены (оскорбление родных), травля.", punishment = "мут / гаг — 30 минут; повтор — бан до 1 дня; серьезное нарушение — до 7 дней", color = col_yellow },
        { name = "1.3 — Выдача себя за другого", desc = "Запрещено копировать ник или аватар, а также притворяться другим игроком. Срок увеличивается при выдаче себя за админа.", punishment = "бан 16 часов (при выдаче за админа 3 дня)", color = col_orange },
        { name = "1.4 — Обход наказания", desc = "Использование твинков или других способов обхода наказания.", punishment = "бан навсегда", color = col_red },
        { name = "1.5 — Спам", desc = "Флуд, спам звуками (Soundpad), засорение чата. В том числе включение NSFW звуков. Использовать soundpad разрешено в меру.", punishment = "бан — 20 минут; повтор — до 5 часов", color = col_yellow },
        { name = "1.6 — Провокации", desc = "Подставы и намеренные попытки заставить другого игрока нарушить правила.", punishment = "бан до 3 недель", color = col_orange },
        { name = "1.7 — Запрещённый контент", desc = "NSFW, шок-контент, экстремистская символика.", punishment = "бан 2 дня", color = col_red },
        { name = "1.8 — Угрозы и слив данных", desc = "Любые угрозы или распространение личной информации.", punishment = "бан навсегда", color = col_red },
        { name = "1.9 — Злоупотребление лазейками", desc = "Использование недоработок правил или механик в свою пользу. В частности — использование багов сервера в личных целях.", punishment = "бан до 5 дней", color = col_orange },
        { name = "1.10 — Давление на администрацию", desc = "Спам жалобами, споры после финального решения, угрозы.", punishment = "бан до 2 дней", color = col_yellow },
        { name = "1.11 — Неадекватное поведение", desc = "Крики в микрофон, троллинг, намеренное раздражение игроков.", punishment = "бан до 6 часов", color = col_yellow }
    }},
    { category = "2. Игровые правила (KIROCITY)", items = {
        { name = "2.1 — Читы", desc = "Любые сторонние программы, дающие преимущество.", punishment = "бан навсегда + снятие доната", color = col_red },
        { name = "2.2 — Баги и абузы", desc = "Использование багов, дюпов и абуз механик.", punishment = "2 недели; серьезное нарушение — до 3 месяцев", color = col_orange },
        { name = "2.3 — Сговор (тиминг)", desc = "Помощь врагам или игра в сговоре ради преимущества.", punishment = "бан 1 час", color = col_yellow },
        { name = "2.4 — Мониторинг", desc = "Передача информации после смерти.", punishment = "бан 2 часа", color = col_yellow },
        { name = "2.5 — Помеха игре", desc = "Блокировка проходов, спам объектами, мешание другим игрокам.", punishment = "бан от 1 часа до 1 дня", color = col_orange },
        { name = "2.6 — Лив от наказания", desc = "Выход во время разборки или перед наказанием.", punishment = "бан до 2 дней", color = col_orange },
        { name = "2.7 — Обман администрации", desc = "Ложные жалобы или поддельные доказательства.", punishment = "бан до 1 дня", color = col_orange },
        { name = "2.8 — Руин (порча игры)", desc = "Намеренные действия, портящие игру другим игрокам.", punishment = "бан до 7 дней", color = col_red },
        { name = "2.9 - Массовые убийства", desc = "Человек не является предателем, а иноцентом и начинает без причины убивать людей.", punishment = "бан до 2 часов", color = col_red },
        { name = "2.10 — Массовые нарушения", desc = "Многократные или систематические нарушения.", punishment = "вплоть до перманента", color = col_red },
        { name = "2.11 — Намеренный лаг сервера", desc = "Создание лагов любыми способами.", punishment = "бан вплоть до перманента", color = col_red }
    }}
}

function hg.DrawRules(ParentPanel)
    ParentPanel:SetAlpha(0)
    ParentPanel.BackgroundAnim = 0
    ParentPanel.GridFadeIn = 0
    
    ParentPanel.Paint = function(self,w,h)
        local pinkAnim = (hg and hg.SaladPinkAnim) or 0

        self.BackgroundAnim = LerpFT(0.08, self.BackgroundAnim, 1)
        self.GridFadeIn = LerpFT(0.1, self.GridFadeIn, 1)

        surface.SetDrawColor(28, 28, 28, 255)
        surface.DrawRect(0, 0, w, h)

        local gridTime = CurTime() * 30
        local gridAlpha = 20 * self.GridFadeIn
        local gridR = math.floor(Lerp(pinkAnim, 107, 220))
        local gridG = math.floor(Lerp(pinkAnim, 107, 60))
        local gridB = math.floor(Lerp(pinkAnim, 107, 160))

        for i = 1, (ybars + 1) do
            local lineAlpha = gridAlpha * math.Clamp((self.GridFadeIn - i * 0.01) * 2, 0, 1)
            surface.SetDrawColor(gridR, gridG, gridB, lineAlpha)
            surface.DrawRect((sw / ybars) * i - (gridTime % (sw / ybars)), 0, ScreenScale(1), sh)
        end
        for i = 1, (xbars + 1) do
            local lineAlpha = gridAlpha * math.Clamp((self.GridFadeIn - i * 0.01) * 2, 0, 1)
            surface.SetDrawColor(gridR, gridG, gridB, lineAlpha)
            surface.DrawRect(0, (sh / xbars) * (i - 1) + (gridTime % (sh / xbars)), sw, ScreenScale(1))
        end

        if pinkAnim > 0.01 then
            local pp = math.sin(CurTime() * 0.8) * 0.15 + 0.85
            surface.SetDrawColor(160, 15, 90, math.floor(pinkAnim * 100 * pp))
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(255, 60, 160, math.floor(pinkAnim * 80))
            surface.DrawRect(0, 0, w, 2)
            surface.DrawRect(0, h - 2, w, 2)
            surface.DrawRect(0, 0, 2, h)
            surface.DrawRect(w - 2, 0, 2, h)
        end
    end
    hg.DrawBlur(ParentPanel, 5)
    ParentPanel:AlphaTo(255,0.15,0)

    local titleLabel = vgui.Create("DLabel", ParentPanel)
    titleLabel:SetPos(ScreenScale(20), ScreenScale(20))
    titleLabel:SetFont("ZCity_setiings_category")
    titleLabel:SetText("RULES")
    titleLabel:SizeToContents()
    titleLabel:SetTextColor(Color(0, 0, 0, 0))
    titleLabel.AppearAnim = 0
    
    titleLabel.Paint = function(self, w, h)
        self.AppearAnim = LerpFT(0.12, self.AppearAnim, 1)
        draw.SimpleText("RULES", "ZCity_setiings_category", 2, 2, Color(0, 0, 0, self.AppearAnim * 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("RULES", "ZCity_setiings_category", 0, 0, Color(clr_title.r, clr_title.g, clr_title.b, self.AppearAnim * 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local scrollPanel = vgui.Create("DScrollPanel", ParentPanel)
    scrollPanel:SetSize(ParentPanel:GetWide() - ScreenScale(60), ParentPanel:GetTall() - ScreenScale(100))
    scrollPanel:SetPos(ScreenScale(20), ScreenScale(80))
    scrollPanel.Paint = function()end

    local vbar = scrollPanel:GetVBar()
    vbar:SetSize(ScreenScale(10), 0)
    vbar.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 30, 200))
    end
    vbar.btnUp.Paint = function()end
    vbar.btnDown.Paint = function()end
    vbar.btnGrip.Paint = function(self, w, h)
        local col = self:IsHovered() and Color(100, 100, 130, 255) or Color(70, 70, 90, 255)
        draw.RoundedBox(4, 2, 2, w - 4, h - 4, col)
    end

    local yOffset = 0
    local ruleIndex = 0
    for _, catData in ipairs(hg.rules.list) do
        local catLabel = vgui.Create("DLabel", scrollPanel)
        catLabel:SetPos(ScreenScale(10), yOffset)
        catLabel:SetFont("ZCity_setiings_fine")
        catLabel:SetText(catData.category)
        catLabel:SetTextColor(clr_title)
        catLabel:SizeToContents()
        yOffset = yOffset + catLabel:GetTall() + ScreenScale(5)

        for _, item in ipairs(catData.items) do
            ruleIndex = ruleIndex + 1
            local panelHeight = item.punishment and ScreenScale(50) or ScreenScale(35)
            local rulePanel = vgui.Create("DPanel", scrollPanel)
            rulePanel:SetSize(scrollPanel:GetWide() - ScreenScale(15), panelHeight)
            rulePanel:SetPos(ScreenScale(5), yOffset)
            rulePanel.HoverAnim = 0
            rulePanel.AppearAnim = 0
            rulePanel.AppearStart = CurTime() + ruleIndex * 0.03
            
            rulePanel.Paint = function(self, w, h)
                if CurTime() > self.AppearStart then self.AppearAnim = LerpFT(0.15, self.AppearAnim, 1) end
                self.HoverAnim = LerpFT(0.12, self.HoverAnim, self:IsHovered() and 1 or 0)
                local bgCol = Color(43 + (self.HoverAnim * 10), 43 + (self.HoverAnim * 10), 43 + (self.HoverAnim * 10), 145 * self.AppearAnim)
                draw.RoundedBox(4, 0, 0, w, h, bgCol)
                
                local accentCol = item.color or Color(100, 200, 255)
                surface.SetDrawColor(accentCol.r, accentCol.g, accentCol.b, (self.HoverAnim > 0 and 150 or 40) * self.AppearAnim)
                surface.DrawRect(0, 0, 3, h)
            end

            local nameLabel = vgui.Create("DLabel", rulePanel)
            nameLabel:SetPos(ScreenScale(10), ScreenScale(5))
            nameLabel:SetFont("ZCity_setiings_fine")
            nameLabel:SetText(item.name)
            nameLabel:SetTextColor(clr_rule_num)
            nameLabel:SizeToContents()

            local descLabel = vgui.Create("DLabel", rulePanel)
            descLabel:SetPos(ScreenScale(10), ScreenScale(22))
            descLabel:SetFont("ZCity_setiings_tiny")
            descLabel:SetText(item.desc)
            descLabel:SetTextColor(clr_desc)
            descLabel:SetWide(rulePanel:GetWide() - ScreenScale(20))
            descLabel:SetWrap(true)
            descLabel:SetAutoStretchVertical(true)

            if item.punishment then
                local punLabel = vgui.Create("DLabel", rulePanel)
                punLabel:SetPos(ScreenScale(10), ScreenScale(35))
                punLabel:SetFont("ZCity_setiings_tiny")
                punLabel:SetText("Наказание: " .. item.punishment)
                punLabel:SetTextColor(clr_punishment)
                punLabel:SizeToContents()
            end

            yOffset = yOffset + panelHeight + ScreenScale(5)
        end
        yOffset = yOffset + ScreenScale(10)
    end
end