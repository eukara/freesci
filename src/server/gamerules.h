/*
 * Copyright (c) 2016-2020 Marco Cawthorne <marco@icculus.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF MIND, USE, DATA OR PROFITS, WHETHER
 * IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING
 * OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

class HLGameRules:CGameRules
{
	int m_iScientistsAlive;

	float m_flRestockTimer;
	float m_flBreakRespawnTimer;

	/* client */
	virtual void(NSClientPlayer) PlayerSpawn;
	virtual void(NSClientPlayer) PlayerDeath;
	virtual void(NSClientPlayer) PlayerPostFrame;
	virtual void(NSClientPlayer, entity) ScientistKill;
	virtual void(void) RegisterSciDeath;

	virtual void(NSClientPlayer) LevelDecodeParms;
	virtual void(NSClientPlayer) LevelChangeParms;
	virtual void(void) LevelNewParms;
	virtual void(void) FrameStart;
	virtual void(void) CheckRules;
	virtual bool(void) IsMultiplayer;
	virtual void(void) RestartRound;

	virtual void(void) CountScientists;

	void(void) HLGameRules;
	virtual void(void) InitPostEnts;
};

class SHTeamRules:HLGameRules
{
	int m_iKillsTeam1;
	int m_iKillsTeam2;

	int m_iScoreTeam1;
	int m_iScoreTeam2;

	void(void) SHTeamRules;

	virtual void(void) RestartRound;
	virtual void(NSClientPlayer) PlayerSpawn;
	virtual void(NSClientPlayer) PlayerTeamSpawn;
	virtual bool(void) IsTeamplay;
	virtual void(void) AddTeam1Kill;
	virtual void(void) AddTeam2Kill;
	virtual void(void) RegisterSciDeath;
	virtual void(NSClientPlayer, entity) ScientistKill;
	virtual void(void) InitPostEnts;
};

class SHRules:HLGameRules
{
	void(void) SHRules;
	virtual void(void) RegisterSciDeath;
};

/* Standard Hunting (0):
	Round-based competitive killing where scientists are always running around. Scientists don't respawn.
*/
class SHGameHunt:SHTeamRules
{
	void(void) SHGameHunt;
};

/* Stealth Hunting (1):
	Round-based competitive killing where scientists stand or walk around, but will run in fear if they see the player. Similar to deer hunting. Scientists don't respawn.
*/
class SHGameStealth:SHTeamRules
{
	void(void) SHGameStealth;
};

/* Traditional Slaughter (2):
	Casual killing where scientists behave the same as they were in Half-Life. Scientists respawn.
*/
class SHGameSlaughter:HLGameRules
{
	void(void) SHGameSlaughter;
};

/* Live in Fear (3):
	Unique round-based gamemode where players have to only kill an evil randomly selected player controlled scientist causing chaos. Those who kill good scientists are punished with lost points. The evil scientist gains one point from every kill (NPC or Players). Scientists respawn.
*/
class SHGameFear:HLGameRules
{
	void(void) SHGameFear;
};

/* Madness (4):
	Unique gamemode where scientists attack themselves and the players. Scientists inject players and NPCs only once with a poison that slowly drains their health to 0. The scientists also play a sound (sh/hide_laugh.wav) when they get a sucessful kill and are still alive. Scientists respawn.
*/
class SHGameMadness:HLGameRules
{
	void(void) SHGameMadness;
};

/* Invasion (5):
	Unique new round-based gamemode where scientists attack similar to madness but work together to kill everyone else. If players eleminate all scientists, then they win the round and have to do it all over again. Heavy WIP. Scientists and players don't respawn.
*/
class SHGameInvasion:SHRules
{
	void(void) SHGameInvasion;
};

typedef enum
{
	SHMODE_STANDARD = 0,
	SHMODE_STEALTH,
	SHMODE_SLAUGHTER,
	SHMODE_LIVEINFEAR,
	SHMODE_MADNESS,
	SHMODE_INVASION
} shmode_e;

/* give our gamemode cvar a default */
var shmode_e autocvar_sh_realistic = SHMODE_SLAUGHTER;
var shmode_e g_chosen_mode;

/* enable team changing */
var int autocvar_sh_allowteamchange = 1;

/* limit the amount of scientists that can spawn by default */
var int autocvar_sh_scimax = 5;

var int autocvar_sh_scialert = FALSE;

/* default speed for scientists */
var int autocvar_sh_scispeed = 40;

/* enable scientist obituaries */
var int autocvar_sh_announcescideath = 1;

/* enable scientist scoreboard */
var int autocvar_sh_announcescinum = 1;

/* default kills required for insanity */
var int autocvar_sh_insanity = 5;

/* an override for sh_scimax */
var int autocvarsh_scimax_override = 0;