####
#
#

xload_xilinx_library libmXMLTclIf

proc update_version_proc {param_handle} {
	set    mhsinst      [xget_hw_parent_handle $param_handle]
	set    ipinsthandle [xget_hw_mpd_handle $mhsinst]
	set    ipdir        [xget_hw_pcore_dir_from_mpd $ipinsthandle]
	set    version      [exec ./setlocalversion $ipdir]

	return [expr 0x$version];
}
