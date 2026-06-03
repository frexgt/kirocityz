zb = zb or {}
include("shared.lua")
include("loader.lua")

if not ConVarExists("hg_newspectate") then
    CreateClientConVar("hg_newspectate", "1", true, false, "Enables smooth spectator camera transitions", 0, 1)
end

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

function CurrentRound()
	return zb.modes[zb.CROUND]
end

zb.ROUND_STATE = 0
--0 = players can join, 1 = round is active, 2 = endround
local vecZero = Vector(0.2, 0.2, 0.2)
local vecFull = Vector(1, 1, 1)
spect,prevspect,viewmode = nil,nil,1
local hullscale = Vector(0,0,0)
net.Receive("ZB_SpectatePlayer", function(len)
	spect = net.ReadEntity()
	prevspect = net.ReadEntity()
	viewmode = net.ReadInt(4)

	timer.Simple(0.1,function()
		-- LocalPlayer():BoneScaleChange()
		LocalPlayer():SetHull(-hullscale,hullscale)
		LocalPlayer():SetHullDuck(-hullscale,hullscale)

		if viewmode == 3 then
			LocalPlayer():SetMoveType(MOVETYPE_NOCLIP)
		end
	end)
end)

zb.ROUND_TIME = zb.ROUND_TIME or 400
zb.ROUND_START = zb.ROUND_START or CurTime()
zb.ROUND_BEGIN = zb.ROUND_BEGIN or CurTime() + 5

net.Receive("updtime",function()
	local time = net.ReadFloat()
	local time2 = net.ReadFloat()
	local time3 = net.ReadFloat()

	zb.ROUND_TIME = time
	zb.ROUND_START = time2
	zb.ROUND_BEGIN = time3
end)

local blur = Material("pp/blurscreen")
local blur2 = Material("effects/shaders/zb_blur" )
local blursettings = {}
local hg_potatopc
hg = hg or {}
function hg.DrawBlur(panel, amount, passes, alpha)
	if is3d2d then return end
	amount = amount or 5
	hg_potatopc = hg_potatopc or hg.ConVars.potatopc

	// old blur
	if(hg_potatopc:GetBool())then
		surface.SetDrawColor(0, 0, 0, alpha or (amount * 20))
		surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
	else
		surface.SetMaterial(blur)
		surface.SetDrawColor(0, 0, 0, alpha or 125)
		surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
		local x, y = panel:LocalToScreen(0, 0)
		if blursettings and blursettings[1] == amount and blursettings[2] == passes then
			render.UpdateScreenEffectTexture()
			surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
			return
		end
		blursettings = {amount, passes}
		for i = -(passes or 0.2), 1, 0.2 do
			blur:SetFloat("$blur", i * amount)
			blur:Recompute()

			render.UpdateScreenEffectTexture()
			surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
		end
	end

	--surface.SetMaterial(blur2)
	--surface.SetDrawColor(color_white)
	--local x, y = panel:LocalToScreen(0, 0)
--
	--// those are currently hardcoded cuz it would be too much of a hassle to change this
	--blur2:SetFloat("$c0_x", (amount or 5) * 2500) // density
	--blur2:SetFloat("$c0_y", (passes or 0.2) * 2000) // noise (inverted)
	--blur2:SetFloat("$c0_z", 1) // blending
--
	--render.UpdateScreenEffectTexture()
	--surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())

	-- surface.SetDrawColor(0, 0, 0, alpha or 125)
	-- surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
end

BlurBackground = BlurBackground or hg.DrawBlur

local keydownattack
local keydownattack2
local keydownreload

hook.Add("HUDPaint","FUCKINGSAMENAMEUSEDINHOOKFUCKME",function()
    if LocalPlayer():Alive() then return end
	local spect = LocalPlayer():GetNWEntity("spect")
	if not IsValid(spect) then return end
	if viewmode == 3 then return end
	
	surface.SetFont("HomigradFont")
	surface.SetTextColor(255, 255, 255, 255)
	local txt = "Spectating player: "..spect:Name()
	local w, h = surface.GetTextSize(txt)
	surface.SetTextPos(ScrW() / 2 - w / 2, ScrH() / 8 * 7)
	surface.DrawText(txt)
	local txt = "In-game name: "..spect:GetPlayerName()
	local w, h = surface.GetTextSize(txt)
	surface.SetTextPos(ScrW() / 2 - w / 2, ScrH() / 8 * 7 + h)
	surface.DrawText(txt)
end)

local function GetSpectatorMarkerEntity(ply)
	if not IsValid(ply) then return end

	local ent = (hg.GetCurrentCharacter and hg.GetCurrentCharacter(ply)) or ply
	if IsValid(ent) then
		return ent
	end

	return ply
end

local function GetSpectatorMarkerPos(ent)
	if not IsValid(ent) then return end

	local mins = ent:OBBMins()
	if mins then
		return ent:LocalToWorld(Vector(0, 0, mins.z))
	end

	return ent:GetPos()
end

local function GetSpectatorMarkerOrganism(ply, ent)
	if istable(ply.new_organism) and (ply.new_organism.owner or ply.new_organism.blood or ply.new_organism.pulse or ply.new_organism.otrub ~= nil) then
		return ply.new_organism
	end

	if IsValid(ent) and istable(ent.new_organism) and (ent.new_organism.owner or ent.new_organism.blood or ent.new_organism.pulse or ent.new_organism.otrub ~= nil) then
		return ent.new_organism
	end

	if istable(ply.organism) and (ply.organism.owner or ply.organism.blood or ply.organism.pulse or ply.organism.otrub ~= nil) then
		return ply.organism
	end

	if IsValid(ent) and istable(ent.organism) and (ent.organism.owner or ent.organism.blood or ent.organism.pulse or ent.organism.otrub ~= nil) then
		return ent.organism
	end
end

local function GetSpectatorMarkerName(ply, ent)
	local model = ""

	if IsValid(ent) and ent.GetModel then
		model = string.lower(ent:GetModel() or "")
	end

	if model == "" and IsValid(ply) and ply.GetModel then
		model = string.lower(ply:GetModel() or "")
	end

	if string.find(model, "nosacz.mdl", 1, true) and zb.CROUND == "kingkong" then
		return "Кинг Конг"
	end

	if ply.role and isstring(ply.role.name) then
		if ply.role.name == "Кинг Конг" then
			return "Кинг Конг"
		end
	end

	return (ply.GetPlayerName and ply:GetPlayerName()) or ply:Name()
end

