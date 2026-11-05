                                                                                 if getgenv().c6r6v    
                                                                        then pcall(function() game:GetService(          
                                                                    "StarterGui"):SetCore("SendNotification",{Title="c6r6",Text=  
                                                                "Already running.",Duration=3});end);return;end local v0="3.0.0";local  
                                                            v1="2026.11.05";local v2=table.concat;local function v3(v20) return (v20:gsub 
                                                          ("%x%x",function(v52) local v53=tonumber(v52,16);if v53 then return string.char(  
                                                        v53);end return "";end));end local v4={base=v2({v3("68747470733a2f2f7261772e676974"), 
                                                      v3("68756275736572636f6e74656e742e"),v3("636f6d2f6d6f756d6f7533316b2d"),v3(               
                                                    "63796265722f736372697074732f"),v3("726566732f68656164732f6d61696e2f")}),baseAlt=v2({v3(      
                                                  "68747470733a2f2f6a732e64656c69766572"),v3("792e6e65742f67682f6d6f75"),v3(                        
                                                  "6d6f7533316b2d63796265722f7363"),v3("726970747340726566732f68656164"),v3("732f6d61696e2f")}),      
                                                fluent={v2({v3("68747470733a2f2f6769746875622e636f6d"),v3("2f64617769642d736372697074732f466c75"),v3(   
                                                "656e742f72656c65617365732f6c617465"),v3("73742f646f776e6c6f61642f6d61696e2e6c7561")}),v2({v3(            
                                              "68747470733a2f2f63646e2e6a7364656c6976"),v3("65722e6e65742f67682f64617769642d73"),v3(                        
                                              "6372697074732f466c75656e74406d6173"),v3("7465722f6d61696e2e6c7561")}),v2({v3(                                
                                            "68747470733a2f2f7261772e676974687562"),v3("75736572636f6e74656e742e636f6d2f64"),v3(                              
                                            "617769642d736372697074732f466c7565"),v3("6e742f6d61737465722f6d61696e2e6c7561")})},discord=v3(                     
                                          "68747470733a2f2f646973636f72642e67672f6e3976637354646365")};local v5={{id="uni",name="Universal",file="universal.lua", 
                                          places={},icon="globe"},{id="riv",name="Rivals",file="rivals.lua",places={17625359962},icon="crosshair"},{id="ars",name=  
                                          "Arsenal",file="arsenal.lua",places={286090429},icon="swords"},{id="mm2",name="MM2",file="mm2.lua",places={142823291},icon= 
                                          "swords"},{id="snip",name="Sniper Arena",file="sniper-arena.lua",places={122446657157717},icon="target"}};local v6={        
                                        attempts=3,lastUsed=nil,executor=nil};local function v7(v21,v22,v23) pcall(function() game:GetService("StarterGui"):SetCore(    
                                        "SendNotification",{Title=v21,Text=v22,Duration=v23 or 4 });end);end  --[[==============================]]local function v8(...)  
                                        warn("[c6r6 "   .. v0   .. "]" ,...);end local function v9( --[[============================================]]) local v24,v25=    
                                        pcall(function() if (type(identifyexecutor)=="function" --[[======================================================]]) then return   
                                      tostring(identifyexecutor());end if (type(getexecutor --[[==========================================================]])=="function")    
                                      then return tostring(getexecutor());end end);if (   --[[==============================================================]]v24 and v25 and 
                                       (v25~="")) then return v25;end for v54,v55 in      --[[================================================================]]ipairs({{"syn", 
                                      "Synapse X"},{"KRNL_LOADED","Krnl"},{"krnl","Krnl"} --[[==================================================================]],{            
                                      "PROTOSMASHER_LOADED","ProtoSmasher"},{"is_sirhurt" --[[==================================================================]],"SirHurt"},{     
                                    "Solara","Solara"},{"SOLARA_LOADED","Solara"},{       --[[====================================================================]]"fluxus",     
                    "Fluxus"},{"FLUXUS_LOADED","Fluxus"},{"delta","Delta"},{              --[[====================================================================]]"DELTA_LOADED", 
              "Delta"},{"xeno","Xeno"},{"XENO_LOADED","Xeno"}}) do local v56,v57=pcall(   --[[======================================================================]]function()    
            return rawget(_G,v55[1]);end);if (v56 and v57) then return v55[2];end end     --[[======================================================================]]return        
          "Unknown";end local function v10(v26) local v27={};if ((type(syn)=="table") and --[[======================================================================]] (type(syn.   
        request)=="function")) then table.insert(v27,syn.request);end if ((type(http)==   --[[======================================================================]]"table") and  
        (type(http.request)=="function")) then table.insert(v27,http.request);end if (    --[[======================================================================]]type(         
      http_request)=="function") then table.insert(v27,http_request);end if (type(request --[[======================================================================]])=="function" 
      ) then table.insert(v27,request);end if ((type(fluxus)=="table") and (type(fluxus.    --[[==================================================================]]request)==      
      "function")) then table.insert(v27,fluxus.request);end if ((type(krnl)=="table") and  --[[================================================================]](type(krnl.       
    request)=="function")) then table.insert(v27,krnl.request);end for v58,v59 in ipairs(   --[[==============================================================]]v27) do local v60 
    ,v61=pcall(v59,{Url=v26,Method="GET",Headers={["User-Agent"]="c6r6/"   .. v0 }});if (v60  --[[==========================================================]]and v61) then local 
     v82=v61.Body or v61.body or ((type(v61)=="string") and v61) ;if ((type(v82)=="string") and --[[====================================================]] ( #v82>0)) then return 
     v82;end end end if game.HttpGetAsync then local v74,v75=pcall(function() return game:        --[[==============================================]]HttpGetAsync(v26);end);if 
     (v74 and (type(v75)=="string") and ( #v75>0)) then return v75;end end local v28,v29=pcall(game.  --[[====================================]]HttpGet,game,v26);if (v28 and 
     (type(v29)=="string") and ( #v29>0)) then return v29;end return nil;end local function v11(v30) for  --[[========================]]v62=1,v6.attempts do local v63=v10(   
    v30);if v63 then return v63,v62;end if (v62<v6.attempts) then task.wait(0.3 * v62 );end end return nil,v6.attempts;end local function v12(v31) if ( not v31 or ( #v31<  
  200)) then return true;end local v32=v31:sub(1,300):lower();if (v32:find("<!doctype") or v32:find("<html") or v32:find("404")) then return true;end return false;end    
  local function v13() local v33=((type(getgenv)=="function") and select(2,pcall(getgenv))) or _G ;local v34=(v33 and rawget(v33,"Fluent")) or rawget(_G,"Fluent") ;if  
  (v34 and (type(v34)=="table") and v34.CreateWindow) then return v34;end for v64,v65 in ipairs(v4.fluent) do local v66=v11(v65);if (v66 and  not v12(v66)) then local    
  v83,v84=pcall(function() return loadstring(v66)();end);if (v83 and (type(v84)=="table") and v84.CreateWindow) then pcall(function() getgenv().Fluent=v84;end);pcall(    
  function() _G.Fluent=v84;end);v8("Fluent loaded from "   .. v65:sub(1,40)   .. "..." );return v84;end end end return nil;end local function v14() for v67,v68 in ipairs 
  (v5) do for v76,v77 in ipairs(v68.places) do if (v77==game.PlaceId) then return v68;end end end return nil;end local function v15(v35,v36) local v37=tick();v36:SetDesc 
  ("Downloading "   .. v35.name   .. "..." );local v38=v11(v4.base   .. v35.file );if  not v38 then v38=v11(v4.baseAlt   .. v35.file );end if ( not v38 or v12(v38)) then 
   v7("c6r6","Download failed: "   .. v35.name ,5);v36:SetDesc("Failed.");return false;end v36:SetDesc(string.format("Compiling %s (%.1f KB)...",v35.name, #v38/1024 ));  
  local v39,v40=loadstring(v38);if (type(v39)~="function") then v7("c6r6","Compile error: "   .. v35.name ,5);v36:SetDesc("Compile: "   .. tostring(v40):sub(1,40) );     
  return false;end v36:SetDesc("Executing "   .. v35.name   .. "..." );local v41,v42=pcall(v39);if  not v41 then v7("c6r6","Runtime error: "   .. v35.name ,5);v8(        
  "runtime: "   .. tostring(v42) );v36:SetDesc("Runtime: "   .. tostring(v42):sub(1,40) );return false;end local v43=math.floor((tick() -v37) * 1000 );v7("c6r6",v35.name 
     .. " loaded in "   .. v43   .. "ms" ,4);return true;end local function v16() if getgenv().c6r6Window then pcall(function() getgenv().c6r6Window:Destroy();end);getgenv 
  ().c6r6Window=nil;end v6.executor=v9();local v45=v13();if  not v45 then v7("c6r6","Fluent failed. Check HttpGet.",8);v8(                                                  
  "Fluent could not load. Executor HttpGet blocked?");return false;end local v46=v45:CreateWindow({Title="c6r6",SubTitle="v"   .. v0   .. " · "   .. v6.executor ,TabWidth= 
  140,Size=UDim2.fromOffset(540,460),Acrylic=true,Theme="Dark",MinimizeKey=Enum.KeyCode.RightShift});local v47=v46:AddTab({Title="Modules",Icon="package"});local v48=v46:  
  AddTab({Title="Info",Icon="info"});local v49=v14();v47:AddParagraph({Title="Loader",Content="v"   .. v0   .. " · build "   .. v1 });v47:AddParagraph({Title="Executor",   
  Content=v6.executor});if v49 then v47:AddParagraph({Title="Detected",Content="Current game: "   .. v49.name });end v47:AddSection("Available Modules");local v50=false;   
  for v69,v70 in ipairs(v5) do local v71=v70.name   .. ((v49 and (v49.id==v70.id) and "  •  current") or "") ;v47:AddButton({Title=v71,Description=v70.file,Callback=       
  function(v79) if v50 then v7("c6r6","Already loading.",3);return;end v50=true;task.spawn(function() local v85=v15(v70,v79);if v85 then getgenv().c6r6Loaded=v70.name;task 
  .wait(0.4);pcall(function() v46:Destroy();end);getgenv().c6r6Window=nil;end v50=false;end);end});end v47:AddSection("Community");v47:AddButton({Title="Discord",          
  Description="discord.gg/n9vcsTdce",Callback=function() if setclipboard then pcall(setclipboard,v4.discord);v7("c6r6","Link copied.",3);else v7("c6r6",v4.discord,8);end   
  end});v48:AddParagraph({Title="Executor",Content=v6.executor});v48:AddButton({Title="Clear cache",Callback=function() for v80,v81 in ipairs({"c6r6Loaded","c6r6Window",   
  "Fluent","KanhaRayfield","KanhaSession"}) do if getgenv()[v81] then pcall(function() getgenv()[v81]=nil;end);end end v7("c6r6","Cache cleared.",4);pcall(function() v46:  
  Destroy();end);getgenv().c6r6Window=nil;end});v48:AddButton({Title="Reload loader",Callback=function() pcall(function() v46:Destroy();end);getgenv().c6r6Window=nil;task. 
  wait(0.3);v16();end});getgenv().c6r6Window=v46;v7("c6r6 v"   .. v0 ,v6.executor   .. " · discord.gg/n9vcsTdce" ,5);return true;end getgenv().c6r6v=v0;local v18,v19=    
  pcall(v16);if  not v18 then v7("c6r6","Loader crashed.",6);v8("fatal: "   .. tostring(v19) );end
