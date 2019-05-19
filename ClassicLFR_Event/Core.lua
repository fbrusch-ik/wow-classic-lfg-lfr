local ClassicLFR = LibStub("AceAddon-3.0"):GetAddon("ClassicLFR")
local Event = ClassicLFR:NewModule("Event","AceEvent-3.0")

--------------------------------------------------------------------------------------

function Event:OnInitialize()
end

function Event:OnEnable()
	self:RegisterEvent("ADDON_ACTION_BLOCKED")
	self:RegisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED")
	self:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
	self:RegisterEvent("LFG_LIST_APPLICANT_UPDATED")
	self:RegisterEvent("PARTY_INVITE_REQUEST")
	local LFGListFrame = LFGListFrame
	LFGListFrame:UnregisterAllEvents();
	LFGListFrame:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED");
	UIParent:UnregisterEvent("PARTY_INVITE_REQUEST")
	LFGListFrame:Hide()
	local profile = ClassicLFR.db.profile
	if not profile.spam_filter_community then
		local frames = {GetFramesRegisteredForEvent("CLUB_INVITATION_ADDED_FOR_SELF")}
		for i=1,#frames do
			frames[i]:UnregisterEvent("CLUB_INVITATION_ADDED_FOR_SELF")
		end
	end
	if profile.disable_quick_join then
		local frames = {GetFramesRegisteredForEvent("SOCIAL_QUEUE_UPDATE")}
		for i=1,#frames do
			frames[i]:UnregisterEvent("SOCIAL_QUEUE_UPDATE")
		end
		FriendsTabHeaderTab2:Hide()
		QuickJoinFrame:Hide()
		QuickJoinToastButton:Hide()
		QuickJoinFrame:UnregisterAllEvents()
		QuickJoinToastButton:UnregisterAllEvents()
	end
end

function Event:LFG_LIST_APPLICANT_LIST_UPDATED(event,hasNewPending,hasNewPendingWithData,...)
	if LFGListUtil_IsEntryEmpowered() then
		local info = C_LFGList.GetActiveEntryInfo()
		if info.autoAccept then
			if ClassicLFR.db.profile.taskbar_flash then
				FlashClientIcon()
			end
		elseif not InCombatLockdown() and ( hasNewPending and hasNewPendingWithData ) then
			if not ClassicLFR.db.profile.mute and LFGListUtil_IsEntryEmpowered() then
				QueueStatusMinimapButton_SetGlowLock(QueueStatusMinimapButton, "lfglist-applicant", true)
			end
		end
	end
end

function Event:LFG_LIST_APPLICANT_UPDATED()
	if InCombatLockdown() or ( select(2,C_LFGList.GetNumApplicants()) == 0 ) then
		QueueStatusMinimapButton_SetGlowLock(QueueStatusMinimapButton, "lfglist-applicant", false)
	end
end

function Event:ADDON_ACTION_BLOCKED(info,addon,method)
	if addon:find("ClassicLFR") and (method == "Search()" or method == "resume()" or method == "UNKNOWN()") then
		local profile = ClassicLFR.db.profile
		if not profile.hardware then
			profile.hardware = true
			ClassicLFR:Print(MODE,HARDWARE)
		end
	end
end

function Event:LFG_LIST_ACTIVE_ENTRY_UPDATE(event,creatednew)
	if creatednew and not ClassicLFR.db.profile.mute then
		PlaySound(SOUNDKIT.PVP_ENTER_QUEUE)
	end
end

function Event:PARTY_INVITE_REQUEST(event, name, tank, healer, damage, isXRealm, allowMultipleRoles, inviterGuid)
	-- Color the name by our relationship
	local modifiedName, color, selfRelationship = SocialQueueUtil_GetRelationshipInfo(inviterGuid);
	if ( selfRelationship ) then
		name = color..name..FONT_COLOR_CODE_CLOSE;
	elseif not ClassicLFR.db.profile.sf_invite_relationship then
		DeclineGroup()
		return
	end
	-- if there's a role, it's an LFG invite
	if ( tank or healer or damage ) then
		StaticPopupSpecial_Show(LFGInvitePopup);
		LFGInvitePopup_Update(name, tank, healer, damage, allowMultipleRoles);
	else
		local text = isXRealm and INVITATION_XREALM or INVITATION;
		text = string.format(text, name);

		if ( WillAcceptInviteRemoveQueues() ) then
			text = text.."\n\n"..ACCEPTING_INVITE_WILL_REMOVE_QUEUE;
		end
		StaticPopup_Show("PARTY_INVITE", text);
	end
end
