local AceAddon = LibStub("AceAddon-3.0")
local ClassicLFR = AceAddon:GetAddon("ClassicLFR")
local ClassicLFR_Options = AceAddon:GetAddon("ClassicLFR_Options")
local L = LibStub("AceLocale-3.0"):GetLocale("ClassicLFR")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local order = 0
local function get_order()
	local temp = order
	order = order + 1
	return temp
end

local function get_filters()
	local recommended = ClassicLFR_Options.db.profile.recommended
	if recommended then
		return LE_LFG_LIST_FILTER_NOT_RECOMMENDED
	elseif recommended == false then
		return
	else
		return LE_LFG_LIST_FILTER_RECOMMENDED
	end
end

function ClassicLFR_Options.find_search()
	local db = ClassicLFR_Options.db
	local a = db.profile.a
	local category = a.category
	if category then
		coroutine.wrap(function()
			ClassicLFR_Options.Search("lfg_opt_sr_default_multiselect",
			nil,
			ClassicLFR_Options.find_search,
			{"spam","find"},
			category,nil,get_filters(),0)
		end)()
	else
		pcall(ClassicLFR_Options.expected,format(L.must_select_xxx,CATEGORY,SEARCH))
		AceConfigDialog:SelectGroup("ClassicLFR","find")
	end
end

function ClassicLFR_Options.update_editing()
	local profile = ClassicLFR_Options.db.profile
	local s = profile.s
	wipe(s)
	if C_LFGList.HasActiveEntryInfo() then
		C_LFGList.CopyActiveEntryInfoToCreationFields()
		local info = C_LFGList.GetActiveEntryInfo()
		local iLevel = info.requiredItemLevel
		if iLevel == 0 then
			s.minimum_item_level=nil
		else
			s.minimum_item_level=iLevel
		end
		local honorLevel = info.requiredHonorLevel
		if honorLevel == 0 then
			s.minimum_honor_level = nil
		else
			s.minimum_honor_level = honorLevel
		end
		s.quest_id = info.questID
		s.auto_accept,s.private = info.autoAccept or nil, info.privateGroup or nil
		local fullName, shortName, categoryID, groupID, itemLevel, filters, minLevel, maxPlayers, displayType, activityOrder = C_LFGList.GetActivityInfo(info.activityID)
		if bit.band(filters,LE_LFG_LIST_FILTER_RECOMMENDED) == 1 then
			profile.recommended = nil
		elseif bit.band(filters,LE_LFG_LIST_FILTER_NOT_RECOMMENDED) == 1 then
			profile.recommended = false
		else
			profile.recommended = true
		end
		local a = profile.a
		wipe(a)
		a.category,a.group,a.activity=categoryID,groupID,activityID
	else
		C_LFGList.ClearCreationTextFields()
	end
end

local activities_select_tb = {}
local keywords_select_sup = {}
local temp = {}

