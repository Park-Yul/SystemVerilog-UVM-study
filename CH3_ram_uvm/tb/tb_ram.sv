`include "uvm_macros.sv"
import uvm_pkg::*;

//---------------------
// 0. interface
interface ram_if(input i_clk);
  // port declaratin
  logic       i_we;
  logic [7:0] i_addr;
  logic [7:0] i_wdata;
  logic [7:0] o_rdata;
  
  // clocking
  
  // modport

  // property
  
  // assertion

endinterface
//---------------------


//---------------------
// 1. sequence_item
class ram_seq_item extends uvm_sequence_item;
  // port declaration
  rand  bit         i_we;
  rand  bit   [7:0] i_addr;
  rand  bit   [7:0] i_wdata;
        logic [7:0] o_rdata;

  // constraint
  constraint  c_we  { i_we  dist{ 0:=1, 1:=1};}

  // counstructor
  function new(string name = "RAM_SEQUENCE_ITEM");
    super.new(name);
  endfunction

  // uvm factory registry
  `uvm_object_utils_begin(ram_seq_item)
  `uvm_field_int(i_we,    UVM_DEFAULT)
  `uvm_field_int(i_addr,  UVM_DEFAULT)
  `uvm_field_int(i_wdata, UVM_DEFAULT)
  `uvm_field_int(o_rdata, UVM_DEFAULT)
  `uvm_object_utils_end

  // function 'conver2string'
  virtual function string convert2string();
    return $sformatf("\ni_we = %b, i_addr = 8'h%h, i_wdata = 8'h%h, o_rdata = 8'h%h \n", i_we, i_addr, i_wdata, o_rdata);
  endfunction

endclass
//--------------------


//---------------------
// 2. sequence
class ram_sequence extends uvm_sequence #(ram_seq_item);
  // uvm factory registry
  `uvm_object_utils(ram_sequence)

  // handle declaration
  ram_seq_item r_item;

  // constructor
  function new(string name = "RAM_SEQUENCE");
    super.new(name);
  endfunction

  // task 'body'
  virtual task body();
    repeat(100) begin
      r_item = ram_seq_item::type_id::create("ITEM");
      start_item(r_item);
      if(!r_item.randomize())
        `uvm_fatal(get_name(), $sformatf("\n%s randomized fail\n", get_type_name()))
      finish_item(r_item);
      `uvm_info(get_name(), r_item.convert2string(), UVM_HIGH)
    end
  endtask

endclass
//---------------------


//---------------------
// 3. driver
class ram_driver extends uvm_driver #(ram_seq_item);
  // uvm factory registry
  `uvm_component_utils(ram_driver)

  // handle declaration
  ram_seq_item r_item;

  // virtual interface declaration
  virtual ram_if r_if;

  // constructor
  function new(string name = "RAM_DRIVER", uvm_component c = null);
    super.new(name, c);
  endfunction

  // function 'build_phase'
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db #(virtual ram_if)::get(this, "", "r_if", r_if)) begin
      `uvm_fatal(get_name(), "\nbuild phase : can't access virtual interface\n")
    end
  endfunction

  // task 'run_phase'
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(r_item);
      @(posedge r_if.i_clk) #2;
      r_if.i_we       <=  r_item.i_we;
      r_if.i_addr     <=  r_item.i_addr;
      r_if.i_wdata    <=  r_item.i_wdata;
      seq_item_port.item_done();
      `uvm_info(get_name(), r_item.convert2string(), UVM_HIGH)
    end
  endtask

endclass
//---------------------


//---------------------
// 4. monitor
class ram_monitor extends uvm_monitor;
  // uvm factory registry
  `uvm_component_utils (ram_monitor)

  // handle declaration
  ram_seq_item r_item;
  uvm_analysis_port#(ram_seq_item) send;

  // virtual interface declaration
  virtual ram_if r_if;

  // constructor
  function new(string name = "RAM MONITOR", uvm_component c = null);
    super.new(name, c);
    send = new("WRITE", this);
  endfunction

  // function 'build_phase'
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db #(virtual ram_if)::get(this, "", "r_if", r_if)) begin
      `uvm_fatal(get_name(), "\nbuild phase : can't access virtual interface\n")
    end
  endfunction

  // task 'run_phase'
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      r_item = ram_seq_item::type_id::create("ITEM");
      @(posedge r_if.i_clk) #1;
      r_item.i_we       = r_if.i_we;
      r_item.i_addr     = r_if.i_addr;
      r_item.i_wdata    = r_if.i_wdata;
      r_item.o_rdata    = r_if.o_rdata;
      `uvm_info(get_name(), r_item.convert2string(), UVM_HIGH)
      send.write(r_item);
    end
  endtask
