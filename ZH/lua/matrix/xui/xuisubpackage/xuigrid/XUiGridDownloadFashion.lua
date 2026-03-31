---@class XUiGridDownloadFashion : XUiNode
local XUiGridDownloadFashion = XClass(XUiNode, "XUiGridDownloadFashion")

function XUiGridDownloadFashion:OnStart()
end

function XUiGridDownloadFashion:Refresh(data)
    if not data then return end
    self.Data = data

    -- 涂装名称
    if self.TxtFashionName then
        self.TxtFashionName.text = data.Name or ""
    end

    -- 涂装图标
    if self.RImgFashion then
        local template = XDataCenter.FashionManager.GetFashionTemplate(data.FashionId)
        if template and template.Icon then
            self.RImgFashion:SetRawImage(template.Icon)
        end
    end

    -- 角色名称
    if self.TxtCharacterName and XTool.IsNumberValid(data.CharacterId) then
        local charConfig = XMVCA.XCharacter:GetCharacterTemplate(data.CharacterId)
        self.TxtCharacterName.text = charConfig and charConfig.Name or ""
    end

    -- 资源大小
    if self.TxtSize then
        local size = XMVCA.XSubPackage:GetResTotalSize(data.ResId)
        local num, unit = XMVCA.XSubPackage:TransformSize(size)
        self.TxtSize.text = string.format("%d%s", num, unit)
    end

    -- Tag显隐
    self:RefreshTags(data)

    -- 进度条
    self:RefreshProgress(nil)
end

-- 刷新Tag显隐（TagDownloaded/TagDownloading/TagNotOwn 三选一互斥，TagSelect 独立）
function XUiGridDownloadFashion:RefreshTags(data)
    local showDownloaded = data.IsDownloaded
    local showDownloading = data.IsDownloading and not data.IsDownloaded
    local showNotOwn = not showDownloaded and not showDownloading and not data.IsOwn

    if self.TagDownloaded then
        self.TagDownloaded.gameObject:SetActiveEx(showDownloaded)
    end
    if self.TagDownloading then
        self.TagDownloading.gameObject:SetActiveEx(showDownloading)
    end
    if self.TagNotOwn then
        self.TagNotOwn.gameObject:SetActiveEx(showNotOwn)
    end

    -- 选中标记（独立）
    if self.TagSelect then
        self.TagSelect.gameObject:SetActiveEx(data.IsSelected)
    end
end

-- 更新选中状态
function XUiGridDownloadFashion:UpdateSelectState(isSelected)
    self.Data.IsSelected = isSelected
    if self.TagSelect then
        self.TagSelect.gameObject:SetActiveEx(isSelected)
    end
end

function XUiGridDownloadFashion:RefreshProgress(progress)
    if not self.ImgProgress or not self.Data then return end

    if progress == nil then
        local resItem = XMVCA.XSubPackage:GetResourceItem(self.Data.ResId)
        progress = resItem and resItem:GetProgress() or 0
    end

    self.ImgProgress.fillAmount = progress

    if self.TxtProgress then
        self.TxtProgress.text = math.floor(progress * 100) .. "%"
    end
end

return XUiGridDownloadFashion