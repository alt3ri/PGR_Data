--- 关卡列表按组管理跳转等功能的组件
---@class XUiMainLine2StageAreaCom: XUiNode
---@field protected _Control XMainLine2Control
---@field Parent
local XUiMainLine2StageAreaCom = XClass(XUiNode, "XUiMainLine2StageAreaCom")

function XUiMainLine2StageAreaCom:OnStart(chapterId, stageId)
    self.ChapterId = chapterId
    self.StageId = stageId
    self.CurFocusAreaIndex = 1
    
    self:Init()
end

function XUiMainLine2StageAreaCom:OnEnable()
    self:Refresh()
end

function XUiMainLine2StageAreaCom:Init()
    -- 查找所有Area添加点击事件
    self._AreaUi = {}

    local areaCount = self._Control.UiStageAreaControl:GetChapterAreaCount(self.ChapterId)

    -- 遍历额外增加一点容错，防止UI有额外的Area节点没收集到
    for i = 1, areaCount + 10 do
        local areaUi = self["Area" .. i]

        if areaUi then
            if i <= areaCount then
                XUiHelper.RegisterClickEvent(nil, areaUi, function()
                    self:_OnAreaFocus(i)
                end)
                self._AreaUi[i] = areaUi
            else
                -- 超出的部分直接隐藏
                areaUi.gameObject:SetActiveEx(false)
            end
        else
            -- 连续索引命名，如果查不到则认为无后续节点
            break
        end
    end

    -- 读取自动聚焦阈值配置
    --todo 走配置
    self._AutoFocusThreshold = 50
end

function XUiMainLine2StageAreaCom:Refresh()
    -- 检查对应区域是否需要显示
    if XTool.IsTableEmpty(self._AreaUi) then
        return
    end
    
    local areaGroupCfg = self._Control.UiStageAreaControl:GetTableMainLine2StageAreaGroupCfgById(self.ChapterId)

    if areaGroupCfg then
        for i, v in pairs(self._AreaUi) do
            local id = areaGroupCfg.AreaIds[i]

            if XTool.IsNumberValidEx(id) then
                v.gameObject:SetActiveEx(self._Control.UiStageAreaControl:CheckAreaIsOpen(id))
            else
                v.gameObject:SetActiveEx(false)
            end
        end
    end
end

function XUiMainLine2StageAreaCom:_OnAreaFocus(index)
    if self.CurFocusAreaIndex == index then
        return
    end

    self.CurFocusAreaIndex = index

    local areaGroupCfg = self._Control.UiStageAreaControl:GetTableMainLine2StageAreaGroupCfgById(self.ChapterId)

    if areaGroupCfg then
        local id = areaGroupCfg.AreaIds[index]

        local areaCfg = self._Control.UiStageAreaControl:GetTableMainLine2StageAreaCfgById(id)

        --todo: 没有区分message
        if XTool.IsNumberValidEx(areaCfg.CenterNodeId) then
            -- 派送事件请求聚焦
            self._Control:DispatchEvent(self._Control.EventIds.FOCUS_STAGE_WITH_AREA_GROUP, areaCfg.CenterNodeId)
        end
    end
end

-- 获取指定分区的左右边界 X（内容坐标系，单位与 anchoredPosition 一致）
-- 返回 leftX, rightX
function XUiMainLine2StageAreaCom:_GetAreaBoundsX(areaIndex)
    local areaGroupCfg = self._Control.UiStageAreaControl:GetTableMainLine2StageAreaGroupCfgById(self.ChapterId)
    if not areaGroupCfg then return nil, nil end

    local areaId = areaGroupCfg.AreaIds[areaIndex]
    if not XTool.IsNumberValidEx(areaId) then return nil, nil end

    local areaCfg = self._Control.UiStageAreaControl:GetTableMainLine2StageAreaCfgById(areaId)
    if not areaCfg or XTool.IsTableEmpty(areaCfg.AreaStageIds) then return nil, nil end

    local leftX, rightX = math.huge, -math.huge
    for _, stageId in pairs(areaCfg.AreaStageIds) do
        local index = self.Parent:GetEntranceIndexByStageId(stageId)
        if index then
            local stageGo = self.Parent:GetStageGo(index)
            if stageGo then
                local x = stageGo.anchoredPosition.x
                if x < leftX then leftX = x end
                if x > rightX then rightX = x end
            end
        end
    end

    if leftX == math.huge then return nil, nil end
    return leftX, rightX
