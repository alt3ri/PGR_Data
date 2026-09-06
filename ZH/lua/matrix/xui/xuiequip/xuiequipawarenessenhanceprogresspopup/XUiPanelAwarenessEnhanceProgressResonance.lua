---@class XUiAwarenessEnhanceRemainingMaterial
---@field MaterialData table 材料显示数据
---@field RemainCount number 剩余数量

-- 意识一键养成共鸣进度面板
---@class XUiPanelAwarenessEnhanceProgressResonance : XUiNode
---@field Parent XUiEquipAwarenessEnhanceProgressPopup 所属进度弹窗
---@field _Control XEquipControl 装备控制器
---@field PanelTitle UiObject
---@field PanelContent UiObject
---@field GridCostItem UnityEngine.RectTransform 材料格子模板
---@field TitleGrid XUiGridEnhanceProgressUnit 进度标题组件
---@field SkillScrollRect UnityEngine.UI.ScrollRect 共鸣技能横向滚动组件
---@field ViewportCorners System.Array Viewport 世界坐标四角缓存
---@field SkillGridCorners System.Array 共鸣技能格子世界坐标四角缓存
---@field ExecuteCallbacks { onSuccess: fun(), onFail: fun(errorCode: number) }|nil 当前执行回调，取消或消费后清空
---@field CostItemGridList UiObject[] 材料格子缓存
---@field ResonanceTargetList XUiPanelAwarenessOneClickResonanceUnachievedSkillData[] 本次待处理的共鸣目标列表
---@field ResonanceSkillGridList XUiGridTRAwarenessResonanceSkill[] 共鸣技能格子缓存
---@field ExecutingTask XUiPanelAwarenessOneClickResonanceTask|nil 当前执行任务
---@field ResonanceResult XUiPanelAwarenessOneClickResonanceResult|nil 本次共鸣执行数据
---@field MaterialInsufficientMap table<string, true> 本轮流程中已确认不足的材料 Key 集合
---@field CompletedResonanceCount number 当前流程已完成的共鸣次数
---@field MaterialBudget XUiPanelAwarenessOneClickResonanceMaterialBudget|nil 最新的执行阶段材料预算
---@field IsSkillScrollDragging boolean 玩家是否正在拖拽技能列表
---@field AutoLocateResumeTime number 玩家松手后允许自动定位的实时截止时间
local XUiPanelAwarenessEnhanceProgressResonance = XClass(XUiNode, "XUiPanelAwarenessEnhanceProgressResonance")
local XUiGridEnhanceProgressUnit = require("XUi/XUiEquip/XUiEquipEnhanceProgress/XUiGridEnhanceProgressUnit")
local XUiGridTRAwarenessResonanceSkill = require("XUi/XUiTeamRecommend/Grid/XUiGridTRAwarenessResonanceSkill")
local CSInstantiate = CS.UnityEngine.Object.Instantiate

local PROGRESS_KEY_RESONANCE = "AwarenessResonance"
local PROCESSING_TEXT_KEY_RESONANCE = "AwarenessOneClickResonanceProcessing"
-- 共鸣技能自动滚动动画时长，单位：秒。
local SCROLL_DURATION = 0.2
-- 玩家松手后恢复自动定位的等待时长，单位：秒。
local SKILL_SCROLL_AUTO_LOCATE_DELAY_SECONDS = 3
-- RectTransform:GetWorldCorners 按左下、左上、右上、右下顺序写入四个顶点。
local RECT_TRANSFORM_CORNER_COUNT = 4
local TARGET_MATCH_MODE = XEnumConst.EQUIP.AWARENESS_RESONANCE_TARGET_MATCH_MODE
local SKILL_TYPE_TEXT_KEY_BY_MATCH_MODE = {
    [TARGET_MATCH_MODE.ANY] = "AwarenessOneClickResonanceSkillTypeAny",
    [TARGET_MATCH_MODE.ATTACK] = {
        [XEnumConst.EQUIP.AWARENESS_RESONANCE_POS.UP] = "AwarenessOneClickResonanceSkillTypeAttackAttribute",
        [XEnumConst.EQUIP.AWARENESS_RESONANCE_POS.DOWN] = "AwarenessOneClickResonanceSkillTypeAttack",
    },
    [TARGET_MATCH_MODE.TARGET] = "AwarenessOneClickResonanceSkillTypeTarget",
}

