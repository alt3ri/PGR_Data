local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
---@class XUiSoloReformRoomRoleDetailProxy : XUiBattleRoomRoleDetailDefaultProxy
local XUiSoloReformRoomRoleDetailProxy = XClass(XUiBattleRoomRoleDetailDefaultProxy,"XUiSoloReformRoomRoleDetailProxy")

-- team : XTeam
function XUiSoloReformRoomRoleDetailProxy:Ctor(stageId, team, pos)
    self.StageId = stageId
end

function XUiSoloReformRoomRoleDetailProxy:GetEntities(characterType)
    local chapterId = XMVCA.XSoloReform:GetEnterChapterId()
    local roles = {}
    if not XTool.IsNumberValid(chapterId) then
        return roles
    end
    local chapterCfg = XMVCA.XSoloReform:GetSoloReformChapterCfg(chapterId)
    if not XTool.IsTableEmpty(chapterCfg.RobotData) then
        for _, characterId in pairs(chapterCfg.RobotData) do
            if XDataCenter.RoomCharFilterTipsManager.IsFilterSelectTag(characterId, characterType) then
                local robotData = XRobotManager.GetRobotById(characterId)
                table.insert(roles, robotData)
            end    
        end
    end 

    if not XTool.IsTableEmpty(chapterCfg.UseChara) then
        for _, characterId in pairs(chapterCfg.UseChara) do
            if XDataCenter.RoomCharFilterTipsManager.IsFilterSelectTag(characterId, characterType) then
                local characterData = XMVCA.XCharacter:GetCharacter(characterId)
                table.insert(roles, characterData)
            end    
        end
    end    
    return roles
end

function XUiSoloReformRoomRoleDetailProxy:CheckIsNeedPractice()
    return false
end

return XUiSoloReformRoomRoleDetailProxy