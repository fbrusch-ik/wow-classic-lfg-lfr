local ClassicLFR = LibStub("AceAddon-3.0"):GetAddon("ClassicLFR")
local ClassicLFR_Options = LibStub("AceAddon-3.0"):GetAddon("ClassicLFR_Options")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

function ClassicLFR_Options.ApplyToGroup(lfgid,...)
	local info = C_LFGList.GetSearchResultInfo(lfgid)
	if info == nil or info.isDelisted then
		return
	end
	C_LFGList.ApplyToGroup(lfgid, ...)
	return true
end

local select_sup = {}

ClassicLFR_Options.select_sup = select_sup

function ClassicLFR_Options.make_signup(func)
	return function()
		if ClassicLFR.db.profile.role_check and next(select_sup) then
			LFGListApplicationDialog.resultID = func
			LFGListApplicationDialog_UpdateRoles(LFGListApplicationDialog)
			StaticPopupSpecial_Show(LFGListApplicationDialog)
		else
			func()
		end
	end
end

local function signup_func()
	local tank,healer,dps = select(2,GetLFGRoles())
	local ApplyToGroup = ClassicLFR_Options.ApplyToGroup
	if ClassicLFR.db.profile.hardware then
		for k,v in pairs(select_sup) do
			if v then
				select_sup[k] = nil
				if ApplyToGroup(k,tank,healer,dps) then
					return
				end
			end
		end
	else
		for k,v in pairs(select_sup) do
			if v then
				ApplyToGroup(k,tank,healer,dps)
			end
		end
	end
end

local default_signup = ClassicLFR_Options.make_signup(signup_func)

local function unregister_lfg_list_search_result_updated()
	ClassicLFR_Options:UnregisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED")
	ClassicLFR_Options:UnregisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")
end

function ClassicLFR_Options.register_lfg_list_search_result_updated(control,update)
	control.OnRelease = unregister_lfg_list_search_result_updated
	ClassicLFR_Options:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED",function(_,resultID)
		local children = control.children
		for i = 1,#children do
			local child = children[i]
			local udt = child:GetUserDataTable()
			if udt.val == resultID then
				update(child)
				return
			end
		end
		ClassicLFR_Options:SendMessage("LFG_SR_UPDATED",resultID)
	end)
	ClassicLFR_Options:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED",function(_,resultID, newStatus, oldStatus)
		local children = control.children
		for i = 1,#children do
			local child = children[i]
			local udt = child:GetUserDataTable()
			if udt.val == resultID then
				if newStatus == "applied" then
					child:SetTriState(true)
					child:SetValue(nil)
					child:SetCallback("OnValueChanged",nop)
				elseif newStatus ~= "none" then
					update(child)
				end
				return
			end
		end
		ClassicLFR_Options:SendMessage("LFG_SR_UPDATED",resultID,newStatus,oldStatus)
	end)
end

local function GetApplications()
	local applications = C_LFGList.GetApplications()
	local n = #applications
	local GetApplicationInfo = C_LFGList.GetApplicationInfo
	local j = 1
	for i=1,n do
		local id, appStatus = GetApplicationInfo(applications[i])
		if appStatus == "applied" or appStatus == "invited" then
			applications[j] = id
			j = j + 1
		end
	end
	for i=n,j,-1 do
		applications[i] = nil
	end
	ClassicLFR_Options.applications_count = #applications
	return applications
end