ClassicLFR_Options:push("find",{
	name = FIND_A_GROUP,
	desc = LFG_LIST_SELECT_A_CATEGORY,
	type = "group",
	childGroups = "tab",
	args =
	{
		category =
		{
			order = get_order(),
			name = function()
				local category = ClassicLFR_Options.db.profile.a.category
				if category then
					wipe(temp)
					temp[#temp+1]=CATEGORY
					temp[#temp+1]=" |cffff00ff"
					temp[#temp+1]=category
					temp[#temp+1]="|r"
					return table.concat(temp)
				end
				return CATEGORY
			end,
			type = "select",
			values = function()
				wipe(temp)
				temp[0]=""
				local categorys_tb = temp
				local GetCategoryInfo = C_LFGList.GetCategoryInfo
				if get_filters() then
					local categorys = C_LFGList.GetAvailableCategories()
					for i=1,#categorys do
						categorys_tb[categorys[i]] = GetCategoryInfo(categorys[i])
					end
				else
					local i = 1
					while true do
						local ctg = GetCategoryInfo(i)
						if ctg == nil then
							break
						end
						categorys_tb[i] = ctg
						i = i + 1
					end
				end
				return categorys_tb
			end,
			set = function(_,v)
				local a = ClassicLFR_Options.db.profile.a
				wipe(a)
				if v ~= 0 then
					a.category = v
				end
				C_LFGList.ClearSearchTextFields()
				ClassicLFR_Options:SendMessage("LFG_OPT_CATEGORY",ClassicLFR_Options.option_table.args.find.args,a.category)
			end,
			get = function() return ClassicLFR_Options.db.profile.a.category or 0 end,
			width = 1.5,
		},
		recommanded =
		{
			order = get_order(),
			name = RECOMMENDED,
			desc = L.find_recommended_desc,
			type = "toggle",
			get = function(_)
				local recommended = ClassicLFR_Options.db.profile.recommended
				if recommended then
					return
				elseif recommended == false then
					return false
				else
					return true
				end
			end,
			set = function(_,val)
				if val then
					ClassicLFR_Options.db.profile.recommended = nil
				elseif val == false then
					ClassicLFR_Options.db.profile.recommended = false
				else
					ClassicLFR_Options.db.profile.recommended = true
				end
			end,
			tristate = true,
		},
		group =
		{
			order = get_order(),
			name = function()
				local group = ClassicLFR_Options.db.profile.a.group
				if group then
					wipe(temp)
					temp[#temp+1]=GROUP
					temp[#temp+1]=" |cff00ff00"
					temp[#temp+1]=group
					temp[#temp+1]="|r"
					return table.concat(temp)
				end
				return GROUP			
			end,
			type = "select",
			values = function()
				local a = ClassicLFR_Options.db.profile.a
				local category = a.category
				local filters = get_filters()
				wipe(temp)
				if filters then
					temp[-1]=""
					temp[0]="..."
					if category then
						local groups_tb = temp
						local groups = C_LFGList.GetAvailableActivityGroups(category,filters)
						local C_LFGList_GetActivityGroupInfo = C_LFGList.GetActivityGroupInfo
						for i = 1,#groups do
							local groups_i = groups[i]
							groups_tb[groups_i] = C_LFGList_GetActivityGroupInfo(groups_i)
						end
						local grp = a.group
						if grp and groups_tb[grp] == nil then
							groups_tb[grp] = C_LFGList_GetActivityGroupInfo(grp)
						end
					end
				else
					local i = 1
					local j = 0
					local C_LFGList_GetActivityInfo = C_LFGList.GetActivityInfo
					while true do
						local fullName, shortName, categoryID, groupID = C_LFGList_GetActivityInfo(i)
						if categoryID == nil then
							j = j + 1
							if j == 20 then
								break
							end
						else
							j = 0
						end
						if groupID and (category == nil or category == categoryID) then
							temp[groupID] = true
						end
						i = i + 1
					end
					local ret_tb = {}
					for k,v in pairs(temp) do
						ret_tb[#ret_tb+1] = k
					end
					table.sort(ret_tb)
					local C_LFGList_GetActivityGroupInfo = C_LFGList.GetActivityGroupInfo
					for i=1,#ret_tb do
						ret_tb[i] = C_LFGList_GetActivityGroupInfo(ret_tb[i])
					end
					ret_tb[-1]=""
					ret_tb[0]="..."
					temp = ret_tb
				end
				return temp
			end,
			set = function(_,v)
				local a = ClassicLFR_Options.db.profile.a
				local category = a.category
				local activities = a.activities
				wipe(a)
				C_LFGList.ClearSearchTextFields()
				a.category = category
				a.activities = activities
				if v ~= -1 then
					a.group = v
				end
			end,
			get = function() return ClassicLFR_Options.db.profile.a.group or -1 end,
			width = "full",
		},
		activity =
		{
			order = get_order(),
			
			name = function()
				local activity = ClassicLFR_Options.db.profile.a.activity
				if activity then
					wipe(temp)
					temp[#temp+1]=LFG_LIST_ACTIVITY
					temp[#temp+1]=" |cff8080cc"
					temp[#temp+1]=activity
					temp[#temp+1]="|r"
					return table.concat(temp)
				end
				return LFG_LIST_ACTIVITY			
			end,
			type = "select",
			values = function()
				local a = ClassicLFR_Options.db.profile.a
				wipe(temp)
				temp[0]=""
				local ret = temp
				local c,g = a.category,a.group
				local filters = get_filters()
				if filters then
					local res = C_LFGList.GetAvailableActivities(c,g,filters)
					local i
					for i=1,#res do
						local res_i = res[i]
						local fullName, shortName = C_LFGList.GetActivityInfo(res_i)
						if fullName then
							ret[res_i] = fullName
						else
							if shortName then
								ret[res_i] = shortName
							end
						end
					end
				else
					local i = 1
					local j = 0
					while true do
						local fullName, shortName, categoryID, groupID = C_LFGList.GetActivityInfo(i)
						if categoryID == nil then
							j = j + 1
							if j == 20 then
								break
							end
						else
							j = 0
						end
						if (c == nil or c == categoryID) and (g == nil or g == groupID) then
							if fullName then
								ret[i] = fullName
							elseif shortName then
								ret[i] = shortName
							end
						end
						i = i + 1
					end
				end
				return ret
			end,
			set = function(_,v)
				local a = ClassicLFR_Options.db.profile.a
				local activity = a.activity
				C_LFGList.ClearSearchTextFields()
				if v == 0 then
					local category = a.category
					local group = a.group
					local activities = a.activities
					wipe(a)
					a.category = category
					a.group = group
					a.activities = activities
				else
					local activities = a.activities
					local category = a.category
					wipe(a)
					a.activity = v
					a.activities = activities
					_,_,a.category,a.group = C_LFGList.GetActivityInfo(v)
					if category ~= a.category then
						ClassicLFR_Options:SendMessage("LFG_OPT_CATEGORY",ClassicLFR_Options.option_table.args.find.args,a.category)					
					end
				end
			end,
			get = function() return ClassicLFR_Options.db.profile.a.activity or 0 end,
			width = "full",
		},
		f =
		{
			name = LFG_LIST_FIND_A_GROUP,
			order = get_order(),
			type = "group",
			childGroups = "select",
			args =
			{
				search =
				{
					order = get_order(),
					name = SEARCH,
					type = "execute",
					func = ClassicLFR_Options.find_search
				},
				reset = 
				{
					order = get_order(),
					name = RESET,
					type = "execute",
					func = function()
						wipe(ClassicLFR_Options.db.profile.a)
						C_LFGList.ClearSearchTextFields()
					end
				},
				opt =
				{
					name = BASE_SETTINGS,
					order = get_order(),
					type = "group",
					args =
					{
						role =
						{
							name = ROLE,
							desc = L.find_f_advanced_role,
							type = "toggle",
							get = ClassicLFR_Options.options_get_a_function,
							set = ClassicLFR_Options.options_set_a_function
						},
						class =
						{
							name = CLASS,
							desc = L.find_f_advanced_class,
							type = "toggle",
							get = ClassicLFR_Options.options_get_a_function,
							set = ClassicLFR_Options.options_set_a_function
						},
						complete =
						{
							name = COMPLETE,
							desc = L.find_f_advanced_complete,
							type = "toggle",
							get = ClassicLFR_Options.options_get_a_function,
							set = ClassicLFR_Options.options_set_a_function
						},
						gold =
						{
							name ="|TInterface\\MoneyFrame\\UI-GoldIcon:%d:%d:2:0|t",
							type = "toggle",
							desc = L.find_f_advanced_gold,
							set = function(info,val)
								if val then
									ClassicLFR_Options.db.profile.a.gold = true
								elseif val == false then
									ClassicLFR_Options.db.profile.a.gold = nil
								else
									ClassicLFR_Options.db.profile.a.gold = false
								end
							end,
							get = function()
								local d = ClassicLFR_Options.db.profile.a.gold
								if d then
									return true
								elseif d == false then
									return
								else
									return false
								end
							end,
							tristate = true
						},
						ilvl =
						{
							name = ITEM_LEVEL_ABBR,
							desc = LFG_LIST_ITEM_LEVEL_REQ,
							type = "input",
							order = -1,
							get = function()
								local ilv = ClassicLFR_Options.db.profile.a.ilvl
								if ilv then
									return tostring(ilv)
								end
							end,
							set = function(_,val)
								if val == "" then
									ClassicLFR_Options.db.profile.a.ilvl = nil
								else
									local num = tonumber(val)
									local average = GetAverageItemLevel()
									if num <= average then
										ClassicLFR_Options.db.profile.a.ilvl = num
									else
										ClassicLFR_Options.db.profile.a.ilvl = math.floor(average)
									end
								end
							end,
							pattern = "^[0-9]*$"
						},
						newg =
						{
							order = get_order(),
							name = NEW,
							type = "toggle",
							get = ClassicLFR_Options.options_get_a_function,
							set = ClassicLFR_Options.options_set_a_function
						},
						fast =
						{
							order = get_order(),
							name = L.Fast,
							desc = L.Fast_desc,
							type = "toggle",
							get = ClassicLFR_Options.options_get_a_function,
							set = ClassicLFR_Options.options_set_a_function
						},
						ft =
						{
							order = get_order(),
							name = nop,
							type = "input",
							dialogControl = "LFG_SECURE_SEARCH_BOX_REFERENCE",
							width = "full",
							order = 0
						},
					},
				},
				act =
				{
					name = LFG_LIST_ACTIVITY,
					order = get_order(),
					type = "group",
					args =
					{
						add =
						{
							order = get_order(),
							name = ADD,
							type = "execute",
							func = function()
								local a = ClassicLFR_Options.db.profile.a
								if not a.category then return end
								local act = a.activity
								local mtc
								if act then
									local fullName, shortName = C_LFGList.GetActivityInfo(act)
									mtc = fullName or shortName
								else
									local grp = a.group
									if grp then
										mtc = C_LFGList.GetActivityGroupInfo(grp)
									end
								end
								local atvs = a.activities
								if atvs then
									for i=1,#atvs do
										if mtc == atvs[i] then
											return
										end
									end
								else
									atvs = {}
									a.activities = atvs
								end
								atvs[#atvs+1] = mtc
							end
						},
						rmv = 
						{
							name = REMOVE,
							type = "execute",
							order = get_order(),
							func = function()
								local a = ClassicLFR_Options.db.profile.a
								local atvs = a.activities
								if atvs then
									local tb = {}
									for i = 1,#atvs do
										if not activities_select_tb[i] then
											tb[#tb+1] = atvs[i]
										end
									end
									if #tb == 0 then
										a.activities = nil
									else
										a.activities = tb
									end
								end
								wipe(activities_select_tb)
							end
						},
						activities =
						{
							order = get_order(),
							name = LFG_LIST_ACTIVITY,
							type = "multiselect",
							width = "full",
							values = function()	return ClassicLFR_Options.db.profile.a.activities end,
							get = function(info,key)
								return activities_select_tb[key]
							end,
							set = function(info,key,val)
								if val then
									activities_select_tb[key] = true
								else
									activities_select_tb[key] = nil
								end
							end
						},
					}
				},
			}
		},
		s =
		{
			name = START_A_GROUP,
			order = get_order(),
			type = "group",
			childGroups = "select",
			args =
			{
				cancel = 
				{
					order = get_order(),
					name = CANCEL,
					type = "execute",
					func = ClassicLFR_Options.update_editing
				},
				start =
				{
					order = get_order(),
					name = function()
						if C_LFGList.HasActiveEntryInfo() then
							return DONE_EDITING
						end
						return LIST_GROUP
					end,
					type = "execute",
					func = function()
						local profile = ClassicLFR_Options.db.profile
						if ClassicLFR_Options.listing(profile.a.activity,profile.s,{"s","f"}) then
							AceConfigDialog:SelectGroup("ClassicLFR","requests")
						end
					end
				},
				s =
				{
					order = 1,
					name = DESCRIPTION,
					type = "group",
					args =
					{
						title =
						{
							order = get_order(),
							name = LFG_LIST_TITLE,
							type = "input",
							dialogControl = "LFG_SECURE_NAME_EDITBOX_REFERENCE",
							width = "full"
						},
						details =
						{
							order = get_order(),
							name = LFG_LIST_DETAILS,
							type = "input",
							multiline = true,
							dialogControl = "LFG_SECURE_DESCRIPTION_EDITBOX_REFERENCE",
							width = "full"
						},
						minitemlvl =
						{
							order = get_order(),
							name = LFG_LIST_ITEM_LEVEL_INSTR_SHORT,
							desc = LFG_LIST_ITEM_LEVEL_REQ,
							type = "input",
							get = function(info)
								local sminilv = ClassicLFR_Options.db.profile.s.minimum_item_level
								if sminilv then
									return tostring(sminilv)
								end
							end,
							pattern = "^[0-9,.,-]*$",
							set = function(info,val)
								if val == "" then
									ClassicLFR_Options.db.profile.s.minimum_item_level = nil
								else
									local player_ilv = GetAverageItemLevel()
									local v = tonumber(val)
									if v then
										if player_ilv < v then
											ClassicLFR_Options.db.profile.s.minimum_item_level = player_ilv
										else
											ClassicLFR_Options.db.profile.s.minimum_item_level = v
										end
									end
								end
							end
						},
						minhonorlvl =
						{
							order = get_order(),
							name = LFG_LIST_HONOR_LEVEL_INSTR_SHORT,
							desc = LFG_LIST_HONOR_LEVEL_REQ,
							type = "input",
							get = function(info)
								local sminilv = ClassicLFR_Options.db.profile.s.minimum_honor_level
								if sminilv then
									return tostring(sminilv)
								end
							end,
							pattern = "^[0-9,.]*$",
							set = function(info,val)
								if val == "" then
									ClassicLFR_Options.db.profile.s.minimum_honor_level = nil
								else
									local player_ilv = math.floor(UnitHonorLevel("player"))
									local v = tonumber(val)
									if v then
										if player_ilv < v then
											ClassicLFR_Options.db.profile.s.minimum_honor_level = player_ilv
										else
											ClassicLFR_Options.db.profile.s.minimum_honor_level = v
										end
									end
								end
							end
						},
						vc =
						{
							order = get_order(),
							name = VOICE_CHAT,
							type = "input",
							dialogControl = "LFG_SECURE_VOICE_CHAT_EDITBOX_REFERENCE",
							width = "full",
						},
						auto_accept =
						{
							order = get_order(),
							name = LFG_LIST_AUTO_ACCEPT,
							type = "toggle",
							get = ClassicLFR_Options.options_get_s_function,
							set = ClassicLFR_Options.options_set_s_function
						},
						private =
						{
							order = get_order(),
							name = LFG_LIST_PRIVATE,
							desc = LFG_LIST_PRIVATE_TOOLTIP,
							type = "toggle",
							get = ClassicLFR_Options.options_get_s_function,
							set = ClassicLFR_Options.options_set_s_function
						},
						quest_id =
						{
							order = get_order(),
							name = BATTLE_PET_SOURCE_2,
							type = "input",
							get = function(info)
								local quest_id = ClassicLFR_Options.db.profile.s.quest_id
								if quest_id then
									return tostring(quest_id)
								end
							end,
							pattern = "^[0-9]*$",
							set = function(info,val)
								local s = ClassicLFR_Options.db.profile.s
								if val == "" or 10 < val:len() then
									s.quest_id = nil
								else
									local n = tonumber(val)
									if C_LFGList.CanCreateQuestGroup(n) then
										ClassicLFR_Options.db.profile.s.quest_id = n
									end
								end
							end,
							width = "full"
						},
					}
				},
				opt =
				{
					name = BASE_SETTINGS,
					order = 2,
					type = "group",
					args =
					{
						minitemlvl =
						{
							name = LFG_LIST_ITEM_LEVEL_INSTR_SHORT,
							desc = LFG_LIST_ITEM_LEVEL_REQ,
							type = "input",
							get = function(info)
								local sminilv = ClassicLFR_Options.db.profile.s.fake_minimum_item_level
								if sminilv then
									return tostring(sminilv)
								end
							end,
							pattern = "^[0-9,.,-]*$",
							set = function(info,val)
								if val == "" then
									ClassicLFR_Options.db.profile.s.fake_minimum_item_level = nil
								else
									local v = tonumber(val)
									if v then
										ClassicLFR_Options.db.profile.s.fake_minimum_item_level = v
									end
								end
							end
						},
						role =
						{
							name = ROLE,
							desc = L.find_f_advanced_role,
							type = "toggle",
							get = ClassicLFR_Options.options_get_s_function,
							set = ClassicLFR_Options.options_set_s_function
						},
					}
				}
			}
		},
	}
})
