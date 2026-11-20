`timescale 1ns / 1ps
`include "uvm_macros.svh"    // define : uvm_* macro
import uvm_pkg::*;           // import : UVM package

//----------------------//
// 0. interface
interface adder_if(
    input bit clk
);

logic [7:0] a;
logic [7:0] b;
logic [8:0] y;  // result

endinterface
//----------------------//


//----------------------//
// 1. transaction -> seq_item from uvm_sequence_item
class seq_item extends uvm_sequence_item;
    rand bit [7:0] a;   // stimulus
    rand bit [7:0] b;   // stimulus
    logic [8:0] y;      // monitoring stimulus

    // constructor
    function new(string name = "ADDER_Seq_item");   
        super.new(name);
    endfunction

    `uvm_object_utils_begin(seq_item)   // `uvm_object_utils : factory registry -> write the class name in ()
        `uvm_field_int(a, UVM_DEFAULT)  // UVM_DEFAULT : include print(), copy(), pack(),...
        `uvm_field_int(b, UVM_DEFAULT)
        `uvm_field_int(y, UVM_DEFAULT)
    `uvm_object_utils_end 
endclass
//----------------------//


//----------------------//
// 2. sequence(=generator)
// randomize seq_item(transaction object)
class adder_sequence extends uvm_sequence #(seq_item);
    // factory registry
    `uvm_object_utils(adder_sequence)  

    // seq_item(transaction) handle declaration
    seq_item adder_seq_item;    

    // constructor
    function new(string name = "ADDER_Sequence");
        super.new(name);
    endfunction

    // task : body -> generate random value and replaces mailbox 'put'
    task body(); 
        repeat(100) begin
        // like seq_item(transaction) handle dynamic allocation
        // format : 'handle name' = 'class name'::type_id::create("");
        adder_seq_item = seq_item::type_id::create("SEQ_ITEM"); 
        start_item(adder_seq_item); // transaction start
            // randomize
            if(!adder_seq_item.randomize()) begin
                // error message output
                `uvm_fatal("SEQ", "adder_seq_item randomized fail")
            end
            // message output : to TCL console, log
            // sformat : task, sformatf : function, there is return
            `uvm_info("SEQ", $sformatf(" a = %d, b = %d", adder_seq_item.a, adder_seq_item.b), UVM_HIGH) // UVM_MEDIUM : message level
        finish_item(adder_seq_item); // transaction finish
        end
    endtask
endclass
//----------------------//


//----------------------//
// 3. driver
// from sequence with seq_item to drive to interface
class adder_driver extends uvm_driver #(seq_item); // #(seq_item) : like mailbox datatype select
    // factory registry
    `uvm_component_utils(adder_driver)

    // seq_item(transaction) handle declaration
    seq_item adder_seq_item;

    // virtual interface declaration
    virtual adder_if a_vif;

    // constructor
    function new(string name = "ADDER_DRV", uvm_component c=null);
        super.new(name, c);
    endfunction

    // function : build phase -> components configurtion
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual adder_if)::get(this, "", "a_vif", a_vif))begin
            `uvm_fatal(get_name(), "unable to access adder interface")
        end
    endfunction

    // connect phase -> connect transaction to components(will be used in agent and environments

    // task : run phase -> operation
    task run_phase(uvm_phase phase);
    a_vif.a = 0;
    a_vif.b = 0;
    forever begin
        // to drive to interface
        // handshaking
        seq_item_port.get_next_item(adder_seq_item); // replaces mailbox 'get'

        @(posedge a_vif.clk);
        a_vif.a <= adder_seq_item.a;
        a_vif.b <= adder_seq_item.b;

        seq_item_port.item_done(); // done to use seq_item(transaction) object
    end
    endtask

    // report_phase -> score report(will be used in scoreboard)

endclass
//----------------------//

// sequence <-> driver is 1:1 communication through 'sequencer'
// 'sequencer' is built-in(don't need to design)
// 'sequencer' is like 'FIFO mailbox' for multiple transactions
// 'sequencer' is declared in 'adder_agent'
// need to be connected in 'adder_agent' using 'connect_phase'

//----------------------//
// 4. monitor
class adder_monitor extends uvm_monitor();
    // factory registry
    `uvm_component_utils(adder_monitor)

    // uvm_analysis_port handle declaration
    // broadcasting(to scoreboard, coverage,...) -> replaces mailbox 'put'
    // port for receiving function pointer(from scoreboard, coverage,...)
    uvm_analysis_port #(seq_item) send; 

    // virtual interface
    virtual adder_if    a_vif;
    
    // transaction handle declaration
    seq_item        adder_seq_item;

    // constructor
    function new(string name = "ADDER_MON", uvm_component c =null);
        super.new(name, c);
        send = new("WRITE" , this);
    endfunction

    // function : build phase
    function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual adder_if)::get(this, "", "a_vif", a_vif))begin
            `uvm_fatal(get_name(), "unable to access adder interface")
        end
    endfunction

    // task : run_phase
    task run_phase(uvm_phase phase);
    forever begin
        // create
        // liketransaction handle dynamic allocation
        // check...
        adder_seq_item = seq_item::type_id::create("SEQ_ITEM");

        @(posedge a_vif.clk);
        adder_seq_item.a = a_vif.a;
        adder_seq_item.b = a_vif.b;
        adder_seq_item.y = a_vif.y;
        send.write(adder_seq_item);
        `uvm_info("MON", $sformatf(" a = %d, b = %d", adder_seq_item.a, adder_seq_item.b), UVM_HIGH)
    end
    endtask
