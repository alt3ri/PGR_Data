local XUiEquipOverrunSelectGrid = XClass(nil, "XUiEquipOverrunSelectGrid")

function XUiEquipOverrunSelectGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiEquipOverrunSelectGrid:Init(parent)
    self.Parent = parent
end

--- @param isCultureMode boolean 养成方案展示模式（纯展示，显示养成相关标签）
--- @param isRecommend boolean 养成方案展示模式下是否为推荐套装
function XUiEquipOverrunSelectGrid:Refresh(suitData, isLastSelect, isCultureMode, isRecommend)
    self.IsCultureMode = isCultureMode
    local suitCfg = XMVCA.XEquip:GetConfigEquipSuit(suitData.Id)
    self.RImgIcon:SetRawImage(suitCfg.IconPath)
    self.TxtName.text = suitCfg.Name
    self.TxtDes.text = suitCfg.Description

    local qualityPath = XArrangeConfigs.GeQualityBgPath(suitData.Quality)
    self.ImgEquipQuality:SetSprite(qualityPath)

    if isCultureMode then
        -- 养成展示态：隐正常态标签（TagNow/TagNotActive/Select）
        self.TagNow.gameObject:SetActiveEx(false)
        self.TagNotActive.gameObject:SetActiveEx(false)
        self.Select.gameObject:SetActiveEx(false)
        -- 推荐套装只显 TagTarget；非推荐按是否已绑定显 TagBind/TagNotBind
        self.TagTarget.gameObject:SetActiveEx(isRecommend)
        self.TagBind.gameObject:SetActiveEx(isLastSelect)
        self.TagNotBind.gameObject:SetActiveEx(not isRecommend)
    else
        -- 正常态/装备预览：隐养成态标签（TagTarget/TagBind/TagNotBind）
        self.TagTarget.gameObject:SetActiveEx(false)
        self.TagBind.gameObject:SetActiveEx(false)
        self.TagNotBind.gameObject:SetActiveEx(false)
        self.TagNotActive.gameObject:SetActiveEx(not suitData.IsActive)
        self.TagNow.gameObject:SetActiveEx(isLastSelect)
    end
end

function XUiEquipOverrunSelectGrid:SetCurSelect(isCurSelect)
    -- 养成展示态不显选中框
    self.Select.gameObject:SetActiveEx(not self.IsCultureMode and isCurSelect)
end

return XUiEquipOverrunSelectGrid