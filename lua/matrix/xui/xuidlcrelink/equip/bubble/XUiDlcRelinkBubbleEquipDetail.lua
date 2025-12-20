local XUiPanelDlcRelinkEquipDetail = require("XUi/XUiDlcRelink/Equip/Panel/XUiPanelDlcRelinkEquipDetail")
---@class XUiDlcRelinkBubbleEquipDetail : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiDlcRelinkBubbleEquipDetail = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkBubbleEquipDetail")

local CSVector2 = CS.UnityEngine.Vector2
local CSVector3 = CS.UnityEngine.Vector3

function XUiDlcRelinkBubbleEquipDetail:OnAwake()
    self:RegisterUiEvents()
    -- 偏移值
    self.Offset = CSVector2(5, 0)
end

---@param targetTransform UnityEngine.RectTransform
---@param equipUid number 装备Uid
---@param targetTransform UnityEngine.RectTransform 目标节点
---@param callBack function 关闭回调
---@param extraData { SlotIndex:number, MainEquipUid:number, IsNotSelf:boolean } 额外数据
function XUiDlcRelinkBubbleEquipDetail:OnStart(equipUid, targetTransform, callBack, extraData)
    self.EquipUid = equipUid
    self.TargetTransform = targetTransform
    self.CallBack = callBack
    self.SlotIndex = extraData and extraData.SlotIndex or 0
    self.MainEquipUid = extraData and extraData.MainEquipUid or 0
    self.IsNotSelf = extraData and extraData.IsNotSelf or false

    self:RefreshEquipDetail()
    self:RefreshPanelSkill()

    -- 设置锚点与枢轴并进行布局
    self:SetAnchorAndPivot()

    -- 以SafeAreaContentPane节点为根节点进行位置计算
    self.Root = self.EquipDetailNode.Transform.parent
end

function XUiDlcRelinkBubbleEquipDetail:OnEnable()
    if self.CanvasGroupDetail then
        self.CanvasGroupDetail.alpha = 0
    end
    if self.CanvasGroupSkill then
        self.CanvasGroupSkill.alpha = 0
    end

    --异形屏适配需要
    XScheduleManager.ScheduleOnce(function()
        self:LayoutEquipDetailNode()
        self:LayoutPanelSkill()

        if self.CanvasGroupDetail then
            self.CanvasGroupDetail.alpha = 1
        end
        if self.CanvasGroupSkill then
            self.CanvasGroupSkill.alpha = 1
        end
    end, 1)
end

function XUiDlcRelinkBubbleEquipDetail:SetAnchorAndPivot()
    -- 统一采用中心锚点 + 左下枢轴，便于以左下角作为定位参考
    self.EquipDetailNode.Transform.anchorMin = CSVector2(0.5, 0.5)
    self.EquipDetailNode.Transform.anchorMax = CSVector2(0.5, 0.5)
    self.EquipDetailNode.Transform.pivot = CSVector2(0, 0)

    self.PanelSkill.transform.anchorMin = CSVector2(0.5, 0.5)
    self.PanelSkill.transform.anchorMax = CSVector2(0.5, 0.5)
    self.PanelSkill.transform.pivot = CSVector2(0, 0)
end

-- 计算 target 在本 UI 根节点坐标空间中的边界（左、右、上、下）
function XUiDlcRelinkBubbleEquipDetail:GetBoundsInRoot(target)
    if not target or not self.Root then
        return 0, 0, 0, 0
    end
    -- 单节点矩形：基于 Rect + Pivot 计算四角，再转换到 root 坐标
    local root = self.Root
    local rect = target.rect
    local pivot = target.pivot
    local w, h = rect.width, rect.height
    local x0 = -pivot.x * w
    local y0 = -pivot.y * h

    -- 以首点初始化 min/max
    local p = root:InverseTransformPoint(target:TransformPoint(CSVector3(x0, y0, 0)))
    local minX, maxX = p.x, p.x
    local minY, maxY = p.y, p.y

    -- 其余三点迭代更新
    p = root:InverseTransformPoint(target:TransformPoint(CSVector3(x0, y0 + h, 0)))
    if p.x < minX then minX = p.x end
    if p.x > maxX then maxX = p.x end
    if p.y < minY then minY = p.y end
    if p.y > maxY then maxY = p.y end

    p = root:InverseTransformPoint(target:TransformPoint(CSVector3(x0 + w, y0 + h, 0)))
    if p.x < minX then minX = p.x end
    if p.x > maxX then maxX = p.x end
    if p.y < minY then minY = p.y end
    if p.y > maxY then maxY = p.y end

    p = root:InverseTransformPoint(target:TransformPoint(CSVector3(x0 + w, y0, 0)))
    if p.x < minX then minX = p.x end
    if p.x > maxX then maxX = p.x end
    if p.y < minY then minY = p.y end
    if p.y > maxY then maxY = p.y end

    local left, right, top, bottom = minX, maxX, maxY, minY
    return left, right, top, bottom
end

