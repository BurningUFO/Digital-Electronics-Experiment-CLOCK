open_project clock_amd.xpr

set required_files {
  comm_ctrl.v
  message_store.v
  preset_reply_rom.v
  protocol_builder.v
  protocol_parser.v
  uart_rx.v
  uart_tx.v
}

set missing {}
foreach file_name $required_files {
  set matches [get_files -quiet "*$file_name"]
  if {[llength $matches] == 0} {
    lappend missing $file_name
  }
}

if {[llength $missing] != 0} {
  puts "ERROR: missing ClockLink source files in clock_amd.xpr: $missing"
  exit 1
}

update_compile_order -fileset sources_1
puts "PASS: ClockLink source files are present in clock_amd.xpr"
close_project
