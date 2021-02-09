local AKPL = (file.Read("akpl.dat") != nil && util.JSONToTable(util.Decompress(file.Read("akpl.dat"))) || {})
 
// internal calculations
local Col = {[-1]=Color(150,150,150,255), [0]=Color(255,0,0,255), [1]=Color(255,165,0,255), [2]=Color(0,255,0,255)}
AKPL.LP = LocalPlayer()
function AKPL.CalculateRenderPos(self)
	local pos = self:GetPos() pos:Add(self:GetForward() * self:OBBMaxs().x) pos:Add(self:GetRight() * self:OBBMaxs().y) pos:Add(self:GetUp() * self:OBBMaxs().z) pos:Add(self:GetForward() * 0.15) return pos
end
function AKPL.CalculateRenderAng(self)
	local ang = self:GetAngles() ang:RotateAroundAxis(ang:Right(), -90) ang:RotateAroundAxis(ang:Up(), 90) return ang
end
function AKPL.CalculateKeypadCursorPos(ply, ent)
	if !ply:IsValid() then return end local tr = util.TraceLine( { start = ply:EyePos(), endpos = ply:EyePos() + ply:GetAimVector() * 65, filter = ply } ) if !tr.Entity or tr.Entity ~= ent then return 0, 0 end local scale = ent.Scale || 0.02 if !scale then return 0, 0 end local pos, ang = AKPL.CalculateRenderPos(ent), AKPL.CalculateRenderAng(ent) if !pos or !ang then return 0, 0 end local normal = ent:GetForward() local intersection = util.IntersectRayWithPlane(ply:EyePos(), ply:GetAimVector(), pos, normal) if !intersection then return 0, 0 end local diff = pos - intersection local x = diff:Dot( -ang:Forward() ) / scale local y = diff:Dot( -ang:Right() ) / scale return x, y
