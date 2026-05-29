---@class XUiPanelTheatre6TagDetail : XUiNode
---@field _Control XTheatre6Control
---@field BtnClose XUiComponent.XUiButton
---@field GridTagDetail UiObject
---@field GridTagDetail.UiTxtName UnityEngine.UI.Text
---@field GridTagDetail.UiTxtDesc XUiComponent.XUiRichTextCustomRender
---@field GridTagDetail.ImgIcon UnityEngine.UI.Image
local XUiPanelTheatre6TagDetail = XLuaUiManager.Register(XUiNode, "XUiPanelTheatre6TagDetail")

function XUiPanelTheatre6TagDetail:OnStart()
    self:InitComponents()
end

function XUiPanelTheatre6TagDetail:InitComponents()
end

function XUiPanelTheatre6TagDetail:Refresh(buildTagIds, keyWordIds)
    local buildTagCfg = self._Control:GetShowBuildTagWithSort(buildTagIds)
    --先显示keyword
    local showKeyWordCfgs = {}
    if keyWordIds then
        for _, kwId in ipairs(keyWordIds) do
            local cfg = self._Control:GetKeyWordConfig(kwId)
            if cfg then
                table.insert(showKeyWordCfgs, cfg)
            end
        end
    end
    local totalCount = #buildTagCfg + #showKeyWordCfgs
    XUiHelper.RefreshCustomizedList(self.GridTagDetail.transform.parent, self.GridTagDetail, totalCount,
        function(index, go)
            local ui = {}
            XTool.InitUiObjectByUi(ui, go)
            ui.UiTxtDesc.requestImage = XMVCA.XTheatre6.RichTextImageCallBack
            local desc = nil
            if index <= #showKeyWordCfgs then
                local cfg = showKeyWordCfgs[index]
                ui.UiTxtName.text = cfg.Name
                desc = self._Control:ReplaceAttrPlaceholder(cfg.Desc)
                local isExistIcon = not string.IsNilOrEmpty(cfg.Icon)
                ui.ImgIcon.gameObject:SetActiveEx(isExistIcon)
                if isExistIcon then
                    ui.ImgIcon:SetSprite(cfg.Icon)
                end
            else
                local config = buildTagCfg[index - #showKeyWordCfgs]
                ui.UiTxtName.text = config.Name
                desc = self._Control:ReplaceAttrPlaceholder(config.Desc)
                ui.ImgIcon.gameObject:SetActiveEx(false)
            end
            if desc ~= nil then
                desc = XUiHelper.ReplaceTextNewLine(desc)
                ui.UiTxtDesc.text = desc
            end
            ui.GameObject:SetActiveEx(true)
        end)
end

return XUiPanelTheatre6TagDetail