-- 获取根画布（本 UI 根 RectTransform）的边界（最小X、最大X、最大Y、最小Y）
function XUiDlcRelinkBubbleEquipDetail:GetRootLimits()
    local rect = self.Root and self.Root.rect
    if not rect then
        return -10000, 10000, 10000, -10000
    end
    local halfW = rect.width * 0.5
    local halfH = rect.height * 0.5
    local minX = -halfW
    local maxX = halfW
    local maxY = halfH
    local minY = -halfH
    return minX, maxX, maxY, minY
end

-- 计算并设置 EquipDetailNode 的位置
function XUiDlcRelinkBubbleEquipDetail:LayoutEquipDetailNode()
    local nodeRt = self.EquipDetailNode.Transform
    local nodeRect = nodeRt.rect
    local nodeW, nodeH = nodeRect.width, nodeRect.height

    local minX, maxX, maxY, minY = self:GetRootLimits()
    local tLeft, tRight, tTop, tBottom = self:GetBoundsInRoot(self.TargetTransform)

    -- 水平方向：默认放在目标右侧；若越界则放在目标左侧
    local x = tRight + self.Offset.x
    if x + nodeW > maxX then
        x = tLeft - nodeW - self.Offset.x
        if x < minX then
            x = math.max(minX, math.min(x, maxX - nodeW))
        end
    end

    -- 垂直方向：默认“顶部对齐”；若底部越界则“底部对齐”
    local y = tTop - nodeH - self.Offset.y -- 顶部对齐：node 顶 = target 顶
    if y < minY then
        y = tBottom + self.Offset.y -- 底部对齐：node 底 = target 底
        -- 若顶部也越界则做边界钳制
        if y + nodeH > maxY then
            y = math.max(minY, math.min(y, maxY - nodeH))
        end
    end

    nodeRt.anchoredPosition = CSVector2(x, y)
end

-- 计算并设置 PanelSkill 的位置（以 EquipDetailNode 为目标）
function XUiDlcRelinkBubbleEquipDetail:LayoutPanelSkill()
    local skillRt = self.PanelSkill.transform
    local skillRect = skillRt.rect
    local sW, sH = skillRect.width, skillRect.height

    local minX, maxX, maxY, minY = self:GetRootLimits()
    local tLeft, tRight, tTop, tBottom = self:GetBoundsInRoot(self.EquipDetailNode.Transform)

    -- 水平方向：默认放在 EquipDetailNode 右侧；若越界则放在左侧
    local x = tRight + self.Offset.x
    if x + sW > maxX then
        x = tLeft - sW - self.Offset.x
        if x < minX then
            x = math.max(minX, math.min(x, maxX - sW))
        end
    end

    -- 垂直方向：默认“顶部对齐”；若底部越界则“底部对齐”
    local y = tTop - sH - self.Offset.y
    if y < minY then
        y = tBottom + self.Offset.y
        if y + sH > maxY then
            y = math.max(minY, math.min(y, maxY - sH))
        end
    end

    skillRt.anchoredPosition = CSVector2(x, y)
end

function XUiDlcRelinkBubbleEquipDetail:CheckExtendSlotAndMainSlotWearEquip()
    local isExtendSlot = self._Control:CheckIsExpandSlotIndex(self.SlotIndex)
    local isMainSlotWearEquip = XTool.IsNumberValid(self.MainEquipUid)
    return isExtendSlot and isMainSlotWearEquip
end

function XUiDlcRelinkBubbleEquipDetail:RefreshEquipDetail()
    if not self.EquipDetailNode then
        ---@type XUiPanelDlcRelinkEquipDetail
        self.EquipDetailNode = XUiPanelDlcRelinkEquipDetail.New(self.PanelDetail, self, self.IsNotSelf)
    end
    self.EquipDetailNode:Open()
    self.EquipDetailNode:Refresh(self.EquipUid)
end

function XUiDlcRelinkBubbleEquipDetail:RefreshPanelSkill()
    local templateId = self._Control:GetEquipTemplateIdByEquipUid(self.EquipUid, self.IsNotSelf)
    local equipType = self._Control:GetEquipType(templateId)

    local isMainEquip = equipType == XEnumConst.DlcRelink.EquipType.Main
    self.PanelSkill.gameObject:SetActiveEx(isMainEquip)
    if not isMainEquip then
        return
    end

    local mainSkillAttr = self._Control:GetEquipMainFactorByUid(self.EquipUid, true, self.IsNotSelf)
    if not mainSkillAttr then
        return
    end

    self.TxtName.text = self._Control:GetEquipSkillFactorName(mainSkillAttr.FactorId)
    self.TxtDesc.text = self._Control:GetEquipSkillFactorDescription(mainSkillAttr.FactorId)
end

function XUiDlcRelinkBubbleEquipDetail:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end

function XUiDlcRelinkBubbleEquipDetail:OnBtnCloseClick()
    self:Close()
    if self.CallBack then
        self.CallBack()
    end
end

return XUiDlcRelinkBubbleEquipDetail
