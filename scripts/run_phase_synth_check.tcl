read_verilog {
  clock_amd.srcs/sources_1/new/button_pulse.v
  clock_amd.srcs/sources_1/new/clk_ring.v
  clock_amd.srcs/sources_1/new/time_core.v
  clock_amd.srcs/sources_1/new/date_core.v
  clock_amd.srcs/sources_1/new/hour_format_ctrl.v
  clock_amd.srcs/sources_1/new/hour_format_display.v
  clock_amd.srcs/sources_1/new/adt7420_reader.v
  clock_amd.srcs/sources_1/new/alarm_ctrl.v
  clock_amd.srcs/sources_1/new/countdown_ctrl.v
  clock_amd.srcs/sources_1/new/schedule_ctrl.v
  clock_amd.srcs/sources_1/new/notification_ctrl.v
  clock_amd.srcs/sources_1/new/oled_date_status.v
  clock_amd.srcs/sources_1/new/oled_countdown_status.v
  clock_amd.srcs/sources_1/new/oled_notify_status.v
  clock_amd.srcs/sources_1/new/uart_rx.v
  clock_amd.srcs/sources_1/new/uart_tx.v
  clock_amd.srcs/sources_1/new/protocol_parser.v
  clock_amd.srcs/sources_1/new/protocol_builder.v
  clock_amd.srcs/sources_1/new/message_store.v
  clock_amd.srcs/sources_1/new/preset_reply_rom.v
  clock_amd.srcs/sources_1/new/comm_ctrl.v
  clock_amd.srcs/sources_1/new/display_ctrl.v
  clock_amd.srcs/sources_1/new/seg_7.v
  clock_amd.srcs/sources_1/new/nexys_seg_scan.v
  clock_amd.srcs/sources_1/new/i2c_master_simple.v
  clock_amd.srcs/sources_1/new/oled_ui_display.v
  clock_amd.srcs/sources_1/new/ui_ctrl.v
  clock_amd.srcs/sources_1/new/clock.v
  clock_amd.srcs/sources_1/new/clock_amd_top.v
}
read_xdc clock_amd.srcs/constrs_1/new/clock_amd.xdc
synth_design -top clock_amd_top -part xc7a100tcsg324-1
report_timing_summary -no_header -no_detailed_paths
report_timing -max_paths 5 -nworst 1 -delay_type max -sort_by group
