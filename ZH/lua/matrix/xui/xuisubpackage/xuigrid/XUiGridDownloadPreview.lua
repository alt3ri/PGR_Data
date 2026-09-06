---@class XUiGridDownloadPreview : XUiNode
local XUiGridDownloadPreview = XClass(XUiNode, "XUiGridDownloadPreview")

function XUiGridDownloadPreview:OnStart()
    if self.ToggleSelect then
        self.ToggleSelect:AddEventListener(handler(self, self.OnToggleSelectClick))
    end
end

function XUiGridDownloadPreview:Refresh(data)
    if not data then return end
    self.Data = data

    self._SizeInfo = XMVCA.XSubPackage:CreateResListSizeInfo(data.ResIds)

    -- 选项名称
    if self.TxtTitle then
        self.TxtTitle.text = data.OptionName or ""
    end

    -- 描述
    if self.TxtTips then
        self.TxtTips.text = data.Desc or ""
    end

    -- 资源大小（按物理文件名去重）
    if self.TxtNum then
        local totalSize = self._SizeInfo.TotalSize
        local num, unit = XMVCA.XSubPackage:TransformSize(totalSize)
        self.TxtNum.text = string.format("%d%s", num, unit)
    end

    -- 选中状态
    self:UpdateSelectState(data.IsSelected)

    -- PanelIgnoreTips显示逻辑
    local playerId = XPlayer.Id
    local cacheKey = "SubPackageIgnoreVersion_" .. playerId
        .. "_" .. (data.EnterType or "")
        .. "_" .. (data.Param or "")
        .. "_" .. data.ControlId
    local cachedState = XSaveTool.GetData(cacheKey)
    -- 版本忽略勾选框仅在界面只有弱选项时才显示
    local showIgnoreTips = data.IgnoreInterput and cachedState == nil and data.OnlyWeakOptions

    if self.PanelIgnoreTips then
        self.PanelIgnoreTips.gameObject:SetActiveEx(showIgnoreTips)
    end

    -- ToggleIgnoreVersion状态（Unity原生Toggle组件）
    if self.ToggleIgnoreVersion then
        self.ToggleIgnoreVersion.isOn = cachedState == true
    end

    -- 聚合进度条刷新
    self:RefreshAggregatedProgress()
end

function XUiGridDownloadPreview:UpdateSelectState(isSelected)
    if self.ToggleSelect then
        self.ToggleSelect:SetButtonState(isSelected and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    end
end

function XUiGridDownloadPreview:OnToggleSelectClick()
    if not self.Data then return end
    -- 强选项不允许取消勾选
    if not self.Data.IsWeak and self.Data.IsSelected then
        self:UpdateSelectState(true)
        return
    end
    self.Data.IsSelected = not self.Data.IsSelected
    self:UpdateSelectState(self.Data.IsSelected)
end

-- 刷新聚合进度
function XUiGridDownloadPreview:RefreshAggregatedProgress()
    local totalSize = self._SizeInfo.TotalSize
    local downloadedSize = XMVCA.XSubPackage:GetSizeInfoDownloadSize(self._SizeInfo)
    local progress = totalSize > 0 and (downloadedSize / totalSize) or 0
    if self.ImgBar then
        self.ImgBar.fillAmount = progress
    end
    if self.TxtProgress then
        self.TxtProgress.text = math.floor(progress * 100) .. "%"
    end
end

-- 获取数据
function XUiGridDownloadPreview:GetData()
    return self.Data
end

-- 获取ToggleIgnoreVersion状态（Unity原生Toggle组件）
function XUiGridDownloadPreview:GetIgnoreVersionState()
    if self.ToggleIgnoreVersion then
        return self.ToggleIgnoreVersion.isOn
    end
    return false
end

return XUiGridDownloadPreview
