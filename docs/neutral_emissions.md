1. Source Chain에서 sendPacket 함수 호출 시 packetSequence로 `SendPacket` event가 발생됩니다.

2. 동일한 packetSequence로 Dest Chain에서 packet을 받고 `RecvPacket` event가 발생됩니다.

3. Dest Chain에서 조회 원하는 집계 기준 값으로 이벤트 검색 혹은 트랜잭션을 검색 후 

4. 검색된 트랜잭션에 연결된 `RecvPacket` 이벤트를 찾고 인자 packet의 sequence 값으로 Source Chain의 SendPacket의 첫번째 인자 sequence를 필터링해서 트랜잭션(블록)을 연결할 수 있습니다.


```
emit SendPacket(packetSequence, sourcePort, sourceChannel, timeoutHeight, timeoutTimestamp, data);

// msg_.packet.sequence
emit RecvPacket(msg_.packet);
```


___
> - N/45:O/32
> - N/32:O/14

표기 "{block_number} ({tx_count})"
|중립 체인(N)|상쇄 체인(O)|배출 체인(E)|비고|
|---|:---|:---:|---:|
|45 (1)|32 (4)|-|기부 (탄소 중립)|
|32 (1)|-|14 (1)|배출 (탄소 배출)|

* 배출인 경우 배출 즉시 이종체인간 이동 되기에 TX가 1개 입니다.
* 상쇄인 경우 상쇄권을 구매 및 거래 후 기부하기에 관련된 TX 2개 이상입니다.