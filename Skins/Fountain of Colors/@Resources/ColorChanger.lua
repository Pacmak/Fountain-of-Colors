-- ColorChanger v2.4.2, A modification of ColorChanger v1.3 by Smurfier
-- LICENSE: Creative Commons Attribution-Non-Commercial-Share Alike 3.0

Colors={}
local CheckColors,DoubleCheck,BlankTable,FinalColors,ColorsIdx,VarColors,Check,Out,Mode,Measure,Meter,OldColor,Child={},{},{},{},{},{},{},{},{},{},{},{},{}
local random,concat=math.random,table.concat

function Initialize()

	-- Color option that is dynamically updated
	Option=SELF:GetOption("OptionName","BarColor")
	
	-- Iteration control variables
	Sub,Index,Limit=SELF:GetOption("Sub"),SELF:GetOption("Index"),SKIN:ParseFormula(SELF:GetNumberOption("Limit"))
	
	local MeasureName,MeterName,gsub=SELF:GetOption("MeasureName"),SELF:GetOption("MeterName"),string.gsub
	
	-- Check for leading zeros
	if Index:match("0%d") then
	
		-- Retrieve measures and meter names, store in tables
		for i=0,9 do
			Measure[i],Meter[i]=SKIN:GetMeasure((gsub(MeasureName,Sub,"0"..i))),(gsub(MeterName,Sub,"0"..i))
		end
		
		for i=10,Limit do
			Measure[i],Meter[i]=SKIN:GetMeasure((gsub(MeasureName,Sub,i))),(gsub(MeterName,Sub,i))
		end
	
	else
	
		for i=Index,Limit do
			Measure[i],Meter[i]=SKIN:GetMeasure((gsub(MeasureName,Sub,i))),(gsub(MeterName,Sub,i))
		end
		
	end
	
	-- Set this script instance as a child unless overriden by SetParent()
	Parent=0
	
	-- Set initial total number of child script instances associated with this one
	ChildTotal=0
	
	-- Set counter limit
	TransitionTime=math.floor(SKIN:ReplaceVariables("#ColorTransitionTime#")*SKIN:ReplaceVariables("#ColorUpdatesPerSecond#"))
	
	-- See local "Main" function within global "Update" function
	BlendingMultiplier=SKIN:ParseFormula(SKIN:ReplaceVariables("#ColorIntensity#"))
	
	TransparencyLower=SKIN:ParseFormula(SKIN:ReplaceVariables("#TransparencyLower#"))
	TransparencyUpper=SKIN:ParseFormula(SKIN:ReplaceVariables("#TransparencyUpper#"))
	TransparencyMultiplier=SKIN:ParseFormula(SKIN:ReplaceVariables("#TransparencyIntensity#"))
	
	-- Check if spectrum is inverted
	Invert=SKIN:ParseFormula(SKIN:ReplaceVariables("#Invert#"))
	
	-- Initialize colors based on the default playlist
	Playlist(SKIN:ReplaceVariables("#ColorPlaylist#"))
	
end

function SetParent()
	Parent=1
end

function AddChild(Name)
	
	-- Associate child script instances in other configs (must have no variant skins) with this one
	ChildTotal=ChildTotal+1
	Child[ChildTotal]=Name
	
	-- Immediately update the colors for this instance and all other childs
	Counter=TransitionTime-1
	
end

