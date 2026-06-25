local XUiGridDyeMerge = require("XUi/XUiDyeMergeGame/UiDyeMergeGame/Grids/XUiGridDyeMerge")

--- 需求块
---@class XUiGridDyeMergeTarget: XUiGridDyeMerge
---@field protected _Control
---@field Parent
---@field RImgBg @显示目标颜色的底图，用于表示该方块需要合成什么颜色
---@field RImgFinish @混色成功时显示，需显示目标颜色
---@field RImgDye @用来表示混合颜色的结果，包括冲突的情况，需要根据相邻颜色读表设置
---@field ImgSelect|nil @选中时显示
---@field RImgObject @图标，关联颜色，需要注意未合成目标颜色时有单独的配置设置
---@field BtnMove|nil @点击按钮, 可移动的预制存在该引用，表示可点击选择并移动位置
local XUiGridDyeMergeTarget = XClass(XUiGridDyeMerge, "XUiGridDyeMergeTarget")

function XUiGridDyeMergeTarget:OnStart()
    if self.BtnMove then
        self.BtnMove:AddEventListener(handler(self, self._OnBtnMoveClick))
    end

    -- 预分配排序 entry 槽位和比较器，避免每次 Refresh 创建临时表
    self._SortedColors = {}
    self._SortEntryPool = {
        { adjDir = 0, colorId = 0 },
        { adjDir = 0, colorId = 0 },
        { adjDir = 0, colorId = 0 },
        { adjDir = 0, colorId = 0 },
    }
    self._SortComparator = function(a, b) return a.colorId < b.colorId end
end

---@overload
function XUiGridDyeMergeTarget:Refresh(uid)
    self.Uid = uid
    local gc = self._Control.GamingControl
    local block = gc.BlocksControl:GetBlockByUid(uid)
    if not block then return end
    local blockCfg = gc:GetTableDyeMergeBlockById(block:GetId())
    if not blockCfg then return end

    local targetColor = blockCfg.Color
    local isAnyColorTarget = targetColor == 0
    local targetColorCfg = not isAnyColorTarget and gc:GetTableDyeMergeBlocksConfig(targetColor) or nil

    -- RImgBg: 显示目标颜色底图（任意色需求块不设置）
    if self.RImgBg and targetColorCfg and not isAnyColorTarget then
        self.RImgBg:SetRawImage(targetColorCfg.IconTarget)
    end

    -- 需求块的侧面颜色和基础块一样处理，共用字段
    if self.RImgDiban then
        self.RImgDiban:SetRawImage(targetColorCfg.IconNormalBig)
    end

    local receivedColor = block:GetReceivedColor()
    local dirColors = block:GetReceivedDirColors()
    local sorted = self:_CollectAndSortDirColors(dirColors)
    local count = #sorted

    local isSatisfied = false
    if isAnyColorTarget then
        isSatisfied = XTool.IsNumberValidEx(receivedColor)
    else
        isSatisfied = receivedColor and receivedColor == targetColor
    end

    if isSatisfied then
        -- 满足目标：显示通关态
        local successCfg = isAnyColorTarget and gc:GetTableDyeMergeBlocksConfig(receivedColor) or targetColorCfg
        self:_ShowSuccessState(successCfg)
    elseif count == 0 then
        -- 无相邻颜色
        self:_SetAllHidden()
    elseif count == 1 then
        -- 仅 1 色且未满足目标
        self:_SetFinishVisible(false)
        self:_SetObjectVisible(false)
        self:_ShowSingleColorDye(sorted[1], gc)
    else
        -- 2+ 色且未满足目标：先按 colorId 去重（sorted 已升序，相同颜色必相邻）
        local uniqueCount = 1
        for i = 2, count do
            if sorted[i].colorId ~= sorted[i - 1].colorId then
                uniqueCount = uniqueCount + 1
            end
        end

        self:_SetFinishVisible(false)
        if uniqueCount == 1 then
            -- 多方向同色，视为单色显示
            self:_SetObjectVisible(false)
            self:_ShowSingleColorDye(sorted[1], gc)
        elseif uniqueCount == 2 then
            local mergeColor = self:_TryPairMerge(sorted, gc)
            if mergeColor then
                -- 恰好 2 色种且能合成：显示合成色的 IconMix 图片
                self:_ShowSingleDyeImage(gc:GetTableDyeMergeColorMix(mergeColor), false)
            else
                -- 恰好 2 色种但不能合成：显示 mix 失败
                self:_ShowSingleDyeImage(gc:GetTableDyeMergeColorMix(sorted[1].colorId), true)
            end
            self:_SetObjectVisible(false)
        else
            -- 色种 >2：显示 mix 失败
            self:_ShowSingleDyeImage(gc:GetTableDyeMergeColorMix(sorted[1].colorId), true)
            self:_SetObjectVisible(false)
        end
    end

    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(false)
    end
