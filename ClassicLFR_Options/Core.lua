local AceAddon = LibStub("AceAddon-3.0")
local ClassicLFR = AceAddon:GetAddon("ClassicLFR")
local ClassicLFR_Options = AceAddon:GetAddon("ClassicLFR_Options")

function ClassicLFR_Options:OnEnable()
	local options = ClassicLFR_Options.option_table
	LibStub("AceConfig-3.0"):RegisterOptionsTable("ClassicLFR", options)
	options.args.find.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(ClassicLFR_Options.db)
	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
	local GetAddOnMetadata = GetAddOnMetadata
	local GetAddOnInfo = GetAddOnInfo
	local region = GetCurrentRegion()
	for i = 1, GetNumAddOns() do
		local metadata = GetAddOnMetadata(i, "X-LFG-OPT")
		if metadata and (metadata == "0" or region == tonumber(metadata)) then
			LoadAddOn(i)
		end
	end
	self:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
--	self:RegisterEvent("LFG_LIST_APPLICANT_UPDATED")
--	self:RegisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED","LFG_LIST_APPLICANT_UPDATED")
	self:RegisterMessage("LFG_UPDATE_EDITING")
	self:RegisterMessage("LFG_ICON_LEFT_CLICK")
	self:RegisterMessage("LFG_ChatCommand")
	self:RegisterMessage("LFG_AUTO_MAIN_LOOP")
	if C_LFGList.HasActiveEntryInfo() then
		coroutine.wrap(ClassicLFR_Options.req_main)()
	end
	C_Timer.After(0.01,function()
		ClassicLFR_Options:OnProfileChanged()
		ClassicLFR_Options.NotifyChangeIfSelected("find")
	end)
end

function ClassicLFR_Options.IsSelected(groupname)
	local status_table = LibStub("AceConfigDialog-3.0"):GetStatusTable("ClassicLFR")
	if status_table.groups and status_table.groups.selected == groupname then
		return true
	end
end

function ClassicLFR_Options.NotifyChangeIfSelected(groupname)
	if ClassicLFR_Options.IsSelected(groupname) then
		LibStub("AceConfigRegistry-3.0"):NotifyChange("ClassicLFR")
		return true
	end
end

function ClassicLFR_Options:OnProfileChanged()
	local st = LibStub("AceConfigDialog-3.0"):GetStatusTable("ClassicLFR")
	local profile = self.db.profile
	st.height,st.width = profile.window_height,profile.window_width
	self:SendMessage("LFG_OPT_CATEGORY",self.option_table.args.find.args,self.db.profile.a.category)
	self:SendMessage("LFG_OPT_DBUpdate")
end

function ClassicLFR_Options:LFG_ChatCommand(message,input)
	if not input or input:trim() == "" then
		LibStub("AceConfigDialog-3.0"):Open("ClassicLFR")
	else
		LibStub("AceConfigCmd-3.0"):HandleCommand("ClassicLFR", "ClassicLFR",input)
	end
end

function ClassicLFR_Options:LFG_ICON_LEFT_CLICK(message,para,...)
	local AceConfigDialog = LibStub("AceConfigDialog-3.0")
	if AceConfigDialog.OpenFrames.ClassicLFR then
		AceConfigDialog:Close("ClassicLFR")
	else
		if para then
			AceConfigDialog:SelectGroup(para,...)
		end
		AceConfigDialog:Open("ClassicLFR")
	end
end

function ClassicLFR_Options:LFG_UPDATE_EDITING()
	self.update_editing()
	PVEFrame:Hide()
	local AceConfigDialog = LibStub("AceConfigDialog-3.0")
	AceConfigDialog:SelectGroup("ClassicLFR","find","s")
	AceConfigDialog:Open("ClassicLFR")
end
