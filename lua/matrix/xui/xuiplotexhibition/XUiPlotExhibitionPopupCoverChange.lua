local XUiPlotExhibitionPopupCoverChangeGrid = require("XUi/XUiPlotExhibition/XUiPlotExhibitionPopupCoverChangeGrid")

---@class XUiPlotExhibitionPopupCoverChange : XLuaUi
---@field _Control XPlotExhibitionControl
local XUiPlotExhibitionPopupCoverChange = XLuaUiManager.Register(XLuaUi, "UiPlotExhibitionPopupCoverChange")

function XUiPlotExhibitionPopupCoverChange:OnAwake()
    self.GridCover.gameObject:SetActiveEx(false)
    self:BindExitBtns(self.BtnClose)
    
    ---@type XUiPlotExhibitionPopupCoverChangeGrid[]
    self._GridCover = {}
end

function XUiPlotExhibitionPopupCoverChange:OnStart(roleId)
    -- 如果传入了roleId，设置该角色
    if roleId then
        local role = self._Control:GetRole(roleId)
        if role then
            self._Control:SetRole4UiDetail(role)
        end
    end
end

function XUiPlotExhibitionPopupCoverChange:OnEnable()
    self:Update()
end

function XUiPlotExhibitionPopupCoverChange:OnDisable()
end

function XUiPlotExhibitionPopupCoverChange:Update()
    -- 更新Detail
    self._Control:UpdateDetail(true)
    
    -- 获取该角色下所有可用的Character列表
    local characterList = self._Control:GetUiData().Detail.CharacterList
    
    -- 逆序处理
    local reversedList = {}
    for i = #characterList, 1, -1 do
        reversedList[#reversedList + 1] = characterList[i]
    end
    
    -- 使用UpdateDynamicItem更新Grid列表
    XTool.UpdateDynamicItem(self._GridCover, reversedList, self.GridCover, XUiPlotExhibitionPopupCoverChangeGrid, self)
end

return XUiPlotExhibitionPopupCoverChange

