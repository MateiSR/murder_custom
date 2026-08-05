util.AddNetworkString("Spawns_View")
util.AddNetworkString("Spawns_ViewChange")


if !TeamSpawns then
	TeamSpawns = {}
	TeamSpawns['spawns'] = {}
end

local FALLBACK_SPAWN_DISTANCE = 512 ^ 2
local LEARNED_SPAWN_DISTANCE = 384 ^ 2
local MAX_LEARNED_SPAWNS = 64
local MAX_NAV_SPAWNS = 128
local MapSpawnPositions = {}
local LearnedSpawnPositions = {}
local NavSpawnPositions = {}
local RoundSpawnPositions = {}

GM.DynamicSpawnFallback = CreateConVar("mu_spawn_dynamic_fallback", 1, bit.bor(FCVAR_NOTIFY),
	"Use map, traversed, and navmesh fallback positions when authored spawns are unavailable")

local function minimumSpawnDistance(pos, positions)
	local minimum = math.huge
	for k, other in ipairs(positions) do
		minimum = math.min(minimum, pos:DistToSqr(other))
	end
	return minimum
end

assert(minimumSpawnDistance(Vector(3, 4, 0), {Vector(0, 0, 0)}) == 25,
	"spawn distance calculation is invalid")

local function rememberPosition(positions, pos, minDistance, limit)
	if minimumSpawnDistance(pos, positions) < minDistance then return end
	if limit && #positions >= limit then table.remove(positions, 1) end
	table.insert(positions, Vector(pos.x, pos.y, pos.z))
end

local function isValid() return true end
local function getPos(self) return self.pos end

local function spawnEntity(pos)
	return {
		IsValid = isValid,
		GetPos = getPos,
		pos = pos
	}
end

local function validatedSpawnPosition(ply, pos)
	if !pos || !util.IsInWorld(pos + Vector(0, 0, 36)) then return end

	local ground = util.TraceLine({
		start = pos + Vector(0, 0, 8),
		endpos = pos - Vector(0, 0, 64),
		filter = player.GetAll(),
		mask = MASK_PLAYERSOLID
	})
	if !ground.Hit || ground.StartSolid || ground.HitNormal.z < 0.7 then return end

	pos = ground.HitPos + Vector(0, 0, 1)
	local contents = util.PointContents(pos + Vector(0, 0, 36))
	if bit.band(contents, bit.bor(CONTENTS_WATER, CONTENTS_SLIME)) != 0 then return end

	local mins, maxs = ply:GetHull()
	local clearance = util.TraceHull({
		start = pos,
		endpos = pos,
		mins = mins,
		maxs = maxs,
		filter = ply,
		mask = MASK_PLAYERSOLID
	})
	if clearance.Hit || clearance.StartSolid || clearance.AllSolid then return end
	if !GAMEMODE:IsSpawnpointSuitable(ply, spawnEntity(pos), false) then return end

	return pos
end

