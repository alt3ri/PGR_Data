-- 选择关卡界面规则解说面板
local XUiFingerGuessSSExplainPanel = XClass(nil, "XUiFingerGuessSSExplainPanel")
local CHINESE_NUMBER = {}
local INITIAL_TEXT = "Text initial complete."
--================
--构造函数
--================
function XUiFingerGuessSSExplainPanel:Ctor(gameObject, rootUi)
    self.RootUi = rootUi

    CHINESE_NUMBER = {
        [0] = "",
        [1] = CS.XTextManager.GetText("One"),
        [2] = CS.XTextManager.GetText("Two"),
        [3] = CS.XTextManager.GetText("Three"),
        [4] = CS.XTextManager.GetText("Four"),
        [5] = CS.XTextManager.GetText("Five"),
        [6] = CS.XTextManager.GetText("Six"),
        [7] = CS.XTextManager.GetText("Seven"),
        [8] = CS.XTextManager.GetText("Eight"),
        [9] = CS.XTextManager.GetText("Nine"),
        [10] = CS.XTextManager.GetText("Ten"),
        [11] = CS.XTextManager.GetText("Eleven"),
        [12] = CS.XTextManager.GetText("Twelve")
    }
    XTool.InitUiObjectByUi(self, gameObject)
    self:InitPanel()
    
end
--================
--初始化面板
--================
function XUiFingerGuessSSExplainPanel:InitPanel()
    self:SetTxtTitle(0, 0)
    self.TxtDescription.text = INITIAL_TEXT
end
--================
--选择关卡时
--================
function XUiFingerGuessSSExplainPanel:OnStageSelected()
    self:SetTxtTitle(self.RootUi.StageSelected:GetRoundNum(), self.RootUi.StageSelected:GetWinScore())
    self.TxtDescription.text = self.RootUi.StageSelected:GetDescription()
end
--================
--设置规则Title
--================
function XUiFingerGuessSSExplainPanel:SetTxtTitle(total, winPoint)
    self.TxtTitle.text = CS.XTextManager.GetText("FingerGuessingRuleTitle", CHINESE_NUMBER[total] or total, CHINESE_NUMBER[winPoint] or winPoint)
end

return XUiFingerGuessSSExplainPanel