 * Add a ban by steam id
   sm_addban <minutes> <STEAM_ID>
 
 * Remove a player's ban by steam id
   sm_unban <STEAM_ID>

 * To work through third-party plugins
 *
 * native int HxSetClientBan(int client, int iTime);
 * native int HxSetClientGag(int client, int iTime);
 * native int HxSetClientMute(int client, int iTime);
 *