endclass
//---------------------


//---------------------
// 5. agent
class ram_agent extends uvm_agent;
  // uvm factory registry
  `uvm_component_utils(ram_agent)

  // handle declaration
  uvm_sequencer#(ram_seq_item)      r_sqr;
  ram_driver                        r_drv;
  ram_monitor                       r_mon;

  // constructor
  function new(string name = "RAM_AGENT", uvm_component c = null);
    super.new(name, c);
  endfunction

  // function 'build_phase'
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    r_sqr = uvm_sequencer#(ram_seq_item)::type_id::create("SQR", this);
    r_drv = ram_driver::type_id::create("DRV", this);
    r_mon = ram_monitor::type_id::create("MON", this);
  endfunction

  // function 'connect_phase'
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    r_drv.seq_item_port.connect(r_sqr.seq_item_export);
  endfunction

endclass
//---------------------


//---------------------
// 6. scoreboard
class ram_scoreboard extends uvm_scoreboard;
  // uvm factory registry
 `uvm_component_utils(ram_scoreboard)

  // handle declaration
  uvm_analysis_imp #(ram_seq_item, ram_scoreboard) recv;

  // value declaration for scoring
  logic [7:0] ram_buffer[0:255];
  int pass_cnt = 0, fail_cnt = 0;

  // constructor
  function new(string name = "RAM_SCOREBOARD", uvm_component c = null);
    super.new(name, c);
    recv = new("READ", this);
  endfunction

  // function 'write'
  virtual function void write(ram_seq_item r_item);
    if(r_item.i_we) begin
      ram_buffer[r_item.i_addr] = r_item.i_wdata;
      if(r_item.i_wdata == r_item.o_rdata) begin
        `uvm_info(get_name(), $sformatf("\nPASS!! i_wdata = 8'h%h, o_rdata = 8'h%h\n", r_item.i_wdata, r_item.o_rdata), UVM_HIGH)
        pass_cnt++;
      end
      else begin
        `uvm_error(get_name(), "\nFAIL !!")
        `uvm_info(get_name(), r_item.convert2string(), UVM_NONE)
        fail_cnt++;
      end
    end
    else begin
      if(ram_buffer[r_item.i_addr] ===  r_item.o_rdata) begin
        `uvm_info(get_name(), $sformatf("\nPASS !! ram_buffer = 8'h%h, o_rdata = 8'h%h\n", ram_buffer[r_item.i_addr], r_item.o_rdata) , UVM_HIGH)
        pass_cnt++;
      end
      else begin
        `uvm_error(get_name(), "\nFAIL !!")
        `uvm_info(get_name(), r_item.convert2string(), UVM_NONE)
        `uvm_info(get_name(), $sformatf("ram_buffer = 8'h%h\n", ram_buffer[r_item.i_addr]), UVM_HIGH)
        fail_cnt++;
      end
    end
  endfunction

  // function 'report_phase'
  virtual function void report_phase(uvm_phase phase);
    `uvm_info(get_name(), $sformatf("\n***** Scoreboard Report *****"), UVM_NONE)
    `uvm_info(get_name(), $sformatf("\n=== PASS : %d === \n=== FAIL : %d === ", pass_cnt, fail_cnt), UVM_NONE)
    `uvm_info(get_name(), $sformatf("\n***************************\n"), UVM_NONE)
    if(!(pass_cnt + fail_cnt)) begin
      `uvm_error(get_name(), "\nNo transaction received!!!\n")
    end
  endfunction

endclass
//---------------------


//--------------------
// +coverage
class ram_coverage extends uvm_subscriber#(ram_seq_item);
  // uvm factory registry
  `uvm_component_utils(ram_coverage)

  // handle declaration
  ram_seq_item r_item;

  // covergroup
  covergroup ram_cg;
    option.per_instance = 1;

    cp_we: coverpoint r_item.i_we {
      bins write[]  = {1};
      bins read[]   = {[0:1]};
    }
    cp_addr: coverpoint r_item.i_addr {
      bins range_0_to_255[] = {[0:255]};
    }
    cp_wdata: coverpoint r_item.i_wdata iff(r_item.i_we == 1){
      bins range_0_to_255[] = {[0:255]};
    }
    cp_rdata: coverpoint r_item.o_rdata {
      bins range_0_to_255[] = {[0:255]};
    }
    cx_wdata_addr : cross cp_wdata, cp_addr;
    cx_addr_wdata : cross cp_addr, cp_wdata;
  endgroup

  // constructor
  function new(string name = "RAM_COVERAGE", uvm_component c = null);
    super.new(name, c);
    ram_cg = new();
  endfunction

  // function 'write'
  virtual function void write(ram_seq_item t);
    r_item = t;
    ram_cg.sample();  // sample, bins one time hit
  endfunction

  // function 'report_phase'
  virtual function  void report_phase(uvm_phase phase); 
    `uvm_info(get_name(), $sformatf("\n***** Coverage Report *****"), UVM_NONE)
    `uvm_info(get_name(), $sformatf("\n=== Overall        : %.2f%% === ", ram_cg.get_coverage), UVM_NONE)
    `uvm_info(get_name(), $sformatf("\n=== i_we           : %.2f%% === ", ram_cg.cp_we.get_coverage), UVM_NONE)
    `uvm_info(get_name(), $sformatf("\n=== i_addr         : %.2f%% === ", ram_cg.cp_addr.get_coverage), UVM_NONE)
    `uvm_info(get_name(), $sformatf("\n=== i_wdata        : %.2f%% === ", ram_cg.cp_wdata.get_coverage), UVM_NONE)
    `uvm_info(get_name(), $sformatf("\n=== o_rdata        : %.2f%% === ", ram_cg.cp_rdata.get_coverage), UVM_NONE)
    `uvm_info(get_name(), $sformatf("\n=== i_rdata/i_addr : %.2f%% === ", ram_cg.cx_wdata_addr.get_coverage), UVM_NONE)
    `uvm_info(get_name(), $sformatf("\n***************************\n"), UVM_NONE)
  endfunction
