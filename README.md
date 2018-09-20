# RISC-V

# Development environment (docker image)

``` bash
x11docker -- -v $(pwd):/src -- aptman/vhdl:spinal
```

Either append `xterm` to the command above, or acces from a different terminal with the command below:

``` bash
docker exec -it $(docker ps -q --filter=name=aptman-vhdl --format '{{.Names}}') bash
```

Then, in any case: `./runme.sh`

# VexRiscv

- Modify scala sources in `VexRiscv/src/main/scala/vexriscv/demo`:
  - `Murax.scala`
  - `MuraxUtiles.scala`
- Modify and build the program in `VexRiscvSocSoftware`:
  - `libs/axis.h`
  - `projects/murax/demo/src`
- Build `Murax.scala` from `VexRiscv`, in order to generate VHDL source:

``` bash
sbt "run-main vexriscv.demo.Murax"
# or
sbt "run-main vexriscv.demo.MuraxWithRamInit"
```
- Copy generated VHDL to from `VexRiscv/Murax.vhd` to `vhdl/srcs`.
- Profit.

> TODO Write C wrapper.

> TODO Add AXI Stream ports to Murax.

> TODO Add VGA to Murax.

> TODO How to use the JTAG port to program Murax/Briey from either the ARM or the x86 host?
