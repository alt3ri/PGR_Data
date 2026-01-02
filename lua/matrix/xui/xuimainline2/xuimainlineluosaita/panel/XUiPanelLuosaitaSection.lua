local XUiGridLuosaitaBlock = require("XUi/XUiMainLine2/XUiMainLineLuosaita/Grid/XUiGridLuosaitaBlock")
local XUiGridLuosaitaMemberCharacter = require("XUi/XUiMainLine2/XUiMainLineLuosaita/Grid/XUiGridLuosaitaMemberCharacter")
local XUiGridLuosaitaMemberArmy = require("XUi/XUiMainLine2/XUiMainLineLuosaita/Grid/XUiGridLuosaitaMemberArmy")
local XUiGridLuosaitaMemberEnemy = require("XUi/XUiMainLine2/XUiMainLineLuosaita/Grid/XUiGridLuosaitaMemberEnemy")
local XUiGridLuosaitaMemberStage = require("XUi/XUiMainLine2/XUiMainLineLuosaita/Grid/XUiGridLuosaitaMemberStage")
local CSInstantiate = CS.UnityEngine.Object.Instantiate
local CSTween = CS.DG.Tweening
local DOTween = CS.DG.Tweening.DOTween

-- 罗塞塔主线阶段面板
---@class XUiPanelLuosaitaSection : XUiNode
---@field Parent XUiMainLineLuosaitaMain
---@field _Control XMainLineLuosaitaControl
---@field _GridPositions table<number, XUiGridLuosaitaMember>
local XUiPanelLuosaitaSection = XClass(XUiNode, "XUiPanelLuosaitaSection")

function XUiPanelLuosaitaSection:OnStart(sectionId)
    self:RegisterUiEvents()
    
    for i = 0, self.PanelBlock.childCount - 1 do
        self.PanelBlock:GetChild(i).gameObject:SetActiveEx(false)
    end

    self.SectionId = sectionId
    self._GridBlocks = {}
    self._GridPositions = {}
    local sectionInfo = self._Control:GetSectionInfo(self.SectionId)
    for k, blockConfig in pairs(self._Control:GetConfig():GetConfigBlocksBySectionId(self.SectionId)) do
        local blockTransform = self.PanelBlock:Find(blockConfig.UiNodeName)
        if not blockTransform then
            goto continue
        end
        blockTransform.gameObject:SetActiveEx(true)
        if not sectionInfo:GetBlockInfo(blockConfig.Id) then
            goto continue
        end
        self._GridBlocks[blockConfig.Id] = XUiGridLuosaitaBlock.New(blockTransform, self)
        self._GridBlocks[blockConfig.Id]:Refresh(sectionInfo:GetBlockInfo(blockConfig.Id))
        ::continue::
    end
end

function XUiPanelLuosaitaSection:OnEnable()
    -- 恢复到上次关闭时候的位置
    local pos = self.Parent:GetSectionLastPosition(self.SectionId)
    if pos then
        self:SetAreaScaleDragPosition(pos)

        -- 等待切换阶段动画播完，再播移动动画
        self:Refresh(true, false, true, true)
    else
        self:GotoFocusTarget()
        self:Refresh(true)
    end
end

function XUiPanelLuosaitaSection:OnDestroy()
    self:RemoveDragTimer()
    self:RemoveAnimWaitTimer()
end

function XUiPanelLuosaitaSection:RegisterUiEvents()
    if self.BtnSkyGarden then
        XUiHelper.RegisterClickEvent(self, self.BtnSkyGarden, self.OnBtnSkyGardenClick)
    end
    self.PanelAreaScaleDrag:AddTranslateValueChangedListener(Handler(self, self.OnTranslateValueChanged))
end

function XUiPanelLuosaitaSection:OnBtnSkyGardenClick()
    if self:IsDragOperation() then
        return
    end
    
    if not self._ConditionPassed then
        XUiManager.TipMsg(self._ConditionDesc)
        return
    end
    if self._TaskFinished then
        return
    end
    XLuaUiManager.Open("UiMainLineLuosaitaPopupSkyGardenDetail")
end

function XUiPanelLuosaitaSection:OnTranslateValueChanged(value)
    if not self.FocusTarget then
        return
    end

    self.EndValue = value
    local screenPointV3 = self.FocusTarget.Camera:WorldToScreenPoint(self.EndValue)
    local screenPointV2 = Vector2(screenPointV3.x, screenPointV3.y)
    if not self.DragTimer then
        self:RemoveDragTimer()
        self.DragTimer = XScheduleManager.ScheduleOnce(function()
            if not self.FocusTarget:IsInScreenSize(screenPointV2) then
                local offsetSize = self.PanelAreaScaleDrag.Target.transform.localPosition.x - self.FocusTarget.Transform.localPosition.x
                if offsetSize ~= 0 then
                    self.Parent:ShowFocusTipsBtn(offsetSize)
                end
            else
                self.Parent:ShowFocusTipsBtn(0)
            end
            self.DragTimer = nil
        end, 200)
    end
