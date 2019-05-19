local ClassicLFR_Options = LibStub("AceAddon-3.0"):GetAddon("ClassicLFR_Options")

ClassicLFR_Options.RegisterSimpleFilter("find",function(info,profile,flag_array)
	local fullName, shortName, categoryID = C_LFGList.GetActivityInfo(info.activityID)
	local band = bit.band
	local tb = C_LFGList.GetSearchResultMemberCounts(info.searchResultID)
	local tank = tb.TANK + flag_array[2] 
	local healer = tb.HEALER + flag_array[3]
	local damager = tb.NOROLE + tb.DAMAGER + flag_array[4]
	local flag = flag_array[1]
	local t,h,d = band(flag,1)~=0,band(flag,2)~=0,band(flag,4)~=0
	if band(flag,8) ~= 0 then
		if categoryID == 1 or categoryID == 4 then
			if d or (h and healer == 0) or (t and tank == 0) then
				return 0
			end
		elseif categoryID == 2 then
			if (d and (damager < 3)) or (h and healer == 0 and damager ~= 4) or (t and tank == 0) then
				return 0
			end
		elseif categoryID == 3 then
			local nm = 15
			if nm < info.numMembers then
				nm = info.numMembers
			end
			local maxhealer = math.ceil(nm/5)
			local maxmembers = maxhealer * 5
			if (d and damager + 1 < maxmembers) or (h and healer < maxhealer) or (t and tank < 2) then
				return 0
			end
		elseif categoryID == 9 then
			if (d and damager < 7) or (h and healer < 3) or (t and tank == 0) then
				return 0
			end
		else
			return 0
		end
	elseif band(flag,16) ~= 0 then
		if categoryID == 2 then
			if t or tank == 1 then
				return 0
			end
		elseif categoryID == 3 then
			if t and 0 < tank or 1 < tank then
				return 0
			end
		elseif categoryID == 9 then
			if h and 1 < healer or 2 < healer then
				return 0
			end
		else
			return 0
		end
	end
	return 1
end,
function(profile)
	local a = profile.a
	local bit = bit
	local bor = bit.bor
	local flags = a.role and 8 or 0
	flags = bor(flags,a.fast and 16 or 0)
	if flags ~= 0 then
		local leader,t,h,d = GetLFGRoles()
		flags = bor(flags,t and 1 or 0)
		flags = bor(flags,h and 2 or 0)
		flags = bor(flags,d and 4 or 0)
		if UnitIsGroupLeader("player") then
			local r = UnitGroupRolesAssigned("player")
			if bit.band(flags,7) == 0 then
				if r == "TANK" then
					flags = bor(flags,t and 1 or 0)
				elseif r == "Healer" then
					flags = bor(flags,t and 2 or 0)
				else
					flags = bor(flags,t and 4 or 0)
				end
			end
			local tb = GetGroupMemberCounts()
			if r == "NONE" then
				tb.NOROLE = tb.NOROLE - 1
			else
				tb[r] = tb[r] - 1
			end
			local tank = tb.TANK
			local healer = tb.HEALER
			local damager = tb.NOROLE + tb.DAMAGER
			wipe(tb)
			tb[1] = flags
			tb[2] = tank
			tb[3] = healer
			tb[4] = damager
			return tb
		end
		return {flags,0,0,0}
	end
end)

local order = 0
local function get_order()
	local temp = order
	order = order + 1
	return temp
end

