AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include('shared.lua')

function ENT:Initialize()

	self.Throttle = 0
	self.Active = false
	self.IsMaster = true
	self.GearLink = {}
	self.GearRope = {}

	self.LastCheck = 0
	self.LastThink = 0
	self.Mass = 0
	self.PhysMass = 0
	self.MassRatio = 1
	self.Legal = true
	self.CanUpdate = true
	
	--####################
	self.TqAdd = 0
	self.MaxRpmAdd = 0
	self.LimitRpmAdd = 0
	self.FlywheelMass = 0
	self.WeightKg = 0
	self.idle = 0
	self.DisableCut = 0
	self.CutMode = 0
	self.CutValue = 0
	self.CutRpm = 0
	--####################
	
	self.Inputs = Wire_CreateInputs( self.Entity, { "Active", "Throttle", "TqAdd", "MaxRpmAdd", "LimitRpmAdd", "FlywheelMass", "Idle", "DisableCut"} )
	self.Outputs = WireLib.CreateSpecialOutputs( self.Entity, { "RPM", "Torque", "Power", "Entity" , "Mass" , "Physical Mass" }, { "NORMAL" ,"NORMAL" ,"NORMAL" , "ENTITY" , "NORMAL" , "NORMAL" } )
	Wire_TriggerOutput(self.Entity, "Entity", self.Entity)
	self.WireDebugName = "ACF Engine4"

end  

function MakeACF_Engine4(Owner, Pos, Angle, Id, Data1, Data2, Data3, Data4, Data5, Data6)

	if not Owner:CheckLimit("_acf_misc") then return false end

	local Engine4 = ents.Create("ACF_Engine4")
	local List = list.Get("ACFEnts")
	local Classes = list.Get("ACFClasses")
	if not Engine4:IsValid() then return false end
	Engine4:SetAngles(Angle)
	Engine4:SetPos(Pos)
	Engine4:Spawn()

	Engine4:SetPlayer(Owner)
	Engine4.Owner = Owner
	Engine4.Id = Id
	Engine4.Model = List["Mobility2"][Id]["model"]
	Engine4.SoundPath = List["Mobility2"][Id]["sound"]
	Engine4.Weight = List["Mobility2"][Id]["weight"]
	--##################################################################################
	Engine4.iselec = List["Mobility2"][Id]["iselec"]
	Engine4.elecpower = List["Mobility2"][Id]["elecpower"]
	Engine4.FlywheelOverride = List["Mobility2"][Id]["flywheeloverride"]
	
	Engine4.ModTable = List["Mobility2"][Id]["modtable"]
		Engine4.ModTable[1] = Data1
		Engine4.ModTable[2] = Data2
		Engine4.ModTable[3] = Data3
		Engine4.ModTable[4] = Data4
		Engine4.ModTable[5] = Data5
		Engine4.ModTable[6] = Data6
			
		Engine4.PeakTorque = Data1
		Engine4.IdleRPM = Data2
		Engine4.PeakMinRPM = Data3
		Engine4.LimitRPM = Data5
		if(Data4 <= Data5 ) then 
			Engine4.PeakMaxRPM = Data4
		elseif(Data4 > Data5 ) then
			Engine4.PeakMaxRPM = Data5
		end
		Engine4.FlywheelMass2 = Data6
		Engine4.CutValue = Engine4.LimitRPM / 40
		Engine4.CutRpm = Engine4.LimitRPM - 100
			
		Engine4.PeakTorque2 = Data1
		Engine4.PeakTorque3 = Data1
		Engine4.Idling = Data2
		Engine4.PeakMaxRPM2 = Data4
		Engine4.LimitRPM2 = Data5
		Engine4.FlywheelMass3 = Data6
			
		Engine4.Inertia = Engine4.FlywheelMass2*(3.1416)^2
	--##################################################################################
	
	Engine4.FlyRPM = 0
	Engine4:SetModel( Engine4.Model )	
	Engine4.Sound = nil
	Engine4.SoundPitch = 1
	Engine4.RPM = {}

	Engine4:PhysicsInit( SOLID_VPHYSICS )      	
	Engine4:SetMoveType( MOVETYPE_VPHYSICS )     	
	Engine4:SetSolid( SOLID_VPHYSICS )

	Engine4.Out = Engine4:WorldToLocal(Engine4:GetAttachment(Engine4:LookupAttachment( "driveshaft" )).Pos)

	local phys = Engine4:GetPhysicsObject()  	
	if (phys:IsValid()) then 
		phys:SetMass( Engine4.Weight ) 
	end

	Engine4:SetNetworkedBeamString("Type",List["Mobility2"][Id]["name"])
	Engine4:SetNetworkedBeamInt("Torque",Engine4.PeakTorque)	
	-- add in the variable to check if its an electric motor
	if (Engine4.iselec == true )then
		Engine4:SetNetworkedBeamInt("Power",Engine4.elecpower) -- add in the value from the elecpower
	else
		Engine4:SetNetworkedBeamInt("Power",math.floor(Engine4.PeakTorque * Engine4.PeakMaxRPM / 9548.8))
	end
	Engine4:SetNetworkedBeamInt("MinRPM",Engine4.PeakMinRPM)
	Engine4:SetNetworkedBeamInt("MaxRPM",Engine4.PeakMaxRPM)
	Engine4:SetNetworkedBeamInt("LimitRPM",Engine4.LimitRPM)
	--####################################################
	Engine4:SetNetworkedBeamInt("FlywheelMass2",Engine4.FlywheelMass3*1000)
	Engine4:SetNetworkedBeamInt("Idle",Engine4.IdleRPM)
	Engine4:SetNetworkedBeamInt("Weight",Engine4.Weight)
	Engine4:SetNetworkedBeamInt("Rpm",Engine4.FlyRPM)
	--####################################################

	undo.Create("ACF Engine4")
		undo.AddEntity( Engine4 )
		undo.SetPlayer( Owner )
	undo.Finish()

	Owner:AddCount("_acf_engine4", Engine4)
	Owner:AddCleanup( "acfmenu", Engine4 )

	return Engine4
