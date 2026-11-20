`include "uvm_macros.sv"
import uvm_pkg::*;

//---------------------
// 0. interface
interface OOO_if (
    input i_clk
);
    // port

    // clocking

    // modport

    // property

    // assertion

endinterface
//---------------------


//---------------------
// 1. sequence_item
class OOO_seq_item extends uvm_sequence_item;
    // item

    // constraint

    // counstructor
    function new(string name = "OOO_SEQUENCE_ITEM");
        super.new(name);
    endfunction

    // uvm factory registry
    `uvm_object_utils_begin(ram_seq_item)
    `uvm_field_int(XXX,    UVM_DEFAULT)
    `uvm_object_utils_end

    // function 'conver2string'
    virtual function string convert2string();
        return $sformatf("______");
    endfunction

endclass
//--------------------


//---------------------
// 2. sequence
class OOO_sequence extends uvm_sequence #(OOO_seq_item);
    // uvm factory registry
    `uvm_object_utils(OOO_sequence)

    // handle declaration
    OOO_seq_item u_item;

    // constructor
    function new(string name = "OOO_SEQUENCE");
        super.new(name);
    endfunction

    // task 'body'
    virtual task body();
        repeat (1) begin
            u_item = OOO_seq_item::type_id::create("ITEM");
            start_item(u_item);
            // my code
            `uvm_info(get_name(), u_item.convert2string(), UVM_HIGH)
        end
    endtask

endclass
//---------------------


//---------------------
// 3. driver
class OOO_driver extends uvm_driver #(OOO_seq_item);
    // uvm factory registry
    `uvm_component_utils(OOO_driver)

    // handle declaration
    OOO_seq_item   u_item;

    // virtual interface declaration
    virtual OOO_if u_if;

    // constructor
    function new(string name = "OOO_DRIVER", uvm_component c = null);
        super.new(name, c);
    endfunction

    // function 'build_phase'
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual OOO_if)::get(this, "", "u_if", u_if)) begin
            `uvm_fatal(get_name(), "_____")
        end
    endfunction

    // task 'run_phase'
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            seq_item_port.get_next_item(u_item);
            // my code
            seq_item_port.item_done();
            `uvm_info(get_name(), u_item.convert2string(), UVM_HIGH)
        end
    endtask

endclass
//---------------------


//---------------------
// 4. monitor
class OOO_monitor extends uvm_monitor;
    // uvm factory registry
    `uvm_component_utils (OOO_monitor)

    // handle declaration
    OOO_seq_item u_item;
    uvm_analysis_port #(OOO_seq_item) send;

    // virtual interface declaration
    virtual OOO_if u_if;

    // constructor
    function new(string name = "OOO MONITOR", uvm_component c = null);
        super.new(name, c);
        send = new("WRITE", this);
    endfunction

    // function 'build_phase'
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual OOO_if)::get(this, "", "u_if", u_if)) begin
            `uvm_fatal(get_name(), "_____")
        end
    endfunction

    // task 'run_phase'
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            u_item = OOO_seq_item::type_id::create("ITEM");
            // my code
            uvm_info(get_name(), u_item.convert2string(), UVM_HIGH)
            send.write(u_item);
        end
    endtask
endclass
//---------------------


//---------------------
// 5. agent
class OOO_agent extends uvm_agent;
    // uvm factory registry
    `uvm_component_utils(OOO_agent)

    // handle declaration
    uvm_sequencer #(ram_seq_item) u_sqr;
    OOO_driver                    u_drv;
    OOO_monitor                   u_mon;

    // constructor
    function new(string name = "OOO_AGENT", uvm_component c = null);
        super.new(name, c);
    endfunction

    // function 'build_phase'
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        u_sqr = uvm_sequencer#(OOO_seq_item)::type_id::create("SQR", this);
        u_drv = OOO_driver::type_id::create("DRV", this);
        u_mon = OOO_monitor::type_id::create("MON", this);
    endfunction

    // function 'connect_phase'
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        u_drv.seq_item_port.connect(u_sqr.seq_item_export);
    endfunction

endclass
//---------------------


//---------------------
// 6. scoreboard
class OOO_scoreboard extends uvm_scoreboard;
    // uvm factory registry
    `uvm_component_utils(OOO_scoreboard)

    // handle declaration
    uvm_analysis_imp #(OOO_seq_item, OOO_scoreboard) recv;

    // value declaration for scoring-

    // constructor
    function new(string name = "OOO_SCOREBOARD", uvm_component c = null);
        super.new(name, c);
        recv = new("READ", this);
    endfunction

    // function 'write'
    virtual function void write(OOO_seq_item u_item);
        // my code
    endfunction

    // function 'report_phase'
    virtual function void report_phase(uvm_phase phase);
        // my code
    endfunction

endclass
//---------------------


//--------------------
// 7. coverage
class OOO_coverage extends uvm_subscriber #(OOO_seq_item);
    // uvm factory registry
    `uvm_component_utils(OOO_coverage)

    // handle declaration
    OOO_seq_item u_item;

    // covergroup

    // constructor
    function new(string name = "OOO_COVERAGE", uvm_component c = null);
        super.new(name, c);
        OOO_cg = new();
    endfunction

    // function 'write'
    virtual function void write(OOO_seq_item t);
        // my code
    endfunction

    // function 'report_phase'
    virtual function void report_phase(uvm_phase phase);
        // my code
    endfunction
endclass
//---------------------


//---------------------
// 8. environment
class OOO_environment extends uvm_env;
    // uvm factory registry
    `uvm_component_utils(OOO_environment)

    // handle declaration
    OOO_agent      u_agt;
    OOO_scoreboard u_scb;
    OOO_coverage   u_cov;

    // constructor
    function new(string name = "OOO_ENVIRONMENT", uvm_component c = null);
        super.new(name, c);
    endfunction

    // function 'build_phase'
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        u_agt = OOO_agent::type_id::create("AGT", this);
        u_scb = OOO_scoreboard::type_id::create("SCB", this);
        u_cov = OOO_coverage::type_id::create("COV", this);
    endfunction

    // function 'connect_phase'
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        u_agt.u_mon.send.connect(u_scb.recv);
        u_agt.u_mon.send.connect(
            u_cov.analysis_export);  // monitor : caller |  scoreboard, coverage : callee
    endfunction

endclass
//---------------------


//---------------------
// 9. test
class OOO_test extends uvm_test;
    // uvm factory registry
    `uvm_component_utils(OOO_test)

    // handle declaration
    OOO_environment u_env;
    OOO_sequence    u_seq;

    // construnctor
    function new(string name = "OOO_TEST", uvm_component c = null);
        super.new(name, c);
    endfunction

    // function 'build_phase'
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        u_env = OOO_environment::type_id::create("ENV", this);
        u_seq = OOO_sequence::type_id::create("SEQ", this);
    endfunction

    // task 'run_phase'
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        phase.raise_objection(this);
        u_seq.start(u_env.u_agt.u_sqr);
        // delay
        phase.drop_objection(this);
    endtask

endclass
//---------------------


//---------------------
// tb
module tb_OOO;
    // clock generation
    logic i_clk = 0;
    always #5 i_clk = ~i_clk;

    // interface instantiation
    OOO_if u_if (i_clk);

    // DUT instantiation

    // run
    initial begin
        uvm_config_db#(virtual OOO_if)::set(null, "*", "u_if", u_if);
        run_test("OOO_test");
    end

    // fsdb
    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, tb_OOO);
    end

endmodule
//---------------------