end
local elements = {{x = 0.075, y = 0.04, w = 0.85, h = 0.25,},{x = 0.075, y = 0.04 + 0.25 + 0.03, w = 0.85 / 2 - 0.04 / 2 + 0.05, h = 0.125, text = "ABORT",},{x = 0.5 + 0.04 / 2 + 0.05, y = 0.04 + 0.25 + 0.03, w = 0.85 / 2 - 0.04 / 2 - 0.05, h = 0.125, text = "OK",}} do for i = 1, 9 do local column = (i - 1) % 3 local row = math.floor((i - 1) / 3) local element = {x = 0.075 + (0.3 * column), y = 0.175 + 0.25 + 0.05 + ((0.5 / 3) * row), w = 0.25, h = 0.13, text = tostring(i), } elements[#elements + 1] = element end end
function AKPL.GetHoveredElement(ply, ent)
	local scale = ent.Scale || 0.02 local w, h = (ent:OBBMaxs().y - ent:OBBMins().y) / scale , (ent:OBBMaxs().z - ent:OBBMins().z) / scale local x, y = AKPL.CalculateKeypadCursorPos(ply, ent) for _, element in ipairs(elements) do local element_x = w * element.x local element_y = h * element.y local element_w = w * element.w local element_h = h * element.h if  element_x < x and element_x + element_w > x and element_y < y and element_y + element_h > y then return element end end
end
// internal calculations
 
AKPL.KeypadCache = {}
AKPL.KeypadOwners = AKPL.KeypadOwners || {}
AKPL.AwaitingResponse = {}
AKPL.ShouldUnlockKeypad = {}
 
AKPL.InsertKey = function(i, p, v)
    if(!tonumber(i) || !tonumber(p) || !tonumber(v)) then return i end
    local val = i:ToTable()
    val[p] = v
    return table.concat(val)
end
 
AKPL.ResetLog = function(ent, validated)
    if(!validated) then
        AKPL.KeypadCache[ent]["Code"] = "0000"
    end
    AKPL.KeypadCache[ent]["Validated"] = validated && 2 || -1
    AKPL.AwaitingResponse[ent] = nil
    AKPL.ShouldUnlockKeypad[ent] = nil
end
 
AKPL.ValidCode = function(code)
    return (tonumber(code) != 0 && code:StartWith(code:Replace("0", "")))
end
 
AKPL.ValidateCode = function(ent, status)
    if(status == ent.Status_Granted) then
        local code = AKPL.KeypadCache[ent]["Code"]
        if (AKPL.ValidCode(code)) then
            AKPL.KeypadCache[ent]["Validated"] = 1
            if(AKPL.AwaitingResponse[ent]) then
                AKPL.AwaitingResponse[ent][1] = -1
            end
        end
    elseif(status == ent.Status_Denied) then
        if(AKPL.KeypadCache[ent]["Validated"] <= 0 || (AKPL.KeypadCache[ent]["Validated"] == 1 && AKPL.AwaitingResponse[ent] && AKPL.AwaitingResponse[ent][3] == 3)) then
            AKPL.ResetLog(ent)
        end
    end
end
 
AKPL.Logger = function(ent, name, old, new)
    local Handler = {
        ["Text"] = function(ent, old, new)
            if(AKPL.AwaitingResponse[ent]) then
                if(AKPL.AwaitingResponse[ent][3] == 1) then 
                    if((new:len() - old:len()) == AKPL.AwaitingResponse[ent][1]) then
                        if(!AKPL.AwaitingResponse[ent][2]) then
                            AKPL.AwaitingResponse[ent][3] = 3
                        else
                            AKPL.AwaitingResponse[ent][3] = 2
                        end
                    else
                        AKPL.AwaitingResponse[ent] = nil
                    end
                elseif(AKPL.AwaitingResponse[ent][3] == 2) then
                    if((new:len() - old:len()) == tostring(AKPL.AwaitingResponse[ent][2]):len()) then
                        AKPL.AwaitingResponse[ent][3] = 3
                    else
                        AKPL.AwaitingResponse[ent] = nil
                    end
                end
            return end
            if(new == "" && AKPL.KeypadCache[ent]["Validated"] <= 0) && AKPL.ValidCode(AKPL.KeypadCache[ent]["Code"]) then return AKPL.ResetLog(ent) end
            if(!ent:GetSecure()) then
                for k, v in ipairs(string.ToTable(new)) do
                    AKPL.KeypadCache[ent]["Code"] = AKPL.InsertKey(AKPL.KeypadCache[ent]["Code"], k, v)
                end
            else
                for k, v in ipairs(ents.FindInSphere(ent:GetPos(), 120)) do
                    if(!v:IsPlayer()) then continue end
                    local element = AKPL.GetHoveredElement(v, ent)
                    if(element) then
                        if(tonumber(element.text)) then
                            AKPL.KeypadCache[ent]["Code"] = AKPL.InsertKey(AKPL.KeypadCache[ent]["Code"], new:len(), tonumber(element.text))
                        end
                    else
                        continue
                    end
                end
            end
            if(AKPL.KeypadCache[ent]["Validated"] != -1 && AKPL.GetEntOwner(ent)) then
                AKPL.KeypadOwners[AKPL.GetEntOwner(ent)][AKPL.RenderText(AKPL.KeypadCache[ent]["Code"])] = AKPL.KeypadCache[ent]["Validated"]
            end
        end,
        ["Status"] = function(ent, old, new)
            AKPL.ValidateCode(ent, tonumber(new))
        end,
    }
    if(Handler[name]) then
        Handler[name](ent, old, new)
    end
end
 
AKPL.GetPlayerByName = function(name)
    if(!name || name == "") then return false end
	name = string.lower(name)
	for _,v in ipairs(player.GetHumans()) do
		if(string.find(string.lower(v:Name()),name,1,true) != nil)
			then return v
		end
    end
    return false
end
 
AKPL.GetEntOwner = function(ent)
    local ply = AKPL.GetPlayerByName(ent:GetNWString("FounderName"))
    return ply && ply:AccountID() || ply
end
 
AKPL.RegisterCallback = function(ent)
    if(!AKPL.KeypadCache[ent] && isfunction(ent.GetStatus) && isfunction(ent.GetText)) then
        ent:NetworkVarNotify("Text", AKPL.Logger)
        ent:NetworkVarNotify("Status", AKPL.Logger)
        AKPL.KeypadCache[ent] = {["Code"]="0000", ["Validated"]=-1}
        local sid = AKPL.GetEntOwner(ent)
        if(sid == false) then return end
        if(!AKPL.KeypadOwners[sid]) then
            AKPL.KeypadOwners[sid] = {}
        end
        AKPL.KeypadOwners[sid][#AKPL.KeypadOwners[sid]+1] = ent
    end
end
 
AKPL.SendCommand = function(ent, c, d)
    if(ent:GetStatus() != ent.Status_None || AKPL.LP:EyePos():Distance(ent:GetPos()) >= 120 || util.NetworkStringToID(ent:GetClass()) == 0) then return end
    net.Start(ent:GetClass())
    net.WriteEntity(ent)
    net.WriteUInt(c, 4)
    if(tonumber(d)) then
        net.WriteUInt(tonumber(d), 8)
    end
    net.SendToServer()
end
 
AKPL.TestCodes = function(ent)
    if(AKPL.AwaitingResponse[ent] && AKPL.AwaitingResponse[ent][3] != 1) then
        if(AKPL.AwaitingResponse[ent][1] == -1) then
            AKPL.ResetLog(ent, true)
        elseif(AKPL.AwaitingResponse[ent][3] == 2) then
            AKPL.SendCommand(ent, 0, AKPL.AwaitingResponse[ent][2])
        elseif(AKPL.AwaitingResponse[ent][3] == 3) then
            AKPL.SendCommand(ent, 1)
        end
    else
        if(AKPL.KeypadCache[ent]["Validated"] == 2) then
            AKPL.ShouldUnlockKeypad[ent] = true
        end
        if(AKPL.KeypadCache[ent]["Validated"] != 1 && !AKPL.ShouldUnlockKeypad[ent]) then return end
        if(ent:GetText() != "") then
            return AKPL.SendCommand(ent, 2)
        end
        local code = AKPL.KeypadCache[ent]["Code"]:Replace("0",""):ToTable()
        local split = tonumber(table.concat({code[1], code[2], code[3]}))
        if(!split) then return end
        if(split < 2^8) then
            AKPL.AwaitingResponse[ent] = {3, code[4], 1}
        else
            split = tonumber(table.concat({code[1], code[2]}))
            AKPL.AwaitingResponse[ent] = {2, tonumber(table.concat({code[3], code[4]})), 1}
        end
        AKPL.SendCommand(ent, 0, split)
    end
end
 
hook.Add("Tick", "AKPL", function()
    file.Write("akpl.dat", util.Compress(util.TableToJSON(AKPL)))
    for k, v in ipairs(ents.FindByClass("keypad*")) do
        AKPL.RegisterCallback(v)
        -- AKPL.TestCodes(v) --this only works if the first 3 digits of a keypad code are under 255, TODO account for keypad cooldowns
    end
end)
 
AKPL.RenderText = function(str)
    if(tonumber(str) == 0) then return "Unknown" elseif(AKPL.ValidCode(str)) then return str:Replace("0", "") else return str:Replace("0", "*") end
end
AKPL.Gradient = Material( "gui/gradient" )
 
hook.Add("HUDPaint","AKPL", function()
	local tr = AKPL.LP:GetEyeTrace().Entity
	if IsValid(tr) and AKPL.KeypadCache[tr] then
		local text = AKPL.RenderText(AKPL.KeypadCache[tr]["Code"])
		local color = Col[AKPL.KeypadCache[tr]["Validated"]]
        surface.SetDrawColor( Color(0,0,50,255) )
        surface.SetMaterial( AKPL.Gradient )
        surface.DrawTexturedRect( ScrW() / 2 + 57, ScrH() / 2 - 7, 50, 15 )
        draw.SimpleText(text, "DermaDefault", ScrW() / 2 + 60, ScrH() / 2, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end
 
    for k, v in pairs(AKPL.KeypadCache) do
        if(IsValid(k) && k != tr) then
            local pos = k:GetPos():ToScreen()
            if(pos.visible) then
                local text = AKPL.RenderText(v["Code"])
		        local color = Col[v["Validated"]]
                surface.SetDrawColor( Color(0,0,50,255) )
                surface.SetMaterial( AKPL.Gradient )
                surface.DrawTexturedRect( pos.x, pos.y, 50, 15 )
                draw.SimpleText( text, "DermaDefault", pos.x + 5, pos.y + 6, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end
    end
end)