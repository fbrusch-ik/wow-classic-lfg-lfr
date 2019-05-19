local ClassicLFR = LibStub("AceAddon-3.0"):GetAddon("ClassicLFR")
local ClassicLFR_Options = LibStub("AceAddon-3.0"):GetAddon("ClassicLFR_Options")

function ClassicLFR_Options.req_main(auto_accept,filters,back_list,invite_provider,dialogControl)
	filters = filters or {"s","f"}
	local app_tb = {}
	ClassicLFR_Options.applicants = app_tb
	local current = coroutine.running()
	local app = {}
	local b =
	{
		type = "multiselect",
		width = "full",
		dialogControl = dialogControl or "lfg_opt_rq_default_multiselect",
		values = app,
		name = nop
	}
	local a =
	{
		type = "group",
		order = 5,
		args =
		{
			applicant_list = b
		}
	}
	local function event_func(...)
		ClassicLFR.resume(current,...)
	end
	local to_list = not C_LFGList.HasActiveEntryInfo()
	if to_list then
		ClassicLFR_Options:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE",event_func)
		ClassicLFR_Options:RegisterEvent("LFG_LIST_ENTRY_CREATION_FAILED",event_func)
		local yd = coroutine.yield()
		if yd == "LFG_LIST_ENTRY_CREATION_FAILED" then
			ClassicLFR_Options.expected(FAILED..": LFG_LIST_ENTRY_CREATION_FAILED")
			ClassicLFR_Options:UnregisterEvent("LFG_LIST_ENTRY_CREATION_FAILED")
			ClassicLFR_Options:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
			return
		end
	end
