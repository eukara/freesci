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

void VGUI_ChooseTeam(void);

int
ClientGame_ConsoleCommand(void)
{
	switch(argv(0)) {
	case "+sciscore":
		g_sciscore = true;
		break;
	case "-sciscore":
		g_sciscore = false;
		break;
	default:
		return (0);
	}
	return (1);
}

void
CMD_ChooseTeam(void)
{
	if (serverkeyfloat("sv_playerslots") <= 1)
		return;

		if (serverkeyfloat("teams") > 1)

	/* handle both VGUI and text menus */
//	if (ClientGame_IsUsingVGUI())
		VGUI_ChooseTeam();
//	else
//		Textmenu_Toggle("TEAM_SELECT");
}