function ClassicLFR_Options.Search(dialog_control,sign_up_func,research_func,filter_options,
	category,terms,filters,preferredfilters,converter,sag_func,sag_insecure,back_list)
	local lfg_profile = ClassicLFR.db.profile
	local profile = ClassicLFR_Options.db.profile
	local hardware = lfg_profile.hardware
	local option_table_args = ClassicLFR_Options.option_table.args
	local current = coroutine.running()
	local function resume()
		ClassicLFR.resume(current)
	end
	local unsecure_state
	local yd,arg1,arg2,arg3,arg4,arg5 = 0
	local args =
	{
		back = 
		{
			order = 1,
			name = BACK,
			type = "execute",
			func = resume,
			width = 0.667
		},
		search_again = 
		{
			order = 2,
			name = LFG_LIST_SEARCH_AGAIN,
			type = "execute",
			func = function()
				ClassicLFR.resume(current,0)
			end,
		}
	}
	local sign_up =
	{
		order = 3,
		name = SIGN_UP,
		type = "execute",
		func = sign_up_func or default_signup,
		width = 0.667
	}
	local search_config_tb =
	{
		name = KBASE_SEARCH_RESULTS,
		type = "group",
		childGroups = "tab",
		args = args
	}
	local results_t =
	{
		type = "multiselect",
		dialogControl = dialog_control,
		get = function(info,val)	return select_sup[val] end,
		width = "full"
	}
	local search_info =
	{
		type = "group",
		childGroups = "tab",
		order = 4,
		args ={results_t}
	}
	local function resume_1()
		ClassicLFR.resume(current,1)
	end
	ClassicLFR_Options:RegisterMessage("LFG_CORE_FINALIZER",resume)
	ClassicLFR_Options:RegisterMessage("LFG_ICON_MIDDLE_CLICK",resume)
	local count, results
	local timer
	local pending
	local none_format_concat = {}
	local C_LFGList = C_LFGList
	while true do
		if type(yd)~="number" then
			break
		end
		repeat
		if yd < 2 then
			if yd == 1 and next(select_sup) then
				break
			end
			local elapse_time_start = GetTime()
			local error_msg
			if not unsecure_state then
				if yd == 0 or option_table_args.search_result then
					args.results =
					{
						order = 4,
						name = SEARCHING,
						type = "description",
						width = "full"
					}
					args.sign_up = nil
					option_table_args.search_result = search_config_tb
					if yd == 0 then
						AceConfigDialog:SelectGroup("ClassicLFR","search_result")
					else
						ClassicLFR_Options.NotifyChangeIfSelected("search_result")
					end
				end
				ClassicLFR_Options.ExecuteSearchPattern(filter_options)
				count, results = ClassicLFR.Search(category,filters,preferredfilters)
				wipe(select_sup)
				if count == 0 then
					error_msg = results and LFG_LIST_NO_RESULTS_FOUND or LFG_LIST_SEARCH_FAILED
					args.results =
					{
						order = 4,
						name = error_msg,
						type = "description",
						width = "full"
					}
					args.sign_up = nil
					results=nil
					option_table_args.search_result = search_config_tb
				end
				unsecure_state=hardware
			end
			local ftrs
			if results then
				ftrs = ClassicLFR_Options.ExecuteFilter(results,filter_options,yd == 0)
				if ClassicLFR_Options.Background_Timer then
					ClassicLFR_Options:CancelTimer(ClassicLFR_Options.Background_Timer)
				end
				ClassicLFR_Options.Background_Timer = ClassicLFR_Options:ScheduleRepeatingTimer(resume_1,#ftrs+10)
				wipe(none_format_concat)
				if converter then
					local cvt = converter(ftrs)
					none_format_concat[#none_format_concat+1] = #cvt
					results_t.values = cvt
				else
					local applications = GetApplications()
					if #applications ~= 0 then
						none_format_concat[#none_format_concat+1] = #applications
					end
					none_format_concat[#none_format_concat+1] = #ftrs
					for i=1,#ftrs do
						applications[#applications+1]=ftrs[i]
					end
					results_t.values = applications
				end
				none_format_concat[#none_format_concat+1] = #results
				none_format_concat[#none_format_concat+1] = (#results ~= count and count) or nil
				none_format_concat[#none_format_concat+1] = string.format("%.3fs",GetTime()-elapse_time_start)
				search_info.name=table.concat(none_format_concat,"/")
				args.results = search_info
				option_table_args.search_result = search_config_tb
				args.sign_up = sign_up
			elseif not hardware then
				if ClassicLFR_Options.Background_Timer then
					ClassicLFR_Options:CancelTimer(ClassicLFR_Options.Background_Timer)
				end
				ClassicLFR_Options.Background_Timer = ClassicLFR_Options:ScheduleRepeatingTimer(resume_1,10)
			end
			if yd == 0 then
				ClassicLFR_Options.NotifyChangeIfSelected("search_result")
				if ftrs and #ftrs < (profile.background_counts or 3) then
					pending = true
				end
			else
				if ClassicLFR_Options.NotifyChangeIfSelected("search_result") then
					pending = nil
				elseif pending and ftrs and ((profile.background_counts or 3)<= #ftrs) then
					if not lfg_profile.mute then
						PlaySound(SOUNDKIT.UI_GROUP_FINDER_RECEIVE_APPLICATION)
					end
					if lfg_profile.taskbar_flash then
						FlashClientIcon()
					end
					ClassicLFR_Options.Background_Result = #ftrs
				end
			end
		end
		until true
		yd,arg1,arg2,arg3,arg4,arg5=coroutine.yield()
	end
	option_table_args.search_result = nil
	ClassicLFR_Options.Background_Result = nil
	C_LFGList.ClearSearchResults()
	if ClassicLFR_Options.Background_Timer then
		ClassicLFR_Options:CancelTimer(ClassicLFR_Options.Background_Timer)
		 ClassicLFR_Options.Background_Timer = nil
	end
	ClassicLFR_Options:UnregisterMessage("LFG_CORE_FINALIZER")
	if ClassicLFR_Options.IsSelected("search_result") then
		if back_list then
			AceConfigDialog:SelectGroup("ClassicLFR",unpack(back_list))
		else
			AceConfigDialog:SelectGroup("ClassicLFR","find","f")
		end
	else
		LibStub("AceConfigRegistry-3.0"):NotifyChange("ClassicLFR")
	end
end

local AceGUI = LibStub("AceGUI-3.0")
AceGUI:RegisterWidgetType("lfg_opt_sr_default_multiselect", function()
	local control = AceGUI:Create("InlineGroup")
	control.type = "lfg_opt_sr_default_multiselect"
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
		local applications_count = ClassicLFR_Options.applications_count
		control.SetItemValue = function(self,key)
			local val = self.values[key]
			local check = AceGUI:Create("ClassicLFR_search_result_checkbox")
			check:SetUserData("key", key)
			check:SetUserData("val", val)
			if applications_count and key <= applications_count then
				check:SetTriState(true)
				check:SetValue(nil)
				check:SetCallback("OnValueChanged",nop)
			else
				check:SetValue(select_sup[val])
				check:SetCallback("OnValueChanged",function(self,...)
					local user = self:GetUserDataTable()
					local v = user.val
					if select_sup[v] then
						select_sup[v] = nil
					else
						select_sup[v] = true
					end
					check:SetValue(select_sup[v])
				end)
			end
			ClassicLFR_Options.updatetitle(check)
			self:AddChild(check)
		end
		ClassicLFR_Options.register_lfg_list_search_result_updated(control,ClassicLFR_Options.updatetitle)
	end
	return AceGUI:RegisterAsContainer(control)
end , 1)
