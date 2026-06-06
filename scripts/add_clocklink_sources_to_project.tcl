set opened_here 0

if {[llength [get_projects -quiet]] == 0} {
  open_project clock_amd.xpr
  set opened_here 1
}

set project_dir [get_property DIRECTORY [current_project]]
set source_dir [file normalize [file join $project_dir clock_amd.srcs sources_1 new]]

set required_files {
  uart_rx.v
  uart_tx.v
  protocol_parser.v
  protocol_builder.v
  message_store.v
  preset_reply_rom.v
  comm_ctrl.v
}

set missing_paths {}
foreach file_name $required_files {
  set source_path [file normalize [file join $source_dir $file_name]]
  if {![file exists $source_path]} {
    puts "ERROR: expected source file not found: $source_path"
    puts "ERROR: make sure you opened the final project directory, not the old CLOCK/clock_amd copy."
    exit 1
  }

  if {[llength [get_files -quiet $source_path]] == 0 && [llength [get_files -quiet "*$file_name"]] == 0} {
    lappend missing_paths $source_path
  }
}

if {[llength $missing_paths] != 0} {
  puts "Adding ClockLink source files to sources_1:"
  foreach source_path $missing_paths {
    puts "  $source_path"
  }
  add_files -fileset sources_1 $missing_paths
} else {
  puts "ClockLink source files already exist in sources_1."
}

update_compile_order -fileset sources_1
save_project
puts "PASS: ClockLink source files are present and project is saved."

if {$opened_here} {
  close_project
}
