---@class XUiGridTheatre6PvpRole : XUiNode pvp角色头像
---@field _Control XTheatre6Control
local XUiGridTheatre6PvpRole = XClass(XUiNode, "XUiGridTheatre6PvpRole")

local XUiCommonDraggable = require("XUi/XUiCommon/XCommonDrag/XUiCommonDraggable")

function XUiGridTheatre6PvpRole:OnStart(callBack)
    self.CallBack = callBack
    self.BtnPVPRole:AddEventListener(handler(self, self.OnBtnPVPRoleClick))
    self.Select.gameObject:SetActiveEx(false)

    if self.HighLight then
        self.HighLight.gameObject:SetActiveEx(false)
    end
    if self.PanelDisabled then
        self.PanelDisabled.gameObject:SetActiveEx(false)
    end

    -- Canvas 默认层级
    if self.Canvas then
        self.DefaultLayer = self.Canvas.sortingOrder
    end
end

function XUiGridTheatre6PvpRole:OnDestroy()
    if self._Draggable then
        self._Draggable:Destroy()
        self._Draggable = nil
    end
end

---@param fileData Theatre6FileData|nil PVP存档数据
---@param isMist boolean 是否迷雾
function XUiGridTheatre6PvpRole:Refresh(fileData, isMist, index)
    self.FileData = fileData
    self.Index = index
    self.IsMist = isMist

    self.TxtIndex.text = index or ""
    if not fileData then
        self.PanelRole.gameObject:SetActiveEx(false)
        return
    end
    self.PanelRole.gameObject:SetActiveEx(true)

    if isMist then
        self.RImgHead:SetRawImageEx(self._Control:GetPvpClientConfigValue("MistHeadIcon"))
        self.ListTag.gameObject:SetActiveEx(false)
        self.TxtNum.gameObject:SetActiveEx(false)
        return
    end

    -- 角色头像
    local characterConfig = self._Control:GetCharacterConfig(fileData.CharacterId)
    local fashionConfig = self._Control:GetFashionConfig(characterConfig.FashionIds[1])
    self.RImgHead:SetRawImageEx(fashionConfig.Portrait)
    -- 分数
    self.TxtNum.gameObject:SetActiveEx(true)
    self.TxtNum.text = fileData.Score
    -- 标签
    self.ListTag.gameObject:SetActiveEx(true)
    local showTags = self._Control:GetSortFileDataBuildTags(fileData)
    XUiHelper.RefreshCustomizedList(self.ListTag, self.Tag.transform, #showTags, function(i, go)
        local grid = {}
        local cfg = self._Control:GetBuildTagConfig(showTags[i])
        XUiHelper.InitUiClass(grid, go)
        grid.RImgIcon:SetRawImageEx(cfg.Icon)
    end)
end

function XUiGridTheatre6PvpRole:SetSelect(isSelect)
    self.Select.gameObject:SetActiveEx(isSelect)
end

-- 显示/隐藏可放入光圈
function XUiGridTheatre6PvpRole:SetHighLight(isOn)
    if self.HighLight then
        self.HighLight.gameObject:SetActiveEx(isOn)
    end
end

function XUiGridTheatre6PvpRole:SetPanelDisabled(isDisabled)
    if self.PanelDisabled then
        self.PanelDisabled.gameObject:SetActiveEx(isDisabled)
    end
end

-- 显示/隐藏自身的角色显示（拖拽期间隐藏，使克隆体作为唯一可视对象）
function XUiGridTheatre6PvpRole:SetRoleVisible(isVisible)
    self.PanelRole.gameObject:SetActiveEx(isVisible)
end

-- 设置该存档战斗胜利/失败
function XUiGridTheatre6PvpRole:SetBattleResult(isSuccess)
    self.BtnPVPRole:SetButtonState(isSuccess and XUiButtonState.Normal or XUiButtonState.Disable)
end

-- 是否启用按钮
function XUiGridTheatre6PvpRole:SetBtnEnabled(isEnabled)
    self.BtnPVPRole.enabled = isEnabled
end

function XUiGridTheatre6PvpRole:OnBtnPVPRoleClick()
    if self.CallBack then
        self.CallBack(self)
    end
end

--region 拖拽相关
-- 为槽位声明内部互换拖拽源
function XUiGridTheatre6PvpRole:InitGridDraggable()
    self:SetBtnEnabled(false) -- 禁用按钮事件，避免与拖拽冲突（点击改由拖拽源 OnClick 派发）

    ---@type XUiCommonDraggable
    self._Draggable = XUiCommonDraggable.New(self.Transform,
        {
            Context = self.Parent._DragContext,
            Mode = XEnumConst.CommonDrag.TriggerMode.Direct,
            CanDrag = function() return self.FileData ~= nil end,
            GetPayload = function() return self.Index end,
            CloneFactory = function() return self.Parent:CreateDragClone(self.FileData) end,
            CloneRecycle = function(clone) if clone then clone:Close() end end,
            OnClick = function() self:OnBtnPVPRoleClick() end,
        })

    -- 拖拽开始隐藏源格子，克隆体作为唯一可视对象
    self._Draggable:SetOnDragBegin(function() self:SetRoleVisible(false) end)
    self._Draggable:SetOnDragEnd(function() self:SetRoleVisible(true) end)
end

-- 将本格子设置为拖拽克隆体样式：置顶、锚点居中、禁用射线检测
function XUiGridTheatre6PvpRole:SetupAsDragClone()
    self:SetOverrideSorting(true)
    self:SetLayerOrder(5)

    local center = CS.UnityEngine.Vector2(0.5, 0.5)
    self.Transform.anchorMin = center
    self.Transform.anchorMax = center
    self.Transform.pivot = center

    ---@type UnityEngine.CanvasGroup
    local canvasGroup = self.GameObject:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
    if XTool.UObjIsNil(canvasGroup) then
        canvasGroup = self.GameObject:AddComponent(typeof(CS.UnityEngine.CanvasGroup))
    end
    canvasGroup.blocksRaycasts = false
end

-- 设置 Canvas 覆盖排序
function XUiGridTheatre6PvpRole:SetOverrideSorting(isOverride)
    if not self.Canvas then
        return
    end
    self.Canvas.overrideSorting = isOverride
end

-- 设置 Canvas 层级（基于 OnStart 时记录的 DefaultLayer）
function XUiGridTheatre6PvpRole:SetLayerOrder(order)
    if not self.Canvas then
        return
    end
    local base = self.DefaultLayer or self.Canvas.sortingOrder or 0
    self.Canvas.sortingOrder = base + (order or 0)
end
--endregion

return XUiGridTheatre6PvpRole
