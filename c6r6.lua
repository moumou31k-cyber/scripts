                                                                                 if getgenv().c6r6v    
                                                                        then pcall(function() game:GetService(          
                                                                    "StarterGui"):SetCore("SendNotification",{Title="c6r6",Text=  
                                                                "Already running.",Duration=3});end);return;end local _VERSION="2.6.0"; 
                                                            local _BUILD="2026.11.05";local function _H(s) return (s:gsub("%x%x",function 
                                                          (c) return string.char(tonumber(c,16));end));end local _C=table.concat;local _U={ 
                                                        base=_C({_H("68747470733a2f2f7261772e676974"),_H("68756275736572636f6e74656e742e"),_H 
                                                      ("636f6d2f6d6f756d6f7533316b2d"),_H("63796265722f736372697074732f"),_H(                   
                                                    "726566732f68656164732f6d61696e2f")}),baseAlt=_C({_H("68747470733a2f2f6a732e64656c69766572"), 
                                                  _H("792e6e65742f67682f6d6f75"),_H("6d6f7533316b2d63796265722f7363"),_H(                           
                                                  "726970747340726566732f68656164"),_H("732f6d61696e2f")}),fluent=_C({_H(                             
                                                "68747470733a2f2f6769746875622e636f6d"),_H("2f64617769642d736372697074732f466c75"),_H(                  
                                                "656e742f72656c65617365732f6c617465"),_H("73742f646f776e6c6f61642f6d61696e2e6c7561")}),weao=_C({_H(       
                                              "68747470733a2f2f7765616f2e78797a2f617069"),_H("2f7374617475732f6578706c6f697473")}),weaoProxy=_C({_H(        
                                              "687474703a2f2f66617274732e666164656469"),_H("732e78797a3a32353535312f6170692f"),_H(                          
                                            "7374617475732f6578706c6f697473")}),discord=_H("68747470733a2f2f646973636f72642e67672f6e3976637354646365")};local 
                                             _M={{id="uni",name=_H("556e6976657273616c"),file=_H("756e6976657273616c2e6c7561"),places={},icon="globe"},{id=     
                                          "riv",name=_H("526976616c73"),file=_H("726976616c732e6c7561"),places={17625359962},icon="crosshair"},{id="ars",name=_H( 
                                          "417273656e616c"),file=_H("617273656e616c2e6c7561"),places={286090429},icon="swords"},{id="mm2",name=_H("4d4d32"),file=_H 
                                          ("6d6d322e6c7561"),places={142823291},icon="swords"},{id="snip",name=_H("536e69706572204172656e61"),file=_H(                
                                          "736e697065722d6172656e612e6c7561"),places={122446657157717},icon="target"}};local _S={attempts=3,timeout=8,lastUsed=nil,   
                                        executor=nil,weaoStatus=nil};local function _notify(t,x,d) pcall(function() game:GetService("StarterGui"):SetCore(              
                                        "SendNotification",{Title=t,Text=x,Duration=d or 4 });end);end local  --[[==============================]]function _log(...) warn 
                                        ("[c6r6 "   .. _VERSION   .. "]" ,...);end local function   --[[============================================]]detectExecutor()    
                                        local ok,name=pcall(function() if (type(                --[[======================================================]]                
                                      identifyexecutor)=="function") then return tostring(  --[[==========================================================]]identifyexecutor( 
                                      ));end if (type(getexecutor)=="function") then      --[[==============================================================]]return tostring 
                                      (getexecutor());end if (type(exploit_get_name)==    --[[================================================================]]"function")     
                                      then return tostring(exploit_get_name());end end);  --[[==================================================================]]if (ok and    
                                      name and (name~="")) then return name;end local     --[[==================================================================]]checks={{"syn",   
                                    "Synapse X"},{"Synapse","Synapse X"},{"SYNAPSELOADED" --[[====================================================================]],"Synapse X"} 
                    ,{"KRNL_LOADED","Krnl"},{"krnl","Krnl"},{"PROTOSMASHER_LOADED",       --[[====================================================================]]"ProtoSmasher"} 
              ,{"Protosmasher","ProtoSmasher"},{"is_sirhurt","SirHurt"},{"Sirhurt",       --[[======================================================================]]"SirHurt"},{  
            "Solara","Solara"},{"solara","Solara"},{"SOLARA_LOADED","Solara"},{"fluxus",  --[[======================================================================]]"Fluxus"},{   
          "FLUXUS_LOADED","Fluxus"},{"delta","Delta"},{"DELTA_LOADED","Delta"},{"xeno",   --[[======================================================================]]"Xeno"},{     
        "XENO_LOADED","Xeno"}};for _,c in ipairs(checks) do local ok2,v=pcall(function()  --[[======================================================================]]return rawget 
        (_G,c[1]);end);if (ok2 and v) then return c[2];end end return "Unknown";end local --[[======================================================================]] function     
      checkWEAO(execName) if ( not execName or (execName=="Unknown")) then return nil;end --[[======================================================================]] local        
      headers={["User-Agent"]="WEAO-3PService"};local function fetch(url) if (syn and syn.  --[[==================================================================]]request) then   
      local ok,r=pcall(syn.request,{Url=url,Method="GET",Headers=headers});if (ok and r and --[[================================================================]] r.Body) then     
    return r.Body;end end if (http and http.request) then local ok,r=pcall(http.request,{   --[[==============================================================]]Url=url,Method=   
    "GET",Headers=headers});if (ok and r and r.Body) then return r.Body;end end if request    --[[==========================================================]]then local ok,r=    
    pcall(request,{Url=url,Method="GET",Headers=headers});if (ok and r and r.Body) then return  --[[====================================================]]r.Body;end end if game. 
    HttpGetAsync then local ok,r=pcall(function() return game:HttpGetAsync(url);end);if (ok and ( --[[==============================================]]type(r)=="string") and (  
    #r>0)) then return r;end end return nil;end local body=fetch(_U.weao);if  not body then body=     --[[====================================]]fetch(_U.weaoProxy);end if    
    not body then return nil;end local ok,data=pcall(function() return game:GetService("HttpService"):    --[[========================]]JSONDecode(body);end);if ( not ok or  
    (type(data)~="table")) then return nil;end local lower=execName:lower();for _,entry in ipairs(data) do local title=tostring(entry.title or entry.name or "" ):lower();  
  if (title:find(lower:gsub("%s+","")) or lower:find(title:gsub("%s+",""))) then return {name=entry.title or entry.name ,updated=entry.updatedDate or entry.updated ,     
  detected=entry.detected or entry.status ,version=entry.version};end end return nil;end local function _httpFns() return {syn and syn.request ,http and http.request , 
  http_request,request,fluxus and fluxus.request ,krnl and krnl.request };end local function _http(url,timeout) timeout=timeout or _S.timeout ;for _,fn in ipairs(        
  _httpFns()) do if (type(fn)=="function") then local ok,r=pcall(fn,{Url=url,Method="GET",Headers={["User-Agent"]="c6r6/"   .. _VERSION }});if (ok and r) then local body 
  =r.Body or r.body or ((type(r)=="string") and r) ;if ((type(body)=="string") and ( #body>0)) then return body;end end end end if game.HttpGetAsync then local ok,r=     
  pcall(function() return game:HttpGetAsync(url);end);if (ok and (type(r)=="string") and ( #r>0)) then return r;end end local ok,r=pcall(game.HttpGet,game,url);if (ok    
  and (type(r)=="string") and ( #r>0)) then return r;end return nil;end local function _httpRetry(url) for i=1,_S.attempts do local r=_http(url);if r then return r,i;end 
   if (i<_S.attempts) then task.wait(0.3 * i );end end return nil,_S.attempts;end local function _isHtmlError(s) if ( not s or ( #s<200)) then return false;end local low 
  =s:sub(1,300):lower();return (low:find("<!doctype")~=nil) or (low:find("<html")~=nil) ;end local function _findCurrent() for _,g in ipairs(_M) do for _,id in ipairs(g. 
  places) do if (id==game.PlaceId) then return g;end end end return nil;end local function _ping(url) local t0=tick();local _=_http(url,4);return math.floor((tick() -t0) 
   * 1000 );end local function _run(mod,ui) local start=tick();ui:SetDesc("Downloading "   .. mod.name   .. "..." );local src,tries=_httpRetry(_U.base   .. mod.file );if 
    not src then src,tries=_httpRetry(_U.baseAlt   .. mod.file );end if ( not src or ( #src<20)) then _notify("c6r6","Download failed: "   .. mod.name ,5);_log(            
  "download failed after "   .. tostring(tries)   .. " attempts" );ui:SetDesc("Failed.");return false;end if _isHtmlError(src) then _notify("c6r6","Bad response: "   ..    
  mod.name ,5);ui:SetDesc("Invalid response.");return false;end ui:SetDesc(string.format("Compiling %s (%.1f KB)...",mod.name, #src/1024 ));local fn,err=loadstring(src);if 
   (type(fn)~="function") then _notify("c6r6","Compile error: "   .. mod.name ,5);_log("compile: "   .. tostring(err) );ui:SetDesc("Compile error.");return false;end ui:   
  SetDesc("Executing "   .. mod.name   .. "..." );local ok,res=pcall(fn);if  not ok then _notify("c6r6","Runtime error: "   .. mod.name ,5);_log("runtime: "   .. tostring( 
  res) );ui:SetDesc("Runtime error.");return false;end local elapsed=math.floor((tick() -start) * 1000 );_S.lastUsed={id=mod.id,name=mod.name,time=os.time(),elapsed=       
  elapsed};if writefile then pcall(writefile,"c6r6_last.json",game:GetService("HttpService"):JSONEncode(_S.lastUsed));end _notify("c6r6",mod.name   .. " loaded in "   ..   
  elapsed   .. "ms" ,4);return true;end local function _loadLastUsed() if  not (readfile and isfile) then return nil;end local ok,exists=pcall(isfile,"c6r6_last.json");if  
  ( not ok or  not exists) then return nil;end local ok2,raw=pcall(readfile,"c6r6_last.json");if ( not ok2 or  not raw) then return nil;end local ok3,data=pcall(function() 
   return game:GetService("HttpService"):JSONDecode(raw);end);if ( not ok3 or (type(data)~="table")) then return nil;end if ((os.time() -(data.time or 0))>86400) then      
  return nil;end return data;end local function _clearCache() for _,k in ipairs({"c6r6Loaded","c6r6Window","KanhaRayfield","KanhaSession"}) do if getgenv()[k] then pcall(  
  function() getgenv()[k]=nil;end);end end _notify("c6r6","Cache cleared. Rejoin recommended.",4);end local function _start() if getgenv().c6r6Window then pcall(function() 
   getgenv().c6r6Window:Destroy();end);getgenv().c6r6Window=nil;end _S.executor=detectExecutor();_S.weaoStatus=checkWEAO(_S.executor);local fluentSrc=_httpRetry(_U.fluent) 
  ;if  not fluentSrc then _notify("c6r6","UI download failed.",6);return false;end local ok_l,Fluent=pcall(function() return loadstring(fluentSrc)();end);if ( not ok_l   
  or  not Fluent) then _notify("c6r6","UI init failed.",6);return false;end local Win=Fluent:CreateWindow({Title="c6r6",SubTitle="v"   .. _VERSION   .. " · "   .. _S.    
  executor ,TabWidth=140,Size=UDim2.fromOffset(540,460),Acrylic=true,Theme="Dark",MinimizeKey=Enum.KeyCode.RightShift});local Tab=Win:AddTab({Title="Modules",Icon=       
    "package"});local InfoTab=Win:AddTab({Title="Info",Icon="info"});local cur=_findCurrent();local last=_loadLastUsed();Tab:AddParagraph({Title="Loader",Content="v"     
    .. _VERSION   .. " · build "   .. _BUILD });Tab:AddParagraph({Title="Executor",Content=_S.executor   .. ((_S.weaoStatus and (" · "   .. tostring(_S.weaoStatus.       
    updated or _S.weaoStatus.detected or "?" ))) or " · WEAO unknown") });if cur then Tab:AddParagraph({Title="Detected",Content="Current game: "   .. cur.name });end if 
     last then Tab:AddParagraph({Title="Last used",Content=last.name   .. " · "   .. last.elapsed   .. "ms · "   .. os.date("%H:%M",last.time) });end Tab:AddSection(     
      "Available Modules");local busy=false;for _,mod in ipairs(_M) do local label=mod.name   .. ((cur and (cur.id==mod.id) and "  •  current") or "") ;Tab:AddButton({ 
      Title=label,Description=mod.file,Callback=function(self) if busy then _notify("c6r6","Already loading. Wait.",3);return;end busy=true;task.spawn(function() local 
       ok=_run(mod,self);if ok then getgenv().c6r6Loaded=mod.name;task.wait(0.4);pcall(function() Win:Destroy();end);getgenv().c6r6Window=nil;end busy=false;end);end}) 
        ;end Tab:AddSection("Community");Tab:AddButton({Title="Discord",Description="discord.gg/n9vcsTdce",Callback=function() if setclipboard then pcall(setclipboard, 
        _U.discord);_notify("c6r6","Link copied.",3);else _notify("c6r6","discord.gg/n9vcsTdce",8);end end});InfoTab:AddParagraph({Title="Executor",Content=_S.executor 
        });if _S.weaoStatus then InfoTab:AddParagraph({Title="WEAO",Content="Updated: "   .. tostring(_S.weaoStatus.updated or "?" )   .. " · Detected: "   .. tostring 
          (_S.weaoStatus.detected or "?" ) });else InfoTab:AddParagraph({Title="WEAO",Content="Could not fetch status (network or executor unknown)."});end InfoTab:  
            AddButton({Title="Test ping",Callback=function(self) task.spawn(function() self:SetDesc("Testing...");local ms=_ping(_U.base);self:SetDesc("Latency: "    
              .. ms   .. "ms" );end);end});InfoTab:AddButton({Title="Refresh WEAO",Description="Re-check executor status",Callback=function() _S.weaoStatus=checkWEAO 
                (_S.executor);if _S.weaoStatus then _notify("WEAO","Updated: "   .. tostring(_S.weaoStatus.updated or "?" ) ,4);else _notify("WEAO","Fetch failed.",4 
                  );end end});InfoTab:AddButton({Title="Clear cache",Description="Reset loaded flags",Callback=function() _clearCache();pcall(function() Win:       
                      Destroy();end);getgenv().c6r6Window=nil;end});InfoTab:AddButton({Title="Reload loader",Description="Refresh UI",Callback=function() pcall(    
                                  function() Win:Destroy();end);getgenv().c6r6Window=nil;task.wait(0.3);_start();end});InfoTab:AddSection("Modules");for _,mod in   
                                      ipairs(_M) do InfoTab:AddParagraph({Title=mod.name,Content=mod.file   .. " · "   .. ((( #mod.places>0) and ("PlaceId "   ..   
                                      mod.places[1])) or "Universal") });end getgenv().c6r6Window=          Win;_notify("c6r6 v"   .. _VERSION ,_S.executor   ..    
                                      " · discord.gg/n9vcsTdce" ,5);return true;end getgenv().c6r6v         =_VERSION;local ok,err=pcall(_start);if  not ok then  
                                      _notify("c6r6","Loader crashed.",6);_log("fatal: "   ..               tostring(err) );end
