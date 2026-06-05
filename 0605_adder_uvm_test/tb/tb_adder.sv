`include "uvm_macros.svh"
import uvm_pkg::*;

interface adder_intf;
    logic [7:0] a;
    logic [7:0] b;
    logic  [8:0] y;
endinterface //adder_intf

class adder_seq_item extends uvm_sequence_item;
    rand logic [7:0] a;
    rand logic [7:0] b;
    logic [8:0] y;
    function new(string name = "adder_seq_item");
        super.new(name);
    endfunction 

    `uvm_object_utils_begin(adder_seq_item)
        `uvm_field_int(a, UVM_DEFAULT)
        `uvm_field_int(b, UVM_DEFAULT)
        `uvm_field_int(y, UVM_DEFAULT)
    `uvm_object_utils_end
endclass 

class adder_seq extends uvm_sequence;
    `uvm_object_utils(adder_seq)
    adder_seq_item a_seq_item;

    function new(string name = "adder_seq");
        super.new(name);
    endfunction //new()

    virtual task body();
        a_seq_item = adder_seq_item::type_id::create("SEQ_ITEM");

        repeat(100) begin
            start_item(a_seq_item);
            if(!a_seq_item.randomize()) begin
                `uvm_error("SEQ_ITEM", "Fail to generate random value!");
            end
            `uvm_info("SEQ", "Data send to Driver", UVM_NONE);
            finish_item(a_seq_item);
        end
    endtask 
endclass 

class adder_drv extends uvm_driver#(adder_seq_item);
    `uvm_component_utils(adder_drv)
    virtual adder_intf adder_if;
    adder_seq_item a_seq_item;

    function new(string name = "adder_drv", uvm_component c);
        super.new(name, c);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        a_seq_item = adder_seq_item::type_id::create("SEQ_ITEM", this);
        if(!uvm_config_db#(virtual adder_intf)::get(this, "", "adder_if", adder_if)) begin
            `uvm_fatal(get_name(), "Unable to access adder interface.")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        $display("Display run phase");
        forever begin
            seq_item_port.get_next_item(a_seq_item);
            adder_if.a <= a_seq_item.a;
            adder_if.b <= a_seq_item.b;
            #10;
            seq_item_port.item_done();
        end
    endtask 
endclass

class adder_mon extends uvm_monitor;
    `uvm_component_utils(adder_mon)
    uvm_analysis_port#(adder_seq_item) send;
    virtual adder_intf adder_if;
    adder_seq_item a_seq_item;

    function new(string name = "adder_mon", uvm_component c);    
        super.new(name, c);
        send = new("send", this);
    endfunction //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        a_seq_item = adder_seq_item::type_id::create("SEQ_ITEM", this);
        if(!uvm_config_db#(virtual adder_intf)::get(this, "", "adder_if", adder_if)) begin
            `uvm_fatal(get_name(), "Unable to access adder interface");
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            #10;
            a_seq_item.a = adder_if.a;
            a_seq_item.b = adder_if.b;
            a_seq_item.y = adder_if.y;
            `uvm_info("MON", "Send data to Scoreboard", UVM_LOW);
            send.write(a_seq_item);
        end
    endtask 

endclass 

class adder_scb extends uvm_scoreboard;
    `uvm_component_utils(adder_scb)
    uvm_analysis_imp#(adder_seq_item, adder_scb) recv;

    function new(string name = "adder_scb", uvm_component c);
        super.new(name, c);
        recv = new("READ", this);
    endfunction

    virtual function void write(adder_seq_item data);
        `uvm_info("SCB", "Data received from Monitor", UVM_LOW);
        if(data.a + data.b == data.y) begin
            `uvm_info("SCB", $sformatf("PASS!, a:%0d + b:%0d = y:%0d", data.a, data.b, data.y), UVM_LOW)
        end else begin
            `uvm_error("SCB", $sformatf("FAIL, a:%0d + b:%0d = y:%0d", data.a, data.b, data.y))
        end
    endfunction
endclass 

class adder_agent extends uvm_agent;
    `uvm_component_utils(adder_agent)

    adder_mon a_mon;
    adder_drv a_drv;
    uvm_sequencer#(adder_seq_item) a_sqr;

    function new(string name = "adder_agent", uvm_component c);
        super.new(name, c);
    endfunction 

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        a_mon = adder_mon::type_id::create("MON", this);
        a_drv = adder_drv::type_id::create("DRV", this);
        a_sqr = uvm_sequencer#(adder_seq_item)::type_id::create("SQR", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        a_drv.seq_item_port.connect(a_sqr.seq_item_export);
    endfunction
endclass 


class adder_env extends uvm_env;
    `uvm_component_utils(adder_env)
    adder_agent a_agt;
    adder_scb a_scb;
    function new(string name = "adder_env", uvm_component c);    
        super.new(name, c);
    endfunction //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        a_agt = adder_agent::type_id::create("AGENT", this);
        a_scb = adder_scb::type_id::create("SCB", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        a_agt.a_mon.send.connect(a_scb.recv);
    endfunction
endclass 

class adder_test extends uvm_test;
    `uvm_component_utils(adder_test) //factory에 adder_test 등록 macro

    adder_seq a_seq;
    adder_env a_env;

    function new(string name = "adder_test", uvm_component c);
        super.new(name, c);
    endfunction //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        a_seq = adder_seq::type_id::create("SEQ", this); //make instance
        a_env = adder_env::type_id::create("ENV", this);
        
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        a_seq.start(a_env.a_agt.a_sqr);
        phase.drop_objection(this);
        
    endtask

endclass

module tb_adder ();

    adder_intf adder_if();

    adder dut(
        .a(adder_if.a),
        .b(adder_if.b),
        .y(adder_if.y)
    );

    initial begin
        $fsdbDumpvars(0);
        $fsdbDumpfile("wave.fsdb");
    end

    initial begin
        uvm_config_db#(virtual adder_intf)::set(null, "*", "adder_if", adder_if);
        run_test("adder_test");
    end

        
endmodule