end
list.Set( "ACFCvars", "acf_engine4" , {"id", "data1", "data2", "data3", "data4", "data5", "data6"} )
duplicator.RegisterEntityClass("acf_engine4", MakeACF_Engine4, "Pos", "Angle", "Id", "PeakTorque", "IdleRPM", "PeakMinRPM", "PeakMaxRPM", "LimitRPM", "FlywheelMass2", "FlywheelMass3")

function ENT:Update( ArgsTable )	--That table is the player data, as sorted in the ACFCvars above, with player who shot, and pos and angle of the tool trace inserted at the start

	local Feedback = "Engine updated"
	if self.Active then
		Feedback = "Please turn off the engine before updating it"
	return Feedback end
	if ( ArgsTable[1] != self.Owner ) then --Argtable[1] is the player that shot the tool
		Feedback = "You don't own that engine !"
	return Feedback end

	local Id = ArgsTable[4]	--Argtable[4] is the engine ID
	local List = list.Get("ACFEnts")

	if ( List["Mobility2"][Id]["model"] != self.Model ) then --Make sure the models are the sames before doing a changeover
		Feedback = "The new engine needs to have the same model as the old one !"
	return Feedback end
	
	if self.Id != Id then
		self.Id = Id
		self.SoundPath = List["Mobility2"][Id]["sound"]
		self.Weight = List["Mobility2"][Id]["weight"]
		self.iselec = List["Mobility2"][Id]["iselec"] -- is the engine electric?
		self.elecpower = List["Mobility2"][Id]["elecpower"] -- how much power does it output
		self.FlywheelOverride = List["Mobility2"][Id]["flywheeloverride"] -- how much power does it output
	end
	
	self.ModTable[1] = ArgsTable[5]
	self.ModTable[2] = ArgsTable[6]
	self.ModTable[3] = ArgsTable[7]
	self.ModTable[4] = ArgsTable[8]
	self.ModTable[5] = ArgsTable[9]
	self.ModTable[6] = ArgsTable[10]
		
	self.PeakTorque = ArgsTable[5]
	self.IdleRPM = ArgsTable[6]
	self.PeakMaxRPM = ArgsTable[8]
	if(ArgsTable[7] <= ArgsTable[8] ) then 
		self.PeakMinRPM = ArgsTable[7]
	elseif(ArgsTable[7] > ArgsTable[8] ) then
		self.PeakMinRPM = ArgsTable[8]
	end
	self.LimitRPM = ArgsTable[9]
	self.FlywheelMass2 = ArgsTable[10]
	self.CutValue = self.LimitRPM / 40
	self.CutRpm = self.LimitRPM - 100
		
	self.PeakTorque2 = ArgsTable[5]
	self.PeakTorque3 = ArgsTable[5]
	self.Idling = ArgsTable[6]
	self.PeakMaxRPM2 = ArgsTable[8]
	self.LimitRPM2 = ArgsTable[9]
	self.FlywheelMass3 = ArgsTable[10]

	self.Inertia = self.FlywheelMass2*(3.1416)^2
	--##################################################################################
	
	self:SetModel( self.Model )	
	self:SetSolid( SOLID_VPHYSICS )
	self.Out = self:WorldToLocal(self:GetAttachment(self:LookupAttachment( "driveshaft" )).Pos)

	local phys = self:GetPhysicsObject()  	
	if (phys:IsValid()) then 
		phys:SetMass( self.Weight ) 
	end

	self:SetNetworkedBeamString("Type",List["Mobility2"][Id]["name"])
	self:SetNetworkedBeamInt("Torque",self.PeakTorque)
	-- add in the variable to check if its an electric motor
	if (self.iselec == true)  then
		self:SetNetworkedBeamInt("Power",self.elecpower) -- add in the value from the elecpower
	else
		self:SetNetworkedBeamInt("Power",math.floor(self.PeakTorque * self.PeakMaxRPM / 9548.8))
	end

	self:SetNetworkedBeamInt("MinRPM",self.PeakMinRPM)
	self:SetNetworkedBeamInt("MaxRPM",self.PeakMaxRPM)
	self:SetNetworkedBeamInt("LimitRPM",self.LimitRPM)
	--################################################
	self:SetNetworkedBeamInt("FlywheelMass2",self.FlywheelMass3*1000)
	self:SetNetworkedBeamInt("Idle",self.IdleRPM)
	self:SetNetworkedBeamInt("Weight",self.Weight)
	self:SetNetworkedBeamInt("Rpm",self.FlyRPM)
	--################################################


	return Feedback
