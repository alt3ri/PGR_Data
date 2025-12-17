---@class XUiBigWorldTip : XBigWorldUi
local XUiBigWorldTip = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldTip")

function XUiBigWorldTip:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBigWorldTip:OnStart(data, title)
    if title then
        self.TxtTitle.text = title
        if self._CopyTitle then
            self._CopyTitle.text = title
        end
    end
    self._Data = data
end

function XUiBigWorldTip:OnEnable()
    self:UpdateView()
end

function XUiBigWorldTip:InitUi()
    local txt = self.Transform:Find("SafeAreaContentPane/PanelTitle/Image2/TxtTitle")
    if txt then
        --这个文本不会显示，仅用于动画控制蓝色底的长度
        self._CopyTitle = txt:GetComponent("Text")
    end
end

function XUiBigWorldTip:InitCb()
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
end

function XUiBigWorldTip:UpdateView()
    if not self._Data then
        XLog.Error("道具参数错误!")
        self:Close()
    end
    local data = self._Data
    self:ResetUi()
    if type(data) == "number" then
        self._TemplateId = data
    else
        if data.IsTempItemData then
            self:SetTempGoodsInfo(data)
            return
        end
        self.TemplateId = data.TemplateId and data.TemplateId or data.Id
    end
    if self.TemplateId == XDataCenter.ItemManager.ItemId.AndroidHongKa or
            self.TemplateId == XDataCenter.ItemManager.ItemId.IosHongKa
    then
        self.TemplateId = XDataCenter.ItemManager.ItemId.HongKa
    end
    
    self:SetGoodsInfo(data)
end

function XUiBigWorldTip:SetTempGoodsInfo(data)
    -- 名称
    if self.TxtName and data.Name then
        self.TxtName.text = data.Name
        self.TxtName.gameObject:SetActiveEx(true)
    end
    -- 数量
    if self.TxtCount and data.Count then
        -- data.Count 可能会与 XUiGridCommon 冲突
        self.TxtCount.text = data.OwnCount or data.Count
        self.TxtCount.gameObject:SetActiveEx(true)
        self.CountTitle.gameObject:SetActiveEx(true)
    end
    -- 图标
    if self.RImgIcon and self.RImgIcon:Exist() and data.Icon then
        self.RImgIcon:SetRawImage(data.Icon)
        self.RImgIcon.gameObject:SetActiveEx(true)
    end
    -- 品质底图
    if self.ImgQuality and data.Quality then
        XUiHelper.SetQualityIcon(self, self.ImgQuality, data.Quality)
        self.ImgQuality.gameObject:SetActiveEx(true)
    end
    -- 世界观描述
    if self.TxtWorldDesc and data.WorldDesc then
        self.TxtWorldDesc.text = data.WorldDesc
        self.ImgQuality.gameObject:SetActiveEx(true)
    end
    -- 描述
    if self.TxtDescription and data.Description then
        self.TxtDescription.text = data.Description
        self.TxtDescription.gameObject:SetActiveEx(true)
    end
end

function XUiBigWorldTip:SetGoodsInfo(data)
    --不显示道具数量
    local tipNotShowCount = false
    
    local params = XMVCA.XBigWorldService:GetGoodsShowParamsByTemplateId(self.TemplateId)

    -- 表情包和聊天框不显示数量
    if params.RewardType == XRewardManager.XRewardType.ChatEmoji
            or params.RewardType == XRewardManager.XRewardType.ChatBoard then
        tipNotShowCount = true
    end

    -- 名称
    if self.TxtName and params.Name then
        self.TxtName.text = params.Name
        self.TxtName.gameObject:SetActiveEx(true)
    end

    -- 数量
    if self.TxtCount then
        if tipNotShowCount then
            self.TxtCount.gameObject:SetActiveEx(false)
            self.CountTitle.gameObject:SetActiveEx(false)
        else
            local count = nil
            if self.ShowNum then
                count = self.ShowNum
            else
                count = XGoodsCommonManager.GetGoodsCurrentCount(self.TemplateId)
            end
            self.TxtCount.text = count or 0
            self.TxtCount.gameObject:SetActiveEx(true)
            self.CountTitle.gameObject:SetActiveEx(true)
        end
    end

    -- 图标
    if self.RImgIcon and self.RImgIcon:Exist() then
        local icon = params.Icon

        if params.BigIcon then
            icon = params.BigIcon
        end

        if icon and #icon > 0 then
            self.RImgIcon:SetRawImage(icon)
            self.RImgIcon.gameObject:SetActiveEx(true)
        end

        if self.ImgBlackBg then
            self.ImgBlackBg.gameObject:SetActiveEx(false)
        end
    end

    -- 特效
    if self.HeadIconEffect then
        local effect = params.Effect
        local config = XHeadPortraitConfigs.GetHeadPortraitsCfg()[params.TemplateId]
        if effect and config.Type == XHeadPortraitConfigs.HeadType.HeadPortrait then
            self.HeadIconEffect.gameObject:LoadPrefab(effect)
            self.HeadIconEffect.gameObject:SetActiveEx(true)
            self.HeadIconEffect:Init()
        else
            self.HeadIconEffect.gameObject:SetActiveEx(false)
        end
    end

    if self.HeadFrameEffect then
        local effect = params.Effect
        local config = XHeadPortraitConfigs.GetHeadPortraitsCfg()[params.TemplateId]
        if effect and config.Type == XHeadPortraitConfigs.HeadType.HeadFrame then
            self.HeadFrameEffect.gameObject:LoadPrefab(effect)
            self.HeadFrameEffect.gameObject:SetActiveEx(true)
            self.HeadFrameEffect:Init()
        else
            self.HeadFrameEffect.gameObject:SetActiveEx(false)
        end
    end

    -- 品质底图
    if self.ImgQuality and params.Quality then
        XUiHelper.SetQualityIcon(self, self.ImgQuality, params.Quality)
        self.ImgQuality.gameObject:SetActiveEx(false)
    end

    -- 世界观描述
    if self.TxtWorldDesc then
        local worldDesc = XGoodsCommonManager.GetGoodsWorldDesc(self.TemplateId)

        ---黑岩超难关藏品特殊处理
        if self.TemplateId == XEnumConst.SpecialHandling.DEADCollectiblesId then
            worldDesc = XUiHelper.ReplaceUnicodeSpace(worldDesc)
        end

        if worldDesc and #worldDesc then
            self.TxtWorldDesc.text = worldDesc
            self.TxtWorldDesc.gameObject:SetActiveEx(true)
        end
    end

    -- 描述
    if self.TxtDescription then
        local desc = XGoodsCommonManager.GetGoodsDescription(self.TemplateId)
        if desc and #desc > 0 then
            self.TxtDescription.text = desc
            self.TxtDescription.gameObject:SetActiveEx(true)
        end
    end
end

function XUiBigWorldTip:ResetUi()
    self.TxtCount.gameObject:SetActiveEx(false)
    self.TxtName.gameObject:SetActiveEx(false)
    self.ImgQuality.gameObject:SetActiveEx(false)
    self.TxtWorldDesc.gameObject:SetActiveEx(false)
    self.TxtDescription.gameObject:SetActiveEx(false)
    self.BtnGet.gameObject:SetActiveEx(false)
    self.CountTitle.gameObject:SetActiveEx(false)
    self.BtnAction.gameObject:SetActiveEx(false)
end

function XUiBigWorldTip:OnBtnBackClick()
    self:Close()
end