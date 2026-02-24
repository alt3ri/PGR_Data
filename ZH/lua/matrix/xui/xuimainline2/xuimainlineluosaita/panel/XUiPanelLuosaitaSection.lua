local XUiGridLuosaitaBlock = require("XUi/XUiMainLine2/XUiMainLineLuosaita/Grid/XUiGridLuosaitaBlock")
local XUiGridLuosaitaMemberCharacter = require("XUi/XUiMainLine2/XUiMainLineLuosaita/Grid/XUiGridLuosaitaMemberCharacter")
local XUiGridLuosaitaMemberArmy = require("XUi/XUiMainLine2/XUiMainLineLuosaita/Grid/XUiGridLuosaitaMemberArmy")
local XUiGridLuosaitaMemberEnemy = require("XUi/XUiMainLine2/XUiMainLineLuosaita/Grid/XUiGridLuosaitaMemberEnemy")
local XUiGridLuosaitaMemberStage = require("XUi/XUiMainLine2/XUiMainLineLuosaita/Grid/XUiGridLuosaitaMemberStage")
local CSTween = CS.DG.Tweening
local Vector3 = CS.UnityEngine.Vector3
local Quaternion = CS.UnityEngine.Quaternion
local Mathf = CS.UnityEngine.Mathf

-- 罗塞塔主线阶段面板
---@class XUiPanelLuosaitaSection : XUiNode
---@field Parent XUiMainLineLuosaitaMain
---@field _Control XMainLineLuosaitaControl
---@field _GridPositions table<number, XUiGridLuosaitaMember>
---@field _GridBlocks table<number, XUiGridLuosaitaBlock>
---@field IsMapMoving boolean 地图是否在移动中
local XUiPanelLuosaitaSection = XClass(XUiNode, "XUiPanelLuosaitaSection")

function XUiPanelLuosaitaSection:OnStart(sectionId)
    self.SectionId = sectionId
    self._GridBlocks = {}
    self._GridPositions = {}
    self.FOCUS_SPEED = self._Control:GetConfig():GetConfigNumber("FocusSpeed", 1)
    
    self:InitDragArea()
    self:InitPositions()
    self:RegisterUiEvents()
    self:LoadSectionLoopAnim()

    local pos = self.Parent:GetResumePos(self.SectionId)
    if pos then
        -- 恢复到上次关闭时候的位置
        self:SetAreaScaleDragPosition(pos)
        self:Refresh(false)
    else
        -- 定位可挑战关卡/敌军
        self:GotoFocusTarget(false)
        -- 刷新界面
        self:Refresh(false)
    end
end

function XUiPanelLuosaitaSection:OnEnable()
    self:UpdateAreaDragEnable()
end

function XUiPanelLuosaitaSection:OnDestroy()
    self:ClearSequence()
    self:RemoveAnimWaitTimer()
end

function XUiPanelLuosaitaSection:RegisterUiEvents()
    if self.BtnSkyGarden then
        XUiHelper.RegisterClickEvent(self, self.BtnSkyGarden, self.OnBtnSkyGardenClick)
    end
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

function XUiPanelLuosaitaSection:Refresh(isCheckSwitchSection, checkWaitTime)
    self:ClearCharacterMoveNode()
    self:RefreshBlocks()
    self:RefreshPositions()
    self:RefreshSkyGardenButton()
    self:UpdateAreaDragEnable()

    if checkWaitTime and checkWaitTime > 0 then
        self:RemoveAnimWaitTimer()
        self.AnimWaitTimer = XScheduleManager.ScheduleOnce(function()
            self:CheckAnim(isCheckSwitchSection)
        end, checkWaitTime)
    else
        self:CheckAnim(isCheckSwitchSection)
    end
end

function XUiPanelLuosaitaSection:CheckAnim(isCheckSwitchSection)
    -- 检查打开文件弹窗
    if self:CheckOpenPopUpDocument() then
        return
    end
    -- 检查播放角色移动
    if self:CheckPlayCharacterMove() then
        return
    end
    -- 检查播放阶段特效动画
    if self:CheckPlaySectionEnableAnim() then
        return
    end
    -- 定位军队/关卡
    self:GotoFocusTarget(true)
    -- 检查切换阶段
    if isCheckSwitchSection then
        self.Parent:CheckSwitchNextSection()
    end
end