end

function ENT:TriggerInput( iname , value )

	if (iname == "Throttle") then
		self.Throttle = math.Clamp(value,0,100)/100
	elseif (iname == "Active") then
		if (value > 0 and not self.Active) then
			self.RPM = {}
			self.RPM[1] = self.IdleRPM
			self.Active = true
			self.Active2 = true
			self.Sound = CreateSound(self, self.SoundPath)
			self.Sound:PlayEx(0.5,100)
			self:ACFInit()
		elseif (value <= 0 and self.Active) then
			self.Active = false
			Wire_TriggerOutput( self, "RPM", 0 )
			Wire_TriggerOutput( self, "Torque", 0 )
			Wire_TriggerOutput( self, "Power", 0 )
		end
	--##################################################
	elseif (iname == "TqAdd") then
		if (value ~= 0 ) then
			self.TqAdd = true
			self.PeakTorque = self.PeakTorque2+value
			--self.PeakTorque3 = self.PeakTorque2+value
			self:SetNetworkedBeamInt("Torque",self.PeakTorque)
			self:SetNetworkedBeamInt("Power", math.floor(self.PeakTorque * self.PeakMaxRPM / 9548.8))
		elseif (value == 0 ) then
			self.TqAdd = false
			self.PeakTorque = self.PeakTorque2
			--self.PeakTorque3 = self.PeakTorque2
			self:SetNetworkedBeamInt("Torque",self.PeakTorque)
			self:SetNetworkedBeamInt("Power", math.floor(self.PeakTorque * self.PeakMaxRPM / 9548.8))
		end
	elseif (iname == "MaxRpmAdd") then
		if (value ~= 0 ) then
			self.MaxRpmAdd = true
			--self.PeakMaxRPM = self.PeakMaxRPM2+value
			if( self.PeakMaxRPM2+value <= self.LimitRPM ) then
				self.PeakMaxRPM = self.PeakMaxRPM2+value
			elseif( self.PeakMaxRPM2+value > self.LimitRPM ) then
				self.PeakMaxRPM = self.LimitRPM
			end
			self:SetNetworkedBeamInt("MaxRPM",self.PeakMaxRPM)
			self:SetNetworkedBeamInt("Power", math.floor(self.PeakTorque * self.PeakMaxRPM / 9548.8))
		elseif (value == 0 ) then
			self.MaxRpmAdd = false
			self.PeakMaxRPM = self.PeakMaxRPM2
			self:SetNetworkedBeamInt("MaxRPM",self.PeakMaxRPM)
			self:SetNetworkedBeamInt("Power", math.floor(self.PeakTorque * self.PeakMaxRPM / 9548.8))
		end
	elseif (iname == "LimitRpmAdd") then
		if (value ~= 0 ) then
			self.LimitRpmAdd = true
			self.LimitRPM = self.LimitRPM2+value
			self:SetNetworkedBeamInt("LimitRPM",self.LimitRPM)
			self.CutValue = self.LimitRPM / 40
			self.CutRpm = self.LimitRPM - 100
		elseif (value == 0 ) then
			self.LimitRpmAdd = false
			self.LimitRPM = self.LimitRPM2
			self:SetNetworkedBeamInt("LimitRPM",self.LimitRPM)
			self.CutValue = self.LimitRPM / 40
			self.CutRpm = self.LimitRPM - 100
		end
	elseif (iname == "FlywheelMass") then
		if (value > 0 ) then
			self.FlywheelMass = true
			self.Inertia = value*(3.1416)^2
			self:SetNetworkedBeamInt("FlywheelMass2",value*1000)
		elseif (value <= 0 ) then
			self.FlywheelMass = false
			self.Inertia = self.FlywheelMass3*(3.1416)^2
			self:SetNetworkedBeamInt("FlywheelMass2",self.FlywheelMass3*1000)
		end
	elseif (iname == "Idle") then
		if (value > 0 ) then
			self.Idle = true
			self.IdleRPM = value
			self:SetNetworkedBeamInt("Idle",self.IdleRPM)
		elseif (value <= 0 ) then
			self.Idle = false
			self.IdleRPM = self.Idling
			self:SetNetworkedBeamInt("Idle",self.IdleRPM)
		end
	elseif (iname == "DisableCut") then
		if (value > 0 ) then
			self.DisableCut = 1
		elseif (value <= 0 ) then
			self.DisableCut = 0
		end
	end

