--
hg = hg or {}
hg.WeaponSelector = hg.WeaponSelector or {}
local WS = hg.WeaponSelector

function WS.GetPrintName( self )
	local class = self:GetClass()
	local phrase = language.GetPhrase(class)
	return phrase ~= class and phrase or self:GetPrintName()
end

WS.Show = 0
WS.Transparent = 0
WS.LastSelectedSlot = 0
WS.LastSelectedSlotPos = 0
WS.Anim = WS.Anim or {}
WS.Slide = 0

WS.SelectedSlot = 0
WS.SelectedSlotPos = 0

function WS.DrawText(text, font, posX, posY, color, textAlign)

    local ply = LocalPlayer()
    local brainDamage = 0
    if IsValid(ply) and ply.organism and ply.organism.brain then
        brainDamage = ply.organism.brain
    end
    

    if brainDamage > 0.15 then
        text = WS.GlitchText(text, brainDamage)
        

        local grayIntensity = 0
        if brainDamage >= 0.3 then
            grayIntensity = 1
        else
            grayIntensity = math.Clamp((brainDamage - 0.15) / 0.15, 0, 1)
        end
        
        local gray = math.floor(color.r * 0.299 + color.g * 0.587 + color.b * 0.114)
        color = Color(
            math.floor(Lerp(grayIntensity, color.r, gray)),
            math.floor(Lerp(grayIntensity, color.g, gray)),
            math.floor(Lerp(grayIntensity, color.b, gray)),
            color.a
        )
        

        local glitchIntensity = brainDamage >= 0.3 and 3 or (brainDamage - 0.15) * 2
        local time = CurTime() * (10 + brainDamage * 30) -- Ускоряем с повреждением
        local offsetX = math.sin(time + posX * 0.01) * glitchIntensity * (brainDamage >= 0.3 and 20 or 3 + brainDamage * 5)
        local offsetY = math.cos(time * 1.3 + posY * 0.01) * glitchIntensity * (brainDamage >= 0.3 and 15 or 2 + brainDamage * 4)
        
        posX = posX + offsetX
        posY = posY + offsetY
        

        local colorChance = brainDamage >= 0.3 and 0.9 or glitchIntensity * (0.3 + brainDamage * 0.4)
        if math.random() < colorChance then
            local colorShift = brainDamage >= 0.3 and 255 or 50 + brainDamage * 100
            color = Color(
                math.Clamp(color.r + math.random(-colorShift, colorShift), 0, 255),
                math.Clamp(color.g + math.random(-colorShift, colorShift), 0, 255),
                math.Clamp(color.b + math.random(-colorShift, colorShift), 0, 255),
                color.a
            )
        end
        

        local rgbChance = brainDamage >= 0.3 and 1.0 or glitchIntensity * (0.4 + brainDamage * 0.5)
        if math.random() < rgbChance then
            local separation = brainDamage >= 0.3 and 12 or 2 + brainDamage * 4
            local rgbAlpha = WS.Transparent * (brainDamage >= 0.3 and 255 or 100 + brainDamage * 100)
            draw.DrawText(text, font, posX - separation, posY, ColorAlpha(Color(255, 0, 0), rgbAlpha), textAlign)
            draw.DrawText(text, font, posX + separation, posY, ColorAlpha(Color(0, 255, 255), rgbAlpha), textAlign)
        end

        if brainDamage >= 0.3 or (brainDamage > 0.2 and math.random() < (brainDamage - 0.2) * 0.8) then
            local numCopies = brainDamage >= 0.3 and math.random(5, 12) or math.random(1, 3)
            for i = 1, numCopies do
                local copyX = posX + math.random(-30, 30) * (brainDamage >= 0.3 and 2 or brainDamage)
                local copyY = posY + math.random(-20, 20) * (brainDamage >= 0.3 and 2 or brainDamage)
                local copyAlpha = WS.Transparent * math.random(50, 180)
                local gray = math.floor(color.r * 0.299 + color.g * 0.587 + color.b * 0.114)
                draw.DrawText(text, font, copyX, copyY, ColorAlpha(Color(gray, gray, gray), copyAlpha), textAlign)
            end
        end
    end
    
    draw.DrawText( text, font, posX + 2, posY + 2, ColorAlpha(color_black,WS.Transparent*255) ,textAlign )
    draw.DrawText( text, font, posX, posY, ColorAlpha(color,WS.Transparent*255) ,textAlign )
end

