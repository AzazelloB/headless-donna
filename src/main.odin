package main

import "core:crypto"
import "core:encoding/json"
import "core:encoding/uuid"
import "core:fmt"
import "core:log"
import "core:math"
import "core:os"
import "core:slice"
import "core:strings"
import "core:time"
import "core:time/datetime"

Once :: struct {
	time: datetime.Time,
	date: datetime.Date,
	// tz:   ^datetime.TZ_Region,
}

EveryWeek :: struct {
	time:        datetime.Time,
	day_of_week: datetime.Weekday,
	// tz:          ^datetime.TZ_Region,
}

Recurrence :: union {
	// Once,
	EveryWeek,
}

Event :: struct {
	id:         string,
	title:      string,
	recurrence: Recurrence,
}

// TODO: data encoding is completely fucked
// json marshal/unmarshal does not support unions or enums
EventsData :: struct {
	events: []Event,
}

EVENTS_PATH :: "./events.json"

get_events :: proc() -> []Event {
	data, ok := os.read_entire_file(EVENTS_PATH)

	if !ok {
		return {}
	}

	events_data: EventsData

	json.unmarshal(data, &events_data)

	return events_data.events
}

save_events :: proc(events: []Event) {
	fd, err := os.open(EVENTS_PATH, os.O_CREATE | os.O_WRONLY)
	defer os.close(fd)

	data, _ := json.marshal(EventsData{events = events}, {pretty = true})

	os.write(fd, data)
}

command_add :: proc(title: string, recurrence: Recurrence) {
	context.random_generator = crypto.random_generator()

	event := Event {
		id         = uuid.to_string(uuid.generate_v4()),
		title      = title,
		recurrence = recurrence,
	}

	events := slice.to_dynamic(get_events())

	append(&events, event)

	save_events(events[:])
}

command_start :: proc() {
	for {
		events := get_events()

		now := time.now()

		for event in events {
			switch v in event.recurrence {
			// case Once:
			// 	unimplemented()

			case EveryWeek:
				if time.weekday(now) == time.Weekday(v.day_of_week) {
					hour, minute, second := time.clock(now)

					time, _ := datetime.components_to_time(
						hour + 2, // TODO: add timezone
						minute,
						second,
						0,
					)

					if v.time == time {
						create_toast(event.title, fmt.tprintf("[%02d:%02d]", hour, minute))
					}
				}
			}
		}

		time.sleep(time.Second)
	}
}

next_arg :: proc(args: ^[]string) -> string {
	if len(args) == 0 {
		log.fatal("Parsed more arguments then provided")
		os.exit(1)
	}

	arg := args[:1][0]
	args^ = args[1:]

	return arg
}

print_usage :: proc(program: string) {
	fmt.println("Usage:")
	fmt.printfln("\t%s <command> [arguments]", program)
	fmt.println("Commands:")
	fmt.println("\tadd <title> <recurrence> [arguments]")
	fmt.println("\tstart")
}

print_add_help :: proc(program: string) {
	fmt.println("Usage:")
	fmt.printfln("\t%s add <title> <recurrence>", program)
	fmt.println("Recurrence:")
	fmt.println("\tonce <time:24h> <date>")
	fmt.println("\tweek <time:24h> <day_of_week>")
}

string_to_number :: proc(str: string) -> i32 {
	result: i32

	for ch, i in str {
		result += i32(ch - 48) * i32(math.pow(10, f32(len(str) - 1 - i)))
	}

	return result
}

main :: proc() {
	context.random_generator = crypto.random_generator()

	time, err := datetime.components_to_time(15, 30, 0)
	day_of_week := datetime.Weekday.Monday

	recurrence := EveryWeek {
		time        = time,
		day_of_week = day_of_week,
	}

	event := Event {
		id         = uuid.to_string(uuid.generate_v4()),
		title      = "Go gym",
		recurrence = recurrence,
	}

	command := AddCommand {
		event = event,
	}
	encoded := encode(command)
	decoded := decode(encoded)

	fmt.println("original:", command)
	fmt.println("size:", size_of(command))

	fmt.println("encoded:", encoded)
	fmt.println("size:", size_of(encoded))

	fmt.println("decoded:", decoded)
	fmt.println("size:", size_of(decoded))

	fmt.println("same?", command == decoded)
}

main1 :: proc() {
	create_toast("Title", "Text")

	context.logger = log.create_console_logger(.Debug, {.Terminal_Color, .Level})

	args := os.args
	program := next_arg(&args)

	if len(args) == 0 {
		command_start()
		// print_usage(program)
		return
	}

	command := next_arg(&args)

	switch command {
	case "add":
		title := next_arg(&args)
		recurrence := next_arg(&args)

		switch recurrence {
		case "once":
			unimplemented()

		case "week":
			if len(args) != 2 {
				log.error("Invalid arguments for the \"week\" command")
				print_add_help(program)
				os.exit(1)
			}

			components := strings.split(next_arg(&args), ":")

			if len(components) != 2 {
				log.error("Invalid time format")
				log.info("Example: \"15:25\"")
				os.exit(1)
			}

			time, err := datetime.components_to_time(
				string_to_number(components[0]),
				string_to_number(components[1]),
				0,
			)

			if err != nil {
				log.error("Invalid time format")
				log.info("Example: \"15:25\"")
				os.exit(1)
			}

			day_of_week: datetime.Weekday
			switch next_arg(&args) {
			case "mo", "mon":
				day_of_week = .Monday

			case "tu", "tue":
				day_of_week = .Tuesday

			case "we", "wed":
				day_of_week = .Wednesday

			case "th", "thu":
				day_of_week = .Thursday

			case "fr", "fri":
				day_of_week = .Friday

			case "sa", "sat":
				day_of_week = .Saturday

			case "su", "sun":
				day_of_week = .Sunday
			}

			command_add(title, EveryWeek{time = time, day_of_week = day_of_week})
		}

	case "start":
		command_start()

	case:
		log.errorf("Unknown command \"%s\"", command)
	}
}
