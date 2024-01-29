# Emissions Merkle Guide
### 1. 각 배출항목의 대표 Calculator Contract(Impletemented CarbonEmissionsCalculatorBase) 배포합니다.

```typescript
// 아래 함수를 재정의하고 계산기의 계산 함수내에서 result(배출량)이 나온 후 호출합니다.
// 각 항목은 abstract contract를 참조하세요.
function onCalculated(
    address carbonEmissions,
    address from,
    uint256 amount,
    uint256 applicationId,
    string memory sourceChannel
) internal virtual

// Example
function calculate(
        uint256 usedHeatingAmount,
        uint256 applicationId,
        address carbonEmissions,
        string memory sourceChannel
) external returns (uint256) {
        // 난방 사용량(MJ) x 난방 탄소배출 계수(kgCO2/MJ) = 탄소배출량(kgCO2)
        uint256 public heatingAverageCarbonEmissionValue = 469;
        
        uint256 result = heatingAverageCarbonEmissionValue * usedHeatingAmount;

        uint256 scaledResult = (result * 1e18) / 1e8;

        // result는 톤 단위여야 합니다.
        onCalculated(
            carbonEmissions,
            msg.sender,
            scaledResult,
            applicationId,
            sourceChannel
        );

        return scaledResult;
}
```

### 2. CarbonEmissions Contract(Impletemented ERC1155)를 배포합니다.

1. 각 체인에 1개씩 기배포된 IBC Application Contract가 존재합니다.

2. 배출 항목을 기준으로 계산기 컨트랙트와 배출량 컨트랙트는 한쌍을 이룹니다. 
    * ex) 배출항목: 비행기
        * 1. 비행기 배출량 계산기 함수 구현(#1 참고) 및 컨트랙트 배포
        * 2. CarbonEmissions 컨트랙트 배포

* 생성자의 application에는 #2.1 address를, calculator에는 #2.2 address를 넣으면 됩니다.

### 3. Frontend에서 계산기 함수의 onCalculated를 실행하는 `계산 함수를 호출` 시 탄소 배출량 계산 후 배출량 토큰이 중립 체인으로 전송됩니다.

* development 환경에서는 호출자는 항상 eth를 충분한 가스량의 ETH를 소유하여야 합니다.
* `계산 직후`에 토큰은 사용자가 소유합니다.
* `체인 전송중`에 토큰은 Escrow가 소유합니다.
* `체인 전송완료`에 토큰은 Application이 소유합니다.
* `체인 전송실패`에 토큰은 Escrow > 사용자에게 반환됩니다.