---@class XUiGridPreviewTips : XUiNode
local XUiGridPreviewTips = XClass(XUiNode, "XUiGridPreviewTips")

function XUiGridPreviewTips:OnStart()
    if self.ToggleSelect then
        self.ToggleSelect:AddEventListener(handler(self, self.OnToggleSelectClick))
    end
end

function XUiGridPreviewTips:Refresh(data)
    if not data then return end
    self.Data = data

    -- 选项名称
    if self.TxtTitle then
        self.TxtTitle.text = data.OptionName or ""
    end

    -- 描述
    if self.TxtTips then
        self.TxtTips.text = data.Desc or ""
    end

    -- 资源大小（跨ResId去重，与Grid/下载器大小一致）
    if self.TxtNum then
        local resIdTable = {}
        for _, resId in ipairs(data.ResIds or {}) do
            resIdTable[resId] = true
        end
        local totalSize = XMVCA.XSubPackage:GetResListTotalSize(resIdTable)
        local num, unit = XMVCA.XSubPackage:TransformSize(totalSize)
        self.TxtNum.text = string.format("%d%s", num, unit)
    end

    -- 选中状态
    self:UpdateSelectState(data.IsSelected)

    -- 聚合进度条刷新
    self:RefreshAggregatedProgress(data)
end

function XUiGridPreviewTips:UpdateSelectState(isSelected)
    if self.ToggleSelect then
        self.ToggleSelect:SetButtonState(isSelected and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    end
end

function XUiGridPreviewTips:OnToggleSelectClick()
    -- 单选逻辑：通知父级切换选中
    if self.Parent and self.Parent.OnGridSelectChanged then
        self.Parent:OnGridSelectChanged(self.Data.Index)
    end
end

function XUiGridPreviewTips:RefreshAggregatedProgress(data)
    if not data or XTool.IsTableEmpty(data.ResIds) then
        return
    end

    local totalSize = 0
    local downloadedSize = 0
    for _, resId in ipairs(data.ResIds) do
        local resItem = XMVCA.XSubPackage:GetResourceItem(resId)
        if resItem then
            totalSize = totalSize + resItem:GetTotalSize()
            downloadedSize = downloadedSize + resItem:GetDownloadSize()
        end
    end

    local progress = totalSize > 0 and (downloadedSize / totalSize) or 0
    if self.ImgBar then
        self.ImgBar.fillAmount = progress
    end
    if self.TxtProgress then
        self.TxtProgress.text = math.floor(progress * 100) .. "%"
    end
end

return XUiGridPreviewTips
