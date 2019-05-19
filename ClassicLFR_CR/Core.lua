local AceAddon=LibStub("AceAddon-3.0")
local ClassicLFR = AceAddon:GetAddon("ClassicLFR")
local ClassicLFR_CR = AceAddon:NewAddon("ClassicLFR_CR","AceEvent-3.0")

local function print_result(tb,state)
	local tb2 = {}
	local num = 0
	for k,v in pairs(tb) do
		tb2[#tb2+1]={k,v}
		num = num + v
	end
	table.sort(tb2,function(a,b) return b[2] < a[2]; end)
	if num == 0 then
		ClassicLFR:Print(UNKNOWN)
	else
		local n = #tb2
		if n == 1 then
			ClassicLFR:Print(tb2[1][1])
			return
		end
		if 3 < n then
			ClassicLFR:Print("CRZ",n)
			if not state then
				n = 2
			end
		end
		local string_format = string.format
		for i = 1, n do
			local ti = tb2[i]
			ClassicLFR:Print(i,ti[1],string_format("%.0f%%",100 * ti[2]/num))
			if i < n and tb2[i+1][2]*2 < ti[2] then
				break
			end
		end
	end
end

local function scan(state)
	local current = coroutine.running()
	local string_match = string.match
	local player_realm = GetRealmName()
	local log_tb = {}
	local function add_to_log_tb(uid,name)
		if not string.find(uid,"Player") or UnitGUID("player") == uid then
			return
		end
		local realm = string_match(name,"-(.*)$")
		if realm == nil then
			realm = player_realm
		end
		if log_tb[realm] == nil then
			log_tb[realm] = 1
		else
			log_tb[realm] = log_tb[realm] + 1
		end
	end
	FriendsFrame:UnregisterEvent("WHO_LIST_UPDATE")
	SetWhoToUI(0)
	ClassicLFR_CR:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED",function()
		local timeStamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName = CombatLogGetCurrentEventInfo()
		add_to_log_tb(sourceGUID,sourceName)
		add_to_log_tb(destGUID,destName)
		ClassicLFR.resume(current,2)
	end)
	SendWho(table.concat{"z-\"",GetRealZoneText(),"\""})
	ClassicLFR_CR:RegisterEvent("WHO_LIST_UPDATE",function()
		ClassicLFR.resume(current,1)
	end)
	local timer = C_Timer.NewTimer(20,function()
		ClassicLFR.resume(current,0)
	end)
	local i = 1
	while i<31 do
		local yd = coroutine.yield()
		if yd == 1 then
			ClassicLFR_CR:UnregisterEvent("WHO_LIST_UPDATE")
			local tb = {}
			local all_player_realm = true
			for i = 1,GetNumWhoResults() do
				local name = GetWhoInfo(i)
				local realm = string_match(name,"-(.*)$")
				if realm == nil then
					realm = player_realm
				else
					all_player_realm = false
				end
				local tbs = tb[realm]
				if tbs == nil then
					tb[realm] = 1
				else
					tb[realm] = tbs + 1
				end
			end
			if not all_player_realm then
				print_result(tb,state)
				break
			end
		elseif yd == 2 then
			i=i+1
		elseif yd == 0 then
			i=31
		else
			break
		end
	end
	if 30 < i then
		print_result(log_tb,state)
	end
	ClassicLFR_CR:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	ClassicLFR_CR:UnregisterEvent("WHO_LIST_UPDATE")
	ClassicLFR_CR:RegisterMessage("LFG_ICON_RIGHT_CLICK")
	FriendsFrame:RegisterEvent("WHO_LIST_UPDATE")
	timer:Cancel()
end

local results_cache

local function hop()
	local activities = C_LFGList.GetAvailableActivities()
	local C_LFGList_GetActivityInfoExpensive = C_LFGList.GetActivityInfoExpensive
	local activity_id
	for i=1,#activities do
		if C_LFGList_GetActivityInfoExpensive(activities[i]) then
			activity_id = activities[i]
			break
		end
	end
	if activity_id == nil then
		return
	end
	local activityName, activityShortName, categoryID, groupID, iLevel, filters, minLevel, maxPlayers, displayType = C_LFGList.GetActivityInfo(activity_id)
	local function search()
		if results_cache and results_cache.activity_id == activity_id then
			local GetSearchResultInfo = C_LFGList.GetSearchResultInfo
			while #results_cache ~= 0 do
				local info = GetSearchResultInfo(results_cache[#results_cache])
				if info and not isDelisted and (info.questID or info.numMembers ~= 5) then
					break
				else
					results_cache[#results_cache]=nil
				end
			end
			if results_cache and #results_cache ~= 0 then
				results_cache.activity_id = activity_id
				return #results_cache,results_cache,true
			end
		end
		C_LFGList.SetSearchToActivity(activity_id)
		local count,results = ClassicLFR.Search(categoryID,filters,0)
		if rare == 1 then
			if results then
				rare_filter(results)
			end
		end
		results_cache = results
		if results_cache then
			results_cache.activity_id = activity_id		
		end
		return count,results_cache
	end
	local current = coroutine.running()
	local function resume()
		ClassicLFR.resume(current,4)
	end
	local activityName,activityShortName = C_LFGList.GetActivityInfo(activity_id)
	local zone_text = activityName or activityShortName
	if ClassicLFR.accepted(zone_text,search,nil,1) then
		ClassicLFR:Print(LFG_LIST_NO_RESULTS_FOUND)
		return
	end
	while true do
		if rare~=1 then
			coroutine.wrap(scan)()
		end
		local timer = C_Timer.NewTimer(5,resume)
		ClassicLFR_CR:RegisterEvent("GROUP_LEFT",resume)
		local yd = coroutine.yield()
		ClassicLFR_CR:UnregisterEvent("GROUP_LEFT")
		timer:Cancel()
		if IsInInstance() then return end
		if yd == 4 then
			local dialog = StaticPopupDialogs.ClassicLFR_HardwareAPIDialog
			wipe(dialog)
			if IsInGroup() then
				dialog.text=zone_text
				dialog.button1=PARTY_LEAVE
				dialog.button2=CANCEL
				dialog.button3=NEXT
				dialog.timeOut=45
				dialog.OnAccept=function()
					LeaveParty()
					ClassicLFR.resume(current,5)
				end
				dialog.OnAlt = function()
					ClassicLFR.resume(current,6)
				end
			else
				dialog.text=zone_text
				dialog.button1=NEXT
				dialog.button2=CANCEL
				dialog.timeOut=45
				dialog.OnAccept=function()
					ClassicLFR.resume(current,6)
				end
			end
			StaticPopup_Show("ClassicLFR_HardwareAPIDialog")
			if coroutine.yield()==6 then
				if IsInInstance() then return end
				if IsInGroup() then
					LeaveParty()
					results_cache = nil
				end
				if ClassicLFR.accepted(zone_text,search,nil,1) then
					ClassicLFR:Print(LFG_LIST_NO_RESULTS_FOUND)
					return
				end
			else
				break
			end
		else
			break
		end
	end
end

function ClassicLFR_CR:LFG_ICON_RIGHT_CLICK(message,r)
	if r then
		self:SendMessage("LFG_SECURE_QUEST_ACCEPTED")
		coroutine.wrap(hop)(r)
	else
		local name, t = GetInstanceInfo()
		if t == "none" then
			coroutine.wrap(scan)(true)
		else
			ClassicLFR:Print(INSTANCE)
		end
	end
end

function ClassicLFR_CR:OnInitialize()
	self:RegisterMessage("LFG_ICON_RIGHT_CLICK")
end

function ClassicLFR_CR:OnEnable()
end