-- 获取指定共鸣位和匹配模式对应的方案文案 Key。
---@param resonancePos number 共鸣位
---@param targetMatchMode XEquipAwarenessResonanceTargetMatchMode
---@return string|nil
local function GetSkillTypeTextKey(resonancePos, targetMatchMode)
    local textKey = SKILL_TYPE_TEXT_KEY_BY_MATCH_MODE[targetMatchMode]
    return type(textKey) == "table" and textKey[resonancePos] or textKey
end

-- 将 RectTransform 的世界坐标边界转换为指定节点下的水平边界。
---@param relativeTransform UnityEngine.RectTransform
---@param rectTransform UnityEngine.RectTransform
---@param cornerBuffer System.Array
---@return number left
---@return number right
local function ReadHorizontalBounds(relativeTransform, rectTransform, cornerBuffer)
    rectTransform:GetWorldCorners(cornerBuffer)
    local left = relativeTransform:InverseTransformPoint(cornerBuffer[0]).x
    local right = relativeTransform:InverseTransformPoint(cornerBuffer[2]).x
    return left, right
end

-- 初始化进度标题、格子缓存和执行状态
function XUiPanelAwarenessEnhanceProgressResonance:OnStart()
    self.TitleGrid = XUiGridEnhanceProgressUnit.New(self.PanelTitle, self)
    self.SkillScrollRect = self.PanelContent:GetObject("ListSkill")
    self.ViewportCorners = CS.System.Array.CreateInstance(typeof(CS.UnityEngine.Vector3), RECT_TRANSFORM_CORNER_COUNT)
    self.SkillGridCorners = CS.System.Array.CreateInstance(typeof(CS.UnityEngine.Vector3), RECT_TRANSFORM_CORNER_COUNT)
    self.ExecuteCallbacks = nil
    self.CostItemGridList = {}
    self.ResonanceTargetList = {}
    self.ResonanceSkillGridList = {}
    self.ExecutingTask = nil
    self.ResonanceResult = nil
    self.MaterialInsufficientMap = {}
    self.CompletedResonanceCount = 0
    self.MaterialBudget = nil
    self.IsSkillScrollDragging = false
    self.AutoLocateResumeTime = 0
    self:InitSkillScrollAutoLocate()
end

-- 注册列表拖拽事件。XUiWidget 仅用于区分玩家手势，不接管 ScrollRect 的滚动行为。
function XUiPanelAwarenessEnhanceProgressResonance:InitSkillScrollAutoLocate()
    local scrollGameObject = self.SkillScrollRect.gameObject
    local uiWidget = scrollGameObject:GetComponent(typeof(CS.XUiWidget))
    if not uiWidget then
        uiWidget = scrollGameObject:AddComponent(typeof(CS.XUiWidget))
    end

    uiWidget:AddBeginDragListener(function()
        self:OnSkillScrollBeginDrag()
    end)
    uiWidget:AddEndDragListener(function()
        self:OnSkillScrollEndDrag()
    end)
end

-- 玩家开始拖拽时停止正在执行的自动定位，拖拽期间始终不允许自动定位抢回列表。
function XUiPanelAwarenessEnhanceProgressResonance:OnSkillScrollBeginDrag()
    self.IsSkillScrollDragging = true
    self.SkillScrollRect:StopMovement()
    self.SkillScrollRect.content:DOKill()
end

-- 玩家松手后延后自动定位。
function XUiPanelAwarenessEnhanceProgressResonance:OnSkillScrollEndDrag()
    self.IsSkillScrollDragging = false
    self.AutoLocateResumeTime = CS.UnityEngine.Time.realtimeSinceStartup + SKILL_SCROLL_AUTO_LOCATE_DELAY_SECONDS
end

-- 判断当前时刻是否允许自动定位；调用方传入时间，保证该判断不修改面板状态。
---@param now number Unity 未受时间缩放影响的实时秒数
---@return boolean
function XUiPanelAwarenessEnhanceProgressResonance:IsSkillScrollAutoLocateAvailable(now)
    return not self.IsSkillScrollDragging and now >= self.AutoLocateResumeTime
end