end
--######################################################

function ENT:Think()

	local Time = CurTime()

	if self.Active2 then
		if self.Legal then
			self:CalcRPM()
		end

		if self.LastCheck < CurTime() then
			self:CheckRopes()
			if self:GetPhysicsObject():GetMass() < self.Weight or self:GetParent():IsValid() then
				self.Legal = false
			else 
				self.Legal = true
			end

			self.LastCheck = Time + math.Rand(5, 10)
		end

	end

	self.LastThink = Time
	self:NextThink( Time )
	return true

end

function ENT:ACFInit()

	local Constrained = constraint.GetAllConstrainedEntities(self)
	self.Mass = 0
	self.PhysMass = 0

	for _,Ent in pairs(Constrained) do

		if IsValid(Ent) then
			local Phys = Ent:GetPhysicsObject()

			if Phys and Phys:IsValid() then
				self.Mass = self.Mass + Phys:GetMass()
				local Parent = Ent:GetParent()

				if IsValid(Parent) then

					local Constraints = {}
					table.Add(Constraints,constraint.FindConstraints(Ent, "Weld"))
					table.Add(Constraints,constraint.FindConstraints(Ent, "Axis"))
					table.Add(Constraints,constraint.FindConstraints(Ent, "Ballsocket"))
					table.Add(Constraints,constraint.FindConstraints(Ent, "AdvBallsocket"))

					if Constraints then

						for Key,Const in pairs(Constraints) do

							if Const.Ent1 == Parent or Const.Ent2 == Parent then
								self.PhysMass = self.PhysMass + Phys:GetMass()
							end

						end

					end

				else
					self.PhysMass = self.PhysMass + Phys:GetMass()
				end

			end

		end

	end

	self.MassRatio = self.PhysMass/self.Mass

	Wire_TriggerOutput(self, "Mass", math.floor(self.Mass))
	Wire_TriggerOutput(self, "Physical Mass", math.floor(self.PhysMass))

	self.LastThink = CurTime()
	self.Torque = self.PeakTorque
	self.FlyRPM = self.IdleRPM*1.5

