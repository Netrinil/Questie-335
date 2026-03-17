local Questie = _G.Questie
---@class QuestieAnnounce
local QuestieAnnounce = QuestieLoader:CreateModule("QuestieAnnounce")
local _QuestieAnnounce = {}
---@type QuestieDB
local QuestieDB = QuestieLoader:ImportModule("QuestieDB")
---@type QuestieLink
local QuestieLink = QuestieLoader:ImportModule("QuestieLink")
---@type l10n
local l10n = QuestieLoader:ImportModule("l10n")

--- COMPATIBILITY ---
local IsInGroup = QuestieCompat.IsInGroup
local IsInRaid = QuestieCompat.IsInRaid
local LE_PARTY_CATEGORY_INSTANCE = QuestieCompat.LE_PARTY_CATEGORY_INSTANCE

local itemCache = {} -- cache data since this happens on item looted it could happen a lot with auto loot

local alreadySentBandaid = {} -- TODO: rewrite the entire thing its a lost cause

local _GetAnnounceMarker

---@return string
_GetAnnounceMarker = function()
    local locale = l10n:GetUILocale()
    if IsInRaid() or IsInGroup() then
        if locale == "ruRU" then
            return "{звезда} Questie: ";
        elseif locale == "frFR" then
            return "{rt1} Questie : ";
        else
            return "{rt1} Questie: "
        end
    else
        return ""
    end
end

function QuestieAnnounce:AnnounceObjectiveToChannel(questId, itemId, objectiveText, objectiveProgress)
    if _QuestieAnnounce:AnnounceEnabledAndPlayerInChannel() and Questie.db.profile.questAnnounceObjectives then
        -- no hyperlink required here
        local questLink = QuestieLink:GetQuestLinkStringById(questId);

        local objective
        if itemId then
            local itemLink = select(2, GetItemInfo(itemId))
            objective = objectiveProgress.." "..itemLink
        else
            objective = objectiveProgress.." "..objectiveText
        end

        local message = _GetAnnounceMarker() .. l10n("%s for %s!", objective, questLink)
        _QuestieAnnounce:AnnounceToChannel(message)
    end
end

local _has_seen_incomplete = {}
local _has_sent_announce = {}

function QuestieAnnounce:ObjectiveChanged(questId, text, numFulfilled, numRequired)
    -- Announce completed objective
    if (numRequired ~= numFulfilled) then
        _has_seen_incomplete[text] = true
    elseif _has_seen_incomplete[text] and not _has_sent_announce[text] then
        _has_seen_incomplete[text] = nil
        _has_sent_announce[text] = true
        QuestieAnnounce:AnnounceObjectiveToChannel(questId, nil, text, tostring(numFulfilled) .. "/" .. tostring(numRequired))
    end
end


function QuestieAnnounce:AnnounceQuestItemLootedToChannel(questId, itemId)
    if _QuestieAnnounce:AnnounceEnabledAndPlayerInChannel() and Questie.db.profile.questAnnounceItems then
        local questHyperLink = QuestieLink:GetQuestLinkStringById(questId);
        local itemLink = select(2, GetItemInfo(itemId))

        local message = _GetAnnounceMarker() .. l10n("Picked up %s which starts %s!", itemLink, questHyperLink)
        _QuestieAnnounce:AnnounceToChannel(message)
        return true
    else
        return false
    end
end

function _QuestieAnnounce:AnnounceSelf(questId, itemId)
    local questHyperLink = QuestieLink:GetQuestHyperLink(questId);
    local itemLink = select(2, GetItemInfo(itemId));

    Questie:Print(l10n("You picked up %s which starts %s!", itemLink, questHyperLink));
end

---@return boolean
function _QuestieAnnounce:AnnounceEnabledAndPlayerInChannel()
    if Questie.db.profile.questAnnounceLocally == true then
        return true -- we always want to print if this option is enabled
    elseif Questie.db.profile.questAnnounceChannel == "both" then
        return IsInRaid() or IsInGroup()
    elseif Questie.db.profile.questAnnounceChannel == "raid" then
        return IsInRaid()
    elseif Questie.db.profile.questAnnounceChannel == "party" then
        return IsInGroup() and not IsInRaid()
    else
        return false
    end
end

function _QuestieAnnounce.GetChatMessageChannel()
    if IsInRaid() then
        return "RAID"
    elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT"
    else
        return "PARTY"
    end
end

function _QuestieAnnounce:AnnounceToChannel(message)
    Questie:Debug(Questie.DEBUG_DEVELOP, "[QuestieAnnounce] raw msg: ", message)
    if (not message) or alreadySentBandaid[message] or Questie.db.profile.questieShutUp then
        return
    end

    alreadySentBandaid[message] = true

    if IsInRaid() or IsInGroup() then
        SendChatMessage(message, _QuestieAnnounce.GetChatMessageChannel())
    elseif Questie.db.profile.questAnnounceLocally == true then
        Questie:Print(message)
    end
