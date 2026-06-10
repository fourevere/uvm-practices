`include "uvm_macros.svh"                               //UVM macro를 사용하기 위해 설정
import uvm_pkg::*;                                      //현재 파일에서 uvm 패키지를 사용할 수 있도록 설정

interface adder_intf;                                   //interface (DUT 입출력) 선언
    logic [7:0] a;                                      //adder할 첫번째 숫자값 a 데이터 신호
    logic [7:0] b;                                      //adder할 두번째 숫자값 b 데이터 신호
    logic  [8:0] y;                                     //최종적으로 adder되어 출력되는 결과값 y 데이터 신호
endinterface 

class adder_seq_item extends uvm_sequence_item;         //데이터를 주고받을 transaction 클래스 선언
    rand logic [7:0] a;                                 //8비트 입력 a 선언
    rand logic [7:0] b;                                 //8비트 입력 b 선언
    logic [8:0] y;                                      //9비트 출력 y 선언

    function new(string name = "adder_seq_item");       //adder_seq_item 객체 생성자 정의
        super.new(name);                                //부모 클래스 uvm_sequence_item의 생성자 호출
    endfunction 

    `uvm_object_utils_begin(adder_seq_item)             //adder_seq_item을 factory에 등록 후 macro 시작
        `uvm_field_int(a, UVM_DEFAULT)                  //a를 uvm이 사용할 수 있도록 등록
        `uvm_field_int(b, UVM_DEFAULT)                  //b를 uvm이 사용할 수 있도록 등록
        `uvm_field_int(y, UVM_DEFAULT)                  //y를 uvm이 사용할 수 있도록 등록
    `uvm_object_utils_end                               //factory 선언 종료
endclass 

