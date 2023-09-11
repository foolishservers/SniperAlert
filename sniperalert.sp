#include <sourcemod>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

ConVar g_CvarEnabled;
ConVar g_CvarVCtext;
ConVar g_CvarVCvo;
ConVar g_CvarCooldown;

public Plugin myinfo = {
	name = "Sniper Alert",
	author = "Dilmah(aka cfnnit) and Sandy(He fixed my some poor code, thx!)",
	description = "Add Sniper alert on voicecommand.",
	version = "1.0",
	url = "https://discord.gg/foolishserver" //The community server host in South Korea that we belong to.
};

float g_PlayerCooldowns[MAXPLAYERS + 1];

public void OnPluginStart() {
	AddFileToDownloadsTable("sound/sniperalert/demo.mp3");
	AddFileToDownloadsTable("sound/sniperalert/pyro.mp3");
	AddFileToDownloadsTable("sound/sniperalert/sniper.mp3");
	AddFileToDownloadsTable("sound/sniperalert/spy.mp3");
	
	PrecacheSound("sniperalert/demo.mp3");
	PrecacheSound("sniperalert/pyro.mp3");
	PrecacheSound("sniperalert/sniper.mp3");
	PrecacheSound("sniperalert/spy.mp3");

	AddCommandListener(Cmd_VoiceMenu, "voicemenu");

	g_CvarEnabled = CreateConVar("sm_snipervm_enabled", "1", "Enable Disable.", FCVAR_NONE);
	g_CvarVCtext = CreateConVar("sm_snipervm_text", "Sniper Ahead!", "Setting Messege", FCVAR_NONE);
	g_CvarVCvo = CreateConVar("sm_snipervm_voice", "(Voice)", "Setting Prefixes", FCVAR_NONE);
	g_CvarCooldown = CreateConVar("sm_snipervm_cooldown", "3", "Cooldown Second", FCVAR_NONE);

	// Lateload.
	for (int i = 1; i <= MaxClients; i++) {
		g_PlayerCooldowns[i] = 0.0;
	}
}

public Action Cmd_VoiceMenu(int client, const char[] command, int argc) {
	if (!g_CvarEnabled.BoolValue) {
		return Plugin_Continue;
	}

	char unparsedArgs[4];
	GetCmdArgString(unparsedArgs, sizeof(unparsedArgs));
	if (!strcmp(unparsedArgs, "2 2") && IsPlayerAlive(client)) { // Change Cheers! to sniper alert.
		char clientName[64];
		GetClientName(client, clientName, sizeof(clientName));

		int playerTeam = GetClientTeam(client);
		float currentTime = GetGameTime();
		if (g_PlayerCooldowns[client] <= currentTime) {
			char message[256];
			char conVarText[256];
			char conVarVoice[256];
			g_CvarVCtext.GetString(conVarText, sizeof(conVarText));
			g_CvarVCvo.GetString(conVarVoice, sizeof(conVarVoice));

			switch(view_as<TFTeam>(playerTeam)) {
				case TFTeam_Red: {
					Format(message, sizeof(message), "\x07FF3D3D%s %s\x01: %s", conVarVoice, clientName, conVarText);
				}
				case TFTeam_Blue: {
					Format(message, sizeof(message), "\x079ACDFF%s %s\x01: %s", conVarVoice, clientName, conVarText);
				}
				default: {
					Format(message, sizeof(message), "\x03%s %s\x01: %s", conVarVoice, clientName, conVarText); // SourceTV?
				}
			}

			g_PlayerCooldowns[client] = currentTime + g_CvarCooldown.FloatValue;

			char classSound[64];
			switch (TF2_GetPlayerClass(client)) {
				case TFClass_Pyro: strcopy(classSound, sizeof(classSound), "sniperalert/pyro.mp3");
				case TFClass_Scout: strcopy(classSound, sizeof(classSound), "vo/scout_dominationsnp01.mp3");
				case TFClass_Soldier: strcopy(classSound, sizeof(classSound), "vo/soldier_mvm_sniper01.mp3");
				case TFClass_Heavy: strcopy(classSound, sizeof(classSound), "vo/heavy_mvm_sniper01.mp3");
				case TFClass_DemoMan: strcopy(classSound, sizeof(classSound), "sniperalert/demo.mp3");
				case TFClass_Medic: strcopy(classSound, sizeof(classSound), "vo/medic_mvm_sniper01.mp3");
				case TFClass_Sniper: strcopy(classSound, sizeof(classSound), "sniperalert/sniper.mp3");
				case TFClass_Spy: strcopy(classSound, sizeof(classSound), "sniperalert/spy.mp3");
				case TFClass_Engineer: strcopy(classSound, sizeof(classSound), "vo/engineer_mvm_sniper01.mp3");
				case TFClass_Unknown: strcopy(classSound, sizeof(classSound), "vo/null.mp3");
			}

			EmitSoundToClient(client, classSound, client, _, SNDLEVEL_FRIDGE, _, SNDVOL_NORMAL, _, _);	// Avoid to listen several sound at once.
			for (int i = 1; i <= MaxClients; i++) {
				if (IsClientInGame(i)) {
					if (classSound[0] != '\0' && i != client) {
						EmitSoundToClient(i, classSound, client, _, SNDLEVEL_GUNFIRE, _, SNDVOL_NORMAL, _, _);	// Use different sound level to enhanced listen.
					}

					if (GetClientTeam(i) == playerTeam) {
						PrintToChat(i, "%s", message);
					}
				}
			}

			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}
