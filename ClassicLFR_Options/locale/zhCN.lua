local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:NewLocale("ClassicLFR", "zhCN") or AceLocale:NewLocale("ClassicLFR", "zhTW")
if not L then return end
L["Armory"] = "英雄榜"
L["Auto"] = "自动"
L["auto_disable_desc"] = "禁用任务/侵入点/精英等各种LFG自动队自动弹出。事实上你不需要禁用这个选项因为LFG会在当你离开这些区域的时候自动关闭静态弹出框。"
L["auto_leave_party_desc"] = [=[正常勾 = 任务完成后自动离开队伍
暗勾 = 永不自动离开队伍即使玩家在飞行
无勾 = 只在玩家飞行时自动离开队伍]=]
L["auto_no_info_quest"] = "屏蔽无信息任务"
L["auto_no_info_quest_desc"] = "屏蔽不能从API得到信息的任务。启用该选项可以屏蔽很多烦人的任务但也同样可能屏蔽有意义的任务。"
L["auto_report"] = "自动举报"
L["auto_report_desc"] = "自动举报游戏LFG系统里的垃圾信息队伍"
L["auto_wq_only_desc"] = "只接受%s"
L["Backfill"] = "补人"
L["background_search"] = "后台搜索"
L["bwlist_desc"] = [=[正常勾 = %s黑名单
暗勾 = %s白名单
无勾 = %s]=]
L["cr_realm_rand_hop"] = "随机跨服"
L["cr_realm_rand_hop_desc"] = [=[跨到一个随机的服务器。Ctrl+右击小地图图标同样会干同样的事。
宏: /lfg cr rand_hop
您还可以在ESC-按键设置-插件-ClassicLFR-Random Hop里绑定你的键位]=]
L["cr_realm_scan"] = "扫描你的服务器"
L["cr_realm_scan_desc"] = [=[扫描你的当前服务器。右击小地图图标会干同样的事。
您还可以在ESC-按键设置-插件-ClassicLFR-Scan Your Realm里绑定你的键位]=]
L["Cross Realm"] = "跨服"
L["digits_desc"] = "刷屏信息通常有一大堆的数字。这个选项控制了描述中最多的数字数量可以是多少。"
L["enable_levenshtein_desc"] = [=[Levenshtein距离是用来过滤LFG中有一大堆相似描述的团。不要启用这个选项如果你所在的区域没有大规模的刷屏因为这个算法极慢。

算法: 动态规划
时间复杂度: Θ(n^4)]=]
L["Fast"] = "快速"
L["Fast_desc"] = "统计意义上最短组队时间的职责配比"
L["find_f_advanced_class"] = "有>=2个和你相同职业的队伍"
L["find_f_advanced_complete"] = "至少有2/3人数的那个活动的团"
L["find_f_advanced_gold"] = "金团搜索"
L["find_f_advanced_role"] = "依据你的职责。举个例子，如果你是治疗，你就不会在搜索结果里看到有治疗的5人本队"
L["find_f_encounters"] = [=[正常勾 = 这个boss必须被击杀过。
暗勾 = 这个boss必须未被击杀过。
无勾 = 不在乎这个boss是否被击杀过]=]
L["find_recommended_desc"] = [=[正常勾 = 只显示推荐的活动
暗勾 = 显示其它活动
无勾 = 显示全部活动]=]
L["hyperlinks_desc"] = "刷屏信息通常有一大堆的超链接。这个选项控制了描述中最多的超链接数量可以是多少。"
L["Keywords"] = "关键字"
L["language_sf_desc"] = "强化版的BlockChinese插件。不仅可以屏蔽中文和韩文，同时还能屏蔽其它语言。"
L["Levenshtein Distance"] = "Levenshtein距离"
L["levenshtein_desc"] = "Levenshtein距离是用于测量两个序列之间差异的字符串度量，非正式的讲，是两个单词之间的Levenshtein距离是将一个单词更改为另一个单词所需的单字符编辑（插入，删除或替换）的最小数量。 由苏联数学家Vladimir Levenshtein在1965年发明，因而以他的名字来命名。"
L["max_length_desc"] = "刷屏的文本通常非常的长。这个选项限制了一个LFG团的最大文本长度可以为多少。"
L["Maximum Text Length"] = "最大文本长度"
L["must_input_title"] = "你必须输入%s在你%s之前"
L["must_select_xxx"] = "你必须选择一个%s在你%s之前"
L["options_advanced_complete"] = "如果启用，复制队伍名或描述时将不会过滤垃圾信息而是完整复制"
L["options_advanced_hardware"] = "使得LFG运行在保护态下。如有需要，会自动打开。"
L["options_advanced_mute"] = "如果启用，不会播放任何声音且小地图图标不会闪烁"
L["options_advanced_role_check"] = "如果启用，你将在每次申请前确认职责和注释。否则，你应当在|cffff2020%s|r选项页修改默认申请设置。"
L["options_auto_fnd_desc"] = [=[亮勾 = 手动选择寻找或创建队伍
无勾 = 自动寻找或创建队伍]=]
L["options_auto_start_desc"] = [=[亮勾 = 强制自行创建队伍
暗勾 = 永不创建队伍
无勾 = 无相关队伍时创建队伍]=]
L["options_sort_shuffle_desc"] = "搜索结果将被打乱，覆盖其他排序选项"
L["options_window"] = "窗口大小"
L["rand_rare"] = "随机稀有"
L["rand_rare_desc"] = [=[跨到一个随机的服务器抓稀有。Shift+右击小地图图标同样会干同样的事。
宏: /lfg cr rand_rare
您还可以在ESC-按键设置-插件-ClassicLFR-Random Rare里绑定你的键位]=]
L["Relist"] = "重新列出队伍"
L["sf_add_desc"] = "在这里添加你的过滤关键字。不要试图在你的地区有20%以上的刷屏团通过添加关键字的方式来过滤LFG团因为这只会鼓励刷屏者尝试各种各样的办法来绕过过滤器，并且还可能不正确的过滤正常团。"
L["sf_dk_desc"] = "刷屏者通常会使用一大堆的55级死亡骑士来创建LFG团。这个选项在中国区域非常有效，能消灭80%以上的LFG刷屏。"
L["sf_ilvl"] = "很多刷屏者会创建很奇怪的iLvl要求的团队"
L["sf_invite_relationship_desc"] = "只允许和你有关系的人邀请你。"
L["sf_language_lfg"] = "让语言屏蔽器不光对聊天信息有效，还会作用于LFG团"
L["sf_player_name_desc"] = "对玩家名应用垃圾信息过滤器"
L["sf_solo"] = "刷屏者往往只用一个角色来创建LFG团用来广告。这个选项会移除LFG里所有只有一个角色的团。"
L["sf_whisper_desc"] = "很多插件（例如WQGF, WQA）一直在聊天频道里刷屏以为自己做广告。并且很多的中国人使用插件整合包，这些插件整合包会整页整页的刷屏。打开这个选项会通过发消息让这些刷屏者关掉这些插件来与这些插件做斗争。"
L["solo_hint"] = "请在%s文本框里输入点东西在你按%s按钮前"
L["Taskbar Flash"] = "任务栏闪烁"