end

function ENT:CalcRPM()

	local DeltaTime = CurTime() - self.LastThink
	-- local AutoClutch = math.min(math.max(self.FlyRPM-self.IdleRPM,0)/(self.IdleRPM+self.LimitRPM/10),1)

	//local ClutchRatio = math.min(Clutch/math.max(TorqueDiff,0.05),1)
	
	-- Calculate the current torque from flywheel RPM
	--#################
	local Drag
	local TorqueDiff
	if self.Active then
	if( self.CutMode == 0 ) then
		self.Torque = self.Throttle * math.max( self.PeakTorque * math.min( self.FlyRPM / self.PeakMinRPM , (self.LimitRPM - self.FlyRPM) / (self.LimitRPM - self.PeakMaxRPM), 1 ), 0 )
		if self.iselec == true then
			Drag = self.PeakTorque * (math.max( self.FlyRPM - self.IdleRPM, 0) / self.FlywheelOverride) * (1 - self.Throttle) / self.Inertia
		else
			Drag = self.PeakTorque * (math.max( self.FlyRPM - self.IdleRPM, 0) / self.PeakMaxRPM) * ( 1 - self.Throttle) / self.Inertia
		end
	
	elseif( self.CutMode == 1 ) then
		self.Torque = 0 * math.max( self.PeakTorque * math.min( self.FlyRPM / self.PeakMinRPM , (self.LimitRPM - self.FlyRPM) / (self.LimitRPM - self.PeakMaxRPM), 1 ), 0 )
		if self.iselec == true then
			Drag = self.PeakTorque * (math.max( self.FlyRPM - self.IdleRPM, 0) / self.FlywheelOverride) * (1 - 0) / self.Inertia
		else
			Drag = self.PeakTorque * (math.max( self.FlyRPM - self.IdleRPM, 0) / self.PeakMaxRPM) * ( 1 - 0) / self.Inertia
		end
		
	end 
	
	-- Let's accelerate the flywheel based on that torque
	self.FlyRPM = math.max( self.FlyRPM + self.Torque / self.Inertia - Drag, 1 )
	-- This is the presently avaliable torque from the engine
	TorqueDiff = math.max( self.FlyRPM - self.IdleRPM, 0 ) * self.Inertia

	end
	
	if( self.Active == false ) then
		self.Torque = 0 * math.max( self.PeakTorque * math.min( self.FlyRPM / self.PeakMinRPM , (self.LimitRPM - self.FlyRPM) / (self.LimitRPM - self.PeakMaxRPM), 1 ), 0 )
		if self.iselec == true then
			Drag = self.PeakTorque * (math.max( self.FlyRPM - 0, 0) / self.FlywheelOverride) * (1 - 0) / self.Inertia
		else
			Drag = self.PeakTorque * (math.max( self.FlyRPM - 0, 0) / self.PeakMaxRPM) * ( 1 - 0) / self.Inertia
		end
	
	-- Let's accelerate the flywheel based on that torque
	self.FlyRPM = math.max( self.FlyRPM + self.Torque / self.Inertia - Drag, 1 )
	-- This is the presently avaliable torque from the engine
	TorqueDiff = math.max( self.FlyRPM - 0, 0 ) * self.Inertia
	
	end
	--##############
	
	-- The gearboxes don't think on their own, it's the engine that calls them, to ensure consistent execution order
	local Boxes = table.Count( self.GearLink )
	
	local MaxTqTable = {}
	local MaxTq = 0
	for Key, Gearbox in pairs(self.GearLink) do
		-- Get the requirements for torque for the gearboxes (Max clutch rating minus any wheels currently spinning faster than the Flywheel)
		MaxTqTable[Key] = Gearbox:Calc( self.FlyRPM, self.Inertia )
		MaxTq = MaxTq + MaxTqTable[Key]
	end
	
	-- Calculate the ratio of total requested torque versus what's avaliable
	local AvailTq = math.min( TorqueDiff / MaxTq / Boxes, 1 )

	for Key, Gearbox in pairs(self.GearLink) do
		-- Split the torque fairly between the gearboxes who need it
		Gearbox:Act( MaxTqTable[Key] * AvailTq * self.MassRatio, DeltaTime )
	end

	self.FlyRPM = self.FlyRPM - (math.min(TorqueDiff,MaxTq)/self.Inertia)
	
	--#######################################
	--if( self.CutOn == 1 ) then
	if( self.DisableCut == 0 ) then
		if( self.FlyRPM >= self.CutRpm and self.CutMode == 0 ) then
			self.CutMode = 1
			if self.Sound then
				self.Sound:Stop()
			end
			self.Sound = nil
			self.Sound2 = CreateSound(self, "acf_other/penetratingshots/00000293.wav")
			self.Sound2:PlayEx(0.5,100)
		end
		if( self.FlyRPM <= self.CutRpm - self.CutValue and self.CutMode == 1 ) then
			self.CutMode = 0
			self.Sound = CreateSound(self, self.SoundPath)
			self.Sound:PlayEx(0.5,100)
			if self.Sound2 then
				self.Sound2:Stop()
			end
		end
	--elseif( self.CutOn == 0 ) then
	elseif( self.DisableCut == 1 ) then
		self.CutMode = 0
	end
	if( self.FlyRPM <= 50 and self.Active == false ) then
		self.Active2 = false
		self.FlyRPM = 0
		if self.Sound then
			self.Sound:Stop()
		end
		self.Sound = nil
	end
	--#######################################

	-- Then we calc a smoothed RPM value for the sound effects
	table.remove( self.RPM, 10 )
	table.insert( self.RPM, 1, self.FlyRPM )
	local SmoothRPM = 0
	for Key, RPM in pairs( self.RPM ) do
		SmoothRPM = SmoothRPM + (RPM or 0)
	end
	SmoothRPM = SmoothRPM / 10

	local Power = self.Torque * SmoothRPM / 9548.8
	Wire_TriggerOutput(self, "Torque", math.floor(self.Torque))
	Wire_TriggerOutput(self, "Power", math.floor(Power))
	Wire_TriggerOutput(self, "RPM", self.FlyRPM)
	--##############################################################################################
	self:SetNetworkedBeamInt("Rpm",self.FlyRPM)
	--##############################################################################################
	
	if self.Sound then
		self.Sound:ChangePitch( math.min( 20 + (SmoothRPM * self.SoundPitch) / 50, 255 ), 0 )
		self.Sound:ChangeVolume( 0.25 + self.Throttle / 1.5, 0 )
	end
	
	return RPM
