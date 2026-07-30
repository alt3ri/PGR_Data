local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiGridPhotographCharacterBtn = XClass(nil, "XUiGridPhotographCharacterBtn")

function XUiGridPhotographCharacterBtn:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui:GetComponent(typeof(CS.UnityEngine.RectTransform))
    XTool.InitUiObject(self)
end

function XUiGridPhotographCharacterBtn:Init(rootUi)
    self.rootUi = rootUi
end

function XUiGridPhotographCharacterBtn:Refrash(data)
    self.ImgHead:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(data.Id))
    self.TxtName.text = data.LogName
    if self.TxtNameEn then
        self.TxtNameEn.text = data.EnName
    end
    self.TxtAIXin.text = data.TrustLv
    local fashionId = XDataCenter.FashionManager.GetFashionIdByCharId(data.Id)
    local template = XDataCenter.FashionManager.GetFashionTemplate(fashionId)

    if self.ColorTag then
        local hasOwnedColor = false
        if template.FashionColorIds then
            for _, colorId in ipairs(template.FashionColorIds) do
                if XMVCA.XFashion:IsFashionColorHas(fashionId, colorId) then
                    hasOwnedColor = true
                    break
                end
            end
        end
        self.ColorTag.gameObject:SetActiveEx(hasOwnedColor)
    end
end

function XUiGridPhotographCharacterBtn:OnTouched(charId)
    self:SetSelect(true)
    local fashionId = XDataCenter.FashionManager.GetFashionIdByCharId(charId)
    local colorId = XDataCenter.FashionManager.GetOwnFashionDataById(fashionId).ColorId
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_PHOTO_CHANGE_MODEL, charId, fashionId,colorId)
end

function XUiGridPhotographCharacterBtn:SetSelect(bool)
    self.Sel.gameObject:SetActiveEx(bool)
end

function XUiGridPhotographCharacterBtn:Reset()
    self:SetSelect(false)
end

return XUiGridPhotographCharacterBtn