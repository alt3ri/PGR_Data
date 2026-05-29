---@class XMainLine2UiStageAreaControl : XControl
---@field private _Model XMainLine2Model
---@field _MainControl XMainLine2Control
local XMainLine2UiStageAreaControl = XClass(XControl, "XMainLine2UiStageAreaControl", true)

XClassPartialRequire("XModule/XMainLine2/SubModules/UiStageArea/XMainLine2UiStageAreaControlConfig", "XMainLine2UiStageAreaControl")

function XMainLine2UiStageAreaControl:OnInit()
    self:_InitConfigs()
end

function XMainLine2UiStageAreaControl:AddAgencyEvent()

end

function XMainLine2UiStageAreaControl:RemoveAgencyEvent()

end

function XMainLine2UiStageAreaControl:OnRelease()

end

function XMainLine2UiStageAreaControl:CheckChapterHasAreaGroup(chapterId)
    local cfg = self:GetTableMainLine2StageAreaGroupCfgById(chapterId, true)
    
    return not XTool.IsTableEmpty(cfg)
end

function XMainLine2UiStageAreaControl:GetChapterAreaCount(chapterId)
    local cfg = self:GetTableMainLine2StageAreaGroupCfgById(chapterId, true)

    if cfg then
        return XTool.GetTableCount(cfg.AreaIds)
    end
    
    return 0
end

-- 根据 stageId 查询所属 areaIndex（在指定章节中，1-based）
-- 找不到返回 nil
function XMainLine2UiStageAreaControl:GetAreaIndexByStageId(chapterId, stageId)
    local areaGroupCfg = self:GetTableMainLine2StageAreaGroupCfgById(chapterId)
    if not areaGroupCfg then return nil end

    for i, areaId in pairs(areaGroupCfg.AreaIds) do
        local areaCfg = self:GetTableMainLine2StageAreaCfgById(areaId)
        if areaCfg and not XTool.IsTableEmpty(areaCfg.AreaStageIds) then
            for _, sid in pairs(areaCfg.AreaStageIds) do
                if sid == stageId then
                    return i
                end
            end
        end
    end
    return nil
end

function XMainLine2UiStageAreaControl:CheckAreaIsOpen(areaId)
    local areaCfg = self:GetTableMainLine2StageAreaCfgById(areaId)

    if not areaCfg then
        return false
    end

    if not XTool.IsTableEmpty(areaCfg.AreaStageIds) then
        for i, stageId in pairs(areaCfg.AreaStageIds) do
            -- 检查关卡是否显示
            if self._MainControl:IsStageShow(stageId) then
                return true
            end
        end
    end

    if not XTool.IsTableEmpty(areaCfg.AreaMessageIds) then
        for i, messageId in pairs(areaCfg.AreaMessageIds) do
            if self._MainControl.MessageControl:CheckMessageCanShowById(messageId) then
                return true
            end
        end
    end
    
    return false
end

return XMainLine2UiStageAreaControl