end

function XUiPanelLuosaitaSection:RemoveDragTimer()
    if self.DragTimer then
        XScheduleManager.UnSchedule(self.DragTimer)
        self.DragTimer = nil
    end
end

function XUiPanelLuosaitaSection:Refresh(isCheckFocus, isCheckSwitchSection, isFocusAnim, isFocusWait)
    self:RefreshBlocks()
    self:RefreshPositions()
    self:RefreshSkyGardenButton()

    if isCheckFocus then
        local isOpen = self:CheckOpenPopUpDocument()
        if isOpen then return end
        local isPlay = self:CheckPlayCharacterMove()
        if isPlay then return end
        self:GotoFocusTarget(isFocusAnim, isFocusWait)
    end

    if isCheckSwitchSection then
        self.Parent:CheckSwitchNextSection()
    end
end

-- 刷新块
function XUiPanelLuosaitaSection:RefreshBlocks()
    self.FocusTarget = nil
    local sectionInfo = self._Control:GetSectionInfo(self.SectionId)
    for blockId, blockUiData in pairs(self._GridBlocks) do
        blockUiData:Refresh(sectionInfo:GetBlockInfo(blockId))
    end
end

-- 刷新点位
function XUiPanelLuosaitaSection:RefreshPositions()
    local sectionInfo = self._Control:GetSectionInfo(self.SectionId)
    local posConfigs = self._Control:GetConfig():GetConfigPositionsBySectionId(self.SectionId)
    for _, posConfig in pairs(posConfigs) do
        local posId = posConfig.Id
        local grid = self._GridPositions[posId]
        local posInfo = sectionInfo:GetPositionInfo(posId)
        
        -- 移除点位
        if not posInfo then
            if grid then
                grid.LinkGameObject.gameObject:SetActiveEx(false)
                self:RemoveChildNode(grid)
                self._GridPositions[posId] = nil
                grid = nil
            end
            goto CONTINUE
            
        -- 点位类型变化，删除旧点位，加载新点位
        elseif grid and posInfo:GetType() ~= grid:GetType() then
            self:RemoveChildNode(grid)
            self._GridPositions[posId] = nil
            grid = nil
        end
        
        -- UI节点检测
        local posTransform = self:GetPositionLinkGo(posConfig.UiNodeName)
        if not posTransform then
            goto CONTINUE
        end
        posTransform.gameObject:SetActiveEx(true)

        -- 创建
        if not grid then
            if posInfo:IsArmy() then
                local prefabPath =  self._Control:GetConfig():GetConfigString("ArmyPrefab", 1)
                local go = posTransform:LoadPrefab(prefabPath)
                grid = XUiGridLuosaitaMemberArmy.New(go, self)
            elseif posInfo:IsEnemy() then
                local prefabPath = self._Control:GetConfig():GetConfigString("EnemyPrefab", 1)
                local go = posTransform:LoadPrefab(prefabPath)
                grid = XUiGridLuosaitaMemberEnemy.New(go, self)
            elseif posInfo:IsCharacter() then
                local prefabPath = self._Control:GetConfig():GetConfigString("CharacterPrefab", 1)
                local go = posTransform:LoadPrefab(prefabPath)
                grid = XUiGridLuosaitaMemberCharacter.New(go, self)
            elseif posInfo:IsStage() then
                local stageId = posInfo:GetStageId()
                local stageCfg = XMVCA.XFuben:GetStageCfg(stageId)
                local prefabName = stageCfg.StageGridStyle
                local prefabPath = CS.XGame.ClientConfig:GetString(prefabName)
                local go = posTransform:LoadPrefab(prefabPath)
                grid = XUiGridLuosaitaMemberStage.New(go, self, prefabName)
            end
            XUiHelper.SetCanvasesSortingOrder(posTransform)
            grid:Init(posTransform)
        end
        grid:Open()
        grid:Refresh(posInfo)
        self._GridPositions[posId] = grid
        self:SetFocusTaget(grid, posInfo)
        :: CONTINUE ::
    end
end

