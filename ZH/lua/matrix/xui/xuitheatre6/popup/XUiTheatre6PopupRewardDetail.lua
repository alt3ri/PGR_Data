local XUiTheatre6PopupRewardDetail = XLuaUiManager.Register(XLuaUi, "UiTheatre6PopupRewardDetail")

function XUiTheatre6PopupRewardDetail:OnAwake()
    self:InitAutoScript()
end

function XUiTheatre6PopupRewardDetail:OnStart(data, title, showNum)
    self.Data = data
    self.ShowNum = showNum
    if self.TxtTitle and title then
        self.TxtTitle.text = title
    end
    self:PlayAnimation("AnimStart")
end

function XUiTheatre6PopupRewardDetail:OnEnable()
    self:Refresh(self.Data)
end

function XUiTheatre6PopupRewardDetail:InitAutoScript()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnOk, self.OnBtnOkClick)
end

function XUiTheatre6PopupRewardDetail:OnBtnBackClick()
    self:Close()
end

function XUiTheatre6PopupRewardDetail:OnBtnOkClick()
    self:Close()
end

function XUiTheatre6PopupRewardDetail:SetUiActive(ui, active)
    if not ui or not ui.gameObject then return end
    if ui.gameObject.activeSelf == active then return end
    ui.gameObject:SetActive(active)
end

function XUiTheatre6PopupRewardDetail:ResetUi()
    self:SetUiActive(self.TxtCount, false)
    self:SetUiActive(self.TxtName, false)
    self:SetUiActive(self.ImgQuality, false)
    self:SetUiActive(self.TxtWorldDesc, false)
    self:SetUiActive(self.TxtDescription, false)
end

function XUiTheatre6PopupRewardDetail:Refresh(data)
    self.Data = data
    if not data then
        XLog.Error("XUiTheatre6PopupRewardDetail:Refresh错误: 参数data不能为空")
        return
    end

    self:ResetUi()

    local templateId = type(data) == "number" and data or (data.TemplateId or data.Id)
    local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(templateId)

    -- 名称
    if self.TxtName and goodsShowParams.Name then
        self.TxtName.text = goodsShowParams.Name
        self:SetUiActive(self.TxtName, true)
    end

    -- 数量
    if self.TxtCount then
        local count = self.ShowNum or XGoodsCommonManager.GetGoodsCurrentCount(templateId)
        self.TxtCount.text = count or 0
        self:SetUiActive(self.TxtCount, true)
    end

    -- 图标
    if self.RImgIcon and self.RImgIcon:Exist() then
        local icon = goodsShowParams.BigIcon or goodsShowParams.Icon
        if icon and #icon > 0 then
            self.RImgIcon:SetRawImage(icon)
            self:SetUiActive(self.RImgIcon, true)
        end
    end

    -- 品质
    if self.ImgQuality and goodsShowParams.Quality then
        XUiHelper.SetQualityIcon(self, self.ImgQuality, goodsShowParams.Quality)
        self:SetUiActive(self.ImgQuality, true)
    end

    -- 世界观描述
    if self.TxtWorldDesc then
        local worldDesc = XGoodsCommonManager.GetGoodsWorldDesc(templateId)
        if worldDesc and #worldDesc > 0 then
            self.TxtWorldDesc.text = XUiHelper.ReplaceTextNewLine(worldDesc)
            self:SetUiActive(self.TxtWorldDesc, true)
        end
    end

    -- 描述
    if self.TxtDescription then
        local desc = XGoodsCommonManager.GetGoodsDescription(templateId)
        if desc and #desc > 0 then
            self.TxtDescription.text = desc
            self:SetUiActive(self.TxtDescription, true)
        end
    end
end

return XUiTheatre6PopupRewardDetail
