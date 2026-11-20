`include "uvm_macros.svh"
import uvm_pkg::*;


//--------------------//
// 0. interface
interface counter_if(input i_clk);
  logic         i_rst_n;
  logic         i_en;
  logic   [2:0] o_counter;
  logic         o_tick;
  // clocking for driver
  clocking drv_cb @(posedge i_clk);
    default input #1step output #1ns;
    output        i_rst_n;
    output        i_en;
  endclocking
  // clocking for monitor
  clocking mon_cb @(posedge i_clk);
  default input #1step;
  input           i_rst_n;
  input           i_en;
  input           o_counter;
  input           o_tick;
  endclocking
  // modport
  modport drv_mb (clocking drv_cb, input i_clk);
  modport mon_mb (clocking mon_cb, input i_clk);
  // 1) property
  property p_reset_clear_count;
    @(posedge i_clk) (!i_rst_n) |=> (o_counter == 3'b000);
  endproperty
  // 2) assertion
  A_RESET_CLEAR : assert property(p_reset_clear_count)
    else `uvm_error("ERROR","RESET_ASSERT property p_reset_clear_counter!")
endinterface
//--------------------//



//--------------------//
// 1. sequence_item
class counter_sequence_item extends uvm_sequence_item;
  // item list
        bit         i_rst_n;
  rand  bit         i_en;
        logic [2:0] o_counter;
        logic       o_tick;
  // constraint
  constraint c_en       {i_en     dist {0:=1, 1:=9};}
  // constructor
  function new(string name = "COUNTER_SEQUENCE_ITEM");
    super.new(name);
  endfunction
  // uvm factory registry
  `uvm_object_utils_begin(counter_sequence_item)
    `uvm_field_int(i_rst_n    , UVM_DEFAULT)
    `uvm_field_int(i_en       , UVM_DEFAULT)
    `uvm_field_int(o_counter  , UVM_DEFAULT)
    `uvm_field_int(o_tick     , UVM_DEFAULT)
  `uvm_object_utils_end
  // function 'conver2string'
  virtual function string convert2string();
    return $sformatf("i_rst_n = %b, i_en = %b, o_counter =  %d, o_tick = %b", i_rst_n, i_en, o_counter, o_tick);
  endfunction
endclass
//--------------------//


//--------------------//
// 2-1. sequence(for i_rst_n)
class counter_sequence_reset extends uvm_sequence#(counter_sequence_item);
  // uvm factory registry
  `uvm_object_utils(counter_sequence_reset)
  // handle declaration
  counter_sequence_item c_item;
  // constructor
  function new(string name = "COUNTER_SEQUENCE_RESET");
    super.new(name);
  endfunction
  // task 'body'
  virtual task body();
    repeat(5) begin
      // object creation
      c_item = counter_sequence_item::type_id::create("C_ITEM");
      start_item(c_item);   // start
      c_item.i_rst_n    = 0;
      c_item.i_en       = 0;
      // uvm_info message output
      `uvm_info(get_name(), c_item.convert2string(), UVM_HIGH)
      finish_item(c_item);  // finish
    end
  endtask
endclass
//--------------------//


