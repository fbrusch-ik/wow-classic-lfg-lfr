local AceAddon = LibStub("AceAddon-3.0")
local ClassicLFR_Gearscore = AceAddon:NewAddon("ClassicLFR_Gearscore","AceEvent-3.0","AceTimer-3.0")
local ClassicLFR = AceAddon:GetAddon("ClassicLFR")

ClassicLFR_Gearscore.option_table =
{
	type = "group",
	name = LFG_TITLE:gsub(" ","").." |cff8080cc"..GetAddOnMetadata("ClassicLFR","Version").."|r",
	args = {profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(ClassicLFR.db)}
}

function ClassicLFR_Gearscore:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("ClassicLFR_GearscoreDB",{profile ={a={},s={}}},true)
end

local order = 0

function ClassicLFR_Gearscore:push(key,val)
	if val.order == nil then
		val.order = order
		order = order + 1
	end
	self.option_table.args[key] = val
end

function ClassicLFR_Gearscore.lfg_frame_is_open()
	return LibStub("AceConfigDialog-3.0").OpenFrames.ClassicLFR
end
function ClassicLFR_Gearscore.expected(message)
	ClassicLFR_Gearscore.lfg_frame_is_open():SetStatusText(message)
	PlaySound(882)
end

function ClassicLFR_Gearscore.listing(activity,s,...)
	local quest_id = s.quest_id
	local expected = s.expected or ClassicLFR_Gearscore.expected
	if quest_id then
		if not activity then
			activity = LFGListUtil_GetQuestCategoryData(quest_id) or 16
		end
	else
		if not activity then
			local L = LibStub("AceLocale-3.0"):GetLocale("ClassicLFR")
			expected(format(L.must_select_xxx,LFG_LIST_ACTIVITY,START_A_GROUP))
			LibStub("AceConfigDialog-3.0"):SelectGroup("ClassicLFR","find")
			return
		end
	end
	local listing
	provider = provider or C_LFGList
	if C_LFGList.HasActiveEntryInfo() then
		if activity ~= C_LFGList.GetActiveEntryInfo().activityID then
			return
		end
		listing = provider.UpdateListing
		if quest_id == nil and LFGListFrame.EntryCreation.Name:GetText()=="" then
			local L = LibStub("AceLocale-3.0"):GetLocale("ClassicLFR")
			expected(format(L.must_input_title,LFG_LIST_TITLE,DONE_EDITING))
			return
		end
	else
		listing = provider.CreateListing
		if quest_id == nil and LFGListFrame.EntryCreation.Name:GetText()=="" then
			local L = LibStub("AceLocale-3.0"):GetLocale("ClassicLFR")
			expected(format(L.must_input_title,LFG_LIST_TITLE,LIST_GROUP))
			return
		end
	end
	if listing(activity,s.minimum_item_level or 0,s.minimum_honor_level or 0,s.auto_accept or false,s.private or false,quest_id) then
		if not active then
			coroutine.wrap(ClassicLFR_Gearscore.req_main)(s.auto_accept,...)
		end
		return true
	else
		expected(FAILED)
	end
end

local function get_get_set_tb(tb,parameters)
	local t = tb
	for i = 1,#parameters do
		t=t[parameters[i]]
	end
	return t
end

local function generate_get_set(tb,parameters)
	if parameters == nil then
		parameters = {"db","profile"}
	end
	local function get(info)
		return get_get_set_tb(tb,parameters)[info[#info]]
	end
	local function set(info,val)
		if val then
			get_get_set_tb(tb,parameters)[info[#info]]=true
		else
			get_get_set_tb(tb,parameters)[info[#info]]=nil
		end
	end
	return get,set,function(info) return not get(info) end,function(info,val) set(info,not val) end
end


ClassicLFR_Gearscore.get_function,ClassicLFR_Gearscore.set_function,ClassicLFR_Gearscore.get_function_negative,ClassicLFR_Gearscore.set_function_negative=generate_get_set(ClassicLFR)

ClassicLFR_Gearscore.options_get_function,ClassicLFR_Gearscore.options_set_function,ClassicLFR_Gearscore.options_get_function_negative,ClassicLFR_Gearscore.options_set_function_negative=generate_get_set(ClassicLFR_Gearscore)

ClassicLFR_Gearscore.options_get_a_function,ClassicLFR_Gearscore.options_set_a_function,ClassicLFR_Gearscore.options_get_a_function_negative,ClassicLFR_Gearscore.options_set_a_function_negative=generate_get_set(ClassicLFR_Gearscore,{"db","profile","a"})

ClassicLFR_Gearscore.options_get_s_function,ClassicLFR_Gearscore.options_set_s_function,ClassicLFR_Gearscore.options_get_s_function_negative,ClassicLFR_Gearscore.options_set_s_function_negative=generate_get_set(ClassicLFR_Gearscore,{"db","profile","s"})
