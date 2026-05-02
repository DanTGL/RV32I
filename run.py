from vunit import VUnit

if __name__ == "__main__":
    vu = VUnit.from_argv(vhdl_standard="2008")

    vu.add_vhdl_builtins()
    vu.add_osvvm()

    lib = vu.add_library("lib")
    lib.add_source_files("hdl/*.vhd")
    lib.add_source_files("vunit/*.vhd")

    vu.main()