-- 刷新块
function XUiPanelLuosaitaSection:RefreshBlocks()
    local sectionInfo = self._Control:GetSectionInfo(self.SectionId)
    local blockInfos = sectionInfo:GetBlockInfoDic()
    for _, blockInfo in pairs(blockInfos) do
        local blockId = blockInfo:GetId()
        local gridBlock = self._GridBlocks[blockId]
        if not gridBlock then
            local uiNodeName = self._Control:GetConfig():GetBlockUiNodeName(blockId)
            local blockTransform = self.PanelBlock:Find(uiNodeName)
            if not blockTransform then
                XLog.Error("阶段预制体缺少地块:" .. uiNodeName)
                goto CONTINUE
            end
            gridBlock = XUiGridLuosaitaBlock.New(blockTransform, self)
            self._GridBlocks[blockId] = gridBlock
        end
        gridBlock:Open()
        gridBlock:Refresh(blockInfo)
        :: CONTINUE ::
    end
end

-- 初始化拖拽缩放组件设置
function XUiPanelLuosaitaSection:InitDragArea()
    self.PanelAreaScaleDrag.MaxScale = XMVCA.XMainLineLuosaita.EnumConst.MAX_SCALE
    self.PanelAreaScaleDrag.MinScale = XMVCA.XMainLineLuosaita.EnumConst.MIN_SCALE
end

-- 初始化点位
function XUiPanelLuosaitaSection:InitPositions()
    -- 默认隐藏
    local childCnt = self.PanelPosition.transform.childCount
    local btnSkyGardenName = "BtnSkyGarden"
    for i = 1, childCnt do
        local childGo = self.PanelPosition.transform:GetChild(i - 1)
        if childGo.gameObject.name ~= btnSkyGardenName then
            childGo.gameObject:SetActiveEx(false)
        end
    end
end

-- 刷新点位
function XUiPanelLuosaitaSection:RefreshPositions()
    local sectionInfo = self._Control:GetSectionInfo(self.SectionId)
    local posConfigs = self._Control:GetConfig():GetConfigPositionsBySectionId(self.SectionId)
    for _, posConfig in pairs(posConfigs) do
        -- UI节点检测
        local posTransform = self:GetPositionLinkGo(posConfig.UiNodeName)
        if not posTransform then
            goto CONTINUE
        end
        
        local posId = posConfig.Id
        local grid = self._GridPositions[posId]
        local posInfo = sectionInfo:GetPositionInfo(posId)
        
        -- 移除点位
        if not posInfo then
            if grid and grid:IsNodeShow() then
                grid:Hide()
            end
            posTransform.gameObject:SetActiveEx(false)
            goto CONTINUE
            
        -- 点位类型变化，删除旧点位，加载新点位
        elseif grid and posInfo:GetType() ~= grid:GetType() then
            self:RemoveChildNode(grid)
            self._GridPositions[posId] = nil
            grid = nil
        end

        -- 创建
        posTransform.gameObject:SetActiveEx(true)
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
        :: CONTINUE ::
    end
    
    -- 清理缓存
    sectionInfo:ClearLastPositionInfoDic()
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
    
    -- 已完成隐藏特效
    if passed and taskFinished then
        self.FxUiBtnSkyGardenV42 = self.FxUiBtnSkyGardenV42 or self.BtnSkyGarden.transform:FindTransform("FxUiBtnSkyGardenV42")
        if self.FxUiBtnSkyGardenV42 then
            self.FxUiBtnSkyGardenV42.gameObject:SetActiveEx(false)
        end
    end
end

--region 角色移动
-- 检测是否播放角色移动
function XUiPanelLuosaitaSection:CheckPlayCharacterMove()
    -- 移动中
    if self.CharacterMoveNode then
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
    self:ClearCharacterMoveNode()
    
    local endUiNodeName = self._Control:GetConfig():GetPositionUiNodeName(endPosId)
    ---@type XUiGridLuosaitaMemberCharacter
    local startGrid = self._GridPositions[startPosId]
    self.CharacterMoveNode = startGrid.LinkGameObject
    local endLinkGo = self:GetPositionLinkGo(endUiNodeName)

    local moveStartPos = self.CharacterMoveNode.transform.localPosition -- 角色移动开始位置
    local moveAimPos = endLinkGo.transform.localPosition -- 角色移动结束位置
    self.CharacterMoveNodeOriginPos = moveStartPos

    local focusAimPos = Vector3((moveAimPos.x - moveStartPos.x)/2, (moveAimPos.y + moveStartPos.y)/2, (moveAimPos.z - moveStartPos.z)/2)
    self:FocusWithTargetPos(focusAimPos, true, function()
        XLuaUiManager.SetMask(true)
        self.IsMapMoving = true
        self:SetAreaDragEnable(false)
        startGrid:ShowMovingEffect(true)
        self.CharacterMoveNode.transform:DOLocalMove(moveAimPos, time):SetEase(CSTween.Ease.OutQuad):OnComplete(function()
            XLuaUiManager.SetMask(false)
            self.IsMapMoving = false
            self:UpdateAreaDragEnable()
            
            startGrid:ShowMovingEffect(false)
            startGrid:Close()
            self:ClearCharacterMoveNode()
            self:Refresh(true)
        end)
    end)
