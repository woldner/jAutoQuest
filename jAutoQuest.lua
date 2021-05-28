local AddonName, Addon = ...

-- locals and speed
local pairs = pairs

local IsAddOnLoaded = IsAddOnLoaded
local C_GossipInfo = C_GossipInfo
local CreateFrame = CreateFrame
local IsShiftKeyDown = IsShiftKeyDown
local ConfirmAcceptQuest = ConfirmAcceptQuest
local GetNumQuestChoices = GetNumQuestChoices
local GetQuestReward = GetQuestReward
local GetActiveTitle = GetActiveTitle
local GetAvailableQuestInfo = GetAvailableQuestInfo
local GetNumActiveQuests = GetNumActiveQuests
local GetNumAvailableQuests = GetNumAvailableQuests
local SelectActiveQuest = SelectActiveQuest
local SelectAvailableQuest = SelectAvailableQuest
local IsQuestCompletable = IsQuestCompletable
local CompleteQuest = CompleteQuest
local QuestDetailAcceptButton_OnClick = QuestDetailAcceptButton_OnClick

local GetQuestItemLink = GetQuestItemLink
local PawnGetItemData = PawnGetItemData
local PawnIsItemAnUpgrade = PawnIsItemAnUpgrade

function Addon:OnEvent(event, ...)
  local action = self[event]

  if (action and not IsShiftKeyDown()) then
    action(self, ...)
  end
end

function Addon:Load()
  self.frame = CreateFrame("Frame", nil)

  self.frame:SetScript("OnEvent", function(_, ...)
    self:OnEvent(...)
  end)

  self.frame:RegisterEvent("ADDON_LOADED")
end

-- This event fires when an escort quest is started by another player.
function Addon:QUEST_ACCEPT_CONFIRM()
  -- print("QUEST_ACCEPT_CONFIRM")

  ConfirmAcceptQuest()
end

-- Fired after the player hits the "Continue" button in the quest-information page,
-- before the "Complete Quest" button.
function Addon:QUEST_COMPLETE()
  -- print("QUEST_COMPLETE")

  local numQuestChoices = GetNumQuestChoices()

  if (not numQuestChoices or numQuestChoices == 0) then
    GetQuestReward()
  end

  if (numQuestChoices == 1) then
    GetQuestReward(1)
  end

  if (numQuestChoices > 1) then
    local upgrades = {}

    for i = 1, numQuestChoices do
      local link = GetQuestItemLink("choice", i)

      if (link) then
        local item = PawnGetItemData(link)

        if (item) then
          for _, upgrade in pairs(PawnIsItemAnUpgrade(item) or {}) do
            upgrades[#upgrades + 1] = {index = i, value = upgrade.PercentUpgrade}
          end
        end
      end
    end

    if (#upgrades ~= 0) then
      table.sort(upgrades, function (a, b) return a.value > b.value end)
      GetQuestReward(upgrades[1].index)
    end
  end
end

-- Fired when the player is given a more detailed view of his quest.
function Addon:QUEST_DETAIL()
  -- print("QUEST_DETAIL")

  QuestDetailAcceptButton_OnClick()
end

-- Fired when talking to an NPC that offers or accepts more than one quest,
-- e.g. has more than one active or available quest.
function Addon:QUEST_GREETING()
  -- print("QUEST_GREETING")

  for i = 1, GetNumActiveQuests() do
    local _, isComplete = GetActiveTitle(i)
    if (isComplete) then
      SelectActiveQuest(i)
    end
  end

  for i = 1, GetNumAvailableQuests() do
    local isTrivial = GetAvailableQuestInfo(i)
    if (not isTrivial) then
      SelectAvailableQuest(i)
    end
  end
end

-- Fired when a player is talking to an NPC about the status of a quest
-- and has not yet clicked the complete button.
function Addon:QUEST_PROGRESS()
  -- print("QUEST_PROGRESS")

  if (IsQuestCompletable()) then
    CompleteQuest()
  end
end

-- This event typically fires when you are given several choices, including choosing to sell item,
-- select available and active quests, just talk about something, or bind to a location.
-- Even when the the only available choices are quests, this event is often used instead of QUEST_GREETING.
function Addon:GOSSIP_SHOW()
  -- print("GOSSIP_SHOW")

  for i = 1, GetNumGossipActiveQuests() do
    local isComplete = select(i * 6 - 5 + 3, GetGossipActiveQuests())
    if (isComplete) then
      SelectGossipActiveQuest(i)
    end
  end

  for i = 1, GetNumGossipAvailableQuests() do
    SelectGossipAvailableQuest(i)
  end
end

function Addon:ADDON_LOADED(name)
  if (name == AddonName and IsAddOnLoaded("Pawn")) then
    self.frame:RegisterEvent("GOSSIP_SHOW")
    self.frame:RegisterEvent("QUEST_ACCEPT_CONFIRM")
    self.frame:RegisterEvent("QUEST_COMPLETE")
    self.frame:RegisterEvent("QUEST_DETAIL")
    self.frame:RegisterEvent("QUEST_GREETING")
    self.frame:RegisterEvent("QUEST_PROGRESS")

    print(name, "loaded")

    self.frame:UnregisterEvent("ADDON_LOADED")
  end
end

-- begin
Addon:Load()
