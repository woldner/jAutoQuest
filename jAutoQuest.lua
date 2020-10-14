local AddonName, Addon = ...

-- locals and speed
local pairs = pairs

local C_GossipInfo = C_GossipInfo
local CreateFrame = CreateFrame
local IsShiftKeyDown = IsShiftKeyDown
local ConfirmAcceptQuest = ConfirmAcceptQuest
local GetNumQuestChoices = GetNumQuestChoices
local GetQuestReward = GetQuestReward
local GetActiveTitle = GetActiveTitle
local GetAvailableQuestInfo = GetAvailableQuestInfo
local IsQuestCompletable = IsQuestCompletable
local CompleteQuest = CompleteQuest
local QuestDetailAcceptButton_OnClick = QuestDetailAcceptButton_OnClick

-- pawn functions
local GetQuestItemLink = GetQuestItemLink
local PawnGetItemData = PawnGetItemData
local PawnIsItemAnUpgrade = PawnIsItemAnUpgrade

function Addon:OnEvent(event, ...)
  local action = self[event]

  if (action and not IsShiftKeyDown()) then
    action(self, event, ...)
  end
end

function Addon:Load()
  self.frame = CreateFrame("Frame", nil)

  self.frame:SetScript("OnEvent", function(_, ...)
    self:OnEvent(...)
  end)

  self.frame:RegisterEvent("ADDON_LOADED")
  self.frame:RegisterEvent("QUEST_ACCEPT_CONFIRM")
  self.frame:RegisterEvent("QUEST_COMPLETE")
  self.frame:RegisterEvent("QUEST_DETAIL")
  self.frame:RegisterEvent("QUEST_GREETING")
  self.frame:RegisterEvent("QUEST_PROGRESS")
  self.frame:RegisterEvent("GOSSIP_SHOW")
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
        local data = PawnGetItemData(link)

        if (data) then
          local infos = PawnIsItemAnUpgrade(data)

          if (infos) then
            for _, info in pairs(infos) do
              local upgrade = { choice = i, value = info.PercentUpgrade }
              upgrades[#upgrades + 1] = upgrade
            end
          end
        end
      end
    end

    if (#upgrades > 0) then
      table.sort(upgrades, function (a, b) return a.value > b.value end)
      GetQuestReward(upgrades[1].choice)
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

  for i = 1, C_GossipInfo.GetNumActiveQuests() do
    local _, isComplete = GetActiveTitle(i)
    if (isComplete) then
      C_GossipInfo.SelectActiveQuest(i)
    end
  end

  for i = 1, C_GossipInfo.GetNumAvailableQuests() do
    local isTrivial = GetAvailableQuestInfo(i)
    if (not isTrivial) then
      C_GossipInfo.SelectAvailableQuest(i)
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

  local activeQuests = C_GossipInfo.GetActiveQuests()
  for i = 1, C_GossipInfo.GetNumActiveQuests() do
    if (activeQuests[i].isComplete) then
      C_GossipInfo.SelectActiveQuest(i)
    end
  end

  local availableQuests = C_GossipInfo.GetAvailableQuests()
  for i = 1, C_GossipInfo.GetNumAvailableQuests() do
    if (not availableQuests[i].repeatable and not availableQuests[i].isTrivial) then
      C_GossipInfo.SelectAvailableQuest(i)
    end
  end
end

function Addon:ADDON_LOADED(_, name)
  if (name == AddonName) then
    self.frame:UnregisterEvent("ADDON_LOADED")

    print(name, "loaded")
  end
end

-- begin
Addon:Load()
