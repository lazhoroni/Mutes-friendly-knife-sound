#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <multicolors>
#define PLUGIN_VERSION "3.1"
bool g_bIsEnabled[MAXPLAYERS + 1], g_bPlayerHitted[MAXPLAYERS], g_bPlayerDisable[MAXPLAYERS];
ConVar g_cvarPluginEnabled;
Handle g_PluginTagi;
public Plugin myinfo =
{
	name = "Mutes knife sounds",
	author = "Nano & GAMMACASE",
	description = "Mutes knife sounds against friendly targets when no damage is dealt.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/marianzet1"
}
public void OnPluginStart()
{
	RegConsoleCmd("sm_knifemute", Command_muteknife, "Mutes knife sounds.");
	RegConsoleCmd("sm_muteknife", Command_muteknife, "Mutes knife sounds.");
	RegConsoleCmd("sm_mk", Command_muteknife, "Mutes knife sounds.");
	RegConsoleCmd("sm_bs", Command_muteknife, "Mutes knife sounds.");
	RegConsoleCmd("sm_bicaksesi", Command_muteknife, "Mutes knife sounds.");
	g_cvarPluginEnabled = CreateConVar("bs_eklenti_durumu", "1", "1 - Eklenti acik | 0 - Eklenti kapali");
	g_PluginTagi = CreateConVar("bs_eklenti_tagi", "[not2easy]", "Pluginlerin basinda olmasini istediginiz tagi giriniz");
	AutoExecConfig(true, "bicak_sesleri");
	AddNormalSoundHook(NSound_CallBack);
	HookEvent("player_hurt", PlayerHurt_Event, EventHookMode_Pre);
	LoadTranslations("bicak_sesleri.phrases");
}
public OnClientPostAdminCheck(Client)
{
    g_bIsEnabled[Client] = false;
}
public OnClientDisconnect(Client)
{
    g_bIsEnabled[Client] = false;
}
public Action Command_muteknife(int client, int args)
{
	char sPluginTagi[64];
	GetConVarString(g_PluginTagi, sPluginTagi, sizeof(sPluginTagi));
	if (!g_cvarPluginEnabled.BoolValue) {
		CPrintToChat(client, "%t", "Eklenti-Kapali-Mesaji", sPluginTagi);
		return Plugin_Handled;
	}
	g_bPlayerDisable[client] = !g_bPlayerDisable[client];
	if(!g_bIsEnabled[client])
    {
		g_bIsEnabled[client] = true;
		CPrintToChat(client, "%t", "Bicak-Sesli-Kapandi-Mesaji-Chat", sPluginTagi);
		PrintCenterText(client, "%t", "Bicak-Sesli-Kapandi-Mesaji-Center");
		return Plugin_Changed;
    }
	else
	{
		g_bIsEnabled[client] = false;
		CPrintToChat(client, "%t", "Bicak-Sesli-Acildi-Mesaji-Chat", sPluginTagi);
		PrintCenterText(client, "%t", "Bicak-Sesli-Acildi-Mesaji-Center");
		return Plugin_Changed;
	}
}	
public void OnClientPutInServer(int client)
{
	g_bPlayerHitted[client] = false;
	g_bPlayerDisable[client] = false;
}
public Action PlayerHurt_Event(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	g_bPlayerHitted[attacker] = true;
}
public Action NSound_CallBack(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	char classname[32];
	GetEdictClassname(entity, classname, sizeof(classname));
	if(StrContains(sample, "flesh") != -1 || StrContains(sample, "kevlar") != -1)
	{
		CheckClients(clients, numClients);
		return Plugin_Changed;
	}
	if(StrContains(classname, "knife") != -1)
	{
		int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if(!IsValidClient(client, false))
		return Plugin_Continue;
		if(g_bPlayerHitted[client])
		{
			g_bPlayerHitted[client] = false;
			return Plugin_Continue;
		}
		CheckClients(clients, numClients);
		g_bPlayerHitted[client] = false;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
stock void CheckClients(int[] clients, int &numClients)
{
	for(int i = 0; i < numClients; i++)
	if(g_bPlayerDisable[clients[i]])
	{
		for (int j = i; j < numClients-1; j++)
		clients[j] = clients[j+1];
		numClients--;
		i--;
	}
}
stock bool IsValidClient(int client, bool botcheck = true)
{
	return (1 <= client && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (botcheck ? !IsFakeClient(client) : true)); 
}