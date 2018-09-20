from vunit import VUnit

vu = VUnit.from_argv()

vu.add_verification_components()

lib = vu.add_library("lib")
lib.add_source_files("../../srcs/*.vhd")
lib.add_source_files("./*.vhd")

vu.main()
