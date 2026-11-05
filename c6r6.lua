                                                                                 if getgenv().c6r6v    
                                                                        then local v71=0;while true do if (v71==0) then 
                                                                     pcall(function() game:GetService("StarterGui"):SetCore(      
                                                                "SendNotification",{Title="c6r6",Text="Already running.",Duration=704 - 
                                                            (376 + 325) });end);return;end end end local v0="2.5.0";local v1="2026.11.05" 
                                                          ;local function v2(v22) return (v22:gsub("%x%x",function(v72) return string.char( 
                                                        tonumber(v72,16));end));end local v3=table.concat;local v4={base=v3({v2(              
                                                      "68747470733a2f2f7261772e676974"),v2("68756275736572636f6e74656e742e"),v2(                
                                                    "636f6d2f6d6f756d6f7533316b2d"),v2("63796265722f736372697074732f"),v2(                        
                                                  "726566732f68656164732f6d61696e2f")}),baseAlt=v3({v2("68747470733a2f2f6a732e64656c69766572"),v2(  
                                                  "792e6e65742f67682f6d6f75"),v2("6d6f7533316b2d63796265722f7363"),v2(                                
                                                "726970747340726566732f68656164"),v2("732f6d61696e2f")}),fluent=v3({v2(                                 
                                                "68747470733a2f2f6769746875622e636f6d"),v2("2f64617769642d736372697074732f466c75"),v2(                    
                                              "656e742f72656c65617365732f6c617465"),v2("73742f646f776e6c6f61642f6d61696e2e6c7561")}),discord=v2(            
                                              "68747470733a2f2f646973636f72642e67672f6e3976637354646365")};local v5={{id="uni",name=v2("556e6976657273616c" 
                                            ),file=v2("756e6976657273616c2e6c7561"),places={},icon="globe"},{id="riv",name=v2("526976616c73"),file=v2(        
                                            "726976616c732e6c7561"),places={17625360354 -(232 + 160) },icon="crosshair"},{id="ars",name=v2("417273656e616c"),   
                                          file=v2("617273656e616c2e6c7561"),places={286091706 -(37 + 1240) },icon="swords"},{id="mm2",name=v2("4d4d32"),file=v2(  
                                          "6d6d322e6c7561"),places={142823291},icon="swords"},{id="snip",name=v2("536e69706572204172656e61"),file=v2(               
                                          "736e697065722d6172656e612e6c7561"),places={122446657157717},icon="target"}};local v6={attempts=4 -1 ,timeout=2 + 6 ,       
                                          lastUsed=nil};local function v7(v23,v24,v25) pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{    
                                        Title=v23,Text=v24,Duration=v25 or (5 -1) });end);end local function v8(...) warn("[c6r6 "   .. v0   .. "]" ,...);end local v9= 
                                        {syn and syn.request ,http and http.request ,http_request,request,    --[[==============================]]fluxus and fluxus.      
                                        request ,krnl and krnl.request };local function v10(v26,v27 --[[============================================]]) local v28=1850 -( 
                                        1409 + 441) ;local v29;local v30;while true do if (v28  --[[======================================================]]==(719 -(15 +   
                                      703))) then if game.HttpGetAsync then local v96=0 + 0 --[[==========================================================]] ;local v97;local 
                                       v98;local v99;while true do if (v96==(439 -(262 +  --[[==============================================================]]176))) then v99 
                                      =nil;while true do if (v97==(1721 -(345 + 1376)))   --[[================================================================]]then v98,v99=   
                                      pcall(function() return game:HttpGetAsync(v26);end) --[[==================================================================]];if (v98 and  
                                      (type(v99)=="string") and ( #v99>0)) then return    --[[==================================================================]]v99;end break;    
                                    end end break;end if (v96==(688 -(198 + 490))) then   --[[====================================================================]]v97=0 -0 ;v98 
                    =nil;v96=2 -1 ;end end end v29,v30=pcall(game.HttpGet,game,v26);v28=  --[[====================================================================]]1208 -(696 +    
              510) ;end if (v28==(3 -1)) then local v77=1262 -(1091 + 171) ;while true do --[[======================================================================]] if (v77==0)  
            then if (v29 and (type(v30)=="string") and ( #v30>0)) then return v30;end     --[[======================================================================]]return nil;   
          end end end if (v28==0) then v27=v27 or v6.timeout ;for v82,v83 in ipairs(v9)   --[[======================================================================]]do if (type(  
        v83)=="function") then local v110=0;local v111;local v112;while true do if (v110  --[[======================================================================]]==(0 + 0))    
        then v111,v112=pcall(v83,{Url=v26,Method="GET",Headers={["User-Agent"]="c6r6/"    --[[======================================================================]].. v0 }});if  
      (v111 and v112) then local v124=0;local v125;while true do if (v124==0) then v125=  --[[======================================================================]]v112.Body or  
      v112.body or ((type(v112)=="string") and v112) ;if ((type(v125)=="string") and ( #    --[[==================================================================]]v125>(0 -0)))   
      then return v125;end break;end end end break;end end end end v28=3 -2 ;end end end    --[[================================================================]]local function    
    v11(v31) local v32=0;while true do if (v32==(374 -(123 + 251))) then local v78=0 -0 ;   --[[==============================================================]]while true do if  
    (v78==(698 -(208 + 490))) then for v116=1,v6.attempts do local v117=0;local v118;while    --[[==========================================================]]true do if (v117==( 
    0 + 0)) then v118=v10(v31);if v118 then return v118,v116;end v117=1 + 0 ;end if (v117==(837 --[[====================================================]] -(660 + 176))) then if 
     (v116<v6.attempts) then task.wait((0.3 + 0) * v116 );end break;end end end return nil,v6.    --[[==============================================]]attempts;end end end end  
    end local function v12(v33) local v34=202 -(14 + 188) ;local v35;while true do local v73=675 -(   --[[====================================]]534 + 141) ;while true do if  
    (v73==(0 + 0)) then if ((1 + 0)==v34) then return (v35:find("<!doctype")~=nil) or (v35:find("<html")  --[[========================]]~=nil) ;end if ((0 + 0)==v34) then if 
     ( not v33 or ( #v33<200)) then return false;end v35=v33:sub(1,630 -330 ):lower();v34=1 -0 ;end break;end end end end local function v13() local v36=0 -0 ;while true   
  do if (v36==(0 + 0)) then for v84,v85 in ipairs(v5) do for v100,v101 in ipairs(v85.places) do if (v101==game.PlaceId) then return v85;end end end return nil;end end    
  end local function v14(v37) local v38=0 + 0 ;local v39;local v40;while true do if (v38==(397 -(115 + 281))) then return math.floor((tick() -v39) * (2326 -1326) );end 
   if (v38==0) then local v79=0 + 0 ;while true do if (v79==(2 -1)) then v38=3 -2 ;break;end if (v79==0) then v39=tick();v40=v10(v37,4);v79=868 -(550 + 317) ;end end end 
   end end local function v15(v41,v42) local v43=0 -0 ;local v44;local v45;local v46;local v47;local v48;local v49;local v50;local v51;while true do if (v43==1) then if  
    not v45 then v45,v46=v11(v4.baseAlt   .. v41.file );end if ( not v45 or ( #v45<(28 -8))) then v7("c6r6","Download failed: "   .. v41.name ,13 -8 );v8(                
  "download failed after "   .. tostring(v46)   .. " attempts" );v42:SetDesc("Failed.");return false;end if v12(v45) then local v102=0;while true do if (v102==(286 -(134 
   + 151))) then return false;end if (v102==(1665 -(970 + 695))) then v7("c6r6","Bad response: "   .. v41.name ,9 -4 );v42:SetDesc("Invalid response.");v102=1;end end    
  end v43=1992 -(582 + 1408) ;end if (v43==(13 -9)) then v51=math.floor((tick() -v44) * (1258 -258) );v6.lastUsed={id=v41.id,name=v41.name,time=os.time(),elapsed=v51};if 
   writefile then pcall(writefile,"c6r6_last.json",game:GetService("HttpService"):JSONEncode(v6.lastUsed));end v43=18 -13 ;end if (v43==3) then v42:SetDesc("Executing "  
     .. v41.name   .. "..." );v49,v50=pcall(v47);if  not v49 then local v103=1824 -(1195 + 629) ;while true do local v113=0 -0 ;while true do if ((241 -(187 + 54))==v113 
  ) then if (v103==(781 -(162 + 618))) then v42:SetDesc("Runtime error.");return false;end if (v103==(0 + 0)) then v7("c6r6","Runtime error: "   .. v41.name ,5);v8(      
  "runtime: "   .. tostring(v50) );v103=1 + 0 ;end break;end end end end v43=4;end if (v43==(3 -1)) then v42:SetDesc(string.format("Compiling %s (%.1f KB)...",v41.name, #  
  v45/(1721 -697) ));v47,v48=loadstring(v45);if (type(v47)~="function") then v7("c6r6","Compile error: "   .. v41.name ,1 + 4 );v8("compile: "   .. tostring(v48) );v42:    
  SetDesc("Compile error.");return false;end v43=1639 -(1373 + 263) ;end if (v43==0) then v44=tick();v42:SetDesc("Downloading "   .. v41.name   .. "..." );v45,v46=v11(v4.  
  base   .. v41.file );v43=1001 -(451 + 549) ;end if (v43==(2 + 3)) then v7("c6r6",v41.name   .. " loaded in "   .. v51   .. "ms" ,4);return true;end end end local         
  function v16() local v52=0 -0 ;local v53;local v54;local v55;local v56;local v57;local v58;while true do local v74=0 -0 ;while true do if (v74==0) then if (v52==1) then  
  if ( not v53 or  not v54) then return nil;end v55,v56=pcall(readfile,"c6r6_last.json");v52=2;end if (v52==4) then return v58;end v74=1385 -(746 + 638) ;end if (v74==1)   
  then if ((1 + 1)==v52) then if ( not v55 or  not v56) then return nil;end v57,v58=pcall(function() return game:GetService("HttpService"):JSONDecode(v56);end);v52=4 -1 ;  
  end if (0==v52) then if  not (readfile and isfile) then return nil;end v53,v54=pcall(isfile,"c6r6_last.json");v52=342 -(218 + 123) ;end v74=1583 -(1535 + 46) ;end if (   
  v74==(2 + 0)) then if (v52==(1 + 2)) then if ( not v57 or (type(v58)~="table")) then return nil;end if ((os.time() -(v58.time or (560 -(306 + 254))))>(5349 + 81051))     
  then return nil;end v52=4;end break;end end end end local function v17() local v59=0;local v60;while true do if (v59==0) then v60={"c6r6Loaded","c6r6Window",             
  "KanhaRayfield","KanhaSession"};for v86,v87 in ipairs(v60) do if getgenv()[v87] then pcall(function() getgenv()[v87]=nil;end);end end v59=1;end if (v59==1) then v7(      
  "c6r6","Cache cleared. Rejoin recommended.",9 -5 );break;end end end local function v18() local v61=603 -(268 + 335) ;local v62;local v63;local v64;local v65;local v66;  
  local v67;local v68;local v69;local v70;while true do if (v61==(296 -(60 + 230))) then v67:AddParagraph({Title="Server ping",Content="Click below to test connectivity."} 
  );v67:AddButton({Title="Test ping",Callback=function(v88) task.spawn(function() local v104=0;local v105;while true do if (v104==(573 -(426 + 146))) then v88:SetDesc(   
  "Latency: "   .. v105   .. "ms" );break;end if (v104==(0 + 0)) then v88:SetDesc("Testing...");v105=v14(v4.base);v104=1457 -(282 + 1174) ;end end end);end});v67:        
  AddButton({Title="Clear cache",Description="Reset loaded flags and reload UI",Callback=function() local v89=0;while true do if (v89==0) then v17();pcall(function() v65 
    :Destroy();end);v89=812 -(569 + 242) ;end if (v89==(2 -1)) then getgenv().c6r6Window=nil;break;end end end});v61=1 + 6 ;end if (v61==(1029 -(706 + 318))) then for    
    v90,v91 in ipairs(v5) do local v92=v91.name   .. ((v68 and (v68.id==v91.id) and "  •  current") or "") ;v66:AddButton({Title=v92,Description=v91.file,Callback=       
    function(v106) local v107=0;while true do if (v107==(1251 -(721 + 530))) then if v70 then v7("c6r6","Already loading. Wait.",3);return;end v70=true;v107=1272 -(945 + 
     326) ;end if ((2 -1)==v107) then task.spawn(function() local v122=0 + 0 ;local v123;while true do if (v122==1) then v70=false;break;end if (v122==0) then v123=v15(  
      v91,v106);if v123 then local v126=0;while true do if (v126==(700 -(271 + 429))) then getgenv().c6r6Loaded=v91.name;task.wait(0.4 + 0 );v126=1501 -(1408 + 92) ;   
      end if ((1087 -(461 + 625))==v126) then pcall(function() v65:Destroy();end);getgenv().c6r6Window=nil;break;end end end v122=1289 -(993 + 295) ;end end end);break 
      ;end end end});end v66:AddSection("Community");v66:AddButton({Title="Discord",Description="discord.gg/n9vcsTdce",Callback=function() if setclipboard then local   
        v114=0 + 0 ;local v115;while true do if (v114==(1171 -(418 + 753))) then v115=0 + 0 ;while true do if ((0 + 0)==v115) then pcall(setclipboard,v4.discord);v7(   
        "c6r6","Link copied.",1 + 2 );break;end end break;end end else v7("c6r6","discord.gg/n9vcsTdce",8);end end});v61=2 + 4 ;end if (v61==3) then v69=v16();v66:     
        AddParagraph({Title="Loader",Content="Version "   .. v0   .. " · build "   .. v1 });if v68 then v66:AddParagraph({Title="Detected",Content="Current game: "     
          .. v68.name });end v61=4;end if (v61==(530 -(406 + 123))) then v63,v64=pcall(function() return loadstring(v62)();end);if ( not v63 or  not v64) then v7(    
            "c6r6","UI init failed.",6);return false;end v65=v64:CreateWindow({Title="c6r6",SubTitle="v"   .. v0   .. " · discord.gg/n9vcsTdce" ,TabWidth=1909 -(1749 
               + 20) ,Size=UDim2.fromOffset(540,105 + 335 ),Acrylic=true,Theme="Dark",MinimizeKey=Enum.KeyCode.RightShift});v61=2;end if (v61==(1326 -(1249 + 73)))   
                then if v69 then v66:AddParagraph({Title="Last used",Content=v69.name   .. " · "   .. v69.elapsed   .. "ms · "   .. os.date("%H:%M",v69.time) });end  
                  v66:AddSection("Available Modules");v70=false;v61=2 + 3 ;end if (2==v61) then v66=v65:AddTab({Title="Modules",Icon="package"});v67=v65:AddTab({   
                      Title="Info",Icon="info"});v68=v13();v61=1148 -(466 + 679) ;end if (v61==0) then if getgenv().c6r6Window then pcall(function() getgenv().     
                                  c6r6Window:Destroy();end);getgenv().c6r6Window=nil;end v62=v11(v4.fluent);if  not v62 then local v109=0 -0 ;while true do if (    
                                      v109==(0 -0)) then v7("c6r6","UI download failed.",6);return false;end end end v61=1901 -(106 + 1794) ;end if ((3 + 4)==v61)  
                                      then v67:AddButton({Title="Reload loader",Description=                "Refresh the loader window",Callback=function() local   
                                      v93=0 + 0 ;while true do if (v93==(2 -1)) then task.wait(0.3          -0 );v18();break;end if (v93==0) then pcall(function( 
                                      ) v65:Destroy();end);getgenv().c6r6Window=nil;v93=1;end end           end});v67:AddSection("Modules disponibles");for v94,  
                                      v95 in ipairs(v5) do v67:AddParagraph({Title=v95.name,Content         =v95.file   .. " · "   .. ((( #v95.places>(114 -(4 +  
                                      110))) and ("PlaceId "   .. v95.places[585 -(57 + 527) ])) or            "Universal (any game)") });end v61=1435 -(41 +     
                                      1386) ;end if (v61==8) then getgenv().c6r6Window=v65;v7(                "c6r6 v"   .. v0 ,"Loaded. discord.gg/n9vcsTdce",5) 
                                      ;return true;end end end getgenv().c6r6v=v0;local v20,v21=              pcall(v18);if  not v20 then local v75=103 -(17 +  
                                        86) ;local v76;while true do if (0==v75) then v76=0 + 0 ;             while true do if (v76==(0 -0)) then v7("c6r6",    
                                        "Loader crashed.",17 -11 );v8("fatal: "   .. tostring(v21)              );break;end end break;end end end