end

function XUiPanelLuosaitaSection:ClearSequence()
    if self.Sequence then
        self.Sequence:Kill()
        self.Sequence = nil
    end
end

-- 复原角色移动节点
function XUiPanelLuosaitaSection:ClearCharacterMoveNode()
    if self.CharacterMoveNode then
        self.CharacterMoveNode.transform.localPosition = self.CharacterMoveNodeOriginPos
        self.CharacterMoveNode = nil
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
            self:OnPopUpDocumentClose()
        end)
        return true
    end
    return false
end

-- 文件弹窗关闭回调
function XUiPanelLuosaitaSection:OnPopUpDocumentClose()
    self.Parent:RefreshBtnReview()
    self:Refresh(true)
end
--endregion

--region 阶段动效
-- 检测播放阶段第一次满足条件激活的Enable动画
function XUiPanelLuosaitaSection:CheckPlaySectionEnableAnim()
    local sectionConfig = self._Control:GetConfig():GetConfigSection(self.SectionId)
    for i, enableAnim in ipairs(sectionConfig.EnableAnims) do
        local uiNodeName = sectionConfig.FocusPosUiNodeNames[i]
        local conditionId = sectionConfig.ConditionIds[i]
        local isReach = true -- 不填conditionId视为
        local tips
        if XTool.IsNumberValidEx(conditionId) then
            isReach, tips = XConditionManager.CheckCondition(conditionId)
        end
        if isReach and not self.ActivatedAnimDic[i] then
            self.ActivatedAnimDic[i] = true
            self:FocusWithUiNodeName(uiNodeName, true, function()
                if not string.IsNilOrEmpty(enableAnim) then
                    self:SetAreaDragEnable(false)
                    self:PlayAnimationWithMask(enableAnim, function()
                        self:UpdateAreaDragEnable()
                        self:Refresh()
                    end)
                end
            end)
            return true
        end
    end
    return false
end

-- 加载阶段满足条件激活的Loop动画
function XUiPanelLuosaitaSection:LoadSectionLoopAnim()
    local sectionConfig = self._Control:GetConfig():GetConfigSection(self.SectionId)
    
    -- 关卡战斗回来按照战斗前缓存的特效来播
    self.ActivatedAnimDic = self.Parent:GetResumeActivatedAnimDic(self.SectionId)
    if self.ActivatedAnimDic then
        for i, _ in ipairs(sectionConfig.FocusPosUiNodeNames) do
            local isReach = self.ActivatedAnimDic[i] == true
            local loopAnim = sectionConfig.LoopAnims[i]
            if isReach and not string.IsNilOrEmpty(loopAnim) then
                self:PlayAnimation(loopAnim)
            end
        end
        return
    end
    
    -- 进入界面/切换阶段 重新计算达成条件进行播放
    self.ActivatedAnimDic = {}
    for i, _ in ipairs(sectionConfig.FocusPosUiNodeNames) do
        local conditionId = sectionConfig.ConditionIds[i]
        local isReach = true -- 不填conditionId视为
        local tips
        if XTool.IsNumberValidEx(conditionId) then
            isReach, tips = XConditionManager.CheckCondition(conditionId)
        end
        if isReach then
            self.ActivatedAnimDic[i] = true
            local loopAnim = sectionConfig.LoopAnims[i]
            if not string.IsNilOrEmpty(loopAnim) then
                self:PlayAnimation(loopAnim)
            end
        end
    end
end

function XUiPanelLuosaitaSection:GetActivatedAnimDic()
    return self.ActivatedAnimDic
end
--endregion

