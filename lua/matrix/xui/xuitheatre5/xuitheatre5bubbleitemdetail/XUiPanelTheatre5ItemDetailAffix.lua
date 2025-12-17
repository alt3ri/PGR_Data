---@class XUiPanelTheatre5ItemDetailAffix: XUiNode
---@field private _Control XTheatre5Control
local XUiPanelTheatre5ItemDetailAffix = XClass(XUiNode, 'XUiPanelTheatre5ItemDetailAffix')

function XUiPanelTheatre5ItemDetailAffix:OnStart()
    -- transform的宽度隐藏后会莫名清空，目前UI宽度没有自适应变化，直接激活时缓存
    self.Width = self.Transform.sizeDelta.x
end

---@param keywordList number[]
function XUiPanelTheatre5ItemDetailAffix:Refresh(keywordList)
    self._AffixList = XUiHelper.RefreshUiObjectList(self._AffixList, self.Transform, self.GridAffix, #keywordList, function(index, grid)
        ---@type XTableTheatre5ItemKeyWord
        local keywordCfg = self._Control:GetTheatre5ItemKeyWordCfgById(keywordList[index])

        if keywordCfg then
            if grid.TxtTitle then
                grid.TxtTitle.text = keywordCfg.KeyWord
            end

            if grid.TxtDes then
                grid.TxtDes.text = XUiHelper.ReplaceTextNewLine(keywordCfg.Desc)
            end
        end
    end)
end

return XUiPanelTheatre5ItemDetailAffix