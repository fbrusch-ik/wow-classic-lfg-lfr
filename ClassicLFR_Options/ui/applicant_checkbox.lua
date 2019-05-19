local AceGUI = LibStub("AceGUI-3.0")
local ClassicLFR = LibStub("AceAddon-3.0"):GetAddon("ClassicLFR")
local ClassicLFR_Options = LibStub("AceAddon-3.0"):GetAddon("ClassicLFR_Options")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("ClassicLFR")

local function AlignImage(self)
	local img = self.image:GetTexture()
	self.text:ClearAllPoints()
	if not img then
		self.text:SetPoint("LEFT", self.checkbg, "RIGHT")
		self.text:SetPoint("RIGHT")
	else
		self.text:SetPoint("LEFT", self.image,"RIGHT", 1, 0)
		self.text:SetPoint("RIGHT")
	end
end

local LFGListApplicanter =
{
	notCheckable = true,
}
LFGListApplicanter.__index = LFGListApplicanter

function LFGListApplicanter:new(o)
	setmetatable(o,self)
	return o
end

local function backfunc()
	if ClassicLFR_Options.option_table.args.requests then
		AceConfigDialog:SelectGroup("ClassicLFR","requests")
	end
end

local function paste(text)
	ClassicLFR_Options.Paste(text,backfunc)
end

local armory_menu = {}
local concat_tb = {}

local function update_armory_menu()
	wipe(armory_menu)
	local k,v
	for k,v in pairs(ClassicLFR_Options.armory) do
		armory_menu[#armory_menu + 1] = LFGListApplicanter:new(
		{
			text = k,
			func = function(_, id,memberIdx)
				local applicantName = C_LFGList.GetApplicantMemberInfo(id,memberIdx)
				if applicantName then
					local armory_link = v(applicantName)
					if armory_link then
						paste(armory_link)
					end
				end
			end,
		})
	end
	table.sort(armory_menu,function(a,b)
		return a.text < b.text
	end)
end
ClassicLFR_Options:RegisterMessage("UpdateArmory",update_armory_menu)
local tank_icon = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:0:19:22:41|t"
local healer_icon = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:1:20|t"
local damager_icon = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:22:41|t"

local CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
local LFG_LIST_APPLICANT_MEMBER_MENU