class adder_seq extends uvm_sequence;                   //driver로 보낼 transaction(item)를 생성하는 sequence 클래스 선언
    `uvm_object_utils(adder_seq)                        //adder_seq를 factory에 등록
    adder_seq_item a_seq_item;                          //a_seq_item handle 선언

    function new(string name = "adder_seq");            //adder_seq 객체 생성자 정의
        super.new(name);                                //부모 클래스 uvm_sequence의 생성자 호출
    endfunction 

    virtual task body();                                                    //sequence가 실제로 실행할 동작 정의
        a_seq_item = adder_seq_item::type_id::create("SEQ_ITEM");           //factory로 a_seq_item 객체 생성

        repeat(100) begin                                                   //100번 반복하는 구간
            start_item(a_seq_item);                                         //sequencer에게 item을 driver로 전송하는 권한 요청
            if(!a_seq_item.randomize()) begin                               //item 안의 rand 변수들을 랜덤 값으로 바꾸는 randomize 실행
                `uvm_error("SEQ_ITEM", "Fail to generate random value!");   //randomize 실패시 error 메시지 출력
            end
            `uvm_info("SEQ", "Data send to Driver", UVM_NONE);              //driver로 보낼 준비가 끝났다는 메시지 출력
            finish_item(a_seq_item);                                        //randomize가 끝난 transaction을 sequencer를 통해 driver로 전달
        end
    endtask 
endclass 

class adder_drv extends uvm_driver#(adder_seq_item);                        //dut에게 item값을 보내는 driver 선언
    `uvm_component_utils(adder_drv)                                         //adder_drv를 component factory에 등록
    virtual adder_intf adder_if;                                            //실제 interface를 가리키는 interface handle 선언
    adder_seq_item a_seq_item;                                              //sequencer에서 받아올 transaction handle 선언

    function new(string name = "adder_drv", uvm_component c);               //adder_drv, compnent 생성자 정의(위 sequence는 object라서 component를 받지x)
        super.new(name, c);                                                 //부모 클래스 uvm_driver의 생성자 호출
    endfunction

    virtual function void build_phase(uvm_phase phase);                                     //객체 생성 및 설정을 수행하는 phase
        super.build_phase(phase);                                                           //부모 클래스의 build_phase 호출
        a_seq_item = adder_seq_item::type_id::create("SEQ_ITEM", this);                     //item 객체를 factory로 생성
        if(!uvm_config_db#(virtual adder_intf)::get(this, "", "adder_if", adder_if)) begin  //config DB에서 interface 가져옴
            `uvm_fatal(get_name(), "Unable to access adder interface.")                     //실패시 fatal 출력
        end
    endfunction

    virtual task run_phase(uvm_phase phase);                                //driver가 dut에 값을 보내는 동작 task
        $display("Display run phase");                                      //시작 메시지 출력
        forever begin                                                       //트랙젝션 처리를 위한 forever 구문
            seq_item_port.get_next_item(a_seq_item);                        //sequencer에서 transaction 받음
            adder_if.a <= a_seq_item.a;                                     //받아온 트랜젝션 a의 값을 interface에 nonblocking으로 넣음
            adder_if.b <= a_seq_item.b;                                     //받아온 트랜젝션 b의 값을 interface에 nonblocking으로 넣음
            #10;                                                            //안정될 시간을 주기 위해 #10 추가
            seq_item_port.item_done();                                      //현재 진행하던 item 처리가 끝났다는 신호를 seq에 알림
        end
    endtask 
endclass

class adder_mon extends uvm_monitor;                                        //DUT interface 신호를 관측하는 monitor 선언
    `uvm_component_utils(adder_mon)                                         //adder_mon을 component factory에 등록
    uvm_analysis_port#(adder_seq_item) send;                                //관측 데이터를 다른 component로 전달할 analysis port 선언
    virtual adder_intf adder_if;                                            //monitor가 관측할 interface handle 선언
    adder_seq_item a_seq_item;                                              //관측 데이터를 저장할 transaction handle 선언

    function new(string name = "adder_mon", uvm_component c);               //adder_mon, compnent 생성자 정의
        super.new(name, c);                                                 //부모 클래스 uvm_monitor의 생성자 호출
        send = new("send", this);                                           //analysis port 객체 생성("port이름")
    endfunction 

    virtual function void build_phase(uvm_phase phase);                                     //객체 생성 및 설정을 수행하는 phase
        super.build_phase(phase);                                                           //부모 클래스의 build_phase 호출
        a_seq_item = adder_seq_item::type_id::create("SEQ_ITEM", this);                     //item 객체를 factory로 생성
        if(!uvm_config_db#(virtual adder_intf)::get(this, "", "adder_if", adder_if)) begin  //config DB에서 interface 가져옴(현재component,현재 위치,DB에 등록된 이름,가져온 것을 저장할 변수)
            `uvm_fatal(get_name(), "Unable to access adder interface");                     //실패시 fatal 출력
        end
    endfunction

    virtual task run_phase(uvm_phase phase);                                //interface 신호를 주기적으로 샘플링하는 task
        forever begin                                                       //interface 값 처리를 위한 forever 구문
            #10;                                                            //출력이 안정될 시간을 주기 위해 #10 추가
            a_seq_item.a = adder_if.a;                                      //interface 안에 저장되어 있는 a값을 transaction a에 저장
            a_seq_item.b = adder_if.b;                                      //interface 안의 저장되어 있는 b값을 transaction b에 저장
            a_seq_item.y = adder_if.y;                                      //interface 안의 저장되어 있는 y값을 transaction y에 저장
            `uvm_info("MON", "Send data to Scoreboard", UVM_LOW);           //scoreboard로 데이터를 보내는 메시지 출력
            send.write(a_seq_item);                                         //analysis port로 transaction을 scoreboard로 전달
        end
    endtask 

endclass 

class adder_scb extends uvm_scoreboard;                                     //DUT 결과가 맞는지 검사하는 scoreboard 클래스 선언
    `uvm_component_utils(adder_scb)                                         //adder_scb을 component factory에 등록
    uvm_analysis_imp#(adder_seq_item, adder_scb) recv;                      //monitor에서 보낸 transaction을 받을 analysis implementation 선언

    function new(string name = "adder_scb", uvm_component c);               //adder_scb, compnent 생성자 정의
        super.new(name, c);                                                 //부모 클래스 uvm_scoreboard의 생성자 호출
        recv = new("READ", this);                                           //analysis implementation 객체 생성
    endfunction

    virtual function void write(adder_seq_item data);                                                       //monitor의 analysis port에서 transaction이 들어올 때 자동 호출되는 함수
        `uvm_info("SCB", "Data received from Monitor", UVM_LOW);                                            //monitor에서 데이터를 받았다는 메시지 출력
        if(data.a + data.b == data.y) begin                                                                 //기대값인 a+b와 실제 DUT에서 출력된 결과값 y 비교하여 PASS,FAIL 출력
            `uvm_info("SCB", $sformatf("PASS!, a:%0d + b:%0d = y:%0d", data.a, data.b, data.y), UVM_LOW)    
        end else begin
            `uvm_error("SCB", $sformatf("FAIL, a:%0d + b:%0d = y:%0d", data.a, data.b, data.y))
        end
    endfunction
endclass 

class adder_agent extends uvm_agent;                                        //driver, monitor, sequencer를 묶는 agent 클래스를 선언
    `uvm_component_utils(adder_agent)                                       //adder_agent를 component factory에 등록

    adder_mon a_mon;                                                        //agent에 들어갈 monitor handle 선언
    adder_drv a_drv;                                                        //agent에 들어갈 driver handle 선언
    uvm_sequencer#(adder_seq_item) a_sqr;                                   //transaction값을 driver로 전달할 sequencer handle 선언

    function new(string name = "adder_agent", uvm_component c);             //adder_agent, compnent 생성자 정의
        super.new(name, c);                                                 //부모 클래스 uvm_agent의 생성자 호출
    endfunction 

    virtual function void build_phase(uvm_phase phase);                             //객체 생성 및 설정을 수행하는 phase
        super.build_phase(phase);                                                   //부모 클래스의 build_phase 호출
        a_mon = adder_mon::type_id::create("MON", this);                            //monitor component를 factory로 생성
        a_drv = adder_drv::type_id::create("DRV", this);                            //driver component를 factory로 생성
        a_sqr = uvm_sequencer#(adder_seq_item)::type_id::create("SQR", this);       //sequencer component를 factory로 생성
    endfunction

    virtual function void connect_phase(uvm_phase phase);                           //component 간 port를 연결하는 connect_phase
        super.connect_phase(phase);                                                 //부모 클래스의 connect_phase 호출
        a_drv.seq_item_port.connect(a_sqr.seq_item_export);                         //driver의 item port를 sequencer의 export에 연결
    endfunction
endclass 


class adder_env extends uvm_env;                                                    //agent와 scoreboard를 묶는 environment 클래스 선언
    `uvm_component_utils(adder_env)                                                 //adder_env를 component factory에 등록
    adder_agent a_agt;                                                              //env에 들어갈 agent handle 선언
    adder_scb a_scb;                                                                //env에 들어갈 scoreboard handle 선언

    function new(string name = "adder_env", uvm_component c);                       //adder_env, compnent 생성자 정의
        super.new(name, c);                                                         //부모 클래스 uvm_env의 생성자 호출
    endfunction 

    virtual function void build_phase(uvm_phase phase);                             //객체 생성 및 설정을 수행하는 phase
        super.build_phase(phase);                                                   //부모 클래스의 build_phase 호출
        a_agt = adder_agent::type_id::create("AGENT", this);                        //agent component를 factory로 생성
        a_scb = adder_scb::type_id::create("SCB", this);                            //scoreboard component를 factory로 생성
    endfunction

    virtual function void connect_phase(uvm_phase phase);                           //connect_phase에서 monitor와 scoreboard를 연결
        super.connect_phase(phase);                                                 //부모 클래스의 connect_phase 호출
        a_agt.a_mon.send.connect(a_scb.recv);                                       //monitor의 analysis port를 scoreboard의 analysis implementation에 연결
    endfunction
endclass 

class adder_test extends uvm_test;                                                  //전체 검증 시나리오를 실행하는 adder_test 클래스 선언
    `uvm_component_utils(adder_test)                                                //adder_test를 component factory에 등록 

    adder_seq a_seq;                                                                //테스트에서 실행할 sequence handle 선언
    adder_env a_env;                                                                //test 환경인 env handle 선언

    function new(string name = "adder_test", uvm_component c);                      //adder_test, compnent 생성자 정의
        super.new(name, c);                                                         //부모 클래스 uvm_test의 생성자 호출
    endfunction

    virtual function void build_phase(uvm_phase phase);                             //객체 생성 및 설정을 수행하는 phase
        super.build_phase(phase);                                                   //부모 클래스의 build_phase 호출
        a_seq = adder_seq::type_id::create("SEQ", this);                            //sequence 객체를 factory로 생성
        a_env = adder_env::type_id::create("ENV", this);                            //env component를 factory로 생성
        
    endfunction

    virtual task run_phase(uvm_phase phase);                                        //실제 테스트 sequence 실행
        phase.raise_objection(this);                                                //테스트가 끝나기 전 시뮬이 종료되지 않도록 objection raise
        a_seq.start(a_env.a_agt.a_sqr);                                             //sequence를 env 내부에 있는 agent 내부 sequencer에서 실행
        phase.drop_objection(this);                                                 //sequence 실행이 끝났으니 objection drop을 통해 시뮬레이션 종료
        
    endtask

endclass

module tb_adder ();                                                                 //DUT와 test 연결하는 최상위 테스트벤치 모듈 선언

    adder_intf adder_if();                                                          //interface 인스턴스 생성

    adder dut(                                                                      //검증대상인 DUT 인스턴스 생성
        .a(adder_if.a),
        .b(adder_if.b),
        .y(adder_if.y)
    );

    initial begin                                                                   //초기에 한번 실행하는 waveform dump 관련 initial block
        $fsdbDumpvars(0);                                                           //테스트벤치 전체의 신호를 fsdb파형에 기록(괄호는 계층깊이)
        $fsdbDumpfile("wave.fsdb");                                                 //생성할 fsdb 파형 이름을 wave.fsdb로 지정
    end

    initial begin                                                                   //초기에 한번 실행하는 초기화 및 시작을 담당하는 initial block
        uvm_config_db#(virtual adder_intf)::set(null, "*", "adder_if", adder_if);   //모든 component가 사용할 interface를 config DB에 등록(등록 기준 위치,접근 가능 범위,저장 이름,저장할 인스턴스)
        run_test("adder_test");                                                     //UVM factory에 등록된 adder_test를 top test로 생성하고 UVM phase 실행 시작
    end

        
endmodule