-- 根据共鸣预览结果刷新目标展示
---@param resonanceResult XUiPanelAwarenessOneClickResonanceResult 共鸣预览结果
function XUiPanelAwarenessEnhanceProgressResonance:Refresh(resonanceResult)
    self.ExecutingTask = nil
    self.ResonanceResult = resonanceResult
    self.MaterialInsufficientMap = {}
    self.MaterialBudget = resonanceResult.MaterialBudget
    self.PanelContent.gameObject:SetActiveEx(true)
    self:RefreshTitleGrid(resonanceResult)
    self:RefreshCostItemGrids(self.MaterialBudget)
    self.ResonanceTargetList = resonanceResult.UnachievedList
    self:RefreshResonanceSkillGrids()
end

-- 刷新共鸣目标文案
---@param resonanceResult XUiPanelAwarenessOneClickResonanceResult 共鸣预览结果
function XUiPanelAwarenessEnhanceProgressResonance:RefreshTitleGrid(resonanceResult)
    self.TitleGrid:Update({
        Key = PROGRESS_KEY_RESONANCE,
        Name = self.TitleGrid.UiTxtUnitName.text,
        Target = self:GetTargetPreviewText(resonanceResult),
        ProcessingTextKey = PROCESSING_TEXT_KEY_RESONANCE,
    })
end

-- 根据上下排共鸣技能类型生成目标文案
---@param resonanceResult XUiPanelAwarenessOneClickResonanceResult 共鸣预览结果
---@return string 共鸣目标文案
function XUiPanelAwarenessEnhanceProgressResonance:GetTargetPreviewText(resonanceResult)
    local resonancePos = XEnumConst.EQUIP.AWARENESS_RESONANCE_POS
    local targetMatchModeByPos = resonanceResult.TargetMatchModeByPos
    local upSkillTypeTextKey = GetSkillTypeTextKey(resonancePos.UP, targetMatchModeByPos[resonancePos.UP])
    local downSkillTypeTextKey = GetSkillTypeTextKey(resonancePos.DOWN, targetMatchModeByPos[resonancePos.DOWN])
    local upTargetText
    local downTargetText
    if upSkillTypeTextKey then
        local upSkillTypeText = XUiHelper.GetText(upSkillTypeTextKey)
        upTargetText = XUiHelper.GetText("AwarenessOneClickResonanceTargetUpDesc", upSkillTypeText)
    end
    if downSkillTypeTextKey then
        local downSkillTypeText = XUiHelper.GetText(downSkillTypeTextKey)
        downTargetText = XUiHelper.GetText("AwarenessOneClickResonanceTargetDownDesc", downSkillTypeText)
    end

    if upTargetText and downTargetText then
        return XUiHelper.GetText("AwarenessOneClickResonanceTargetCombinedDesc", upTargetText, downTargetText)
    end
    return upTargetText or downTargetText or ""
end

-- 根据材料预算刷新全部已选材料及其执行阶段剩余数量
---@param materialBudget XUiPanelAwarenessOneClickResonanceMaterialBudget 材料预算
function XUiPanelAwarenessEnhanceProgressResonance:RefreshCostItemGrids(materialBudget)
    local displayMaterialList = materialBudget.DisplayMaterialList
    local minCostCountMap = self:BuildPendingMaterialMinCostCountMap(displayMaterialList)
    for index, materialData in ipairs(displayMaterialList) do
        local grid = self:GetOrCreateCostItemGrid(index)
        local materialKey = materialData.MaterialKey
        local remainCount = materialBudget.SelectedCountMap[materialKey] or 0
        local minCostCount = minCostCountMap[materialKey]
        local isMaterialInsufficient = self.MaterialInsufficientMap[materialKey] == true
        if not isMaterialInsufficient and self:IsMaterialInsufficient(materialData, remainCount, minCostCount) then
            self.MaterialInsufficientMap[materialKey] = true
            isMaterialInsufficient = true
        end
        self:RefreshCostItemGrid(grid, materialData, remainCount, isMaterialInsufficient)
        grid.gameObject:SetActiveEx(true)
    end

    for index = #displayMaterialList + 1, #self.CostItemGridList do
        self.CostItemGridList[index].gameObject:SetActiveEx(false)
    end
end