--region 引导
-- 引导支持：预览友军攻击敌军
function XUiPanelLuosaitaSection:GuideAttackPreview(armyNodeName, enemyNodeName)
    self:GuideClearAttackPreview()
    
    local arrow = self.Parent.Arrow
    local target = self.PanelAreaScaleDrag.Target
    local scale = target.transform.localScale
    
    self.GuideGridArmy = self:GetGridPositionByUiNodeName(armyNodeName)
    self.GuideGridEnemy = self:GetGridPositionByUiNodeName(enemyNodeName)
    arrow.gameObject:SetActiveEx(true)
    local armyPos = self.GuideGridArmy.LinkGameObject.localPosition
    local enemyPos = self.GuideGridEnemy.LinkGameObject.localPosition
    local v2 = XLuaVector2.New((enemyPos.x - armyPos.x) * scale.x, (enemyPos.y - armyPos.y) * scale.y) -- 起点到终点的向量
    local ADD_HEIGHT = 40 -- 由于箭头图片预留空白，这里增加箭头高度，指向敌军中心点
    local height = XLuaVector2.Magnitude(v2) + ADD_HEIGHT -- 计算箭头高度
    local rotationAngle = math.atan(v2.y, v2.x) * Mathf.Rad2Deg - 90
    local rotation = Quaternion.AngleAxis(rotationAngle, Vector3.forward)
    arrow.position = self.GuideGridArmy.LinkGameObject.position
    arrow.sizeDelta = Vector2(arrow.sizeDelta.x, height)
    arrow.rotation = rotation
    self.GuideGridEnemy:ShowSelectEffect(true)

    self.Parent:SetFight(self.GuideGridArmy.MemberData, self.GuideGridEnemy.MemberData)
end

-- 引导支持：清除友军攻击敌军预览
function XUiPanelLuosaitaSection:GuideClearAttackPreview()
    if self.GuideGridEnemy then
        self.GuideGridEnemy:ShowSelectEffect(false)
        self.GuideGridEnemy = nil
    end
    self.Parent.Arrow.gameObject:SetActiveEx(false)
end

-- 引导支持：友军攻击敌军
function XUiPanelLuosaitaSection:GuideAttack(armyNodeName, enemyNodeName)
    self:GuideClearAttackPreview()

    local guideGridArmy = self:GetGridPositionByUiNodeName(armyNodeName)
    local guideGridEnemy = self:GetGridPositionByUiNodeName(enemyNodeName)
    local armyId = guideGridArmy:GetArmyId()
    local armyPosId = guideGridArmy.MemberData:GetPosId()
    local enemyPosId = guideGridEnemy.MemberData:GetPosId()
    
    -- 请求移动
    XMVCA.XMainLineLuosaita:RequestMainLineLuosaitaMove(self.SectionId, armyPosId, enemyPosId, function()
        -- 先播敌军死亡
        guideGridEnemy:PlayAnimDead(function()
            -- 播友军消失
            guideGridArmy:PlayAnimDisEnable(function()
                -- 刷新阶段
                local CHECK_ANIM_WAIT_TIME = 500
                self:Refresh(true, CHECK_ANIM_WAIT_TIME)
                -- 播放友军出现动画
                local grid = self:GetGridPosArmy(armyId)
                if grid then
                    grid:PlayAnimEnable()
                end
            end)
        end)
    end)

    self.Parent:ClearTalk()
    self.Parent:ClosePanelFight()
    self:SetIsLastOperationEnemy(true)
end

--endregion

function XUiPanelLuosaitaSection:GetGridBlocks()
    return self._GridBlocks
end

function XUiPanelLuosaitaSection:GetGridMembers()
    return self._GridPositions
end

---@return XUiGridLuosaitaMemberArmy
function XUiPanelLuosaitaSection:GetGridPosArmy(armId)
    for _, grid in pairs(self._GridPositions) do
        if grid:GetType() == XMVCA.XMainLineLuosaita.EnumConst.POS_TYPE.ARMY then
            if armId == grid:GetArmyId() then
                return grid
            end
        end
    end
end

-- 通过ui挂点名称获取位置单位
---@return XUiGridLuosaitaMember
function XUiPanelLuosaitaSection:GetGridPositionByUiNodeName(uiNodeName)
    for _, grid in pairs(self._GridPositions) do
        if grid.LinkGameObject.name == uiNodeName then
            return grid
        end
    end
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
    if sectionInfo:IsFinish() then
        return
    end
    
    -- 有未通关的关卡
    local positionInfos = sectionInfo:GetPositionInfos()
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

    -- 刚进阶段/挑战关卡回来，定位目标都需要包括敌军
    local isFocusWithEnemy = not self.IsLastOperationEnemy
    if isFocusWithEnemy then
        -- 有可挑战的敌军，多个军队的时候定位到id最大的军队
        local focusEnemyId = nil
        local focusEnemyPosId = nil
        for _, posInfo in ipairs(positionInfos) do
            if posInfo:IsEnemy() and self._Control:IsEnemyCanAttack(self.SectionId, posInfo) then
                local enemyId = posInfo:GetEnemyId()
                if not focusEnemyId or focusEnemyId < enemyId then
                    focusEnemyId = enemyId
                    focusEnemyPosId = posInfo:GetPosId()
                end
            end
        end
        if focusEnemyPosId then
            return self._Control:GetConfig():GetPositionUiNodeName(focusEnemyPosId)
        end
    end