ClassicLFR_Options:push("role",
{
	name = ROLE,
	type = "group",
	order = 8,
	args =
	{
		comment =
		{
			order = get_order(),
			name = function(info)
				local text = LFGListApplicationDialogDescription.EditBox:GetText()
				if text:len() == 0 then
					return LFG_LIST_NOTE_TO_LEADER
				else
					return "|cff00ff00"..text.."|r"
				end
			end,
			type = "description",
			width = "full",
		},
		edit_comment =
		{
			order = get_order(),
			name = EDIT,
			desc = LFG_LIST_NOTE_TO_LEADER,
			type = "execute",
			func = function()
				LFGListApplicationDialog.resultID = function()
					ClassicLFR_Options.NotifyChangeIfSelected("role")
				end
				LFGListApplicationDialog_UpdateRoles(LFGListApplicationDialog)
				StaticPopupSpecial_Show(LFGListApplicationDialog)
			end
		},
		reset =
		{
			order = get_order(),
			name = RESET,
			type = "execute",
			func = C_LFGList.ClearApplicationTextFields
		},
		warmode=
		{
			name = function()
				local default = C_PvP.GetWarModeRewardBonusDefault()
				local bouns = C_PvP.GetWarModeRewardBonus()
				if  default ~= bouns then
					return PVP_LABEL_WAR_MODE.." |cff8080cc("..bouns.."%)|r"
				else
					return PVP_LABEL_WAR_MODE.." |cff00ff00("..bouns.."%)|r"
				end
			end,
			desc = function()
				local e = PVP_WAR_MODE_DESCRIPTION_FORMAT:format(C_PvP.GetWarModeRewardBonus())
				local t = _G["PVP_WAR_MODE_NOT_NOW_"..UnitFactionGroup("player"):upper().."_RESTAREA"]
				if t then
					return e.."\n\n|cffff0000"..t.."|r"
				else
					return e
				end
			end,
			order = get_order(),
			set = function()
				if C_PvP.CanToggleWarMode(false) or C_PvP.CanToggleWarMode(true) then
					local function notify()
						ClassicLFR_Options.NotifyChangeIfSelected("role")
						ClassicLFR_Options:UnregisterEvent("PLAYER_FLAGS_CHANGED")
					end
					ClassicLFR_Options:RegisterEvent("PLAYER_FLAGS_CHANGED",notify)
					C_Timer.After(1,notify)
					C_PvP.ToggleWarMode()
				end
			end,
			get = C_PvP.IsWarModeDesired,
			width = "full",
			type = "toggle"
		},
		leader =
		{
			order = get_order(),
			name = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:0:19:1:20|t"..LEADER,
			desc = GUIDE_TOOLTIP,
			type = "toggle",
			get = function(info)
				return GetLFGRoles()
			end,
			set = function(info,val)
				local leader,tank,healer,damage = GetLFGRoles()
				SetLFGRoles(val,tank,healer,damage)
			end,
			width = "full",
		},
		tank = 
		{
			order = get_order(),
			name = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:0:19:22:41|t"..TANK,
			desc = ROLE_DESCRIPTION_TANK,
			type = "toggle",
			get = function(info)
				return select(2,GetLFGRoles())
			end,
			set = function(info,val)
				local leader,tank,healer,damage = GetLFGRoles()
				SetLFGRoles(leader,val,healer,damage)
			end,
			width = "full",
		},
		healer = 
		{
			order = get_order(),
			name = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:1:20|t"..HEALER,
			desc = ROLE_DESCRIPTION_HEALER,
			type = "toggle",
			get = function(info)
				return select(3,GetLFGRoles())
			end,
			set = function(info,val)
				local leader,tank,healer,damage = GetLFGRoles()
				SetLFGRoles(leader,tank,val,damage)
			end,
			width = "full",
		},
		damage = 
		{
			order = get_order(),
			name = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:22:41|t"..DAMAGER,
			desc = ROLE_DESCRIPTION_DAMAGER,
			type = "toggle",
			get = function(info)
				return select(4,GetLFGRoles())
			end,
			set = function(info,val)
				local leader,tank,healer,damage = GetLFGRoles()
				SetLFGRoles(leader,tank,healer,val)
			end,
			width = "full",
		},
	}
})

ClassicLFR_Options.Register("auto_accept","f",function(infos,bts,first,profile)
	if not profile.s.role then
		return
	end
	local entry_info = C_LFGList.GetActiveEntryInfo()
	local activityID = entry_info.activityID
	local fullName, shortName, categoryID, groupID, itemLevel, filters, minLevel, maxPlayers, displayType, activityOrder = C_LFGList.GetActivityInfo(entry_info.activityID)
	if categoryID == 1 or entry_info.questID then
		return
	end
	local max_healer = math.ceil(maxPlayers/5)
	if categoryID == 9 then
		max_healer = max_healer + 1
	end
	local max_tank
	if categoryID == 2 or categoryID == 3 or categoryID == 111 then
		max_tank = math.floor(math.min(maxPlayers/5,2))
	end
	local max_damager = maxPlayers - max_healer
	if max_tank then
		max_damager = max_damager - max_tank
	end
	local member_count_tb = GetGroupMemberCounts()
	local tank = member_count_tb.TANK
	local healer = member_count_tb.HEALER
	local damager = member_count_tb.DAMAGER+member_count_tb.NOROLE
	for i=1,#infos do
		local info = infos[i]
		if info and bit.band(bts[i],1) == 0 then
			local gtank,ghealer,gdamager = 0,0,0
			for memberIdx=1,info.numMembers do
				local name, class, localizedClass, level, itemLevel, honorLevel, tank, healer, damage, assignedRole, relationship = C_LFGList.GetApplicantMemberInfo(info.applicantID,memberIdx)
				if assignedRole=="TANK" and max_tank then
					gtank = gtank + 1
				elseif assignedRole == "HEALER" then
					ghealer = ghealer + 1
				else
					gdamager = gdamager + 1
				end
			end
			if (not max_tank or gtank + tank <= max_tank) and ghealer + healer <= max_healer and gdamager + damager <= max_damager  then
				if max_tank then
					tank = tank +gtank
				end
				healer = healer + ghealer
				damager = damager + gdamager
			else
				bts[i] = bit.bor(bts[i],1)
			end
		end
	end
end)