-- 刷新空花入口按钮
function XUiPanelLuosaitaSection:RefreshSkyGardenButton()
    if not self.BtnSkyGarden then
        return
    end
    local conditionId = self._Control:GetSkyGardenEntryConditionId()
    local passed = true
    local desc = ""
    if conditionId and conditionId > 0 then
        passed, desc = XConditionManager.CheckCondition(conditionId)
    end
    local taskId = self._Control:GetSkyGardenEntryTaskId()
    local taskFinished = false
    if taskId and taskId > 0 then
        taskFinished = XDataCenter.TaskManager.CheckTaskFinished(taskId)
    end
    self._ConditionPassed = passed
    self._TaskFinished = taskFinished
    self._ConditionDesc = desc
    self.BtnSkyGarden:SetDisable(not passed)
    self.BtnSkyGarden:ShowTag(passed and taskFinished)
end

--region 角色移动
-- 检测是否播放角色移动
function XUiPanelLuosaitaSection:CheckPlayCharacterMove()
    -- 移动中
    if self.CloneMoveNode then
        return true
    end
    
    local moveConfig = self._Control:GetUnlockMoveConfig(self.SectionId)
    if not moveConfig then
        return false
    end
    
    local sectionInfo = self._Control:GetSectionInfo(self.SectionId)
    local startPosId = sectionInfo:GetCharacterPosId(moveConfig.CharacterId)
    local endPosId = moveConfig.PosId
    local time = moveConfig.Millisecond / 1000
    XMVCA.XMainLineLuosaita:RequestMainLineLuosaitaCharacterMove(self.SectionId, moveConfig.Id, function()
        self:PlayCharacterMove(startPosId, endPosId, time)
    end)
    return true
end

-- 播放角色移动表现
---@param startPosId number
---@param endPosId number
function XUiPanelLuosaitaSection:PlayCharacterMove(startPosId, endPosId, time)
    local startUiNodeName = self._Control:GetConfig():GetPositionUiNodeName(startPosId)
    local endUiNodeName = self._Control:GetConfig():GetPositionUiNodeName(endPosId)
    local startLinkGo = self:GetPositionLinkGo(startUiNodeName)
    local endLinkGo = self:GetPositionLinkGo(endUiNodeName)

    XLuaUiManager.SetMask(true)
    self:DestroyCloneMoveNode()
    self.CloneMoveNode = CSInstantiate(startLinkGo, self.PanelPosition.transform)
    startLinkGo.gameObject:SetActiveEx(false)
    self.CloneMoveNode.transform:DOLocalMove(endLinkGo.transform.localPosition, time):SetEase(CSTween.Ease.OutQuad):OnComplete(function()
        XLuaUiManager.SetMask(false)
        self:DestroyCloneMoveNode()
        self:Refresh(true, true, true)
    end)
end

-- 销毁克隆出来的移动节点
function XUiPanelLuosaitaSection:DestroyCloneMoveNode()
    if self.CloneMoveNode then
        self.CloneMoveNode.gameObject:SetActiveEx(false)
        CS.UnityEngine.Object.Destroy(self.CloneMoveNode.gameObject)
        self.CloneMoveNode = nil
    end
end
--endregion

--region 文件弹窗
-- 检查是否打开文件弹窗
function XUiPanelLuosaitaSection:CheckOpenPopUpDocument()
    -- 弹窗显示中
    local isShow = XLuaUiManager.IsUiShow("UiMainLineLuosaitaPopupFileDetail") or XLuaUiManager.IsUiPushing("UiMainLineLuosaitaPopupFileDetail")
    if isShow then
        return true
    end
    
    local sectionInfo = self._Control:GetSectionInfo(self.SectionId)
    local docId = sectionInfo:GetUnUseDocId()
    if docId then
        XLuaUiManager.Open("UiMainLineLuosaitaPopupFileDetail", self.SectionId, docId, function()  
            self:SetAreaScaleDragEnable(false)
        end, function()
            self:SetAreaScaleDragEnable(true)
            self:OnPopUpDocumentClose()
        end)
        return true        
    end
    return false
end

-- 文件弹窗关闭回调
function XUiPanelLuosaitaSection:OnPopUpDocumentClose()
    self:Refresh(true, true, true)
end
--endregion

function XUiPanelLuosaitaSection:MoveToPos(curPosId, targetPosId)
    XMVCA.XMainLineLuosaita:RequestMainLineLuosaitaMove(self.SectionId, curPosId, targetPosId, function()
        self:Refresh(true, true, true)
    end)
end

function XUiPanelLuosaitaSection:SetFocusTaget(uiNode, postionInfo)
    local stageType = XMVCA.XMainLineLuosaita.EnumConst.POS_TYPE.STAGE
    if not self.FocusTarget then
        if uiNode:GetType() == XMVCA.XMainLineLuosaita.EnumConst.POS_TYPE.ENEMY then
            self.FocusTarget = uiNode
        end
        if uiNode:GetType() == stageType then
            if self._Control:IsStageShow(postionInfo:GetStageId()) and self._Control:IsStageUnlock(postionInfo:GetStageId()) then
                self.FocusTarget = uiNode
            end
        end
    end
    if self.FocusTarget then
        if self.FocusTarget.MemberData:IsStage() and uiNode:GetType() == stageType then
            if self._Control:IsStageShow(postionInfo:GetStageId()) and self._Control:IsStageUnlock(postionInfo:GetStageId()) then
                self.FocusTarget = uiNode
            end
        end
    end