-- 根据当前及后续未完成任务，计算各道具材料可支持一次共鸣的最低消耗数量。
---@param displayMaterialList table[] 已选材料展示列表
---@return table<string, number> 材料 Key 到最低单次消耗数量的映射
function XUiPanelAwarenessEnhanceProgressResonance:BuildPendingMaterialMinCostCountMap(displayMaterialList)
    local result = {}
    local resonanceResult = self.ResonanceResult

    local resonanceControl = self._Control.ResonanceControl
    local taskList = resonanceResult.TaskList
    local firstPendingTaskIndex = 1
    if self.ExecutingTask then
        firstPendingTaskIndex = table.indexof(taskList, self.ExecutingTask)
    end
    local costType = XEnumConst.EQUIP.RESONANCE_COST_TYPE

    for taskIndex = firstPendingTaskIndex, #taskList do
        local task = taskList[taskIndex]
        local isTimesExhausted = task.ExecutedTimes >= task.MaxTimes
        local equip = self._Control:GetEquip(task.EquipId)
        local resonanceInfo = equip:GetResonanceInfo(task.Pos)
        local isTargetReached = resonanceControl:IsAwarenessResonanceTargetReached(
            task.Target, resonanceResult.CharacterId, resonanceInfo)
        if not isTimesExhausted and not isTargetReached then
            for _, materialData in ipairs(displayMaterialList) do
                if materialData.Type ~= costType.AWARENESS
                        and resonanceControl:IsAwarenessResonanceCostAvailable(task.Target, materialData) then
                    local costCount = resonanceControl:GetAwarenessResonanceCostCount(materialData, equip)
                    local materialKey = materialData.MaterialKey
                    local oldMinCostCount = result[materialKey]
                    if costCount and costCount > 0 and (not oldMinCostCount or costCount < oldMinCostCount) then
                        result[materialKey] = costCount
                    end
                end
            end
        end
    end

    return result
end

-- 获取执行完成后的剩余材料，只返回数量大于零的展示数据
---@return XUiAwarenessEnhanceRemainingMaterial[]
function XUiPanelAwarenessEnhanceProgressResonance:GetRemainingMaterialList()
    local remainingMaterialList = {}
    local materialBudget = self.MaterialBudget
    if not materialBudget then
        return remainingMaterialList
    end

    for _, materialData in ipairs(materialBudget.DisplayMaterialList) do
        local remainCount = materialBudget.SelectedCountMap[materialData.MaterialKey] or 0
        if remainCount > 0 then
            table.insert(remainingMaterialList, {
                MaterialData = materialData,
                RemainCount = remainCount,
            })
        end
    end

    return remainingMaterialList
end

-- 按本次共鸣目标刷新技能格子；格子根据装备和槽位实时读取当前共鸣技能
---@param isPlayResonanceEffect boolean|nil 是否播放当前已确认共鸣格子的特效
function XUiPanelAwarenessEnhanceProgressResonance:RefreshResonanceSkillGrids(isPlayResonanceEffect)
    local executingIndex
    for index, targetData in ipairs(self.ResonanceTargetList) do
        local grid = self:GetOrCreateResonanceSkillGrid(index)
        local targetResonanceData = self:GetResonanceTargetData(targetData)
        grid:Refresh({
            ResonanceData = targetResonanceData.ResonanceData,
            Site = targetData.Site,
            Pos = targetData.Pos,
            WearingEquipId = targetData.EquipId,
            TargetState = targetResonanceData.TargetState,
            TargetMatchMode = targetData.Target.MatchMode,
        })
        grid:SetImgEffectShow(false)
        local isExecuting = self:IsExecutingResonanceTarget(targetData)
        grid:SetSelected(isExecuting)
        grid.GameObject:SetActiveEx(true)
        if isExecuting then
            executingIndex = index
            if isPlayResonanceEffect then
                grid:SetImgEffectShow(true)
            end
        end
    end

    for index = #self.ResonanceTargetList + 1, #self.ResonanceSkillGridList do
        self.ResonanceSkillGridList[index].GameObject:SetActiveEx(false)
    end

    local now = CS.UnityEngine.Time.realtimeSinceStartup
    if executingIndex and self:IsSkillScrollAutoLocateAvailable(now) then
        self:EnsureExecutingResonanceSkillVisible(executingIndex)
    end
