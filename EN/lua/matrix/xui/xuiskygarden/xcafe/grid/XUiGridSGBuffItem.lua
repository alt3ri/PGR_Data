---@class XUiGridSGBuffItem : XUiNode
---@field _Control XSkyGardenCafeControl
local XUiGridSGBuffItem = XClass(XUiNode, "XUiGridSGBuffItem")

function XUiGridSGBuffItem:OnStart(buffListId)
    self._BuffListId = buffListId
    local listener = self.GameObject:GetComponent("XUguiEventListener")
    --if listener then
    --    listener.OnDown = function() 
    --        self:OnBuffDown()
    --    end
    --
    --    listener.OnUp = function()
    --        self:OnBuffUp()
    --    end
    --end
    self.Enable = self.Transform:Find("PanelBubble/Animation/Enable")
    self.Disable = self.Transform:Find("PanelBubble/Animation/Disable")
    listener.OnClick = function() 
        self:OnClickBuff()
    end
    self._OnBubbleFinishCb = function()
        self._IsPlaying = false
        if XTool.UObjIsNil(self.PanelBubble) then
            return
        end
        self.PanelBubble.gameObject:SetActiveEx(self._IsShowDetail)
    end
    self.Listener = listener
    self.TxtDetail.requestImage = XMVCA.XSkyGardenCafe.RichTextImageCallBackCb
    self:RefreshView()
end

function XUiGridSGBuffItem:OnDestroy()
    self.Listener.OnClick = nil
end

function XUiGridSGBuffItem:RefreshView()
    if not self._BuffListId or self._BuffListId <= 0 then
        self:Close()
        return
    end
    self._IsShowDetail = self.Parent.IsShowBuffDetail and self.Parent:IsShowBuffDetail()
    local id = self._BuffListId
    local icon = self._Control:GetBuffListIcon(id)
    if not string.IsNilOrEmpty(icon) then
        if self.ImgBuff then
            self.ImgBuff:SetSprite(icon)
        elseif self.RImgBuff then
            self.RImgBuff:SetRawImage(icon)
        end
    end
    self:PlayBubbleAnimation()
    self.PanelNum.gameObject:SetActiveEx(false)
    self.TxtDetail.text = XUiHelper.ReplaceTextNewLine(self._Control:GetBuffListDesc(id))
end

function XUiGridSGBuffItem:OnBuffDown()
    self.PanelBubble.gameObject:SetActiveEx(true)
end

function XUiGridSGBuffItem:OnBuffUp()
    self.PanelBubble.gameObject:SetActiveEx(false)
end

function XUiGridSGBuffItem:OnClickBuff()
    if self._IsPlaying then
        return
    end
    self._IsShowDetail = not self._IsShowDetail
    self:PlayBubbleAnimation()
end

function XUiGridSGBuffItem:PlayBubbleAnimation()
    local grid
    if self._IsShowDetail then
        grid = self.Enable
        self.PanelBubble.gameObject:SetActiveEx(true)
    else
        grid = self.Disable
    end
    if grid then
        self._IsPlaying = true
        grid:PlayTimelineAnimation(self._OnBubbleFinishCb)
    end
end

return XUiGridSGBuffItem