function WS.GlitchText(text, brainDamage)

    text = tostring(text or "")
    
    if brainDamage < 0.15 then return text end
    

    local glitchChance = brainDamage >= 0.3 and 1.0 or (brainDamage - 0.15) * 1.2
    local result = ""
    local glitchChars = {"█", "▓", "▒", "░", "▄", "▀", "■", "□", "▪", "▫", "◆", "◇", "●", "○", "◘", "◙", "☺", "☻", "♠", "♣", "♥", "♦", "♪", "♫", "☼", "►", "◄", "↕", "‼", "¶", "§", "▬", "↨", "↑", "↓", "→", "←", "∟", "↔", "▲", "▼", "?", "!", "@", "#", "$", "%", "^", "&", "*"}
    

    if brainDamage >= 0.3 then
        local aggressiveChars = {"Ж", "Щ", "Ъ", "Ы", "Э", "Ю", "Я", "ё", "ъ", "ь", "ы", "э", "ю", "я", "ѐ", "ё", "ђ", "ѓ", "є", "ѕ", "і", "ї", "ј", "љ", "њ", "ћ", "ќ", "ѝ", "ў", "џ", "ERROR", "NULL", "VOID", "FAIL", "DEAD", "LOST", "GONE", "HELP", "PAIN", "STOP", "BROKEN", "CORRUPT", "DAMAGE", "SYSTEM", "FAILURE"}
        for _, char in ipairs(aggressiveChars) do
            table.insert(glitchChars, char)
        end
    end
    
    for i = 1, #text do
        local char = text:sub(i, i)
        
        if math.random() < glitchChance then

            if math.random() < 0.7 then
                char = glitchChars[math.random(#glitchChars)]
            else

                char = ""
            end
        elseif math.random() < glitchChance * 0.5 then

            char = char .. char
            if brainDamage >= 0.3 and math.random() < 0.7 then
                char = char .. char .. char 
            end
        end
        
        result = result .. char
    end
    

    local endGlitchChance = brainDamage >= 0.3 and 1.0 or glitchChance * (0.6 + brainDamage * 0.4)
    if math.random() < endGlitchChance then
        local numChars = brainDamage >= 0.3 and math.random(8, 20) or math.random(1, math.floor(3 + brainDamage * 5))
        for i = 1, numChars do
            result = result .. glitchChars[math.random(#glitchChars)]
        end
    end
    
    if brainDamage >= 0.3 and math.random() < 0.6 then
        result = ""
        for i = 1, math.random(8, 15) do
            result = result .. glitchChars[math.random(#glitchChars)]
        end
    end
    
    return result
end

function WS.GetAnimValue(id, target, speed)
    WS.Anim[id] = LerpFT(speed or 0.18, WS.Anim[id] or 0, target)
    return WS.Anim[id]
end

local function EaseOutCubic(t)
    t = math.Clamp(t, 0, 1)
    return 1 - (1 - t) ^ 3
end


local SADSALAT_COLORS = {
    accent    = Color(220, 60, 160),
    grid      = Color(220, 60, 160),
    select    = Color(255, 80, 180),
    gradient  = Color(180, 30, 120),
}

local sadsalatParticles = {}

local function SpawnSadsalatParticle(x, y, w, h)
    local t = CurTime()

    local types = {"♥", "♦", "✦", "★", "·", "•", "✿"}
    table.insert(sadsalatParticles, {
        x     = x + math.random(0, w),
        y     = y + h * 0.5,
        vy    = -math.random(20, 60) * 0.1, 
        vx    = math.random(-15, 15) * 0.1,
        alpha = 1,
        size  = math.random(8, 16),
        char  = types[math.random(#types)],
        born  = t,
        life  = math.random(8, 18) * 0.1,
        wobble = math.random() * math.pi * 2,
    })
end

local function UpdateSadsalatParticles(dt)
    local t = CurTime()
    for i = #sadsalatParticles, 1, -1 do
        local p = sadsalatParticles[i]
        local age = t - p.born
        if age > p.life then
            table.remove(sadsalatParticles, i)
        else
            p.x = p.x + p.vx
            p.y = p.y + p.vy
            p.alpha = 1 - (age / p.life)
        end
    end
end

local function DrawSadsalatParticles(pinkAnim)
    if pinkAnim < 0.01 then return end
    surface.SetFont("HomigradFontSmall")
    for _, p in ipairs(sadsalatParticles) do
        local a = math.floor(p.alpha * pinkAnim * 220)
        if a < 5 then continue end
        local wobbleX = math.sin(CurTime() * 3 + p.wobble) * 3
        draw.DrawText(p.char, "HomigradFontSmall", p.x + wobbleX, p.y, Color(255, 120, 200, a), TEXT_ALIGN_CENTER)
    end
end

local function DrawAnimatedGrid(x, y, w, h, alpha, grayIntensity, pinkAnim)
    grayIntensity = grayIntensity or 0
    pinkAnim = pinkAnim or 0
    local cell = 18
    local driftX = (CurTime() * 18) % cell
    local driftY = (CurTime() * 10) % cell
    local t = CurTime()
    local minX, minY = math.floor(x), math.floor(y)
    local maxX, maxY = math.floor(x + w), math.floor(y + h)

    render.SetScissorRect(minX, minY, maxX, maxY, true)

    local baseLineAlpha = alpha * 0.16
    local pulse = 0.82 + math.abs(math.sin(t * 2.5)) * 0.18
    
    local ply = LocalPlayer()
    local brainDamage = 0
    if IsValid(ply) and ply.organism and ply.organism.brain then
        brainDamage = ply.organism.brain
    end
    
    local gridR, gridG, gridB = 220, 45, 45
    -- Розовая тема
    if pinkAnim > 0 then
        gridR = math.floor(Lerp(pinkAnim, gridR, SADSALAT_COLORS.grid.r))
        gridG = math.floor(Lerp(pinkAnim, gridG, SADSALAT_COLORS.grid.g))
        gridB = math.floor(Lerp(pinkAnim, gridB, SADSALAT_COLORS.grid.b))
    end
    if grayIntensity > 0 then
        local gray = math.floor(gridR * 0.299 + gridG * 0.587 + gridB * 0.114)
        gridR = math.floor(Lerp(grayIntensity, gridR, gray))
        gridG = math.floor(Lerp(grayIntensity, gridG, gray))
        gridB = math.floor(Lerp(grayIntensity, gridB, gray))
    end
    
    if brainDamage > 0.15 then
        local glitchIntensity = (brainDamage - 0.15) * 2
        
        if math.random() < glitchIntensity * (0.3 + brainDamage * 0.4) then
            cell = cell + math.random(-8 - brainDamage * 10, 8 + brainDamage * 10)
        end
        
        if math.random() < glitchIntensity * (0.4 + brainDamage * 0.5) then
            pulse = pulse + math.random(-0.5 - brainDamage, 0.5 + brainDamage)
            baseLineAlpha = baseLineAlpha * (1 + math.random(-0.5 - brainDamage, 1 + brainDamage * 2))
        end
        
        local numGlitchLines = math.random(1, math.floor(5 + brainDamage * 10))
        if math.random() < glitchIntensity * (0.2 + brainDamage * 0.6) then
            for i = 1, numGlitchLines do
                local rx = x + math.random(0, w)
                local ry = y + math.random(0, h)
                local glitchAlpha = baseLineAlpha * (2 + brainDamage * 3)
                
                local glitchR, glitchG, glitchB = 255, math.random(0, 100), math.random(0, 100)
                if grayIntensity > 0 then
                    local gray = math.floor(glitchR * 0.299 + glitchG * 0.587 + glitchB * 0.114)
                    glitchR = math.floor(Lerp(grayIntensity, glitchR, gray))
                    glitchG = math.floor(Lerp(grayIntensity, glitchG, gray))
                    glitchB = math.floor(Lerp(grayIntensity, glitchB, gray))
                end
                
                surface.SetDrawColor(glitchR, glitchG, glitchB, glitchAlpha)
                if math.random() < 0.5 then
                    surface.DrawRect(rx, y, math.random(1, 3 + brainDamage * 2), h)
                else
                    surface.DrawRect(x, ry, w, math.random(1, 3 + brainDamage * 2))
                end
            end
        end
    end

    for gx = -driftX, w, cell do
        local lx = x + gx
        surface.SetDrawColor(gridR, gridG, gridB, baseLineAlpha * pulse)
        surface.DrawRect(lx, y, 1, h)
    end

    for gy = -driftY, h, cell do
        local ly = y + gy
        surface.SetDrawColor(gridR, gridG, gridB, baseLineAlpha * 0.9 * pulse)
        surface.DrawRect(x, ly, w, 1)
    end

    render.SetScissorRect(0, 0, 0, 0, false)
end

function WS.GetSelectedWeapon()
    if not IsValid( LocalPlayer() ) or not LocalPlayer():Alive() then return end
    local Weapons = WS.GetWeaponTable( LocalPlayer() )
    return Weapons[WS.SelectedSlot] and Weapons[WS.SelectedSlot][WS.SelectedSlotPos] or Weapons[WS.LastSelectedSlot][WS.LastSelectedSlotPos] or Weapons[0][0]
end

function WS.GetWeaponTable( ply )
    if not IsValid( ply ) or not ply:Alive() then return end
    local WeaponsGet = ply:GetWeapons()
    local FormatedTable = {
        [0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {},
    }

    table.sort(WeaponsGet, function(a, b) return (a.SlotPos or 0) > (b.SlotPos or 0) end)

    for k,wep in ipairs(WeaponsGet) do
        local tTbl = FormatedTable[wep.Slot or 0]
        local iMinPos = math.min( (wep.SlotPos and wep.SlotPos) or 1, ((#tTbl or 0) + 1)) - 1
        local iPos = tTbl[ iMinPos ] and #tTbl + 1 or iMinPos
        tTbl[ iPos ] = wep
    end
    return FormatedTable
end

local scrW, scrH = ScrW(), ScrH()

local AcsentColor = Color(155,0,0)
local AcsentColorPink = Color(220,60,160)
local gradient_u = Material("vgui/gradient-d")

function WS.WeaponSelectorDraw( ply )
    if not IsValid( ply ) or not ply:Alive() or GetGlobalBool("RadialInventory", false) then return end
    local isShown = WS.Show > CurTime()
    WS.Transparent = LerpFT(0.12, WS.Transparent, isShown and 1 or 0)

    if not isShown and WS.Transparent < 0.02 then
        WS.SelectedSlot = WS.LastSelectedSlot
        WS.SelectedSlotPos = -1
        return
    end

    local brainDamage = 0
    if ply.organism and ply.organism.brain then
        brainDamage = ply.organism.brain
    end
    
    local grayIntensity = 0
    if brainDamage >= 0.3 then
        grayIntensity = 1
    elseif brainDamage > 0.15 then
        grayIntensity = math.Clamp((brainDamage - 0.15) / 0.15, 0, 1)
    end

    local Weapons = WS.GetWeaponTable( ply )
    local SelectedWep = WS.GetSelectedWeapon()
    if not IsValid(SelectedWep) then return end
    WS.Slide = LerpFT(0.1, WS.Slide, EaseOutCubic(WS.Transparent))


    local activeWep = ply:GetActiveWeapon()
    local isSadsalat = IsValid(activeWep) and activeWep:GetClass() == "weapon_sadsalat"
    local pinkAnim = WS.GetAnimValue("sadsalat_pink", isSadsalat and 1 or 0, 0.08)

 
    UpdateSadsalatParticles()

    local function GetThemeColor(r, g, b, pinkR, pinkG, pinkB)
        local pr = pinkR or SADSALAT_COLORS.accent.r
        local pg = pinkG or SADSALAT_COLORS.accent.g
        local pb = pinkB or SADSALAT_COLORS.accent.b
        return math.floor(Lerp(pinkAnim, r, pr)), math.floor(Lerp(pinkAnim, g, pg)), math.floor(Lerp(pinkAnim, b, pb))
    end
    --draw.RoundedBox(0,(scrW / 2)-10,(scrH *0.15),20,20, color_red )
    local SuperAmmout = 0
    local AmmoutSlots = 0
    for i = 0, #Weapons do
        local slotTbl = Weapons[i]
        if table.Count(slotTbl) < 1 then continue end
        AmmoutSlots = AmmoutSlots + 1
    end

    for i = 0, #Weapons do
        local slotTbl = Weapons[i]
        if table.Count(slotTbl) < 1 then continue end
        local sizeX = scrW*0.1
        local position = scrW/2 + ( ( SuperAmmout -  (AmmoutSlots/2)) * sizeX )
        local slotAnim = WS.GetAnimValue("slot_" .. i, WS.Slide, 0.1)
        local slotOffsetY = (1 - EaseOutCubic(slotAnim)) * (scrH * 0.045)
        
        local slotColor = color_white
        if grayIntensity > 0 then
            local gray = math.floor(255 * 0.299 + 255 * 0.587 + 255 * 0.114)
            slotColor = Color(
                math.floor(Lerp(grayIntensity, 255, gray)),
                math.floor(Lerp(grayIntensity, 255, gray)),
                math.floor(Lerp(grayIntensity, 255, gray)),
                255
            )
        end
        
        WS.DrawText( i+1, "HomigradFontMedium", position + sizeX/2, scrH*0.02 - slotOffsetY, ColorAlpha(slotColor,WS.Transparent*255) ,TEXT_ALIGN_CENTER )
        
        --  draw.RoundedBox(
        --      1,
        --      position,
        --      (scrH *0.01),
        --      sizeX,
        --      (scrH *0.02), 
        --      ColorAlpha(color_black,WS.Transparent*255) 
        --  )
        --if slotTbl and table.Count(slotTbl) < 0 then continue end
        local Ammout = 0
        local lastPos = 0
        for Id = 0, #slotTbl do
            local wepId = Id
            local wep = slotTbl[wepId]
            if not wep then continue end
            --print(wepId,wep)
            local selectedAnim = WS.GetAnimValue("selected_" .. wep:EntIndex(), SelectedWep == wep and 1 or 0, 0.16)
            local hoverAnim = WS.GetAnimValue("hover_" .. wep:EntIndex(), SelectedWep == wep and 1 or 0, 0.08)
            local itemAppear = WS.GetAnimValue("item_" .. wep:EntIndex(), isShown and 1 or 0, 0.11 + (Ammout * 0.01))
            local easedAppear = EaseOutCubic(itemAppear)
            local sizeH = Lerp(selectedAnim, scrH * 0.025, scrH * 0.12)
            local LastSelected = 0
            if slotTbl[wepId-1] and SelectedWep == slotTbl[wepId-1] then
                lastPos = (scrH *0.095) 
            end
            local boxY = (scrH * 0.025) * (Ammout) + (scrH * 0.05) + lastPos - slotOffsetY + (1 - easedAppear) * (scrH * 0.018)
            local itemAlpha = WS.Transparent * (0.35 + easedAppear * 0.65)
            
            local brainDamage = 0
            if IsValid(ply) and ply.organism and ply.organism.brain then
                brainDamage = ply.organism.brain
            end
            
            local glitchOffsetX, glitchOffsetY = 0, 0
            local glitchSizeX, glitchSizeY = sizeX, sizeH
            
            if brainDamage > 0.15 then
                local glitchIntensity = brainDamage >= 0.3 and 4 or (brainDamage - 0.15) * 2
                local time = CurTime() * (8 + brainDamage * 25) + wep:EntIndex()
                
                local offsetChance = brainDamage >= 0.3 and 1.0 or glitchIntensity * 0.4
                if math.random() < offsetChance then
                    local maxOffset = brainDamage >= 0.3 and 35 or glitchIntensity * 6
                    glitchOffsetX = math.sin(time) * maxOffset
                    glitchOffsetY = math.cos(time * 1.2) * maxOffset * 0.8
                end
                
                local sizeChance = brainDamage >= 0.3 and 0.8 or glitchIntensity * 0.3
                if math.random() < sizeChance then
                    local maxSizeChange = brainDamage >= 0.3 and 40 or glitchIntensity * 10
                    glitchSizeX = sizeX + math.sin(time * 2) * maxSizeChange
                    glitchSizeY = sizeH + math.cos(time * 1.5) * maxSizeChange * 0.6
                end
                
                local panelChance = brainDamage >= 0.3 and 0.7 or glitchIntensity * 0.2
                if math.random() < panelChance then
                    local numPanels = brainDamage >= 0.3 and math.random(5, 12) or math.random(1, 4)
                    for g = 1, numPanels do
                        local gx = position + math.random(-50, 50) * (brainDamage >= 0.3 and 2 or 1)
                        local gy = boxY + math.random(-25, 25) * (brainDamage >= 0.3 and 2 or 1)
                        local gw = sizeX + math.random(-60, 60) * (brainDamage >= 0.3 and 2 or 1)
                        local gh = sizeH + math.random(-30, 30) * (brainDamage >= 0.3 and 2 or 1)
                        
                        local glitchR, glitchG, glitchB = 255, math.random(0, 100), math.random(0, 100)
                        if grayIntensity > 0 then
                            local gray = math.floor(glitchR * 0.299 + glitchG * 0.587 + glitchB * 0.114)
                            glitchR = math.floor(Lerp(grayIntensity, glitchR, gray))
                            glitchG = math.floor(Lerp(grayIntensity, glitchG, gray))
                            glitchB = math.floor(Lerp(grayIntensity, glitchB, gray))
                        end
                        
                        local glitchAlpha = brainDamage >= 0.3 and itemAlpha * 200 or itemAlpha * 120
                        draw.RoundedBox(0, gx, gy, gw, gh, ColorAlpha(Color(glitchR, glitchG, glitchB), glitchAlpha))
                    end
                end
            end

            draw.RoundedBox(
                0,
                position + glitchOffsetX,
                boxY + glitchOffsetY,
                glitchSizeX,
                glitchSizeY, 
                ColorAlpha(color_black,itemAlpha * 205) 
            )
            draw.RoundedBox(
                0,
                position + glitchOffsetX,
                boxY + glitchOffsetY + glitchSizeY - 2,
                glitchSizeX,
                2, 
                ColorAlpha(color_black,itemAlpha * 205) 
            )
            DrawAnimatedGrid(position + 2 + glitchOffsetX, boxY + 2 + glitchOffsetY, glitchSizeX - 4, math.max(glitchSizeY - 4, 4), itemAlpha * 255, grayIntensity, pinkAnim)
            
            local gradientR, gradientG, gradientB = GetThemeColor(155, 0, 0, SADSALAT_COLORS.gradient.r, SADSALAT_COLORS.gradient.g, SADSALAT_COLORS.gradient.b)
            if grayIntensity > 0 then
                local gray = math.floor(gradientR * 0.299 + gradientG * 0.587 + gradientB * 0.114)
                gradientR = math.floor(Lerp(grayIntensity, gradientR, gray))
                gradientG = math.floor(Lerp(grayIntensity, gradientG, gray))
                gradientB = math.floor(Lerp(grayIntensity, gradientB, gray))
            end
            
            surface.SetDrawColor( gradientR, gradientG, gradientB, itemAlpha * (55 + hoverAnim * 145) )
            surface.SetMaterial( gradient_u )
            surface.DrawTexturedRect( position + glitchOffsetX, boxY + glitchOffsetY, glitchSizeX, glitchSizeY )
            if SelectedWep == wep then
                local pulse = 0.75 + math.abs(math.sin(CurTime() * 6)) * 0.25
                
                local selectR, selectG, selectB = GetThemeColor(255, 45, 45, SADSALAT_COLORS.select.r, SADSALAT_COLORS.select.g, SADSALAT_COLORS.select.b)
                if grayIntensity > 0 then
                    local gray = math.floor(selectR * 0.299 + selectG * 0.587 + selectB * 0.114)
                    selectR = math.floor(Lerp(grayIntensity, selectR, gray))
                    selectG = math.floor(Lerp(grayIntensity, selectG, gray))
                    selectB = math.floor(Lerp(grayIntensity, selectB, gray))
                end
                
                surface.SetDrawColor( selectR, selectG, selectB, itemAlpha * (110 + pulse * 85) )
	            surface.DrawOutlinedRect( position + glitchOffsetX, boxY + glitchOffsetY, glitchSizeX, glitchSizeY, 2 )
            end
            local sizeHi = boxY + glitchOffsetY
            sizeHi = sizeHi + 2.5
            
            local weaponTextColor = color_white
            if grayIntensity > 0 then
                local gray = math.floor(255 * 0.299 + 255 * 0.587 + 255 * 0.114)
                weaponTextColor = Color(
                    math.floor(Lerp(grayIntensity, 255, gray)),
                    math.floor(Lerp(grayIntensity, 255, gray)),
                    math.floor(Lerp(grayIntensity, 255, gray)),
                    255
                )
            end
            
            WS.DrawText( WS.GetPrintName(wep), "HomigradFontSmall", position + glitchSizeX/2 + glitchOffsetX, sizeHi, ColorAlpha(weaponTextColor,itemAlpha * 255) ,TEXT_ALIGN_CENTER )
            Ammout = Ammout + 1

      
            if wep:GetClass() == "weapon_sadsalat" and pinkAnim > 0.01 then
                local cx = position + glitchOffsetX + glitchSizeX / 2
                local cy = boxY + glitchOffsetY + glitchSizeY / 2
                local t = CurTime()


                local glowPulse = 0.5 + math.abs(math.sin(t * 3)) * 0.5
                local glowLayers = 4
                for g = glowLayers, 1, -1 do
                    local expand = g * 4 * glowPulse
                    local glowA = math.floor(pinkAnim * itemAlpha * (40 - g * 8) * glowPulse)
                    if glowA > 0 then
                        draw.RoundedBox(4,
                            position + glitchOffsetX - expand,
                            boxY + glitchOffsetY - expand,
                            glitchSizeX + expand * 2,
                            glitchSizeY + expand * 2,
                            Color(255, 80, 180, glowA)
                        )
                    end
                end

    
                local sparkCount = 6
                for s = 1, sparkCount do
                    local angle = (t * 1.2 + s / sparkCount * math.pi * 2)
                    local radius = (glitchSizeX * 0.5 + 8) + math.sin(t * 4 + s) * 4
                    local sx = cx + math.cos(angle) * radius
                    local sy = (boxY + glitchOffsetY + glitchSizeY * 0.5) + math.sin(angle) * (glitchSizeY * 0.4)
                    local sparkA = math.floor(pinkAnim * itemAlpha * (0.5 + math.sin(t * 5 + s) * 0.5) * 200)
                    if sparkA > 10 then
                        draw.RoundedBox(2, sx - 2, sy - 2, 4, 4, Color(255, 180, 230, sparkA))
                    end
                end

     
                if math.random() < pinkAnim * 0.15 then
                    SpawnSadsalatParticle(position + glitchOffsetX, boxY + glitchOffsetY, glitchSizeX, glitchSizeY)
                end

                -- Розовая полоска снизу панели (как подчёркивание)
                local lineA = math.floor(pinkAnim * itemAlpha * (150 + math.sin(t * 4) * 80))
                surface.SetDrawColor(255, 100, 200, lineA)
                surface.DrawRect(position + glitchOffsetX, boxY + glitchOffsetY + glitchSizeY - 2, glitchSizeX, 2)
            end

            if SelectedWep == wep and wep.DrawWeaponSelection then
                wep:DrawWeaponSelection(position + 5 + glitchOffsetX, boxY + (scrH * 0.03) + glitchOffsetY, glitchSizeX - 10, glitchSizeY, itemAlpha * 255)
            end
        end
        SuperAmmout = SuperAmmout + 1
    end


    DrawSadsalatParticles(pinkAnim)
end


local tAcceptKeys = {
    ["slot1"] = 1,
    ["slot2"] = 2,
    ["slot3"] = 3,
    ["slot4"] = 4,
    ["slot5"] = 5,
    ["slot6"] = 6,
}

--[[
    Table:
        [1]	=	Weapon [52][weapon_hands_sh]
        [2]	=	Weapon [117][weapon_bigconsumable]
        [3]	=	Weapon [121][weapon_handcuffs_key]
        [4]	=	Weapon [122][weapon_handcuffs]
        [5]	=	Weapon [123][weapon_traitor_poison1]
        [6]	=	Weapon [124][weapon_traitor_suit]
        [7]	=	Weapon [125][weapon_matches]

    TableFormated:
    [0]:
		[0]	=	Weapon [126][weapon_physgun]
		[1]	=	Weapon [52][weapon_hands_sh]
    [1]:
    [2]:
    [3]:
		[1]	=	Weapon [117][weapon_bigconsumable]
		[2]	=	Weapon [121][weapon_handcuffs_key]
		[3]	=	Weapon [122][weapon_handcuffs]
		[4]	=	Weapon [123][weapon_traitor_poison1]
		[5]	=	Weapon [125][weapon_matches]
    [4]:
    [5]:
		[1]	=	Weapon [124][weapon_traitor_suit]
--]]

local function GetUpper(Weapons)
    if #LocalPlayer():GetWeapons() < 1 then return end
    WS.SelectedSlot = WS.SelectedSlot < 0 and #Weapons or WS.SelectedSlot - 1
    WS.SelectedSlotPos = Weapons[WS.SelectedSlot] and #Weapons[WS.SelectedSlot] or 0

    --print(WS.SelectedSlot, WS.SelectedSlotPos)

    if Weapons[WS.SelectedSlot] == nil or Weapons[WS.SelectedSlot][WS.SelectedSlotPos] == nil then
        GetUpper(Weapons)
    end
end

local function GetDown(Weapons)
    if #LocalPlayer():GetWeapons() < 1 then return end
    WS.SelectedSlot = WS.SelectedSlot > #Weapons and 0 or WS.SelectedSlot + 1
    WS.SelectedSlotPos = 0

    --print(WS.SelectedSlot, WS.SelectedSlotPos)

    if Weapons[WS.SelectedSlot] == nil or Weapons[WS.SelectedSlot][WS.SelectedSlotPos] == nil then
        GetDown(Weapons)
    end
end

local LastSelected = 0

local function get_active_tool(ply, tool)
    local activeWep = ply:GetActiveWeapon()
    if not IsValid(activeWep) or activeWep:GetClass() ~= "gmod_tool" or activeWep.Mode ~= tool then return end
    return activeWep:GetToolObject(tool)
end

local function canUseSelector(ply)
    local wep = ply:GetActiveWeapon()
    local tool = get_active_tool(ply, "submaterial")
    if tool and IsValid(ply:GetEyeTraceNoCursor().Entity) then
        return true
    end

    return IsAiming(ply) or (IsValid(wep) and wep:GetClass() == "weapon_physgun" and ply:KeyDown(IN_ATTACK)) or (lply.organism and lply.organism.pain and lply.organism.pain > 100) or GetGlobalBool("RadialInventory", false)
end

function WS.ChangeSelectionWep( ply, key )
    if not IsValid( ply ) or not ply:Alive() or GetGlobalBool("RadialInventory", false) then return end
    if ply.organism and ply.organism.otrub then return end
    if canUseSelector( ply ) then return end
    --print(canUseSelector( ply ))
    --print("Table")
    --PrintTable( WS.GetWeaponTable( ply ) )
    local iPos = tAcceptKeys[ key ]
    if iPos or key == "invnext" or key == "invprev" or key == "lastinv" then

        local Weapons = WS.GetWeaponTable( ply )

        WS.Show = CurTime() + 4
        --print(key)
        surface.PlaySound("arc9_eft_shared/weapon_generic_rifle_spin"..math.random(10)..".ogg")
        if iPos then
            iPos = iPos - 1
            if LastSelected ~= iPos then 
                WS.SelectedSlotPos = -1
            end
            WS.SelectedSlotPos = (Weapons[iPos] and LastSelected == iPos and WS.SelectedSlotPos + 1 > #Weapons[iPos] and 0 or math.min( WS.SelectedSlotPos + 1, #Weapons[iPos] )) or 0
            WS.SelectedSlot = iPos
            LastSelected = iPos
            --print(WS.SelectedSlotPos)
            --print(iPos)
            --print( Weapons[WS.SelectedSlot][WS.SelectedSlotPos] )
        elseif key == "invprev" then
            WS.SelectedSlotPos = WS.SelectedSlotPos - 1
            --print(WS.SelectedSlotPos)
            if Weapons[WS.SelectedSlot] and WS.SelectedSlotPos < 0  then
                GetUpper(Weapons)
            end
            --WS.SelectedSlot = Weapons[WS.SelectedSlot] and #Weapons[WS.SelectedSlot] > (WS.SelectedSlotPos + 1) and WS.SelectedSlot + 1 or WS.SelectedSlot + 1 > #Weapons - 1 and 0 or 0
        elseif key == "invnext" then
            WS.SelectedSlotPos = WS.SelectedSlotPos + 1
            --print(WS.SelectedSlotPos)
            if Weapons[WS.SelectedSlot] and WS.SelectedSlotPos > #Weapons[WS.SelectedSlot] then
                GetDown(Weapons)
            end
        elseif key == "lastinv" and IsValid(WS.LastInv) then
            WS.Show = 0
            WS.LastInv = WS.LastInv or "weapon_hands_sh"
            local oldwep = ply:GetActiveWeapon()
            input.SelectWeapon( WS.LastInv )
            WS.LastInv = oldwep
        end

    end
end

function WS.SetActuallyWeapon( ply, cmd )
    if not IsValid( ply ) or not ply:Alive() or GetGlobalBool("RadialInventory", false) then return end
    if (cmd:KeyDown( IN_ATTACK ) or cmd:KeyDown( IN_ATTACK2 )) and WS.Show > CurTime() then

        if WS.Selected and WS.Selected > CurTime() then 
            cmd:RemoveKey(IN_ATTACK) 
            cmd:RemoveKey(IN_ATTACK2) 
        else
            cmd:RemoveKey(IN_ATTACK)
            cmd:RemoveKey(IN_ATTACK2) 
            --print(WS.GetSelectedWeapon())
            
            if IsValid(WS.GetSelectedWeapon()) then
                WS.LastInv = WS.LastInv ~= ply:GetActiveWeapon() and WS.LastInv or ply:GetActiveWeapon()
                input.SelectWeapon( WS.GetSelectedWeapon() )
            end
            cmd:RemoveKey(IN_ATTACK)
            cmd:RemoveKey(IN_ATTACK2) 

            WS.LastSelectedSlot = WS.SelectedSlot
            WS.LastSelectedSlotPos = WS.SelectedSlotPos
            WS.Selected = CurTime() + 0.2
            WS.Show = CurTime() + 0.2
            surface.PlaySound("arc9_eft_shared/weapon_generic_spin"..math.random(1,10)..".ogg")
        end
    end
end

hook.Add( "PlayerBindPress", "WeaponSelector_PlayerBindPress", WS.ChangeSelectionWep )

hook.Add( "HUDPaint", "WeaponSelector_Draw", function()
    WS.WeaponSelectorDraw( LocalPlayer() )
end)

hook.Add( "StartCommand", "WeaponSelector_StartCommand", WS.SetActuallyWeapon )

local tHideElements = {
    ["CHudWeaponSelection"] = true
}

hook.Add("HUDShouldDraw", "WeaponSelector_HUDShouldDraw", function(sElementName)
    if tHideElements[sElementName] then return false end
end)

-- Я ТАК ЗАДОЛБАЛСЯ ПРОСТО УБЕЙТЕ МЕНЯ ХАХАХАХАХАХАХАХАХАХААХАХАХАХАХАХА
-- ПОЛЧАСА Я ПЫТАЛСЯ СДЕЛАТЬ НОРМЛАЬНОЕ ПЕРЕКЛЮЧЕНИЕ ГОВНА!!!
-- ЗАТО ПОЛУЧИЛОСЬ!!!!
-- УЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭЭ
--[[
    /\_/\
    |_ _|
    |   |__
   /_|_____\ -- IT'S SO OVER
--]]
