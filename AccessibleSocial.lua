local ENABLED = "enabled"
local ENABLE = "enable"
local DISABLED = "disabled"
local DISABLE = "disable"
local VOICE = "voice"
local NOVOICE = "novoice"
local REPLAY = "replay"
local GUILD = "guild"
local ONLINE = "online"
local OFFLINE = "offline"
local INVITEBNET = "invitebnet"
local LISTBNET = "listbnet"
local FRIENDS = "friends"
local INVITEGUILDIE = "inviteguildie"

local friends = {}
local bnetFriendList = {}
local guildieList = {}

AccessibleSocial = LibStub("AceAddon-3.0"):NewAddon("AccessibleSocial", "AceConsole-3.0", "AceEvent-3.0")
AS = AccessibleSocial

--- Determine if our settings allow printing
---@return boolean
local function IsPrintEnabled()
    local enablement = ASDB ~= nil and ASDB.enabled == true
    return enablement
end

local function GetBnetClientDesc(client)
    local desc = "Unknown Client"
    if client == BNET_CLIENT_WOW then 
        desc = "World of Warcraft"
    elseif client == BNET_CLIENT_APP then 
        desc = "Battle.net desktop app"
    elseif client == BNET_CLIENT_HEROES then 
        desc = "Heroes of the Storm"
    elseif client == BNET_CLIENT_CLNT then 
        desc = "CLNT"
    elseif client == "BSAp" then
        desc = "Blizzard Services (Mobile)"
    elseif client == "App" then
        desc = "Blizzard Services (App)"
    end

    return desc
    
end

--- Our custom print function.  Will print to screen and check the addon voice setting before concatenating the strings to text-to-speech.
---@param printString1 string First string to print/read
---@param ... string Additional strings to print/read
local function AccessiblePrintWithPrefix(printString1, ...)
    if IsPrintEnabled() then
        AS:Print(printString1, ...)
        TextToSpeech_Speak("AccessibleSocial " .. printString1.. ..., TextToSpeech_GetSelectedVoice(0))
    end
end

local function AccessiblePrint(printString1, ...)
    if IsPrintEnabled() then
        AS:Print(printString1, ...)
        TextToSpeech_Speak(printString1.. ..., TextToSpeech_GetSelectedVoice(0))
    end
end

local function PrintAddonStatus()
    local enabledString = ENABLED

    if not IsPrintEnabled() then
        enabledString = DISABLED
        AS:Print(enabledString)
    end

    AccessiblePrintWithPrefix(enabledString, "")
end

--- Determine if we should be printing, then get the achievement info and call our print function.
local function PrintFriend(accountInfo)
    if (IsPrintEnabled() and accountInfo ~= nil) then
            local battleTag = accountInfo.battleTag
            local isOnline = accountInfo.gameAccountInfo.isOnline or (accountInfo.lastOnlineTime == nil)
            local characterName = accountInfo.gameAccountInfo.characterName
            local skipPrint = false

            local oldStatus = friends[battleTag]

            if oldStatus ~= nil then
                if oldStatus.charName == characterName then
                    if oldStatus.isOnline == isOnline then
                        -- Same character, same status, don't print
                        skipPrint = true
                    end
                end
            end

            if skipPrint == false then
                friends[battleTag] = {
                    charName = characterName,
                    isOnline = isOnline
                }
                local onlineStatus = (isOnline == true and ONLINE) or OFFLINE
                if isOnline == true and characterName ~= nil then
                    AccessiblePrintWithPrefix("BattleNet: "..battleTag, "is "..onlineStatus.." on "..characterName)
                else
                    AccessiblePrintWithPrefix("BattleNet: "..battleTag, "is "..onlineStatus)
                end
            end
    end
end

function PrintGuild()
    local numTotalGuildMembers, numOnlineGuildMembers, _ = GetNumGuildMembers()
    guildieList = {}

    AccessiblePrintWithPrefix(numOnlineGuildMembers.." guildies online out of", numTotalGuildMembers.." total members")
    local onlineCount = 0
    for gIndex=1, numTotalGuildMembers do
        local name, rankName, _, level, classDisplayName, zone, _, _, isOnline, _ = GetGuildRosterInfo(gIndex)
        if(isOnline) then
            onlineCount = onlineCount + 1
            PrintGuildie(onlineCount, name, rankName, level, classDisplayName, zone)
        end
    end
end

function PrintGuildie(index, name, rankName, level, classDisplayName, zone)
    guildieList[index] = name
    AccessiblePrint("Guildie "..index..": "..rankName.." "..name, "level " .. level.." "..classDisplayName.." location: "..zone)
end

function ListBnetFriends()
    bnetFriendList = {}

    local total, online = BNGetNumFriends()
    AccessiblePrint("You have "..total.." Battle.net friends and", online.." of them are online!")
    local onlineIndex = 1
    
    for bIndex=1, total do
        local friend = C_BattleNet.GetFriendAccountInfo(bIndex)
        bnetFriendList[bIndex] = friend
    end


    for fIndex=1, total do
        local indexString = "Friend "..fIndex
        local friend = bnetFriendList[fIndex]
        local descString = ""
        local isOnline = friend.gameAccountInfo.isOnline or (friend.lastOnlineTime == nil)
            
        if(friend.gameAccountInfo ~= nil and isOnline and friend.gameAccountInfo.clientProgram ~= nil) then
            descString = friend.battleTag.." is online in "..GetBnetClientDesc(friend.gameAccountInfo.clientProgram)
            if(friend.gameAccountInfo.characterName ~= nil) then
                descString = descString.." on toon "..friend.gameAccountInfo.characterName
            end
        elseif isOnline then
            descString = friend.battleTag.." is online"
        else
            descString = friend.battleTag.." is offline"
        end
        AccessiblePrint(indexString, descString)
    end