local function GetApplicantMemberMenu(applicantID, memberIdx)
	LFGListApplicanter.arg1 = applicantID
	LFGListApplicanter.arg2 = memberIdx
	if LFG_LIST_APPLICANT_MEMBER_MENU == nil then
		update_armory_menu()
		LFG_LIST_APPLICANT_MEMBER_MENU =
		{
			{
				notCheckable = true,
				disabled = true
			},
			LFGListApplicanter:new({text = WHISPER,
			func = function(_, id,memberIdx)
				local applicantName = C_LFGList.GetApplicantMemberInfo(id,memberIdx)
				if applicantName then
					ChatFrame_SendTell(applicantName)
				end
			end}),
			{
				text = ROLE,
				hasArrow = true,
				notCheckable = true,
				menuList =
				{
				}
			},
			{
				text = CALENDAR_COPY_EVENT,
				hasArrow = true,
				notCheckable = true,
				menuList =
				{
					LFGListApplicanter:new(
					{
						text = NAME,
						func = function(_, id, memberIdx)
							local applicantName = C_LFGList.GetApplicantMemberInfo(id,memberIdx)
							if applicantName then
								paste(applicantName)
							end
						end,
					}),
					LFGListApplicanter:new(
					{
						text = LFG_LIST_BAD_DESCRIPTION,
						func = function(_, id)
							paste(C_LFGList.GetApplicantInfo(id).comment)
						end,
					}),
				}
			},
			{
				text = L.Armory,
				hasArrow = true,
				notCheckable = true,
				menuList = armory_menu
			},
			{
				text = IGNORE,
				hasArrow = true,
				notCheckable = true,
				menuList =
				{
					LFGListApplicanter:new({text = PLAYER,func = function(_,id,memberIdx)
						local applicantName = C_LFGList.GetApplicantMemberInfo(id,memberIdx)
						if applicantName then
							AddIgnore(applicantName)
						end
						C_LFGList.DeclineApplicant(id)
					end}),
					LFGListApplicanter:new({text = FRIENDS_LIST_REALM:match("^(.*)%:") or FRIENDS_LIST_REALM:match("^(.*)%：") or FRIENDS_LIST_REALM,func = function(_,id,memberIdx)
						local applicantName = C_LFGList.GetApplicantMemberInfo(id,memberIdx)
						if applicantName then
							local _,realm = strsplit("-",applicantName)
							if realm then
								ClassicLFR_Options:add_realm_filter(realm)
							end
						end
						C_LFGList.DeclineApplicant(id)
					end}),
				}
			},
			{
				text = LFG_LIST_REPORT_FOR,
				hasArrow = true,
				notCheckable = true,
				menuList =
				{
					LFGListApplicanter:new({text = LFG_LIST_BAD_PLAYER_NAME,func = function(_,id,memberIdx) C_LFGList.ReportApplicant(arg1,"badplayername",memberIdx); end}),
					LFGListApplicanter:new({text = LFG_LIST_BAD_DESCRIPTION,func = function(_,id) C_LFGList.ReportApplicant(arg1,"lfglistappcomment"); end}),
				}
			},
			{
				text = CANCEL,
				notCheckable = true,
			},
		}
	end
	local name, class, localizedClass, level, itemLevel, honorLevel, tank, healer, damage, assignedRole, relationship = C_LFGList.GetApplicantMemberInfo(applicantID,memberIdx)
	LFG_LIST_APPLICANT_MEMBER_MENU[1].text = table.concat{"|c",CLASS_COLORS[class].colorStr,name,"|r"}
	local roleMenuList = LFG_LIST_APPLICANT_MEMBER_MENU[3].menuList
	wipe(roleMenuList)
	if tank then
		roleMenuList[#roleMenuList + 1] = LFGListApplicanter:new(
		{
			text = tank_icon..TANK,
			func = function(_, id, memberIdx)
				C_LFGList.SetApplicantMemberRole(id,memberIdx,"TANK")
			end,
		})
	end
	if healer then
		roleMenuList[#roleMenuList + 1] = LFGListApplicanter:new(
		{
			text = healer_icon..HEALER,
			func = function(_, id, memberIdx)
				C_LFGList.SetApplicantMemberRole(id,memberIdx,"HEALER")
			end,
		})
	end
	if damage then
		roleMenuList[#roleMenuList + 1] = LFGListApplicanter:new(
		{
			text = damager_icon..DAMAGER,
			func = function(_, id, memberIdx)
				C_LFGList.SetApplicantMemberRole(id,memberIdx,"DAMAGER")
			end,
		})
	end
	return LFG_LIST_APPLICANT_MEMBER_MENU
end

local max_lvl = GetMaxPlayerLevel()
local concat_tb = {}