end

-- 根据当前执行格位于 Viewport 左右半区，优先完整显示对应相邻格；到达内容边界时对齐边缘
---@param executingIndex number 当前执行的共鸣技能格下标
function XUiPanelAwarenessEnhanceProgressResonance:EnsureExecutingResonanceSkillVisible(executingIndex)
    local skillScrollRect = self.SkillScrollRect
    local content = skillScrollRect.content
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(content)

    local executingGrid = self.ResonanceSkillGridList[executingIndex]
    local gridRectTransform = executingGrid.GameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
    local viewportLeft, viewportRight = ReadHorizontalBounds(content, skillScrollRect.viewport, self.ViewportCorners)
    local gridLeft, gridRight = ReadHorizontalBounds(content, gridRectTransform, self.SkillGridCorners)
    local viewportCenter = (viewportLeft + viewportRight) * 0.5
    local gridCenter = (gridLeft + gridRight) * 0.5
    -- 执行格位于左半区时优先预留上一格，右半区时优先预留下一格。
    local isGridOnLeftSide = gridCenter < viewportCenter
    local scrollOffset = 0

    if isGridOnLeftSide then
        local previousGrid
        if executingIndex > 1 then
            previousGrid = self.ResonanceSkillGridList[executingIndex - 1]
        end
        local desiredLeft = content.rect.xMin
        if previousGrid then
            local previousRectTransform = previousGrid.GameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
            desiredLeft = ReadHorizontalBounds(content, previousRectTransform, self.SkillGridCorners)
        end
        -- 上一格已完整显示时保持当前位置；没有上一格时仅在未到内容左边缘时回退。
        scrollOffset = math.max(viewportLeft - desiredLeft, 0)
    else
        local nextGrid
        if executingIndex < #self.ResonanceTargetList then
            nextGrid = self.ResonanceSkillGridList[executingIndex + 1]
        end
        local desiredRight = content.rect.xMax
        if nextGrid then
            local nextRectTransform = nextGrid.GameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
            local _, nextRight = ReadHorizontalBounds(content, nextRectTransform, self.SkillGridCorners)
            desiredRight = nextRight
        end
        -- 下一格已完整显示时保持当前位置；没有下一格时仅在未到内容右边缘时回退。
        scrollOffset = math.min(viewportRight - desiredRight, 0)
    end

    local minScrollOffset = viewportRight - content.rect.xMax
    local maxScrollOffset = viewportLeft - content.rect.xMin
    -- Content 未超出 Viewport 时不存在合法滚动区间，保留布局的默认位置。
    if minScrollOffset > maxScrollOffset then
        return
    end
    scrollOffset = math.max(minScrollOffset, math.min(scrollOffset, maxScrollOffset))
    if scrollOffset == 0 then
        return
    end

    skillScrollRect:StopMovement()
    local anchoredPosition = content.anchoredPosition
    local targetAnchoredPosition = CS.UnityEngine.Vector2(anchoredPosition.x + scrollOffset, anchoredPosition.y)
    content:DOKill()
    content:DOAnchorPos(targetAnchoredPosition, SCROLL_DURATION):SetEase(CS.DG.Tweening.Ease.OutQuad)
end

-- 获取单个共鸣目标的技能数据与当前达成状态，供进度格和完成数统计共用
---@param targetData XUiPanelAwarenessOneClickResonanceUnachievedSkillData 共鸣目标数据
---@return { ResonanceData: table, TargetState: XEquipAwarenessResonanceTargetState }
function XUiPanelAwarenessEnhanceProgressResonance:GetResonanceTargetData(targetData)
    local target = targetData.Target
    local targetResonanceData = {
        ResonanceType = target.TargetType,
        SkillId = target.TargetSkillId,
    }
    local equip = self._Control:GetEquip(targetData.EquipId)
    local targetState = self._Control.ResonanceControl:GetAwarenessResonanceTargetMatchState(
        equip, target, targetData.CharacterId)

    return {
        ResonanceData = targetResonanceData,
        TargetState = targetState,
    }
end

