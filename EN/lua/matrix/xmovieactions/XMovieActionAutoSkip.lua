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
    local OpenMovieThirdGender = XMVCA.XMovie:GetOpenMovieThirdGender()
    --OpenMovieThirdGender配置1第三性别功能开启，且玩家选择的性别为保密时
    local gender = XPlayer.GetShowGender()
    if OpenMovieThirdGender and gender == XEnumConst.PLAYER.GENDER_TYPE.SECRECY then
        --如果段落剧情差分中，只配置了男女两种性别，没有保密性别的文本差分配置
        if self.SecrecyActionId == 0 and self.ManSkipActionId ~=0 and self.WomanSkipActionId ~=0 then
            self.SelectedActionId = self.ManSkipActionId
            return
        end
    end

    if self.SkipActionId ~= 0 then
        self.SelectedActionId = self.SkipActionId
        return
    end

    if gender == XEnumConst.PLAYER.GENDER_TYPE.MAN then
        self.SelectedActionId = self.ManSkipActionId
    elseif gender == XEnumConst.PLAYER.GENDER_TYPE.SECRECY then
        self.SelectedActionId = self.SecrecyActionId
    else
        self.SelectedActionId = self.WomanSkipActionId
    end
end

function XMovieActionAutoSkip:GetSelectedActionId()
    if not self.SelectedActionId then
        self:GenSelectedActionId()
    end
    return self.SelectedActionId or 0
end

return XMovieActionAutoSkip