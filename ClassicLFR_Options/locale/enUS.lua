local L = LibStub("AceLocale-3.0"):NewLocale("ClassicLFR", "enUS", true)

L["Armory"] = true
L["Auto"] = true
L["auto_disable_desc"] = "Disabling quests/invasion points/elites, etc of all kinds of LFG auto groups from automatically popping up. You do not actually need to disable this since LFG will close static popup when you leave those areas."
L["auto_leave_party_desc"] = [=[Normal Click = Leave party after finishing quests automatically
Dark Click = Never leave party automatically even player is flying
No Click = Only leave party automatically when the player is flying]=]
L["auto_no_info_quest"] = "Block No Info Quest"
L["auto_no_info_quest_desc"] = "Block quests which are not able to get info from API. Enabling this might block a lot of annoying quests but meaningful quests as well."
L["auto_report"] = "Auto Report"
L["auto_report_desc"] = "Automatically report spamming groups in LFG system"
L["auto_wq_only_desc"] = "%s Only"
L["Backfill"] = true
L["background_search"] = "Background Search"
L["bwlist_desc"] = [=[Normal Click = %s Blacklist
Dark Click = %s Whitelist
No Click = %s]=]
L["cr_realm_rand_hop"] = "Random Hop"
L["cr_realm_rand_hop_desc"] = [=[Hop to a random realm. Ctrl + Right-click minimap icon would also do this.
Macro: /lfg cr rand_hop
You can also bind your key in the ESC-Key Bindings-AddOns-ClassicLFR-Random Hop
]=]
L["cr_realm_scan"] = "Scan Your Realm"
L["cr_realm_scan_desc"] = [=[Scanning your current realm. Right-click minimap icon would also do this.
You can also bind your key in the ESC-Key Bindings-AddOns-ClassicLFR-Scan Your Realm]=]
L["Cross Realm"] = true
L["digits_desc"] = "Spams always have a lot of numbers in their descriptions. This option controls the maximum count of numbers a description could have."
L["enable_levenshtein_desc"] = [=[Levenshtein Distance is used for filtering a lot of spamming groups with similar descriptions in LFG. Do not enable this if your region does not have a large scale of spamming since this algorithm is extremely slow.

Algorithm: Dynamic Programming
Time Complexity: Θ(n^4)]=]
L["Fast"] = true
L["Fast_desc"] = "Statistically the shortest grouping time of roles matching"
L["find_f_advanced_class"] = "Groups have >= 2 your class"
L["find_f_advanced_complete"] = "Groups have at least 2/3 people of that activity"
L["find_f_advanced_gold"] = "WTS/RMT Groups Searching"
L["find_f_advanced_role"] = "Filter groups based on your role. For example, if you are a healer, you will not see dungeon groups with a healer in the search results."
L["find_f_encounters"] = [=[Normal Click = This boss must be defeated
Dark Click = This boss must not be defeated
No Click = Do not care whether this boss is defeated or not.]=]
L["find_recommended_desc"] = [=[Normal Click = Display recommended activities only
Dark Click = Display other activities
No Click = Display all activities]=]
L["hyperlinks_desc"] = "Spams always have a lot of hyperlinks in their descriptions. This option controls the maximum count of hyperlinks a description could have."
L["Keywords"] = true
L["language_sf_desc"] = "An empowered version of AddOn BlockChinese. It can block not only Chinese/Korean but other languages as well."
L["Levenshtein Distance"] = true
L["levenshtein_desc"] = "The Levenshtein distance is a string metric for measuring the difference between two sequences. Informally, the Levenshtein distance between two words is the minimum number of single-character edits (insertions, deletions or substitutions) required to change one word into the other. It is named after the Soviet mathematician Vladimir Levenshtein, who considered this distance in 1965."
L["max_length_desc"] = "Spamming texts are always very long. This option restricts the maximum text length an LFG group could be."
L["Maximum Text Length"] = true
L["must_input_title"] = "You must input %s before you %s"
L["must_select_xxx"] = "You must select a(n) %s before you %s"
L["options_advanced_complete"] = "If enabled, copying group name or description will not filter spam but completely"
L["options_advanced_hardware"] = "Make LFG running under protected mode. Automatically enabled if needed."
L["options_advanced_mute"] = "If enabled, no sound will play and minimap icon will not shine"
L["options_advanced_role_check"] = "If enabled, you will confirm role and comment before each application. Otherwise, you should change default settings of application in |cffff2020%s|r option page."
L["options_auto_fnd_desc"] = [=[Normal Click = Manually choose to find or create a group
No click = Auto find or create a group]=]
L["options_auto_start_desc"] = [=[Normal Click = ALWAYS create a group
Dark Click = NEVER create a group
No click = Create a group if there are no relative groups]=]
L["options_sort_shuffle_desc"] = "The search result will be shuffled, overwrite other sort option"
L["options_window"] = "Window Size"
L["rand_rare"] = "Random Rare"
L["rand_rare_desc"] = [=[Hop to a random realm for rare. Shift + Right-click minimap icon would also do this.
Macro: /lfg cr rand_rare
You can also bind your key in the ESC-Key Bindings-AddOns-ClassicLFR-Random Rare]=]
L["Relist"] = true
L["sf_add_desc"] = "Add your spamming keywords here. Do not try to add keywords for filtering LFG when your region has over 20% of spamming groups since it only encourages spammers to try all kinds of methods in order to bypass the filter and might incorrectly filter normal groups."
L["sf_dk_desc"] = "Spammers always use a lot of lvl 55 Death Knights to create LFG groups. This toggle is extremely effective and kills over 80% of LFG spamming in Chinese Region."
L["sf_ilvl"] = "A lot of spammers create groups with the strange iLvl requirement."
L["sf_invite_relationship_desc"] = "Only allows people related you to invite you."
L["sf_language_lfg"] = "Apply Language Blocker not only to Chat but LFG as well."
L["sf_player_name_desc"] = "Apply spam filters on the player names"
L["sf_solo"] = "Spammers always create LFG groups with only 1 character in order to advertise. This toggle will remove all groups in LFG with only 1 character."
L["sf_whisper_desc"] = "A lot of AddOns (like WQGF, WQA) just keep spamming in chat in order to advertise themselves. Also, a lot of Chinese use AddOns packages which keep spamming pages and pages long of spamming messages. Enabling this toggle will fight against these AddOns by notifying spammers to shut down them down."
L["solo_hint"] = "Please input something into the %s edit box before you click %s button."
L["Taskbar Flash"] = true