endclass
//----------------------//


//----------------------//
// 5. scoreboard
class adder_scoreboard extends uvm_scoreboard();
    // factory registry
    `uvm_component_utils(adder_scoreboard)

    // uvm_analysis_imp handle declaration
    // for receiving transaction
    // imp for sending function pointer to monitor
    uvm_analysis_imp #(seq_item, adder_scoreboard) recv; 

    // constructor
    function new(string name = "ADDER_SCB", uvm_component c = null);
        super.new(name, c);
        recv = new("READ", this);
    endfunction

    // bit declaration for comparison
    bit [8:0] expected_data = 0;
    int pass_cnt = 0, fail_cnt = 0;
    
    function void write(seq_item data);
        // pass/fail decision
        expected_data = data.a + data.b;
        if( expected_data == data.y) begin
            `uvm_info("SCB", $sformatf(" PASS : a = %d, b = %d, y = %d", data.a, data.b, data.y), UVM_HIGH)
            pass_cnt++;
        end
        else begin
            `uvm_info("SCB", $sformatf(" FAIL : a = %d, b = %d, y = %d", data.a, data.b, data.y), UVM_HIGH)
            fail_cnt++;
        end 
    endfunction

    // function : report_phase
    function void report_phase(uvm_phase phase);
        `uvm_info("SCB", $sformatf("\n=== PASS : %d === \n=== FAIL : %d", pass_cnt, fail_cnt), UVM_HIGH)
        if(!(pass_cnt + fail_cnt)) // no transaction
            `uvm_error("SCB", "No transaction reeived !!!")
    endfunction
endclass
//----------------------//

// mointor <-> scoreboard is 1:N communication through function pointer or 'export'
// need to be connected in 'adder_agent' using 'connect_phase'

//----------------------//
// 6. Agent 
// include sequencer + driver + monitor
class adder_agent extends uvm_agent;
    // factory registry
    `uvm_component_utils(adder_agent)

    // adder_driver, adder_monitor, uvm_sequencer handle declaration
    adder_driver adder_drv;
    adder_monitor adder_mon;
    uvm_sequencer #(seq_item) adder_sqr;    // 'sequencer' -> built-in(don't need to design)

    // constructor
    function new(string name = "ADDER_AGT", uvm_component c = null);
        super.new(name, c);
    endfunction

    // function : build_phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // create adder_drv, adder_mon, adder_sqr
        // like dynamic allocation
        // 'this' means 'this class'
        adder_drv = adder_driver::type_id::create("DRV", this); // for driver
        adder_mon = adder_monitor::type_id::create("MON", this);    // for monior
        adder_sqr = uvm_sequencer #(seq_item)::type_id::create("SQR", this);    // for sequencer
    endfunction

    // function : connect_phase -> connect sequencer and driver 
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        adder_drv.seq_item_port.connect(adder_sqr.seq_item_export);  
    endfunction
endclass
//----------------------//

// new() vs. create()
// new() : dynamic allocation during process
// create() : standardized enrollment(static allocation)

//----------------------//
// 7. environment
// include agent + scoreboard
class adder_environment extends uvm_env;
    // factory registry
    `uvm_component_utils(adder_environment)

    // adder_agent, adder_scoreboard handle declaration
    adder_agent adder_agt;
    adder_scoreboard adder_scb;

    // constructor
    function new(string name = "ADDER_ENV", uvm_component c = null);
        super.new(name, c);
    endfunction

    // function : build_phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // create adder_agt, adder_scb
        adder_agt = adder_agent::type_id::create("AGT", this);
        adder_scb = adder_scoreboard::type_id::create("SCB", this);
    endfunction

    // function : connect_phase -> connect monitor's uvm_analysis_port and scoreboard's uvm_analysis_imp
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        adder_agt.adder_mon.send.connect(adder_scb.recv);
    endfunction
endclass
//----------------------//


//----------------------//
// 8. test
// include sequence + environment
// top_scenario, run_test
class adder_test extends uvm_test;
    // factory registry
    `uvm_component_utils(adder_test)

    //adder_sequence, adder_environment handle declaration
    adder_sequence adder_seq;
    adder_environment adder_env;

    // constructor
    function new(string name = "ADDER_TEST", uvm_component c = null);
        super.new(name, c);
    endfunction

    // function : build_phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // create adder_seq, adder_env
        adder_seq = adder_sequence::type_id::create("SEQ", this);
        adder_env = adder_environment::type_id::create("ENV", this);  
    endfunction

    // task : run_phase
    task run_phase(uvm_phase phase);
        // start run phase
        phase.raise_objection(this);

        // generate sequence and go to the sequencer
        adder_seq.start(adder_env.adder_agt.adder_sqr);

        #100;

        // stop run phase
        phase.drop_objection(this);
    endtask
endclass

//----------------------//


//----------------------//
// tb
module tb_adder_uvm();
    logic clk = 0;
    always #5 clk = ~clk;
    adder_if a_if(clk);

    adder dut(
    .a(a_if.a),
    .b(a_if.b),
    .y(a_if.y)
);

initial begin
  $fsdbDumpfile("wave.fsdb");
  $fsdbDumpvars(0);
end

initial begin   
    uvm_config_db#(virtual adder_if)::set(null, "*", "a_vif", a_if); // set a_if as name "a_vif"
    // can be processed without object(uvm_root start all the components)
    run_test("adder_test");
    end

endmodule
//----------------------//
