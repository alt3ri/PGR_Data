---@class XUiPanelTheatre6BubbleTag : XUiNode Tag气泡
---@field _Control XTheatre6Control
local XUiPanelTheatre6BubbleTag = XClass(XUiNode, "XUiPanelTheatre6BubbleTag")

function XUiPanelTheatre6BubbleTag:OnStart()
    self.BtnCloseTagDetail:AddEventListener(handler(self, self.Close))
end

function XUiPanelTheatre6BubbleTag:SetIds(buildTagIds, keyWordIds)
    local keyWordCfgs = self:_GetKeyWordCfgs(keyWordIds)
    local totalCount = #buildTagIds + #keyWordCfgs
    self._TagGrids = XUiHelper.RefreshUiObjectList(self._TagGrids, self.GridTagDetail.parent, self.GridTagDetail, totalCount, function(i, grid)
        if i <= #buildTagIds then
            local config = self._Control:GetBuildTagConfig(buildTagIds[i])
            self:ShowGrid(grid, config)
        else
            local kwCfg = keyWordCfgs[i - #buildTagIds]
            self:ShowKeyWordGrid(grid, kwCfg)
        end
    end)
end

---@param buildTagConfigs XTableTheatre6BuildTag[]
function XUiPanelTheatre6BubbleTag:SetConfigs(buildTagConfigs, keyWordIds)
    local keyWordCfgs = self:_GetKeyWordCfgs(keyWordIds)
    local totalCount = #buildTagConfigs + #keyWordCfgs
    self._TagGrids = XUiHelper.RefreshUiObjectList(self._TagGrids, self.GridTagDetail.parent, self.GridTagDetail, totalCount, function(i, grid)
        if i <= #buildTagConfigs then
            local config = buildTagConfigs[i]
            self:ShowGrid(grid, config)
        else
            local kwCfg = keyWordCfgs[i - #buildTagConfigs]
            self:ShowKeyWordGrid(grid, kwCfg)
        end
    end)
end

function XUiPanelTheatre6BubbleTag:_GetKeyWordCfgs(keyWordIds)
    local cfgs = {}
    if keyWordIds then
        for _, kwId in ipairs(keyWordIds) do
            local cfg = self._Control:GetKeyWordConfig(kwId)
            if cfg then
                table.insert(cfgs, cfg)
            end
        end
    end
    return cfgs
end

---@param config XTableTheatre6BuildTag
function XUiPanelTheatre6BubbleTag:ShowGrid(grid, config)
    local isExistIcon = not string.IsNilOrEmpty(config.Icon)
    grid.ImgIcon.gameObject:SetActiveEx(isExistIcon)
    grid.UiTxtName.text = config.Name
    grid.UiTxtDesc.text = config.Desc
    if isExistIcon then
        grid.ImgIcon:SetSprite(config.Icon)
    end
end

---@param kwCfg XTableTheatre6KeyWord
function XUiPanelTheatre6BubbleTag:ShowKeyWordGrid(grid, kwCfg)
    grid.ImgIcon.gameObject:SetActiveEx(false)
    grid.UiTxtName.text = kwCfg.Name
    grid.UiTxtDesc.text = kwCfg.Des
end

return XUiPanelTheatre6BubbleTag
