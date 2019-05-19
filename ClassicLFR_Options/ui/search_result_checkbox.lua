local AceGUI = LibStub("AceGUI-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local ClassicLFR = LibStub("AceAddon-3.0"):GetAddon("ClassicLFR")
local ClassicLFR_Options = LibStub("AceAddon-3.0"):GetAddon("ClassicLFR_Options")


local L = LibStub("AceLocale-3.0"):GetLocale("ClassicLFR")

local LFGListSearchReporter =
{
	func = function(self, ...)C_LFGList.ReportSearchResult(...)end,
	notCheckable = true,
}
LFGListSearchReporter.__index = LFGListSearchReporter

function LFGListSearchReporter:new(o)
	setmetatable(o,self)
	return o
end

local function backfunc()
	if ClassicLFR_Options.option_table.args.search_result then
		AceConfigDialog:SelectGroup("ClassicLFR","search_result")
	end
end

local function paste(text)
	ClassicLFR_Options.Paste(text,backfunc)
end


local LFG_LIST_SEARCH_ENTRY_MENU

local armory_menu = {}

local function update_armory_menu()
	wipe(armory_menu)
	local k,v
	for k,v in pairs(ClassicLFR_Options.armory) do
		armory_menu[#armory_menu + 1] = LFGListSearchReporter:new(
		{
			text = k,
			func = function(_, id)
				local leaderName = C_LFGList.GetSearchResultInfo(id).leaderName
				if leaderName then
					local armory_link = v(leaderName)
					if armory_link then
						paste(armory_link)
					end
				end
			end,
		})
	end
	table.sort(armory_menu,function(a,b)
		return a.text < b.text
	end)
end
ClassicLFR_Options:RegisterMessage("UpdateArmory",update_armory_menu)

local function fake_achievement_link(id,b)
	local concat_tb = {"\124cffffff00\124Hachievement:",id,":",string.gsub(UnitGUID("player"), '0x', ''),":1:"}	
	local time_tb = date("*t",time()-691200)
	local d,m,y = time_tb.day,time_tb.month,math.fmod(time_tb.year,100)
	if b then
		concat_tb[#concat_tb+1] = math.random(1,28)
		concat_tb[#concat_tb+1] = ":"
		concat_tb[#concat_tb+1] = math.random(1,12)
		concat_tb[#concat_tb+1] = ":"
		concat_tb[#concat_tb+1] = math.random(y-7,y-1)
	else
		concat_tb[#concat_tb+1] = d
		concat_tb[#concat_tb+1] = ":"
		concat_tb[#concat_tb+1] = m
		concat_tb[#concat_tb+1] = ":"
		concat_tb[#concat_tb+1] = y
	end
	concat_tb[#concat_tb+1] = ":4294967295:4294967295:4294967295:4294967295\124h["
	concat_tb[#concat_tb+1] = select(2,GetAchievementInfo(id))
	concat_tb[#concat_tb+1] = "]\124h\124r"
	return table.concat(concat_tb)
end

local function raid_achievement(ce,aotc,from,n)
	local GetAchievementInfo = GetAchievementInfo
	if select(14,GetAchievementInfo(ce)) then	-- Cutting Edge
		return GetAchievementLink(ce)
	end
	local aotc = select(14,GetAchievementInfo(aotc)) and GetAchievementLink(aotc) or fake_achievement_link(aotc)
	if from then
		if select(14,GetAchievementInfo(from+n-1)) then
			return GetAchievementLink(from+n-1)
		end
		for i=from+n-2,from,-1 do
			if select(14,GetAchievementInfo(i)) then
				return table.concat{GetAchievementLink(i),aotc}
			end
		end
	end
	return aotc
end

local function botting_achievement(id,v)
	if select(14,GetAchievementInfo(id)) then
		return GetAchievementLink(id)
	end
	return fake_achievement_link(id,v)
end

local function applysearchresultinfo(id,key,func)
	local searchresultinfo = C_LFGList.GetSearchResultInfo(id)
	if searchresultinfo then
		local val = searchresultinfo[key]
		if val then
			func(val)
		end
	end
end

local function GetSearchEntryMenu(resultID)
	LFGListSearchReporter.arg1 = resultID;
	if LFG_LIST_SEARCH_ENTRY_MENU == nil then
		update_armory_menu()
		LFG_LIST_SEARCH_ENTRY_MENU =
		{
			LFGListSearchReporter:new(
			{
				text = WHISPER_LEADER,
				func = function(_, id)
					applysearchresultinfo(id,"leaderName",ChatFrame_SendTell)
				end,
			}),
			{
				text = CALENDAR_COPY_EVENT,
				hasArrow = true,
				notCheckable = true,
				menuList =
				{
--[[					LFGListSearchReporter:new(
					{
						text = LFG_LIST_BAD_NAME,
						func = function(_, id)
							applysearchresultinfo(id,"name",paste)
						end,
					}),
					LFGListSearchReporter:new(
					{
						text = LFG_LIST_BAD_DESCRIPTION,
						func = function(_, id)
							applysearchresultinfo(id,"comment",paste)
						end,
					}),
					LFGListSearchReporter:new(
					{
						text = VOICE_CHAT,
						func = function(_, id)
							applysearchresultinfo(id,"voiceChat",paste)
						end,
					}),]]
					LFGListSearchReporter:new(
					{
						text = LFG_LIST_BAD_LEADER_NAME,
						func = function(_, id)
							applysearchresultinfo(id,"leaderName",paste)
						end,
					})
				}
			},
			{
				text = L.Armory,
				hasArrow = true,
				notCheckable = true,
				menuList = armory_menu
			},
			LFGListSearchReporter:new({
				text = BATTLE_PET_SOURCE_6,
				func = function(_,groupid)
					local info = C_LFGList.GetSearchResultInfo(groupid)
					if not info then
						return
					end
					local leaderName = info.leaderName
					local activityID = info.activityID
					if leaderName then
						if activityID == 478 or activityID == 479 then -- ToS N/H
							SendChatMessage(raid_achievement(11875,11874,11774,9),"WHISPER",nil,leaderName)
						end
						
						if activityID == 415 or activityID == 416 then -- NH N/H
							SendChatMessage(raid_achievement(11192,11195),"WHISPER",nil,leaderName)
						end
						if activityID == 481 then	-- NH M
							SendChatMessage(botting_achievement(11192),"WHISPER",nil,leaderName)
						end

						if activityID == 456 or activityID == 457 then -- ToV N/H
							SendChatMessage(raid_achievement(11580,11426),"WHISPER",nil,leaderName)
						end
						if activityID == 480 then	-- ToV M
							SendChatMessage(botting_achievement(11580),"WHISPER",nil,leaderName)
						end

						if activityID == 413 or activityID == 414 then -- EN N/H
							SendChatMessage(raid_achievement(11191,11194),"WHISPER",nil,leaderName)
						end

						if activityID == 468 then	-- EN M
							SendChatMessage(botting_achievement(11191),"WHISPER",nil,leaderName)
						end

						if activityID == 482 or activityID == 483 then	-- Antorus N/H
							SendChatMessage(raid_achievement(12111,12110,11992,11),"WHISPER",nil,leaderName)
						end

						if activityID == 493 then	-- Antorus M
							SendChatMessage(botting_achievement(12111),"WHISPER",nil,leaderName)
						end

						if activityID == 494 or activityID == 495 then -- Uldir N/H
							SendChatMessage(raid_achievement(12535,12536),"WHISPER",nil,leaderName)
						end

						if activityID == 496 then
							SendChatMessage(botting_achievement(12535),"WHISPER",nil,leaderName)
						end

						if activityID == 663 or activityID == 664 then -- BoD N/H
							SendChatMessage(raid_achievement(13323,13322),"WHISPER",nil,leaderName)
						end
						
						if activityID == 667 or activityID == 668 then -- Crucible of Storms N/H
							SendChatMessage(raid_achievement(13419,13418),"WHISPER",nil,leaderName)						
						end
						
						if activityID == 6 then -- 2 Bots vs 2 Bots
							SendChatMessage(botting_achievement(1159,true),"WHISPER",nil,leaderName)
						end
						if activityID == 7 then -- 3 Bots vs 3 Bots
							SendChatMessage(botting_achievement(5267,true),"WHISPER",nil,leaderName)
						end
						if activityID == 19 then -- Rated Bots
							SendChatMessage(botting_achievement(5356,true)..botting_achievement(5267,true),"WHISPER",nil,leaderName)	-- Rated Bots + 3 Bots vs 3 Bots
						end
					end
				end
			}),
			LFGListSearchReporter:new({
				text = IGNORE,
				hasArrow = true,
				notCheckable = true,
				func = function(_,id)
					local info = C_LFGList.GetSearchResultInfo(id)
					if not info then
						return
					end
					local leaderName = info.leaderName
					if leaderName then
						C_LFGList.ReportSearchResult(id,"lfglistspam")
						local tb = ClassicLFR.db.profile.spam_filter_keywords
						if tb == nil then
							tb = {}
						end
						tb[#tb+1] = leaderName:lower()
						ClassicLFR.db.profile.spam_filter_keywords = tb
					end
				end,
				menuList =
				{
					LFGListSearchReporter:new({text = LFG_LIST_BAD_LEADER_NAME,func = function(_, id)
						applysearchresultinfo(id,"leaderName",AddIgnore)
					end}),
					LFGListSearchReporter:new({text = FRIENDS_LIST_REALM:match("^(.*)%:") or FRIENDS_LIST_REALM:match("^(.*)%：") or FRIENDS_LIST_REALM,func = function(_,id)
						local info = C_LFGList.GetSearchResultInfo(id)
						if not info then
							return
						end
						local leaderName = info.leaderName
						if leaderName then
							local _,realm = strsplit("-",leaderName)
							if realm then
								ClassicLFR_Options:add_realm_filter(realm)
							end
						end
					end}),
				}
			}),
			{
				text = LFG_LIST_REPORT_GROUP_FOR,
				hasArrow = true,
				notCheckable = true,
				menuList =
				{
					LFGListSearchReporter:new({text = LFG_LIST_SPAM,arg2 = "lfglistspam"}),
					LFGListSearchReporter:new({text = LFG_LIST_BAD_NAME,arg2 = "lfglistname"}),
					LFGListSearchReporter:new({text = LFG_LIST_BAD_DESCRIPTION,arg2 = "lfglistcomment"}),
					LFGListSearchReporter:new({text = LFG_LIST_BAD_VOICE_CHAT_COMMENT,arg2 = "lfglistvoicechat"}),
					LFGListSearchReporter:new({text = LFG_LIST_BAD_LEADER_NAME,arg2 = "badplayername"}),
				},
			},
			{
				text = CANCEL,
				notCheckable = true,
			},
		}
	end
	return LFG_LIST_SEARCH_ENTRY_MENU;
end

local function AlignImage(self)
	local img = self.image:GetTexture()
	self.text:ClearAllPoints()
	if not img then
		self.text:SetPoint("LEFT", self.checkbg, "RIGHT")
		self.text:SetPoint("RIGHT")
	else
		self.text:SetPoint("LEFT", self.image,"RIGHT", 1, 0)
		self.text:SetPoint("RIGHT")
	end
end

local GameTooltip = GameTooltip
local string_format = string.format

local function convert_sec_to_xx_xx_xx(value)
	value = math.floor(value)
	local hour = value / 3600
	local min_sec = value % 3600
	local minute = min_sec / 60
	local sec = min_sec % 60
	return ("%02d:%02d:%02d"):format(hour,minute,sec)
end

ClassicLFR_Options.convert_sec_to_xx_xx_xx = convert_sec_to_xx_xx_xx

local tank_tb = {}
local healer_tb = {}
local damager_tb = {}

local classes = {}
do

local CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
local GetClassInfo = GetClassInfo
for i=1,GetNumClasses() do
	local _,class = GetClassInfo(i)
	classes[i]=CLASS_COLORS[class]
	classes[class]=i
end

end

local function add_role(tbl,icon,n)
	if n ~= 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddDoubleLine(icon,n,nil,nil,nil,0.5,0.5,0.8)
		local GetClassInfo = GetClassInfo
		for i=1,#tbl do
			local v = tbl[i]
			if v ~= 0 then
				local color=classes[i]
				if v == 1 then
					GameTooltip:AddDoubleLine(GetClassInfo(i),nil,color.r,color.g,color.b)
				else
					GameTooltip:AddDoubleLine(GetClassInfo(i),v,color.r,color.g,color.b,color.r,color.g,color.b)
				end
			end
		end		
	end
end

local function init_roles(id,numMembers)
	local C_LFGList_GetSearchResultMemberInfo = C_LFGList.GetSearchResultMemberInfo
	for i=1,GetNumClasses() do
		tank_tb[i]=0
		healer_tb[i]=0
		damager_tb[i]=0
	end
	local tank,healer,damager = 0,0,0
	for i = 1, numMembers do
		local role, class, class_localized = C_LFGList_GetSearchResultMemberInfo(id,i)
		local class_id = classes[class]
		if role == "TANK" then
			tank_tb[class_id] = tank_tb[class_id] + 1
			tank = tank + 1
		elseif role == "HEALER" then
			healer_tb[class_id] = healer_tb[class_id] + 1
			healer = healer + 1
		else
			damager_tb[class_id] = damager_tb[class_id] + 1
			damager = damager + 1
		end
	end
	return tank,healer,damager,tank_tb,healer_tb,damager_tb,classes
end
ClassicLFR_Options.init_roles = init_roles
local concat_tb = {}

local function handle_title_role(number,tb,sign)
	if number ~= 0 then
		for i=1,#tb do
			local v = tb[i]
			if v ~= 0 then
				concat_tb[#concat_tb + 1] = "|c"
				concat_tb[#concat_tb + 1] = classes[i].colorStr
				concat_tb[#concat_tb + 1] = sign
				if v ~= 1 then
					concat_tb[#concat_tb + 1] = v
				end
				concat_tb[#concat_tb + 1] = "|r"
			end
		end
		concat_tb[#concat_tb+1] = " "
	end
end

function ClassicLFR_Options.updatetitle(obj)
	local users = obj:GetUserDataTable()
	local info = C_LFGList.GetSearchResultInfo(users.val)
	if info == nil then
		return
	end
	local activityName, shortName, categoryID, groupID, itemLevel, filters, minLevel, maxPlayers, displayType = 
		C_LFGList.GetActivityInfo(info.activityID)
	local questID = info.questID
	if questID then
		local questName = C_TaskQuest.GetQuestInfoByQuestID(questID)
		if questName then
			obj.text:SetText(questName)
		else
			obj.text:SetText(info.name)
		end
	else
		obj.text:SetText(info.name)
	end
	obj.text:SetTextColor(1,0.82,0)
	wipe(concat_tb)
	concat_tb[#concat_tb + 1] = activityName
	local iLvl = info.requiredItemLevel
	if iLvl ~= 0 then
		concat_tb[#concat_tb + 1] = "  "
		concat_tb[#concat_tb + 1] = ITEM_LEVEL_ABBR
		concat_tb[#concat_tb + 1] = " "
		concat_tb[#concat_tb + 1] = iLvl
	end
	concat_tb[#concat_tb+1] = "\n|cff8080cc"
	local numMembers = info.numMembers
	concat_tb[#concat_tb+1] = numMembers
	concat_tb[#concat_tb+1] = "("
	local tank,healer,damager = init_roles(users.val,numMembers)
	concat_tb[#concat_tb+1] = tank
	concat_tb[#concat_tb+1] = "/"
	concat_tb[#concat_tb+1] = healer
	concat_tb[#concat_tb+1] = "/"
	concat_tb[#concat_tb+1] = damager
	concat_tb[#concat_tb+1] = ")|r "
	handle_title_role(tank,tank_tb,"T")
	handle_title_role(healer,healer_tb,"H")
	handle_title_role(damager,damager_tb,"D")
	local voiceChat = info.voiceChat
	if voiceChat:len()~=0 then
		concat_tb[#concat_tb + 1] = "\n|cff00ffff"
		concat_tb[#concat_tb + 1] = voiceChat
		concat_tb[#concat_tb + 1] = "|r"
	end
	local comment = info.comment
	if comment:len()~=0 then
		concat_tb[#concat_tb + 1] = "\n|cff00ff00"
		concat_tb[#concat_tb + 1] = comment
		concat_tb[#concat_tb + 1] = "|r"
	end
	obj:SetDescription(table.concat(concat_tb))
	wipe(concat_tb)
	if info.isDelisted then
		ClassicLFR_Options.delist(obj)
	end
end

function ClassicLFR_Options.delist(obj)
	local r,g,b,a = obj.text:GetTextColor()
	obj.text:SetTextColor(r,g,b,0.55)
	r,g,b,a = obj.desc:GetTextColor()
	obj.desc:SetTextColor(r,g,b,0.55)
	obj.disabled = true
end

function ClassicLFR_Options.disable(obj,disabled)
	obj.disabled = disabled
	if disabled then
		obj.frame:Disable()
		local r,g,b = obj.text:GetTextColor()
		obj.text:SetTextColor(r,g,b,0.55)
		SetDesaturation(obj.check, true)
		if obj.desc then
			r,g,b = obj.desc:GetTextColor()
			obj.desc:SetTextColor(r,g,b,0.55)
		end
	else
		obj.frame:Enable()
		local r,g,b = obj.text:GetTextColor()
		obj.text:SetTextColor(r,g,b,1)
		if obj.tristate and obj.checked == nil then
			SetDesaturation(obj.check, true)
		else
			SetDesaturation(obj.check, false)
		end
		if obj.desc then
			r,g,b = obj.desc:GetTextColor()
			obj.desc:SetTextColor(r,g,b,1)
		end
	end
end

function ClassicLFR_Options.handle_roles(id,numMembers)
	local tank,healer,damager = init_roles(id,numMembers)
	GameTooltip:AddDoubleLine(numMembers,string_format("%d/%d/%d",tank,healer,damager),nil,nil,nil,0.5,0.5,0.8)
	add_role(tank_tb,"|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:0:19:22:41|t",tank)
	add_role(healer_tb,"|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:1:20|t",healer)
	add_role(damager_tb,"|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:22:41|t",damager)
end

function ClassicLFR_Options.handle_encounters(rse)
	if rse then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(#rse)
		for i=1,#rse do
			GameTooltip:AddLine(rse[i],1,0,0,true)
		end
	end
end

local function add_application_info_tooltip(resultID)
	local id, appStatus, pendingStatus, appDuration = C_LFGList.GetApplicationInfo(resultID)
	if appStatus == "none" then
		return
	elseif appStatus == "applied" then
		GameTooltip:AddLine(' ')
		wipe(concat_tb)
		concat_tb[#concat_tb+1] = LFG_LIST_PENDING
		concat_tb[#concat_tb+1] = ' '
		concat_tb[#concat_tb+1] = convert_sec_to_xx_xx_xx(appDuration)
		GameTooltip:AddLine(table.concat(concat_tb),GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b)
		wipe(concat_tb)
	elseif pendingStatus == "cancelled" or appStatus == "cancelled" or appStatus == "failed" then
		GameTooltip:AddLine(' ')
		GameTooltip:AddLine(LFG_LIST_APP_CANCELLED,RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
	elseif appStatus == "declined" or appStatus == "declined_full" or appStatus == "declined_delisted" then
		GameTooltip:AddLine(' ')
		GameTooltip:AddLine(LFG_LIST_APP_DECLINED,RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
	elseif appStatus == "timeout" then
		GameTooltip:AddLine(' ')
		GameTooltip:AddLine(LFG_LIST_APP_TIMED_OUT,RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
	elseif appStatus == "invited" then
		GameTooltip:AddLine(' ')
		GameTooltip:AddLine(LFG_LIST_APP_INVITED,GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b)
	elseif appStatus == "inviteaccepted" then
		GameTooltip:AddLine(' ')
		GameTooltip:AddLine(LFG_LIST_APP_INVITE_ACCEPTED,GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b)
	elseif appStatus == "invitedeclined" then
		GameTooltip:AddLine(' ')
		GameTooltip:AddLine(LFG_LIST_APP_INVITE_DECLINED,RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
	end
end

ClassicLFR_Options.add_application_info_tooltip = add_application_info_tooltip

local function on_enter(self)
	GameTooltip:SetOwner(self,"ANCHOR_TOPRIGHT")
	coroutine.wrap(ClassicLFR_Options.search_result_tooltip_coroutine)(self,self.obj:GetUserDataTable().val)
end

function ClassicLFR_Options.search_result_tooltip_coroutine(frame,id)
	local co = coroutine.running()
	local onenter = frame:GetScript("OnEnter")
	local onleave = frame:GetScript("OnLeave")
	local function cofunc(...)
		ClassicLFR.resume(...)
	end
	frame:SetScript("OnEnter",nop)
	local function leave()
		cofunc(co)
	end
	frame:SetScript("OnLeave",leave)
	local ticker=C_Timer.NewTicker(1,function()
		cofunc(co,true)
	end)
	local function update_method(message,result_id,...)
		if id == result_id then
			cofunc(co,1,message,...)
		end
	end
	ClassicLFR:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED",update_method)
	ClassicLFR:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED",update_method)
	local GameTooltip = GameTooltip
	local GetTime = GetTime
	local info
	local activityName, shortName, categoryID, groupID, itemLevel, filters, minLevel, maxPlayers, displayType 
	local groupname,encounters,friendlist,name, addon, age_refresh_time
	local yd = 1
	local addon
	local age_refresh_time
	while yd do
		if GameTooltip:GetOwner() ~= frame then
			break
		end
		if yd == 1 then
			info = C_LFGList.GetSearchResultInfo(id)
			if info == nil then
				break
			end
			age_refresh_time = GetTime()
			activityName, shortName, categoryID, groupID, itemLevel, filters, minLevel, maxPlayers, displayType = C_LFGList.GetActivityInfo(info.activityID)
			groupname = C_LFGList.GetActivityGroupInfo(groupID)
			encounters = C_LFGList.GetSearchResultEncounterInfo(id)
			friendlist = LFGListSearchEntryUtil_GetFriendList(id)
			local iLvl = info.requiredItemLevel
			local questID = info.questID
			addon = nil
			if iLvl ~= 0 then
				if math.floor(iLvl)~=iLvl then
					addon = "LFG"
				elseif iLvl == 240 then
					addon = "WQL"
				end
			elseif questID then
				addon = "Blizzard"
			end
			name = nil
			if questID then
				name = C_TaskQuest.GetQuestInfoByQuestID(questID)
			end
			if name == nil then
				name = info.name
			end
		end
		GameTooltip:ClearLines()
		GameTooltip:AddLine(name,0.5,0.5,0.8,true)
		if info.requiredItemLevel ~= 0 then
			GameTooltip:AddDoubleLine(ITEM_LEVEL_ABBR, info.requiredItemLevel, nil,nil,nil,  0.5, 0.5, 0.8)
		end
		if info.requiredHonorLevel ~= 0 then
			GameTooltip:AddDoubleLine(LFG_LIST_HONOR_LEVEL_INSTR_SHORT, info.requiredHonorLevel, nil,nil,nil,  0.5, 0.5, 0.8)
		end
		GameTooltip:AddDoubleLine(groupname or activityName)
		GameTooltip:AddDoubleLine(shortName, convert_sec_to_xx_xx_xx(GetTime()-age_refresh_time+info.age),nil,nil,nil,  0.5, 0.5, 0.8)
		GameTooltip:AddDoubleLine(ID,id, nil,nil,nil,  0.5, 0.5, 0.8)
		if info.questID then
			GameTooltip:AddDoubleLine(TRANSMOG_SOURCE_2,info.questID,nil,nil,nil,0.5,0.5,0.8,true)	
		end
		local leaderName = info.leaderName
		if leaderName then
			local name,realm = leaderName:match("^(.*)-(.*)$")
			if name then
				GameTooltip:AddDoubleLine(name,realm,nil,nil,nil,0.5,0.5,0.8)
			else
				GameTooltip:AddDoubleLine(leaderName)
			end
			local lfgscores = ClassicLFR.lfgscores
			if lfgscores and #lfgscores ~= 0 then
				for i=1,#lfgscores do
					lfgscores[i](leaderName,groupID)
				end
			end
		end
		local voiceChat = info.voiceChat
		if voiceChat:len()~=0 then
			GameTooltip:AddDoubleLine(LFG_LIST_VOICE_CHAT,voiceChat, nil,nil,nil,  0.5, 0.5, 0.8,true)
		end
		if addon then
			GameTooltip:AddDoubleLine(ADDONS,addon,nil,nil,nil,0.5,0.5,0.8,true)
		end
		if info.autoAccept then
			GameTooltip:AddLine(LFG_LIST_AUTO_ACCEPT)
		end
		ClassicLFR_Options.handle_roles(id,info.numMembers)
		local comment = info.comment
		if comment:len()~=0 then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(comment,0.5,0.5,0.8,true)
		end
		ClassicLFR_Options.handle_encounters(encounters)
		
		if friendlist:len()~=0 then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(friendlist,nil,nil,nil,true)
		end
		if info.isDelisted then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(LFG_LIST_ENTRY_DELISTED,1,0,0,true)
		end
		add_application_info_tooltip(id)
		GameTooltip:Show()
		yd = coroutine.yield()
	end
	ticker:Cancel()
	ClassicLFR:UnregisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED")
	ClassicLFR:UnregisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")
	frame:SetScript("OnLeave",onleave)
	frame:SetScript("OnEnter",onenter)
	GameTooltip:Hide()
end

AceGUI:RegisterWidgetType("ClassicLFR_search_result_checkbox", function()
	local check = AceGUI:Create("CheckBox")
	local frame = check.frame
	frame:RegisterForClicks("LeftButtonDown","RightButtonDown")
	frame:SetScript("OnMouseUp",function(self,button)
		local obj = self.obj
		local user = obj:GetUserDataTable()
		if button == "LeftButton" then
			if not obj.disabled then
				if obj.checked then
					PlaySound(856)
				else -- for both nil and false (tristate)
					PlaySound(857)
				end
				
				obj:Fire("OnValueChanged", obj.checked)
			end
			AlignImage(obj)
		else
			EasyMenu(GetSearchEntryMenu(user.val), LFGListFrameDropDown, "cursor" , 0, 0, "MENU")
		end
	end)
	check.SetDisabled = ClassicLFR_Options.disable
	frame:SetScript("OnEnter", on_enter)
	function check.OnAcquire(self)
		self:SetTriState(nil)
		self.disabled = false
		self.width = "fill"
	end
	check.type = "ClassicLFR_search_result_checkbox"	
	return AceGUI:RegisterAsWidget(check)
end, 1)
