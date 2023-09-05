//If you're interested in seeing the code, sorry!
//Comment It's written in Korean.
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>

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
    if (!strcmp(unparsedArgs, "2 2") && IsPlayerAlive(client)) {//2 2를 바꿔 다른 보이스메뉴에 적용
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
            if (playerTeam == TFTeam_Red) {
                Format(message, sizeof(message), "\x07FF3D3D%s %s\x01: %s", conVarVoice, clientName, conVarText);
            } else if (playerTeam == TFTeam_Blue) {
                Format(message, sizeof(message), "\x07516D84%s %s\x01: %s", conVarVoice, clientName, conVarText);
            } else {
                Format(message, sizeof(message), "\x03%s %s\x01: %s", conVarVoice, clientName, conVarText); //이걸 볼 수 있어...?
            }

            g_PlayerCooldowns[client] = currentTime + g_CvarCooldown.FloatValue;

            TFClassType playerClass = TF2_GetPlayerClass(client);
            char classSound[64];
            if (playerClass == TFClassType:TFClass_Pyro) {
                strcopy(classSound, sizeof(classSound), "sniperalert/pyro.mp3"); 			 //파이로 
            } else if (playerClass == TFClassType:TFClass_Scout) {
                strcopy(classSound, sizeof(classSound), "vo/scout_dominationsnp01.mp3"); 	 //스카웃
            } else if (playerClass == TFClassType:TFClass_Soldier) {
                strcopy(classSound, sizeof(classSound), "vo/soldier_mvm_sniper01.mp3");		 //솔저
            } else if (playerClass == TFClassType:TFClass_Heavy) {
                strcopy(classSound, sizeof(classSound), "vo/heavy_mvm_sniper01.mp3"); 		 //헤비
            } else if (playerClass == TFClassType:TFClass_DemoMan) {
                strcopy(classSound, sizeof(classSound), "sniperalert/demo.mp3"); 			 //데모맨
            } else if (playerClass == TFClassType:TFClass_Medic) {
                strcopy(classSound, sizeof(classSound), "vo/medic_mvm_sniper01.mp3"); 	     //메딕
            } else if (playerClass == TFClassType:TFClass_Sniper) {
                strcopy(classSound, sizeof(classSound), "sniperalert/sniper.mp3");		     //스나이퍼
            } else if (playerClass == TFClassType:TFClass_Spy) {
                strcopy(classSound, sizeof(classSound), "sniperalert/spy.mp3"); 		     //스파이
            } else {
                strcopy(classSound, sizeof(classSound), "vo/engineer_mvm_sniper01.mp3");     //엔지니어
            }


            for (int i = 1; i <= MaxClients; i++) {
                if (IsClientInGame(i) && GetClientTeam(i) == playerTeam) {
                    PrintToChat(i, "%s", message);
                   //PrintToChat(client, "%s", message);
                    if (classSound[0] != '\0' && i != client) {
                    EmitSoundToClient(i, classSound, client, _, SNDLEVEL_GUNFIRE, _, SNDVOL_NORMAL, _, _);//사용한 플레이어는 제외하는 재생
                    EmitSoundToClient(client, classSound, client, _, SNDLEVEL_FRIDGE, _, SNDVOL_NORMAL, _, _);//나한테 들리는 재생. 이렇게해야 클라이언트한테 너무 크게 안들렸음
                    }
                }
                if (IsClientInGame(i) && GetClientTeam(i) != playerTeam) { //상대편도 들을 수 있게하기 위해.
                    if (classSound[0] != '\0' && i != client) {
                    EmitSoundToClient(i, classSound, client, _, SNDLEVEL_GUNFIRE, _, SNDVOL_NORMAL, _, _); 
                    }
                }
            }

            return Plugin_Handled;
        }
    }

    return Plugin_Continue;
}
