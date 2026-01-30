local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
local XUiBountyChallengeBattleRoomRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiBountyChallengeBattleRoomRoleDetail")

-- team : XTeam
function XUiBountyChallengeBattleRoomRoleDetail:Ctor(stageId, team, pos)
    self.StageId = stageId
    self.Team = team
    self.Pos = pos
end

function XUiBountyChallengeBattleRoomRoleDetail:GetStageId()
    return self.StageId
end

function XUiBountyChallengeBattleRoomRoleDetail:GetEntities(characterType)
    local characters = XMVCA.XBountyChallenge:GetCharacters()
    return characters
end

--function XUiBountyChallengeBattleRoomRoleDetail:SortEntitiesWithTeam(team, entities, sortTagType)
--    return XMVCA.XReform:SortEntitiesInStage(entities, self:GetStageId())
--end

--function XUiBountyChallengeBattleRoomRoleDetail:GetAutoCloseInfo()
--    local endTime = XMVCA.XReform:GetActivityEndTime()
--
--    return true, endTime, function(isClose)
--        if isClose then
--            XMVCA.XReform:HandleActivityEndTime()
--        end
--    end
--end
--
--function XUiBountyChallengeBattleRoomRoleDetail:AOPOnDynamicTableEventAfter(rootUi, event, index, grid)
--    ---@type XCharacter
--    local entity = rootUi.DynamicTable.DataSource[index]
--    local characterList = XMVCA.XReform:GetStageCharacterListByStageId(self.StageId)
--    local isInList = false
--
--    for i = 1, #characterList do
--        if entity and entity:GetId() == characterList[i] then
--            isInList = true
--        end
--    end
--
--    if grid.PanelRecommend then
--        grid.PanelRecommend.gameObject:SetActiveEx(isInList)
--    end
--end

return XUiBountyChallengeBattleRoomRoleDetail