end

function XUiPanelLuosaitaSection:GetGridBlocks()
    return self._GridBlocks
end

function XUiPanelLuosaitaSection:GetGridMembers()
    return self._GridPositions
end

-- 获取位置挂点的Go
function XUiPanelLuosaitaSection:GetPositionLinkGo(uiNodeName)
    self.PositionNodeGoDic = self.PositionNodeGoDic or {}
    local go = self.PositionNodeGoDic[uiNodeName]
    if go then return go end

    go = self.PanelPosition:Find(uiNodeName)
    if go then
        self.PositionNodeGoDic[uiNodeName] = go
        return go
    else
        XLog.Error(string.format("阶段%s的预制体缺少位置节点:%s", self.SectionId, uiNodeName))
    end
end

-- 获取需要聚焦的目标
---@return string
function XUiPanelLuosaitaSection:GetFocusTargetUiNodeName()
    local sectionInfo =  self._Control:GetSectionInfo(self.SectionId)
    local positionInfos = sectionInfo:GetPositionInfos()
    if sectionInfo:IsFinish() then
        return
    end
    
    -- 显示但未通关的关卡
    for _, posInfo in ipairs(positionInfos) do
        local posId = posInfo:GetPosId()
        if posInfo:IsStage() then
            local stageId = posInfo:GetStageId()
            local isPassed = XMVCA.XFuben:CheckStageIsPass(stageId)
            if not isPassed and self._Control:IsStageShow(stageId) and self._Control:IsStageUnlock(stageId) then
                return self._Control:GetConfig():GetPositionUiNodeName(posId)
            end
        end
    end

    -- 显示但未通关的敌军
    for _, posInfo in ipairs(positionInfos) do
        local posId = posInfo:GetPosId()
        if posInfo:IsEnemy() then
            local enemyId = posInfo:GetEnemyId()
            local isShow = self._Control:IsEnemyShow(enemyId)
            if isShow then
                return self._Control:GetConfig():GetPositionUiNodeName(posId)
            end
        end
    end
end

-- 聚焦到目标为止
---@param isWait boolean 是否等待
function XUiPanelLuosaitaSection:GotoFocusTarget(isAnim, isWait)
    local uiNodeName = self:GetFocusTargetUiNodeName()
    if string.IsNilOrEmpty(uiNodeName) then 
        return 
    end

    local posTransform = self:GetPositionLinkGo(uiNodeName)
    if not posTransform then
        return
    end
    
    local target = self.PanelAreaScaleDrag.Target
    local scale = target.transform.localScale
    local localPos = posTransform.localPosition
    local aimPos = XLuaVector3.New(-localPos.x * scale.x, -localPos.y * scale.y, localPos.z)
    
    -- 不播动画
    if not isAnim then
        target.transform.localPosition = aimPos
        return
    end
    
    local ANIM_TIME = 0.5
    local WAIT_TIEM = 1500
    if isWait then
        self:RemoveAnimWaitTimer()
        self.AnimWaitTimer = XScheduleManager.ScheduleOnce(function()
            target.transform:DOLocalMove(aimPos, ANIM_TIME)
        end, WAIT_TIEM)
    else
        target.transform:DOLocalMove(aimPos, ANIM_TIME)
    end
end

-- 移除动画等待时间
function XUiPanelLuosaitaSection:RemoveAnimWaitTimer()
    if self.AnimWaitTimer then
        XScheduleManager.UnSchedule(self.AnimWaitTimer)
        self.AnimWaitTimer = nil
    end
end

function XUiPanelLuosaitaSection:IsDragOperation()
    return self.PanelAreaScaleDrag.DragTranslate.IsFingerDrag
end

-- 设置拖拽和缩放组件是否启用
function XUiPanelLuosaitaSection:SetAreaScaleDragEnable(isEnable)
    self.PanelAreaScaleDrag.enabled = isEnable
end

function XUiPanelLuosaitaSection:GetAreaScaleDragPosition()
    return self.PanelAreaScaleDrag.Target.transform.localPosition
end

function XUiPanelLuosaitaSection:SetAreaScaleDragPosition(pos)
    self.PanelAreaScaleDrag.Target.transform.localPosition = pos
end

return XUiPanelLuosaitaSection
