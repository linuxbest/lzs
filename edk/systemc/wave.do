set binopt {-logic}
set hexopt {-literal -hex}
if { [info exists PathSeparator] } { set ps $PathSeparator } else { set ps "/" }
if { ![info exists tbpath] } { set tbpath "/system_tb${ps}dut" }

  eval add wave -noupdate -divider {"comp_unit_0"}
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0${ps}CPMDMALLCLK
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0${ps}LLDMARSTENGINEREQ
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0${ps}DMALLRSTENGINEACK
  eval add wave -noupdate $hexopt $tbpath${ps}comp_unit_0${ps}LLDMARXD
  eval add wave -noupdate $hexopt $tbpath${ps}comp_unit_0${ps}LLDMARXREM
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0${ps}LLDMARXSOFN
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0${ps}LLDMARXEOFN
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0${ps}LLDMARXSOPN
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0${ps}LLDMARXEOPN
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0${ps}LLDMARXSRCRDYN
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0${ps}DMALLRXDSTRDYN
  eval add wave -noupdate $hexopt $tbpath${ps}comp_unit_0${ps}DMALLTXD
  eval add wave -noupdate $hexopt $tbpath${ps}comp_unit_0${ps}DMALLTXREM
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0${ps}DMALLTXSOFN
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0${ps}DMALLTXEOFN
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0${ps}DMALLTXSOPN
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0${ps}DMALLTXEOPN
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0${ps}DMALLTXSRCRDYN
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0${ps}LLDMATXDSTRDYN
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0${ps}DMATXIRQ
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0${ps}DMARXIRQ
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0${ps}src_last
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0${ps}dst_end
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0${ps}dst_start

  eval add wave -noupdate -divider {"codeout"}
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0/comp_unit_0/u_mod${ps}wb_clk_i
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0/comp_unit_0/u_mod${ps}m_reset

  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0/comp_unit_0/u_mod${ps}m_src
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0/comp_unit_0/u_mod${ps}m_src_getn
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0/comp_unit_0/u_mod${ps}m_src_last
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0/comp_unit_0/u_mod${ps}m_src_almost_empty
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0/comp_unit_0/u_mod${ps}m_src_empty

  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0/comp_unit_0/u_mod${ps}m_dst_putn
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0/comp_unit_0/u_mod${ps}m_dst_last
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0/comp_unit_0/u_mod${ps}m_endn
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0/comp_unit_0/u_mod${ps}m_dst
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0/comp_unit_0/u_mod${ps}m_dst_almost_full
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0/comp_unit_0/u_mod${ps}m_dst_full
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0/comp_unit_0/u_mod${ps}en_out_data
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0/comp_unit_0/u_mod${ps}de_out_data
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0/comp_unit_0/u_mod${ps}en_out_valid
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0/comp_unit_0/u_mod${ps}de_out_valid
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0/comp_unit_0/u_mod${ps}en_out_done
  eval add wave -noupdate $binopt $tbpath${ps}comp_unit_0/comp_unit_0/u_mod${ps}de_out_done

