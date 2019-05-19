local ClassicLFR = LibStub("AceAddon-3.0"):GetAddon("ClassicLFR")
local Hook = ClassicLFR:NewModule("Hook","AceHook-3.0")

--------------------------------------------------------------------------------------

function Hook:OnInitialize()
end

function Hook:OnEnable()
	local profile = ClassicLFR.db.profile
	self:RawHook("QueueStatusDropDown_AddLFGListButtons",true)
	self:RawHook("QueueStatusEntry_SetUpLFGListApplication",true)
	self:RawHook("QueueStatusEntry_SetUpLFGListActiveEntry",true)
	self:RawHook("LFGListInviteDialog_Show",true)
	self:RawHook("LFGListUtil_OpenBestWindow",true)
	self:RawHook("LFGListUtil_FindQuestGroup",true)
	self:RawHookScript(LFGListApplicationDialog.SignUpButton,"OnClick","LFGListApplicationDialog_SignUpButton_OnClick")
	self:SecureHook("QuestObjectiveSetupBlockButton_FindGroup")
	self:SecureHook("GroupFinderFrame_SelectGroupButton")
	self:SecureHook("QuestObjectiveFindGroup_OnEnter")
end

function Hook:LFGListUtil_OpenBestWindow()
	ClassicLFR:SendMessage("LFG_ICON_LEFT_CLICK","ClassicLFR","requests")
end

function Hook:QueueStatusDropDown_AddLFGListButtons()
	local info = UIDropDownMenu_CreateInfo()
	if UnitIsGroupLeader("player") then
		info.text = EDIT
	else
		info.text = VIEW
	end
	info.func = function()
		ClassicLFR:SendMessage("LFG_UPDATE_EDITING")
	end
	info.notCheckable = 1
	UIDropDownMenu_AddButton(info)
	info.text = LFG_LIST_VIEW_GROUP
	info.func = LFGListUtil_OpenBestWindow
	UIDropDownMenu_AddButton(info)
	if UnitIsGroupLeader("player") then
		info.text = UNLIST_MY_GROUP
		info.func = C_LFGList.RemoveListing
		UIDropDownMenu_AddButton(info)
	end
end
local concat_tb = {}

