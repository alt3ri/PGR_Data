local XUiGridTRWeaponOverrunSuit = XClass(nil, "XUiGridTRWeaponOverrunSuit")

function XUiGridTRWeaponOverrunSuit:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridTRWeaponOverrunSuit:Init(parent)
    self.Parent = parent
end

-- 刷新推荐谐振套装展示
---@param suitData table 谐振套装展示数据，IsEquipBoundSuit表示候选武器当前绑定的套装是否为本条
function XUiGridTRWeaponOverrunSuit:Refresh(suitData)
    local suitCfg = XMVCA.XEquip:GetConfigEquipSuit(suitData.Id)
    self.RImgIcon:SetRawImage(suitCfg.IconPath)
    self.TxtName.text = suitCfg.Name
    self.TxtDes.text = suitCfg.Description
    self.ImgEquipQuality:SetSprite(XArrangeConfigs.GeQualityBgPath(suitData.Quality))
    self.TagTarget.gameObject:SetActiveEx(suitData.IsTarget)
    self.TagNow.gameObject:SetActiveEx(false)
    self.TagNotActive.gameObject:SetActiveEx(false)
    self.TagBind.gameObject:SetActiveEx(suitData.IsEquipBoundSuit)
    self.TagNotBind.gameObject:SetActiveEx(not suitData.IsTarget and not suitData.IsEquipBoundSuit)
end

function XUiGridTRWeaponOverrunSuit:SetCurSelect(isCurSelect)
    self.Select.gameObject:SetActiveEx(isCurSelect)
end

return XUiGridTRWeaponOverrunSuit