function InitColors(ColorsStr,j)

	local SplitColors,Sub,Index,Limit,find,gmatch={},Sub,Index,Limit,string.find,string.gmatch
	
	-- Initialize the tables for colors and color item options
	Colors[j],ColorsIdx[j],VarColors[j],SplitColors[j],Out[j],Mode[j]={},{},{},{},PlaylistMeasure:GetOption("Out"..j),PlaylistMeasure:GetOption("Mode"..j)
	
	-- Check output variables
	if Out[j]=="Meter" then
		Check[j]=3
	
	elseif Out[j]~="" then
		Check[j]=1
		
		-- Check if interpolation is designated in the output variable
		if find(Out[j],Sub) then
			Check[j]=2
			for i=Index,Limit do
				VarColors[j][i]={}
			end
		end
		
	else
		Check[j]=0
	end
	
	-- Check if interpolation is designated in the colors string
	if find(ColorsStr,Sub) then
		Check[j]={}
	end
	
	-- Split colors string at the "|" separator into left-hand and right-hand substrings
	local a=1
	for b in gmatch(ColorsStr,"[^%|]+") do
		SplitColors[j][a]=b
		a=a+1
	end
	
	
	-- For each left-hand and right-hand substring
	for a=1,2 do
	
		Colors[j][a],ColorsIdx[j][a]={},{}
		
		-- Split left-hand and right-hand substrings at the "," commas into individual R,G,B,(A) channels
		local b=1
		for c in gmatch(SplitColors[j][a],"[^,]+") do
		
			-- Initialize index table
			ColorsIdx[j][a][b]=c
			b=b+1
			
		end
		
		-- Check for transparency
		if ColorsIdx[j][a][4]==nil then
			ColorsIdx[j][a][4]=255
		end
		
		-- Initialize manipulated table
		for d=1,4 do
			if ColorsIdx[j][a][d]=="Random" then
				Colors[j][a][d]=random(0,255)
			else
				Colors[j][a][d]=ColorsIdx[j][a][d]
			end
		end
		 
		for k=1,Total do
		
			-- Check if left-hand or right-hand substring matches an output variable
			if SplitColors[j][a]==Out[k] then
			
				-- Set the manipulated left-hand or right-hand color table as a reference to the designated output color table
				Colors[j][a]=VarColors[k]
				
				-- Check if interpolation is designated in the substring
				if Check[k]==2 then
					Check[j][a]=1
				end
				
				break
				
			end
			
		end
		
	end

end

function Playlist(Name)

	PlaylistMeasure=SKIN:GetMeasure(Name)
	
	-- Determine total number of color items in the playlist
	local j=1
	while PlaylistMeasure:GetOption(j)~="" do
		j=j+1
	end
	Total=j-1
	
	-- Initialize color item iteration index
	Shuffle=PlaylistMeasure:GetNumberOption("Shuffle")
	if Shuffle==1 then
		Idx,Next=random(1,Total),random(1,Total)
	else
		Idx,Next=1,2
	end
	
	-- Initialize counter
	Counter=0
	
	-- Synchronize the counters of child script instances
	for k=1,ChildTotal do
		SKIN:Bang("!CommandMeasure","ScriptColorChanger","Counter=0",Child[k])
	end
	
	-- For each color item in the playlist
	for j=1,Total do
		
		-- Retrieve the color item
		local ColorsStr=SKIN:ReplaceVariables(PlaylistMeasure:GetOption(j))
		
		-- Initialize colors
		InitColors(ColorsStr,j)
		
		-- Initialize colors for child script instances
		for k=1,ChildTotal do
			SKIN:Bang("!CommandMeasure","ScriptColorChanger","InitColors(\""..ColorsStr.."\","..j..")",Child[k])
		end
		
	end
	
	
end

local function Transition(j)
	
	local ColorsIdx,random=ColorsIdx,random
	
	if Mode[j]=="RightToLeft" then
	
		for a=1,4 do

			-- Set left-hand color as right-hand color
			Colors[j][1][a]=Colors[j][2][a]
			
			-- Update the manipulated color table for child script instances
			for k=1,ChildTotal do
				SKIN:Bang("!CommandMeasure","ScriptColorChanger","Colors["..j.."][1]["..a.."]="..Colors[j][2][a],Child[k])
			end
			
			-- Set right-hand color retrieved from index
			if ColorsIdx[j][2][a]=="Random" then
				Colors[j][2][a]=random(0,255)
			else
				Colors[j][2][a]=ColorsIdx[j][2][a]
			end
			
			-- Update the manipulated color table for child script instances
			for k=1,ChildTotal do
				SKIN:Bang("!CommandMeasure","ScriptColorChanger","Colors["..j.."][2]["..a.."]="..Colors[j][2][a],Child[k])
			end
			
		end
	
	-- Color item without output variables
	elseif j==Idx and Out[j]=="" then
		
		-- Set left-hand and right-hand colors retrieved from index
		for a=1,2 do
			for b=1,4 do
				if ColorsIdx[j][a][b]=="Random" then
					Colors[j][a][b]=random(0,255)
				else
					Colors[j][a][b]=ColorsIdx[j][a][b]
				end
				
				-- Update the manipulated color table for child script instances
				for k=1,ChildTotal do
					SKIN:Bang("!CommandMeasure","ScriptColorChanger","Colors["..j.."]["..a.."]["..b.."]="..Colors[j][a][b],Child[k])
				end
				
			end
		end
		
	end
	
