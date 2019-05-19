local ClassicLFR = LibStub("AceAddon-3.0"):GetAddon("ClassicLFR")
local ClassicLFR_Q = LibStub("AceAddon-3.0"):NewAddon("ClassicLFR_Q","AceEvent-3.0")

function ClassicLFR_Q:OnInitialize()
	local db = ClassicLFR.db
	local defaults = ClassicLFR.db.defaults
	defaults.profile.q = {[42170]=true,[42233]=true,[42234]=true,[42420]=true,[42421]=true,[42422]=true,[43179]=true,[43943]=true,[45379]=true,[48338]=true,[48358]=true,[48360]=true,[48374]=true,[48592]=true,[48639]=true,[48641]=true,[48642]=true,[50562]=true,
	[54978] = true, -- Against Overwhelming Odds
	[51017] = true, -- Supplies Needed: Monelite Ore
	[54618] = true, -- Paragon of the 7th Legion
	[48973] = true, -- Paragon of Argussian Reach
	[48974] = true, -- Paragon of the Army of the Light
-- bfa assaults
    [51982] = true, -- Storm's Rage
    [53701] = true, -- A Drust Cause
    [53771] = true, -- A Sound Defense
    [53883] = true, -- Shores of Zuldazar
    [53885] = true, -- Isolated Victory
    [53939] = true, -- Breaching Boralus
    [54132] = true, -- Horde of Heroes
	}
	db:RegisterDefaults(defaults)
end

function ClassicLFR_Q:OnEnable()
	ClassicLFR_Q:RegisterEvent("QUEST_ACCEPTED")
	ClassicLFR_Q:RegisterMessage("LFG_SECURE_QUEST_ACCEPTED")
end

local function cofunc(quest_id,secure,gp)
	local questName = C_TaskQuest.GetQuestInfoByQuestID(quest_id)
	if questName == nil then
		if secure <= 0 and ClassicLFR.db.profile.auto_no_info_quest then
			return
		end
		local GetQuestLogTitle = GetQuestLogTitle
		for i=1,GetNumQuestLogEntries() do
			local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling = GetQuestLogTitle(i)
			if questID == quest_id then
				if secure <= 0 and frequency == LE_QUEST_FREQUENCY_WEEKLY then
					return
				end
				questName = title
				break
			end
		end
	end
	if questName == nil then return end
	local activityID = C_LFGList.GetActivityIDForQuestID(quest_id)
	if activityID  == nil then
		local activities = C_LFGList.GetAvailableActivities()
		local C_LFGList_GetActivityInfoExpensive = C_LFGList.GetActivityInfoExpensive
		for i=1,#activities do
			if C_LFGList_GetActivityInfoExpensive(activities[i]) then
				activityID = activities[i]
				break
			end
		end
		if activityID == nil then
			activityID = 280 --use wandering isle activity since no one will use it unless you are a level capped neutral pandaren like me
		end
	end
	local fullName, shortName, categoryID, groupID, iLevel, filters, minLevel, maxPlayers, displayType = C_LFGList.GetActivityInfo(activityID)
	local confirm_keyword = not C_LFGList.CanCreateQuestGroup(quest_id) and tostring(quest_id) or nil
	local function create()
		local ilvl = GetAverageItemLevel() - 100
		if ilvl < 0 then
			ilvl = 0
		end
		if confirm_keyword then
			if math.floor(ilvl) == ilvl then
				ilvl = ilvl + 0.1
			end
			C_LFGList.CreateListing(activityID,ilvl,0,true,false)
		else
			C_LFGList.ClearCreationTextFields()
			C_LFGList.CreateListing(activityID,ilvl,0,true,false,quest_id)
		end
	end
	local function search()
		if not confirm_keyword then
			C_LFGList.SetSearchToQuestID(quest_id)
		end
		return ClassicLFR.Search(categoryID,filters,0)
	end
	ClassicLFR_Q:RegisterEvent("QUEST_REMOVED",function(info,id)
		if quest_id == id then
			StaticPopup_Hide("ClassicLFR_HardwareAPIDialog")
		end
	end)
	local raid = select(4,GetQuestTagInfo(quest_id)) == 3
	if not gp and IsInGroup() then
		if 0 < secure and UnitIsGroupLeader("player", LE_PARTY_CATEGORY_HOME) then
			gp = true
		else
			return
		end
	end
	local current = coroutine.running()
	if ClassicLFR.accepted(questName,search,create,secure,raid,confirm_keyword,"<LFG>Q",gp) then
		return
	end
	ClassicLFR_Q:RegisterEvent("QUEST_ACCEPTED",function(event,index,id)
		if IsInGroup() then
			if quest_id == id then
				ClassicLFR.resume(current,3)
			end
		else
			ClassicLFR.resume(current)
			ClassicLFR_Q:RegisterEvent("QUEST_ACCEPTED")
		end
	end)
	ClassicLFR_Q:RegisterEvent("QUEST_TURNED_IN",function(info,id)
		if quest_id == id then
			ClassicLFR.resume(current,0,gp)
		end
	end)
	ClassicLFR_Q:RegisterEvent("QUEST_REMOVED",function(info,id)
		if quest_id == id then
			ClassicLFR.resume(current,1,gp)
		end
	end)
	ClassicLFR.autoloop(questName,create,raid,confirm_keyword,"<LFG>Q",function()
		local distance = C_TaskQuest.GetDistanceSqToQuest(quest_id)
		return not distance or distance < 40000
	end)
	ClassicLFR_Q:UnregisterEvent("QUEST_TURNED_IN")
	ClassicLFR_Q:UnregisterEvent("QUEST_REMOVED")
	ClassicLFR_Q:RegisterEvent("QUEST_ACCEPTED")
