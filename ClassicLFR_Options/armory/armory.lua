local ClassicLFR_Options = LibStub("AceAddon-3.0"):GetAddon("ClassicLFR_Options")

local function player_armory_name(playername)
	local name,realm = strsplit("-",playername)
	if realm == nil or realm == "" then
		realm = GetRealmName()
	end
	if GetCurrentRegion() < 4 then
		if realm ~= "AzjolNerub" then
			local sbyte = string.byte
			local i = 2
			local n = realm:len()
			while i<=n do
				local bt = sbyte(realm,i)
				if bt==39 or bt == 45 then
					realm = table.concat{realm:sub(1,i-1),realm:sub(i+1)}
					n = realm:len()
					if bt == 39 then
						i = i + 1
					end
				elseif (64<bt and bt<91) or (47<bt and bt <58) then
					realm = table.concat{realm:sub(1,i-1), '-', realm:sub(i)}
					break
				else
					i = i + 1
				end
			end
		end
	end
	return name,realm
end

local function region_name()
	local region = GetCurrentRegion()
	if region == 1 then
		return "us"
	elseif region == 2 then
		return "kr"
	elseif region == 3 then
		return "eu"
	elseif region == 4 then
		return "tw"
	elseif region == 5 then
		return "cn"
	end
end

ClassicLFR_Options.armory =
{
	["Battle.net"] = function(playername)
		local name,realm = player_armory_name(playername)
		local region = GetCurrentRegion()
		if region == 1 then
			return "https://worldofwarcraft.com/en-us/character/"..realm.."/"..name
		elseif region == 2 then
			return "https://worldofwarcraft.com/ko-kr/character/"..realm.."/"..name
		elseif region == 3 then
			return "https://worldofwarcraft.com/en-gb/character/"..realm.."/"..name
		elseif region == 4 then
			return "https://worldofwarcraft.com/zh-tw/character/"..realm.."/"..name
		elseif region == 5 then
			return "http://www.battlenet.com.cn/wow/zh/character/"..realm.."/"..name
		end
	end,
	[_G.ACHIEVEMENTS] = function(playername)
		local name,realm = player_armory_name(playername)
		local region = GetCurrentRegion()
		if region == 1 then
			return "https://worldofwarcraft.com/en-us/character/"..realm.."/"..name.."/achievements/feats-of-strength/raids"
		elseif region == 2 then
			return "https://worldofwarcraft.com/ko-kr/character/"..realm.."/"..name.."/achievements/feats-of-strength/raids"
		elseif region == 3 then
			return "https://worldofwarcraft.com/en-gb/character/"..realm.."/"..name.."/achievements/feats-of-strength/raids"
		elseif region == 4 then
			return "https://worldofwarcraft.com/zh-tw/character/"..realm.."/"..name.."/achievements/feats-of-strength/raids"
		elseif region == 5 then
			return "http://www.battlenet.com.cn/wow/zh/character/"..realm.."/"..name.."/achievements/feats-of-strength/raids"
		end
	end,
	WarcraftLogs = function(playername)
		local name,realm = player_armory_name(playername)
		local reg = region_name()
		if reg then
			return "https://www.warcraftlogs.com/character/"..reg.."/"..realm.."/"..name
		end
	end,	
	["Ask Mr. Robot"] = function(playername)
		local name,realm = player_armory_name(playername)
		local reg = region_name()
		if reg then
			return "https://www.askmrrobot.com/wow/gear/"..reg.."/"..realm.."/"..name
		end
	end,
	Guildox = function(playername)
		local name,realm = player_armory_name(playername)
		local reg = region_name()
		if reg then
			return "http://guildox.com/toon/"..reg.."/"..realm.."/"..name
		end
	end,
	WoWProgress = function(playername)
		local name,realm = player_armory_name(playername)
		local reg = region_name()
		if reg then
			return "https://www.wowprogress.com/character/"..reg.."/"..realm.."/"..name
		end
	end,
	["Raider.IO"] = function(playername)
		local name,realm = player_armory_name(playername)
		local reg = region_name()
		if reg then
			return "https://raider.io/characters/"..reg.."/"..realm.."/"..name
		end	
	end,
}