end

--region 数据处理

--- 收集 dirColors 并按 colorId 升序排列，复用内部列表和 entry 对象
function XUiGridDyeMergeTarget:_CollectAndSortDirColors(dirColors)
    local sorted = self._SortedColors
    for i = #sorted, 1, -1 do sorted[i] = nil end

    if dirColors then
        local idx = 0
        for adjDir, colorId in pairs(dirColors) do
            idx = idx + 1
            local entry = self._SortEntryPool[idx]
            entry.adjDir = adjDir
            entry.colorId = colorId
            sorted[idx] = entry
        end
        table.sort(sorted, self._SortComparator)
    end
    return sorted
end

--- 按 colorId 升序尝试两两合成，返回第一个成功的合成颜色
---@return number|nil mergeColor
function XUiGridDyeMergeTarget:_TryPairMerge(sorted, gc)
    for i = 1, #sorted - 1 do
        for j = i + 1, #sorted do
            local result = gc:TryMixTwoColors(sorted[i].colorId, sorted[j].colorId)
            if result then
                return result
            end
        end
    end
    return nil
end

--endregion

--region 显示状态

--- 通关态：显示 RImgFinish + RImgObject，隐藏 RImgDye
function XUiGridDyeMergeTarget:_ShowSuccessState(colorCfg)
    self:_HideAllDyeImages()
    self:_SetFinishVisible(true, colorCfg and colorCfg.IconActive)
    self:_SetObjectVisible(true, colorCfg and colorCfg.IconTop)
end

--- 单色：显示 IconMix（不控制方向）
function XUiGridDyeMergeTarget:_ShowSingleColorDye(entry, gc)
    local mixCfg = gc:GetTableDyeMergeColorMix(entry.colorId)
    self:_ShowSingleDyeImage(mixCfg, false)
end

--- 显示单张 RImgDye 图片（不控制方向），隐藏其余
---@param mixCfg table|nil ColorMix 配置
---@param isMixFiled boolean true 时读 IconMixFiled，false 时读 IconMix
function XUiGridDyeMergeTarget:_ShowSingleDyeImage(mixCfg, isMixFiled)
    local img = self:_GetDyeImage()
    if img then
        local icon = mixCfg and (isMixFiled and mixCfg.IconMixFiled or mixCfg.IconMix)
        if icon then
            img.gameObject:SetActiveEx(true)
            img:SetRawImage(icon)
        else
            img.gameObject:SetActiveEx(false)
        end
    end
end

--endregion

--region RImgDye 实例管理

function XUiGridDyeMergeTarget:_GetDyeImage()
    return self.RImgDye
end

function XUiGridDyeMergeTarget:_HideAllDyeImages()
    self.RImgDye.gameObject:SetActiveEx(false)
end

--endregion

--region 节点控制

function XUiGridDyeMergeTarget:_SetAllHidden()
    self:_HideAllDyeImages()
    self:_SetFinishVisible(false)
    self:_SetObjectVisible(false)
end

function XUiGridDyeMergeTarget:_SetFinishVisible(visible, icon)
    if self.RImgFinish then
        self.RImgFinish.gameObject:SetActiveEx(visible)
        if visible and icon then
            self.RImgFinish:SetRawImage(icon)
        end
    end
end

function XUiGridDyeMergeTarget:_SetObjectVisible(visible, icon)
    if self.RImgObject then
        self.RImgObject.gameObject:SetActiveEx(visible)
        if visible and icon then
            self.RImgObject:SetRawImage(icon)
        end
    end
end

--endregion

function XUiGridDyeMergeTarget:_OnBtnMoveClick()
    if self._SendGridClickSignal then
        self._SendGridClickSignal(self.Uid)
    end
end

return XUiGridDyeMergeTarget
