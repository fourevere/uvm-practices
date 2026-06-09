`include "uvm_macros.svh"
import uvm_pkg::*;

interface ram_intf(input logic clk);

    logic we;
    logic [7:0] addr;
    logic [7:0] wdata;
    logic [7:0] rdata;
    
endinterface 


class ram_seq_item extends uvm_sequence_item;
    rand logic we;
    rand logic [7:0] addr;
    rand logic [7:0] wdata;
    logic [7:0] rdata;

    function new(string name = "ram_seq_item");
        super.new(name);
    endfunction 

    `uvm_object_utils_begin(ram_seq_item)
        `uvm_field_int(we, UVM_ALL_ON)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(wdata, UVM_ALL_ON)
        `uvm_field_int(rdata, UVM_ALL_ON)
    `uvm_object_utils_end

    function string convert2string();
        return $sformatf("we=%0d, addr=%0d, wdata=%0d, rdata=%0d", we, addr, wdata, rdata);
    endfunction

endclass 

class ram_sequence extends uvm_sequence #(ram_seq_item);
    `uvm_object_utils(ram_sequence)
    int loop_count;

    function new(string name = "ram_seq");
        super.new(name);
    endfunction 

    virtual task body();
        ram_seq_item item;
        for(int i = 0; i < loop_count; i++) begin
            item = ram_seq_item::type_id::create($sformatf("item_%0d",i));
            start_item(item);
            if(!item.randomize()) `uvm_fatal(get_type_name(), "Randomizetaion fail")
            finish_item(item);

            `uvm_info(get_type_name(), $sformatf("[%0d/%0d] %s", i + 1, loop_count, item.convert2string()),UVM_HIGH)
        end         
    endtask 

endclass 

class ram_driver extends uvm_driver #(ram_seq_item);
    `uvm_component_utils(ram_driver)
    virtual ram_intf ram_if;
    function new(string name, uvm_component c);
        super.new(name,c);
    endfunction 

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual ram_intf)::get(this, "", "ram_if", ram_if))
            `uvm_fatal(get_type_name(), "ram_if를 찾을 수 없음");
        `uvm_info(get_type_name(), "build_phase 실행 완료", UVM_HIGH);
    
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction

    virtual task drive_item (ram_seq_item item);
        @(posedge ram_if.clk);
        ram_if.we <= item.we;
        ram_if.addr <= item.addr;
        ram_if.wdata <= item.wdata;
        @(posedge ram_if.clk);
        `uvm_info(get_type_name(), item.convert2string(), UVM_HIGH);
    endtask //drive_item

    virtual task run_phase(uvm_phase phase);
        ram_seq_item item;
        forever begin
            @(posedge ram_if.clk);                                      //clock 상승 엣지에 맞춰 driver 동작 수행
            #1;
            seq_item_port.get_next_item(item);
            drive_item(item);
            seq_item_port.item_done();
        end
    endtask

    virtual function void report_phase(uvm_phase phase);
    endfunction


endclass 


class ram_monitor extends uvm_monitor;
    `uvm_component_utils(ram_monitor)
    uvm_analysis_port #(ram_seq_item) ap;
    virtual ram_intf ram_if;

    function new(string name, uvm_component c);
        super.new(name,c);
        ap = new("ap", this);
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual ram_intf)::get(this, "", "ram_if", ram_if))
            `uvm_fatal(get_type_name(), "ram_if를 찾을 수 없음")
        `uvm_info(get_type_name(), "build_phase 실행 완료", UVM_HIGH)
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            ram_seq_item item = ram_seq_item::type_id::create("item");
            @(posedge ram_if.clk);
            item.we = ram_if.we;
            item.addr = ram_if.addr;
            item.wdata = ram_if.wdata;
            item.rdata = ram_if.rdata;
            ap.write(item);
            `uvm_info(get_type_name(), item.convert2string(), UVM_MEDIUM);
        end
    endtask 


endclass 



