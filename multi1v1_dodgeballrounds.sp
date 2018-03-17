/*  CS:GO Multi1v1: Dodgeball round addon
 *
 *  Copyright (C) 2018 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */
 
 
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multi1v1>

#pragma semicolon 1
#pragma newdecls required

int g_iRoundType;

public Plugin myinfo = {
  name = "CS:GO Multi1v1: Dodgeball round addon",
  author = "Franc1sco franug",
  description = "Adds an unranked Dodgeball round-type",
  version = "1.0.2",
  url = "http://steamcommunity.com/id/franug"
};

public void Multi1v1_OnRoundTypesAdded() 
{
	// Add the custom round and get custom round index
	g_iRoundType = Multi1v1_AddRoundType("Dodgeball", "dodgeball", DodgeballHandler, true, false, "", true);
}

public void DodgeballHandler(int iClient) 
{
	// Start the custom round with a decoy and 1 hp
	GivePlayerItem(iClient, "weapon_decoy");
	SetEntityHealth(iClient, 1);
	
	// Remove armor (Thanks to Wacci)
	SetEntProp(iClient, Prop_Data, "m_ArmorValue", 0);
}

public void OnEntityCreated(int iEntity, const char[] szClassname)
{
	// Check if new entity is a decoy
	if (!StrEqual(szClassname, "decoy_projectile"))
		return;
		
	// Hook spawn
	SDKHook(iEntity, SDKHook_Spawn, OnEntitySpawned);
}

public int OnEntitySpawned(int iEntity)
{
	// Get client index
	int iClient = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
	
	// checkers on the client index for prevent errors
	if (iClient == -1 || !IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return;
		
	// If current round is decoy round then do timer
	if(Multi1v1_GetCurrentRoundType(Multi1v1_GetArenaNumber(iClient)) == g_iRoundType)
		CreateTimer(0.0, Timer_RemoveThinkTick, EntIndexToEntRef(iEntity), TIMER_FLAG_NO_MAPCHANGE);

}

public Action Timer_RemoveThinkTick(Handle hTimer, int iRef)
{
	// Get entity index
	int iEntity = EntRefToEntIndex(iRef);
	
	// Check if entity is valid
	if (iEntity == INVALID_ENT_REFERENCE || !IsValidEntity(iEntity))
		return;
		
	// Prevent explode
	SetEntProp(iEntity, Prop_Data, "m_nNextThinkTick", -1);
	
	// Give new decoy in 1.4 seconds
	CreateTimer(1.4, Timer_RemoveDecoy, EntIndexToEntRef(iEntity), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_RemoveDecoy(Handle hTimer, int iRef)
{
	// Get entity index
	int iEntity = EntRefToEntIndex(iRef);
	
	// Check if entity is valid
	if (iEntity == INVALID_ENT_REFERENCE || !IsValidEntity(iEntity))
		return;
		
	// Get client index
	int iClient = GetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity");
		
	// Remove old decoy
	AcceptEntityInput(iEntity, "Kill");
		
	// checkers on the client index for prevent errors
	if (iClient == -1 || !IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return;
		
	// Check if the current round is still the dodgeball round
	if(Multi1v1_GetCurrentRoundType(Multi1v1_GetArenaNumber(iClient)) != g_iRoundType)
		return;

	// give a new decoy
	GivePlayerItem(iClient, "weapon_decoy");
}

