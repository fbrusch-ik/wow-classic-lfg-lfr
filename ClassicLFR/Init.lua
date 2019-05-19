local ClassicLFR = LibStub("AceAddon-3.0"):NewAddon("ClassicLFR","AceEvent-3.0","AceConsole-3.0")

function ClassicLFR:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("ClassicLFRDB",{profile = ((GetCurrentRegion()==5 and {spam_filter_maxlength=120,spam_filter_digits=2,spam_filter_hyperlinks=2}) or {spam_filter_maxlength=80,hardware = true})},true)
	self:RegisterChatCommand("ClassicLFR", "ChatCommand")
	self:RegisterChatCommand("LFG", "ChatCommand")
	self:RegisterChatCommand(LFG_TITLE:gsub(" ",""), "ChatCommand")
	local event_zero
	for i = 1, GetNumAddOns() do
		local event = GetAddOnMetadata(i, "X-LFG-EVENT")
		if event then
			if event == "0" then
				event_zero = true
			else
				self:RegisterEvent(event,"loadevent",i)
			end
		end
		local messages = GetAddOnMetadata(i,"X-LFG-MESSAGE")
		if messages then
			for message in gmatch(messages, "([^,]+)") do
				self:RegisterMessage(message,"loadevent",i)
			end
		end
	end
	if event_zero then
		self:LOADING_SCREEN_DISABLED()
	else
		ClassicLFR.LOADING_SCREEN_DISABLED = nil
	end
end

function ClassicLFR:ChatCommand(input)
	self:SendMessage("LFG_ChatCommand",input)
end

function ClassicLFR:OnEnable()
	self.load_time = GetTime()
	local C_LFGList = C_LFGList
	for k,v in pairs(C_LFGList) do
		local secure,addon = issecurevariable(C_LFGList,k)
		if not secure then
			ClassicLFR:Print("|c00ff0000WARNING|r: C_LFGList."..k.." is tainted by |c00ff0000"..addon.."|r. ClassicLFR will disable it automatically. A number of common WoW UI coding practices (most notably hooking) can easily cause problems, preventing players from casting spells or performing actions.")
			DisableAddOn(addon)
		end	
	end
end

function ClassicLFR.resume(current,...)
	local current_status = coroutine.status(current)
	if current_status ~="running" and current_status ~= "dead" then
		local status, msg = coroutine.resume(current,...)
		if not status then
			ClassicLFR:Print(msg)
		end
		return status,msg
	end
	return current_status
end

function ClassicLFR.Search(category,filters,preferredfilters)
	ClassicLFR:SendMessage("LFG_CORE_FINALIZER",0)
	C_LFGList.Search(category,filters,preferredfilters,C_LFGList.GetLanguageSearchFilter())
	local current = coroutine.running()
	local function resume(...)
		ClassicLFR.resume(current,...)
	end
	ClassicLFR:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED",resume)
	ClassicLFR:RegisterEvent("LFG_LIST_SEARCH_FAILED",resume)
	local r = coroutine.yield()
	ClassicLFR:UnregisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")
	ClassicLFR:UnregisterEvent("LFG_LIST_SEARCH_FAILED")
	if r == "LFG_LIST_SEARCH_RESULTS_RECEIVED" then
		return C_LFGList.GetSearchResults()
	end
	return 0
end

function ClassicLFR:loadevent(p,event,...)
	ClassicLFR:UnregisterEvent(event)
	ClassicLFR:UnregisterMessage(event)
	if IsAddOnLoaded(p) then
		self:SendMessage(event,...)
		return true
	end
	LoadAddOn(p)
	if IsAddOnLoaded(p) then
		local addon = GetAddOnInfo(p)
		local a = LibStub("AceAddon-3.0"):GetAddon(addon)
		a[event](a,event,...)
		return true
	end
end

function ClassicLFR:LOADING_SCREEN_DISABLED()
	local _,v = GetInstanceInfo()
	if v == "none" or v == "scenario" then
		for i = 1, GetNumAddOns() do
			if GetAddOnMetadata(i, "X-LFG-EVENT") == "0" then
				LoadAddOn(i)
			end
		end
		self:UnregisterEvent("LOADING_SCREEN_DISABLED")
		ClassicLFR.LOADING_SCREEN_DISABLED = nil
	else
		self:RegisterEvent("LOADING_SCREEN_DISABLED")
	end
end

function ClassicLFR.accepted(...)
	ClassicLFR.accepted = nil
	local loaded, reason = LoadAddOn("ClassicLFR_Auto")
	if not loaded then return true end
	return ClassicLFR.accepted(...)
end

function ClassicLFR.realm_filter(name)
	local profile = ClassicLFR.db.profile
	local mode_rf = profile.mode_rf
	if mode_rf == nil then
		return
	end
	local realm_filters = profile.realm_filters
	if mode_rf then
		if realm_filters and name then
			local realm = name:match("-(.*)$")
			if realm and realm_filters[realm] then
				return true
			end
		end
		return
	end
	if realm_filters and name then
		local realm = name:match("-(.*)$")
		if not realm or realm_filters[realm] then
			return
		end
	end
	return true
end
