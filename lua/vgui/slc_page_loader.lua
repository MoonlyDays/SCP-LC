local PANEL = {}
function PANEL:Init()
    self:SetSkin("scplc")
    self.CachedErrors = {}
end

function PANEL:DrawError(err, w, h)
    if not self.Handler then return end
    local msg = self.CachedErrors[err]
    if not msg then
        local txt = self.Handler.Lang.Errors[err]
        if not txt then return end
        msg = markup.Parse(txt, w * 0.333)
        self.CachedErrors[err] = msg
    end

    msg:Draw(w * 0.5, h * 0.33, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 255, TEXT_ALIGN_CENTER)
end

function PANEL:PerformLayout(w, h)
    if not self.Handler or not self.ActivePage or not self.PageData or self.Loading then return end
    local obj = self.Handler:GetPage(self.ActivePage)
    if obj and obj.Layout then obj:Layout(w, h, self.PageData, self) end
end

function PANEL:Paint(w, h)
    if self.Banned then
        self:DrawError("BANNED", w, h)
    elseif self.Restricted then
        self:DrawError("RESTRICTED", w, h)
    elseif self.Failed then
        self:DrawError("FAILED", w, h)
    elseif self.Loading then
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawLoading(w * 0.5, h * 0.5, h * 0.05, h * 0.005)
    end
end

local translate_error = {
    to = "Request timed out"
}

function PANEL:LoadPage(id, req_data)
    if not isstring(id) or not self.Handler or self.Loading or self.PreventLoad then return end
    local obj = self.Handler:GetPage(id)
    if obj and self.ActivePage == id and obj.DisableRefresh then return end
    self.PageData = nil
    self.ActivePage = id
    self:Clear()
    if not obj then
        self.Failed = true
        print("Page load failed", id, "Page not found")
        return
    end

    self.Loading = true
    self.Failed = false
    self.Banned = false
    self.Restricted = false
    local p = obj:Load(self, req_data)
    if p == false then
        self.Loading = false
        self.Failed = true
    elseif ispromise(p) then
        p:Then(function(data)
            if not IsValid(self) then return end
            self.Loading = false
            self.PageData = data
            self.Banned = not not data.__banned
            self.Restricted = not not data.__restrict
            --self:InvalidateLayout( true )
            self:InvalidateLayout()
        end):Catch(function(err)
            if not IsValid(self) then return end
            self.Loading = false
            self.Failed = true
            print("Page load failed", id, err and translate_error[err] or err)
        end)
    else
        self.Loading = false
        self.PageData = p
        self.Banned = p and not not p.__banned
        self.Restricted = p and not not p.__restrict
        --self:InvalidateLayout(true)
        self:InvalidateLayout()
    end
end

function PANEL:Reload(data)
    if not self.ActivePage then return end
    self:LoadPage(self.ActivePage, data)
end

vgui.Register("SLCPageLoader", PANEL, "DPanel")