end

function Update()

	Counter=Counter+1
	
	-- If the counter reaches the limit and if this script instance is not a child to another one
	if Counter==TransitionTime and Parent==1 then
		
		-- Transition the colors
		for j=1,Total do
			Transition(j)
		end
		
		-- Update color item iteration index
		if Shuffle==1 then
			Idx=Next
			Next=random(1,Total)
			
		else
			Idx,Next=Idx+1,Next+1
			
			if Idx>Total then
				Idx,Next=1,2
			elseif Next>Total then
				Next=1
			end
		end
		
		-- Reset the counter
		Counter=0
		
		-- Synchronize the playlist index and counter of child script instances
		for k=1,ChildTotal do
			SKIN:Bang("!CommandMeasure","ScriptColorChanger","Idx="..Idx,Child[k])
			SKIN:Bang("!CommandMeasure","ScriptColorChanger","Next="..Next,Child[k])
			SKIN:Bang("!CommandMeasure","ScriptColorChanger","Counter=0",Child[k])
		end
		
	end
	
	local Idx,Next,Index,Limit=Idx,Next,Index,Limit
	local BlendingMultiplier,TransparencyLower,TransparencyUpper,TransparencyMultiplier=BlendingMultiplier,TransparencyLower,TransparencyUpper,TransparencyMultiplier
	local concat,Check,CheckColors,DoubleCheck,BlankTable,FinalColors,Measure,Meter,OldColor=concat,Check,CheckColors,DoubleCheck,BlankTable,FinalColors,Measure,Meter,OldColor
	
	-- For each color item in the playlist
	for j=1,Total do
		
		local BlendingMultiplier,TransparencyLower,TransparencyUpper,TransparencyMultiplier=BlendingMultiplier,TransparencyLower,TransparencyUpper,TransparencyMultiplier
		local concat,FinalColors,Measure,Meter,OldColor=concat,FinalColors,Measure,Meter,OldColor
		
		-- Color calculation and updating meter color
		local function Main(Colors1,Colors2,i)
		
			if i~=-1 then
			
				if Check[j]==2 then
				
					local c=0
					
					if Invert==0 then
						c=(i-Index)%Limit
					else
						c=(Index-i)%Limit
					end
					
					local b=Limit-c
					
					-- Calculate and store average color in the designated output color table
					for k=1,4 do
						VarColors[j][i][k]=(Colors1[k]*b+Colors2[k]*c)/Limit
					end
					
					return VarColors[j][i]
				
				else
					
					local MeasureValue=Measure[i]:GetValue()
					
					-- Check if sound is playing
					if MeasureValue~=0 then
						
						-- Color difference among bars, based on sound level
						local BlendingValue=BlendingMultiplier*MeasureValue
						
						if BlendingValue>1 then
							BlendingValue=1
						end
						
						local FinalColors,b=FinalColors,1-BlendingValue
						
						-- Calculate average color
						for k=1,3 do
							local Color=Colors1[k]*b+Colors2[k]*BlendingValue+0.5
							FinalColors[k]=Color-Color%1
						end
						
						-- Transparency based on sound level
						Colors1[4]=TransparencyLower
						Colors2[4]=TransparencyUpper
						
						local TransparencyValue=TransparencyMultiplier*MeasureValue
						if TransparencyValue>1 then
							TransparencyValue=1
						end
						
						-- Calculate transparency
						local Color=Colors1[4]*(1-TransparencyValue)+Colors2[4]*TransparencyValue+0.5
						FinalColors[4]=Color-Color%1
						
						-- Check if it's a different color
						Color=concat(FinalColors,",")
						if Color~=OldColor[i] then
							OldColor[i]=Color
							
							-- Update meter color
							SKIN:Bang("!SetOption",Meter[i],Option,Color)
							
						end
						
					end
						
				end
			
			
			elseif Mode[j]=="RightToLeft" then
				local b=TransitionTime-Counter
				
				-- Calculate average color based on transition time and store in the designated output color table
				for k=1,4 do
					VarColors[j][k]=(Colors1[k]*b+Colors2[k]*Counter)/TransitionTime
				end
			
			
			elseif j==Idx then 
				local FinalColors,b=FinalColors,TransitionTime-Counter
				
				-- Calculate average color based on transition time
				for k=1,4 do
					FinalColors[k]=(Colors1[k]*b+Colors2[k]*Counter)/TransitionTime
				end
				
				return FinalColors
			end
			
		end
		
		
		-- Color item matches iteration index, without output variables
		if j==Idx and Out[j]=="" then
			
			local CheckColors,DoubleCheck,BlankTable=CheckColors,DoubleCheck,BlankTable
			local k=Next
			
			for a=1,2 do
			
				-- Output variable is null
				if Check[j]==0 and Check[k]==0 then
					CheckColors[a]=Main(Colors[j][a],Colors[k][a],-1)
				
				-- Left-hand or right-hand substrings exist in both color items that designate interpolation
				elseif Check[j][a] and Check[k][a] then
					CheckColors[a],DoubleCheck[a]=BlankTable,1
					for i=Index,Limit do
						CheckColors[a][i]=Main(Colors[j][a][i],Colors[k][a][i],i)
					end
				
				-- Left-hand or right-hand substrings exist in the current color item that designate interpolation
				elseif Check[j][a] then
					CheckColors[a],DoubleCheck[a]=BlankTable,1
					for i=Index,Limit do
						CheckColors[a][i]=Main(Colors[j][a][i],Colors[k][a],i)
					end
				
				-- Left-hand or right-hand substrings exist in the next color item that designate interpolation
				elseif Check[k][a] then
					CheckColors[a],DoubleCheck[a]=BlankTable,1
					for i=Index,Limit do
						CheckColors[a][i]=Main(Colors[j][a],Colors[k][a][i],i)
					end
					
				end
				
			end
			
			-- Output variable is null
			if Check[j]==0 and Check[k]==0 then
				for i=Index,Limit do
					Main(CheckColors[1],CheckColors[2],i)
				end
			
			-- Both left-hand and right-hand substrings exist in a color item that designate interpolation
			elseif DoubleCheck[1] and DoubleCheck[2] then
				for i=Index,Limit do
					Main(CheckColors[1][i],CheckColors[2][i],i)
				end
			
			-- Left-hand substring exists in a color item that designate interpolation
			elseif DoubleCheck[1] then
				for i=Index,Limit do
					Main(CheckColors[1][i],CheckColors[2],i)
				end
			
			-- Right-hand substring exists in a color item that designate interpolation
			elseif DoubleCheck[2] then
				for i=Index,Limit do
					Main(CheckColors[1],CheckColors[2][i],i)
				end
			end
		
		-- Output variable is either null or is neither "Meter" nor designates interpolation
		elseif Check[j]==0 or Check[j]==1 then
			Main(Colors[j][1],Colors[j][2],-1)
		
		-- Output variable is "Meter" or designates interpolation
		elseif Check[j]==2 or Check[j]==3 then
			for i=Index,Limit do
				Main(Colors[j][1],Colors[j][2],i)
			end
		
		-- Both left-hand and right-hand substrings designate interpolation
		elseif Check[j][1] and Check[j][2] then
			for i=Index,Limit do
				Main(Colors[j][1][i],Colors[j][2][i],i)
			end
		
		-- Left-hand substring designates interpolation
		elseif Check[j][1] then
			for i=Index,Limit do
				Main(Colors[j][1][i],Colors[j][2],i)
			end
			
		-- Right-hand substring designates interpolation
		elseif Check[j][2] then
			for i=Index,Limit do
				Main(Colors[j][1],Colors[j][2][i],i)
			end
			
		end
		
	end
	
end