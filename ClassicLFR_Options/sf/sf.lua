local AceAddon = LibStub("AceAddon-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local ClassicLFR = AceAddon:GetAddon("ClassicLFR")
local ClassicLFR_Options = AceAddon:GetAddon("ClassicLFR_Options")
local L = LibStub("AceLocale-3.0"):GetLocale("ClassicLFR")
local order = 0
local function get_order()
	local temp = order
	order = order +1
	return temp
end

local get_function_negative = ClassicLFR_Options.get_function_negative
local set_function_negative = ClassicLFR_Options.set_function_negative
local options_get_function_negative = ClassicLFR_Options.options_get_function_negative
local options_set_function_negative = ClassicLFR_Options.options_set_function_negative

local select_tb = {}

ClassicLFR_Options:push("sf",{
	name = SPAM_FILTER,
	type = "group",
	args =
	{
		mlength = 
		{
			name = L["Maximum Text Length"],
			desc = L.max_length_desc,
			type = "input",
			order = get_order(),
			set = function(_,val)
				if val == "" then
					ClassicLFR.db.profile.spam_filter_maxlength = false
				else
					ClassicLFR.db.profile.spam_filter_maxlength = tonumber(val)
				end
			end,
			get = function()
				local ml = ClassicLFR.db.profile.spam_filter_maxlength
				if ml and 0 <= ml then
					return tostring(ml)
				end
			end,
			pattern = "^[0-9]*$",
			width = "full",
		},
		digits =
		{
			order = get_order(),
			name = "%d+",
			desc = L.digits_desc,
			type = "input",
			get = function(info)
				local d = ClassicLFR.db.profile.spam_filter_digits
				if d then
					return tostring(d)
				end
			end,
			pattern = "^[0-9]*$",
			set = function(info,val)
				if val == "" then
					if GetCurrentRegion() == 5 then
						ClassicLFR.db.profile.spam_filter_digits = false
					else
						ClassicLFR.db.profile.spam_filter_digits = nil
					end
				else
					ClassicLFR.db.profile.spam_filter_digits = tonumber(val)
				end
			end,
			width = "full"
		},
		hyperlinks =
		{
			order = get_order(),
			name = "|c[^%[]+%[([^%]]+)%]|h|r",
			desc = L.hyperlinks_desc,
			type = "input",
			get = function(info)
				local d = ClassicLFR.db.profile.spam_filter_hyperlinks
				if d then
					return tostring(d)
				end
			end,
			pattern = "^[0-9]*$",
			set = function(info,val)
				if val == "" then
					if GetCurrentRegion() == 5 then
						ClassicLFR.db.profile.spam_filter_hyperlinks = false
					else
						ClassicLFR.db.profile.spam_filter_hyperlinks = nil
					end
				else
					ClassicLFR.db.profile.spam_filter_hyperlinks = tonumber(val)
				end
			end,
			width = "full"
		},
		add =
		{
			name = ADD,
			desc = L.sf_add_desc,
			type = "input",
			order = get_order(),
			set = function(_,val)
				local tb = ClassicLFR.db.profile.spam_filter_keywords
				if tb == nil then
					tb = {}
				end
				local lower = string.lower
				local gsub = string.gsub
				tb[#tb+1] = lower(gsub(val," ",""))
				table.sort(tb)
				ClassicLFR.db.profile.spam_filter_keywords = tb
			end,
			get = nop,
			width = "full"
		},
		auto_whisper =
		{
			name = WHISPER,
			type = "input",
			get = function(info)
				return ClassicLFR.db.profile.sf_whisper
			end,
			set = function(info,v)
				if v:len() == 0 then
					ClassicLFR.db.profile.sf_whisper = nil
				else
					ClassicLFR.db.profile.sf_whisper = v					
				end
			end,
			width = "full"
		},
		rmv =
		{
			name = REMOVE,
			type = "execute",
			order = get_order(),
			func = function()
				local profile = ClassicLFR.db.profile
				local spkt = profile.spam_filter_keywords
				local cp = {}
				if spkt then
					for i = 1,#spkt do
						if select_tb[i]~=true then
							cp[#cp+1] = spkt[i]
						end
					end
				end
				wipe(select_tb)
				profile.spam_filter_keywords = cp
			end
		},
		reset =
		{
			name = RESET,
			type = "execute",
			order = get_order(),
			func = function() wipe(select_tb) end
		},
		filters_s =
		{
			name = function()
				local kws = ClassicLFR.db.profile.spam_filter_keywords
				if kws == nil or #kws == 0 then
					return FILTERS
				else
					return tostring(#kws)
				end
			end,
			type = "multiselect",
			order = get_order(),
			values = function() return ClassicLFR.db.profile.spam_filter_keywords end,
			set = function(_,key,val)
				if val then
					select_tb[key] = true
				else
					select_tb[key] = nil
				end
			end,
			get = function(_,key)
				return select_tb[key]
			end,
			width = "full",
		},
		cpft =
		{
			order = get_order(),
			name = COPY_FILTER,
			type = "execute",
			func = function()
				ClassicLFR_Options.paste(ClassicLFR.db.profile,"spam_filter_keywords",true,"sf")
			end
		},
		language =
		{
			name = LANGUAGE,
			desc = L.language_sf_desc,
			type = "group",
			args =
			{
				enable =
				{
					name = ENABLE,
					desc = format(L.bwlist_desc,LANGUAGE,LANGUAGE,DISABLE),
					type = "toggle",
					order = get_order(),
					set = function(_,val)
						if val then
							ClassicLFR.db.profile.spam_filter_language = true
						elseif val == false then
							ClassicLFR.db.profile.spam_filter_language = nil
						else
							ClassicLFR.db.profile.spam_filter_language = false
						end
					end,
					get = function()
						local lg = ClassicLFR.db.profile.spam_filter_language
						if lg then
							return true
						elseif lg == false then
							return
						else
							return false
						end
					end,
					width = "full",
					tristate = true
				},
				language_english =
				{
					name = LFG_LIST_LANGUAGE_ENUS,
					type = "toggle",
					set = ClassicLFR_Options.set_function,
					get =ClassicLFR_Options.get_function,
				},
				language_chinese =
				{
					name = LFG_LIST_LANGUAGE_ZHCN,
					type = "toggle",
					set = ClassicLFR_Options.set_function,
					get =ClassicLFR_Options.get_function,
				},
				language_korean =
				{
					name = LFG_LIST_LANGUAGE_KOKR,
					type = "toggle",
					set = ClassicLFR_Options.set_function,
					get =ClassicLFR_Options.get_function,
				},
				language_russian =
				{
					name = LFG_LIST_LANGUAGE_RURU,
					type = "toggle",
					set = ClassicLFR_Options.set_function,
					get =ClassicLFR_Options.get_function,
				}
			}
		},
		addons =
		IsAddOnLoaded("ClassicLFR_SF") and
		{
			name = ADDONS,
			type = "group",
			args =
			{
				add =
				{
					name = ADD,
					type = "input",
					order = get_order(),
					set = function(_,val)
						if val:len() == 0 then
							return
						end
						local tb = ClassicLFR.db.profile.addon_filters
						if tb == nil then
							tb = {}
						end
						tb[#tb+1] = val
						table.sort(tb)
						ClassicLFR.db.profile.addon_filters = tb
					end,
					get = nop,
					width = "full"
				},
				rmv =
				{
					name = REMOVE,
					type = "execute",
					order = get_order(),
					func = function()
						local profile = ClassicLFR.db.profile
						local spkt = profile.addon_filters
						local cp = {}
						for i = 1,#spkt do
							if select_tb[i]~=true then
								cp[#cp+1] = spkt[i]
							end
						end
						wipe(select_tb)
						if #cp ~= 0 then
							profile.addon_filters = cp
						end
					end
				},
				reset =
				{
					name = RESET,
					type = "execute",
					order = get_order(),
					func = function() wipe(select_tb) end
				},
				defaults =
				{
					name = DEFAULTS,
					type = "execute",
					order = get_order(),
					confirm = true,
					func = function()
						local db = ClassicLFR.db
						local profile = db.profile
						local default = db.defaults.profile.addon_filters
						local tb = {}
						for i=1,#default do
							tb[i] = default[i]
						end
						ClassicLFR.db.profile.addon_filters = tb
					end
				},
				whisper =
				{
					name = WHISPER,
					desc = L.sf_whisper_desc,
					type = "toggle",
					order = get_order(),
					set = function(_,v)
						if v then
							ClassicLFR.db.profile.addon_ft_whisper = v
						else
							ClassicLFR.db.profile.addon_ft_whisper = nil
						end
					end,
					get = function()
						return ClassicLFR.db.profile.addon_ft_whisper
					end
				},
				filters_s =
				{
					name = FILTERS,
					type = "multiselect",
					order = get_order(),
					values = function() return ClassicLFR.db.profile.addon_filters end,
					set = function(_,key,val)
						if val then
							select_tb[key] = true
						else
							select_tb[key] = nil
						end
					end,
					get = function(_,key)
						return select_tb[key]
					end,
					width = "full",
				},
				cpft =
				{
					order = get_order(),
					name = COPY_FILTER,
					type = "execute",
					func = function()
						ClassicLFR_Options.paste(ClassicLFR.db.profile,"addon_filters",false,"sf","addons")
					end
				}
			}
		} or nil,
		channel =
		{
			name = CHANNEL,
			type = "group",
			args =
			{
				spam_filter_slash =
				{
					name = "/",
					type = "toggle",
					set = set_function_negative,
					get = get_function_negative,
				},
				spam_filter_community =
				{
					name = COMMUNITIES_CREATE_DIALOG_NAME_LABEL,
					type = "toggle",
					get = get_function_negative,
					set = set_function_negative
				},
				spam_filter_spaces =
				{
					name = "[Space]",
					type = "toggle",
					get = get_function_negative,
					set = set_function_negative,
				},
				spam_filter_emote_xp =
				{
					name = EMOTE.." "..XP,
					type = "toggle",
					set = set_function_negative,
					get = get_function_negative
				},
				spam_filter_achievements =
				{
					name = ACHIEVEMENTS,
					type = "toggle",
					get = get_function_negative,
					set = set_function_negative
				},
				spam_filter_quest =
				{
					name = BATTLE_PET_SOURCE_2,
					type = "toggle",
					get = get_function_negative,
					set = set_function_negative
				},
				spam_filter_fast =
				{
					name = L.Fast,
					type = "toggle",
					get = get_function_negative,
					set = set_function_negative
				},
				spam_filter_unknown =
				{
					name = UNKNOWN,
					type = "toggle",
					set = ClassicLFR_Options.set_function,
					get = ClassicLFR_Options.get_function
				},
				spam_filter_instance =
				{
					name = INSTANCE,
					type = "toggle",
					get = get_function_negative,
					set = set_function_negative
				},
				reset =
				{
					name = RESET,
					type = "execute",
					order = -1,
					func = function()
						local db = ClassicLFR.db
						local t = {}
						for k,v in pairs(db.profile) do
							if not k:find("^spam_filter_") then
								t[k] = v
							end
						end
						db.profile = t
					end,
					width = "full"
				}
			}
		},
--[[		levenshtein =
		{
			name = L["Levenshtein Distance"],
			desc = L.levenshtein_desc,
			type = "group",
			args =
			{
				enable =
				{
					name = ENABLE,
					desc = L.enable_levenshtein_desc,
					type = "toggle",
					get = function(info)
						return ClassicLFR_Options.db.profile.spam_filter_levenshtein
					end,
					set = function(info,val)
						if val then
							ClassicLFR_Options.db.profile.spam_filter_levenshtein = true
						else
							ClassicLFR_Options.db.profile.spam_filter_levenshtein = nil
						end
					end
				},
				factor =
				{
					name = "α",
					type = "range",
					get = function(info)
						local factor = ClassicLFR_Options.db.profile.spam_filter_levenshtein_factor
						if factor then
							return factor
						else
							return 0.1
						end
					end,
					set = function(info,val)
						if val == 0.1 then
							ClassicLFR_Options.db.profile.spam_filter_levenshtein_factor = nil
						else
							ClassicLFR_Options.db.profile.spam_filter_levenshtein_factor = val
						end
					end,
					min = 0,
					max = 1,
					isPercent = true,
				},
				groups =
				{
					name = "n",
					desc = GROUPS,
					type = "range",
					get = function(info)
						local factor = ClassicLFR_Options.db.profile.spam_filter_levenshtein_groups
						if factor then
							return factor
						else
							return 2
						end
					end,
					set = function(info,val)
						if val == 2 then
							ClassicLFR_Options.db.profile.spam_filter_levenshtein_groups = nil
						else
							ClassicLFR_Options.db.profile.spam_filter_levenshtein_groups = val
						end
					end,
					min = 0,
					max = 100,
					step = 1,
				}
			}
		},]]
		invite =
		{
			name = INVITE,
			type = "group",
			args =
			{
				sf_invite_relationship =
				{
					name = FRIEND,
					desc = L.sf_invite_relationship_desc,
					get = options_get_function_negative,
					set = options_set_function_negative,
					type = "toggle"
				}
			}
		},
		advanced =
		{
			name = ADVANCED_LABEL,
			type = "group",
			order = -1,
			args =
			{
				spam_filter_dk = 
				{
					name = GetClassInfo(6),
					desc = L.sf_dk_desc,
					type = "toggle",
					set = options_set_function_negative,
					get = options_get_function_negative
				},
				spam_filter_solo = 
				{
					name = SOLO,
					desc = L.sf_solo,
					type = "toggle",
					set = options_set_function_negative,
					get = options_get_function_negative
				},
				spam_filter_auto_report =
				{
					name = L.auto_report,
					desc = L.auto_report_desc,
					type = "toggle",
					get = options_get_function_negative,
					set = options_set_function_negative
				},
				spam_filter_ignoreall =
				{
					name = ALL,
					desc = IGNORE,
					type = "toggle",
					get = function(info)
						return ClassicLFR_Options.spam_filter_ignore_all
					end,
					set = function(info,val)
						ClassicLFR_Options.spam_filter_ignore_all = val or nil
						ClassicLFR:SendMessage("LFG_CORE_FINALIZER",0)
					end
				},
				spam_filter_player_name =
				{
					name = CALENDAR_PLAYER_NAME,
					desc = L.sf_player_name_desc,
					type = "toggle",
					get = options_get_function_negative,
					set = options_set_function_negative
				},
				spam_filter_ilvl =
				{
					name = ITEM_LEVEL_ABBR,
					desc = L.sf_ilvl,
					type = "toggle",
					get = options_get_function_negative,
					set = options_set_function_negative
				},
				spam_filter_activity =
				{
					name = LFG_LIST_ACTIVITY,
					type = "toggle",
					get = options_get_function_negative,
					set = options_set_function_negative
				},
				spam_filter_equal =
				{
					name = "=",
					type = "toggle",
					get = ClassicLFR_Options.options_get_function,
					set =ClassicLFR_Options.options_set_function
				}
			}
		}
	}
})

ClassicLFR_Options.RegisterSimpleFilter("spam",function(info)
	if info == nil or info.isDelisted then
		return 1
	end
	local _, appStatus = C_LFGList.GetApplicationInfo(info.searchResultID)
	if appStatus ~= "none" then
		return 1
	end
end)

ClassicLFR_Options.RegisterSimpleFilter("spam",function(info,profile,temp)
	local id, numMembers = info.searchResultID,info.numMembers
	local dk = 0
	local C_LFGList_GetSearchResultMemberInfo = C_LFGList.GetSearchResultMemberInfo
	wipe(temp)
	for i=1,numMembers do
		local role, class, class_localized = C_LFGList_GetSearchResultMemberInfo(id,i)
		local t = (temp[class] or 0)+1
		temp[class] = t
		if dk < t then
			dk = t
		end
	end
	local classnum = 0
	for k,v in pairs(temp) do
		classnum = classnum + 1
	end
	if 10 < dk and classnum < 10 then
		return 8
	end
end,function(profile)
	return not profile.spam_filter_dk and {} or nil
end)

ClassicLFR_Options.RegisterSimpleFilter("find",function(info)
	if info.numMembers == 4 and 2400 < info.age then
		local fullName, shortName, categoryID = C_LFGList.GetActivityInfo(info.activityID)
		if categoryID == 2 then
			local tb = C_LFGList.GetSearchResultMemberCounts(info.searchResultID)
			if tb.TANK == 1 and tb.HEALER == 1 then
				return 8
			end
		end
	end
end,function(profile)
	return not profile.spam_filter_fast
end)

local function issubstr(s,substr)
	local sbyte = string.byte
	local i = 1
	local slen = s:len()
	local substr_len = substr:len()
	local j = 1
	while i <= slen and j <= substr_len do
		if sbyte(s,i) == sbyte(substr,j) then
			j = j + 1
		else
			j = 1
		end
		i = i + 1
	end
	if substr_len < j then
		return true
	end
end

ClassicLFR_Options.RegisterSimpleFilter("find",function(info,profile)
	local activityID = info.activityID
	local fullName, shortName, categoryID, groupID, itemLevel, filters, minLevel, maxPlayers, displayType, activityOrder = C_LFGList.GetActivityInfo(activityID)
	local fsname = fullName or shortName
	local a = profile.a
	if a.activity then
		if a.activity == activityID then
			return 0
		end
	elseif a.group then
		if a.group == groupID then
			return 0
		end
	end
	local activities = profile.a.activities
	if activities and next(activities) then
		for i=1,#activities do
			local ctv = activities[i]
			if issubstr(fsname,ctv) then
				return 0
			end
		end
	else
		if a.activity == nil and a.group == nil then
			return 0
		end
	end
	return 8
end)

ClassicLFR_Options.RegisterSimpleFilter("spam",function(info)
	if 10000 < info.age and 0 < info.comment:len() and info.name == info.comment then
		return 8
	end
end,function(profile)
	return profile.spam_filter_equal
end)

ClassicLFR_Options.RegisterFilter("spam",function(infos,bts,first,profile)
	if not profile.spam_filter_equal then
		return
	end
	local hash = {}
	local categoryID
	for i=1,#infos do
		local info = infos[i]
		repeat
		if not info then
			break
		end
		if not categoryID then
			categoryID = select(3,C_LFGList.GetActivityInfo(info.activityID))
			if categoryID == 1 then
				return
			end
		end
		if info.questID then
			break
		end
		local v = info.name..info.comment
		local t = hash[v]
		if t == nil then
			t = {}
			hash[v] = t
		end
		t[#t+1] = i
		until true
	end
	local limits = 2
	local slen = string.len
	local bor = bit.bor
	for k,v in pairs(hash) do
		local lm = limits
		if slen(k) == 8 then
			lm = lm * 4
		end
		if lm < #v then
			for i=1,#v do
				local e=v[i]
				bts[e] = bor(bts[e],8)
			end
		end
	end
end)

ClassicLFR_Options.RegisterSimpleFilter("spam",function(info)
	local numMembers = info.numMembers
	if numMembers < 2 then
		local fullName, shortName, categoryID = C_LFGList.GetActivityInfo(info.activityID)
		local age = info.age
		if numMembers == 1 then
			if categoryID == 1 then
				if 3600 < age then
					return 8
				end
			elseif 1200 < age then		-- report all groups above 1200 seconds
				return 8
			elseif 300 < age then
				return 1
			else
				if categoryID == 3 or categoryID == 9 then
					if 120 < age then
						return 1
					end
				end
			end
		elseif numMembers == 2 then
			if categoryID == 3 or categoryID == 9 then
				if 300 < age then
					return 1
				elseif 1800 < age then
					return 8
				end
			end
		end
	elseif 36000 < info.age then
		return 8
	end
end,function(profile)
	return not profile.spam_filter_solo
end)

ClassicLFR_Options.RegisterSimpleFilterExpensive("spam",function(info,profile,sf_kw)
	local leaderName = info.leaderName:lower()
	for i=1,#sf_kw do
		if issubstr(leaderName,sf_kw[i]) then
			return 8
		end
	end
end,function()
	local lfg_profile = ClassicLFR.db.profile
	return lfg_profile.spam_filter_player_name and lfg_profile.spam_filter_keywords
end)

ClassicLFR_Options.RegisterSimpleFilter("spam",function(info,profile)
	local fullName, shortName, categoryID, groupID, itemLevel, filters, minLevel, maxPlayers, displayType, activityOrder = C_LFGList.GetActivityInfo(info.activityID)
	local iLvl = info.requiredItemLevel
	if iLvl~=0 and iLvl < itemLevel then
		return 8
	end
end,function(profile)
	return not profile.spam_filter_ilvl
end)

ClassicLFR_Options.RegisterSimpleFilterExpensive("spam",function()
	return 32
end,
function()
	return ClassicLFR_Options.spam_filter_ignore_all and LFGListFrame.SearchPanel.SearchBox:GetText():len()~=0
end)

ClassicLFR_Options.RegisterSimpleFilter("spam",function(info)
	local fullName, shortName, categoryID, groupID = C_LFGList.GetActivityInfo(info.activityID)
	if groupID == 136 then
		return 8
	end
end,
function(profile)
	return not profile.spam_filter_activity and profile.a.group ~= 136
end)
