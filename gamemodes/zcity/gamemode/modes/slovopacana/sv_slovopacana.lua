MODE.name = "slovopacana"
MODE.PrintName = "Слово пацана"

MODE.OverideSpawnPos = true
MODE.LootSpawn = false
MODE.GuiltDisabled = true
MODE.ForBigMaps = false
MODE.Chance = 0.03
MODE.ROUND_TIME = 240
MODE.start_time = 8
MODE.end_time = 6

util.AddNetworkString("slovopacana_roundend")

local teams = {
    [0] = {
        role = "Чайники",
        color = Color(210, 120, 40)
    },
    [1] = {
        role = "Братва",
        color = Color(40, 130, 220)
    }
}

local meleePool = {
    "weapon_hg_shovel",
    "weapon_batmetal",
    "weapon_hg_tonfa",
    "weapon_hg_crowbar",
    "weapon_hg_machete",
    "weapon_hg_axe",
    "weapon_hg_sledgehammer",
    "weapon_hammer",
    "weapon_pan",
    "weapon_pocketknife",
    "weapon_sogknife",
    "weapon_leadpipe",
    "weapon_buck200knife"
}

local fallbackPool = {
    "weapon_bat",
    "weapon_hg_shovel",
    "weapon_pocketknife"
}

local function GiveOneMelee(ply)
    local class = meleePool[math.random(#meleePool)]
    local wep = ply:Give(class)
    if IsValid(wep) then
        return wep:GetClass()
    end

    if class == "weapon_batmetal" then
        local bat = ply:Give("weapon_bat")
        if IsValid(bat) then
            return bat:GetClass()
        end
    end

    for _, fallback in ipairs(fallbackPool) do
        local fallbackWep = ply:Give(fallback)
        if IsValid(fallbackWep) then
            return fallbackWep:GetClass()
        end
    end

    return nil
end

local function AliveTeam(teamId)
    local out = {}

    for _, ply in ipairs(team.GetPlayers(teamId)) do
        if ply:Alive() and not (ply.organism and ply.organism.incapacitated) then
            out[#out + 1] = ply
        end
    end

    return out
end

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
    return 1, true
end

function MODE:CanLaunch()
    local activePlayers = 0

    for _, ply in player.Iterator() do
        if ply:Team() ~= TEAM_SPECTATOR then
            activePlayers = activePlayers + 1
        end
    end

    return activePlayers >= 2
end

function MODE:Intermission()
    game.CleanUpMap()

    local active = {}
    for _, ply in player.Iterator() do
        if ply:Team() ~= TEAM_SPECTATOR then
            active[#active + 1] = ply
        end
    end

    table.Shuffle(active)

    local split = math.ceil(#active / 2)

    for i, ply in ipairs(active) do
        local teamId = (i <= split) and 0 or 1
        local teamData = teams[teamId]

        ply:SetupTeam(teamId)
        ply:SetPlayerClass("terrorist")
        zb.GiveRole(ply, teamData.role, teamData.color)
    end
end

function MODE:CheckAlivePlayers()
    return {AliveTeam(0), AliveTeam(1)}
end

function MODE:ShouldRoundEnd()
    local shouldEnd = zb:CheckWinner(self:CheckAlivePlayers())
    return shouldEnd
end

function MODE:RoundStart()
end

function MODE:RoundThink()
end

function MODE:EndRound()
    timer.Simple(0.1, function()
        net.Start("slovopacana_roundend")
        net.Broadcast()
    end)
end

function MODE:GiveEquipment()
    for _, ply in player.Iterator() do
        if ply:Team() == TEAM_SPECTATOR or not ply:Alive() then continue end

        local teamData = teams[ply:Team()] or teams[0]

        ply:StripWeapons()
        ply:StripAmmo()
        zb.GiveRole(ply, teamData.role, teamData.color)

        local hands = ply:Give("weapon_hands_sh")
        if not IsValid(hands) then
            hands = ply:Give("weapon_hands")
        end

        local selected = GiveOneMelee(ply)
        if selected then
            ply:SelectWeapon(selected)
        elseif IsValid(hands) then
            ply:SelectWeapon(hands:GetClass())
        end
    end
end

function MODE:GetTeamSpawn()
    local team0 = zb.TranslatePointsToVectors(zb.GetMapPoints("SLOVOPACANA_TEAM0"))
    local team1 = zb.TranslatePointsToVectors(zb.GetMapPoints("SLOVOPACANA_TEAM1"))

    if #team0 == 0 then
        team0 = zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_T"))
    end

    if #team1 == 0 then
        team1 = zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_CT"))
    end

    return team0, team1
end

function MODE:CanSpawn()
    return false
end

return MODE

