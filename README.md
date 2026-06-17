# UVM Practices

SystemVerilog UVM 검증 환경을 연습하기 위한 작은 예제 모음입니다. Adder와 RAM DUT를 대상으로 transaction, sequence, driver, monitor, scoreboard, agent, environment, test 구성을 단계적으로 실습합니다.

## 프로젝트 구성

| 폴더 | 내용 |
| --- | --- |
| `0605_adder_uvm_test` | 조합 adder DUT와 기본 UVM 테스트벤치 |
| `0608_clk_adder_uvm` | clock/reset이 있는 adder DUT, UVM component 확장 실습, VCS Makefile |
| `0608_ram` | 256 x 8 RAM DUT와 read/write 검증용 UVM 테스트벤치 |

## 공통 검증 구조

각 테스트벤치는 다음 흐름을 중심으로 구성됩니다.

- `interface`: DUT 입출력 신호 묶음
- `sequence_item`: driver와 monitor가 주고받는 transaction
- `sequence`: 랜덤 stimulus 생성
- `driver`: interface를 통해 DUT 입력 구동
- `monitor`: DUT 입출력 샘플링
- `scoreboard`: 기대값과 실제 출력 비교
- `agent`, `env`, `test`: 검증 컴포넌트 조립과 실행

## 주요 파일

| 파일 | 내용 |
| --- | --- |
| `0605_adder_uvm_test/rtl/adder.sv` | 8-bit 입력, 9-bit 출력 adder |
| `0605_adder_uvm_test/tb/tb_adder.sv` | 기본 adder UVM 테스트벤치 |
| `0608_clk_adder_uvm/rtl/adder.sv` | clock/reset 기반 adder |
| `0608_clk_adder_uvm/tb/tb_adder.sv` | clocked adder UVM 테스트벤치 |
| `0608_clk_adder_uvm/Makefile` | Synopsys VCS 컴파일/시뮬레이션 명령 |
| `0608_ram/rtl/ram.sv` | 256 x 8 RAM |
| `0608_ram/tb/tb_ram.sv` | RAM read/write UVM 테스트벤치 |

## 실행 방법

`0608_clk_adder_uvm` 폴더에는 VCS용 Makefile이 포함되어 있습니다.

```bash
cd 0608_clk_adder_uvm
make simv
```

결과물을 지우려면 다음 명령을 사용합니다.

```bash
make clean
```

다른 예제도 사용하는 시뮬레이터의 UVM 컴파일 옵션에 맞춰 `rtl/*.sv`와 `tb/*.sv`를 함께 컴파일하면 됩니다.

## 개발 환경

- HDL/HVL: SystemVerilog
- Verification: UVM 1.2
- Example simulator flow: Synopsys VCS

## License

별도 라이선스 파일이 없는 학습용 저장소입니다. 외부 사용 전 저장소 소유자에게 확인하세요.
