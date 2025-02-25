package main

import "core:fmt"
import "core:os"
import "core:reflect"

AddCommand :: struct {
	event: Event,
}

Command :: union {
	AddCommand,
}

encode :: proc(command: Command) -> []byte {
	bytes: [dynamic]byte

	switch cmd in command {
	case AddCommand:
		append(&bytes, u8(reflect.get_union_variant_raw_tag(command)))

		append(&bytes, u8(len(cmd.event.id)))
		append(&bytes, cmd.event.id)

		title_len := len(cmd.event.title)
		append(&bytes, u8(title_len))
		append(&bytes, u8(title_len >> 8))
		append(&bytes, cmd.event.title)
	}

	return bytes[:]
}

advance :: proc(bytes: ^[]byte, offset: ^int, step: int) -> []byte {
	result := bytes[offset^:offset^ + step]
	offset^ += step

	return result
}

advance_one :: proc(bytes: ^[]byte, offset: ^int) -> byte {
	result := bytes[offset^:offset^ + 1]
	offset^ += 1

	return result[0]
}

decode :: proc(bytes: []byte) -> Command {
	bytes := bytes

	command: Command

	offset := 0
	tag := i64(advance_one(&bytes, &offset))
	reflect.set_union_variant_raw_tag(command, tag)

	switch &cmd in command {
	case AddCommand:
		id_len := int(advance_one(&bytes, &offset))
		id := transmute(string)advance(&bytes, &offset, id_len)

		title_len_bytes := advance(&bytes, &offset, 2)
		title_len := int(title_len_bytes[1] << 8 | title_len_bytes[0])
		title := transmute(string)advance(&bytes, &offset, title_len)

		cmd.event = Event {
			id    = id,
			title = title,
		}
	}

	return command
}