end

function InviteFriend(friendIndex)
    local friend = bnetFriendList[tonumber(friendIndex)]
    if(friend ~= nil and friend.gameAccountInfo ~= nil and friend.gameAccountInfo.clientProgram == BNET_CLIENT_WOW) then
        local friendName = friend.gameAccountInfo.characterName.."-"..friend.gameAccountInfo.realmName
        AccessiblePrint("About to invite", friendName)
        C_PartyInfo.InviteUnit(friendName)
    end
end

function InviteGuildie(guildieIndex)
    local guildie = guildieList[tonumber(guildieIndex)]
    if(guildie ~= nil) then
        AccessiblePrint("About to invite", guildie)
        C_PartyInfo.InviteUnit(guildie)
    end
end

function AS:OnInitialize()
    AS:Print("OnInitialize")

    local defaults = {
        enabled = true,
        sturdiness = 100
    }

    if (ASDB == nil) then
        ASDB = defaults
    end

    AS:RegisterChatCommand("as", "SlashCommand")
    AS:RegisterChatCommand("accessiblesocial", "SlashCommand")
end

function AS:OnEnable()
    AS:Print("OnEnable")
    AS:RegisterEvent("AUTOFOLLOW_BEGIN")
    AS:RegisterEvent("AUTOFOLLOW_END")
    AS:RegisterEvent("BN_FRIEND_INFO_CHANGED")
    AS:RegisterEvent("STURDINESS_UPDATE")
    -- f:RegisterEvent("CHAT_MSG_BN_WHISPER")
    -- f:RegisterEvent("CHAT_MSG_INSTANCE_CHAT")
    -- f:RegisterEvent("CHAT_MSG_RAID")
    -- f:RegisterEvent("CHAT_MSG_WHISPER")
    -- f:RegisterEvent("CHAT_MSG_BN")
    -- f:RegisterEvent("CHAT_MSG_SKILL") -- Profession?
    -- f:RegisterEvent("CHAT_MSG_PARTY")
    -- Send on BN whisper, read it back
    -- Read who is doing what on battlenet
    -- Send a message


    PrintAddonStatus()
end

function AS:BN_FRIEND_INFO_CHANGED(eventName, friendIndex)
    if friendIndex ~= nil then
        local accountInfo = C_BattleNet.GetFriendAccountInfo(friendIndex)
        PrintFriend(accountInfo)
    end
end

function AS:AUTOFOLLOW_BEGIN(event, name)
    AccessiblePrintWithPrefix("Autofollowing ", name)
end

function AS:AUTOFOLLOW_END(event)
    AccessiblePrintWithPrefix("No longer Autofollowing", "anyone")
end

function AS:STURDINESS_UPDATE(event)
    local currentSturdiness = GetSturdiness()
    local durability = "Durability is now " .. currentSturdiness
    -- AS:Print(durability)
    if ASDB.sturdiness ~= nil then
        if(ASDB.sturdiness < 10) then
            ASDB.sturdiness = currentSturdiness
            AccessiblePrint("Repair now.", durability)
        elseif (ASDB.sturdiness < 50 and ASDB.sturdiness > (currentSturdiness + 5)) then
            ASDB.sturdiness = currentSturdiness
            AccessiblePrint("Repair soon.", durability)
        elseif(ASDB.sturdiness > (currentSturdiness + 9)) then
            ASDB.sturdiness = currentSturdiness
            AccessiblePrint("Don't forget to repair.", durability)
        end
    else
        ASDB.sturdiness = currentSturdiness
    end

end

-- Configure slash commands for enable and disable of the printing
function AS:SlashCommand(msg)
    local cmd1, cmd2 = strsplit(" ", msg)
    local orAS = " or /as "
    local help1 = "Enter a command: /as "..ENABLE..orAS..DISABLE..orAS..GUILD..orAS..FRIENDS
    local help2 = orAS..INVITEBNET.." followed by the number from "..FRIENDS.."for that friend"..orAS..INVITEGUILDIE.." followed by the number from "..GUILD.." for that guild member"

    if #cmd1 > 0 then
        cmd1 = strlower(cmd1)

        if cmd1 == ENABLED or cmd1 == ENABLE or cmd1 == VOICE then
            ASDB.enabled = true
            PrintAddonStatus()
        elseif cmd1 == DISABLED or cmd1 == DISABLE or cmd1 == NOVOICE then
            ASDB.enabled = false
            PrintAddonStatus()
        elseif cmd1 == GUILD then
            PrintGuild()
        elseif cmd1 == INVITEBNET then
            InviteFriend(cmd2)
        elseif cmd1 == LISTBNET or cmd1 == FRIENDS then
            ListBnetFriends()
        elseif cmd1 == INVITEGUILDIE then
            InviteGuildie(cmd2)
        else
            AccessiblePrintWithPrefix(help1, help2)
        end
    else
        AccessiblePrintWithPrefix(help1, help2)
    end
end