--	local whisper_text
	if auto_accept ~= 1 then
		ClassicLFR_Options.option_table.args.requests =
		{
			name = LFGUILD_TAB_REQUESTS_NONE,
			type = "group",
			childGroups = "tab",
			args =
			{
				apply =
				{
					name = APPLY,
					type = "execute",
					order = 1,
					func = function()
						ClassicLFR.resume(current,1)
					end,
					width = 0.667
				},
				delist = 
				{
					order = 2,
					name = UNLIST_MY_GROUP,
					type = "execute",
					func = function()
						ClassicLFR.resume(current,0)
					end
				},
				autoaccept = auto_accept ~= 0 and 
				{
					order = 3,
					name = LFG_LIST_AUTO_ACCEPT,
					type = "toggle",
					get = function()
						if C_LFGList.CanActiveEntryUseAutoAccept() then
							return C_LFGList.GetActiveEntryInfo().autoAccept
						else
							return auto_accept
						end
					end,
					set = function(_,val)
						if LFGListUtil_IsEntryEmpowered() then
							if C_LFGList.CanActiveEntryUseAutoAccept() then
								local info = C_LFGList.GetActiveEntryInfo()				
								C_LFGList.UpdateListing(info.activityID,info.requiredItemLevel,info.requiredHonorLevel,val,info.privateGroup,info.questID)
							else
								auto_accept = val
							end
						end
					end,
					width = 0.667
				} or nil,
--[[				whisper=
				{
					order = 4,
					name = WHISPER,
					type = "input",
					get = function()
						return whisper_text
					end,
					set = function(_,val)
						if val:len()==0 then
							whisper_text = nil
						else
							whisper_text = val
						end
					end,
					width = "full"
				},]]
				applicants = a
			}
		}
		if auto_accept == 0 then
			auto_accept = nil
		end
		local AceConfigDialog = LibStub("AceConfigDialog-3.0")
		if to_list then
			AceConfigDialog:SelectGroup("ClassicLFR","requests")
		else
			LibStub("AceConfigRegistry-3.0"):NotifyChange("ClassicLFR")
		end
	end
	local event = ClassicLFR:GetModule("Event",true) or LFGListFrame
	event:UnregisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED")
	event:UnregisterEvent("LFG_LIST_APPLICANT_UPDATED")
	if auto_accept == 1 then
		auto_accept = nil
	else
		ClassicLFR_Options:RegisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED",event_func)
		ClassicLFR_Options:RegisterEvent("LFG_LIST_APPLICANT_UPDATED",event_func)
	end
	ClassicLFR_Options:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE",event_func)
	local profile = ClassicLFR.db.profile
	local hardware = profile.hardware
	local mute = profile.mute
	local taskbar_flash = profile.taskbar_flash
	local yd,arg1,arg2 = "LFG_LIST_APPLICANT_UPDATED"
	local concat = {}
	local InviteApplicant = (invite_provider or C_LFGList).InviteApplicant
	local relist_timer
	while true do
		local entryinfo = C_LFGList.GetActiveEntryInfo()
		if not entryinfo then
			break
		end
		if not hardware then
			local duration = entryinfo.duration
			local expr = duration - 60
			if duration < 0 then
				expr = 1
			end
			if relist_timer then
				relist_timer:Cancel()
			end
			relist_timer=C_Timer.NewTimer(expr,function()
				ClassicLFR.resume(current,"LFG_Relist_Timer")
			end) 
		end
		if yd == 0 then
			if LFGListUtil_IsEntryEmpowered() then
				C_LFGList.RemoveListing()
			end
		elseif yd == 1 then
			if LFGListUtil_IsEntryEmpowered() then
				if hardware then
					local k,v = next(app_tb)
					if k then
						if v then
							InviteApplicant(k)
						elseif v == false then
							C_LFGList.DeclineApplicant(k)
						end
						app_tb[k]=nil
					end
				else
					for k,v in pairs(app_tb) do
						if v then
							InviteApplicant(k)
						elseif v == false then
							C_LFGList.DeclineApplicant(k)
						end
					end
				end
			end
		elseif yd=="LFG_Relist_Timer" then
			C_LFGList.UpdateListing(entryinfo.activityID,entryinfo.requiredItemLevel,entryinfo.requiredHonorLevel,entryinfo.autoAccept,entryinfo.privateGroup,entryinfo.questID)
		else
			wipe(app)
			local ap = C_LFGList.GetApplicants()
			local C_LFGList_GetApplicantInfo = C_LFGList.GetApplicantInfo
			if ap then
				local exf = ClassicLFR_Options.ExecuteApplicantFilter
				local ivt = 0
				local apl = 0
				for i=1,#ap do
					local info = C_LFGList_GetApplicantInfo(ap[i])
					local id = info.applicantID
					local status = info.applicationStatus
					if status == "invited" then
						app[#app+1] = id
						ivt = ivt + 1
					elseif status == "applied" and exf(id,filters) then
						app[#app+1] = id
						apl = apl + 1
					end
				end
				wipe(concat)
				concat[#concat+1] = apl
				concat[#concat+1] = '/'
				concat[#concat+1] = ivt
				concat[#concat+1] = '/'
				concat[#concat+1] = #app
				concat[#concat+1] = '/'
				local numApplicants,numActiveApplicants = C_LFGList.GetNumApplicants()
				concat[#concat+1] = numActiveApplicants
				a.name = table.concat(concat)
			else
				a.name = nop
			end
			if mute or InCombatLockdown() or not LFGListUtil_IsEntryEmpowered() or #app == 0 then
				QueueStatusMinimapButton_SetGlowLock(QueueStatusMinimapButton, "lfglist-applicant", false)
			elseif yd == "LFG_LIST_APPLICANT_LIST_UPDATED" and ( arg1 and arg2 ) and not entryinfo.autoAccept and not auto_accept then
				QueueStatusMinimapButton_SetGlowLock(QueueStatusMinimapButton, "lfglist-applicant", true)
			end
			ClassicLFR_Options.NotifyChangeIfSelected("requests")
			if taskbar_flash then
				FlashClientIcon()
			end
			if not entryinfo.autoAccept and not C_LFGList.CanActiveEntryUseAutoAccept() and auto_accept then
				if invite_provider then
					local InviteApplicant = invite_provider.InviteApplicant
					for i=1,#app do
						InviteApplicant(app[i])
					end
				else
					local ok,error_msg = pcall(ClassicLFR_Options.ExecuteAutoAccept,app,filters)
					if not ok then
						ClassicLFR_Options.Paste(error_msg,nop)
					end
				end
			end
		end
		yd,arg1,arg2 = coroutine.yield()
	end
	QueueStatusMinimapButton_SetGlowLock(QueueStatusMinimapButton, "lfglist-applicant", false)
	ClassicLFR_Options:UnregisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED")
	ClassicLFR_Options:UnregisterEvent("LFG_LIST_APPLICANT_UPDATED")
	event:RegisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED")
	event:RegisterEvent("LFG_LIST_APPLICANT_UPDATED")
	ClassicLFR_Options.option_table.args.requests = nil
	if ClassicLFR_Options.IsSelected("requests") then
		local AceConfigDialog = LibStub("AceConfigDialog-3.0")
		if back_list then
			AceConfigDialog:SelectGroup("ClassicLFR",unpack(back_list))
		else
			AceConfigDialog:SelectGroup("ClassicLFR","find","s")
		end
	else
		LibStub("AceConfigRegistry-3.0"):NotifyChange("ClassicLFR")
	end
	ClassicLFR_Options:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
	if relist_timer then
		relist_timer:Cancel()
	end
end

function ClassicLFR_Options:LFG_LIST_ACTIVE_ENTRY_UPDATE(event,new)
	if new and C_LFGList.HasActiveEntryInfo() then
		coroutine.wrap(ClassicLFR_Options.req_main)()
	end
end

function ClassicLFR_Options:LFG_AUTO_MAIN_LOOP(event,keyword)
	coroutine.wrap(ClassicLFR_Options.req_main)(1)
end

local AceGUI = LibStub("AceGUI-3.0")
AceGUI:RegisterWidgetType("lfg_opt_rq_default_multiselect", function()
	local control = AceGUI:Create("InlineGroup")
	control.type = "lfg_opt_rq_default_multiselect"
	function control.OnAcquire()
		control:SetLayout("Flow")
		control.width = "fill"
		control.SetList = function(self,values)
			self.values = values
		end
		control.SetLabel = function(self,value)
			self:SetTitle(value)
		end
		control.SetDisabled = function(self,disabled)
			self.disabled = disabled
		end
		control.SetMultiselect = nop
		QueueStatusMinimapButton_SetGlowLock(QueueStatusMinimapButton, "lfglist-applicant", false)
		local app_tb = ClassicLFR_Options.applicants
		control.SetItemValue = function(self,key)
			local val = self.values[key]
			local check = AceGUI:Create("ClassicLFR_applicant_checkbox")
			check:SetUserData("val", val)
			check:updateapplicant()
			local v = app_tb[val]
			if v then
				check:SetValue(true)
			elseif v == nil then
				check:SetValue(false)
			end
			local info = C_LFGList.GetApplicantInfo(val)
			if info then
				local status = info.applicationStatus
				if status == "applied" then
					check:SetTriState(true)
					check:SetCallback("OnValueChanged",function(self,event,val)
						if LFGListUtil_IsEntryEmpowered() then
							if val == nil then
								val = false
							elseif val == false then
								val = true
							else
								val = nil
							end
							local user = self:GetUserDataTable()
							local key = user.val
							if val then
								app_tb[key] = true
							elseif val == nil then
								app_tb[key] = false
							else
								app_tb[key] = nil
							end
							check:SetValue(val)
						end
					end)
				elseif status == "invited" then
					check:SetValue(true)
					check:SetCallback("OnValueChanged",nop)
				end
				check.width = "fill"
				self:AddChild(check)
			end
		end
	end
	return AceGUI:RegisterAsContainer(control)
end , 1)
