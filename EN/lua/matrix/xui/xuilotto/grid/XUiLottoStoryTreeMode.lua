---@class XUiLottoStoryTreeMode : XUiNode
local XUiLottoStoryTreeMode = XClass(XUiNode, "XUiLottoStoryTreeMode")

function XUiLottoStoryTreeMode:InitStageList()
    local storyObj = self.PaneStageTree
    XTool.InitUiObjectByInstance(storyObj, self) -- 将line的UiObjet引用加进来
end

-- 判断关卡是否解锁，返回：是否解锁, 第一个未解锁的前置关卡名
function XUiLottoStoryTreeMode:IsStageUnlocked(stageId)
    local preStageIds = XMVCA.XFuben:GetPreStageId(stageId)
    if XTool.IsTableEmpty(preStageIds) then
        return true, nil
    end

    for _, preStageId in pairs(preStageIds) do
        local isPreStagePass = XMVCA.XFuben:CheckStageIsPass(preStageId)
        if not isPreStagePass then
            local preStageCfg = XMVCA.XFuben:GetStageCfg(preStageId)
            local preStageName = preStageCfg and preStageCfg.Name or ""
            return false, preStageName
        end
    end

    return true, nil
end

function XUiLottoStoryTreeMode:RefreshStageList()
    self.PaneStageTree.gameObject:SetActiveEx(true)
    local stageActivityId = XLottoConfigs.GetLottoStageActivity(self.Parent._LottoGroupData:GetId())
    local festivalActivity = XFestivalActivityConfig.GetFestivalById(stageActivityId)

    for i, stageId in pairs(festivalActivity.StageId) do
        local stageTransform = self.PanelStageContent:GetChild(i - 1)
        local stageObj = stageTransform:GetComponent("UiObject")
        local btn = stageObj:GetObject("BtnStage")

        if btn then
            local stageCfg = XMVCA.XFuben:GetStageCfg(stageId)
            btn.CallBack = function()
                self:OpenStageDetails(stageId)
            end
            btn:SetNameByGroup(0, stageCfg.Name)
        end

        -- 使用封装好的方法判断是否解锁
        local isUnlocked = self:IsStageUnlocked(stageId)
        btn:SetDisable(not isUnlocked)

        local isCurStageClear = XMVCA.XFuben:CheckStageIsPass(stageId)
        btn:ShowTag(isCurStageClear)
    end
end

function XUiLottoStoryTreeMode:OpenStageDetails(stageId)
    local isUnlocked, preStageName = self:IsStageUnlocked(stageId)
    if not isUnlocked then
        XUiManager.TipText("FubenPreStage", nil, nil, preStageName)
        return
    end

    XLuaUiManager.Open("UiEpicFashionGachaStageDetail", stageId)
end

return XUiLottoStoryTreeMode