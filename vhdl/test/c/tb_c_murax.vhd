library ieee;
context ieee.ieee_std_context;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;
use vunit_lib.core_pkg.stop;

entity tb_murax is
end entity;

architecture tb of tb_murax is
  constant baud_rate : integer := 115200; -- bits / s
  constant clk_period: time := 83333 ps;

  constant data_width : natural := 32;
  constant fifo_depth : natural := 4;

  -- UART Verification Components

  constant tx_uart_bfm : uart_master_t := new_uart_master(initial_baud_rate => baud_rate);
  constant tx_stream : stream_master_t := as_stream(tx_uart_bfm);

  constant rx_uart_bfm : uart_slave_t := new_uart_slave(initial_baud_rate => baud_rate);
  constant rx_stream : stream_slave_t := as_stream(rx_uart_bfm);

  -- AXI4Stream Verification Components

  constant m_axis : axi_stream_master_t := new_axi_stream_master(data_length => data_width);
  constant s_axis : axi_stream_slave_t := new_axi_stream_slave(data_length => data_width);

  -- Signals to/from the UUT from/to the verification components

  type uart_t is record
    tx, rx: std_logic;
  end record;

  signal uart: uart_t;

  type axis_t is record
    rdy, valid, last : std_logic;
    strb : std_logic_vector((data_width/8)-1 downto 0);
    data : std_logic_vector(data_width-1 downto 0);
  end record;

  signal m, s: axis_t;

  -- JTAG

  type jtag_t is record
    tms : std_logic;
    tdi : std_logic;
    tdo : std_logic;
    tck : std_logic;
  end record;

  signal jtag: jtag_t;

  -- GPIO

  type gpio_t is record
    rd : std_logic_vector(data_width-1 downto 0);
    wr : std_logic_vector(data_width-1 downto 0);
    we : std_logic_vector(data_width-1 downto 0);
  end record;

  signal gpioA: gpio_t;

  -- tb signals and variables

  signal rst : std_logic;
  signal clk : std_logic := '0';

begin

  clk <= not clk after (clk_period/2);

  main: process
  begin
    --info("Init test");
    asyncReset <= '1';
    wait for 50*clk_period;
    asyncReset <= '0';
    wait for 250 ms;
    --run_test;
    stop(0);
    wait;
  end process;
  test_runner_watchdog(runner, 1 ms);

---

  tx_bfm : entity vunit_lib.uart_master generic map ( uart => tx_uart_bfm ) port map ( tx => uart.rx );
  rx_bfm : entity vunit_lib.uart_slave generic map  ( uart => rx_uart_bfm ) port map ( rx => uart.tx );

---

  vunit_axism: entity vunit_lib.axi_stream_master generic map ( master => m_axis)
    port map (
      aclk   => clk,
      tvalid => m.valid,
      tready => m.rdy,
      tdata  => m.data,
      tlast  => m.last
    );

  vunit_axiss: entity vunit_lib.axi_stream_slave generic map ( slave => s_axis)
    port map (
      aclk   => clk,
      tvalid => s.valid,
      tready => s.rdy,
      tdata  => s.data,
      tlast  => s.last
    );

---

  m.last <= '0';

  murax: entity work.Murax
    port map (
      io_asyncReset          => rst,
      io_mainClk             => clk,
      io_jtag_tms            => jtag.tms,
      io_jtag_tdi            => jtag.tdi,
      io_jtag_tdo            => jtag.tdo,
      io_jtag_tck            => jtag.tck,
      io_gpioA_read          => gpioA.rd,
      io_gpioA_write         => gpioA.wr,
      io_gpioA_writeEnable   => gpioA.we,
      io_uart_txd            => uart.tx,
      io_uart_rxd            => uart.rx,
      io_axis_input_valid    => m.valid,
      io_axis_input_ready    => m.rdy,
      io_axis_input_payload  => m.data,
      io_axis_output_valid   => s.valid,
      io_axis_output_ready   => s.rdy,
      io_axis_output_payload => s.data
    );

end architecture;