end

function ENT:CheckRopes()

	for GearboxKey,Ent in pairs(self.GearLink) do
		local Constraints = constraint.FindConstraints(Ent, "Rope")
		if Constraints then

			local Clean = false
			for Key,Rope in pairs(Constraints) do
				if Rope.Ent1 == self or Rope.Ent2 == self then
					if Rope.length + Rope.addlength < self.GearRope[GearboxKey]*1.5 then
						Clean = true
					end
				end
			end

			if not Clean then
				self:Unlink( Ent )
			end

		else
			self:Unlink( Ent )
		end

		local DrvAngle = (self:LocalToWorld(self.Out) - Ent:LocalToWorld(Ent.In)):GetNormalized():DotProduct( self:GetForward() )
		if ( DrvAngle < 0.7 ) then
			self:Unlink( Ent )
		end

	end

end

function ENT:Link( Target )

	--##################################################
	if ( !Target or Target:GetClass() != "acf_gearbox" and Target:GetClass() != "acf_gearbox2" and Target:GetClass() != "acf_gearbox3" ) then return ("Can only link to Gearboxes") end
	--##################################################

	local Duplicate = false
	for Key,Value in pairs(self.GearLink) do
		if Value == Target then
			Duplicate = true
		end
	end

	if not Duplicate then

		local InPos = Target:LocalToWorld(Target.In)
		local OutPos = self:LocalToWorld(self.Out)
		local DrvAngle = (OutPos - InPos):GetNormalized():DotProduct((self:GetForward()))
		if ( DrvAngle < 0.7 ) then
			return 'ERROR : Excessive driveshaft angle'
		end

		table.insert(self.GearLink,Target)
		table.insert(Target.Master,self)
		local RopeL = (OutPos-InPos):Length()
		constraint.Rope( self, Target, 0, 0, self.Out, Target.In, RopeL, RopeL*0.2, 0, 1, "cable/cable2", false )
		table.insert(self.GearRope,RopeL)

		return false
	else
		return ('ERROR : Gearbox already linked to this Engine')
	end


