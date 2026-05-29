local XMovieActionAutoSkip = XClass(XMovieActionBase, "XMovieActionAutoSkip")

function XMovieActionAutoSkip:OnInit(actionData)
    local params = actionData.Params
    self.ManSkipActionId = XMVCA.XMovie:ParamToNumber(params[1]) -- 男指挥官跳转ActionId
    self.WomanSkipActionId = XMVCA.XMovie:ParamToNumber(params[2]) -- 女指挥官跳转ActionId
    self.SkipActionId = XMVCA.XMovie:ParamToNumber(params[3]) -- 无论性别直接跳转ActionId
    self.SecrecyActionId = XMVCA.XMovie:ParamToNumber(params[4]) -- 第三性别跳转ActionId
end

function XMovieActionAutoSkip:OnEnter()
    self:GenSelectedActionId()
end

-- 生成跳转ActionId
function XMovieActionAutoSkip:GenSelectedActionId()
    -- 如果配置了无论性别直接跳转的ActionId，则优先使用该ActionId
    if self.SkipActionId ~= 0 then
        self.SelectedActionId = self.SkipActionId
        return
    end

    local gender = XPlayer.GetShowGender()

    -- 若玩家选择的性别既不是男性也不是女性，则尝试获取大世界指挥官DIY的当前性别
    if gender ~= XEnumConst.PLAYER.GENDER_TYPE.MAN and gender ~= XEnumConst.PLAYER.GENDER_TYPE.WOMAN then
        local bigWorldGender = XMVCA.XBigWorldCommanderDIY:GetCurrentGender()
        if bigWorldGender == XEnumConst.PLAYER.GENDER_TYPE.MAN or bigWorldGender == XEnumConst.PLAYER.GENDER_TYPE.WOMAN then
            gender = bigWorldGender
        end
    end

    -- 如果配置了第三性别跳转的ActionId，且玩家选择的性别为保密，则使用第三性别跳转的ActionId
    if gender == XEnumConst.PLAYER.GENDER_TYPE.SECRECY and self.SecrecyActionId ~= 0 then
        self.SelectedActionId = self.SecrecyActionId
        return

    -- 如果配置了女指挥官跳转的ActionId，且玩家选择的性别为女性，则使用女指挥官跳转的ActionId
    elseif gender == XEnumConst.PLAYER.GENDER_TYPE.WOMAN and self.WomanSkipActionId ~= 0 then
        self.SelectedActionId = self.WomanSkipActionId
        return
    end

    -- 默认跳转男指挥官跳转的ActionId
    self.SelectedActionId = self.ManSkipActionId
end

function XMovieActionAutoSkip:GetSelectedActionId()
    if not self.SelectedActionId then
        self:GenSelectedActionId()
    end
    return self.SelectedActionId or 0
end

return XMovieActionAutoSkip