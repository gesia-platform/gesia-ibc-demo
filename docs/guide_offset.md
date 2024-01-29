# Emissions Merkle Guide

### 1. 상쇄 흐름에 맞는 컨트랙트를 배포합니다.

### 2. 기부 가능한 소비자 레벨의 탄소상쇄 NFT Contract는 아래를 참고해서 배포해주세요.

1. 생성자에서 아래를 참고하여 추가해 주세요.

```typescript
   // 각 체인에 1개씩 기배포된 IBC Application Contract가 존재합니다. (_carbonNeutralApplication)
   constructor(address _carbonNeutralApplication) ERC1155("") {
        carbonNeutralApplication = CarbonNeutralApplication(
            _carbonNeutralApplication
        );

        address[2] memory addresses = carbonNeutralApplication
            .approvalAddresses();

        super.setApprovalForAll(addresses[0], true);
        super.setApprovalForAll(addresses[1], true);
    }
```

2. donate 함수를 임의로 추가 후 아래 application 함수를 실행하면 됩니다.

```typescript
  function exmapleDonateOffset(
        uint256 donationFromProjectTokenId,
        uint256 donationAmount,
        uint256 donateToApplicationTokenId,
        string memory sourceChannel
    ) external {
        address donator = msg.sender;
        carbonERC1155Contract = address(this);

        carbonNeutralApplication.transferOffsetToNeutral(
            carbonERC1155Contract,
            donator,
            donationFromProjectTokenId,
            donationAmount,
            donateToApplicationTokenId,
            sourceChannel
        );
    }
```

### 3. Frontend에서 `기부 함수를 호출` 상쇄 토큰이 중립 체인으로 전송됩니다.

- development 환경에서는 호출자는 항상 eth를 충분한 가스량의 ETH를 소유하여야 합니다.
- `기부 직후`에 토큰은 사용자가 소유합니다.
- `체인 전송중`에 토큰은 Escrow가 소유합니다.
- `체인 전송완료`에 토큰은 Application이 소유합니다.
- `체인 전송실패`에 토큰은 Escrow > 사용자에게 반환됩니다.
