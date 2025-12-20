local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
local XUiAreaWarBattleRoomRoleDetailChildPanel = require("XUi/XUiAreaWar/XUiAreaWarBattleRoomRoleDetailChildPanel")

local pairs = pairs
local ipairs = ipairs
local tableInsert = table.insert
local tableSort = table.sort

local XUiAreaWarBattleRoomRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiAreaWarBattleRoomRoleDetail")

function XUiAreaWarBattleRoomRoleDetail:Ctor(blockId)
    self.BlockId = blockId
end

function XUiAreaWarBattleRoomRoleDetail:AOPOnStartBefore(rootUi)
    local childCount = rootUi.PanelAsset.childCount
    for i = 1, childCount do
        rootUi.PanelAsset:GetChild(i-1).gameObject:SetActiveEx(false)
    end
    rootUi.BtnFilter.gameObject:SetActiveEx(false)
end

function XUiAreaWarBattleRoomRoleDetail:GetEntities(characterType)
    if self.Entities == nil then
        self.Entities = {}
    end

    local result = {}
    local characterTypes = characterType and 1 or { XEnumConst.CHARACTER.CharacterType.Normal, XEnumConst.CHARACTER.CharacterType.Isomer }
    for _, cType in ipairs(characterTypes) do
        if XTool.IsTableEmpty(self.Entities[cType]) then
            self.Entities[cType] = XDataCenter.AreaWarManager.GetCanFightEntities(cType)
        end
        for _, entity in ipairs(self.Entities[cType]) do
            if entity:GetCharacterViewModel():GetCharacterType() == cType then
                tableInsert(result, entity)
            end
        end
    end
    return result
end

--function XUiAreaWarBattleRoomRoleDetail:GetCharacterViewModelByEntityId(entityId)
--    for _, typeDic in pairs(self.Entities) do
--        for _, entity in pairs(typeDic) do
--            if entity:GetId() == entityId then
--                return entity:GetCharacterViewModel()
--            end
--        end
--    end
--end

--function XUiAreaWarBattleRoomRoleDetail:SortEntitiesWithTeam(team, entities, sortTagType)
--    local blockId = self.BlockId
--    return entities
--end

--function XUiAreaWarBattleRoomRoleDetail:GetChildPanelData()
--    if self.ChildPanelData == nil then
--        self.ChildPanelData = {
--            assetPath = XUiConfigs.GetComponentUrl("XUiAreaWarBattleRoomRoleDetail"),
--            proxy = XUiAreaWarBattleRoomRoleDetailChildPanel
--        }
--    end
--    return self.ChildPanelData
--end

function XUiAreaWarBattleRoomRoleDetail:GetAutoCloseInfo()
    return true, XDataCenter.AreaWarManager.GetEndTime(), function(isClose)
        if isClose then
            XDataCenter.AreaWarManager.OnActivityEnd()
        end
    end
end

return XUiAreaWarBattleRoomRoleDetail
