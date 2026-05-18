MODE.name = "slovopacana"

local MODE = MODE

local teams = {
    [0] = {
        name = "Чайники",
        color = Color(210, 120, 40),
        objective = "Уничтожьте Братву"
    },
    [1] = {
        name = "Братва",
        color = Color(40, 130, 220),
        objective = "Уничтожьте Чайников"
    }
}

function MODE:RenderScreenspaceEffects()
    if zb.ROUND_START + 7 < CurTime() then return end
    local fade = math.Clamp(zb.ROUND_START + 7 - CurTime(), 0, 1)
    surface.SetDrawColor(0, 0, 0, 255 * fade)
    surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end

local function DrawFriendlyMarkers()
    if not IsValid(lply) then return end
    local myTeam = lply:Team()
    if myTeam == TEAM_SPECTATOR then return end

    for _, ply in player.Iterator() do
        if ply == lply then continue end
        if not ply:Alive() then continue end
        if ply:Team() ~= myTeam then continue end

        local dist = lply:GetPos():Distance(ply:GetPos())
        if dist > 2600 then continue end

        local screenPos = (ply:GetPos() + Vector(0, 0, 82)):ToScreen()
        if not screenPos.visible then continue end

        local alpha = math.Clamp(255 - dist * 0.07, 80, 255)
        local text = "СВОЙ"

        surface.SetFont("ZB_InterfaceMedium")
        local tw, th = surface.GetTextSize(text)
        local bw, bh = tw + 16, th + 8
        local bx, by = screenPos.x - bw * 0.5, screenPos.y - 42

        draw.RoundedBox(6, bx, by, bw, bh, Color(25, 120, 25, alpha))
        surface.SetDrawColor(80, 255, 80, alpha)
        surface.DrawOutlinedRect(bx, by, bw, bh, 2)

        draw.SimpleText(text, "ZB_InterfaceMedium", screenPos.x, by + bh * 0.5, Color(210, 255, 210, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        local y = by + bh
        surface.DrawLine(screenPos.x, y, screenPos.x - 6, y + 9)
        surface.DrawLine(screenPos.x, y, screenPos.x + 6, y + 9)
        surface.DrawLine(screenPos.x - 6, y + 9, screenPos.x + 6, y + 9)
    end
end

function MODE:HUDPaint()
    if not IsValid(lply) then lply = LocalPlayer() end
    if not IsValid(lply) or not lply:Alive() then return end

    DrawFriendlyMarkers()

    if zb.ROUND_START + 8 < CurTime() then return end

    local fade = math.Clamp(zb.ROUND_START + 8 - CurTime(), 0, 1)
    local w, h = ScrW(), ScrH()
    local teamData = teams[lply:Team()] or teams[0]

    draw.SimpleText("Слово пацана", "ZB_HomicideMediumLarge", w * 0.5, h * 0.1, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("Команда: " .. teamData.name, "ZB_HomicideMediumLarge", w * 0.5, h * 0.5, Color(teamData.color.r, teamData.color.g, teamData.color.b, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(teamData.objective or "Уничтожьте противоположную команду", "ZB_HomicideMedium", w * 0.5, h * 0.9, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local spEndMenu

local function CloseEndMenu()
    if IsValid(spEndMenu) then
        spEndMenu:Close()
        spEndMenu = nil
    end
end

local function CreateEndMenu()
    CloseEndMenu()

    surface.PlaySound("ambient/alarms/warningbell1.wav")

    spEndMenu = vgui.Create("ZFrame")
    local frame = spEndMenu

    local sizeX, sizeY = ScrW() / 2.5, ScrH() / 1.2
    local posX, posY = ScrW() / 1.3 - sizeX / 2, ScrH() / 2 - sizeY / 2

    frame:SetPos(posX, posY)
    frame:SetSize(sizeX, sizeY)
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(false)
    frame:ShowCloseButton(false)

    local closebutton = vgui.Create("DButton", frame)
    closebutton:SetPos(5, 5)
    closebutton:SetSize(ScrW() / 20, ScrH() / 30)
    closebutton:SetText("")
    closebutton.DoClick = function()
        CloseEndMenu()
    end
    closebutton.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(28, 28, 28, 235))
        surface.SetDrawColor(180, 40, 40, 180)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("Закрыть", "ZB_InterfaceMedium", w * 0.5, h * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    frame.Paint = function(self, w, h)
        hg.DrawBlur(self)
        draw.RoundedBox(12, 0, 0, w, h, Color(255, 0, 0, 65))
        draw.RoundedBox(10, 2, 2, w - 4, h - 4, Color(0, 0, 0, 185))

        draw.SimpleText("Слово пацана", "ZB_InterfaceMediumLarge", w * 0.5, 18, color_white, TEXT_ALIGN_CENTER)
        draw.SimpleText("Игроки:", "ZB_InterfaceMediumLarge", w * 0.5, 44, color_white, TEXT_ALIGN_CENTER)
    end

    local list = vgui.Create("DScrollPanel", frame)
    list:SetPos(10, 80)
    list:SetSize(sizeX - 20, sizeY - 90)
    list.Paint = function(self, w, h)
        hg.DrawBlur(self)
        draw.RoundedBox(10, 0, 0, w, h, Color(255, 0, 0, 55))
        draw.RoundedBox(8, 2, 2, w - 4, h - 4, Color(0, 0, 0, 120))
    end

    for _, ply in player.Iterator() do
        if ply:Team() == TEAM_SPECTATOR then continue end

        local item = vgui.Create("DButton", list)
        item:SetSize(100, 50)
        item:Dock(TOP)
        item:DockMargin(8, 6, 8, 4)
        item:SetText("")

        item.Paint = function(self, w, h)
            local t = teams[ply:Team()] or teams[0]
            local base = ply:Alive() and Color(t.color.r, t.color.g, t.color.b, 220) or Color(85, 85, 85, 255)
            local lower = ply:Alive() and Color(math.max(t.color.r - 20, 0), math.max(t.color.g - 20, 0), math.max(t.color.b - 20, 0), 255) or Color(70, 70, 70, 255)

            draw.RoundedBox(8, 0, 0, w, h, base)
            draw.RoundedBoxEx(8, 0, h * 0.5, w, h * 0.5, lower, false, false, true, true)
            surface.SetDrawColor(0, 0, 0, 120)
            surface.DrawOutlinedRect(0, 0, w, h, 1)

            local name = ply:IsValid() and ply:Name() or "Отключился"
            if not ply:Alive() then
                name = name .. " - мертв"
            end

            surface.SetFont("ZB_InterfaceMediumLarge")
            surface.SetTextColor(255, 255, 255, 255)
            local nw, nh = surface.GetTextSize(name)
            surface.SetTextPos(15, h * 0.5 - nh * 0.5)
            surface.DrawText(name)

            local frags = tostring(ply:Frags() or 0)
            local fw, fh = surface.GetTextSize(frags)
            surface.SetTextPos(w - fw - 15, h * 0.5 - fh * 0.5)
            surface.DrawText(frags)
        end

        item.DoClick = function()
            if ply:IsBot() then return end
            gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
        end

        list:AddItem(item)
    end
end

net.Receive("slovopacana_roundend", function()
    CreateEndMenu()
end)

function MODE:RoundStart()
    CloseEndMenu()
end






