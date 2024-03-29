// SPDX-License-Identifier: GPL-3.0-only
/*
 *
 * Copyright 2011 - 2022 github.com/dr-lex/Server_coop/tree/master/sources/%5BAny%5D%20GagMuteBan
 * Plugin GagMuteBan
 *
*/
#if defined _gagmuteban_included
 #endinput
#endif
#define _gagmuteban_included

/**
 *	@param client		
 *	@param iTime		
 *
 *	@return				
*/
native int HxSetClientBan(int client, int iTime);

/**
 *	@param client		
 *	@param iTime		
 *
 *	@return				
*/
native int HxSetClientGag(int client, int iTime);

/**
 *	@param client		
 *	@param iTime		
 *
 *	@return				
*/
native int HxSetClientMute(int client, int iTime);

/**
 *	@param client		
 *	@param iTime		
 *
 *	@return				
*/
native int HxSetClientVote(int client, int iTime);

public SharedPlugin __pl_gagmuteban = 
{
	name = "gagmuteban",
	file = "gagmuteban.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_gagmuteban_SetNTVOptional()
{
	MarkNativeAsOptional("HxSetClientBan");
	MarkNativeAsOptional("HxSetClientGag");
	MarkNativeAsOptional("HxSetClientMute");
}
#endif
