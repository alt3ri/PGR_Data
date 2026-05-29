---@class XUiGridTheatre6Relic : XUiNode 遗物格子
---@field _Control XTheatre6Control
---@field ListTag UnityEngine.RectTransform
---@field Tag UiObject
local XUiGridTheatre6Relic = XClass(XUiNode, "XUiGridTheatre6Relic")

function XUiGridTheatre6Relic:OnStart()
    if self.GridRelic then
        self.GridRelic:AddEventListener(handler(self, self.OnGridRelicClick))
    end
end

function XUiGridTheatre6Relic:SetRelic(id, count)
    self._Id = id
    self._Config = self._Control:GetAttrPackCfgById(id)
    self.RImgIcon:SetRawImage(self._Config.Icon)
    self.ImgBg:SetRawImage(self._Control:GetRelicQualityIcon(self._Config.Quality))
    self.UiTxtNum.text = count
    if self.UiTxtNumBg then
        self.UiTxtNumBg.gameObject:SetActiveEx(count > 1)
    end
    self.ImgMask.gameObject:SetActiveEx(false)
    self:ShowBuildTag()
end

---置灰 显示 +count
function XUiGridTheatre6Relic:ShowMore(count)
    self.ImgMask.gameObject:SetActiveEx(true)
    self.UiTxtAddNum.text = string.format("+%s", count)
end

function XUiGridTheatre6Relic:ShowBuildTag()
    ---@type XTableTheatre6BuildTag[]
    local showTags = self._Control:GetShowBuildTagWithSort(self._Config.BuildTags)
    if #showTags > 0 then
        self.ListTag.gameObject:SetActiveEx(true)
        XUiHelper.RefreshCustomizedList(self.Tag.parent, self.Tag, #showTags, function(i, go)
            local uiObject = {}
            XUiHelper.InitUiClass(uiObject, go)
            uiObject.RImgIcon:SetRawImage(showTags[i].Icon)
        end)
    else
        self.ListTag.gameObject:SetActiveEx(false)
    end
end

function XUiGridTheatre6Relic:SetClickCb(cb)
    self._Click = cb
end

function XUiGridTheatre6Relic:OnGridRelicClick()
    if self._Click then
        self._Click()
    end
end


----------------------------------------------------------------------------------------------

function XUiGridTheatre6Relic:Update(relicId)
    self._RelicId = relicId
    local config = self._Control:GetAttrPackCfgById(self._RelicId)
    self.ImgBg:SetRawImage(self._Control:GetRelicQualityIcon(config.Quality))
    self.RImgIcon:SetRawImage(config.Icon)
    self.ListTag.gameObject:SetActiveEx(false)
end

function XUiGridTheatre6Relic:GetDesc()
    return self._Control:GetAttrPackDesc(self._RelicId, true)
end

--@return string Icon 用于快速获取技能价格
function XUiGridTheatre6Relic:GetBuyPrice()
    local config = self._Control:GetAttrPackCfgById(self._RelicId)
    return config.BuyPrice or 0
end

return XUiGridTheatre6Relic
