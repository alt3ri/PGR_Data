local XDrawGroupBtnBaseEntity = require("XEntity/XDrawMianButton/XDrawGroupBtnBaseEntity")
---@class XExtraDrawGroupBtnEntity:XDrawGroupBtnBaseEntity
local XExtraDrawGroupBtnEntity = XClass(XDrawGroupBtnBaseEntity, "XExtraDrawGroupBtnEntity")

function XExtraDrawGroupBtnEntity:Ctor()
    self.OptionKey = ""
    self.GroupId = 0
    self.GroupSubtype = 0
    self.IsExtraOption = false
end

function XExtraDrawGroupBtnEntity:UpdateData(optionData)
    self.OptionKey = optionData.OptionKey
    self.GroupId = optionData.GroupId
    self.GroupSubtype = optionData.GroupSubtype
    self.IsExtraOption = optionData.IsExtraOption or false

    -- 从 groupInfo 获取基础数据
    local groupInfo = XDataCenter.DrawManager.GetDrawGroupInfoByGroupId(self.GroupId)
    if groupInfo then
        self.Id = groupInfo.Id
        self.Banner = groupInfo.Banner
        self.UiPrefab = groupInfo.UiPrefab
        self.UiBackGround = groupInfo.UiBackGround
        -- ExtraOption 使用 optionData.Tag（来自 DrawExtraTagGroup 配置），而不是 groupInfo.Tag
        self.Tag = optionData.Tag or groupInfo.Tag
        self.BannerBeginTime = optionData.BannerBeginTime or groupInfo.BannerBeginTime or 0
        self.BannerEndTime = optionData.BannerEndTime or groupInfo.BannerEndTime or 0
        self.BottomTimes = groupInfo.BottomTimes
        self.MaxBottomTimes = groupInfo.MaxBottomTimes
        self.SwitchDrawIdCount = groupInfo.SwitchDrawIdCount or 0
        self.MaxSwitchDrawIdCount = groupInfo.MaxSwitchDrawIdCount or 0
        self.Order = optionData.Priority or groupInfo.Order or 0
        self.UseItemId = groupInfo.UseItemId
    end

    self.UseItemIdList = {}
    table.insert(self.UseItemIdList, XDataCenter.ItemManager.ItemId.FreeGem)
    if self.UseItemId then
        table.insert(self.UseItemIdList, self.UseItemId)
    end
end

function XExtraDrawGroupBtnEntity:GetRuleType()
    return XDrawConfigs.RuleType.Normal
end

function XExtraDrawGroupBtnEntity:GetName()
    -- ExtraOption 使用配置中的 Name
    local option = XDataCenter.DrawManager.GetDisplayOptionByKey(self.OptionKey)
    if option and option.Name then
        return option.Name
    end
    -- 回退到 group 配置
    local cfg = XDrawConfigs.GetDrawGroupRuleById(self.Id)
    return cfg and cfg.TitleCN or ""
end

function XExtraDrawGroupBtnEntity:GetRareRank()
    local cfg = XDrawConfigs.GetDrawGroupRuleById(self.Id)
    return cfg and cfg.RareRank or XDrawConfigs.RareRank.A
end

function XExtraDrawGroupBtnEntity:GetGroupBtnBg()
    local cfg = XDrawConfigs.GetDrawGroupRuleById(self.Id)
    return cfg and cfg.GroupBtnBg or ""
end

function XExtraDrawGroupBtnEntity:GetNewHandBottomCount()
    local cfg = XDrawConfigs.GetDrawGroupRuleById(self.Id)
    return cfg and cfg.NewHandBottomCount or 0
end

function XExtraDrawGroupBtnEntity:GetDrawRules()
    local cfg = XDrawConfigs.GetDrawGroupRuleById(self.Id)
    return cfg and cfg.DrawRules or ""
end

function XExtraDrawGroupBtnEntity:GetGroupType()
    local cfg = XDrawConfigs.GetDrawGroupRuleById(self.Id)
    return cfg and (cfg.SpecialBottomMin > 0 and
                   cfg.SpecialBottomMax > 0 and
                   XDrawConfigs.GroupType.Destiny or XDrawConfigs.GroupType.Normal)
                   or XDrawConfigs.GroupType.Normal
end

function XExtraDrawGroupBtnEntity:GetBottomText()
    local bottomText = CS.XTextManager.GetText("NewDrawMainBottomText")
    local space = not XOverseaManager.IsENRegion() and "" or " "
    local cfg = XDrawConfigs.GetDrawGroupRuleById(self.Id)
    if cfg and cfg.SpecialBottomMin > 0 and cfg.SpecialBottomMax > 0 then
        return string.format("%s%s%d/%d~%d", bottomText, space, self.BottomTimes, cfg.SpecialBottomMin, cfg.SpecialBottomMax)
    else
        return string.format("%s%s%d/%d", bottomText, space, self.BottomTimes, self.MaxBottomTimes)
    end
end

function XExtraDrawGroupBtnEntity:GetSwitchText()
    if self.MaxSwitchDrawIdCount > 0 then
        local count = self.MaxSwitchDrawIdCount - self.SwitchDrawIdCount
        return count > 0 and CS.XTextManager.GetText("DrawBannerSelectCountText", count)
               or CS.XTextManager.GetText("DrawBannerSelectNotCountText")
    end
    return ""
end

function XExtraDrawGroupBtnEntity:GoDraw(cb)
    -- 获取当前 option 的 drawInfo
    local drawInfo = XDataCenter.DrawManager.GetUseDrawInfoByOptionKey(self.OptionKey)
    if not drawInfo then
        local option = XDataCenter.DrawManager.GetDisplayOptionByKey(self.OptionKey)
        if option and #option.DrawIdList > 0 then
            drawInfo = XDataCenter.DrawManager.GetDrawInfo(option.DrawIdList[1])
        end
    end

    if drawInfo then
        if cb then cb() end
        -- 打开抽卡页
        XDataCenter.DrawManager.GetDrawInfoList(self:GetId(), function()
            XLuaUiManager.Open(self:GetUiPrefab(), self:GetId(), function()
                end, self:GetUiBackGround())
        end)
    else
        XLog.Warning(string.format("[XExtraDrawGroupBtnEntity] GoDraw failed: no drawInfo for optionKey=%s", self.OptionKey))
    end
end

function XExtraDrawGroupBtnEntity:IsShowTag()
    local IsShowNewTag = false

    if self.BannerBeginTime > 0 then
        -- 使用 option 维度的新标签检查
        if XDataCenter.DrawManager.IsShowNewTagForOption(self.BannerBeginTime, XDrawConfigs.RuleType.Normal, self.OptionKey) then
            IsShowNewTag = true
        end
    end
    return IsShowNewTag
end

function XExtraDrawGroupBtnEntity:IsShowFreeTip()
    -- 检查是否有免费券（基于 group）
    return XDataCenter.DrawManager.CheckHasFreeTicket(self.GroupId)
end

function XExtraDrawGroupBtnEntity:GetOptionKey()
    return self.OptionKey
end

return XExtraDrawGroupBtnEntity