end

function ENT:Unlink( Target )

	local Success = false
	for Key,Value in pairs(self.GearLink) do
		if Value == Target then

			local Constraints = constraint.FindConstraints(Value, "Rope")
			if Constraints then
				for Key,Rope in pairs(Constraints) do
					if Rope.Ent1 == self or Rope.Ent2 == self then
						Rope.Constraint:Remove()
					end
				end
			end

			table.remove(self.GearLink,Key)
			table.remove(self.GearRope,Key)
			Success = true
		end
	end

	if Success then
		return false
	else
		return ('ERROR : Did not find the Gearbox to unlink')
	end

end

function ENT:PreEntityCopy()

	//Link Saving
	local info = {}
	local entids = {}
	for Key, Value in pairs(self.GearLink) do					--First clean the table of any invalid entities
		if not Value:IsValid() then
			table.remove(self.GearLink, Value)
		end
	end
	for Key, Value in pairs(self.GearLink) do					--Then save it
		table.insert(entids, Value:EntIndex())
	end

	info.entities = entids
	if info.entities then
		duplicator.StoreEntityModifier( self, "GearLink", info )
	end

	//Wire dupe info
	local DupeInfo = WireLib.BuildDupeInfo( self )
	if DupeInfo then
		duplicator.StoreEntityModifier( self, "WireDupeInfo", DupeInfo )
	end

end

function ENT:PostEntityPaste( Player, Ent, CreatedEntities )

	//Link Pasting
	if (Ent.EntityMods) and (Ent.EntityMods.GearLink) and (Ent.EntityMods.GearLink.entities) then
		local GearLink = Ent.EntityMods.GearLink
		if GearLink.entities and table.Count(GearLink.entities) > 0 then
			for _,ID in pairs(GearLink.entities) do
				local Linked = CreatedEntities[ ID ]
				if Linked and Linked:IsValid() then
					self:Link( Linked )
				end
			end
		end
		Ent.EntityMods.GearLink = nil
	end

	//Wire dupe info
	if(Ent.EntityMods and Ent.EntityMods.WireDupeInfo) then
		WireLib.ApplyDupeInfo(Player, Ent, Ent.EntityMods.WireDupeInfo, function(id) return CreatedEntities[id] end)
	end

end

function ENT:OnRemove()
	if self.Sound then
		self.Sound:Stop()
	end
	Wire_Remove( self )
end

function ENT:OnRestore()
	Wire_Restored( self )
end