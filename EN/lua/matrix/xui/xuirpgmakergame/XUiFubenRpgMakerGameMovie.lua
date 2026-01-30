--Loading界面
local XUiFubenRpgMakerGameMovie = XLuaUiManager.Register(XLuaUi, "UiFubenRpgMakerGameMovie")

function XUiFubenRpgMakerGameMovie:OnStart(stageId)
    if not XTool.IsNumberValid(stageId) then
        return
    end

    self.TxtTitle.text = XMVCA.XRpgMakerGame:GetConfig():GetStageName(stageId)

    local desc = XMVCA.XRpgMakerGame:GetConfig():GetStageStageHint(stageId)
    self.TxtContent.text = string.gsub(desc, "\\n", "\n")
end

function XUiFubenRpgMakerGameMovie:OnEnable()
    self:PlayAnimation("ThemeEnable")
end