-- 统计本次共鸣目标中已实际达到目标技能的数量
---@return number 已达成目标数
function XUiPanelAwarenessEnhanceProgressResonance:GetAchievedResonanceTargetCount()
    local achievedCount = 0
    for _, targetData in ipairs(self.ResonanceTargetList) do
        local targetResonanceData = self:GetResonanceTargetData(targetData)
        if targetResonanceData.TargetState.IsAchieved then
            achievedCount = achievedCount + 1
        end
    end

    return achievedCount
end

-- 获取指定下标的共鸣技能格子，不存在时按模板创建
---@param index number 格子下标
---@return XUiGridTRAwarenessResonanceSkill 共鸣技能格子
function XUiPanelAwarenessEnhanceProgressResonance:GetOrCreateResonanceSkillGrid(index)
    local grid = self.ResonanceSkillGridList[index]
    if grid then
        return grid
    end

    local template = self.PanelContent:GetObject("GridResonanceSkill")
    template.gameObject:SetActiveEx(false)
    local ui = CSInstantiate(template, template.transform.parent)
    grid = XUiGridTRAwarenessResonanceSkill.New(ui, self)
    grid:SetEnableClick(false)
    self.ResonanceSkillGridList[index] = grid

    return grid
end

-- 通过装备和槽位判断目标是否对应当前执行任务
---@param targetData XUiPanelAwarenessOneClickResonanceUnachievedSkillData 共鸣目标数据
---@return boolean 是否正在执行该目标
function XUiPanelAwarenessEnhanceProgressResonance:IsExecutingResonanceTarget(targetData)
    local executingTask = self.ExecutingTask
    return executingTask ~= nil and executingTask.EquipId == targetData.EquipId and executingTask.Pos == targetData.Pos
end

-- 获取指定下标的材料格子，不存在时按模板创建
---@param index number 格子下标
---@return UiObject
function XUiPanelAwarenessEnhanceProgressResonance:GetOrCreateCostItemGrid(index)
    local grid = self.CostItemGridList[index]
    if not grid then
        local gridCostItem = self.PanelContent:GetObject("GridCostItem")
        gridCostItem.gameObject:SetActiveEx(false)
        local ui = CSInstantiate(gridCostItem, gridCostItem.transform.parent)
        grid = ui:GetComponent(typeof(CS.UiObject))
        self.CostItemGridList[index] = grid
    end

    return grid
end

-- 判断材料剩余数量是否已经无法支持后续任意一次共鸣
---@param materialData table 材料展示数据
---@param remainCount number 当前剩余数量
---@param minCostCount number|nil 后续任务使用该道具材料的最低单次消耗数量
---@return boolean
function XUiPanelAwarenessEnhanceProgressResonance:IsMaterialInsufficient(materialData, remainCount, minCostCount)
    if materialData.Type == XEnumConst.EQUIP.RESONANCE_COST_TYPE.AWARENESS then
        return remainCount <= 0
    end

    return minCostCount ~= nil and remainCount < minCostCount
end

-- 刷新单个材料格子的图标、品质、剩余数量和不足暗层
---@param grid UiObject 材料格子
---@param materialData table 材料显示数据
---@param remainCount number 执行阶段剩余可消耗数量
---@param isMaterialInsufficient boolean 材料是否已经不足
function XUiPanelAwarenessEnhanceProgressResonance:RefreshCostItemGrid(grid, materialData, remainCount, isMaterialInsufficient)
    local iconObject = grid:GetObject("RImgIcon")
    local qualityObject = grid:GetObject("ImgQuality")
    local haveCountObject = grid:GetObject("TxtHaveCount")
    local darkObject = grid:GetObject("ImgDark")

    local icon
    local quality

    if materialData.Type == XEnumConst.EQUIP.RESONANCE_COST_TYPE.AWARENESS then
        icon = XMVCA.XEquip:GetEquipIconPath(materialData.IconTemplateId)
        quality = materialData.Star
    else
        local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(materialData.ItemId)
        icon = goodsShowParams.Icon
        quality = goodsShowParams.Quality
    end

    iconObject:SetRawImage(icon)
    XUiHelper.SetQualityIcon(self.Parent, qualityObject, quality)
    haveCountObject.text = string.format("x%d", remainCount)
    darkObject.gameObject:SetActiveEx(isMaterialInsufficient)
end