end

-- 聚焦到目标为止
---@param isWait boolean 是否等待UiMainLineLuosaitaMain的AnimEnable播放完毕
function XUiPanelLuosaitaSection:GotoFocusTarget(isAnim)
    local uiNodeName = self:GetFocusTargetUiNodeName()
    self:FocusWithUiNodeName(uiNodeName, isAnim)
end

-- 聚焦到节点
function XUiPanelLuosaitaSection:FocusWithUiNodeName(uiNodeName, isAnim, cb)
    if string.IsNilOrEmpty(uiNodeName) then
        return
    end

    local posTransform = self:GetPositionLinkGo(uiNodeName)
    if not posTransform then
        return
    end

    self:FocusWithTargetPos(posTransform.localPosition, isAnim, cb)
end

-- 聚焦到位置
---@param targetPos Vector3 目标位置
function XUiPanelLuosaitaSection:FocusWithTargetPos(targetPos, isAnim, cb)
    -- 根据缩放确定聚焦位置
    local fixedArea = self.PanelAreaScaleDrag.FixedArea
    local target = self.PanelAreaScaleDrag.Target
    local scale = target.transform.localScale
    local focusX = -targetPos.x * scale.x
    local focusY = -targetPos.y * scale.y
    local focusZ = targetPos.z * scale.z

    -- 根据拖拽范围调整聚焦位置
    local absWidth = target.rect.width * target.localScale.x - fixedArea.rect.width * fixedArea.localScale.x
    local absHeight = target.rect.height * target.localScale.y - fixedArea.rect.height * fixedArea.localScale.y
    local maxFocusPosX = absWidth > 0 and absWidth / 2 or 0
    local maxFocusPosY = absHeight > 0 and absHeight / 2 or 0
    if focusX > maxFocusPosX then
        focusX = maxFocusPosX
    elseif focusX < -maxFocusPosX then
        focusX = -maxFocusPosX
    end
    if focusY > maxFocusPosY then
        focusY = maxFocusPosY
    elseif focusY < -maxFocusPosY then
        focusY = -maxFocusPosY
    end
    local focusPos = Vector3(focusX, focusY, focusZ)

    -- 不播动画
    if not isAnim then
        target.transform.localPosition = focusPos
        if cb then cb() end
        return
    end

    -- 播动画
    XLuaUiManager.SetMask(true)
    self.IsMapMoving = true
    self:SetAreaDragEnable(false)
    local distance = CS.UnityEngine.Vector3.Distance(target.transform.localPosition, focusPos)
    local animTime = distance / self.FOCUS_SPEED
    target.transform:DOLocalMove(focusPos, animTime):OnComplete(function()
        XLuaUiManager.SetMask(false)
        self.IsMapMoving = false
        self:UpdateAreaDragEnable()
        if cb then cb() end
    end)
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

-- 更新拖拽组件是否启用
function XUiPanelLuosaitaSection:UpdateAreaDragEnable()
    local isTopUi = XLuaUiManager.GetTopUiName() == "UiMainLineLuosaitaMain"
    self:SetAreaDragEnable(isTopUi)
end

-- 设置拖拽组件是否启用
function XUiPanelLuosaitaSection:SetAreaDragEnable(isEnable)
    self.PanelAreaScaleDrag.DragTranslate.enabled = isEnable
    self.PanelAreaScaleDrag.PinchScale.enabled = false
end

function XUiPanelLuosaitaSection:GetAreaScaleDragPosition()
    return self.PanelAreaScaleDrag.Target.transform.localPosition
end

function XUiPanelLuosaitaSection:SetAreaScaleDragPosition(pos)
    self.PanelAreaScaleDrag.Target.transform.localPosition = pos
end

-- 设置最后的操作是攻击敌军
function XUiPanelLuosaitaSection:SetIsLastOperationEnemy(isEnemy)
    self.IsLastOperationEnemy = isEnemy
end

return XUiPanelLuosaitaSection
