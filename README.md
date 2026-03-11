![image](asset/outline.png)
## Block Diagram
![image](asset/block_diagram.png)
## FSM
### dht11
![image](asset/FSM_dht11.png)
### ds1302
![image](asset/FSM_ds1302.png)
### ds1302_logic
![image](asset/FSM_ds1302_logic.png)
## Test bench
### dht11
![image](asset/tb_dht11.png)
### ds1302
![image](asset/tb_ds1302.png)
### uart_receiver
![image](asset/tb_uart_receiver.png)
## Oscilloscope Analyze
### dht11
![image](asset/dht11_oscilloscope.png)
### ds1302
![image](asset/ds1302_oscilloscope_1.png)
![image](asset/ds1302_oscilloscope_2.png)
![image](asset/ds1302_oscilloscope_3.png)
## Conclusion
- Bolck Diagram, FSM 구성을 먼저 하는것이 프로젝트 규모가 클수록 필수적이라는 것을 느꼈다.
- 동작이 안될 때 디버깅의 방법으로 test bench를 가장 먼저 짜보고, 각 reg들의 값을 보는 방법이 코드의 어떤 부분에서 잘못되었는지 확인하기 편했다.
- test bench의 작동도 잘된다면 oscilloscope로 측정하는 것도 필수적이었다. 하드웨어 문제가 생각보다 잦았다.
- time_out, pysical issue 등 에러 발생 가능 부분을 잡아놓고 시간 관계상 error 처리를 하지 못했다.
- (개선점) 여러 error를 error controller에 모아 특정 동작을 구현한다.
