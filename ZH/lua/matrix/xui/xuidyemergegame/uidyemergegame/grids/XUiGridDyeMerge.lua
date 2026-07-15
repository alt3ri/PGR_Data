--- 方块基类
---@class XUiGridDyeMerge: XUiNode
---@field protected _Control XDyeMergeGameControl
---@field Parent
--- 以下四个节点用作射线端点
---@field Pos1 @右上节点
---@field Pos2 @左上节点
---@field Pos3 @左下节点
---@field Pos4 @右下节点
local XUiGridDyeMerge = XClass(XUiNode, "XUiGridDyeMerge")

local XUiDyeMergeMainSpine = require("XUi/XUiDyeMergeGame/UiDyeMergeGame/Com/XUiDyeMergeMainSpine")

local SORTING_OFFSET = 5

function XUiGridDyeMerge:OnStart()
    self.RImgObjectSpine = XUiDyeMergeMainSpine.New(self.GameObject)
end

--- 设置样式名称。同一种格子类型可能有不同的UI样式，归类到不同的对象池管理
function XUiGridDyeMerge:SetPrefabStyleName(styleName)
   self.StyleName = styleName 
end

function XUiGridDyeMerge:GetStyleName()
    return self.StyleName
end

--- 设置信号发送器（由 Board 在初始化时注入）
function XUiGridDyeMerge:SetGridClickSignalSender(sender)
    self._SendGridClickSignal = sender
end

--- 初始化时记录 Root 节点原始 Y 值（需判空，不是所有样式都有 Root）
function XUiGridDyeMerge:InitRootOriginY()
    if self.Root then
        local _, y, _ = self.Root:GetLocalPosition()
        self._RootOriginY = y
    end
    self:_InitSortingNodes()
end

--- 设置 Root 节点的选中偏移（覆盖式写入，非叠加）
function XUiGridDyeMerge:SetSelectOffset(isOffset)
    if not self.Root or self._RootOriginY == nil then
        return
    end

    local offsetY = isOffset and XMVCA.XDyeMergeGame:GetClientDyeMergeNumberByKey("BlockSelectOffsetY") or 0
    local x, _, z = self.Root:GetLocalPosition()
    self.Root:SetLocalPosition(x, self._RootOriginY + offsetY, z)

    if isOffset then
        self:_LiftSorting()
    else
        self:_RestoreSorting()
    end
end

--- 子类重写
function XUiGridDyeMerge:Refresh(uid)

end

--- 子类重写
function XUiGridDyeMerge:RefreshOnStagePass(uid)

end

--- 播放方块骨骼动画：初始化阶段直接 Loop，运行时先 Enable 再 Loop
function XUiGridDyeMerge:_PlayObjectSpine(iconTop)
    if not self.RImgObjectSpine or not iconTop then return end
    if self._Control.GamingControl:IsInitPhase() then
        self.RImgObjectSpine:PlaySpineAnimation(iconTop .. "Loop")
    else
        self.RImgObjectSpine:PlaySpineAnimation(iconTop .. "Enable", iconTop .. "Loop")
    end
end

--- 清空骨骼动画状态（切换到 Empty），用于节点隐藏或回收时避免残留画面
function XUiGridDyeMerge:_ClearObjectSpine()
    if self.RImgObjectSpine then
        self.RImgObjectSpine:PlaySpineAnimation("Empty")
    end
end

--- 设置正常态花节点的可见性与图标
---@param visible boolean
---@param icon string|nil
function XUiGridDyeMerge:SetFlowerVisible(visible, icon)
    if not self.RImgObject then return end
    self.RImgObject.gameObject:SetActiveEx(visible)
    if visible and icon then
        self.RImgObject:SetRawImage(icon)
    end
end

--- 设置合成完成标记的可见性与图标（基类空实现，Target 重写）
---@param visible boolean
---@param icon string|nil
function XUiGridDyeMerge:SetCompletionBadgeVisible(visible, icon)
end

--- 切换到正常展示态：清骨骼（Empty 隐藏花动画） + 显示静态图标 + 隐藏完成标记
---@param flowerIcon string|nil
function XUiGridDyeMerge:EnterNormalDisplay(flowerIcon)
    self:_ClearObjectSpine()
    self:SetFlowerVisible(true, flowerIcon)
    self:SetCompletionBadgeVisible(false)
end

