print("loading AB");

include( "ToolTipHelper" );	
include( "InstanceManager" );
include( "TabSupport" );
include( "Civ6Common" );
include( "SupportFunctions" );
include( "AdjacencyBonusSupport");

local m_panel_opened = false;
local m_from_notification = false;

function DoLog(message)
    print("AB:"..message);
end

-- ===========================================================================
-- Support methods, copy from ProductionPanel.Lua
-- ===========================================================================
-- ===========================================================================
function BuildUnit(city, unitEntry)
	local tParameters = {};
	tParameters[CityOperationTypes.PARAM_UNIT_TYPE] = unitEntry.Hash;
	tParameters[CityOperationTypes.PARAM_INSERT_MODE] = CityOperationTypes.VALUE_EXCLUSIVE;
	CityManager.RequestOperation(city, CityOperationTypes.BUILD, tParameters);
    UI.PlaySound("Confirm_Production");
end

-- ===========================================================================
function BuildUnitCorps(city, unitEntry)
	local tParameters = {};
	tParameters[CityOperationTypes.PARAM_UNIT_TYPE] = unitEntry.Hash;
	tParameters[CityOperationTypes.PARAM_INSERT_MODE] = CityOperationTypes.VALUE_EXCLUSIVE;
	tParameters[CityOperationTypes.MILITARY_FORMATION_TYPE] = MilitaryFormationTypes.CORPS_MILITARY_FORMATION;
	CityManager.RequestOperation(city, CityOperationTypes.BUILD, tParameters);
	UI.PlaySound("Confirm_Production");
end

-- ===========================================================================
function BuildUnitArmy(city, unitEntry)
	local tParameters = {};
	tParameters[CityOperationTypes.PARAM_UNIT_TYPE] = unitEntry.Hash;
	tParameters[CityOperationTypes.PARAM_INSERT_MODE] = CityOperationTypes.VALUE_EXCLUSIVE;
	tParameters[CityOperationTypes.MILITARY_FORMATION_TYPE] = MilitaryFormationTypes.ARMY_MILITARY_FORMATION;
	CityManager.RequestOperation(city, CityOperationTypes.BUILD, tParameters);
	UI.PlaySound("Confirm_Production");
end

-- ===========================================================================
function AdvanceProject(city, projectEntry)
	local tParameters = {}; 
	tParameters[CityOperationTypes.PARAM_PROJECT_TYPE] = projectEntry.Hash;
	tParameters[CityOperationTypes.PARAM_INSERT_MODE] = CityOperationTypes.VALUE_EXCLUSIVE;
	CityManager.RequestOperation(city, CityOperationTypes.BUILD, tParameters);
    UI.PlaySound("Confirm_Production");
end


-- Automatical populate the previous project
function AutomaticPopulateProject()
	print("AutomaticPopulateProject");
	local selectedCity	= UI.GetHeadSelectedCity();
	if selectedCity == nil then
		return false;
	end
	local buildQueue	= selectedCity:GetBuildQueue();
	local currentProductionHash = buildQueue:GetCurrentProductionTypeHash();
	local previousProductionHash = buildQueue:GetPreviousProductionTypeHash();

	if currentProductionHash ~= 0 then
		print("has current project skip");
		return false; -- not populate if current project present
	end

	-- check if need populate the previous unit or project
	if buildQueue:CanProduce( previousProductionHash, true ) then
		for row in GameInfo.Units() do
			if row.Hash == previousProductionHash then
				-- Unit
				print("Got unit");
				print(row.Name);
				print(row.Hash);
				local eMilitaryFormationType :number = buildQueue:GetCurrentProductionTypeModifier();
				print(eMilitaryFormationType);
				if (eMilitaryFormationType == MilitaryFormationTypes.STANDARD_FORMATION) then
					BuildUnit(selectedCity, row);
				elseif (eMilitaryFormationType == MilitaryFormationTypes.CORPS_FORMATION) then
					BuildUnitCorps(selectedCity, row);
				elseif (eMilitaryFormationType == MilitaryFormationTypes.ARMY_FORMATION) then
					BuildUnitArmy(selectedCity, row);
				end
				return true;
			end
		end
		for row in GameInfo.Projects() do
			if row.Hash == previousProductionHash then
				-- Project
				print("got projcet");
				AdvanceProject(selectedCity, row);
				return true;
			end
		end
	end

	-- no previous unit and project available, check if we can build some buildings
	print("checking buildings");
	for row in GameInfo.Buildings() do
		-- print(row.Name);
		-- print(row.Hash);
		-- print(row.BuildingType);
		if buildQueue:CanProduce( row.Hash, true ) then
			local bNeedsPlacement :boolean = row.RequiresPlacement;
			if (false == bNeedsPlacement or buildQueue:HasBeenPlaced(row.Hash)) then
				print("got building:"..row.Name);

				-- Build the building
				local tParameters = {}; 
				tParameters[CityOperationTypes.PARAM_BUILDING_TYPE] = row.Hash;  
				tParameters[CityOperationTypes.PARAM_INSERT_MODE] = CityOperationTypes.VALUE_EXCLUSIVE;
				CityManager.RequestOperation(selectedCity, CityOperationTypes.BUILD, tParameters);
				UI.PlaySound("Confirm_Production");

				return true;
			end
		end
	end

	print("checking districts");
	for row in GameInfo.Districts() do
		-- print(row.Name);
		-- print(row.Hash);
		-- print(row.DistrictType);
		if buildQueue:CanProduce( row.Hash, true ) then
			local bNeedsPlacement :boolean = row.RequiresPlacement;
			if (false == bNeedsPlacement or buildQueue:HasBeenPlaced(row.Hash)) then
				print("got disctict:"..row.Name);

				-- Build the district
				local tParameters = {}; 
				tParameters[CityOperationTypes.PARAM_DISTRICT_TYPE] = row.Hash;  
				tParameters[CityOperationTypes.PARAM_INSERT_MODE] = CityOperationTypes.VALUE_EXCLUSIVE;
				CityManager.RequestOperation(city, CityOperationTypes.BUILD, tParameters);
				UI.PlaySound("Confirm_Production");

				return true;
			end
		end
	end

	return false;
end

function OnNotificationPanelChooseProduction()
	DoLog("OnNotificationPanelChooseProduction");
    m_from_notification = true;
end

function OnCitySelectionChanged( owner:number, cityID:number, i, j, k, isSelected:boolean, isEditable:boolean)
    DoLog("City selection changed");
    if m_from_notification then
        AutomaticPopulateProject();
    end
end

function OnProductionPanelClose()
    DoLog("Panel Closed");
    m_panel_opened = false;
    m_from_notification = false;
end

function OnProductionPanelOpen()
    DoLog("Panel Opened");
    m_panel_opened = true;
    AutomaticPopulateProject();
end

function Initialize()
    DoLog("Init");
	-- ===== Event listeners =====
	Events.CitySelectionChanged.Add( OnCitySelectionChanged );	
	LuaEvents.NotificationPanel_ChooseProduction.Add( OnNotificationPanelChooseProduction );
    LuaEvents.ProductionPanel_Close.Add( OnProductionPanelClose );
    LuaEvents.ProductionPanel_Open.Add( OnProductionPanelOpen );
end

print("Initializing AB");
Initialize();
print("Initialized AB");