-- 仅重置展示进度并更新状态；实际共鸣请求由父界面完成固定等待后调用 Execute 发起。
function XUiPanelAwarenessEnhanceProgressResonance:PrepareExecute()
    self.CompletedResonanceCount = 0
    self.TitleGrid:SetStatus(XUiGridEnhanceProgressUnit.STATUS.Processing, self.CompletedResonanceCount)
end

-- 启动共鸣流程，并通过回调返回执行结果
---@param resonanceResult XUiPanelAwarenessOneClickResonanceResult 共鸣预览结果
---@param callbacks { onSuccess: fun(), onFail: fun(errorCode: number) } 执行结果回调
function XUiPanelAwarenessEnhanceProgressResonance:Execute(resonanceResult, callbacks)
    self.ExecuteCallbacks = callbacks
    self.ExecutingTask = nil
    self.ResonanceResult = resonanceResult
    self.ResonanceTargetList = resonanceResult.UnachievedList
    self:RefreshResonanceSkillGrids()

    self._Control.ResonanceControl:StartAwarenessResonance(resonanceResult, {
        onFinish = function(isSuccess, errorCode)
            self:OnResonanceFinish(isSuccess, errorCode)
        end,
        onProgress = function(materialBudget)
            self:OnResonanceProgress(materialBudget)
        end,
        onTaskExecuting = function(task)
            self:OnResonanceTaskExecuting(task)
        end,
    })
end

-- 处理共鸣流程结束，清除执行高亮并向进度弹窗返回最终结果
---@param isSuccess boolean 是否执行成功
---@param errorCode number|nil 失败错误码
function XUiPanelAwarenessEnhanceProgressResonance:OnResonanceFinish(isSuccess, errorCode)
    local executeCallbacks = self.ExecuteCallbacks
    self.ExecuteCallbacks = nil
    self.ExecutingTask = nil
    self:RefreshResonanceSkillGrids()
    if not executeCallbacks then
        return
    end

    if isSuccess then
        local achievedCount = self:GetAchievedResonanceTargetCount()
        self.TitleGrid:SetStatus(XUiGridEnhanceProgressUnit.STATUS.Done, achievedCount, #self.ResonanceTargetList)
        self.PanelContent.gameObject:SetActiveEx(false)
        executeCallbacks.onSuccess()
    else
        self.TitleGrid:SetStatus(XUiGridEnhanceProgressUnit.STATUS.Waiting)
        executeCallbacks.onFail(errorCode)
    end
end

-- 每次共鸣结果确认后刷新剩余材料和目标槽位的当前技能
---@param materialBudget XUiPanelAwarenessOneClickResonanceMaterialBudget 执行阶段材料预算
function XUiPanelAwarenessEnhanceProgressResonance:OnResonanceProgress(materialBudget)
    self.MaterialBudget = materialBudget
    self.CompletedResonanceCount = self.CompletedResonanceCount + 1
    self.TitleGrid:SetStatus(XUiGridEnhanceProgressUnit.STATUS.Processing, self.CompletedResonanceCount)
    self:RefreshCostItemGrids(materialBudget)
    self:RefreshResonanceSkillGrids(true)
end

--- 获取本次流程实际成功的共鸣次数。
---@return number
function XUiPanelAwarenessEnhanceProgressResonance:GetCompletedResonanceCount()
    return self.CompletedResonanceCount
end

-- 根据即将执行的 Task 更新高亮；同一共鸣目标可能对应多个 Task
---@param task XUiPanelAwarenessOneClickResonanceTask 当前执行任务
function XUiPanelAwarenessEnhanceProgressResonance:OnResonanceTaskExecuting(task)
    self.ExecutingTask = task
    self:RefreshCostItemGrids(self.MaterialBudget)
    self:RefreshResonanceSkillGrids()
end

-- 取消共鸣流程，并使尚未返回的异步回调失效
function XUiPanelAwarenessEnhanceProgressResonance:Cancel()
    self.ExecuteCallbacks = nil
    self.ExecutingTask = nil
    self._Control.ResonanceControl:CancelAwarenessResonance()
    self.TitleGrid:SetStatus(XUiGridEnhanceProgressUnit.STATUS.Waiting)
    self:RefreshResonanceSkillGrids()
end

return XUiPanelAwarenessEnhanceProgressResonance