local function GetSpectatorMarkerState(ply, ent)
	local org = GetSpectatorMarkerOrganism(ply, ent)
	local fallbackHealth = math.max(ply:Health(), 0)

	if not org then
		return "НЕИЗВЕСТНО", "данные не получены", Color(190, 190, 190), math.Clamp(fallbackHealth, 0, 100), math.Clamp(fallbackHealth, 0, 100)
	end

	local blood = math.max(math.Round(org.blood or 5000), 0)
	local pulse = math.max(math.Round(org.heartbeat or org.pulse or 0), 0)
	local pain = math.max(math.Round(org.pain or 0), 0)
	local hurt = math.Clamp(org.hurt or 0, 0, 1)
	local rawHealth = math.max(math.Round(org.health or fallbackHealth), 0)
	local bloodHealth = math.Clamp(math.Round(blood / 50), 0, 100)
	local hurtHealth = math.Clamp(math.Round((1 - hurt) * 100), 0, 100)
	local health = math.Clamp(math.min(rawHealth, bloodHealth, hurtHealth), 0, 100)
	local details = string.format("Кровь %d  Пульс %d", blood, pulse)

	if org.heartstop or pulse <= 0 then
		return "ОСТАНОВКА", details, Color(220, 70, 70), health, health
	end

	if org.otrub or org.incapacitated then
		return "БЕЗ СОЗНАНИЯ", details, Color(255, 170, 90), health, health
	end

	if org.critical or blood <= 2600 or health <= 20 then
		return "ПРИ СМЕРТИ", details, Color(225, 90, 90), health, health
	end

	if blood <= 3400 or health <= 45 or pain >= 85 then
		return "ТЯЖЕЛОЕ", details, Color(235, 180, 80), health, health
	end

	if blood <= 4300 or health <= 80 or pain >= 35 then
		return "РАНЕН", details, Color(210, 220, 120), health, health
	end

	return "СТАБИЛЕН", details, Color(120, 220, 120), health, health
end

local function GetSpectatorMarkerHealthColor(health)
	health = math.Clamp(health or 0, 0, 100)

	if health <= 20 then
		return Color(215, 70, 70)
	elseif health <= 45 then
		return Color(230, 155, 75)
	elseif health <= 75 then
		return Color(205, 215, 95)
	end

	return Color(110, 215, 120)
end

local function ClampSpectatorMarker(x, y, margin, sw, sh)
	local cx, cy = sw * 0.5, sh * 0.5
	local visible = x > margin and x < (sw - margin) and y > margin and y < (sh - margin)

	if visible then
		return x, y, true
	end

	local dx = x - cx
	local dy = y - cy

	if dx == 0 and dy == 0 then
		dx = 1
	end

	local scale = math.max(
		math.abs(dx) / math.max(cx - margin, 1),
		math.abs(dy) / math.max(cy - margin, 1),
		1
	)

	return cx + dx / scale, cy + dy / scale, false
end

local zbSpectatorMarkersEnabled = true
local zbSpectatorMarkersAltDown = false
local mat_gradient = Material("vgui/gradient-d")

hook.Add("Think", "ZB_SpectatorPlayerMarkersToggle", function()
	local altDown = input.IsKeyDown(KEY_LALT) or input.IsKeyDown(KEY_RALT)

	if altDown and not zbSpectatorMarkersAltDown then
		zbSpectatorMarkersEnabled = not zbSpectatorMarkersEnabled
	end

	zbSpectatorMarkersAltDown = altDown
end)