//--------------------//
// 2-2. sequence(for i_en)
class counter_sequence extends uvm_sequence#(counter_sequence_item);
  // uvm factory registry
  `uvm_object_utils(counter_sequence)
  // handle declaration
  counter_sequence_item c_item;
  // constructor
  function new(string name = "COUNTER_SEQUENCE");
    super.new(name);
  endfunction
  // task 'body'
  virtual task body();
    repeat(100) begin
      // object creation
      c_item = counter_sequence_item::type_id::create("C_ITEM");
      // randomize
      start_item(c_item); // start
      if(!c_item.randomize()) begin
        // uvm_fatal message output
        `uvm_fatal(get_name(), "c_item randomized fail");
      end
      c_item.i_rst_n    = 1'b1;
      // uvm_info message output
      `uvm_info(get_name(), c_item.convert2string(), UVM_HIGH)
      finish_item(c_item); // finish
    end
  endtask
endclass
//--------------------//


//--------------------//
// 3. driver
class counter_driver extends uvm_driver #(counter_sequence_item);
  // uvm factory registry
  `uvm_component_utils(counter_driver)
  // handle declaration
  counter_sequence_item c_item;
  // virtual interface declaration
  virtual counter_if c_if;
  // counstructor
  function new(string name = "COUNTER_DRIVER", uvm_component c = null);
    super.new(name, c);
  endfunction
  // function 'build_phase'
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // uvm_fatal message output
    if(!uvm_config_db#(virtual counter_if)::get(this, "", "c_if", c_if)) begin
      `uvm_fatal(get_name(), "unable to access counter interface")
    end
  endfunction
  // task 'run phase'
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    // scenario run
    forever begin
      seq_item_port.get_next_item(c_item);
      @(c_if.drv_cb);
      c_if.drv_cb.i_rst_n <=  c_item.i_rst_n;
      c_if.drv_cb.i_en    <=  c_item.i_en;
      seq_item_port.item_done();
      // uvm_info message output
      `uvm_info(get_name(), c_item.convert2string(), UVM_HIGH)
    end
  endtask
endclass
//--------------------//


//--------------------//
// 4. monitor
class counter_monitor extends uvm_monitor;
  // uvm factory registry
  `uvm_component_utils(counter_monitor)
  // handle declaration
  counter_sequence_item c_item;
  uvm_analysis_port #(counter_sequence_item) send;
  // virtual interface declaration
  virtual counter_if c_if;
  // constructor
  function new(string name = "COUNTER_MON", uvm_component c = null);
    super.new(name, c);
    send = new("WRITE", this);
  endfunction
  // function 'build_phase'
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // uvm_fatal message output
    if(!uvm_config_db#(virtual counter_if)::get(this, "", "c_if", c_if)) begin
      `uvm_fatal(get_name(), "unable to access counter interface")
    end
  endfunction
  // task 'run_phase'
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      // object creation
      c_item = counter_sequence_item::type_id::create("C_ITEM");
      // monitor
      @(c_if.mon_cb);
      c_item.i_rst_n    =  c_if.mon_cb.i_rst_n;
      c_item.i_en       =  c_if.mon_cb.i_en;
      c_item.o_counter  =  c_if.mon_cb.o_counter;
      c_item.o_tick     =  c_if.mon_cb.o_tick;
      // uvm_info message output
      `uvm_info(get_name(), c_item.convert2string(), UVM_HIGH)
      // write to scoreboard
      send.write(c_item);
    end
  endtask
endclass
//--------------------//


//--------------------//
// 5. scoreboard
class counter_scoreboard extends uvm_scoreboard;
  // uvm factory registry
  `uvm_component_utils(counter_scoreboard)
  // handle declaration
  uvm_analysis_imp#(counter_sequence_item, counter_scoreboard) recv;
  // expected value declaration
  bit   [2:0] expected_count  = 3'b0;
  bit         expected_tick   = 1'b0;
  int         pass_cnt        = 0;
  int         fail_cnt        = 0;
  int         skip_cnt        = 0;
  // counstructor
  function new(string name, uvm_component c = null);
    super.new(name, c);
    recv = new("READ", this);
  endfunction
  // function 'write'
  virtual function void write(counter_sequence_item c_item);
    `uvm_info(get_name(), c_item.convert2string(), UVM_HIGH)
    if(!c_item.i_rst_n) begin
      `uvm_info(get_name(), $sformatf(" To skip : o_counter or o_tick is x"), UVM_NONE)
      skip_cnt++;
    end else begin
      // pass/fail
      if((expected_count == c_item.o_counter) && (expected_tick == c_item.o_tick)) begin
        `uvm_info(get_name(), $sformatf(" PASS!! \n expected_count = %b | o_counter = %b \n expected_tick = %b, o_tick = %b", expected_count, c_item.o_counter, expected_tick, c_item.o_tick), UVM_HIGH)
        pass_cnt++;
      end
      else begin
        `uvm_error(get_name(), $sformatf(" FAIL!! \n expected_count = %b | o_counter = %b \n expected_tick = %b, o_tick = %b", expected_count, c_item.o_counter, expected_tick, c_item.o_tick))
        fail_cnt++;
      end
      // designate expected c_item
      if(!c_item.i_rst_n) begin
        expected_count    = 3'b0;
        expected_tick     = 1'b0;
      end
      else begin
        if(c_item.i_en) begin
          if(c_item.o_counter >=7) begin
            expected_count    = 3'b0;
            expected_tick     = 1'b1;
          end
          else begin
            expected_count++;
            expected_tick = 1'b0;
          end
        end
        else begin
          expected_tick = 0;
        end
      end
    end
  endfunction
  // function 'report_phase'
  virtual function void report_phase(uvm_phase phase);
    `uvm_info(get_name(), $sformatf("\n=== PASS : %d === \n=== FAIL : %d === \n=== SKIP : %d ===", pass_cnt, fail_cnt, skip_cnt),UVM_NONE)
    if(!(pass_cnt + fail_cnt))
      `uvm_error(get_name(), "No transaction received !!!")
  endfunction
endclass
//--------------------//


//--------------------//
// 6. agent
class counter_agent extends uvm_agent;
  // uvm factory registry
  `uvm_component_utils(counter_agent)
  // handle declaration
  uvm_sequencer #(counter_sequence_item) c_sqr;
  counter_driver  c_drv;
  counter_monitor c_mon;
  // constructor
  function new(string name = "COUNTER_AGENT", uvm_component c = null);
    super.new(name, c);
  endfunction
  // function 'build_phase'
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    c_sqr = uvm_sequencer#(counter_sequence_item)::type_id::create("C_SQR", this);
    c_drv = counter_driver::type_id::create("C_DRV", this);
    c_mon = counter_monitor::type_id::create("C_MON", this);
  endfunction
  // function 'connect_phase'(for sequencer and driver)
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    c_drv.seq_item_port.connect(c_sqr.seq_item_export);
  endfunction
endclass
//--------------------//


//--------------------//
// 7. environment
class counter_environment extends uvm_env;
  // uvm factory registry
  `uvm_component_utils(counter_environment)
  // handle declaration
  counter_agent       c_agt;
  counter_scoreboard  c_scb;
  // constructor
  function new(string name = "COUNTER_AGENT", uvm_component c = null);
    super.new(name, c);
  endfunction
  // function 'build_phase'
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // object creation
    c_agt = counter_agent::type_id::create("C_AGT", this);
    c_scb = counter_scoreboard::type_id::create("C_SCB", this);
  endfunction
  // function 'connect_phase'(for monitor and scoreboard)
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    c_agt.c_mon.send.connect(c_scb.recv);
  endfunction
endclass
//--------------------//


//--------------------//
// 8. test
class counter_test extends uvm_test;
  // uvm factory registy
  `uvm_component_utils(counter_test)
  // handle declaration
  counter_environment       c_env;
  counter_sequence_reset    c_seq_rst;
  counter_sequence          c_seq;
  // counstructor
  function new(string name = "COUNTER_TEST", uvm_component c = null);
    super.new(name, c);
  endfunction
  // function 'build_phase'
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // object creation
    c_env           = counter_environment::type_id::create("C_ENV", this);
    c_seq_rst       = counter_sequence_reset::type_id::create("C_SEQ_RST",this);
    c_seq           = counter_sequence::type_id::create("C_SEQ");
  endfunction
  // task 'run_phase'
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);                        // start
    c_seq_rst.start(c_env.c_agt.c_sqr);                 // item transfer to sequencer
    phase.drop_objection(this);                         // finish
    phase.raise_objection(this);                        // start
    c_seq.start(c_env.c_agt.c_sqr);                     // item transfer to sequencer
    repeat(2) @(posedge c_env.c_agt.c_drv.c_if.i_clk); 
    phase.drop_objection(this);                         // finish
  endtask
endclass
//--------------------//


//--------------------//
// top tb module
module tb_counter();
  logic i_clk = 0;
  always #5 i_clk = ~ i_clk;
  // interface instantiation
  counter_if  c_if(i_clk);
  // DUT instantiation
  counter DUT(
    .i_clk      (i_clk),
    .i_rst_n    (c_if.i_rst_n),
    .i_en       (c_if.i_en),
    .o_counter  (c_if.o_counter),
    .o_tick     (c_if.o_tick)
  );
  // vcs wave db
  initial begin
    $fsdbDumpfile("wave.fsdb");
    $fsdbDumpvars(0, tb_counter);
  end
  // run
  initial begin
    uvm_config_db#(virtual counter_if)::set(null, "*", "c_if", c_if);
    run_test("counter_test");
  end
endmodule
//--------------------//