--- 切换到通关态：播放骨骼动画 + 隐藏花
---@param colorCfg table
function XUiGridDyeMerge:EnterPassDisplay(colorCfg)
    self:_ClearObjectSpine()
    if colorCfg and colorCfg.IconTop then
        self:_PlayObjectSpine(colorCfg.IconTop)
    end
    self:SetFlowerVisible(false)
end

--- 切换到无花态：清骨骼 + 隐藏花
function XUiGridDyeMerge:EnterEmptyDisplay()
    self:_ClearObjectSpine()
    self:SetFlowerVisible(false)
end

--- 回收到对象池前调用，重置与逻辑层直接相关的数据
--- 子类按需重写，须调用父类实现
function XUiGridDyeMerge:OnRecycle()
    self:_RestoreSorting()
    self:_ClearObjectSpine()
    self.Uid = nil
    self._SendGridClickSignal = nil
end

--- 设置选中标记节点的可见性，子类可重写
--- 对无 ImgSelect 节点的 Grid 安全降级（无操作）
---@param isVisible boolean
function XUiGridDyeMerge:SetSelectVisible(isVisible)
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(isVisible)
    end
end

--- 根据索引获取射线端点定位节点（1~4 对应 Pos1~Pos4），可为 nil
---@param posIndex number 1=右上 2=左上 3=左下 4=右下
---@return userdata|nil
function XUiGridDyeMerge:GetPosNode(posIndex)
    local map = self._PosNodeMap
    if not map then
        map = { [1] = self.Pos1, [2] = self.Pos2, [3] = self.Pos3, [4] = self.Pos4 }
        self._PosNodeMap = map
    end
    return map[posIndex]
end

--region Sorting 层级管理

--- 扫描 Canvas{N} / Effect{N} 节点，记录初始 sortingOrder，关闭 overrideSorting
function XUiGridDyeMerge:_InitSortingNodes()
    if self._SortingNodesInited then
        return
    end
    self._SortingNodesInited = true
    self._IsSortingLifted = false

    local canvasList = {}
    for i = 1, 99 do
        local canvas = self["Canvas" .. i]
        if not canvas then
            break
        end
        canvasList[#canvasList + 1] = {
            node = canvas,
            originOrder = canvas.sortingOrder,
            originOverride = canvas.overrideSorting,
        }
    end
    self._SortingCanvasList = canvasList

    local effectList = {}
    for i = 1, 99 do
        local effect = self["Effect" .. i]
        if not effect then
            break
        end
        local renderer = effect:GetComponent("ParticleSystemRenderer")
        if renderer then
            effectList[#effectList + 1] = {
                renderer = renderer,
            }
        end
    end
    self._SortingEffectList = effectList
    self._EffectOrdersInited = false
end

--- 抬起：启用 overrideSorting 并提升 sortingOrder
function XUiGridDyeMerge:_LiftSorting()
    if not self._SortingNodesInited then
        return
    end
    if self._IsSortingLifted then
        return
    end
    self._IsSortingLifted = true

    local canvasList = self._SortingCanvasList
    for i = 1, #canvasList do
        local entry = canvasList[i]
        entry.node.overrideSorting = true
        entry.node.sortingOrder = entry.originOrder + SORTING_OFFSET
    end

    local effectList = self._SortingEffectList
    if not self._EffectOrdersInited then
        self._EffectOrdersInited = true
        for i = 1, #effectList do
            effectList[i].originOrder = effectList[i].renderer.sortingOrder
        end
    end
    for i = 1, #effectList do
        local entry = effectList[i]
        entry.renderer.sortingOrder = entry.originOrder + SORTING_OFFSET
    end
end

--- 放下/回收：关闭 overrideSorting，恢复初始 sortingOrder
function XUiGridDyeMerge:_RestoreSorting()
    if not self._SortingNodesInited then
        return
    end
    if not self._IsSortingLifted then
        return
    end
    self._IsSortingLifted = false

    local canvasList = self._SortingCanvasList
    for i = 1, #canvasList do
        local entry = canvasList[i]
        entry.node.overrideSorting = entry.originOverride
        entry.node.sortingOrder = entry.originOrder
    end

    local effectList = self._SortingEffectList
    for i = 1, #effectList do
        local entry = effectList[i]
        entry.renderer.sortingOrder = entry.originOrder
    end
end

--endregion

return XUiGridDyeMerge