class ram_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(ram_scoreboard)
    uvm_analysis_imp #(ram_seq_item, ram_scoreboard) ap_imp;

    int fail_count;
    int pass_count;

    logic [7:0] mem[0:255];

    function new(string name, uvm_component c);
        super.new(name,c);
        ap_imp = new("ap_imp", this);
        fail_count = 0;
        pass_count = 0;
    endfunction 

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction

    virtual function void write(ram_seq_item item);
        `uvm_info(get_type_name(), $sformatf("scoreboard: %s", item.convert2string()), UVM_MEDIUM);
        if(item.we) begin
            mem[item.addr] = item.wdata;
        end else begin
            if(item.rdata === mem[item.addr]) begin
                pass_count++;
            end else begin
                fail_count++;
            end    
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "===================Scoreboard Summary===========", UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("Toal transactions: %0d", pass_count + fail_count), UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("Pass: %0d", pass_count), UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("Fail: %0d", fail_count), UVM_LOW);

        if(fail_count > 0) begin
            `uvm_error(get_type_name(),$sformatf("TEST FAILED: %0d mismatched detected!", fail_count));
        end else begin
            `uvm_info(get_type_name(), $sformatf("TEST PASSED: %0d all matches detected", pass_count),UVM_LOW);
        end
    endfunction
endclass 


class ram_agent extends uvm_agent;
    `uvm_component_utils(ram_agent)

    uvm_sequencer #(ram_seq_item) sqr;
    ram_driver drv;
    ram_monitor mon;

    function new(string name, uvm_component c);
        super.new(name,c);
    endfunction 

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sqr = uvm_sequencer#(ram_seq_item)::type_id::create("sqr", this);
        drv = ram_driver::type_id::create("drv", this);
        mon = ram_monitor::type_id::create("mon", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction

endclass 


class ram_env extends uvm_env;
    `uvm_component_utils(ram_env)

    ram_agent agt;
    ram_scoreboard scb;

    function new(string name, uvm_component c);
        super.new(name,c);
    endfunction 

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt     = ram_agent::type_id::create("agt", this);
        scb     = ram_scoreboard::type_id::create("scb", this);

    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.mon.ap.connect(scb.ap_imp);
    endfunction

endclass 

class ram_test extends uvm_test;
    `uvm_component_utils(ram_test)

    ram_env env;

    function new(string name, uvm_component c);
        super.new(name,c);
    endfunction 

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = ram_env::type_id::create("env",this);
        `uvm_info(get_type_name(), "build_phase", UVM_HIGH)
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info(get_type_name(), "connect_phase", UVM_HIGH)
    endfunction

    virtual task run_phase(uvm_phase phase);
        ram_sequence seq;
        `uvm_info(get_type_name(), "ram_sequence seq 실행", UVM_DEBUG)

        phase.raise_objection(this);
        `uvm_info(get_type_name(), "phase.raise_objection(this) 실행", UVM_DEBUG)

        seq = ram_sequence::type_id::create("seq");
        `uvm_info(get_type_name(), "seq = ram_sequence::type_id::create 실행", UVM_DEBUG)
        seq.loop_count = 10;
        `uvm_info(get_type_name(), "seq.loop_count = 10; 실행", UVM_DEBUG)
        seq.start(env.agt.sqr);
        `uvm_info(get_type_name(), "seq.start(env.agt.sqr); 실행", UVM_DEBUG)
        phase.drop_objection(this);
        `uvm_info(get_type_name(), "phase.drop_objection(this) 실행", UVM_DEBUG)
    endtask 

    virtual function void report_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction

endclass 

module tb_ram ();
    logic clk;

    always #5 clk = ~clk;

    ram_intf ram_if(clk);

    ram dut(
        .clk(ram_if.clk),
        .we(ram_if.we),
        .addr(ram_if.addr),
        .wdata(ram_if.wdata),
        .rdata(ram_if.rdata)
    );

    initial begin
        clk = 0;
        ram_if.we = 0;
        ram_if.addr = 0;
    end

    initial begin
        uvm_config_db#(virtual ram_intf)::set(null, "*", "ram_if", ram_if);
        run_test("ram_test");
    end
    
endmodule