package main

import "core:fmt"
import "core:sys/darwin"
import "core:sys/darwin/Foundation"

create_toast :: proc(title: string, text: string) -> bool {
	title := title
	text := text

	notification: Foundation.Notification
	t := Foundation.Notification_init(&notification)

	// fmt.println(t)
	// darwin.syscall_execve(
	// 	"osascript",
	// 	"-e 'display notification \"[15:03]\" with title \"Gym Time\" sound name \"\"",
	// 	"/usr/bin/env",
	// )

	// osascript -e 'display notification "[15:03]" with title "Gym Time" sound name ""'

	return true
}