local function bestSpawnPosition(ply, positions)
	if #positions <= 0 then return end

	local best, bestDistance
	local first = math.random(#positions)
	for offset = 0, #positions - 1 do
		local pos = validatedSpawnPosition(ply, positions[(first + offset - 1) % #positions + 1])
		if pos then
			local distance = minimumSpawnDistance(pos, RoundSpawnPositions)
			if !bestDistance || distance > bestDistance then
				best = pos
				bestDistance = distance
			end
			// good enough: stop tracing the rest of the pool
			if distance >= FALLBACK_SPAWN_DISTANCE then break end
		end
	end
	return best, bestDistance
end

// last resort, matching the pre-fallback behaviour: take any position and clear whoever blocks it
local function forcedSpawnPosition(ply, positions)
	if #positions <= 0 then return end

	local pos = positions[math.random(#positions)]
	GAMEMODE:IsSpawnpointSuitable(ply, spawnEntity(pos), true)
	return pos
end

local function chooseFallbackSpawn(ply)
	local fallback, fallbackDistance
	local sources = {MapSpawnPositions, LearnedSpawnPositions, NavSpawnPositions}
	for k, positions in ipairs(sources) do
		local pos, distance = bestSpawnPosition(ply, positions)
		if pos && (#RoundSpawnPositions <= 0 || distance >= FALLBACK_SPAWN_DISTANCE) then return pos end
		if pos && (!fallbackDistance || distance > fallbackDistance) then
			fallback = pos
			fallbackDistance = distance
		end
	end
	return fallback
end

local function usableNavArea(area)
	return area:IsValid() && !area:IsUnderwater() && !area:IsDamaging() && !area:IsBlocked()
		&& !area:HasAttributes(NAV_MESH_CROUCH)
end

local function reachableNavAreas()
	local all = navmesh.GetAllNavAreas()
	if #MapSpawnPositions <= 0 then return all end

	local queue, reachable, seen = {}, {}, {}
	for k, pos in ipairs(MapSpawnPositions) do
		local area = navmesh.GetNearestNavArea(pos, false, 512, true, true)
		if area:IsValid() && !seen[area:GetID()] then
			seen[area:GetID()] = true
			table.insert(queue, area)
		end
	end

	local index = 1
	while queue[index] do
		local area = queue[index]
		index = index + 1
		if !area:IsBlocked() then
			table.insert(reachable, area)
			for k, nextArea in ipairs(area:GetAdjacentAreas()) do
				if !seen[nextArea:GetID()] then
					seen[nextArea:GetID()] = true
					table.insert(queue, nextArea)
				end
			end
		end
	end
	return reachable
end

function GM:PrepareFallbackSpawns()
	table.Empty(MapSpawnPositions)
	table.Empty(NavSpawnPositions)

	for k, ent in ipairs(ents.FindByClass("info_player_*")) do
		if IsValid(ent) then rememberPosition(MapSpawnPositions, ent:GetPos(), 1) end
	end

	if !navmesh.IsLoaded() then return end
	for k, area in RandomPairs(reachableNavAreas()) do
		if #NavSpawnPositions >= MAX_NAV_SPAWNS then break end
		if usableNavArea(area) then
			rememberPosition(NavSpawnPositions, area:GetRandomPoint(), LEARNED_SPAWN_DISTANCE, MAX_NAV_SPAWNS)
		end
	end
end

function GM:GetNavFallbackPositions()
	return NavSpawnPositions
end

function GM:ResetRoundSpawns()
	table.Empty(RoundSpawnPositions)
end

function GM:PlayerSelectTeamSpawn(TeamID, ply)
	local authored = TeamSpawns["spawns"] or {}
	local pos
	if #authored > 0 then
		pos = bestSpawnPosition(ply, authored) || forcedSpawnPosition(ply, authored)
	elseif self.DynamicSpawnFallback:GetBool() then
		pos = chooseFallbackSpawn(ply) || forcedSpawnPosition(ply, MapSpawnPositions)
	end
	if !pos then return end

	table.insert(RoundSpawnPositions, pos)
	return spawnEntity(pos)
end

hook.Add("PlayerFootstep", "MurderRememberSpawn", function(ply)
	if !GAMEMODE.DynamicSpawnFallback:GetBool() || #(TeamSpawns["spawns"] or {}) > 0
		|| GAMEMODE:GetRound() != GAMEMODE.Round.Playing || !ply:Alive() || ply.Frozen
		|| !ply:IsOnGround() || ply:WaterLevel() >= 2 then return end
	if ply.NextSpawnSample && ply.NextSpawnSample > CurTime() then return end

	ply.NextSpawnSample = CurTime() + 2
	rememberPosition(LearnedSpawnPositions, ply:GetPos(), LEARNED_SPAWN_DISTANCE, MAX_LEARNED_SPAWNS)
end)

local function networkList(spawns)
	for k, v in pairs(spawns) do
		net.WriteUInt(k, 32)
		net.WriteVector(v)
	end
	net.WriteUInt(0, 32)
end

local function networkChange(listName)
	local spawns = TeamSpawns[listName]
	if !spawns then return end
	for k, ply in pairs(player.GetAll()) do
		if ply.SpawnsVisualise == listName then
			net.Start("Spawns_ViewChange")
			networkList(spawns)
			net.Send(ply)
		end
	end
end

function GM:LoadSpawns() 
	for listName, spawnList in pairs(TeamSpawns) do
		local jason = file.ReadDataAndContent("murder/" .. game.GetMap() .. "/spawns/" .. listName .. ".txt")
		if jason then
			local tbl = util.JSONToList(jason)
			if istable(tbl) then
				TeamSpawns[listName] = tbl
				networkChange(listName)
			end
		end
	end
end

function GM:SaveSpawns()

	// ensure the folders are there
	if !file.Exists("murder/","DATA") then
		file.CreateDir("murder")
	end

	local mapName = game.GetMap()
	if !file.Exists("murder/" .. mapName .. "/","DATA") then
		file.CreateDir("murder/" .. mapName)
	end

	if !file.Exists("murder/" .. mapName .. "/spawns/","DATA") then
		file.CreateDir("murder/" .. mapName .. "/spawns")
	end

	// JSON!
	for listName, spawnList in pairs(TeamSpawns) do
		local jason = util.TableToJSON(spawnList)
		file.Write("murder/" .. mapName .. "/spawns/" .. listName .. ".txt", jason)
	end
end

local function getPosPrintString(pos, plyPos) 
	return math.Round(pos.x) .. "," .. math.Round(pos.y) .. "," .. math.Round(pos.z) .. " " .. math.Round(pos:Distance(plyPos) / 12) .. "ft"
end

concommand.Add("mu_spawn_counts", function (ply, com, args, full)
	if (!ply:IsAdmin()) then return end

	for k, v in pairs(TeamSpawns) do
		ply:ChatPrint("Spawns: " .. k .. " count " .. table.Count(v))
	end
end)

concommand.Add("mu_spawn_add", function (ply, com, args, full)
	if (!ply:IsAdmin()) then return end

	if #args < 1 then
		ply:ChatPrint("Too few args (spawnList)")
		return
	end

	local spawnList = TeamSpawns[args[1]]
	if !spawnList then
		ply:ChatPrint("Invalid list")
		return
	end

	table.insert(spawnList, ply:GetPos())

	ply:ChatPrint("Added " .. #spawnList .. ": " .. getPosPrintString(ply:GetPos(), ply:GetPos()) )

	GAMEMODE:SaveSpawns()
	networkChange(args[1])
end)

concommand.Add("mu_spawn_list", function (ply, com, args, full)
	if (!ply:IsAdmin()) then return end

	if #args < 1 then
		ply:ChatPrint("Too few args (spawnList)")
		return
	end

	local spawnList = TeamSpawns[args[1]]
	if !spawnList then
		ply:ChatPrint("Invalid list")
		return
	end

	ply:ChatPrint("SpawnList " ..  args[1])
	for k, pos in pairs(spawnList) do
		ply:ChatPrint(k .. ": " .. getPosPrintString(pos,ply:GetPos()) )
	end
end)

concommand.Add("mu_spawn_closest", function (ply, com, args, full)
	if (!ply:IsAdmin()) then return end

	if #args < 1 then
		ply:ChatPrint("Too few args (spawnList)")
		return
	end

	local spawnList = TeamSpawns[args[1]]
	if !spawnList then
		ply:ChatPrint("Invalid list")
		return
	end

	if #spawnList <= 0 then
		ply:ChatPrint("List is empty")
		return
	end

	local closest
	for k, pos in pairs(spawnList) do
		if !closest || (spawnList[closest]:Distance(ply:GetPos()) > pos:Distance(ply:GetPos())) then
			closest = k
		end
	end
	if !closest then
		ply:ChatPrint("No closest spawn")
		return
	end

	ply:ChatPrint(closest .. ": " .. getPosPrintString(spawnList[closest],ply:GetPos()) )
end)

concommand.Add("mu_spawn_remove", function (ply, com, args, full)
	if (!ply:IsAdmin()) then return end

	if #args < 2 then
		ply:ChatPrint("Too few args (spawnList, key)")
		return
	end

	local spawnList = TeamSpawns[args[1]]
	if !spawnList then
		ply:ChatPrint("Invalid list")
		return
	end

	local key = tonumber(args[2]) or 0
	if args[2] == "closest" then
		local closest
		for k, pos in pairs(spawnList) do
			if !closest || (spawnList[closest]:Distance(ply:GetPos()) > pos:Distance(ply:GetPos())) then
				closest = k
			end
		end
		if !closest then
			ply:ChatPrint("No closest spawn")
			return
		end
		key = closest
	end

	if !spawnList[key] then
		ply:ChatPrint("Invalid key, position inexists")
		return
	end

	local pos = spawnList[key]
	table.remove(spawnList, key)
	ply:ChatPrint("Remove " .. key .. ": " .. getPosPrintString(pos, ply:GetPos()) )

	GAMEMODE:SaveSpawns()
	networkChange(args[1])
end)

concommand.Add("mu_spawn_visualise", function (ply, com, args, full)
	if (!ply:IsAdmin()) then return end

	if #args < 1 then
		ply:ChatPrint("Too few args (spawnList)")
		return
	end

	local spawnList = TeamSpawns[args[1]]
	if !spawnList then
		ply:ChatPrint("Invalid list")
		return
	end

	if ply.SpawnsVisualise && ply.SpawnsVisualise == args[1] then
		net.Start("Spawns_View")
		net.WriteUInt(0, 8)
		net.Send(ply)
		ply:ChatPrint("Stopped visualising spawns: " .. args[1])
		ply.SpawnsVisualise = nil
		return
	end

	ply.SpawnsVisualise = args[1]

	net.Start("Spawns_View")
	net.WriteUInt(1, 8)
	net.WriteString(ply.SpawnsVisualise)
	networkList(spawnList)
	net.Send(ply)
	ply:ChatPrint("Visualising spawns: " .. args[1])
end)
