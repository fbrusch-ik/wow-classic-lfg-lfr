local ClassicLFR = LibStub("AceAddon-3.0"):GetAddon("ClassicLFR")
local dialog = {}
StaticPopupDialogs.ClassicLFR_HardwareAPIDialog = dialog
INTERFACE_ACTION_BLOCKED_SHOWN = true

local ms = LibStub("AceAddon-3.0"):GetAddon("MeetingStone", true)
if ms then
	local cp = ms:GetModule("CreatePanel", true)
	if cp then
		cp:UnregisterEvent("LFG_LIST_ENTRY_CREATION_FAILED")
		cp.LFG_LIST_ENTRY_CREATION_FAILED = nil
	end
end

local function is_queueing_lfg()
	for i = 1,6 do
		if GetLFGMode(i) then
			return true
		end
	end
	for i=1,GetMaxBattlefieldID() do
		if GetBattlefieldStatus(i) ~= "none" then
			return true
		end
	end
end

function ClassicLFR.accepted(name,search,create,secure,raid,keyword,ty_pe,create_only)
	local profile = ClassicLFR.db.profile
	if (secure <= 0 and profile.disable_auto) or is_queueing_lfg() then
		return true
	end
	local delta = profile.hardware and -1 or 0
	local current = coroutine.running()
	local function resume()
		ClassicLFR.resume(current)
	end
	local function resume_1()
		ClassicLFR.resume(current,1)
	end	
	local asag
	if create == nil then
		asag = false
	else
		asag = profile.auto_start_a_group
		if create_only then
			asag = true
		end
	end
	if secure < 0 or profile.auto_find_a_group then
		secure = -1
	elseif 0 == secure then
		secure = delta
	end
	local wql = ty_pe and profile.auto_addons_wql or nil
	local function hwe_api(editbox,text,func,clearfunc,button1,strict)
		if not wql and strict then
			clearfunc()
		end
		if editbox and keyword and (wql and (strict and editbox:GetText()==keyword or not editbox:GetText():find(keyword)) or (not strict and editbox:GetText():len()~=1)) then
			wipe(dialog)
			clearfunc()
			if wql then
				dialog.text=text.."\n"..keyword
			elseif keyword then
				dialog.text=text.."("..keyword..")\nf"
			else
				dialog.text=text.."\nf"
			end
			dialog.button1 = CANCEL
			dialog.timeOut = 45
			dialog.OnAccept=resume
			dialog.OnHide = function(self)
				editbox:Hide()
			end
			StaticPopup_Show("ClassicLFR_HardwareAPIDialog",nil,nil,nil,editbox).insertedFrame = nil
			if coroutine.yield() ~= 1 then
				return true
			end
		elseif secure < 0 then
			wipe(dialog)
			dialog.text=text
			dialog.button1 = button1
			dialog.button2 = CANCEL
			dialog.timeOut = 45
			dialog.OnAccept=resume_1
			dialog.OnCancel=resume
			local t = StaticPopup_Show("ClassicLFR_HardwareAPIDialog")
			if t.insertedFrame then
				t.insertedFrame:Hide()
				t.insertedFrame=nil
			end
			if coroutine.yield() ~= 1 then
				return true
			end
		end
		secure = delta
		return nil,func()
	end
	local LFGListFrame = LFGListFrame
	local EntryCreation = LFGListFrame.EntryCreation
	local Name = EntryCreation.Name
	Name:SetEnabled(true)
	local SearchPanel = LFGListFrame.SearchPanel
	local SearchBox = SearchPanel.SearchBox
	SearchBox:SetEnabled(true)
	local searchbox_onenterpressed = SearchBoxTemplate_OnTextChanged
	local name_onenterpressed = InputBoxInstructions_OnTextChanged
	local await_search_result
	if wql then
		searchbox_onenterpressed = function(self)
			if self:GetText()==keyword then
				local popup_name,popup_frame = StaticPopup_Visible("ClassicLFR_HardwareAPIDialog")
				if popup_frame then
					popup_frame:Hide()
					resume_1()
				end
			end
		end
		name_onenterpressed = function(self)
			if self:GetText():find(keyword) then
				local popup_name,popup_frame = StaticPopup_Visible("ClassicLFR_HardwareAPIDialog")
				if popup_frame then
					popup_frame:Hide()
					resume_1()
				end
			end
		end
	else
		await_search_result=function(resultid,leader)
			if leader then
				return resultid
			end
			for timeout=1,10 do
				local info = C_LFGList.GetSearchResultInfo(resultid)
				if not info or info.isDelisted then
					return
				end
				if info.leaderName then
					return resultid
				end
				local current = coroutine.running()
				local timer = C_Timer.NewTimer(0.1, function()
					ClassicLFR.resume(current)
				end)
				ClassicLFR:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED",function(_,resultID)
					if resultid == resultID then
						ClassicLFR.resume(current,true)
					end
				end)
				coroutine.yield()
				ClassicLFR:UnregisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED")
				timer:Cancel()
			end
		end
		name_onenterpressed = function(self)
			if self:GetText():len()~=0 then
				local popup_name,popup_frame = StaticPopup_Visible("ClassicLFR_HardwareAPIDialog")
				if popup_frame then
					popup_frame:Hide()
					resume_1()
				end
			end
		end
	end
	if delta < 0 then
		Name:SetScript("OnTextChanged",InputBoxInstructions_OnTextChanged)
		SearchBox:SetScript("OnTextChanged",SearchBoxTemplate_OnTextChanged)
	else
		if wql then
			Name:SetScript("OnTextChanged",InputBoxInstructions_OnTextChanged)
		else
			Name:SetScript("OnTextChanged",function(...)
				name_onenterpressed(...)
				InputBoxInstructions_OnTextChanged(...)
			end)
		end
		SearchBox:SetScript("OnTextChanged",function(...)
			searchbox_onenterpressed(...)
			SearchBoxTemplate_OnTextChanged(...)
		end)
	end
	Name:SetScript("OnEnterPressed",name_onenterpressed)
	SearchBox:SetScript("OnEnterPressed",searchbox_onenterpressed)
	SearchBox:SetScript("OnArrowPressed",nop)
	SearchBox:SetScript("OnTabPressed",nop)
	SearchBox:SetScript("OnEditFocusGained",SearchBoxTemplate_OnEditFocusGained)
	SearchBox:SetScript("OnEditFocusLost",SearchBoxTemplate_OnEditFocusLost)
	SearchBox.clearButton:SetScript("OnClick",C_LFGList.ClearSearchTextFields)
	if not asag then
	local error_code,count,results,iscache = hwe_api(SearchBox,name,search,C_LFGList.ClearSearchTextFields,SEARCH,true)
	if error_code or is_queueing_lfg() then
		return true
	end
	if iscache then
		secure = secure + 1
	end
	if count==0 then
		if not create then
			return true
		end
	else
		local leader,tank,healer = GetLFGRoles()
		C_LFGList.ClearApplicationTextFields()
		local function event_func(...)
			ClassicLFR.resume(current,...)
		end
		local function resume_2()
			ClassicLFR.resume(current,2)
		end
		local function resume_3()
			ClassicLFR.resume(current,3)		
		end
		local Event = ClassicLFR:GetModule("Event",true) or UIParent
		local invited = -1
		local invited_tb = {}
		local concat_tb = {}
		local oked = 0
		if not create then
			for i=1,#results do
				local id = results[i]
				local info = C_LFGList.GetSearchResultInfo(id)
				if info and not info.isDelisted then
					if info.autoAccept then
						invited_tb[i]=id
					else
						local iLvl = info.requiredItemLevel
						if math.floor(iLvl) == iLvl then
							concat_tb[i]=id
						end
					end
				end
			end
			wipe(results)
			for i=1,#concat_tb do
				results[#results+1]=concat_tb[i]
			end
			for i=1,#invited_tb do
				results[#results+1]=invited_tb[i]
			end
			wipe(invited_tb)
			wipe(concat_tb)
		end
		while #results ~= 0 and oked~=5 do
			local id = results[#results]
			local info = C_LFGList.GetSearchResultInfo(id)
			if info and not info.isDelisted and (not create or create and (raid or info.autoAccept or info.numMembers < 5)) and info.comment:len()==0 and info.voiceChat:len()==0 and info.age < 3600 then
				local iLvl = info.requiredItemLevel
				if keyword and not wql then
					if math.floor(iLvl) ~= iLvl then
						invited_tb[#invited_tb+1] = await_search_result(id,info.leaderName)
					end
				else
					if secure < 0 then
						wipe(dialog)
						wipe(concat_tb)
						concat_tb[#concat_tb+1] = info.name
						concat_tb[#concat_tb+1] = info.numMembers
						concat_tb[#concat_tb+1] = info.leaderName
						dialog.text=table.concat(concat_tb,"\n")
						dialog.button1 = SIGN_UP
						dialog.button2 = CANCEL
						dialog.timeOut = 45
						dialog.OnAccept=resume_1
						dialog.OnCancel=resume
						if #results == 1 then
							if create then
								dialog.button3 = START_A_GROUP
								dialog.OnAlt = resume_2
							end
						else
							dialog.button3 = tostring(#results)
							dialog.OnAlt = resume_2
						end
						StaticPopup_Show("ClassicLFR_HardwareAPIDialog")
						local yd,applicationid = coroutine.yield()
						if yd == 1 then
							C_LFGList.ApplyToGroup(id,tank,healer,true)
							local timer = C_Timer.NewTimer(5,resume_3)
							Event:UnregisterEvent("PARTY_INVITE_REQUEST")
							ClassicLFR:RegisterEvent("PARTY_INVITE_REQUEST",event_func)
							ClassicLFR:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED",function(event,applicationid,invited,applied)
								if invited=="invited" and applied == "applied" and applicationid == id then
									ClassicLFR.resume(current,event,applicationid)
								end
							end)
							local yd,applicationid = coroutine.yield()
							ClassicLFR:UnregisterEvent("PARTY_INVITE_REQUEST")
							ClassicLFR:UnregisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")
							Event:RegisterEvent("PARTY_INVITE_REQUEST")
							timer:Cancel()
							if yd == 3 then
								if hwe_api(nil,CANCEL_SIGN_UP,function()
									C_LFGList.CancelApplication(id)
								end) then
									return true
								end
								C_Timer.After(0.01,resume_3)
								if coroutine.yield()~=3 then
									return true
								end
							elseif yd == "PARTY_INVITE_REQUEST" then
								invited = -2
								break
							elseif yd == "LFG_LIST_APPLICATION_STATUS_UPDATED" then
								invited = applicationid
								break
							else
								return true
							end
						elseif yd == 2 then
							if #results == 1 then
								secure = 0
							else
								secure = delta
								C_Timer.After(0.01,resume_1)
								if coroutine.yield()~= 1 then
									return
								end
							end
						end
					else
						C_LFGList.ApplyToGroup(id,tank,healer,true)
						secure = delta
						oked=oked+1
					end
				end
			end
			results[#results] = nil
		end
		if #results ~= 0 or oked~=0 or #invited_tb ~= 0 then
			local lfgoked = 0
			if #invited_tb ~= 0 then
				if keyword then
					if ty_pe then
						ty_pe = ty_pe..keyword
					else
						ty_pe = keyword
					end
				end
				ClassicLFR:SendMessage("LFG_CHAT_MSG_SILENT")
				for i=1,#invited_tb do
					local info = C_LFGList.GetSearchResultInfo(invited_tb[i])
					if info and not info.isDelisted then
						SendChatMessage(ty_pe,"WHISPER",nil,info.leaderName)
						lfgoked = lfgoked + 1
					end
				end
			end
			local yd
			if #results ~=0 or oked ~= 0 or lfgoked~=0 then
				local netdown, netup, netlagHome, netlagWorld = GetNetStats()
				local timeout = math.max(netlagWorld*0.004,1)
				if lfgoked == 0 then
					timeout = math.max(timeout,15)
				end
				local timer = C_Timer.NewTimer(timeout,resume_3)
				Event:UnregisterEvent("PARTY_INVITE_REQUEST")
				ClassicLFR:RegisterEvent("PARTY_INVITE_REQUEST",event_func)
				if 0 <= delta then
					LFGListInviteDialog:UnregisterAllEvents()
					ClassicLFR:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED",function(event,applicationid,invited,applied)
						if invited=="invited" and applied == "applied" then
							C_LFGList.AcceptInvite(applicationid)
						end
					end)
				end
				ClassicLFR:RegisterEvent("LFG_LIST_JOINED_GROUP",event_func)
				ClassicLFR:RegisterEvent("GROUP_JOINED",event_func)
				if invited == -2 then
					AcceptGroup()
				end
				yd = coroutine.yield()
				if yd == 3 then
					local applications = C_LFGList.GetApplications()
					for i = 1,#applications do
						local groupID, status = C_LFGList.GetApplicationInfo(applications[i])
						if status == "applied" and 0 <= delta then
							C_LFGList.CancelApplication(groupID)
						end
					end
				elseif yd == "PARTY_INVITE_REQUEST" then
					AcceptGroup()
					timer:Cancel()
					yd = coroutine.yield()
				end
				timer:Cancel()
			end
			ClassicLFR:UnregisterEvent("GROUP_JOINED")
			ClassicLFR:UnregisterEvent("LFG_LIST_JOINED_GROUP")
			ClassicLFR:UnregisterEvent("PARTY_INVITE_REQUEST")
			ClassicLFR:UnregisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")
			LFGListInviteDialog_OnLoad(LFGListInviteDialog)
			LFGListInviteDialog:UnregisterEvent("LFG_LIST_JOINED_GROUP")
			Event:RegisterEvent("PARTY_INVITE_REQUEST")
			ClassicLFR:SendMessage("LFG_CHAT_MSG_UNSILENT")
			if yd == "GROUP_JOINED" or yd == "LFG_LIST_JOINED_GROUP" then
				if not IsInGroup() then
					ClassicLFR:SendMessage("LFG_CHAT_MSG_SILENT")
					ClassicLFR:RegisterEvent("GROUP_ROSTER_UPDATE",resume)
					local ticker = C_Timer.NewTicker(0.01,resume)
					repeat
						coroutine.yield()
					until IsInGroup()
					ticker:Cancel()
					ClassicLFR:UnregisterEvent("GROUP_ROSTER_UPDATE")
					ClassicLFR:SendMessage("LFG_CHAT_MSG_UNSILENT")
				end
				if IsInRaid() then
					local could_do_in_raid = raid
					if C_LFGList.HasActiveEntryInfo() then
						local entryinfo = C_LFGList.GetActiveEntryInfo()
						if entryinfo.autoAccept then
							could_do_in_raid = true
						end
					end
					if could_do_in_raid then
						local UnitClass = UnitClass
						local UnitLevel = UnitLevel
						local select = select
						local is_spam_group
						local require_pause = true
						local UnitHealthMax = UnitHealthMax
						ClassicLFR:SendMessage("LFG_CHAT_MSG_SILENT")
						while require_pause do
							require_pause = nil
							for i=1,GetNumGroupMembers() do
								local unit = "raid"..i
								local level  = UnitLevel(unit)
								if level == 0 then
									require_pause = true
									break
								elseif level == 120 and UnitHealthMax(unit) < 25000 or level < 60 and select(3,UnitClass(unit)) == 6 then
									is_spam_group = true
									break
								end
							end
							if require_pause then
								ClassicLFR:RegisterEvent("GROUP_ROSTER_UPDATE",resume)
								local timer = C_Timer.NewTimer(0.01,resume)
								coroutine.yield()
								timer:Cancel()
								ClassicLFR:UnregisterEvent("GROUP_ROSTER_UPDATE")
							end
						end
						ClassicLFR:SendMessage("LFG_CHAT_MSG_UNSILENT")
						if not is_spam_group then
							return
						end
					end
					LeaveParty()
				else
					return
				end
			end
		end
	end
	end
	if asag~=false then
		if 0 <= delta then
			local pause = {}
			local applications = C_LFGList.GetApplications()
			for i = 1,#applications do
				local groupID, status = C_LFGList.GetApplicationInfo(applications[i])
				if status == "applied" then
					C_LFGList.CancelApplication(groupID)
					pause[groupID] = true
				end
			end
			if next(pause) then
				local timer = C_Timer.NewTimer(3,function()
					ClassicLFR.resume(current)
				end)
				ClassicLFR:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED",function(event,applicationid,invited,applied)
					if invited~="applied" then
						pause[applicationid] = nil
						if next(pause) == nil then
							ClassicLFR.resume(current)
						end
					end
				end)
				coroutine.yield()
				timer:Cancel()
				ClassicLFR:UnregisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")
			end
		end
		return hwe_api(Name,name,create,C_LFGList.ClearCreationTextFields,START_A_GROUP)
	end
end

function ClassicLFR.autoloop(name,create,raid,keyword,ty_pe,in_range)
	ClassicLFR:SendMessage("LFG_AUTO_MAIN_LOOP",keyword)
	local current = coroutine.running()
	local profile = ClassicLFR.db.profile
	local function event_func(...)
		ClassicLFR.resume(current,...)
	end
	ClassicLFR:UnregisterEvent("GROUP_ROSTER_UPDATE")
	ClassicLFR:RegisterEvent("LFG_LIST_ENTRY_EXPIRED_TOO_MANY_PLAYERS",event_func)
	local ticker
	if in_range and not profile.auto_kick then
		ticker = C_Timer.NewTicker(1,function()
			event_func(19)
		end)
	end
	ClassicLFR:RegisterEvent("GROUP_LEFT",event_func)
	ClassicLFR:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE",event_func)
	local Event = ClassicLFR:GetModule("Event",true) or LFGListFrame
	Event:UnregisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED")
	Event:UnregisterEvent("LFG_LIST_APPLICANT_UPDATED")
	local player_list
	local original_tp = ty_pe
	local invited_tb
	if not profile.auto_addons_wqt and in_range then
		invited_tb = {}
	end
	if keyword then
		if profile.auto_addons_wql then
			ClassicLFR:RegisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED",event_func)
		end
		ClassicLFR:RegisterEvent("CHAT_MSG_WHISPER",event_func)
		if ty_pe then
			ty_pe = ty_pe..keyword
		else
			ty_pe = keyword
		end
		player_list = {}
	else
		ClassicLFR:RegisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED",event_func)
	end
	
	local must
	while true do
		local k,gpl,arg3,arg4,arg5,arg6 = coroutine.yield()
		if is_queueing_lfg() or k == "GROUP_LEFT" or not IsInGroup() then
			break
		elseif k == 0 or k == 1 then
			local hardware = profile.hardware
			if not hardware then
				local CancelApplication = C_LFGList.CancelApplication
				local DeclineInvite = C_LFGList.DeclineInvite
				local GetApplicationInfo = C_LFGList.GetApplicationInfo
				local temp = C_LFGList.GetApplications()
				for i=1,#temp do
					local groupID, status = GetApplicationInfo(temp[i])
					if status == "invited" then
						DeclineInvite(groupID)
					else
						CancelApplication(groupID)
					end
				end
			end			
			local nm = GetNumGroupMembers()
			local auto_leave_party = profile.auto_leave_party
			if nm == 0 or (k == 0 and (nm == 1 or (not gpl and auto_leave_party))) then
				LeaveParty()
			elseif k == 0 and gpl and not hardware then
				C_LFGList.RemoveListing()
			else
				wipe(dialog)
				dialog.button1=ACCEPT
				dialog.button2=CANCEL
				dialog.timeOut=45
				dialog.whileDead = true
				dialog.text=PARTY_LEAVE
				dialog.OnAccept=LeaveParty
				if C_LFGList.HasActiveEntryInfo() and UnitIsGroupLeader("player") then
					dialog.button3=UNLIST_MY_GROUP
					dialog.OnAlt=function()
						C_LFGList.RemoveListing()
						event_func("GROUP_LEFT")
					end
				end
				StaticPopup_Show("ClassicLFR_HardwareAPIDialog")
			end
			if k == 0 then
				break
			end
		elseif k == 3 then
			StaticPopup_Hide("ClassicLFR_HardwareAPIDialog")
			wipe(dialog)
		elseif k == "LFG_LIST_ENTRY_EXPIRED_TOO_MANY_PLAYERS" then
			ClassicLFR:UnregisterEvent("LFG_LIST_ENTRY_EXPIRED_TOO_MANY_PLAYERS")
			ClassicLFR:RegisterEvent("GROUP_ROSTER_UPDATE",event_func)
		elseif k == "GROUP_ROSTER_UPDATE" then
			local nm = GetNumGroupMembers()
			if nm ~= 0 and nm ~= 5 and nm ~= 40 and UnitIsGroupLeader("player") then
				ClassicLFR:UnregisterEvent("GROUP_ROSTER_UPDATE")
				ClassicLFR:RegisterEvent("LFG_LIST_ENTRY_EXPIRED_TOO_MANY_PLAYERS",event_func)
				if profile.hardware then
					wipe(dialog)
					dialog.button1=START_A_GROUP
					dialog.button2=CANCEL
					dialog.text=name
					dialog.timeOut=45
					dialog.OnAccept=create
					StaticPopup_Show("ClassicLFR_HardwareAPIDialog")
				else
					create()
				end
			end
		elseif k == "LFG_LIST_ACTIVE_ENTRY_UPDATE" then
			if C_LFGList.HasActiveEntryInfo() then
				if must then
					local now = C_LFGList.GetActiveEntryInfo()
					if now.autoAccept ~= must.autoAccept or now.activityID ~= must.activityID or now.questID ~= must.questID then
						local isleader = UnitIsGroupLeader("player")
						if isleader and not profile.hardware and must.autoAccept and must.questID then
							C_LFGList.RemoveListing()
						end
						local quitmessage = "<LFG>ClassicLFR插件已经检测到该团为广告团，请所有人立即退团，防止被工作室举报误封!"
						if UnitInRaid() then
							local assist = isleader and UnitIsGroupAssistant("player")
							SendChatMessage(quitmessage,assist and "RAID_WARNING" or "RAID")
						else
							SendChatMessage(quitmessage,"PARTY")
						end
						LeaveParty()
						break
					end
				else
					must = C_LFGList.GetActiveEntryInfo()
					if UnitIsGroupLeader("player") and not profile.auto_convert_to_raid then
						if C_LFGList.CanActiveEntryUseAutoAccept() or raid then
							ConvertToRaid()
						else
							ConvertToParty()
						end
					end
				end
			end
		elseif k == "LFG_LIST_APPLICANT_LIST_UPDATED" then
			if UnitIsGroupLeader("player") then
				if ( C_LFGList.CanActiveEntryUseAutoAccept() or raid) and not profile.auto_convert_to_raid then
					ConvertToRaid()
				end
				if C_LFGList.HasActiveEntryInfo() and (raid or GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) + C_LFGList.GetNumInvitedApplicantMembers() + C_LFGList.GetNumPendingApplicantMembers() < 6) then
					local app = C_LFGList.GetApplicants()
					local C_LFGList_GetApplicantInfo = C_LFGList.GetApplicantInfo
					local InviteUnit = InviteUnit
					local C_LFGList_GetApplicantMemberInfo = C_LFGList.GetApplicantMemberInfo
					local InviteApplicant = C_LFGList.InviteApplicant
					local hardware = profile.hardware
					for i=1,#app do
						local info = C_LFGList_GetApplicantInfo(app[i])
						if info.applicationStatus == "applied" and info.isNew then
							if hardware then
								local name = C_LFGList_GetApplicantMemberInfo(info.applicantID,1)
								InviteUnit(name)
							else
								InviteApplicant(info.applicantID)
							end
						end
					end
				end
			end
		elseif k == "CHAT_MSG_WHISPER" then
			if UnitIsGroupLeader("player") and gpl == ty_pe and (not player_list[arg3] or player_list[arg3] + 30 < GetTime() ) and (raid or GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) + C_LFGList.GetNumInvitedApplicantMembers() < 6) then
				player_list[arg3] = GetTime()
				InviteUnit(arg3)
			end
		elseif k == 11 then
			if not IsInInstance() then
				LeaveParty()
			end
		elseif k == 19 or k == 20 then
			if in_range() and IsInGroup() and (UnitIsGroupLeader("player") or UnitIsGroupAssistant('player')) then
				local UnitExists = UnitExists
				local UnitIsConnected = UnitIsConnected
				local UnitIsVisible = UnitIsVisible
				local UnitIsUnit = UnitIsUnit
				local u = UnitInRaid("player") and "raid" or "party"
				local UnitDistanceSquared = UnitDistanceSquared
				local UnitGUID = UnitGUID
				if k == 19 then
					local n = GetNumGroupMembers()
					if invited_tb and not IsResting() and n ~= 40 then
						for i = 1, (u=="party" and n-1 or n) do
							local unit = u..i
							if not UnitIsUnit("player",unit) then
								invited_tb[UnitGUID(unit)] = true
							end
						end
						local gtime = GetTime()
						local counter = 0
						local type = type
						for k,v in pairs(invited_tb) do
							if type(v)=="number" then
								if v + 30 < gtime then
									invited_tb[k] = false
								else
									counter = counter + 1
								end
							end
						end
						if C_LFGList.CanActiveEntryUseAutoAccept() or raid then
							counter = -1
						elseif 5 <= n+counter then
							counter = 0
						else
							counter = 5-n-counter
						end
						local UnitIsPlayer = UnitIsPlayer
						local UnitIsFriend = UnitIsFriend
						local UnitOnTaxi = UnitOnTaxi
						local UnitAffectingCombat = UnitAffectingCombat
						for i = 1, 256 do
							if counter == 0 then
								break
							end
							local u = "nameplate"..i
							local guid = UnitGUID(u)
							if guid and not invited_tb[guid] and UnitIsPlayer(u) and UnitIsFriend(u,"player") and not UnitOnTaxi(u) and UnitAffectingCombat(u) then
								invited_tb[guid] = gtime
								local name,server = UnitFullName(u)
								if name then
									if server then
										InviteUnit(name.."-"..server)
									else
										InviteUnit(name)
									end
									counter = counter - 1
								end
							end
						end
					end
					if (not (C_LFGList.CanActiveEntryUseAutoAccept() or raid)) and 5 < n then
						if not StaticPopup_Visible("ClassicLFR_HardwareAPIDialog") then
							wipe(dialog)
							dialog.button2=CANCEL
							dialog.button1=OKAY
							dialog.text="Kick"
							dialog.timeOut=45
							dialog.OnAccept=function()
								event_func(20)
							end
							StaticPopup_Show("ClassicLFR_HardwareAPIDialog")
						end
					else
						local i = 1
						while (i<=n) do
							local unit = u .. i
							local distance = UnitDistanceSquared(unit)
							if not UnitIsUnit("player",unit) and UnitExists(unit) and (not UnitIsConnected(unit) or (not distance or 1000000 < distance)) then
								if not StaticPopup_Visible("ClassicLFR_HardwareAPIDialog") then
									wipe(dialog)
									local name,server = UnitName(unit)
									dialog.button2=CANCEL
									if name then
										dialog.button1="Kick"
										dialog.text = table.concat({name,server},'-')
									else
										dialog.button1=OKAY
										dialog.text="Kick"
									end
									dialog.timeOut=45
									dialog.OnAccept=function()
										event_func(20)
									end
									dialog.OnCancel=function()
										if ticker then ticker:Cancel() end
									end
									StaticPopup_Show("ClassicLFR_HardwareAPIDialog")
								end
								break
							end
							i = i + 1
						end
					end
				else
					local u = UnitInRaid("player") and "raid" or "party"
					local n = GetNumGroupMembers() 
					for i = 1, n do
						local unit = u .. i
						local distance = UnitDistanceSquared(unit)
						if not UnitIsUnit("player",unit) and UnitExists(unit) and (not UnitIsConnected(unit) or (not distance or 250000 < distance)) then
							UninviteUnit(unit)
							break
						end
					end
					if not (C_LFGList.CanActiveEntryUseAutoAccept() or raid) and IsInRaid() then
						for i=6,n do
							UninviteUnit(u .. i)
						end
						ConvertToParty()
					end
				end
			end
		else
			break
		end
	end
	wipe(dialog)
	StaticPopup_Hide("ClassicLFR_HardwareAPIDialog")
	Event:RegisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED")
	Event:RegisterEvent("LFG_LIST_APPLICANT_UPDATED")
	ClassicLFR:UnregisterEvent("GROUP_LEFT")
	ClassicLFR:UnregisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
	ClassicLFR:UnregisterEvent("CHAT_MSG_WHISPER")
	ClassicLFR:UnregisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED")
	ClassicLFR:UnregisterEvent("LFG_LIST_ENTRY_EXPIRED_TOO_MANY_PLAYERS")
	ClassicLFR:UnregisterEvent("GROUP_ROSTER_UPDATE")
	if ticker then ticker:Cancel() end
end
