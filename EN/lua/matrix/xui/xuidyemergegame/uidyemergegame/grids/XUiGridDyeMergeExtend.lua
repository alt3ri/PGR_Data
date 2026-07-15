local XUiGridDyeMerge = require("XUi/XUiDyeMergeGame/UiDyeMergeGame/Grids/XUiGridDyeMerge")

--- 延伸块（切片拼接模式）
--- 中心格由 grid 本身表示，延伸格由从池中获取的独立切片 GO 表示
--- 切片管理模式对标 XUiGridDyeMergeTurnable 的射线管理
---@class XUiGridDyeMergeExtend: XUiGridDyeMerge
---@field protected _Control
---@field Parent
---@field RImgBg1 @中心格图片（length=1 时的显示，现在始终用于中心格）
---@field RImgObject @图标
---@field BtnExtend @点击变化延伸长度的按钮
local XUiGridDyeMergeExtend = XClass(XUiGridDyeMerge, "XUiGridDyeMergeExtend")

function XUiGridDyeMergeExtend:OnStart()
    if self.BtnExtend then
        self.BtnExtend:AddEventListener(handler(self, self._OnBtnExtendClick))
    end
    self._SliceNodes = {}
end

---@overload
function XUiGridDyeMergeExtend:Refresh(uid)
    self.Uid = uid
    local gc = self._Control.GamingControl
    local block = gc.BlocksControl:GetBlockByUid(uid)
    if not block then return end
    local blockCfg = gc:GetTableDyeMergeBlockById(block:GetId())
    if not blockCfg then return end
    local colorCfg = gc:GetTableDyeMergeBlocksConfig(blockCfg.Color)
    if not colorCfg then return end

    local curLength = block:GetVariableLength()
    local extendCount = (curLength - 1) / 2
    local isVertical = gc.BlocksControl:IsVerticalExtend(uid)
    local dirScaleX = isVertical and -1 or 1
    local extendIcons = colorCfg.ExtendIcons

    -- 中心格：始终显示 length=1 的图标
    -- 竖直方向时将 localScale.x 设为 -1 以翻转显示方向
    if self.RImgBg1 then
        self.RImgBg1.gameObject:SetActiveEx(true)
        if extendIcons and extendIcons[1] then
            self.RImgBg1:SetRawImage(extendIcons[1])
        end
        local _, scaleY, scaleZ = self.RImgBg1.transform:GetLocalScale()
        self.RImgBg1.transform:SetLocalScale(dirScaleX, scaleY, scaleZ)
    end

    if self.RImgObject and colorCfg.IconSupprtTop then
        self.RImgObject.gameObject:SetActiveEx(true)
        self.RImgObject:SetRawImage(colorCfg.IconSupprtTop)
    end

    if self.RImgObjectEnd then
        self.RImgObjectEnd.gameObject:SetActiveEx(false)
    end

    -- 延伸切片：按 extendCount 管理
    self:_RefreshSlices(uid, block, extendCount, extendIcons, isVertical, dirScaleX)
end

--- 刷新延伸切片：增删切片 GO 并定位到对应格子
function XUiGridDyeMergeExtend:_RefreshSlices(uid, block, extendCount, extendIcons, isVertical, dirScaleX)
    local gc = self._Control.GamingControl
    local cx, cy = block:GetX(), block:GetY()

    -- 获取 Board 的坐标参数和 DepthSorter
    local board = self.Parent.Parent
    local halfW = board._HalfW
    local halfH = board._HalfH
    local depthSorter = board._DepthSorter

    local sliceIdx = 0
    for i = 1, extendCount do
        -- 两侧对称延伸：直接展开坐标，避免循环内创建临时表
        local p1x, p1y, p2x, p2y
        if isVertical then
            p1x, p1y = cx, cy - i
            p2x, p2y = cx, cy + i
        else
            p1x, p1y = cx - i, cy
            p2x, p2y = cx + i, cy
        end

        -- 处理两侧切片
        for side = 1, 2 do
            local px, py = p1x, p1y
            if side == 2 then px, py = p2x, p2y end

            sliceIdx = sliceIdx + 1
            local slice = self:_GetOrCreateSlice(sliceIdx)
            if slice then
                slice:Open()
                slice.GameObject.name = "GridExtendPart(" .. tostring(py) .. ', ' .. tostring(px) .. ')'
                -- 定位到对应格子的等距坐标（表现层允许越界）
                local sx, sy = gc:Vec2ToIsoPos(px, py, halfW, halfH)
                slice.Transform:SetLocalPosition(sx, sy, 0)

                -- 设置切片图标（读取长度为3时的图片）
                -- 竖直方向时将 localScale.x 设为 -1 以翻转显示方向
                if slice.RImgBg then
                    slice.RImgBg.gameObject:SetActiveEx(true)
                    if extendIcons and extendIcons[2] then
                        slice.RImgBg:SetRawImage(extendIcons[2])
                    end
                    local _, scaleY, scaleZ = slice.RImgBg.transform:GetLocalScale()
                    slice.RImgBg.transform:SetLocalScale(dirScaleX, scaleY, scaleZ)
                end

                -- 注册/更新深度排序
                local depthKey = px + py
                if depthSorter then
                    depthSorter:AddOrUpdate(slice.Transform, depthKey, 1)
                end
            end
        end
    end

    -- 回收多余切片
    self:_ReturnSlicesFrom(sliceIdx + 1)

    -- 统一排序
    if depthSorter then
        depthSorter:Sort()
    end
end

--- 从池中获取第 index 个切片，不足时从池中新取
function XUiGridDyeMergeExtend:_GetOrCreateSlice(index)
    if self._SliceNodes[index] then
        return self._SliceNodes[index]
    end

    local slice = self.Parent:GetExtendSlice("GridExtendPart")
    if not slice then return nil end
    self._SliceNodes[index] = slice
    return slice
end

--- 回收从 fromIndex 开始的所有切片到池
function XUiGridDyeMergeExtend:_ReturnSlicesFrom(fromIndex)
    local board = self.Parent.Parent
    local depthSorter = board and board._DepthSorter

    for i = fromIndex, #self._SliceNodes do
        if self._SliceNodes[i] then
            if depthSorter then
                depthSorter:Remove(self._SliceNodes[i].Transform)
            end
            self.Parent:ReturnExtendSlice(self._SliceNodes[i])
            self._SliceNodes[i] = nil
        end
    end
end

--- 方块被回收到池时归还所有切片
function XUiGridDyeMergeExtend:OnDisable()
    self:_ReturnSlicesFrom(1)
end

--- 通关后将供色图标切换回 IconTop
function XUiGridDyeMergeExtend:RefreshOnStagePass(uid)
    local gc = self._Control.GamingControl
    local block = gc.BlocksControl:GetBlockByUid(uid)
    if not block then return end
    local blockCfg = gc:GetTableDyeMergeBlockById(block:GetId())
    if not blockCfg then return end
    local colorCfg = gc:GetTableDyeMergeBlocksConfig(blockCfg.Color)
    if not colorCfg then return end

    if self.RImgObjectEnd and colorCfg.IconTop then
        self.RImgObjectEnd.gameObject:SetActiveEx(true)
        self.RImgObjectEnd:SetRawImage(colorCfg.IconTop)
    end

    if self.RImgObject then
        self.RImgObject.gameObject:SetActiveEx(false)
    end
end

function XUiGridDyeMergeExtend:_OnBtnExtendClick()
    if self._SendGridClickSignal then
        self._SendGridClickSignal(self.Uid)
    end
end

return XUiGridDyeMergeExtend
