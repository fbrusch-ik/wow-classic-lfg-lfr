local ClassicLFR = LibStub("AceAddon-3.0"):GetAddon("ClassicLFR")
local ClassicLFR_Options = LibStub("AceAddon-3.0"):GetAddon("ClassicLFR_Options")
ClassicLFR_Options.applicant_filters = {}

function ClassicLFR_Options.Register(table_name,filtername,func)
	local tbl = ClassicLFR_Options[table_name]
	if tbl == nil then
		tbl = {}
	end
	local tblf = tbl[filtername]
	if tblf == nil then
		tbl[filtername] = {func}
	else
		tblf[#tblf+1] = func
	end
	ClassicLFR_Options[table_name] = tbl
end

function ClassicLFR_Options.RegisterFilter(...)
	ClassicLFR_Options.Register("filters",...)
end

function ClassicLFR_Options.RegisterSearchPattern(...)
	ClassicLFR_Options.Register("patterns",...)
end

function ClassicLFR_Options.Unregister(tb_name,filtername,func)
	local tbl = ClassicLFR_Options[tb_name]
	if tbl == nil then
		return
	end
	local f = tbl[filtername]
	if f == nil then
		return
	end
	for i=1,#f do
		if f[i] == func then
			table.remove(f,i)
			return
		end
	end
	if next(f) == nil then
		tbl[filtername] = nil
	end
end

local function null_prepare() return true end

function ClassicLFR_Options.RegisterSimpleFilter(filtername,func,prepare)
	local f = {func,prepare or null_prepare}
	ClassicLFR_Options.RegisterFilter(filtername,f)
	return f
end


function ClassicLFR_Options.RegisterApplicantFilter(filtername,func,prepare)
	local f = ClassicLFR_Options.applicant_filters[filtername]
	local g = {func,prepare or null_prepare}
	if f == nil then
		ClassicLFR_Options.applicant_filters[filtername] = {g}
	else
		f[#f+1] = g
	end
end

function ClassicLFR_Options.RegisterSimpleApplicantFilter(filtername,func,prepare)
	ClassicLFR_Options.RegisterApplicantFilter(filtername,function(applicant_id,...)
		local b = 0
		local bor = bit.bor
		for i = 1,C_LFGList.GetApplicantInfo(applicant_id).numMembers do
			b = bor(b,func(applicant_id,i,...) or 0)
		end
		return b
	end,prepare)
end

function ClassicLFR_Options.RegisterSimpleFilterExpensive(filtername,func,prepare)
	local f = {function(info,profile,a,tb,k)
		local searchResultID = info.searchResultID
		while true do
			if not info.leaderName then
				info = C_LFGList.GetSearchResultInfo(searchResultID)
				tb[k] = info
			end
			if info.leaderName then
				local ok,r = pcall(func,info,profile,a,tb,k)
				if ok then
					return r
				end
				ClassicLFR_Options.Paste(r,nop)
				return
			end
			local current = coroutine.running()
			ClassicLFR_Options:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED",function(_,resultID)
				if searchResultID == resultID then
					ClassicLFR.resume(current)
				else
					tb[k] = C_LFGList.GetSearchResultInfo(resultID)
				end
			end)
			coroutine.yield()
			ClassicLFR_Options:UnregisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED")
		end
		return 1
	end,prepare or null_prepare}
	ClassicLFR_Options.RegisterFilter(filtername,f)
	return f
end

local function simplefilter(filters,result,filter_options)
	local type = type
	local band = bit.band
	local bor = bit.bor
	local b = 0
	local profile = ClassicLFR_Options.db.profile
	for i=1,#filter_options do
		local f = filters[filter_options[i]]
		if f then
			for j=1,#f do
				local fj = f[j]
				if type(fj) == "table" then
					local a = fj[2](profile)
					if a then
						b = bor(b,fj[1](result,profile,a) or 0)
						if 3 < b then
							return b
						end
					end
				end
			end
		end
	end
	return b
end

function ClassicLFR_Options.ExecuteApplicantFilter(result,...)
	local ok,b = pcall(simplefilter,ClassicLFR_Options.applicant_filters,result,...)
	if not ok then
		ClassicLFR_Options.Paste(b,nop)	
		return true
	end
	if b < 4 and bit.band(b,1) == 0 then
		return true
	end
end

function ClassicLFR_Options.ExecuteSimpleFilter(result,filter_options)
	local band = bit.band
	local b = simplefilter(ClassicLFR_Options.filters,C_LFGList.GetSearchResultInfo(result),filter_options)
	local C_LFGList_ReportSearchResult = C_LFGList.ReportSearchResult
	local profile = ClassicLFR_Options.db.profile
	if profile.a.disable then
		return results
	end
	if profile.a.gold then
		if 3 < b and band(b,1) == 0 then
			return true
		end
	else
		local hack_ms = not profile.addon_meeting_stone_hack
		local auto_report = not profile.auto_report
		UIErrorsFrame:UnregisterEvent("UI_INFO_MESSAGE") -- Don't show the "Thanks for the report" message
		DEFAULT_CHAT_FRAME:UnregisterEvent("CHAT_MSG_SYSTEM")
		if b < 4 then
			if hack_ms and band(b,2) == 2 then
				C_LFGList_ReportSearchResult(result,"lfglistspam")
			end
			if band(b,1) == 0 then
				return true
			end
		elseif auto_report then
			C_LFGList_ReportSearchResult(result,"lfglistspam")
		end
		DEFAULT_CHAT_FRAME:RegisterEvent("CHAT_MSG_SYSTEM")
		UIErrorsFrame:RegisterEvent("UI_INFO_MESSAGE")
	end
end

local bts = {}
local tb = {}

function ClassicLFR_Options.Execute(table_name,info_func,results,filter_options,first)
	wipe(bts)
	for i=1,#results do
		bts[i]=0
	end
	local profile = ClassicLFR_Options.db.profile
	local filters = ClassicLFR_Options[table_name]
	local type = type
	local band = bit.band
	local bor = bit.bor
	wipe(tb)
	for i=1,#results do
		tb[i] = info_func(results[i]) or false
	end
	for i=1,#filter_options do
		local f = filters[filter_options[i]]
		if f then
			for j=1,#f do
				local fj = f[j]
				if type(fj) == "table" then
					local a = fj[2](profile,first)
					if a then
						local simple_filter_func = fj[1]
						for k=1,#results do
							local b = bts[k]
							if b < 4 then
								bts[k] = bor(b,simple_filter_func(tb[k],profile,a,tb,k) or 0)
							end
						end
					end
				else
					fj(tb,bts,first,profile)
				end
			end
		end
	end
end

function ClassicLFR_Options.ExecuteFilter(results,filter_options,first)
	local profile = ClassicLFR_Options.db.profile
	if profile.a.gold == false then
		return results
	end
	ClassicLFR_Options.Execute("filters",C_LFGList.GetSearchResultInfo,results,filter_options,first)
	local C_LFGList_ReportSearchResult = C_LFGList.ReportSearchResult
	wipe(tb)
	local band = bit.band
	local bor = bit.bor
	if profile.a.gold then
		for i=1,#results do
			local v = bts[i]
			if 3 < v and band(v,1) == 0 then
				tb[#tb+1] = results[i]
			end
		end
	else
		local hack_ms = not profile.addon_meeting_stone_hack
		local auto_report 
		if ClassicLFR.db.profile.hardware then
			if first and not profile.auto_report then
				auto_report = true
			end
		else
			auto_report = not profile.auto_report
		end
		local leadername_ignore_tb
		UIErrorsFrame:UnregisterEvent("UI_INFO_MESSAGE") -- Don't show the "Thanks for the report" message
		DEFAULT_CHAT_FRAME:UnregisterEvent("CHAT_MSG_SYSTEM")
		for i=1,#results do
			local v = bts[i]
			local g = results[i]
			if v < 4 then
				if band(v,1) == 0 then
					tb[#tb+1] = g
				end
				if hack_ms and band(v,2) == 2 then
					C_LFGList_ReportSearchResult(g,"lfglistspam")
--					C_LFGList_ReportSearchResult(g,"lfglistname")
--					C_LFGList_ReportSearchResult(g,"lfglistcomment")
				end
			elseif auto_report then
				C_LFGList_ReportSearchResult(g,"lfglistspam")
				if band(v,32) == 32 then
					local leaderName = GetSearchResultInfo(g).leaderName
					if leaderName then
						if leadername_ignore_tb == nil then
							leadername_ignore_tb = {}
						end
						leadername_ignore_tb[leaderName:lower()] = 0
					end
				end
--[[				if band(v,4) == 4 then
					C_LFGList_ReportSearchResult(g,"lfglistname")
				elseif band(v,8) == 8 then
					C_LFGList_ReportSearchResult(g,"lfglistcomment")
				elseif band(v,16) == 16 then
					C_LFGList_ReportSearchResult(g,"lfglistvoicechat")
				end]]
			end
		end
		DEFAULT_CHAT_FRAME:RegisterEvent("CHAT_MSG_SYSTEM")
		UIErrorsFrame:RegisterEvent("UI_INFO_MESSAGE")
		if leadername_ignore_tb then
			local keywords = ClassicLFR.db.profile.spam_filter_keywords
			if keywords == nil then
				keywords = {}
			end
			for i=1,#keywords do
				leadername_ignore_tb[keywords[i]] = nil
			end
			for k,v in pairs(leadername_ignore_tb) do
				keywords[#keywords+1] = k
			end
			if #keywords == 0 then
				ClassicLFR.db.profile.spam_filter_keywords = nil
			else
				ClassicLFR.db.profile.spam_filter_keywords = keywords
			end
		end
	end
	ClassicLFR_Options.SortSearchResults(tb)
	return tb
end

function ClassicLFR_Options.ExecuteAutoAccept(results,filter_options,first)
	ClassicLFR_Options.Execute("auto_accept",C_LFGList.GetApplicantInfo,results,filter_options,first)
	local hardware = ClassicLFR.db.profile.hardware
	local band = bit.band
	local bor = bit.bor
	for i=1,#results do
		local info = tb[i]
		if info then
			local v = bts[i]
			if v < 4 then
				if band(v,1) == 0 then
					if hardware then
						if info.numMembers == 1 then
							local name = C_LFGList.GetApplicantMemberInfo(info.applicantID,1)
							InviteUnit(name)
						end
					else
						C_LFGList.InviteApplicant(info.applicantID)
					end
				end
			end
		end
	end
end

function ClassicLFR_Options.ExecuteSearchPattern(filter_options)
	local patterns = ClassicLFR_Options.patterns
	local profile = ClassicLFR_Options.db.profile
	local a = profile.a
	local category = a.category
--	local dbf_mx_length = category == 2 and 3 or 1
	for i=1,#filter_options do
		local f = patterns[filter_options[i]]
		if f then
			for j=1,#f do
--[[				local r = f[j](profile,a,category,p)
				if r then
					if #r <= dbf_mx_length then
						p[#p+1] = {matches = r}
					end
				end]]
				f[j](profile,a,category)
			end
		end
	end
end

ClassicLFR_Options.RegisterSearchPattern("find",function(profile,a,category)
	if LFGListFrame.SearchPanel.SearchBox:GetText():len() == 0 and a.activity then
		C_LFGList.SetSearchToActivity(a.activity)
	end
end)


ClassicLFR_Options.RegisterSimpleFilter("find",function(info,profile,class)
	local class_tb = C_LFGList.GetSearchResultMemberCounts(info.searchResultID)
	if class_tb and class_tb[class] < 2 then
		return 1
	end
end,function(profile)
	if profile.a.class then
		return select(2,UnitClass("player"))
	end
end)

ClassicLFR_Options.RegisterSimpleFilter("find",function(info,profile,ilvl)
	if info.requiredItemLevel < ilvl then
		return 1
	end
end,function(profile)
	return profile.a.ilvl
end)

ClassicLFR_Options.RegisterSimpleFilter("find",function(info)
	local fullName, shortName, categoryID, groupID, itemLevel, filters, minLevel, maxPlayers, displayType, activityOrder = C_LFGList.GetActivityInfo(info.activityID)
	if info.numMembers * 3 < maxPlayers * 2 then
		return 1
	end
end,function(profile)
	return profile.a.complete
end)


ClassicLFR_Options.RegisterSimpleFilter("find",function(info,profile,last_time)
	if GetTime() < info.age + last_time then
		return 1
	end
end,function(profile,first)
	local a = profile.a
	if first then
		if a.current_time then
			a.last_time = a.current_time
		end
		a.current_time = GetTime()
	end
	if a.newg then
		return a.last_time
	end
end)

ClassicLFR_Options.RegisterSimpleApplicantFilter("s",function(id,pos,profile,func)
	local name = C_LFGList.GetApplicantMemberInfo(id,pos)
	return func(name) and 1
end,function(profile)
	if ClassicLFR.db.profile.mode_rf ~= nil then
		local SF = ClassicLFR:GetModule("SF",true)
		if SF then
			return SF.realm_filter
		end
	end
end)

ClassicLFR_Options.RegisterSimpleApplicantFilter("s",function(id,pos,profile,fakeilvl)
	local name, class, localizedClass, level, itemLevel, honorLevel, tank, healer, damage, assignedRole, relationship = C_LFGList.GetApplicantMemberInfo(id,pos)
	if itemLevel < fakeilvl then
		return 1
	end
end,function(profile)
	return profile.s.fake_minimum_item_level
end)
