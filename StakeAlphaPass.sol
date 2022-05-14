// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract StakeAlphaSciPass {
    IERC721 public parentNFT;

    // map staker address to stake details
    mapping(address => uint256[]) public tokenIds;

    mapping(address => uint256) public points;

    mapping(address => uint256) lastUpdateTime;

    modifier updateReward(address account) {
        if (account != address(0)) {
            points[account] = earned(account);
            lastUpdateTime[account] = block.timestamp;
        }
        _;
    }

    constructor(IERC721 _nftAddress) {
        parentNFT = _nftAddress;
    }

    function stake(uint256[] memory _tokenIds) public updateReward(msg.sender) {
        for (uint256 i=0; i < _tokenIds.length; ++i) {
            tokenIds[msg.sender].push(_tokenIds[i]);
            parentNFT.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
        }
        lastUpdateTime[msg.sender] = block.timestamp;
    }

    function unstake() public updateReward(msg.sender) {
        for (uint i=0; i < tokenIds[msg.sender].length; ++i) {
            parentNFT.safeTransferFrom(address(this), msg.sender, tokenIds[msg.sender][i]);
        }
        delete tokenIds[msg.sender];
        lastUpdateTime[msg.sender] = block.timestamp;
    }

    function redeem(uint256 _points) public updateReward(msg.sender) {
        require(points[msg.sender] >= _points);
        points[msg.sender] = points[msg.sender] - _points;
    }

    function earned(address _account) public view returns (uint256) {
        uint256 blockTime = block.timestamp;
        return (tokenIds[_account].length * (blockTime - lastUpdateTime[_account])) + points[_account];
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}