local ClassicLFR = LibStub("AceAddon-3.0"):GetAddon("ClassicLFR")
local SF = ClassicLFR:NewModule("SF","AceEvent-3.0")

local function cofunc()
	local current = coroutine.running()
	local function resume(...)
		ClassicLFR.resume(current,...)
	end
	if DBM then
		DBMMainFrame:UnregisterEvent("CHAT_MSG_WHISPER")
	end
	local filteredlineid
	do
		local tbls = {{"CHAT_MSG_WHISPER"},
		{"CHAT_MSG_CHANNEL"},
		{"CHAT_MSG_EMOTE","CHAT_MSG_TEXT_EMOTE"},
		{"CHAT_MSG_SAY","CHAT_MSG_DND","CHAT_MSG_YELL","CHAT_MSG_AFK"},
		{"CHAT_MSG_PARTY","CHAT_MSG_PARTY_LEADER"},
		{"CHAT_MSG_RAID","CHAT_MSG_RAID_LEADER","CHAT_MSG_INSTANCE_CHAT","CHAT_MSG_INSTANCE_CHAT_LEADER","CHAT_MSG_RAID_WARNING"},
		{"CHAT_MSG_WHISPER_INFORM","CHAT_MSG_SYSTEM","CHAT_MSG_IGNORED"}
--		{"CHAT_MSG_GUILD"}
		}
		local function filter_func(_, event, msg, _, _, _, _, _, _, _, _, _, line_id)
			return filteredlineid == line_id
		end
		SF:RegisterMessage("LFG_CHAT_MSG_SILENT",resume,-1)
		for j = 1, #tbls do
			local tbl = tbls[j]
			for i = 1, #tbl do
				local event = tbl[i]
				local frames = {GetFramesRegisteredForEvent(event)}
				SF:RegisterEvent(event,resume,j)
				ChatFrame_AddMessageEventFilter(event, filter_func)
				for i = 1, #frames do
					local frame = frames[i]
					frame:UnregisterEvent(event)
					frame:RegisterEvent(event)
				end
			end
		end
	end
	if IsAddOnLoaded("BigWigs") then
		SF:RegisterMessage("BigWigs_OnPluginEnable",function(_,plugin)
			if plugin.name == "BigWigs_plugins_AutoReply" then
				SF:UnregisterMessage("BigWigs_OnPluginEnable")
				local func = plugin.CHAT_MSG_WHISPER
				plugin.CHAT_MSG_WHISPER = function(self, event, msg, player, language, arg6, arg7, flag, channelId, channelNum, arg11, arg12, line_id, guid)
					if line_id ~= filteredlineid then
						func(self, event, msg, player, language, arg6, arg7, flag, channelId, channelNum, arg11, arg12, line_id, guid)
					end
				end
			end
		end)
	end
	local db = ClassicLFR.db
	local UnitGUID = UnitGUID
	local string_find = string.find
	local tag, event, msg, player, language, arg6, arg7, flag, channelId, channelNum, arg11, arg12, line_id, guid = coroutine.yield()
	local silenting
	while true do
		local whisper
		if tag < 0 then
			if tag == -1 then
				SF:RegisterMessage("LFG_CHAT_MSG_UNSILENT",resume,-2)
				silenting = true
			else
				SF:UnregisterMessage("LFG_CHAT_MSG_UNSILENT")
				silenting = nil
			end
		else
		repeat
		if silenting then
			whisper = 0
			break
		end
		local profile = db.profile
		if tag == 3 and not profile.spam_filter_emote_xp and IsResting() then
			whisper = 1
			break
		end
		local filters = profile.addon_filters
		if string_find(msg,"^<LFG>") then
			whisper = 0
			break
		end
		if tag == 7 then
			break
		end
		for i=1,#filters do
			if string_find(msg,filters[i]) then
				whisper = 2
				break --simulate goto
			end
		end
		if guid == UnitGUID("player") then
			break
		end
		if tag < 5 then
			if ClassicLFR.realm_filter(player) then
				whisper = 0
				break
			end
			local lg = profile.spam_filter_language
			if lg~=nil then
				local ok
				repeat
				if string_find(msg,"[\128-\255]") then
					if profile.spam_filter_language_russian and string_find(msg,"\208") then
						break
					end
					if profile.spam_filter_language_chinese and string_find(msg,"[\228-\233]") then
						break
					end
					if profile.spam_filter_language_korean and string_find(msg,"[\234-\237]") then
						break
					end
				elseif profile.spam_filter_language_english then
					break
				end
				if not lg then
					whisper = 0
					break
				end
				ok = true
				until true
				if lg and not ok then
					whisper = 0
					break
				end
			end
		end
		if tag == 1 then
			if guid and guid:find("^Player") then
				if (IsGuildMember(guid) or IsCharacterFriend(guid) or UnitInRaid(player) or UnitInParty(player) or select(2,BNGetGameAccountInfoByGUID(guid))) then
					break
				end
			end
			if profile.sf_unknown then
				whisper = 1
				break
			end
		end
		if tag < 5 then
			if not profile.spam_filter_community and msg:find("|Hc") then
				whisper = 1
				break
			end
			if not profile.spam_filter_instance and msg:find("|Hjournal") then
				whisper = 1
				break
			end
			if tag == 2 then
				if not profile.spam_filter_achievements and msg:find("|Hachievement") then
					whisper = 1
					break
				end
				if not profile.spam_filter_quest and msg:find("|Hquest") then
					whisper = 1
					break
				end
			end
			local hyperlinks = profile.spam_filter_hyperlinks
			if hyperlinks then
				local numHyperlink
				msg, numHyperlink = msg:gsub("|c[^%[]+%[([^%]]+)%]|h|r", "%1")
				if hyperlinks < numHyperlink then
					whisper = 1
					break
				end
			end
			if not profile.spam_filter_slash and msg:find("//") then
				whisper = 1
				break
			end
			local length = profile.spam_filter_maxlength
			if length and length < (string_find(msg,"[\128-\255]") and strlenutf8(msg) * 3 or msg:len())  then
				whisper = 1
				break
			end
			local digits = profile.spam_filter_digits
			if digits then
				local t = 0
				for number in string.gmatch(msg, "%d+") do
					t = t + 1
				end
				if digits < t then
					whisper = 1
					break
				end
			end
			if not profile.spam_filter_spaces then
				local num_spaces
				msg,num_spaces = msg:gsub(" ","")
				if 1 < num_spaces and string_find(msg,"[\228-\237]") then
					whisper = 1
					break
				end
			end
			local filters = profile.spam_filter_keywords
			if filters then
				msg = msg:lower()
				for i=1,#filters do
					if string_find(msg,filters[i]) then
						whisper = 1
						break
					end
				end
				if profile.spam_filter_player_name then
					player = player:lower()
					for i=1,#filters do
						if string_find(player,filters[i]) then
							whisper = 1
							break
						end
					end
				end
			end
		end
		until true
		end
		repeat
		if whisper then
			filteredlineid = line_id
			local cvar
			if tag == 4 then
				cvar = "chatBubbles"
			elseif tag == 5 then
				cvar = "chatBubblesParty"
			end
			local temp 
			if cvar then
				temp = GetCVarBool(cvar)
			end
			local wmsg
			if whisper == 1 then
				wmsg = db.profile.sf_whisper
			elseif whisper == 2 then
				wmsg = db.profile.addon_ft_whisper and "<LFG>Please shut down spamming of your addon." or nil
			end
			local timer = C_Timer.NewTimer(2, function()
				ClassicLFR.resume(current,0)
			end)
			if temp then
				SetCVar(cvar,false)
			end
			if wmsg then
				SendChatMessage(wmsg,"WHISPER",nil,player)
			end
			while true do
				tag, event, msg, player, language, arg6, arg7, flag, channelId, channelNum, arg11, arg12, line_id, guid = coroutine.yield()
				if wmsg and tag == 7 then
					filteredlineid = line_id
				else
					break
				end
			end
			timer:Cancel()
			if temp then
				SetCVar(cvar,temp)
			end
			if tag ~= 0 then
				break
			end
		elseif tag == 1 then
			if DBM then
				DBM:CHAT_MSG_WHISPER(event, msg, player, language, arg6, arg7, flag, channelId, channelNum, arg11, arg12, line_id, guid)
			end
		end
		tag, event, msg, player, language, arg6, arg7, flag, channelId, channelNum, arg11, arg12, line_id, guid = coroutine.yield()
		until true
	end
end

function SF:OnInitialize()
	local db = ClassicLFR.db
	local defaults = ClassicLFR.db.defaults
	defaults.profile.addon_filters =
	{
		"%d+/%d+$",
		"^%[WQ.*%]",
		"^进度:",
		"^PS 死亡:",
		"^<大脚.*提示>",
		"^大脚.*提示:",
		"^<BF .*>",
		"%(任务完成%)$",
		"^【.*】",
		"打断.+的.+|Hspell",
		"^Quest progress:",
		"^EUI:",
		"^任务: %[%d+%]",
		"任务进度提示%s?[:：]",
		"EUI_RaidCD",
		"%*%*.+%*%*",
		"%[接受任务%]",
		"<iLvl>",
		("%-"):rep(30),
		"<小队物品等级:.+>",
		"^<EH>",
		"^%[World Quest.*%]",
		"%(World Quest.*%)$",
		"任务<.+>%",
		"任务吧"
	}
	db:RegisterDefaults(defaults)
end

function SF:OnEnable()
	coroutine.wrap(cofunc)()
end