end

local playerNameCache
---@return string
local function _GetPlayerName()
    playerNameCache = UnitName("player")
    return playerNameCache
end

-- WIP, Temp measure
local attunableItemsConsumedByQuests = {
    -- Weapons
    [3851] = true,
    [3853] = true,
    [3855] = true,
    [6214] = true,
    [7945] = true,
    [7956] = true,
    [7957] = true,
    [7958] = true,
    [7971] = true,
    [12775] = true,
    [12792] = true,
    [49888] = true,
    -- Armor
    [7931] = true,
    [8193] = true,
    [8191] = true,
    [7933] = true,
    [8197] = true,
    [8185] = true,
    [7935] = true,
    [7936] = true,
    [7937] = true,
    [13858] = true,
    [13864] = true,
    [15086] = true,
    [16681] = true,
    [16671] = true,
    [16735] = true,
    [16697] = true,
    [16703] = true,
    [16722] = true,
    [16683] = true,
    [16710] = true,
    [16714] = true,
    [16680] = true,
    [16736] = true,
    [14104] = true,
    [16673] = true,
    [16696] = true,
    [16702] = true,
    [16723] = true,
    [16685] = true,
    [16713] = true,
    [16716] = true,
    [16675] = true,
    [16676] = true,
    [16670] = true,
    [16734] = true,
    [16692] = true,
    [16691] = true,
    [16704] = true,
    [16705] = true,
    [16672] = true,
    [16737] = true,
    [16725] = true,
    [16724] = true,
    [16682] = true,
    [16684] = true,
    [12417] = true,
    [16711] = true,
    [16712] = true,
    [16715] = true,
    [16717] = true,
    [16679] = true,
    [16695] = true,
    [16701] = true,
    [19610] = true,
    [19611] = true,
    [17690] = true,
    [17905] = true,
    [17906] = true,
    [17907] = true,
    [17908] = true,
    [19579] = true,
    [19585] = true,
    [12422] = true,
    [19602] = true,
    [19603] = true,
    [16729] = true,
    [19619] = true,
    [19618] = true,
    [16689] = true,
    [16669] = true,
    [19598] = true,
    [19599] = true,
    [15095] = true,
    [16708] = true,
    [21196] = true,
    [21206] = true,
    [21201] = true,
    [16733] = true,
    [17691] = true,
    [17900] = true,
    [17901] = true,
    [17902] = true,
    [17903] = true,
    [19574] = true,
    [19575] = true,
    [19592] = true,
    [19591] = true,
    [20407] = true,
    [19607] = true,
    [19606] = true,
    [15088] = true,
    [16718] = true,
    [19615] = true,
    [19614] = true,
    [16678] = true,
    [16694] = true,
    [16699] = true,
    [16668] = true,
    [16732] = true,
    [10455] = true,
    [2851] = true,
    [2310] = true,
    [4239] = true,
    [2309] = true,
    [2857] = true,
    [5387] = true,
    [5094] = true,
    [2314] = true,
    [2868] = true,
    [3482] = true,
    [3483] = true,
    [3719] = true,
    [5770] = true,
    [9362] = true,
    [2944] = true,
    [3842] = true,
    [3835] = true,
    [3836] = true,
    [6040] = true,
    [5739] = true,
    [18706] = true,
    [8663] = true,
    [3985] = true,
    [7963] = true,
    [8176] = true,
    [8175] = true,
    [8187] = true,
    [8198] = true,
    [8189] = true,
    [7922] = true,
    [8203] = true,
    [7927] = true,
    [7926] = true,
    [7928] = true,
    [9243] = true,
    [8204] = true,
    [8214] = true,
    [8211] = true,
    [7930] = true,
    [16728] = true,
    [16687] = true,
    [16709] = true,
    [16719] = true,
    [16677] = true,
    [16667] = true,
    [16693] = true,
    [16698] = true,
    [16731] = true,
    [16727] = true,
    [16686] = true,
    [16707] = true,
    [16720] = true,
    [16674] = true,
    [16730] = true,
    [16690] = true,
    [16700] = true,
    [16726] = true,
    [16688] = true,
    [16721] = true,
    [16666] = true,
    [16706] = true,
    [21197] = true,
    [21202] = true,
    [21207] = true,
    [19612] = true,
    [19586] = true,
    [19604] = true,
    [19620] = true,
    [19600] = true,
    [19576] = true,
    [19593] = true,
    [19608] = true,
    [19616] = true,
    [21208] = true,
    [21198] = true,
    [21203] = true,
    [21209] = true,
    [21199] = true,
    [21204] = true,
    [21210] = true,
    [21200] = true,
    [21205] = true,
    [29277] = true,
    [29285] = true,
    [29281] = true,
    [29289] = true,
    [29288] = true,
    [29284] = true,
    [29280] = true,
    [29276] = true,
    [29282] = true,
    [29278] = true,
    [29291] = true,
    [29286] = true,
    [29298] = true,
    [29302] = true,
    [29307] = true,
    [29294] = true,
    [29287] = true,
    [29290] = true,
    [29279] = true,
    [29283] = true,
    [29300] = true,
    [29304] = true,
    [29303] = true,
    [29299] = true,
    [29306] = true,
    [29295] = true,
    [32649] = true,
    [29308] = true,
    [29296] = true,
    [29301] = true,
    [29297] = true,
    [29309] = true,
    [29305] = true,
    [50375] = true,
    [50377] = true,
    [52569] = true,
    [50376] = true,
    [50378] = true,
    [50388] = true,
    [50384] = true,
    [52570] = true,
    [50387] = true,
    [50386] = true,
    [50403] = true,
    [50397] = true,
    [52571] = true,
    [50401] = true,
    [50399] = true,
    [50404] = true,
    [50398] = true,
    [52572] = true,
    [50402] = true,
    [50400] = true,
}