end

-- 根据当前视野中心 X 判断属于哪个分区
function XUiMainLine2StageAreaCom:_GetCurrentAreaIndex()
    local midX = -self.Parent.PanelStageContent.anchoredPosition.x + self.Parent.LocateOffsetX

    local areaGroupCfg = self._Control.UiStageAreaControl:GetTableMainLine2StageAreaGroupCfgById(self.ChapterId)
    if not areaGroupCfg then return 1 end

    local closestIndex = 1
    local closestDist = math.huge
    for i, _ in pairs(areaGroupCfg.AreaIds) do
        local lx, rx = self:_GetAreaBoundsX(i)
        if lx and rx then
            local centerX = (lx + rx) * 0.5
            local dist = math.abs(midX - centerX)
            if dist < closestDist then
                closestDist = dist
                closestIndex = i
            end
        end
    end
    return closestIndex
end

-- 记录 BeginDrag 时所在的分区 index
function XUiMainLine2StageAreaCom:RecordBeginDragAreaIndex()
    self._BeginDragAreaIndex = self:_GetCurrentAreaIndex()
end

-- 点击拦截：若点击的关卡不在当前聚焦分区，则执行聚焦跳转并返回 true（阻止打开详情）
-- 若在当前分区则返回 false（放行，走正常打开详情逻辑）
function XUiMainLine2StageAreaCom:TryInterceptStageClick(stageId)
    local areaIndex = self._Control.UiStageAreaControl:GetAreaIndexByStageId(self.ChapterId, stageId)
    if not areaIndex then
        return false
    end

    if areaIndex == self.CurFocusAreaIndex then
        return false
    end

    self:_OnAreaFocus(areaIndex)
    return true
end

-- 松手时检测是否需要自动聚焦到前方分区
-- dragDeltaX > 0：手指向右划（视野向 index 减小方向移动）
-- dragDeltaX < 0：手指向左划（视野向 index 增大方向移动）
function XUiMainLine2StageAreaCom:CheckAutoFocusOnEndDrag(dragDeltaX)
    if not XTool.IsNumberValidEx(self._AutoFocusThreshold) or self._AutoFocusThreshold <= 0 then
        return
    end

    local curIndex = self:_GetCurrentAreaIndex()
    local areaGroupCfg = self._Control.UiStageAreaControl:GetTableMainLine2StageAreaGroupCfgById(self.ChapterId)
    if not areaGroupCfg then return end

    local totalArea = XTool.GetTableCount(areaGroupCfg.AreaIds)

    -- 【跨区】拖拽起点和终点不在同一分区，无条件聚焦当前分区
    if self._BeginDragAreaIndex and self._BeginDragAreaIndex ~= curIndex then
        self:_OnAreaFocus(curIndex)
        return
    end

    -- 【同区 Case A】检测移动方向前方分区的边缘侵入量
    local nextIndex
    local checkEdge
    if dragDeltaX < 0 then
        nextIndex = curIndex + 1
        checkEdge = "left"
    else
        nextIndex = curIndex - 1
        checkEdge = "right"
    end

    if nextIndex < 1 or nextIndex > totalArea then return end
    if not self._Control.UiStageAreaControl:CheckAreaIsOpen(areaGroupCfg.AreaIds[nextIndex]) then return end

    local lx, rx = self:_GetAreaBoundsX(nextIndex)
    if not lx then return end

    local contentPosX = self.Parent.PanelStageContent.anchoredPosition.x
    local viewPortWidth = self.Parent.LocateOffsetX * 2
    local viewLeftX  = -contentPosX
    local viewRightX = viewLeftX + viewPortWidth

    local distance
    if checkEdge == "left" then
        -- 目标分区左边缘到视野右边缘的侵入量（lx < viewRightX 表示已进入视野）
        distance = viewRightX - lx
        if distance <= 0 then return end
    else
        -- 目标分区右边缘到视野左边缘的侵入量（rx > viewLeftX 表示已进入视野）
        distance = rx - viewLeftX
        if distance <= 0 then return end
    end

    if distance >= self._AutoFocusThreshold then
        self:_OnAreaFocus(nextIndex)
    end
end

return XUiMainLine2StageAreaCom