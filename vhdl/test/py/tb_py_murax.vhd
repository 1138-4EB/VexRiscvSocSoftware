library ieee;
context ieee.ieee_std_context;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

entity tb_murax is
  generic ( runner_cfg : string );
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

  type axis_data_t is array(integer range 0 to 7) of std_logic_vector(data_width-1 downto 0);
  signal axis_data_in: axis_data_t := (X"0000FFEE", X"0000DDCC", X"0000BBAA", X"00009988", X"00007766", X"00005544", X"00003322", X"00001100");

begin

  clk <= not clk after (clk_period/2);

  main : process
    variable data : std_logic_vector(7 downto 0);
    variable word : std_logic_vector(31 downto 0);
    variable last : std_logic;
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("test") then
        info("Init test");
        rst <= '1';
        wait for clk_period*10;
        rst <= '0';
        wait for 10 us;

        pop_stream(net, rx_stream, data);
        info(to_string(data));

        for x in 0 to axis_data_in'length-1 loop
          push_axi_stream(net, m_axis, axis_data_in(x), tlast => '0');
        end loop;

--        push_stream(net, tx_stream, x"77");
--        pop_stream(net, rx_stream, data);
--        info(to_string(data));

        for x in 0 to axis_data_in'length-1 loop
          pop_axi_stream(net, s_axis, tdata => word, tlast => last);
          info(to_string(word));
          check_equal(3*unsigned(axis_data_in(x)), unsigned(word));
        end loop;

      end if;
    end loop;
    test_runner_cleanup(runner);
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