endclass
//---------------------


//---------------------
// 7. environment
class ram_environment extends uvm_env;
  // uvm factory registry
  `uvm_component_utils(ram_environment)

  // handle declaration
  ram_agent         r_agt;
  ram_scoreboard    r_scb;
  ram_coverage      r_cov;

  // constructor
  function new(string name = "RAM_ENVIRONMENT", uvm_component c = null);
    super.new(name, c);
  endfunction

  // function 'build_phase'
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    r_agt = ram_agent::type_id::create("AGT", this);
    r_scb = ram_scoreboard::type_id::create("SCB", this);
    r_cov = ram_coverage::type_id::create("COV", this);
  endfunction

  // function 'connect_phase'
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    r_agt.r_mon.send.connect(r_scb.recv);
    r_agt.r_mon.send.connect(r_cov.analysis_export);  // monitor : caller |  scoreboard, coverage : callee
  endfunction

endclass
//---------------------


//---------------------
// 8. test
class ram_test extends uvm_test;
  // uvm factory registry
  `uvm_component_utils(ram_test)

  // handle declaration
  ram_environment    r_env;
  ram_sequence       r_seq;

  // construnctor
  function new(string name = "RAM_TEST", uvm_component c = null);
    super.new(name, c);
  endfunction

  // function 'build_phase'
  virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  r_env = ram_environment::type_id::create("ENV", this);
  r_seq = ram_sequence::type_id::create("SEQ", this);
  endfunction

  // task 'run_phase'
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    r_seq.start(r_env.r_agt.r_sqr);
    phase.drop_objection(this);
  endtask

endclass
//---------------------


//---------------------
// tb
module tb_ram;
  // clock generation
  logic i_clk=0;
  always #5 i_clk = ~i_clk;

  // interface instantiation
  ram_if r_if(i_clk);

  // run
  initial begin
    uvm_config_db#(virtual ram_if)::set(null, "*", "r_if", r_if);
    run_test("ram_test");
  end

  // DUT instantiation
  ram DUT(
  .i_clk  (i_clk),
  .i_we   (r_if.i_we),
  .i_addr (r_if.i_addr),
  .i_wdata(r_if.i_wdata),
  .o_rdata(r_if.o_rdata)
  );
//
//  // scenario
//  initial begin
//    r_if.i_we = 1'b0;
//    r_if.i_addr = 0;
//    r_if.i_wdata = 0;
//
//    @(posedge i_clk) #1;
//    r_if.i_we = 1'b1;
//    r_if.i_addr = 8'h34;
//    r_if.i_wdata = 8'haa;
//
//    @(negedge i_clk)
//    @(negedge i_clk)
//    $finish;
//  end

  // fsdb
  initial begin
    $fsdbDumpfile("wave.fsdb");
    $fsdbDumpvars(0, tb_ram);
  end

endmodule
//---------------------


//---------------------

//---------------------
