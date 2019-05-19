local ClassicLFR_Options = LibStub("AceAddon-3.0"):GetAddon("ClassicLFR_Options")

local L = LibStub("AceLocale-3.0"):GetLocale("ClassicLFR")
local instance_tb = {}

function ClassicLFR_Options.generate_encounters_table(groupid)
	if groupid and groupid ~= 0 then
		local igp = instance_tb[groupid]
		if igp then
			return igp
		else
			local name = C_LFGList.GetActivityGroupInfo(groupid)
			local num = GetNumSavedInstances()
			local string_find = string.find
			for i=1,num do
				local instanceName, instanceID, _, instanceDifficulty, locked, _, instanceIDMostSig, isRaid, maxPlayers, difficultyName, maxBosses, _ = GetSavedInstanceInfo(i)
				if (string_find(name,instanceName) or string_find(instanceName,name)) then
					local encounters_tb = {}
					for j = 1, maxBosses do
						encounters_tb[j] = GetSavedInstanceEncounterInfo(i,j)
					end
					instance_tb[groupid] = encounters_tb
					return encounters_tb
				end
			end
		end
	end
end

local encounters_tb

ClassicLFR_Options.RegisterSimpleFilter("find",function(info,profile,mbnm)
	local rse = C_LFGList.GetSearchResultEncounterInfo(info.searchResultID)
	local encounters = profile.a.encounters
	local mct = 0
	if rse then
		for i=1,#rse do
			local gt = encounters[rse[i]]
			if gt then
				mct = mct + 1
			elseif gt == false then
				return 1
			end
		end
	end
	if mct < mbnm then
		return 1
	end
end,function(profile)
	local encounters = profile.a.encounters
	if encounters then
		local mbnm = 0
		for k,v in pairs(encounters) do
			if v then
				mbnm = mbnm + 1
			end
		end
		return mbnm
	end
end)

ClassicLFR_Options.RegisterSimpleFilter("find",function(info) return C_LFGList.GetSearchResultEncounterInfo(info.searchResultID) and 1 or 0 end,function(profile) return profile.a.new end)

ClassicLFR_Options.option_table.args.find.args.f.args.encounters =
{
	name = RAID_BOSSES,
	type = "group",
	args =
	{
		encounters =
		{
			order = 0,
			name = RAID_ENCOUNTERS,
			desc = L.find_f_encounters,
			type = "multiselect",
			width = "full",
			values = function()
				local a = ClassicLFR_Options.db.profile.a
				if not encounters_tb or not a.encounters then
					encounters_tb = ClassicLFR_Options.generate_encounters_table(a.group)
				end
				return encounters_tb
			end,
			tristate = true,
			get = function(info,val)
				local encounters = ClassicLFR_Options.db.profile.a.encounters
				if encounters == nil then
					return false
				end
				local v = encounters[encounters_tb[val]]
				if v then
					return true
				elseif v == false then
					return nil
				end
				return false
			end,
			set = function(info,key,val)
				local k = false
				if val then
					k = true
				elseif val == false then
					k = nil
				end
				local a = ClassicLFR_Options.db.profile.a
				if a.encounters == nil then
					a.encounters = {}
				end
				a.encounters[encounters_tb[key]] = k
			end
		},
		clearall = 
		{
			order = 2,
			name = REMOVE_WORLD_MARKERS,
			type = "execute",
			func = function()
				ClassicLFR_Options.db.profile.a.encounters = nil
			end,
		},
		new =
		{
			name = NEW,
			type = "toggle",
			get = function()
				return ClassicLFR_Options.db.profile.a.new
			end,
			set = function(_,val)
				if val then
					ClassicLFR_Options.db.profile.a.new = true
					ClassicLFR_Options.db.profile.a.encounters = nil
				else
					ClassicLFR_Options.db.profile.a.new = nil
				end
			end,
			width = "full",
			order = 3,
		},
	}
}
