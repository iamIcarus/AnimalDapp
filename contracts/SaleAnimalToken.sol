// SPDX-License-Itentifier: MIT

pragma solidity ^0.8.0;

import "MintAnimalToken.sol";

contract SaleAnimalToken{
    MintAnimalToken public mintAnimalTokenAddress;//mintAnimalTokenAddress = '', contructor에서 생성

    constructor(address _mitAnimalTokenAddress){
        mintAnimalTokenAddress = MintAnimalToken(_mitAnimalTokenAddress);//deploy시 인자로 Mint contract를 deploy하고 생성된 컨트렉트주소입력
    }

    mapping(uint256 => uint256) public animalTokenPrices;//prices: tokenId => price

    uint256[] public onSaleAnimalTokenArr;

      // Gas Optimization: Use view instead of constant
    function isTokenOnSale(uint256 _animalTokenId) public view returns (bool) {
        return animalTokenPrices[_animalTokenId] > 0;
    }

    //판매등록
    function setForSaleAnimalToken(uint256 _animalTokenId, uint256 _price) public {
        address animalTokenOwner = mintAnimalTokenAddress.ownerOf(_animalTokenId);

        //test코드: 맞으면 다음줄 아니면 메시지출력
        require(animalTokenOwner == msg.sender, "Caller is not animal token owner.");
        require(_price > 0, "Price is zero or lower.");

        // 
        require(!isTokenOnSale(_animalTokenId), "This token is already on sale.");
        //Mint 컨트렉트에서 판매권한을 줬는가? isApprovedForAll(owner:이컨트렉트만든놈, operator:_mitAnimalTokenAddress)
        require(mintAnimalTokenAddress.isApprovedForAll(animalTokenOwner, address(this)), "Animal token owner did not approve token.");
        //참고로 권한을 주려면 Mint컨트렉트에서 setApprovalForAll(operator:_mitAnimalTokenAddress, approved: true)

        animalTokenPrices[_animalTokenId] = _price;

        //판매중인것만 배열에 담음 - 프앤에서 사용
        onSaleAnimalTokenArr.push(_animalTokenId);
    }



//payable키워드를 붙여야 metic이 왓다갓다하는 함수를 실행할 수있다.
    function purchaseAnimalToken(uint256 _animalTokenId) public payable{
        uint256 price = animalTokenPrices[_animalTokenId];
        address animalTokenOwner = mintAnimalTokenAddress.ownerOf(_animalTokenId);
        require(isTokenOnSale(_animalTokenId), "Animal token not sale");
        require(price <= msg.value, "Caller sent lower than price.");//사려는 owner value에 10 채워넣어야함
        require(animalTokenOwner != msg.sender, "Caller is animal token owner.");//같은owner끼리느 거래불가
    
        payable(animalTokenOwner).transfer(msg.value);//돈을 주인한테보냄
        //이제 주인바꾸기(확인: ownerOf())
        mintAnimalTokenAddress.safeTransferFrom(animalTokenOwner, msg.sender, _animalTokenId);//from, to, tokenid
    
        // Gas Optimization: Use the swap-and-pop technique to remove the purchased token from the onSaleAnimalTokenArr array
        uint256 lastTokenIndex = onSaleAnimalTokenArr.length - 1;
        uint256 purchasedTokenIndex = 0;
        while (onSaleAnimalTokenArr[purchasedTokenIndex] != _animalTokenId) {
            purchasedTokenIndex++;
        }
        if (purchasedTokenIndex != lastTokenIndex) {
            onSaleAnimalTokenArr[purchasedTokenIndex] = onSaleAnimalTokenArr[lastTokenIndex];
        }
        onSaleAnimalTokenArr.pop();

        animalTokenPrices[_animalTokenId] = 0;
    }

    function getOnSaleAnimalTokenArrLength() public view returns (uint256) {
        return onSaleAnimalTokenArr.length;
    }
}
// 주인이바뀌고 다시 가격을 업데이트하려면 setApproveForAll(sale Contract)