function Hook:QueueStatusEntry_SetUpLFGListApplication(entry,resultID)
	local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)
	wipe(concat_tb)
	local member_counts = C_LFGList.GetSearchResultMemberCounts(resultID)
	concat_tb[#concat_tb+1] = C_LFGList.GetActivityInfo(searchResultInfo.activityID)
	concat_tb[#concat_tb+1] = "\n|cff00ffff"
	concat_tb[#concat_tb+1] = numMembers
	concat_tb[#concat_tb+1] = "("
	concat_tb[#concat_tb+1] = member_counts.TANK
	concat_tb[#concat_tb+1] = "/"
	concat_tb[#concat_tb+1] = member_counts.HEALER
	concat_tb[#concat_tb+1] = "/"
	concat_tb[#concat_tb+1] = member_counts.DAMAGER + member_counts.NOROLE
	concat_tb[#concat_tb+1] = ")|r"
	QueueStatusEntry_SetMinimalDisplay(entry,searchResultInfo.name,QUEUE_STATUS_SIGNED_UP,table.concat(concat_tb))
	wipe(concat_tb)
end

function Hook:QueueStatusEntry_SetUpLFGListActiveEntry(entry)
	local activeEntryInfo = C_LFGList.GetActiveEntryInfo();
	local activityName = C_LFGList.GetActivityInfo(activeEntryInfo.activityID)
	wipe(concat_tb)
	concat_tb[#concat_tb+1] = "|cff8080cc"
	concat_tb[#concat_tb+1] = activityName
	concat_tb[#concat_tb+1] ="|r\n"
	local numApplicants,numActiveApplicants = C_LFGList.GetNumApplicants()
	concat_tb[#concat_tb+1] = LFG_LIST_PENDING_APPLICANTS:format(numActiveApplicants)
	local member_count_tb = GetGroupMemberCounts()
	local tank = member_count_tb.TANK
	local healer = member_count_tb.HEALER
	local damager = member_count_tb.DAMAGER+member_count_tb.NOROLE
	local total = tank+healer+damager
	concat_tb[#concat_tb+1]="\n|cffffffff"
	concat_tb[#concat_tb+1]=total
	concat_tb[#concat_tb+1]="("
	concat_tb[#concat_tb+1]=tank
	concat_tb[#concat_tb+1]="/"
	concat_tb[#concat_tb+1]=healer
	concat_tb[#concat_tb+1]="/"
	concat_tb[#concat_tb+1]=damager
	concat_tb[#concat_tb+1]=")|r"
	
	local questID, voiceChat, iLevel, comment, privateGroup,autoAccept = activeEntryInfo.questID,activeEntryInfo.voiceChat,activeEntryInfo.requiredItemLevel,activeEntryInfo.comment,activeEntryInfo.privateGroup,activeEntryInfo.autoAccept
	if questID then
		concat_tb[#concat_tb+1]="\n"
		concat_tb[#concat_tb+1]=questID
	end
	if voiceChat:len() ~= 0 then
		concat_tb[#concat_tb+1]="\n"
		concat_tb[#concat_tb+1]=LFG_LIST_VOICE_CHAT
		concat_tb[#concat_tb+1]=" |cff00ff00"
		concat_tb[#concat_tb+1]=voiceChat
		concat_tb[#concat_tb+1]="|r"
	end
	if iLevel ~= 0 then
		concat_tb[#concat_tb+1]="\n"
		concat_tb[#concat_tb+1]=ITEM_LEVEL_ABBR
		concat_tb[#concat_tb+1]=" |cffff00ff"
		concat_tb[#concat_tb+1]=iLevel
		concat_tb[#concat_tb+1]="|r"
	end
	if comment:len() ~= 0  then
		concat_tb[#concat_tb+1]="\n\n|cff8080cc"
		concat_tb[#concat_tb+1]=comment
		concat_tb[#concat_tb+1]="|r"
	end
	if privateGroup or autoAccept then
		concat_tb[#concat_tb+1]="\n"
		if privateGroup then
			concat_tb[#concat_tb+1]="\n"
			concat_tb[#concat_tb+1]=LFG_LIST_PRIVATE
		end
		if autoAccept then
			concat_tb[#concat_tb+1]="\n"
			concat_tb[#concat_tb+1]=LFG_LIST_AUTO_ACCEPT
		end
	end
	QueueStatusEntry_SetMinimalDisplay(entry,activeEntryInfo.name,QUEUE_STATUS_LISTED,table.concat(concat_tb))
	wipe(concat_tb)
end

function Hook:LFGListInviteDialog_Show(entry,resultID, kstringGroupName)
	local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID);
	local activityName = C_LFGList.GetActivityInfo(searchResultInfo.activityID);
	local _, status, _, _, role = C_LFGList.GetApplicationInfo(resultID);

	local informational = (status ~= "invited");
	assert(not informational or status == "inviteaccepted");

	entry.resultID = resultID;
	
	wipe(concat_tb)
	local member_counts = C_LFGList.GetSearchResultMemberCounts(resultID)
	concat_tb[#concat_tb+1] = activityName
	concat_tb[#concat_tb+1] = '\n|cff00ffff'
	concat_tb[#concat_tb+1] = searchResultInfo.numMembers
	concat_tb[#concat_tb+1] = "("
	concat_tb[#concat_tb+1] = member_counts.TANK
	concat_tb[#concat_tb+1] = "/"
	concat_tb[#concat_tb+1] = member_counts.HEALER
	concat_tb[#concat_tb+1] = "/"
	concat_tb[#concat_tb+1] = member_counts.DAMAGER + member_counts.NOROLE
	concat_tb[#concat_tb+1] = ")|r"

	if autoaccept and leaderName then
		local realm = leaderName:match("-(.*)$")
		if realm then
			concat_tb[#concat_tb+1] = "\n"
			concat_tb[#concat_tb+1] = FRIENDS_LIST_REALM
			concat_tb[#concat_tb+1] = realm
		end
	end
	entry.GroupName:SetText(kstringGroupName or searchResultInfo.name);
	entry.ActivityName:SetText(table.concat(concat_tb));
	entry.Role:SetText(_G[role]);
	entry.RoleIcon:SetTexCoord(GetTexCoordsForRole(role));
	entry.Label:SetText(informational and LFG_LIST_JOINED_GROUP_NOTICE or LFG_LIST_INVITED_TO_GROUP);

	entry.informational = informational;
	entry.AcceptButton:SetShown(not informational);
	entry.DeclineButton:SetShown(not informational);
	entry.AcknowledgeButton:SetShown(informational);

	if ( not informational and GroupHasOfflineMember(LE_PARTY_CATEGORY_HOME) ) then
		entry:SetHeight(250);
		entry.OfflineNotice:Show();
		LFGListInviteDialog_UpdateOfflineNotice(entry);
	else
		entry:SetHeight(210);
		entry.OfflineNotice:Hide();
	end

	StaticPopupSpecial_Show(entry);

	local profile = ClassicLFR.db.profile
	if not profile.mute then
		PlaySound(SOUNDKIT.READY_CHECK);
	end
	if profile.taskbar_flash then
		FlashClientIcon();
	end
end

function Hook:LFGListApplicationDialog_SignUpButton_OnClick(obj) --bfa
	local dialog = obj:GetParent();
	if not ClassicLFR.db.profile.mute then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	end
	local results = dialog.resultID
	local results_type = type(results)
	if results_type == "number" then
		C_LFGList.ApplyToGroup(results,select(2,GetLFGRoles()));
	elseif results_type == "function" then
		results()
	end
	StaticPopupSpecial_Hide(dialog)
end

function Hook:QuestObjectiveSetupBlockButton_FindGroup(block, questID)
	if ClassicLFR.db.profile.auto_no_info_quest and not C_TaskQuest.GetQuestInfoByQuestID(questID) then
		QuestObjectiveReleaseBlockButton_FindGroup(block)
		return
	end
	block.hasGroupFinderButton = true
	local groupFinderButton = block.groupFinderButton;
	if not groupFinderButton then
		groupFinderButton = QuestObjectiveFindGroup_AcquireButton(block, questID);
		block.groupFinderButton = groupFinderButton;
	end
	QuestObjectiveSetupBlockButton_AddRightButton(block, groupFinderButton, block.module.buttonOffsets.groupFinder);
end

function Hook:GroupFinderFrame_SelectGroupButton(index)
	if index == 4 then
		ClassicLFR:SendMessage("LFG_ICON_LEFT_CLICK")
	end
end

function Hook:LFGListUtil_FindQuestGroup(questID,button)
	if not IsInInstance() and not ClassicLFR:loadevent("ClassicLFR_Q","LFG_SECURE_QUEST_ACCEPTED",questID,button and GetMouseButtonClicked()=="RightButton") then
		ClassicLFR:Print("ClassicLFR_Q failed to load")
	end
end

function Hook:QuestObjectiveFindGroup_OnEnter(button)
	button:RegisterForClicks("AnyUp")
end
