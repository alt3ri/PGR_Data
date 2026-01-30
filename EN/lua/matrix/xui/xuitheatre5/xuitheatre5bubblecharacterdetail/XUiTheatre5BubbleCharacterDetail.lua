---@class XUiTheatre5BubbleCharacterDetail: XLuaUi
---@field private _Control XTheatre5Control
local XUiTheatre5BubbleCharacterDetail = XLuaUiManager.Register(XLuaUi, 'UiTheatre5BubbleCharacterDetail')
local XUiGridTheatre5CharaterAttribute = require('XUi/XUiTheatre5/XUiTheatre5BubbleCharacterDetail/XUiGridTheatre5CharaterAttribute')

function XUiTheatre5BubbleCharacterDetail:OnAwake()
    self.BtnBack.CallBack = handler(self, self.Close)
    self.GridAttribute.gameObject:SetActiveEx(false)
end

function XUiTheatre5BubbleCharacterDetail:OnStart()
    self:RefreshShow()
    self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_HIDE_ITEM_DETAIL)
end

function XUiTheatre5BubbleCharacterDetail:RefreshShow()
    ---@type XTableTheatre5Character
    local characterCfg = self._Control:GetCurCharacterCfg()

    -- 属性展示
    ---@type XTableTheatre5AttrShow[]
    local showAttrCfgs = self._Control:GetTheatre5AttrShowCfgs()

    ---@type XTableAttribBase
    local dlcAttrCfg = XMVCA.XDlcWorld:GetAttributeConfigById(characterCfg.AttrId)

    local attrs = {}
    if dlcAttrCfg then
        for typeUntransform, attrValue in pairs(dlcAttrCfg) do
            local attribType = XDlcNpcAttribType[typeUntransform]
            if attribType then
                attrs[attribType] = attrValue
            end
        end
    end
    self._Control:GetLevelAttr(attrs)

    if not XTool.IsTableEmpty(showAttrCfgs) then
        if self._GridAttrs == nil then
            self._GridAttrs = {}
        end

        if not XTool.IsTableEmpty(self._GridAttrs) then
            for i, v in pairs(self._GridAttrs) do
                v:Close()
            end
        end

        local index = 1

        for i, v in ipairs(showAttrCfgs) do
            if XTool.IsNumberValid(v.ShowType) then

                local grid = self._GridAttrs[index]

                if not grid then
                    local go = CS.UnityEngine.GameObject.Instantiate(self.GridAttribute, self.PanelDetail.transform)
                    grid = XUiGridTheatre5CharaterAttribute.New(go, self)
                    self._GridAttrs[index] = grid
                end

                grid:Open()
                local attrType = XDlcNpcAttribType[v.AttrType]
                grid:Refresh(v, attrs[attrType] or 0)
                index = index + 1
            end
        end
    end
end

return XUiTheatre5BubbleCharacterDetail