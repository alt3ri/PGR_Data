---@class XUiGridDlcRelinkExchangeWheelEmoji : XUiNode
---@field private _Control XDlcRelinkControl
---@field Parent XUiDlcRelinkPopupExchangeWheel
---@field Pointer XUguiPointerEventListener
local XUiGridDlcRelinkExchangeWheelEmoji = XClass(XUiNode, "XUiGridDlcRelinkExchangeWheelEmoji")

function XUiGridDlcRelinkExchangeWheelEmoji:OnStart()
    self.ImgBg.gameObject:SetActiveEx(false)
    self.ImgSelect.gameObject:SetActiveEx(false)
    self.PanelTag.gameObject:SetActiveEx(false)
    if self.ImgOnDrag then
        self.ImgOnDrag.gameObject:SetActiveEx(false)
    end
    if self.BtnDelete then
        self.BtnDelete:AddEventListener(handler(self, self.OnBtnDeleteClick))
    end

    self.DefaultLayer = self.Canvas.sortingOrder
    self.Pointer.OnDown = function(eventData) self:OnPointerDown(eventData) end
    self.Pointer.OnClick = function(eventData) self:OnPointerClick(eventData) end
    self.Pointer.OnPress = function(pressTime) self:OnPress(pressTime) end
    self.Pointer.OnUp = function(eventData) self:OnPointerUp(eventData) end
    self.Pointer.OnExit = function(eventData) self:OnPointerExit(eventData) end

    self.IsDragClone = false  -- 是否是拖拽出来的克隆
    self.IsWheelSlot = false  -- 是否是表情轮盘的槽位
    self.WheelIndex = nil -- 表情轮盘的槽位索引

    self.PressProgressTarget = self.ImgEmoji.transform -- 长按进度条的目标位置
end

function XUiGridDlcRelinkExchangeWheelEmoji:SetIsDragClone(isDragClone)
    self.IsDragClone = isDragClone
end

function XUiGridDlcRelinkExchangeWheelEmoji:GetIsDragClone()
    return self.IsDragClone
end

function XUiGridDlcRelinkExchangeWheelEmoji:SetIsWheelSlot(isWheelSlot)
    self.IsWheelSlot = isWheelSlot or false
end

function XUiGridDlcRelinkExchangeWheelEmoji:GetIsWheelSlot()
    return self.IsWheelSlot
end

function XUiGridDlcRelinkExchangeWheelEmoji:SetWheelIndex(wheelIndex)
    self.WheelIndex = wheelIndex
end

function XUiGridDlcRelinkExchangeWheelEmoji:GetWheelIndex()
    return self.WheelIndex
end

function XUiGridDlcRelinkExchangeWheelEmoji:GetEmojiId()
    return self.EmojiId
end

function XUiGridDlcRelinkExchangeWheelEmoji:Refresh(emojiId)
    self.Parent:OnGridBeforeRefresh(self)
    self.EmojiId = emojiId
    if not XTool.IsNumberValid(emojiId) then
        self:HideAll()
        return
    end

    local emojiType = self._Control:GetTextEmojiType(emojiId)
    self.PanelEmoji.gameObject:SetActiveEx(emojiType == XEnumConst.DlcRelink.ChatType.Emoji)
    self.PanelTalk.gameObject:SetActiveEx(emojiType == XEnumConst.DlcRelink.ChatType.Text)

    if emojiType == XEnumConst.DlcRelink.ChatType.Emoji then
        local icon = self._Control:GetTextEmojiIcon(emojiId)
        self.ImgEmoji:SetSprite(icon)
        self.TxtDescribe.text = self._Control:GetTextEmojiConnotationDesc(emojiId)
        self.PressProgressTarget = self.ImgEmoji.transform
    elseif emojiType == XEnumConst.DlcRelink.ChatType.Text then
        self.TxtTalk.text = self._Control:GetTextEmojiText(emojiId)
        self.PressProgressTarget = self.TxtTalk.transform
    end
end

-- 隐藏所有
function XUiGridDlcRelinkExchangeWheelEmoji:HideAll()
    self.PanelEmoji.gameObject:SetActiveEx(false)
    self.PanelTalk.gameObject:SetActiveEx(false)
    self.ImgSelect.gameObject:SetActiveEx(false)
    self.PanelTag.gameObject:SetActiveEx(false)
    if self.ImgOnDrag then
        self.ImgOnDrag.gameObject:SetActiveEx(false)
    end
end

-- 选择
function XUiGridDlcRelinkExchangeWheelEmoji:SetSelect(isSelect)
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
end

-- 使用中
function XUiGridDlcRelinkExchangeWheelEmoji:SetTag(isTag)
    self.PanelTag.gameObject:SetActiveEx(isTag)
end

-- 点击
function XUiGridDlcRelinkExchangeWheelEmoji:OnPointerClick(eventData)
    if self.IsDragClone then
        return
    end
    if self.IsWheelSlot then
        self.Parent:OnClickWheelEmoji(self)
    else
        self.Parent:OnClickListEmoji(self)
    end
end

-- 拖拽中显示
function XUiGridDlcRelinkExchangeWheelEmoji:SetOnDrag(isOnDrag)
    if self.ImgOnDrag then
        self.ImgOnDrag.gameObject:SetActiveEx(isOnDrag)
    end
end

-- 删除
function XUiGridDlcRelinkExchangeWheelEmoji:OnBtnDeleteClick()
    if self.IsDragClone or not self.IsWheelSlot then
        return
    end
    self.Parent:OnClickDeleteWheelEmoji(self)
end

-- 手指按下
function XUiGridDlcRelinkExchangeWheelEmoji:OnPointerDown(eventData)
    if self.IsDragClone then
        return
    end
    self.Parent:OnGridPointerDown(self)
end

-- 长按触发拖拽
function XUiGridDlcRelinkExchangeWheelEmoji:OnPress(pressTime)
    if self.IsDragClone then
        return
    end

    local emojiId = self:GetEmojiId()
    if not XTool.IsNumberValid(emojiId) then
        return
    end

    self.Parent:OnGridPress(self)
end

-- 手指抬起
function XUiGridDlcRelinkExchangeWheelEmoji:OnPointerUp(eventData)
    if self.IsDragClone then
        return
    end
    self.Parent:OnGridPointerUp(self)
end

-- 移出Grid范围
function XUiGridDlcRelinkExchangeWheelEmoji:OnPointerExit(eventData)
    if self.IsDragClone then
        return
    end
    self.Parent:OnGridPointerExit(self)
end

-- 设置 Canvas 覆盖排序
function XUiGridDlcRelinkExchangeWheelEmoji:SetOverrideSorting(isOverride)
    if not self.Canvas then
        return
    end
    self.Canvas.overrideSorting = isOverride
end

-- 设置 Canvas 层级
function XUiGridDlcRelinkExchangeWheelEmoji:SetLayerOrder(order)
    if not self.Canvas then
        return
    end
    self.Canvas.sortingOrder = order or self.DefaultLayer
end

-- 还原 Canvas 默认层级
function XUiGridDlcRelinkExchangeWheelEmoji:RestoreLayerOrder()
    if not self.Canvas then
        return
    end
    self.Canvas.sortingOrder = self.DefaultLayer
end

return XUiGridDlcRelinkExchangeWheelEmoji