end

local function barrels(quest_id)
	local current = coroutine.running()
	local function resume(info,id)
		if quest_id == id then
			ClassicLFR.resume(current,0)
		end
	end
	ClassicLFR_Q:RegisterEvent("QUEST_TURNED_IN",resume)
	ClassicLFR_Q:RegisterEvent("QUEST_REMOVED",resume)
	ClassicLFR_Q:RegisterEvent("UPDATE_MOUSEOVER_UNIT",function()
		local guid = UnitGUID("mouseover")
		if guid then
			local _,_,_,_,_,id = strsplit("-", guid)
			if id == "115947" then
				if GetRaidTargetIndex("mouseover") == nil then
					ClassicLFR.resume(current,1)
				end
			end
		end
	end)
	local marker = 1
	while coroutine.yield() == 1 do
		SetRaidTarget("mouseover",marker)
		marker = marker + 1
		if marker == 9 then
			marker = 1
		end
	end
	ClassicLFR_Q:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
	ClassicLFR_Q:UnregisterEvent("QUEST_TURNED_IN")
	ClassicLFR_Q:UnregisterEvent("QUEST_REMOVED")
end


local function is_group_q(id,ignore)
	if id == nil or IsRestrictedAccount() then
		return
	end
	local profile = ClassicLFR.db.profile
	if 45068 <= id and id < 45073 then	-- Barrels o' Fun
		if not profile.barrels_o_fun and not IsInGroup() then
			coroutine.wrap(barrels)(id)
		end
		return
	end
	if ignore then
		return true
	end
	if (46794 <= id and id <= 46802) -- legion paragon quests
		or (50598<=id and id <= 50606) -- bfa bounty quests
		or (51021<=id and id <= 51051) or (52375<=id and id <= 52388) -- bfa supplies needed
		or (54134<=id and id <= 54138) --bfa assaults
		or (54626<=id and id <= 54632) -- bfa paragon quests
		then return
	end
	if profile.q[id] then
		return
	end
	local tagID, tagName, wq_type, rarity, isElite, tradeskillLineIndex, displayTimeLeft = GetQuestTagInfo(id)
	if tagID == 62 or tagID == 81 or tagID == 83 or tagID == 117 or tagID == 124 or tagID == 125 then
		return
	end
	if profile.auto_wq_only and wq_type == nil then
		return
	end
	if profile.auto_ccqg and not C_LFGList.CanCreateQuestGroup(id) then
		return
	end
	if wq_type == LE_QUEST_TAG_TYPE_PET_BATTLE or wq_type == LE_QUEST_TAG_TYPE_PROFESSION or wq_type == LE_QUEST_TAG_TYPE_DUNGEON or wq_type == LE_QUEST_TAG_TYPE_RAID then
		return
	end
	if math.floor(id/100) == 413 then
		return
	end
	local quest_faction = select(2,C_TaskQuest.GetQuestInfoByQuestID(id))
	if quest_faction == 1090 or quest_faction == 2163 then
		return
	end
	local num_wq_watches = GetNumWorldQuestWatches()
	if num_wq_watches ~= 0 then
		local i = 1
		local GetWorldQuestWatchInfo = GetWorldQuestWatchInfo
		while i<=num_wq_watches do
			if GetWorldQuestWatchInfo(i) == id then
				break
			end
			i = i + 1
		end
		if num_wq_watches < i then
			return
		end
	end	
	return true
end

function ClassicLFR_Q:QUEST_ACCEPTED(_,index,quest_id)
	local load_time = ClassicLFR.load_time
	if load_time == nil or GetTime() < load_time + 5 then
		return
	end
	if is_group_q(quest_id) then
		coroutine.wrap(cofunc)(quest_id,0)
	end
end

function ClassicLFR_Q:LFG_SECURE_QUEST_ACCEPTED(_,quest_id,group)
	if is_group_q(quest_id,true) then
		coroutine.wrap(cofunc)(quest_id,1,group)
	end
end