local function member_info(id,i)
	local name, class, localizedClass, level, itemLevel, honorLevel, tank, healer, damage, assignedRole, relationship = C_LFGList.GetApplicantMemberInfo(id,i)
	if i ~= 1 then
		concat_tb[#concat_tb+1] = "\n"
	end
	if assignedRole == "DAMAGER" then
		concat_tb[#concat_tb+1] = damager_icon
	elseif assignedRole == "HEALER" then
		concat_tb[#concat_tb+1] = healer_icon
	elseif assignedRole == "TANK" then
		concat_tb[#concat_tb+1] = tank_icon
	end
	if level ~= max_lvl then
		concat_tb[#concat_tb+1] = LEVEL_ABBR
		concat_tb[#concat_tb+1] = ":"
		concat_tb[#concat_tb+1] = level
		concat_tb[#concat_tb+1] = " "
	end
	concat_tb[#concat_tb+1] = math.floor(itemLevel)
	concat_tb[#concat_tb+1] = " |c"
	concat_tb[#concat_tb+1] = CLASS_COLORS[class].colorStr
	concat_tb[#concat_tb+1] = name
	concat_tb[#concat_tb+1] = " "
	concat_tb[#concat_tb+1] = localizedClass
	concat_tb[#concat_tb+1] = "|r"
	local roles = 0
	if tank then
		roles = roles + 1
	end
	if healer then
		roles = roles + 1
	end
	if damage then
		roles = roles + 1
	end
	if 1< roles then
		concat_tb[#concat_tb+1] = " "
		if tank then
			concat_tb[#concat_tb+1] = tank_icon
		end
		if healer then
			concat_tb[#concat_tb+1] = healer_icon
		end
		if damage then
			concat_tb[#concat_tb+1] = damager_icon
		end
	end
	if relationship ~= nil then
		concat_tb[#concat_tb+1] = " "
		concat_tb[#concat_tb+1] = relationship
	end
	local brief = ClassicLFR_Options.lfgscoresbrief
	if brief then
		for j=1,#brief do
			concat_tb[#concat_tb+1] = " "
			concat_tb[#concat_tb+1] = brief[j](id,i,name)
		end
	end
end

function ClassicLFR_Options.updateapplicant(obj)
	local users = obj:GetUserDataTable()
	local info = C_LFGList.GetApplicantInfo(users.val)
	if not info then
		return
	end
	local id = info.applicantID
	local comment = info.comment
	local numMembers = info.numMembers
	obj.text:SetText(comment)
	obj.text:SetTextColor(1,0.82,0)
	wipe(concat_tb)
	for i=1,numMembers do
		member_info(id,i)
	end
	if numMembers == 1 and comment == "" then
		obj.text:SetText(table.concat(concat_tb))	
	else
		obj:SetDescription(table.concat(concat_tb))
	end
end

function ClassicLFR_Options:applicants_tooltip()
	local lfg_applicant_scores = ClassicLFR_Options.lfg_applicant_scores
	if lfg_applicant_scores then
		local owner = GameTooltip:GetOwner()
		if owner == nil then
			return
		end
		local obj = owner.obj
		local users = obj:GetUserDataTable()
		local val = users.val
		GameTooltip:ClearLines()
		local status
		for i=1,#lfg_applicant_scores do
			if lfg_applicant_scores[i](val) then
				status = true
			end
		end
		if status then
			GameTooltip:Show()
		end
	end
end

AceGUI:RegisterWidgetType("ClassicLFR_applicant_checkbox", function()
	local check = AceGUI:Create("CheckBox")
	local frame = check.frame
	frame:RegisterForClicks("LeftButtonDown","RightButtonDown")
	frame:SetScript("OnMouseUp",function(self,button)
		local obj = self.obj
		local user = obj:GetUserDataTable()
		if button == "LeftButton" then
			if not obj.disabled then
--				obj:ToggleChecked()
				if obj.checked then
					PlaySound(856)
				else -- for both nil and false (tristate)
					PlaySound(857)
				end
				
				obj:Fire("OnValueChanged", obj.checked)
				AlignImage(obj)
			end
		else
			local info = C_LFGList.GetApplicantInfo(user.val)
			local numMembers = info.numMembers
			if numMembers == 1 then
				EasyMenu(GetApplicantMemberMenu(info.applicantID,1), LFGListFrameDropDown, "cursor" , 0, 0, "MENU")
			else
				local cursor_x,cursor_y = GetCursorPosition()
				local desc = obj.desc
				local pos = math.floor((desc:GetTop()-cursor_y/UIParent:GetEffectiveScale()) / desc:GetHeight() * numMembers + 1)
				if pos < 1 then
					pos = 1
				end
				if numMembers < pos then
					pos = numMembers
				end
				EasyMenu(GetApplicantMemberMenu(info.applicantID,pos), LFGListFrameDropDown, "cursor" , 0, 0, "MENU")
			end
		end
	end)
	check.updateapplicant = ClassicLFR_Options.updateapplicant
	frame:SetScript("OnLeave", function(self,...)
		GameTooltip:Hide()
	end)
	frame:SetScript("OnEnter", function(self,...)
		GameTooltip:SetOwner(self,"ANCHOR_TOPRIGHT")
		ClassicLFR_Options:applicants_tooltip()
	end)
	function check:OnAcquire()
		self:SetType()
		self:SetValue(false)
		self:SetTriState(nil)
		-- height is calculated from the width and required space for the description
		self:SetWidth(200)
		self:SetImage()
		self:SetDisabled(false)
		self:SetDescription(nil)
		self.width = "fill"
	end
	check.type = "ClassicLFR_applicant_checkbox"
	return AceGUI:RegisterAsWidget(check)
end, 1)
