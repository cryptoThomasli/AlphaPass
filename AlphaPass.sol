//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract AlphaNft is Ownable, ERC721A, ReentrancyGuard {
    uint256 public immutable maxQty = 1024;
    uint256 public immutable mintPrice = 0.01 ether;
    uint256 public immutable maxMintPerAddr = 1;
    string private _baseTokenURI;

    // Flag whether address is minted or not
    mapping(address => bool) private _isMinted;

    constructor(string memory baseURI)
        ERC721A("AlphaPass", "AlphaPass")
    {
        _baseTokenURI = baseURI;
    }

    function whitelistMint(uint256 quantity, bytes memory signature) external payable nonReentrant {
        require(!_isMinted[_msgSender()], "User is minted");
        require(verify(signature, _msgSender()), "Verify failed");

        require(tx.origin == msg.sender, "Contracts not allowed");
        uint256 totalsupply = totalSupply();
        require(totalsupply + quantity <= maxQty, "Exceed sales max limit");
        require(
            numberMinted(msg.sender) + quantity <= maxMintPerAddr,
            "cannot mint this many"
        );

        uint256 cost;
        unchecked {
            cost = quantity * mintPrice;
        }
        require(msg.value == cost, "wrong payment");


        _isMinted[_msgSender()] = true;
        _safeMint(msg.sender, quantity);
    }

    function mint(uint256 quantity) external payable nonReentrant {
        require(tx.origin == msg.sender, "Contracts not allowed");
        uint256 totalsupply = totalSupply();
        require(totalsupply + quantity <= maxQty, "Exceed sales max limit");
        require(
            numberMinted(msg.sender) + quantity <= maxMintPerAddr,
            "cannot mint this many"
        );

        uint256 cost;
        unchecked {
            cost = quantity * mintPrice;
        }
        require(msg.value == cost, "wrong payment");

        _safeMint(msg.sender, quantity);
    }

    function verify(bytes memory signature, address target) internal view returns (bool) {
        bytes32 messageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", abi.encode(target))
        );

        return owner() == ECDSA.recover(messageHash, signature);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function isMinted(address addr) external view returns (bool) {
    return _isMinted[addr];
  }
}