function QuestieAnnounce:ItemLooted(text, notPlayerName, _, _, playerName)
    if (playerNameCache or _GetPlayerName()) == playerName or (string.len(playerName) == 0 and playerNameCache == notPlayerName) then
        local itemId = tonumber(string.match(text, "item:(%d+)"))
        if not itemId then return end
        local startQuestId = itemCache[itemId]
        -- startQuestId can have boolean false as value, need to compare to nil
        -- check QueryItemSingle because this event can fire before db init is complete
        if (startQuestId == nil) and QuestieDB.QueryItemSingle then
            startQuestId = QuestieDB.QueryItemSingle(itemId, "startQuest")
            -- filter 0 values away so itemCache value is a valid questId if it evaluates to true
            -- we do "or false" here because nil would mean not cached
            startQuestId = (startQuestId and startQuestId > 0) and startQuestId or false
            itemCache[itemId] = startQuestId
        end

        if startQuestId then
            if not QuestieAnnounce:AnnounceQuestItemLootedToChannel(startQuestId, itemId) then
                _QuestieAnnounce:AnnounceSelf(startQuestId, itemId)
            end
        end

        local itemName = GetItemInfo(itemId)
        if attunableItemsConsumedByQuests[itemId] and IsAttunableBySomeone and IsAttunableBySomeone(itemId) and not Questie.db.profile.questieShutUp then
            if CanAttuneItemHelper and CanAttuneItemHelper(itemId) > 0 then
                if GetItemAttuneForge and GetItemAttuneForge(id) < 0 then 
                    SendChatMessage("Looted Attunable Item: "..itemName.."!")
                    --print("Attunable quest objective found")
                end
            else
                SendChatMessage("Looted Account Attunable Item: "..itemName.."!")
            end
        end
    end
end

function QuestieAnnounce:AcceptedQuest(questId)
    if (_QuestieAnnounce:AnnounceEnabledAndPlayerInChannel()) and Questie.db.profile.questAnnounceAccepted then
        local questLink = QuestieLink:GetQuestLinkStringById(questId)

        local message = _GetAnnounceMarker() .. l10n("Quest %s: %s", l10n('Accepted'), questLink or "no quest name")
        _QuestieAnnounce:AnnounceToChannel(message)
    end
end

function QuestieAnnounce:AbandonedQuest(questId)
    if (_QuestieAnnounce:AnnounceEnabledAndPlayerInChannel()) and Questie.db.profile.questAnnounceAbandoned then
        local questLink = QuestieLink:GetQuestLinkStringById(questId)

        local message = _GetAnnounceMarker() .. l10n("Quest %s: %s", l10n('Abandoned'), questLink or "no quest name")
        _QuestieAnnounce:AnnounceToChannel(message)
    end
end

function QuestieAnnounce:CompletedQuest(questId)
    if (_QuestieAnnounce:AnnounceEnabledAndPlayerInChannel()) and Questie.db.profile.questAnnounceCompleted then
        local questLink = QuestieLink:GetQuestLinkStringById(questId)

        local message = _GetAnnounceMarker() .. l10n("Quest %s: %s", l10n('Completed'), questLink or "no quest name")
        _QuestieAnnounce:AnnounceToChannel(message)
    end
end
