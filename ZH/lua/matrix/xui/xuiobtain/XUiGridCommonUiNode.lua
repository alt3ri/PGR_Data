local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridCommonUiNode = XClass(XUiNode, "XUiGridCommonUiNode")

-- 对UiGridCommon的浅包装，使其符合XUiNode的约定

function XUiGridCommonUiNode:InitNode(ui, parent, ...)
    self._Grid = XUiGridCommon.New(parent, ui, ...)
    self.Super.InitNode(self, ui, parent, ...)
end

function XUiGridCommonUiNode:SetData(data, args)
    local isBigIcon = nil
    local hideSkipBtn = nil
    local curCount = nil

    if args then
        isBigIcon = args.IsBigIcon
        hideSkipBtn = args.HideSkipBtn
        curCount = args.CurCount
    end

    self:Refresh(data, args, isBigIcon, hideSkipBtn, curCount)
end

XTool.ExportMemberMethods(XUiGridCommonUiNode, "_Grid", {
    "Refresh",
    -- 使用时导出需要的函数
})

return XUiGridCommonUiNode
