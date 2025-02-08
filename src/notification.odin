package main

import "core:strings"
import "core:sys/windows"

create_toast :: proc(title: string, text: string) -> bool {
	title := title
	text := text

	TITLE_LENGTH :: 64

	if len(title) > TITLE_LENGTH {
		title = strings.concatenate({title[:TITLE_LENGTH - 3], "..."})
	}

	sized_title: [TITLE_LENGTH]u16
	for ch, i in title {
		sized_title[i] = cast(u16)ch
	}

	TEXT_LENGTH :: 256

	if len(text) > TEXT_LENGTH {
		text = strings.concatenate({text[:TEXT_LENGTH - 3], "..."})
	}

	sized_text: [TEXT_LENGTH]u16
	for ch, i in text {
		sized_text[i] = cast(u16)ch
	}

	data: windows.NOTIFYICONDATAW = {
		cbSize      = size_of(windows.NOTIFYICONDATAW),
		hWnd        = windows.GetConsoleWindow(),
		uFlags      = windows.NIF_ICON | windows.NIF_INFO,
		szInfoTitle = sized_title,
		szInfo      = sized_text,
		hIcon       = windows.LoadIconA(nil, windows.IDI_APPLICATION),
	}

	windows.Shell_NotifyIconW(windows.NIM_ADD, &data) or_return
	windows.Shell_NotifyIconW(windows.NIM_DELETE, &data) or_return

	return true
}