hook.Add("HUDPaint", "ZB_SpectatorPlayerMarkers", function()
	local lp = LocalPlayer()

	local clr_bg = Color(10, 10, 19, 235)
	local clr_accent = Color(165, 165, 165)

	if not IsValid(lp) or lp:Alive() then return end
	if lp:GetObserverMode() == OBS_MODE_NONE and not IsValid(lp:GetNWEntity("spect")) then return end
	if not zbSpectatorMarkersEnabled then return end

	local sw, sh = ScrW(), ScrH()
	local margin = ScreenScale(16)
	local padX = ScreenScale(6)
	local padY = ScreenScale(5)

	for _, ply in player.Iterator() do
		if not IsValid(ply) or ply == lp then continue end
		if ply:Team() == TEAM_SPECTATOR then continue end
		if not ply:Alive() then continue end

		local ent = GetSpectatorMarkerEntity(ply)
		local worldPos = GetSpectatorMarkerPos(ent)
		if not worldPos then continue end

		local scr = worldPos:ToScreen()
		local posX, posY, onScreen = ClampSpectatorMarker(scr.x, scr.y, margin, sw, sh)
		if not onScreen then continue end
		local playerColor = ply:GetPlayerColor():ToColor()
		local nameText = GetSpectatorMarkerName(ply, ent)
		local stateText, detailsText, stateColor, health, hpNumber = GetSpectatorMarkerState(ply, ent)
		local healthColor = GetSpectatorMarkerHealthColor(health)
		local barH = math.max(ScreenScale(1), 4)
		local hpText = tostring(math.Clamp(math.Round(hpNumber or health), 0, 100))
		posY = posY + ScreenScale(8)

		surface.SetFont("HomigradFontSmall")
		local nameW, nameH = surface.GetTextSize(nameText)
		surface.SetFont("HomigradFontSmall")
		local hpW, hpH = surface.GetTextSize(hpText)
		local stateW, stateH = 0, 0 

		local boxW = math.max(ScreenScale(45), nameW + hpW + 28)
		local boxH = nameH + stateH + barH + 10
		local boxX = posX - boxW * 0.5
		local boxY = posY - boxH * 0.5

		draw.RoundedBox(0, boxX, boxY, boxW, boxH, clr_bg)
		surface.SetDrawColor(clr_accent.r, clr_accent.g, clr_accent.b, 80)
		surface.DrawOutlinedRect(boxX, boxY, boxW, boxH, 1)

		surface.SetDrawColor(playerColor)
		surface.DrawRect(boxX, boxY, 2, boxH)
		surface.SetMaterial(Material("vgui/gradient-d"))
		surface.SetDrawColor(0, 0, 0, 120)
		surface.DrawTexturedRect(boxX, boxY, 2, boxH)

		local nameX = boxX + 10
		local nameY = boxY + 4
		local hpX = boxX + boxW - 8
		local hpY = boxY + 4
		local barX = boxX + 10
		local barY = boxY + boxH - 8
		local barW = boxW - 18

		local t = RealTime() * 4
		local chars = GetTextChars(nameText)
		local cx = nameX
		surface.SetFont("HomigradFontSmall")
		for i, char in ipairs(chars) do
			local cw = surface.GetTextSize(char)
			local shimmer = (math.sin(t - i * 0.4) + 1) * 0.5
			local col = Color(140, 140, 145):Lerp(Color(255, 255, 255), shimmer)
			draw.SimpleText(char, "HomigradFontSmall", cx + 1, nameY + 1, Color(0, 0, 0, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			draw.SimpleText(char, "HomigradFontSmall", cx, nameY, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			cx = cx + cw
		end

		-- draw.SimpleText(stateText, "HomigradFontVSmall", nameX, nameY + nameH - 4, Color(160, 160, 165, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP) -- Убрали текст состояния

		draw.SimpleText(hpText, "HomigradFontSmall", hpX + 1, hpY + 1, Color(0, 0, 0, 210), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		draw.SimpleText(hpText, "HomigradFontSmall", hpX, hpY, healthColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

		draw.RoundedBox(0, barX, barY, barW, barH, Color(30, 30, 35, 150))
		
		local fillW = math.max(2, barW * (health / 100))
		surface.SetDrawColor(healthColor)
		surface.DrawRect(barX, barY, fillW, barH)
		surface.SetMaterial(Material("vgui/gradient-l"))
		surface.SetDrawColor(128, 128, 128, 50)
		surface.DrawTexturedRect(barX, barY, fillW, barH)

		surface.SetDrawColor(255, 255, 255, 10)
		surface.DrawOutlinedRect(barX, barY, barW, barH, 1)
	end
end)

hook.Add("HG_CalcView", "zzzzzzzUwU", function(ply, pos, angles, fov)
	if not lply:Alive() then
		if lply:KeyDown(IN_ATTACK) then
			if not keydownattack then
				keydownattack = true
				net.Start("ZB_ChooseSpecPly")
				net.WriteInt(IN_ATTACK,32)
				net.SendToServer()
			end
		else
			keydownattack = false
		end

		if lply:KeyDown(IN_ATTACK2) then
			if not keydownattack2 then
				keydownattack2 = true
				net.Start("ZB_ChooseSpecPly")
				net.WriteInt(IN_ATTACK2,32)
				net.SendToServer()
			end
		else
			keydownattack2 = false
		end

		if lply:KeyDown(IN_RELOAD) then
			if not keydownreload then
				keydownreload = true
				net.Start("ZB_ChooseSpecPly")
				net.WriteInt(IN_RELOAD,32)
				net.SendToServer()
			end
		else
			keydownreload = false
		end

		local spect = lply:GetNWEntity("spect",spect)
		if not IsValid(spect) then return end

		local viewmode = lply:GetNWInt("viewmode",viewmode)
		
		if viewmode == 3 then
			if lply:GetMoveType()!=MOVETYPE_NOCLIP then
				lply:SetMoveType(MOVETYPE_NOCLIP)
			end
			lply:SetObserverMode(OBS_MODE_ROAMING)
			return
		else
			lply:SetPos(spect:GetPos())
		end
		
		local ent = hg.GetCurrentCharacter(spect)
		if not IsValid(ent) then return end
		
		local headBone = ent:LookupBone("ValveBiped.Bip01_Head1") or ent:LookupBone("ValveBiped.Bip01_Spine1") or 1
		local bon = ent:GetBoneMatrix(headBone)
		
		if not bon then 
			local eyePos = ent:EyePos()
			if eyePos and eyePos ~= vector_origin then
				pos = eyePos
				ang = ent:EyeAngles()
			else
				pos = ent:GetPos() + Vector(0, 0, 64)
				ang = ent:GetAngles()
			end
		else
			pos, ang = bon:GetTranslation(), bon:GetAngles()
		end

		local eyePos, eyeAng = lply:EyePos(), lply:EyeAngles()
		
		local tr = {}
		tr.start = pos
		tr.endpos = pos + eyeAng:Forward() * -120
		tr.filter = {ent, lply, spect}
		tr.mins = Vector(-4, -4, -4)
		tr.maxs = Vector(4, 4, 4)
		tr = util.TraceHull(tr)

		if viewmode == 2 then
			pos = tr.HitPos + eyeAng:Forward() * 8
			ang = eyeAng
		elseif viewmode == 1 then
			if ent ~= spect and IsValid(ent) then
				local eyeAtt = ent:GetAttachment(ent:LookupAttachment("eyes"))
				if eyeAtt then
					ang = eyeAtt.Ang
				else
					ang = spect:EyeAngles()
				end
			else
				ang = spect:EyeAngles()
			end
			pos = pos + spect:EyeAngles():Forward() * 8
		else
			pos = eyePos
			ang = eyeAng
		end
		
		ang[3] = 0
		
		local view
		local hg_newspectate = GetConVar("hg_newspectate")
		if hg_newspectate and hg_newspectate:GetBool() then
			if not lply.spectLastPos then
				lply.spectLastPos = pos
				lply.spectLastAng = ang
			end
			
			local lerpFactor = FrameTime() * 10
			lply.spectLastPos = LerpVector(lerpFactor, lply.spectLastPos, pos)
			lply.spectLastAng = LerpAngle(lerpFactor, lply.spectLastAng, ang)

			view = {
				origin = lply.spectLastPos,
				angles = lply.spectLastAng,
				fov = fov,
			}
		else
			view = {
				origin = pos,
				angles = ang,
				fov = fov,
			}
		end

		return view
	else
		lply.spectLastPos = nil
		lply.spectLastAng = nil
		lply:SetObserverMode(OBS_MODE_NONE)
	end
end)

zb.fade = zb.fade or 0

hook.Add("RenderScreenspaceEffects", "huyhuyUwU", function()
	if zb.fade > 0 then
		zb.fade = math.Approach(zb.fade, 0, FrameTime() * 1)

		surface.SetDrawColor(0, 0, 0, 255 * math.min(zb.fade, 1))
		surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1 )
	end
end)

zb.ROUND_STATE = 0
net.Receive("RoundInfo", function()
	local rnd = net.ReadString()
	
	hook.Run("RoundInfoCalled", rnd)

	if zb.CROUND ~= rnd then
		if hg.DynaMusic then
			hg.DynaMusic:Stop()
		end
	end

	zb.CROUND = rnd

	zb.ROUND_STATE = net.ReadInt(4)
	
	if zb.ROUND_STATE == 0 then
		zb.fade = 7
	end

	if zb.CROUND ~= "" then
		if CurrentRound() then
			if zb.ROUND_STATE == 3 then
				if CurrentRound().EndRound then
					CurrentRound():EndRound()
				end
			elseif zb.ROUND_STATE == 1 then
				if CurrentRound().RoundStart then
					CurrentRound():RoundStart()
				end
			end
		end
	end
end)

if IsValid(scoreBoardMenu) then
	scoreBoardMenu:Remove()
	scoreBoardMenu = nil
end

hook.Add("Player Disconnected","retrymenu",function(data)
	if IsValid(scoreBoardMenu) then
		scoreBoardMenu:Remove()
		scoreBoardMenu = nil
	end
end)

--local hg_coolvetica = ConVarExists("hg_coolvetica") and GetConVar("hg_coolvetica") or CreateClientConVar("hg_coolvetica", "0", true, false, "changes every text to coolvetica because its good", 0, 1)
local hg_font = ConVarExists("hg_font") and GetConVar("hg_font") or CreateClientConVar("hg_font", "Bahnschrift", true, false, "Change UI text font")
local font = function() -- hg_coolvetica:GetBool() and "Coolvetica" or "Bahnschrift"
    local usefont = "Bahnschrift"

    if hg_font:GetString() != "" then
        usefont = hg_font:GetString()
    end

    return usefont
end

surface.CreateFont("ZB_InterfaceSmall", {
    font = font(),
    size = ScreenScale(6),
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_InterfaceMedium", {
    font = font(),
    size = ScreenScale(10),
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_ScrappersMedium", {
    font = font(),
    size = ScreenScale(10),
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_InterfaceMediumLarge", {
    font = font(),
    size = 35,
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_InterfaceLarge", {
    font = font(),
    size = ScreenScale(20),
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_InterfaceHumongous", {
    font = font(),
    size = 200,
    weight = 400,
    antialias = true
})

hg.playerInfo = hg.playerInfo or {}

local function addToPlayerInfo(ply, muted, volume)
	hg.playerInfo[ply:SteamID()] = {muted and true or false, volume}

	local json = util.TableToJSON(hg.playerInfo)
	file.Write("zcity_muted.txt", json)

	if file.Exists("zcity_muted.txt", "DATA") then
		local json = file.Read("zcity_muted.txt", "DATA")

		if json then
			hg.playerInfo = util.JSONToTable(json)
		end
	end

	//PrintTable(hg.playerInfo)
end

gameevent.Listen("player_connect")
hook.Add("player_connect", "zcityhuy", function(data)
	local ply = Player(data.userid)
	if IsValid(ply) and ply.SetMuted and hg.playerInfo and hg.playerInfo[data.networkid] then
		ply:SetMuted(hg.playerInfo[data.networkid][1])
		ply:SetVoiceVolumeScale(hg.playerInfo[data.networkid][2])
	end
end)

hook.Add("InitPostEntity", "furryhuy", function()
	if file.Exists("zcity_muted.txt", "DATA") then
		local json = file.Read("zcity_muted.txt", "DATA")

		if json then
			hg.playerInfo = util.JSONToTable(json)
		end

		if hg.playerInfo then
			for i, ply in player.Iterator() do
				if not istable(hg.playerInfo[ply:SteamID()]) then
					local muted = hg.playerInfo[ply:SteamID()]
					hg.playerInfo[ply:SteamID()] = {}
					hg.playerInfo[ply:SteamID()][1] = muted
					hg.playerInfo[ply:SteamID()][2] = 1
				end//compatibility with old json

				if hg.playerInfo[ply:SteamID()] then
					ply:SetMuted(hg.playerInfo[ply:SteamID()][1])
					ply:SetVoiceVolumeScale(hg.playerInfo[ply:SteamID()][2])
				end
			end	
		end
	end
end)

local colGray = Color(122,122,122,255)
local colBlue = Color(70,70,70,255)
local colBlueUp = Color(92,92,92,255)
local col = Color(255,255,255,255)

local colSpect1 = Color(60,60,60,255)
local colSpect2 = Color(80,80,80,255)

local scoreOutline = Color(135,135,135,180)
local scoreOutlineActive = Color(190,190,190,220)

local colorBG = Color(55,55,55,255)
local colorBGBlacky = Color(40,40,40,255)

hg.muteall = false
hg.mutespect = false

local function OpenPlayerSoundSettings(selfa, ply)
	local Menu = DermaMenu()
	
	if not hg.playerInfo[ply:SteamID()] or not istable(hg.playerInfo[ply:SteamID()]) then addToPlayerInfo(ply, false, 1) end

	local mute = Menu:AddOption( "Mute", function(self)
		if hg.muteall || hg.mutespect then return end
		
		self:SetChecked(not ply:IsMuted())
		ply:SetMuted( not ply:IsMuted() )
		selfa:SetImage(not ply:IsMuted() && "icon16/sound.png" || "icon16/sound_mute.png")
		addToPlayerInfo(ply, ply:IsMuted(), hg.playerInfo[ply:SteamID()][2])
	end ) -- get your stupid one line ass outta here

	mute:SetIsCheckable( true )
	mute:SetChecked( ply:IsMuted() )
	local volumeSlider = vgui.Create("DSlider", Menu)
	volumeSlider:SetLockY( 0.5 )
	volumeSlider:SetTrapInside( true )
	volumeSlider:SetSlideX(hg.playerInfo[ply:SteamID()][2]) 
	volumeSlider.OnValueChanged = function(self, x, y)
		if not IsValid(ply) then return end
		if hg.muteall or (hg.mutespect && !ply:Alive()) then return end
		hg.playerInfo[ply:SteamID()][2] = x
		ply:SetVoiceVolumeScale(hg.playerInfo[ply:SteamID()][2])
		addToPlayerInfo(ply, ply:IsMuted(), hg.playerInfo[ply:SteamID()][2])
	end

	function volumeSlider:Paint(w,h)
		draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0 ) )
		draw.RoundedBox( 0, 0, 0, w*self:GetSlideX(), h, Color( 120, 120, 120 ) )
		draw.DrawText( ( math.Round( 100*self:GetSlideX(), 0 ) ).."%", "DermaDefault", w/2, h/4, color_white, TEXT_ALIGN_CENTER )
	end
	function volumeSlider.Knob.Paint(self) end

	Menu:AddPanel(volumeSlider)
	Menu:Open()
end



hook.Add("Player Getup", "nomorespect", function(ply)
	if not hg.mutespect then return end

	//ply:SetMuted(ply.oldmutedspect)
	ply:SetVoiceVolumeScale(!hg.muteall and (hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2] or 1) or 0)
	//ply.oldmutedspect = nil

	//if IsValid(ply.soundButton) then
		//ply.soundButton:SetImage(not ply:IsMuted() && "icon16/sound.png" || "icon16/sound_mute.png")
	//end
end)

hook.Add("Player_Death", "fixSpectatorVoiceMute", function(ply)
	if not hg.mutespect then return end

	//ply.oldmutedspect = ply:IsMuted()
	//ply:SetMuted(hg.mutespect)
	ply:SetVoiceVolumeScale(0)
	//if IsValid(ply.soundButton) then
		//ply.soundButton:SetImage(not ply:IsMuted() && "icon16/sound.png" || "icon16/sound_mute.png")
	//end
end)

hook.Add("Player_Death", "fixSpectatorVoiceEffect", function(ply)
	if eightbit and eightbit.EnableEffect and ply.UserID then
		eightbit.EnableEffect(ply:UserID(), 0)
	end
end)

local function GetScoreboardPrivilegeTag(ply)
	if not IsValid(ply) then return "user" end
	if ply:IsBot() then return "bot" end
	if not ply.GetUserGroup then return "user" end

	local group = tostring(ply:GetUserGroup() or "")
	if group == "" then
		group = "user"
	end

	return string.lower(group)
end

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

function hg.Query(text, title, btn1Text, btn1Func, btn2Text, btn2Func)
    local frame = vgui.Create("DFrame")
    local w, h = ScreenScale(160), ScreenScale(65)
    frame:SetSize(w, h)
    frame:Center()
    frame:SetTitle("")
    frame:MakePopup()
    frame:ShowCloseButton(false)

    -- Анимация появления: смещение вниз и прозрачность
    local targetY = frame:GetY()
    frame:SetPos(frame:GetX(), targetY + ScreenScale(15))
    frame:SetAlpha(0)
    
    frame:AlphaTo(255, 0.2, 0)
    frame:MoveTo(frame:GetX(), targetY, 0.25, 0, 0.4)

    local clr_bg = Color(10, 10, 19, 245)
    local clr_accent = Color(140, 140, 145)
    local clr_text = Color(225, 225, 225)

    frame.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, clr_bg)
        hg.DrawBlur(self, 5)

        local gridSize = ScreenScale(20)
        local gridTime = RealTime() * 12
        local offset = gridTime % gridSize

        surface.SetDrawColor(200, 200, 200, 8)
        for i = -1, math.ceil(w / gridSize) + 1 do
            surface.DrawRect(i * gridSize - offset, 0, 1, h)
        end
        for i = -1, math.ceil(h / gridSize) + 1 do
            surface.DrawRect(0, i * gridSize + offset, w, 1)
        end

        surface.SetDrawColor(clr_accent.r, clr_accent.g, clr_accent.b, 120)
        surface.DrawOutlinedRect(0, 0, w, h, 2)

        local titleText = string.upper(title or "ВНИМАНИЕ")
        local t = RealTime() * 4
        local chars = GetTextChars(titleText)
        local cx = 10
        surface.SetFont("ZB_InterfaceMedium")
        for i, char in ipairs(chars) do
            local cw = surface.GetTextSize(char)
            local shimmer = (math.sin(t - i * 0.4) + 1) * 0.5
            local col = Color(140, 140, 145):Lerp(Color(255, 255, 255), shimmer)
            draw.SimpleText(char, "ZB_InterfaceMedium", cx, 8, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            cx = cx + cw
        end

        draw.DrawText(text, "ZB_InterfaceSmall", w / 2, h * 0.42, clr_text, TEXT_ALIGN_CENTER)
    end

    local function CreateBtn(name, x, y, w, h, func)
        local btn = vgui.Create("DButton", frame)
        btn:SetSize(w, h)
        btn:SetPos(x, y)
        btn:SetText("")
        btn.HoverLerp = 0
        btn.Paint = function(s, w, h)
            s.HoverLerp = LerpFT(0.1, s.HoverLerp, s:IsHovered() and 1 or 0)
            local v = s.HoverLerp
            draw.RoundedBox(0, 0, 0, w, h, Color(25, 25, 30, 150 + v * 50))
            surface.SetDrawColor(clr_accent.r, clr_accent.g, clr_accent.b, 30 + v * 120)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText(string.upper(name), "ZB_InterfaceSmall", w / 2, h / 2, clr_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        btn.DoClick = function()
            frame:AlphaTo(0, 0.15, 0, function()
                if IsValid(frame) then frame:Remove() end
            end)
            if func then func() end
            surface.PlaySound("shitty/tap_depress.wav")
        end
    end

    local bw, bh = frame:GetWide() * 0.42, ScreenScale(14)
    CreateBtn(btn1Text or "OK", frame:GetWide() * 0.05, frame:GetTall() - bh - 10, bw, bh, btn1Func)
    CreateBtn(btn2Text or "CANCEL", frame:GetWide() * 0.53, frame:GetTall() - bh - 10, bw, bh, btn2Func)
end

function GM:ScoreboardShow()
	if IsValid(scoreBoardMenu) then
		scoreBoardMenu:Remove()
		scoreBoardMenu = nil
	end
	Dynamic = 0
	scoreBoardMenu = vgui.Create("ZFrame")

	local sizeX,sizeY = ScrW() / 1.3 ,ScrH() / 1.2
	local posX,posY = ScrW() / 2 - sizeX / 2,ScrH() / 2 - sizeY / 2

	scoreBoardMenu:SetPos(posX,posY)
	scoreBoardMenu:SetSize(sizeX,sizeY)
	scoreBoardMenu:MakePopup()
	scoreBoardMenu:SetKeyboardInputEnabled( false )
	scoreBoardMenu:ShowCloseButton( false )

	local clr_bg = Color(14, 14, 14, 235)
	local clr_accent = Color(140, 140, 145)
	local clr_text = Color(225, 225, 225)
	local clr_text_sub = Color(105, 105, 105)

	scoreBoardMenu.Paint = function(self, w, h)
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
		surface.SetTexture(surface.GetTextureID("vgui/gradient-l"))
		surface.DrawTexturedRect(0, 0, w, h)

		surface.SetDrawColor(83, 83, 83, 30)
		surface.SetTexture(surface.GetTextureID("vgui/gradient-d"))
		surface.DrawTexturedRect(0, 0, w, h)
	end

	local muteallbut = vgui.Create("DButton", scoreBoardMenu)
	local w, h = ScreenScale(30),ScreenScale(6)
	muteallbut:SetPos(scoreBoardMenu:GetWide()-w*2.3,scoreBoardMenu:GetTall() - h * 1.5)
	muteallbut:SetSize(w, h)
	muteallbut:SetText("Mute all")
	
	muteallbut.Paint = function(self,w,h)
		local clr = hg.muteall and scoreOutlineActive or scoreOutline
		surface.SetDrawColor(clr.r, clr.g, clr.b, clr.a)
		surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
	end

	muteallbut.DoClick = function(self,w,h)
		hg.muteall = not hg.muteall
		
		for i,ply in player.Iterator() do
			if hg.muteall then
				//ply.oldmutedspect = ply:IsMuted()

				ply:SetVoiceVolumeScale(0)
				//if IsValid(ply.soundButton) then
					//ply.soundButton:SetImage(not ply:IsMuted() && "icon16/sound.png" || "icon16/sound_mute.png")
				//end
			else
				ply:SetVoiceVolumeScale((!hg.mutespect or ply:Alive()) and (hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2] or 1) or 0)
				//ply:SetMuted(ply.oldmuted)
				//if IsValid(ply.soundButton) then
					//ply.soundButton:SetImage(not ply:IsMuted() && "icon16/sound.png" || "icon16/sound_mute.png")
				//end
				//ply.oldmuted = nil
			end
		end 
	end

	local mutespectbut = vgui.Create("DButton", scoreBoardMenu)
	local w, h = ScreenScale(30),ScreenScale(6)
	mutespectbut:SetPos(scoreBoardMenu:GetWide()-w*1.2,scoreBoardMenu:GetTall() - h * 1.5)
	mutespectbut:SetSize(w, h)
	mutespectbut:SetText("Mute spectators")
	
	mutespectbut.Paint = function(self,w,h)
		local clr = hg.mutespect and scoreOutlineActive or scoreOutline
		surface.SetDrawColor(clr.r, clr.g, clr.b, clr.a)
		surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
	end

	mutespectbut.DoClick = function(self,w,h)
		hg.mutespect = not hg.mutespect
		
		for i,ply in player.Iterator() do
			if ply:Alive() then continue end

			if hg.mutespect then
				ply:SetVoiceVolumeScale(0)
				//ply.oldmutedspect = ply:IsMuted()

				//ply:SetMuted(true)
				//if IsValid(ply.soundButton) then
					//ply.soundButton:SetImage(not ply:IsMuted() && "icon16/sound.png" || "icon16/sound_mute.png")
				//end
			else
				ply:SetVoiceVolumeScale(!hg.muteall and (hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2] or 1) or 0)
				//ply:SetMuted(ply.oldmutedspect)
				//if IsValid(ply.soundButton) then
					//ply.soundButton:SetImage(not ply:IsMuted() && "icon16/sound.png" || "icon16/sound_mute.png")
				//end
				//ply.oldmutedspect = nil
			end
		end 
	end

	local ServerName = GetHostName() or "ZCity | Developer Server | #01"
	local tick
	scoreBoardMenu.PaintOver = function(self,w,h)
		surface.SetDrawColor(clr_accent.r, clr_accent.g, clr_accent.b, 100)
		surface.DrawOutlinedRect(0, 0, w, h, 2)

		local title = string.upper(ServerName)
		local t = RealTime() * 4
		surface.SetFont("ZB_InterfaceLarge")
		local tw, th = surface.GetTextSize(title)
		local x, y = w / 2, 15
		local startX = x - tw * 0.5

		draw.SimpleText(title, "ZB_InterfaceLarge", x + 2, y + 2, Color(0, 0, 0, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

		local chars = GetTextChars(title)
		local accumulatedW = 0
		for i, char in ipairs(chars) do
			local cw = surface.GetTextSize(char)
			local shimmer = (math.sin(t - i * 0.4) + 1) * 0.5
			local col_shimmer = Color(100, 100, 100):Lerp(Color(255, 255, 255), shimmer)
			draw.SimpleText(char, "ZB_InterfaceLarge", startX + accumulatedW, y, col_shimmer, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			accumulatedW = accumulatedW + cw
		end

		surface.SetFont( "ZB_InterfaceSmall" )
		surface.SetTextColor(clr_text_sub.r, clr_text_sub.g, clr_text_sub.b, 100)
		local txt = "ZC Version: "..hg.Version
		local lengthX, lengthY = surface.GetTextSize(txt)
		surface.SetTextPos(w*0.01,h - lengthY - h*0.01)
		surface.DrawText(txt)

		surface.SetFont( "ZB_InterfaceMediumLarge" )
		surface.SetTextColor(clr_text.r, clr_text.g, clr_text.b, 255)
		
		local pTxt = "PLAYERS [" .. #player.GetAll() - #team.GetPlayers(TEAM_SPECTATOR) .. "]"
		draw.SimpleText(pTxt, "ZB_InterfaceMediumLarge", w / 4, ScreenScale(25), clr_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

		local sTxt = "SPECTATORS [" .. #team.GetPlayers(TEAM_SPECTATOR) .. "]"
		draw.SimpleText(sTxt, "ZB_InterfaceMediumLarge", w * 0.75, ScreenScale(25), clr_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

		tick = math.Round(1 / engine.ServerFrameTime())
		local txt = "SV TICK: " .. tick
		local lengthX, lengthY = surface.GetTextSize(txt)
		surface.SetTextPos(w * 0.5 - lengthX/2,ScreenScale(25))
		surface.DrawText(txt)
	end
	-- TEAMSELECTION
	if LocalPlayer():Team() ~= TEAM_SPECTATOR then
		local SPECTATE = vgui.Create("DButton",scoreBoardMenu)
		SPECTATE:SetPos(sizeX * 0.925,sizeY * 0.095)
		SPECTATE:SetSize(ScrW() / 20,ScrH() / 30)
		SPECTATE:SetText("")
		
		SPECTATE.DoClick = function()
			net.Start("ZB_SpecMode")
				net.WriteBool(true)
			net.SendToServer()
			scoreBoardMenu:Remove()
			scoreBoardMenu = nil
		end

		SPECTATE.Paint = function(self,w,h)
			surface.SetDrawColor(scoreOutline.r, scoreOutline.g, scoreOutline.b, scoreOutline.a)
			surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
			surface.SetFont( "ZB_InterfaceMedium" )
			surface.SetTextColor(col.r,col.g,col.b,col.a)
			local lengthX, lengthY = surface.GetTextSize("Join")
			surface.SetTextPos( lengthX - lengthX/2, 2)
			surface.DrawText("Join")
		end
	end

	if LocalPlayer():Team() == TEAM_SPECTATOR then
		local PLAYING = vgui.Create("DButton",scoreBoardMenu)
		PLAYING:SetPos(sizeX * 0.010,sizeY * 0.095)
		PLAYING:SetSize(ScrW() / 20,ScrH() / 30)
		PLAYING:SetText("")
		
		PLAYING.DoClick = function()
			net.Start("ZB_SpecMode")
				net.WriteBool(false)
			net.SendToServer()
			scoreBoardMenu:Remove()
			scoreBoardMenu = nil
		end

		PLAYING.Paint = function(self,w,h)
			surface.SetDrawColor(scoreOutline.r, scoreOutline.g, scoreOutline.b, scoreOutline.a)
			surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
			surface.SetFont( "ZB_InterfaceMedium" )
			surface.SetTextColor(col.r,col.g,col.b,col.a)
			local lengthX, lengthY = surface.GetTextSize("Join")
			surface.SetTextPos( lengthX - lengthX/2, 2)
			surface.DrawText("Join")
		end
	end

	--без матов

	local DScrollPanel = vgui.Create("DScrollPanel", scoreBoardMenu)
	DScrollPanel:SetPos(10, ScreenScaleH(58))
	DScrollPanel:SetSize(sizeX/2 - 10, sizeY - ScreenScaleH(72))
	function DScrollPanel:Paint( w, h )
		-- BlurBackground(self)

		surface.SetDrawColor(0, 0, 0, 100)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(clr_accent.r, clr_accent.g, clr_accent.b, 50)
        surface.DrawOutlinedRect( 0, 0, w, h, 1 )
	end

	local disappearance = lply:GetNetVar("disappearance", nil)
	for i, ply in player.Iterator() do -- надо это говно переделать.
		if ply:Team() == TEAM_SPECTATOR then continue end
		if CurrentRound().name == "fear" and !ply:Alive() then continue end
		if disappearance and ply != lply then continue end

		local but = vgui.Create("DButton", DScrollPanel)
		but:SetSize(100, ScreenScaleH(22))
		but:Dock(TOP)
		but:DockMargin(8, 6, 8, -1)
		but:SetText("")
		
		local soundButton = vgui.Create("DImageButton", but)
		soundButton:Dock(RIGHT)
		soundButton:SetSize( 30, 0 )
		soundButton:DockMargin(5,10,45,10)
		
		soundButton:SetImage(not ply:IsMuted() && "icon16/sound.png" || "icon16/sound_mute.png") 
		soundButton.DoClick = function(self)
			OpenPlayerSoundSettings(self, ply) 
		end
		ply.soundButton = soundButton
	
		but.Paint = function(self, w, h)
			if not IsValid(ply) then return end
			local hov = self:IsHovered() and 1 or 0
			self.HoverLerp = LerpFT(0.1, self.HoverLerp or 0, hov)
			local v = self.HoverLerp

			draw.RoundedBox(0, 0, 0, w, h, Color(20, 20, 25, 150 + v * 50))
			surface.SetDrawColor(clr_accent.r, clr_accent.g, clr_accent.b, 20 + v * 100)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
	
			surface.SetFont("ZB_InterfaceMediumLarge")
			local playerTitle = string.upper(ply:Name() or "Unknown") .. "  |  " .. string.upper(GetScoreboardPrivilegeTag(ply))
			
			local t = RealTime() * 7
			local chars = GetTextChars(playerTitle)
			local cx = 15
			for i, char in ipairs(chars) do
				local cw = surface.GetTextSize(char)
				local shimmer = (math.sin(t - i * 0.4) + 1) * 0.5
				local col = clr_text:Lerp(Color(255, 255, 255), v * shimmer)
				draw.SimpleText(char, "ZB_InterfaceMediumLarge", cx, h / 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				cx = cx + cw
			end
	
			draw.SimpleText(ply:Ping(), "ZB_InterfaceMediumLarge", w - 15, h / 2, clr_text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		end

		function but:DoClick()
			if ply:IsBot() then chat.AddText(Color(255,0,0), "no, you can't") return end
			hg.Query(
				"ОТКРЫТЬ ВНЕШНЮЮ ССЫЛКУ НА ПРОФИЛЬ " .. string.upper(ply:Nick()) .. "?",
				"Внешняя ссылка",
				"ОТКРЫТЬ", function() 
					gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64()) 
				end,
				"ОТМЕНА"
			)
		end

		function but:DoRightClick()
			--if ply:IsBot() then chat.AddText(Color(255,0,0), "no, you can't") return end
			local Menu = DermaMenu()
			Menu:AddOption( "Account", function(self)
				zb.Experience.AccountMenu( ply )
			end)
			Menu:AddOption( "Copy SteamID", function(self)
				SetClipboardText(ply:SteamID())
			end)

			Menu:Open()
		end
	
		DScrollPanel:AddItem(but)
	end
	-- SPECTATORS
	local DScrollPanel = vgui.Create("DScrollPanel", scoreBoardMenu)
	DScrollPanel:SetPos(sizeX/2 + 5, ScreenScaleH(58))
	DScrollPanel:SetSize(sizeX/2 - 15, sizeY - ScreenScaleH(72))
	function DScrollPanel:Paint( w, h )
		-- BlurBackground(self)

		surface.SetDrawColor(0, 0, 0, 100)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(clr_accent.r, clr_accent.g, clr_accent.b, 50)
        surface.DrawOutlinedRect( 0, 0, w, h, 1 )
	end

	for i, ply in player.Iterator() do
		if ply:Team() ~= TEAM_SPECTATOR then continue end
		if CurrentRound().name == "fear" and !ply:Alive() then continue end
		if disappearance and ply != lply then continue end

		local but = vgui.Create("DButton", DScrollPanel)
		but:SetSize(100, ScreenScaleH(22))
		but:Dock(TOP)
		but:DockMargin( 8, 6, 8, -1 )
		but:SetText("")

		local soundButton = vgui.Create("DImageButton", but)
		soundButton:Dock(RIGHT)
		soundButton:SetSize( 30, 0 )
		soundButton:DockMargin(5,10,45,10)
		
		soundButton:SetImage(not ply:IsMuted() && "icon16/sound.png" || "icon16/sound_mute.png") 
		soundButton.DoClick = function(self)
			OpenPlayerSoundSettings(self, ply)
		end
		ply.soundButton = soundButton

		but.Paint = function(self,w,h)
			if not IsValid(ply) then return end
			local hov = self:IsHovered() and 1 or 0
			self.HoverLerp = LerpFT(0.1, self.HoverLerp or 0, hov)
			local v = self.HoverLerp

			draw.RoundedBox(0, 0, 0, w, h, Color(20, 20, 25, 120 + v * 40))
			surface.SetDrawColor(clr_accent.r, clr_accent.g, clr_accent.b, 10 + v * 80)
			surface.DrawOutlinedRect(0, 0, w, h, 1)

			surface.SetFont("ZB_InterfaceMediumLarge")
			local playerTitle = string.upper(ply:Name() or "Unknown") .. "  |  " .. string.upper(GetScoreboardPrivilegeTag(ply))

			local t = RealTime() * 7
			local chars = GetTextChars(playerTitle)
			local cx = 15
			for i, char in ipairs(chars) do
				local cw = surface.GetTextSize(char)
				local shimmer = (math.sin(t - i * 0.4) + 1) * 0.5
				local col = clr_text:Lerp(Color(255, 255, 255), v * shimmer)
				draw.SimpleText(char, "ZB_InterfaceMediumLarge", cx, h / 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				cx = cx + cw
			end

			draw.SimpleText(ply:Ping(), "ZB_InterfaceMediumLarge", w - 15, h / 2, clr_text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		end

		function but:DoClick()
			if ply:IsBot() then chat.AddText("That bot.") return end
			hg.Query(
				"ОТКРЫТЬ ВНЕШНЮЮ ССЫЛКУ НА ПРОФИЛЬ " .. string.upper(ply:Nick()) .. "?",
				"Внешняя ссылка",
				"ОТКРЫТЬ", function() 
					gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64()) 
				end,
				"ОТМЕНА"
			)
		end

		function but:DoRightClick()
			--if ply:IsBot() then chat.AddText(Color(255,0,0), "no, you can't") return end
			local Menu = DermaMenu()
			Menu:AddOption( "Account", function(self)
				zb.Experience.AccountMenu( ply )
			end)
			Menu:AddOption( "Copy SteamID", function(self)
				SetClipboardText(ply:SteamID())
			end)
			--Menu:AddOption( "Medal", function(self) 
			--	zb.Experience.OpenMenu(ply)
			--	timer.Simple( .1, function()
			--		zb.Experience.Menu(ply)
			--	end)
			--end) 

			Menu:Open()
		end

		DScrollPanel:AddItem(but)
	end

	return true
end

function GM:ScoreboardHide()
	if IsValid(scoreBoardMenu) then
		scoreBoardMenu:Close()
		scoreBoardMenu = nil
	end
end
local AdminShowVoiceChat = CreateClientConVar("zb_admin_show_voicechat","0",false,false,"Show voicechat panels for admins",0,1)
hook.Add("PlayerStartVoice", "showVoicePanels", function(ply)
	if !IsValid(ply) then return end
	if LocalPlayer():IsAdmin() and AdminShowVoiceChat:GetBool() then return end

	local other_alive = (ply:Alive() and LocalPlayer() != ply) or (ply.organism and (ply.organism.otrub or (ply.organism.brain and ply.organism.brain > 0.05)))

	return other_alive or nil
end)

-- свет от молнии а саму молнию я не сделал skill issue
if CLIENT then
	net.Receive("PunishLightningEffect", function()
		local target = net.ReadEntity()
		if not IsValid(target) then return end
		local dlight = DynamicLight(target:EntIndex())
		if dlight then
			dlight.pos = target:GetPos()
			dlight.r = 126
			dlight.g = 139
			dlight.b = 212
			dlight.brightness = 1
			dlight.Decay = 1000
			dlight.Size = 500
			dlight.DieTime = CurTime() + 1
		end
	end)
end

/*  -- а кстати зачем здесь нэт, это же можно было на клиенте полностью сделать...
	if CLIENT then
		net.Receive("PluvCommand", function()
			local specialSteamID = "STEAM_0:1:81850653" 
			local playerSteamID = LocalPlayer():SteamID() 

			local imageURLs = {"https://sadsalat.github.io/salatis/music/boof.gif", "https://i.ibb.co/drt1Lks/KtvCLSs.webp", "https://media.tenor.com/kG4PmVvJuRIAAAAC/rain-world-rain-world-saint.gif"} 
			local soundURLs = {"https://sadsalat.github.io/salatis/music/sus-rock.mp3", "https://sadsalat.github.io/salatis/music/tiktok-raaaah-scream.mp3", "https://sadsalat.github.io/salatis/music/sus-rock.mp3"} 

			local chosenImage = imageURLs[math.random(#imageURLs)]
			local chosenSound = soundURLs[math.random(#soundURLs)]

			sound.PlayURL(chosenSound, "", function(station)
				if IsValid(station) then
					station:Play()
				else
					print("Unable to play the sound.")
				end
			end)

			local html = vgui.Create("HTML")
			html:OpenURL(chosenImage)
			html:SetSize(ScrW(), ScrH())
			html:Center()
			html:MakePopup()

			timer.Simple(3, function()
				if IsValid(html) then
					html:Remove()
				end
			end)
		end)
	end
*/

local lightningMaterial = Material("sprites/lgtning")

net.Receive("AnotherLightningEffect", function()
    local target = net.ReadEntity()
	if not IsValid(target) then return end
    local points = {}
    for i = 1, 27 do
        points[i] = target:GetPos() + Vector(0, 0, i * 50) + Vector(math.Rand(-20,20),math.Rand(-20,20),math.Rand(-20,20))
    end
    hook.Add( "PreDrawTranslucentRenderables", "LightningExample", function(isDrawingDepth, isDrawingSkybox)
        if isDrawingDepth or isDrawingSkybox then return end
        local uv = math.Rand(0, 1)
        render.OverrideBlend( true, BLEND_SRC_COLOR, BLEND_SRC_ALPHA, BLENDFUNC_ADD, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD )
        render.SetMaterial(lightningMaterial)
        render.StartBeam(27)
        for i = 1, 27 do
            render.AddBeam(points[i], 20, uv * i, Color(255,255,255,255))
        end
        render.EndBeam()
        render.OverrideBlend( false )
    end )
    timer.Simple(0.1, function()
        hook.Remove("PreDrawTranslucentRenderables", "LightningExample")
    end)
end)

function GM:AddHint( name, delay )
	return false
end

local snakeGameOpen = false

concommand.Add("zb_snake", function()
    if snakeGameOpen then
        print("[Snake Game] Игра уже запущена!")
        return
    end

    local frame = vgui.Create("ZFrame")
    frame:SetTitle("Snake Game")
    frame:SetSize(400, 400)
    frame:Center()
    frame:MakePopup()
    frame:SetDeleteOnClose(true)  
    snakeGameOpen = true  

    local gridSize = 20
    local gridWidth = 19  
    local gridHeight = 19  
    local snakePanel = vgui.Create("DPanel", frame)
    snakePanel:SetSize(380, 380)
    snakePanel:SetPos(10, 10)

    
    frame:SetDraggable(true)
    frame:ShowCloseButton(true)

    local snake = {
        {x = 10, y = 10},
    }
	
    local snakeDirection = "RIGHT"
    local food = nil
    local score = 0
    local gameRunning = true

  
    local function spawnFood()
        local validPosition = false
        while not validPosition do
            local newFood = {
                x = math.random(0, gridWidth - 1), 
                y = math.random(0, gridHeight - 1)
            }
            validPosition = true

        
            for _, segment in ipairs(snake) do
                if segment.x == newFood.x and segment.y == newFood.y then
                    validPosition = false  
                    break
                end
            end

            
            if validPosition then
                food = newFood
            end
        end
    end

    
    local function drawSnake()
        surface.SetDrawColor(0, 255, 0, 255)
        for _, segment in ipairs(snake) do
            surface.DrawRect(segment.x * gridSize, segment.y * gridSize, gridSize - 1, gridSize - 1)
        end
    end

  
    local function drawFood()
        if food then
            surface.SetDrawColor(255, 0, 0, 255)
            surface.DrawRect(food.x * gridSize, food.y * gridSize, gridSize - 1, gridSize - 1)
        end
    end

   
    local function moveSnake()
        if not gameRunning then return end

        local head = table.Copy(snake[1])

        if snakeDirection == "UP" then
            head.y = head.y - 1
        elseif snakeDirection == "DOWN" then
            head.y = head.y + 1
        elseif snakeDirection == "LEFT" then
            head.x = head.x - 1
        elseif snakeDirection == "RIGHT" then
            head.x = head.x + 1
        end

        
        if head.x < 0 or head.x >= gridWidth or head.y < 0 or head.y >= gridHeight then
            gameRunning = false
        end

       
        for _, segment in ipairs(snake) do
            if segment.x == head.x and segment.y == head.y then
                gameRunning = false
            end
        end

       
        table.insert(snake, 1, head)


        if food and head.x == food.x and head.y == food.y then
            score = score + 1
            spawnFood()  
        else
            
            table.remove(snake)
        end
    end


    local function resetGame()
        snake = {{x = 10, y = 10}}
        snakeDirection = "RIGHT"
        score = 0
        gameRunning = true
        spawnFood()  
    end


    function snakePanel:Paint(w, h)
        surface.SetDrawColor(50, 50, 50, 255)
        surface.DrawRect(0, 0, w, h)

        if gameRunning then
            drawSnake()
            drawFood()
        else
            draw.SimpleText("Game Over! Press R to restart", "DermaDefault", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        draw.SimpleText("Score: " .. score, "DermaDefault", 10, 10, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end


    function frame:OnKeyCodePressed(key)
        if key == KEY_W and snakeDirection ~= "DOWN" then
            snakeDirection = "UP"
        elseif key == KEY_S and snakeDirection ~= "UP" then
            snakeDirection = "DOWN"
        elseif key == KEY_A and snakeDirection ~= "RIGHT" then
            snakeDirection = "LEFT"
        elseif key == KEY_D and snakeDirection ~= "LEFT" then
            snakeDirection = "RIGHT"
        elseif key == KEY_R then
            resetGame()
        end
    end


    timer.Create("SnakeGameTimer", 0.2, 0, function()
        if gameRunning then
            moveSnake()
        end
        snakePanel:InvalidateLayout(true)
    end)


    frame.OnClose = function()
        timer.Remove("SnakeGameTimer")
        snakeGameOpen = false  
        print("[Snake Game] Игра закрыта.")
    end


    resetGame()
end)

hook.Add("Player Spawn", "GuiltKnown",function(ply)
	if ply == LocalPlayer() then
		system.FlashWindow()
	end
end)
-- август когда норм таб меню
-- колл хуйню накодил
