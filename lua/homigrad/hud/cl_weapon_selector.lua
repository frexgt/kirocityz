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

WS.SelectedSlot = 0
WS.SelectedSlotPos = 0

function WS.DrawText(text, font, posX, posY, color, textAlign)
    draw.DrawText( text, font, posX + 2, posY + 2, ColorAlpha(color_black,WS.Transparent*255) ,textAlign )
    draw.DrawText( text, font, posX, posY, ColorAlpha(color,WS.Transparent*255) ,textAlign )
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

local fallback_material = Material("vgui/white")

local function SafeMaterial(path, fallback)
    local mat = Material(path)
    if not mat then return fallback end
    if mat.IsError and mat:IsError() then return fallback end
    return mat
end

local gradient_down = SafeMaterial("vgui/gradient-d", fallback_material)
local gradient_up = SafeMaterial("vgui/gradient-u", fallback_material)
local gradient_right = SafeMaterial("vgui/gradient-r", gradient_down)
local gradient_left = SafeMaterial("vgui/gradient-l", gradient_up)

surface.CreateFont("ZC_WS_Slot", {
    font = "Tahoma",
    size = 14,
    weight = 950,
    antialias = true,
    extended = true,
})

surface.CreateFont("ZC_WS_Name", {
    font = "Tahoma",
    size = 14,
    weight = 900,
    antialias = true,
    extended = true,
})

surface.CreateFont("ZC_WS_NameSmall", {
    font = "Tahoma",
    size = 12,
    weight = 800,
    antialias = true,
    extended = true,
})

WS.CardExpand = WS.CardExpand or {}

local function GetFilledSlots(weapons)
    local slots = {}

    for i = 0, #weapons do
        local slotTbl = weapons[i]
        if table.Count(slotTbl) < 1 then continue end
        slots[#slots + 1] = i
    end

    return slots
end

function WS.WeaponSelectorDraw( ply )
    if not IsValid(ply) or not ply:Alive() or GetGlobalBool("RadialInventory", false) then return end

    if WS.Show < CurTime() then
        WS.SelectedSlot = WS.LastSelectedSlot
        WS.SelectedSlotPos = -1
        return
    end

    local weapons = WS.GetWeaponTable(ply)
    local selectedWep = WS.GetSelectedWeapon()
    if not IsValid(selectedWep) then return end

    local filledSlots = GetFilledSlots(weapons)
    if #filledSlots < 1 then return end

    WS.Transparent = LerpFT(0.22, WS.Transparent, math.min(WS.Show - CurTime(), 1))

    local sw, sh = ScrW(), ScrH()
    local alpha = math.Clamp(WS.Transparent * 255, 0, 255)
    local collapsedH = sh * 0.037
    local expandedH = sh * 0.102
    local cardW = sw * 0.095
    local slotGap = sw * 0.006
    local rowGap = sh * 0.004

    local totalW = #filledSlots * cardW + (#filledSlots - 1) * slotGap
    local startX = sw * 0.5 - totalW * 0.5
    local startY = sh * 0.048

        for slotIndex, slotId in ipairs(filledSlots) do
        local slotTbl = weapons[slotId]
        local x = startX + (slotIndex - 1) * (cardW + slotGap)
        local y = startY

        local slotIsSelected = false
        for id = 0, #slotTbl do
            local checkWep = slotTbl[id]
            if IsValid(checkWep) and checkWep == selectedWep then
                slotIsSelected = true
                break
            end
        end

        local slotNumColor = slotIsSelected and Color(235, 70, 70) or color_white
        WS.DrawText(slotId + 1, "ZC_WS_Slot", x + cardW * 0.5, startY - sh * 0.024, slotNumColor, TEXT_ALIGN_CENTER)

        for id = 0, #slotTbl do
            local wep = slotTbl[id]
            if not IsValid(wep) then continue end

            local isSelected = wep == selectedWep
            local key = wep:EntIndex()

            WS.CardExpand[key] = LerpFT(0.22, WS.CardExpand[key] or 0, isSelected and 1 or 0)

            local expand = WS.CardExpand[key]
            local h = Lerp(expand, collapsedH, expandedH)

            local baseColor = isSelected and Color(15, 15, 18, alpha * 0.96) or Color(18, 18, 22, alpha * 0.88)
            local redAlpha = isSelected and alpha * 0.9 or alpha * 0.56

            surface.SetDrawColor(baseColor)
            surface.DrawRect(x, y, cardW, h)

            surface.SetMaterial(gradient_right)
            surface.SetDrawColor(165, 36, 36, redAlpha)
            surface.DrawTexturedRect(x, y, cardW, h)

            surface.SetMaterial(gradient_left)
            surface.SetDrawColor(0, 0, 0, alpha * 0.35)
            surface.DrawTexturedRect(x, y, cardW, h)

            surface.SetMaterial(gradient_down)
            surface.SetDrawColor(0, 0, 0, alpha * 0.24)
            surface.DrawTexturedRect(x, y, cardW, h)

            surface.SetMaterial(gradient_up)
            surface.SetDrawColor(255, 255, 255, alpha * (isSelected and 0.1 or 0.05))
            surface.DrawTexturedRect(x, y, cardW, h)

            if isSelected then
                surface.SetDrawColor(255, 84, 84, alpha)
                surface.DrawOutlinedRect(x, y, cardW, h, 2)
            else
                surface.SetDrawColor(42, 42, 46, alpha * 0.95)
                surface.DrawOutlinedRect(x, y, cardW, h, 1)
            end

            local weaponName = WS.GetPrintName(wep)
            if expand < 0.55 then
                WS.DrawText(weaponName, "ZC_WS_NameSmall", x + cardW * 0.5, y + h * 0.2, color_white, TEXT_ALIGN_CENTER)
            else
                WS.DrawText(weaponName, "ZC_WS_Name", x + cardW * 0.5, y + h - 18, color_white, TEXT_ALIGN_CENTER)
            end

            if isSelected and wep.DrawWeaponSelection then
                local iconX = x + 8
                local iconY = y + 12
                local iconW = cardW - 16
                local iconH = math.max(h - 34, 18)
                wep:DrawWeaponSelection(iconX, iconY, iconW, iconH, alpha)
            end

            y = y + h + rowGap
        end
    end
end
-- Changer
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

-- РЇ РўРђРљ Р—РђР”РћР›Р‘РђР›РЎРЇ РџР РћРЎРўРћ РЈР‘Р•Р™РўР• РњР•РќРЇ РҐРђРҐРђРҐРђРҐРђРҐРђРҐРђРҐРђРҐРђРҐРђРҐРђРђРҐРђРҐРђРҐРђРҐРђРҐРђРҐРђ
-- РџРћР›Р§РђРЎРђ РЇ РџР«РўРђР›РЎРЇ РЎР”Р•Р›РђРўР¬ РќРћР РњР›РђР¬РќРћР• РџР•Р Р•РљР›Р®Р§Р•РќРР• Р“РћР’РќРђ!!!
-- Р—РђРўРћ РџРћР›РЈР§РР›РћРЎР¬!!!!
-- РЈР­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­Р­
--[[
    /\_/\
    |_ _|
    |   |__
   /_|_____\ -- IT'S SO OVER
--]]









