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

static VGUIWindow winChooseTeam;

class TeamButton:VGUIButton
{
	void TeamButton(void);

	virtual void OnMouseUp(void);
};

void
TeamButton::TeamButton(void)
{
}

void
TeamButton::OnMouseUp(void)
{
	int tag = GetTag();

	localcmd("changeclass\n");
	sendevent("TeamJoin", "f", (float)tag);
	winChooseTeam.Hide();
}


string
VGUI_ChooseTeam_MapInfo(void)
{
	static string mapinfo = __NULL__;

	if (mapinfo != __NULL__)
		return mapinfo;
	
	filestream fileMap = fopen(strcat("maps/", mapname, ".txt"), FILE_READ);
	string temp;

	if (fileMap != -1) {
		while ((temp = fgets(fileMap))) {
			mapinfo = strcat(mapinfo, temp, "\n");
		}
	} else {
		mapinfo = "No map info available.";
	}

	return mapinfo;
}

void
VGUI_ChooseTeam(void)
{
	static int initialized;
	static VGUIButton btnTeamBlue;
	static VGUIButton btnTeamRed;
	static VGUIButton btnAutoAssign;
	static VGUIButton btnGoSpectator;
	static VGUIFrame frmMapInfo;
	static VGUILabel lblSelectTeam;
	static VGUILabel lblMapName;
	static VGUILabel lblMapInfo;

	static void VGUI_AutoAssign(void) {
		sendevent("JoinAuto", "");
		winChooseTeam.Hide();
	}

	static void VGUI_JoinRed(void) {
		sendevent("JoinTeam", "f", 1);
		winChooseTeam.Hide();
	}

	static void VGUI_JoinBlue(void) {
		sendevent("JoinTeam", "f", 2);
		winChooseTeam.Hide();
	}

	static void VGUI_JoinSpectator(void) {
		sendevent("JoinSpectator", "");
		winChooseTeam.Hide();
	}


	if (!initialized) {
		vector btnpos = [40,80];

		initialized = TRUE;
		winChooseTeam = spawn(VGUIWindow);
		winChooseTeam.SetSize('640 480');
		winChooseTeam.SetStyleMask(VGUIWindowBorderless | VGUIWindowFullscreen);

		lblSelectTeam = spawn(VGUILabel);
		lblSelectTeam.SetTitle("SELECT YOUR TEAM");
		lblSelectTeam.SetTextSize(19);
		lblSelectTeam.SetPos([40, 38]);
		lblSelectTeam.SetSize('400 24');

		frmMapInfo = spawn(VGUIFrame);
		frmMapInfo.SetPos('176 80');
		frmMapInfo.SetSize('424 312');

		lblMapName = spawn(VGUILabel);
		lblMapName.SetTitle(mapname);
		lblMapName.SetTextSize(19);
		lblMapName.SetPos('194 105');
		lblMapName.SetSize('250 312');

		lblMapInfo = spawn(VGUILabel);
		lblMapInfo.SetTitle(VGUI_ChooseTeam_MapInfo());
		lblMapInfo.SetPos('194 129');
		lblMapInfo.SetSize('375 250');

		btnTeamBlue = spawn(VGUIButton);
		btnTeamBlue.SetTitle("BLUE");
		btnTeamBlue.SetPos(btnpos);
		btnTeamBlue.SetSize('124 24');
		btnTeamBlue.SetKeyEquivalent("1");
		btnTeamBlue.SetFunc(VGUI_JoinBlue);
		btnpos[1] += 32;

		btnTeamRed = spawn(VGUIButton);
		btnTeamRed.SetTitle("RED");
		btnTeamRed.SetPos(btnpos);
		btnTeamRed.SetSize('124 24');
		btnTeamRed.SetKeyEquivalent("2");
		btnTeamRed.SetFunc(VGUI_JoinRed);
		btnpos[1] += 32;

		btnAutoAssign = spawn(VGUIButton);
		btnAutoAssign.SetTitle("AUTO ASSIGN");
		btnAutoAssign.SetPos(btnpos);
		btnAutoAssign.SetSize('124 24');
		btnAutoAssign.SetKeyEquivalent("5");
		btnAutoAssign.SetFunc(VGUI_AutoAssign);
		btnpos[1] += 32;

		btnGoSpectator = spawn(VGUIButton);
		btnGoSpectator.SetTitle("SPECTATE");
		btnGoSpectator.SetPos(btnpos);
		btnGoSpectator.SetSize('124 24');
		btnGoSpectator.SetKeyEquivalent("6");
		btnGoSpectator.SetFunc(VGUI_JoinSpectator);

		g_uiDesktop.Add(winChooseTeam);
		winChooseTeam.Add(frmMapInfo);
		winChooseTeam.Add(lblSelectTeam);
		winChooseTeam.Add(lblMapName);
		winChooseTeam.Add(lblMapInfo);
		winChooseTeam.Add(btnTeamBlue);
		winChooseTeam.Add(btnTeamRed);
		winChooseTeam.Add(btnAutoAssign);
		winChooseTeam.Add(btnGoSpectator);
	}

	winChooseTeam.Show();
	winChooseTeam.SetPos((video_res / 2) - (winChooseTeam.GetSize() / 2));
}
