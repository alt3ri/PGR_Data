local Vector3 = CS.UnityEngine.Vector3
local mathMax = math.max

local MAX_SLOT = 5
local MASK_ALPHA = 0.7

---@class XUiMovieItemPanel
---@field RootUi XUiMovie
local XUiMovieItemPanel = XClass(nil, "XUiMovieItemPanel")

function XUiMovieItemPanel:Ctor(ui, rootUi)
    self.RootUi = rootUi
    self.GameObject = ui
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.Slots = {}
    self.ActiveCount = 0

    for i = 1, MAX_SLOT do
        local image = self["PanelItem" .. i]
        if image then
            self.Slots[i] = {
                GameObject = image.gameObject,
                Transform = image.transform,
                Image = image,
                Active = false,
            }
            image.gameObject:SetActiveEx(false)
            self:_SetImageAlpha(image, 0)
        end
    end

    if self.PanelMask then
        self:_SetImageAlpha(self.PanelMask, 0)
        self.PanelMask.gameObject:SetActiveEx(false)
    end
end

function XUiMovieItemPanel:Set(index, iconPath, duration, x, y, z)
    local slot = self.Slots[index]
    if not slot then
        XLog.Error(string.format("XUiMovieItemPanel:Set 槽位不存在 index=%s, MAX_SLOT=%s", tostring(index), MAX_SLOT))
        return
    end
    if string.IsNilOrEmpty(iconPath) then
        XLog.Error(string.format("XUiMovieItemPanel:Set IconPath 为空 index=%s", tostring(index)))
        return
    end

    local pos = Vector3(x, y, z)
    self:_KillFadeTween(slot)
    self:_KillMoveTween(slot)

    if slot.Image then
        if not slot.SetNativeSizeCb then
            slot.SetNativeSizeCb = function()
                if not XTool.UObjIsNil(slot.Image) then
                    slot.Image:SetNativeSize()
                end
            end
        end
        slot.Image:SetSprite(iconPath, slot.SetNativeSizeCb)
    end
    slot.Transform.localPosition = pos
    slot.GameObject:SetActiveEx(true)

    if slot.Active then
        self:_SetImageAlpha(slot.Image, 1)
        return
    end

    slot.Active = true
    self.ActiveCount = self.ActiveCount + 1

    if slot.Image then
        self:_SetImageAlpha(slot.Image, 0)
        if duration <= 0 then
            self:_SetImageAlpha(slot.Image, 1)
        else
            slot.FadeTween = slot.Image:DOFade(1, duration)
        end
    end

    self:_AcquireMask(duration)
end

function XUiMovieItemPanel:Move(index, duration, x, y, z)
    local slot = self.Slots[index]
    if not slot or not slot.Active then
        return
    end

    local pos = Vector3(x, y, z)
    self:_KillMoveTween(slot)

    if duration <= 0 then
        slot.Transform.localPosition = pos
    else
        slot.MoveTween = slot.Transform:DOLocalMove(pos, duration)
    end
end

function XUiMovieItemPanel:Remove(index, duration)
    local slot = self.Slots[index]
    if not slot or not slot.Active then
        return
    end

    slot.Active = false
    self.ActiveCount = mathMax(0, self.ActiveCount - 1)

    self:_KillFadeTween(slot)
    self:_KillMoveTween(slot)

    local hide = function()
        if not XTool.UObjIsNil(slot.GameObject) then
            slot.GameObject:SetActiveEx(false)
        end
    end

    if duration <= 0 or not slot.Image then
        self:_SetImageAlpha(slot.Image, 0)
        hide()
    else
        slot.FadeTween = slot.Image:DOFade(0, duration)
        slot.FadeTween:OnComplete(hide)
    end

    self:_ReleaseMask(duration)
end

function XUiMovieItemPanel:_AcquireMask(duration)
    if self.ActiveCount > 1 or XTool.UObjIsNil(self.PanelMask) then
        return
    end
    self:_KillMaskTween()
    self.PanelMask.gameObject:SetActiveEx(true)
    self:_SetImageAlpha(self.PanelMask, 0)
    if duration <= 0 then
        self:_SetImageAlpha(self.PanelMask, MASK_ALPHA)
    else
        self.MaskTween = self.PanelMask:DOFade(MASK_ALPHA, duration)
    end
end

function XUiMovieItemPanel:_ReleaseMask(duration)
    if self.ActiveCount > 0 or XTool.UObjIsNil(self.PanelMask) then
        return
    end
    self:_KillMaskTween()
    if duration <= 0 then
        self:_SetImageAlpha(self.PanelMask, 0)
        self.PanelMask.gameObject:SetActiveEx(false)
    else
        self.MaskTween = self.PanelMask:DOFade(0, duration)
        self.MaskTween:OnComplete(function()
            if not XTool.UObjIsNil(self.PanelMask) then
                self.PanelMask.gameObject:SetActiveEx(false)
            end
        end)
    end
end

function XUiMovieItemPanel:_SetImageAlpha(image, alpha)
    if XTool.UObjIsNil(image) then
        return
    end
    local color = image.color
    color.a = alpha
    image.color = color
end

function XUiMovieItemPanel:_KillFadeTween(slot)
    if slot.FadeTween then
        slot.FadeTween:Kill()
        slot.FadeTween = nil
    end
end

function XUiMovieItemPanel:_KillMoveTween(slot)
    if slot.MoveTween then
        slot.MoveTween:Kill()
        slot.MoveTween = nil
    end
end

function XUiMovieItemPanel:_KillMaskTween()
    if self.MaskTween then
        self.MaskTween:Kill()
        self.MaskTween = nil
    end
end

function XUiMovieItemPanel:OnDestroy()
    self:_KillMaskTween()
    for _, slot in pairs(self.Slots) do
        self:_KillFadeTween(slot)
        self:_KillMoveTween(slot)
        slot.Active = false
        slot.SetNativeSizeCb = nil
    end
    self.ActiveCount = 0
end

return XUiMovieItemPanel
