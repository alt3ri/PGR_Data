local XTheatre5PVENode = require("XModule/XTheatre5/PVE/Rouge/XTheatre5PVENode")
---@class XTheatre5BattleChapterInitNode
local XTheatre5BattleChapterInitNode = XClass(XTheatre5PVENode, "XTheatre5BattleChapterInitNode")

function XTheatre5BattleChapterInitNode:SetData(characterId, storyEntranceId)
    self._CharacterId = characterId
    self._StoryEntranceId = storyEntranceId
end

function XTheatre5BattleChapterInitNode:_OnEnter()
    XMVCA.XTheatre5.PVEAgency:RequestPveChapterEnter(self._StoryEntranceId, self._StoryLineId, self._CharacterId, function(sucess)
        if sucess then
            local chapterBattleData = self._MainModel.PVEAdventureData:GetCurChapterBattleData()
            XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_CHAPTER_BATTLE_PROMOTE,
            self:GetUid(), XMVCA.XTheatre5.EnumConst.PVENodeType.BattleChapterMain, chapterBattleData)
        end    
    end)
end

function XTheatre5BattleChapterInitNode:_OnExit()

end

return XTheatre5BattleChapterInitNode