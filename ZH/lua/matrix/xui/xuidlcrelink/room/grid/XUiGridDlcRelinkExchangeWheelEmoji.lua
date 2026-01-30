---@class XUiGridDlcRelinkExchangeWheelEmoji : XUiNode
---@field private _Control XDlcRelinkControl
---@field Parent XUiDlcRelinkPopupExchangeWheel
---@field GoInput XGoInputHandler
local XUiGridDlcRelinkExchangeWheelEmoji = XClass(XUiNode, "XUiGridDlcRelinkExchangeWheelEmoji")

function XUiGridDlcRelinkExchangeWheelEmoji:OnStart()
    self.ImgBg.gameObject:SetActiveEx(false)
    self.ImgSelect.gameObject:SetActiveEx(false)
    self.PanelTag.gameObject:SetActiveEx(false)
    --self.BtnEmoji:AddEventListener(handler(self, self.OnBtnEmojiClick))
    if self.BtnDelete then
        self.BtnDelete:AddEventListener(handler(self, self.OnBtnDeleteClick))
    end

    self.DefaultLayer = self.Canvas.sortingOrder
    self.GoInput:AddPointerClickListener(function(eventData) self:OnPointerClick(eventData) end)
    self.GoInput:AddBeginDragListener(function(eventData) self:OnBeginDrag(eventData) end)
    self.GoInput:AddDragListener(function(eventData) self:OnDrag(eventData) end)
    self.GoInput:AddEndDragListener(function(eventData) self:OnEndDrag(eventData) end)

    self.IsDragClone = false  -- 是否是拖拽出来的克隆
    self.IsWheelSlot = false  -- 是否是表情轮盘的槽位
    self.WheelIndex = nil -- 表情轮盘的槽位索引
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
    self.EmojiId = emojiId
    if not XTool.IsNumberValid(emojiId) then
        self:HideAll()
        return
    end

    local type = self._Control:GetTextEmojiType(emojiId)
    self.PanelEmoji.gameObject:SetActiveEx(type == XEnumConst.DlcRelink.ChatType.Emoji)
    self.PanelTalk.gameObject:SetActiveEx(type == XEnumConst.DlcRelink.ChatType.Text)

    if type == XEnumConst.DlcRelink.ChatType.Emoji then
        local icon = self._Control:GetTextEmojiIcon(emojiId)
        self.ImgEmoji:SetSprite(icon)
        self.TxtDescribe.text = self._Control:GetTextEmojiConnotationDesc(emojiId)
    elseif type == XEnumConst.DlcRelink.ChatType.Text then
        self.TxtTalk.text = self._Control:GetTextEmojiText(emojiId)
    end
end

-- 隐藏所有
function XUiGridDlcRelinkExchangeWheelEmoji:HideAll()
    self.PanelEmoji.gameObject:SetActiveEx(false)
    self.PanelTalk.gameObject:SetActiveEx(false)
    self.ImgSelect.gameObject:SetActiveEx(false)
    self.PanelTag.gameObject:SetActiveEx(false)
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
function XUiGridDlcRelinkExchangeWheelEmoji:OnBtnEmojiClick()
    if self.IsDragClone then
        return
    end
    if self.IsWheelSlot then
        self.Parent:OnClickWheelEmoji(self)
    else
        self.Parent:OnClickListEmoji(self)
    end
end

-- 删除
function XUiGridDlcRelinkExchangeWheelEmoji:OnBtnDeleteClick()
    if self.IsDragClone or not self.IsWheelSlot then
        return
    end
    self.Parent:OnClickDeleteWheelEmoji(self)
end

function XUiGridDlcRelinkExchangeWheelEmoji:OnPointerClick(eventData)
    if self.IsDragClone then
        return
    end
    self:OnBtnEmojiClick()
end

function XUiGridDlcRelinkExchangeWheelEmoji:OnBeginDrag(eventData)
    if self.IsDragClone then
        return
    end
    self.Parent:StartDrag(self)
end

function XUiGridDlcRelinkExchangeWheelEmoji:OnDrag(eventData)
    if self.IsDragClone then
        return
    end
    self.Parent:OnDragMove(eventData)
end

function XUiGridDlcRelinkExchangeWheelEmoji:OnEndDrag(eventData)
    if self.IsDragClone then
        return
    end
    self.Parent:EndDrag(eventData)
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
